;在Win11，Alt+Tab（短按）可以切换到上一个窗口。但这么做有两个缺点：1. 会短暂显示系统切换界面。2. 长按时光标会在那个界面快速跳跃。
;对此我的解决办法是：
;拦截原生Alt+Tab，自己写一个这个逻辑。



#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 1 ;长按Alt+Tab时自动重复的按键会被丢弃，一次长按只切一次
InstallKeybdHook ;强制装键盘钩子，确保能吃掉系统原生的Alt+Tab

ACT_WAIT := 0.4 ;等待目标窗口真正激活的超时（秒），没激活成功就换下一个候选

gCur := 0        ;当前窗口
gPrev := 0       ;上一个窗口
gSwitching := false ;热键切换期间挂起追踪，避免中间态污染记录

;EVENT_SYSTEM_FOREGROUND=0x3；WINEVENT_OUTOFCONTEXT|WINEVENT_SKIPOWNPROCESS=0x2
gCallback := CallbackCreate(OnForeground, "F", 7)
gHook := DllCall("SetWinEventHook", "uint", 0x3, "uint", 0x3, "ptr", 0
    , "ptr", gCallback, "uint", 0, "uint", 0, "uint", 0x2, "ptr")
if !gHook {
    MsgBox "SetWinEventHook 失败，前台窗口无法追踪"
    ExitApp
}
OnExit Cleanup

!Tab:: {
    global gCur, gPrev, gSwitching, ACT_WAIT
    gSwitching := true
    try {
        Track(WinExist("A")) ;同步一次当前活动窗口：补上漏掉的事件，也让第一次按键就有正确的起点
        for target in Candidates() {
            try {
                if WinGetMinMax(target) = -1
                    WinRestore target
                WinActivate target
                if WinWaitActive("ahk_id " target, , ACT_WAIT) {
                    gPrev := gCur
                    gCur := target
                    break
                }
            } catch TargetError {
                continue ;候选窗口已关闭，继续尝试下一个
            }
        }
    } finally {
        gSwitching := false ;无论激活成功、失败还是抛错，追踪都必须恢复
    }
    KeyWait "Tab" ;Tab松开前不再触发（Alt可以一直按着）
}

OnForeground(hook, event, hwnd, idObject, idChild, thread, time) {
    global gSwitching
    if !gSwitching
        Track(hwnd)
}

Track(id) {
    global gCur, gPrev
    if !id || id = gCur || !Normal(id)
        return
    if gCur
        gPrev := gCur
    gCur := id
}

;候选目标：优先"上一个窗口"，它不可用或激活不了就按z序依次往下试
Candidates() {
    global gCur, gPrev
    list := []
    if Valid(gPrev)
        list.Push(gPrev)
    for hwnd in WinGetList()
        if hwnd != gCur && hwnd != gPrev && Normal(hwnd)
            list.Push(hwnd)
    return list
}

;是不是一个"能切过去的普通窗口"：排除桌面、任务栏、Alt+Tab UI、工具窗口、无标题窗口、UWP隐藏壳
Normal(hwnd) {
    static SKIP := Map(
        "Shell_TrayWnd", 1,                  ;任务栏
        "Shell_SecondaryTrayWnd", 1,         ;副屏任务栏
        "Progman", 1, "WorkerW", 1,          ;桌面
        "MultitaskingViewFrame", 1,          ;任务视图
        "XamlExplorerHostIslandWindow", 1,   ;Win11的Alt+Tab界面
        "Windows.UI.Core.CoreWindow", 1,     ;开始菜单/搜索等UWP壳
        "ForegroundStaging", 1,
        "TaskListThumbnailWnd", 1,           ;任务栏缩略图预览
        "Shell_InputSwitchTopLevelWindow", 1 ;输入法切换指示
    )
    try {
        cls := WinGetClass(hwnd)
        title := WinGetTitle(hwnd)
        style := WinGetStyle(hwnd)
        ex := WinGetExStyle(hwnd)
    } catch
        return false
    if SKIP.Has(cls) || title = ""
        return false
    if !(style & 0x10000000) ;WS_VISIBLE
        return false
    if (ex & 0x00000080) ;WS_EX_TOOLWINDOW，工具窗口本来就不进Alt+Tab
        return false
    ;DWMWA_CLOAKED=14：UWP应用挂起后窗口还在，但已被系统隐藏，切过去会黑屏
    if (DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "int*", &cloaked := 0, "uint", 4) = 0 && cloaked)
        return false
    return true
}

Valid(hwnd) {
    global gCur
    return hwnd && hwnd != gCur && WinExist("ahk_id " hwnd) && Normal(hwnd)
}

Cleanup(*) {
    global gHook, gCallback
    DllCall("UnhookWinEvent", "ptr", gHook)
    CallbackFree(gCallback)
}
