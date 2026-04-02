;在苹果iPad上使用远程控制软件控制Windows电脑时，在外接键盘上输入Home/End/PgUp/PgDn，电脑上输入的却是Ctrl+左右上下方向键。
;联想键盘BK001有一个特性：“在蓝牙模式下，键盘会自动识别并切换到对应的系统”，而不能手动指定。因此在苹果iPad上使用远程控制软件控制Windows电脑时，在键盘上输入Win/Alt，电脑上输入的却是Alt/Win。
;对此我的解决办法是：
;把 Ctrl+左右上下方向键 映射为 Home/End/PgUp/PgDn 
;把 Win/Alt 映射为 Alt/Win 

#Requires AutoHotkey v2.0 ;我的AutoHotkey Dash是2.0版本的，v2和v1语法不同，所以写上这么一句

^Left::Send("{Home}") ; Ctrl+左方向键 映射为 Home 
^+Left::{ ; Ctrl+Shift+左方向键 映射为 Shift+Home 
    Send("{Shift down}") ;AHK有一个修饰键自动管理机制，表现在这里就是在Send之前它会松开所有按键。如果在这之后我们执行的语句是^+Left::Send("+{Home}")，那么在它发送完Shift+Home后，Shift和Home都会松开。但此时我们正在物理按住Shift，我们也希望这个Shift能够正常生效。所以这里我们要单独写一句Send("{Shift down}")
    Send("{Home}")
}

^Right::Send("{End}")
^+Right::{
    Send("{Shift down}")
    Send("{End}")
}

^Up::Send("{PgUp}")
^+Up::{
    Send("{Shift down}")
    Send("{PgUp}")
}

^Down::Send("{PgDn}")
^+Down::{
    Send("{Shift down}")
    Send("{PgDn}")
}

LWin::LAlt ; 左Win 映射为 左Alt 
RWin::RAlt ; 右Win 映射为 右Alt （如果有右侧按键的话）

LAlt::LWin
RAlt::RWin

;还有一个特性：运行该脚本时，在键盘上输入Win+PrtSc，等效Shift+Win+3打开记事本。额...这是为什么？要搞吗？之后再看看吧。