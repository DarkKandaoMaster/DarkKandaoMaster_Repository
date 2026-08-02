"""
精确哈希查重（只读扫描，不删除、不移动任何文件）

策略：文件大小分组 -> 头部 64KB 部分哈希 -> 全文件 BLAKE2b
结果写入 UTF-8(BOM) CSV。两张图只要有一个字节不同就不会被判为重复。

用法:
    python find_duplicates.py                 # 扫描下面 TARGET_DIR 指定的目录
    python find_duplicates.py "D:\\Kandao\\Pictures\\[ 相册 ]\\1·荧"    # 扫描指定目录
"""

import csv
import hashlib
import os
import sys
from collections import defaultdict
from datetime import datetime

# ---------------- 配置 ----------------

# 待扫描目录，相对路径以本脚本所在目录为基准
TARGET_DIR = "1·荧"

# 是否递归扫描子目录
RECURSIVE = True

# 只检查这些扩展名（小写，含点）。设为 None 表示检查所有文件。
EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".tif", ".tiff", ".heic"}

# 部分哈希读取的字节数
PARTIAL_BYTES = 64 * 1024

# 全文件哈希的分块大小
CHUNK_BYTES = 1024 * 1024

# --------------------------------------

# Windows 控制台默认可能是 GBK，统一成 UTF-8 以免打印中文文件名时报错
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

errors = []

# 路径 -> 修改时间。扫描时一并取好，出报告时不再碰磁盘，避免文件中途消失导致前功尽弃。
mtimes = {}


def csv_safe(value):
    """Excel 会把以 = + - @ 开头的单元格当公式，加个前导单引号强制当文本。"""
    text = str(value)
    return "'" + text if text[:1] in ("=", "+", "-", "@", "\t", "\r") else text


def human_size(n):
    v = float(n)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if v < 1024 or unit == "TB":
            return f"{v:.0f} {unit}" if unit == "B" else f"{v:.1f} {unit}"
        v /= 1024


def collect_files(root):
    """返回 [(路径, 大小)]，跳过空文件和扩展名不匹配的文件。"""

    def on_walk_error(e):
        # os.walk 默认静默跳过打不开的目录，那样会漏扫一整棵子树还不报错
        errors.append((getattr(e, "filename", root), str(e)))

    result = []
    for dirpath, dirnames, filenames in os.walk(root, onerror=on_walk_error):
        for name in filenames:
            if EXTENSIONS is not None and os.path.splitext(name)[1].lower() not in EXTENSIONS:
                continue
            path = os.path.join(dirpath, name)
            try:
                st = os.stat(path)
            except OSError as e:
                errors.append((path, str(e)))
                continue
            if st.st_size > 0:
                result.append((path, st.st_size))
                mtimes[path] = st.st_mtime
        if not RECURSIVE:
            dirnames.clear()
    return result


def hash_file(path, limit=None):
    """计算 BLAKE2b。limit 为 None 时算全文件，否则只算前 limit 字节。"""
    h = hashlib.blake2b(digest_size=32)
    remaining = limit
    with open(path, "rb") as f:
        while remaining is None or remaining > 0:
            size = CHUNK_BYTES if remaining is None else min(CHUNK_BYTES, remaining)
            chunk = f.read(size)
            if not chunk:
                break
            h.update(chunk)
            if remaining is not None:
                remaining -= len(chunk)
    return h.hexdigest()


def regroup(groups, limit, label):
    """
    groups: [(大小, [路径, ...]), ...] —— 已知大小相同的候选组
    对组内每个文件算哈希再细分，返回 [(大小, 哈希, [路径, ...]), ...]，只保留成员数 > 1 的组。
    """
    buckets = defaultdict(list)
    total = sum(len(paths) for _, paths in groups)
    done = 0
    for size, paths in groups:
        for path in paths:
            done += 1
            if done % 200 == 0 or done == total:
                print(f"  [{label}] {done}/{total}", end="\r", flush=True)
            try:
                digest = hash_file(path, limit)
            except OSError as e:
                errors.append((path, str(e)))
                continue
            buckets[(size, digest)].append(path)
    if total:
        print()
    return [(size, digest, paths) for (size, digest), paths in buckets.items() if len(paths) > 1]


def main():
    base = os.path.dirname(os.path.abspath(__file__))
    target = sys.argv[1] if len(sys.argv) > 1 else TARGET_DIR
    if not os.path.isabs(target):
        target = os.path.join(base, target)

    if not os.path.isdir(target):
        print(f"目录不存在: {target}")
        return 1

    print(f"扫描目录: {target}")
    files = collect_files(target)
    print(f"共 {len(files)} 个文件, {human_size(sum(s for _, s in files))}")
    if not files:
        return 0

    # 阶段 1: 按大小分组。大小唯一的文件不可能字节相同，直接排除。
    by_size = defaultdict(list)
    for path, size in files:
        by_size[size].append(path)
    candidates = [(size, paths) for size, paths in by_size.items() if len(paths) > 1]
    print(f"[1/3] 大小分组: {sum(len(p) for _, p in candidates)} 个文件进入候选")
    if not candidates:
        print("没有大小相同的文件，不存在精确重复。")
        return 0

    # 阶段 2: 头部部分哈希。本身不超过 PARTIAL_BYTES 的文件跳过这步，直接进阶段 3。
    large = [(size, paths) for size, paths in candidates if size > PARTIAL_BYTES]
    small = [(size, paths) for size, paths in candidates if size <= PARTIAL_BYTES]
    print(f"[2/3] 部分哈希 (前 {human_size(PARTIAL_BYTES)}), {sum(len(p) for _, p in large)} 个文件:")
    survivors = [(size, paths) for size, _, paths in regroup(large, PARTIAL_BYTES, "部分")]
    survivors += small
    print(f"      {sum(len(p) for _, p in survivors)} 个文件进入完整哈希")
    if not survivors:
        print("没有重复文件。")
        return 0

    # 阶段 3: 全文件哈希，确认精确重复
    print(f"[3/3] 完整哈希, {human_size(sum(size * len(p) for size, p in survivors))}:")
    dup_groups = regroup(survivors, None, "完整")
    if not dup_groups:
        print("没有重复文件。")
        return 0

    # 整理结果：按可回收空间从大到小排组；组内按修改时间升序，最早的一个标记为“保留”
    dup_groups.sort(key=lambda g: g[0] * (len(g[2]) - 1), reverse=True)
    rows = []
    wasted = 0
    for gid, (size, digest, paths) in enumerate(dup_groups, start=1):
        wasted += size * (len(paths) - 1)
        paths = sorted(paths, key=lambda p: (mtimes.get(p, 0), p))
        for i, path in enumerate(paths):
            mtime = mtimes.get(path)
            rows.append(
                {
                    "组号": gid,
                    "建议": "保留" if i == 0 else "重复",
                    "文件名": csv_safe(os.path.basename(path)),
                    "文件大小": human_size(size),
                    "组内数量": len(paths),
                    "修改时间": (
                        datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")
                        if mtime
                        else ""
                    ),
                    "字节数": size,
                    "哈希": digest,
                    "完整路径": csv_safe(path),
                }
            )

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report = os.path.join(base, f"duplicates_{stamp}.csv")
    # utf-8-sig 带 BOM，Excel 打开中文不乱码
    with open(report, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    print()
    print(f"重复组: {len(dup_groups)} 组, 涉及 {len(rows)} 个文件")
    print(f"可回收空间: {human_size(wasted)}")
    print(f"报告: {report}")

    if errors:
        print(f"\n{len(errors)} 个文件读取失败:")
        for path, msg in errors[:20]:
            print(f"  {path}: {msg}")
        if len(errors) > 20:
            print(f"  ... 另有 {len(errors) - 20} 条")

    print("\n本脚本只读，未改动任何文件。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
