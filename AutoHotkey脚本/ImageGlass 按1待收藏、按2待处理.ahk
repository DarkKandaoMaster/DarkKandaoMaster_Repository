#Requires AutoHotkey v2.0 ;我的AutoHotkey是2.0版本的，v2和v1语法不同，所以写上这么一句，如果使用v1解释器运行该脚本那么会报错
#HotIf WinActive("ahk_class WindowsForms10.Window.8.app.0.bf7771_r3_ad1 ahk_exe ImageGlass.exe")

1::CreateImageShortcut("D:\Kandao\Pictures\[ 相册 ]\[ 待收藏 ]") ;按下1触发CreateImageShortcut函数
2::CreateImageShortcut("D:\Kandao\Pictures\[ 相册 ]\[ 待处理 ]") ;按下2触发CreateImageShortcut函数

#HotIf ;结束#HotIf作用域，避免影响其他程序

CreateImageShortcut(targetDir){ ;自定义函数。实现：模拟输入Ctrl+L复制图像路径，然后在固定路径targetDir生成一个该图片的快捷方式
    A_Clipboard:="" ;清空剪贴板，方便后续判断Ctrl+L是否真的写入了内容
    Send "^l" ;模拟输入Ctrl（^）和L（l）
    if !ClipWait(1){ ;暂停脚本，最多暂停1秒，如果在这期间剪贴板写入了内容，那么立刻继续运行脚本；否则弹出提示框、终止当前函数
        MsgBox("等待剪贴板超时，未能成功获取图片路径")
        return
    }

    imagePath:=Trim(A_Clipboard," `t`r`n") ;读取剪贴板中的内容，并使用Trim()去除两端的空格或换行符
    if !FileExist(imagePath){ ;如果读出来的路径在硬盘上不存在，那么大概率是读到了什么奇奇怪怪的东西，弹出提示框、终止当前函数
        MsgBox("剪贴板内容不是有效的文件路径：`n" imagePath)
        return
    }
    fileName:=""
    SplitPath imagePath,&fileName ;SplitPath可以从完整路径（比如D:\...\a.jpg）中，把文件名（a.jpg）提取出来，并赋值给fileName变量
    if !DirExist(targetDir){ ;如果固定路径targetDir在硬盘上不存在，那么自动创建该路径
        DirCreate targetDir
    }
    shortcutPath:=targetDir "\" fileName ".lnk" ;拼接我们最终要生成的快捷方式文件的完整路径 ;因为我们全程都是Windows环境，所以这里最好使用\拼接路径

    FileCreateShortcut imagePath,shortcutPath ;生成快捷方式。第一个参数表示指向的源文件，第二个参数表示快捷方式文件的保存位置
}