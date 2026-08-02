;Win+PrtSc非常非常常用，但单独的一个PrtSc不怎么会用到，基本已经被截图软件代替了。
;对此我的解决办法是：
;把 PrtSc（无视修饰键的状态） 映射为 Win+PrtSc 



#Requires AutoHotkey v2.0
#NoTrayIcon ;运行该脚本时不显示托盘图标
A_MenuMaskKey:="vkE8" ;禁用AHK的掩护键，防止物理按下Win+PrtSc时还会额外按下Ctrl：把AHK的内置变量A_MenuMaskKey（默认值为Ctrl）改为未分配的虚拟键vkE8，发送它无任何效果，等同于禁用掩护键

*PrintScreen::Send("#{PrintScreen}") ;星号*表示无视修饰键的状态