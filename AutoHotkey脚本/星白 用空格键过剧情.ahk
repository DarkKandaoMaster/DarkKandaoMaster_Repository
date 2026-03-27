#Requires AutoHotkey v2.0 ;我的AutoHotkey Dash是2.0版本的，v2和v1语法不同，所以写上这么一句
#HotIf WinActive("ahk_class UnityWndClass ahk_exe 星空列车与白的旅行.exe")

Space::{
    Send("{Enter}")
    return
}
;不过这就有了个问题，就是长按空格会一直继续剧情...