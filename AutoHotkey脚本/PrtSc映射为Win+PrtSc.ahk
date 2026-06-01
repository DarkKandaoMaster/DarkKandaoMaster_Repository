;Win+PrtSc非常非常常用，但单独的一个PrtSc不怎么会用到，基本已经被截图软件代替了。
;对此我的解决办法是：
;把 PrtSc（无视修饰键的状态） 映射为 Win+PrtSc 



#Requires AutoHotkey v2.0
#NoTrayIcon ;运行该脚本时不显示托盘图标

*PrintScreen::Send("#{PrintScreen}") ;星号*表示无视修饰键的状态