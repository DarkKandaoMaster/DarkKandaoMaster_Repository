;很多galgame是用鼠标滚轮、回车键过剧情的，而不是空格键、方向键。
;对此我的解决办法是：
;把 空格键、下方向键、右方向键 映射为 鼠标滚轮向下滚动一格 



#Requires AutoHotkey v2.0 ;我的AutoHotkey是2.0版本的，v2和v1语法不同，所以写上这么一句，如果使用v1解释器运行该脚本那么会报错

Space::{
    Send("{WheelDown}")
    KeyWait("Space") ;阻塞脚本直到物理松开空格键。这样可以防止不小心长按空格于是快速过剧情
}

Down::{
    Send("{WheelDown}")
    KeyWait("Down")
}

Right::{
    Send("{WheelDown}")
    KeyWait("Right")
}