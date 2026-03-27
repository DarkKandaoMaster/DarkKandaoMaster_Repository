#Requires AutoHotkey v2.0 ;我的AutoHotkey Dash是2.0版本的，v2和v1语法不同，所以写上这么一句
#HotIf WinActive("ahk_class WindowsForms10.Window.8.app.0.3455ce_r7_ad1 ahk_exe mpvnet.exe")

Right:: ; 模拟B站长按右方向键倍速播放的功能：长按0.3秒右方向键倍速播放，松开时恢复
{
if !(KeyWait("Right", "T0.3")) { ; 按住右方向键持续0.3s
Send("]") ; 三倍速播放
KeyWait("Right") ; 松开按键
Send("\") ; 恢复一倍速
}
else {
Send("{Right}") ; 如果按住右方向键未持续0.3s，则触发mpvnet原始快捷键
}
return
}