;遍历指定路径 D:\Kandao\Pictures\[ 相册 ]\[ 收藏 ] 下的所有文件（包括子文件夹里的文件），
;如果不是快捷方式文件，或者是已失效/已损坏的快捷方式文件，那么弹出弹窗提示
;如果是快捷方式文件，那么获取该快捷方式文件所指向文件的三个日期，将它们设置为该快捷方式文件的三个日期

#Requires AutoHotkey v2.0 ;我的AutoHotkey是2.0版本的，v2和v1语法不同，所以写上这么一句，如果使用v1解释器运行该脚本那么会报错

targetDir:="D:\Kandao\Pictures\[ 相册 ]\[ 收藏 ]"
Loop Files,targetDir "\*","FR"{ ;使用Loop Files遍历指定路径下的所有文件 ;targetDir "\*"表示匹配该文件夹下的所有文件 ;"FR"是参数："F"表示只匹配文件不匹配文件夹；"R"表示也匹配所有子文件夹里的文件
    targetPath:=""
    try{
        FileGetShortcut A_LoopFilePath,&targetPath ;取出该快捷方式文件所指向文件的绝对路径，并赋值给targetPath变量
    }
    catch{
        MsgBox("该快捷方式读取失败，可能已失效/已损坏：`n" A_LoopFileName) ;虽然这个弹窗不能选中文字，但是当焦点在弹窗上时，你可以按下Ctrl+C，这样就能把整个弹窗都复制到剪贴板里
        continue
    }
    if( targetPath="" or !FileExist(targetPath) ){ ;如果取出的targetPath为空或者指向了不存在的路径
        MsgBox("该快捷方式读取失败，可能已失效/已损坏：`n" A_LoopFileName)
        continue
    }

    createTime:=FileGetTime(targetPath,"C") ;获取路径为targetPath的文件的创建时间
    modifyTime:=FileGetTime(targetPath,"M") ;获取路径为targetPath的文件的修改时间
    accessTime:=FileGetTime(targetPath,"A") ;获取路径为targetPath的文件的访问时间
    FileSetTime createTime,A_LoopFilePath,"C" ;将刚刚获取到的创建时间，设置为该快捷方式文件的创建时间
    FileSetTime modifyTime,A_LoopFilePath,"M" ;将刚刚获取到的修改时间，设置为该快捷方式文件的修改时间
    FileSetTime accessTime,A_LoopFilePath,"A" ;将刚刚获取到的访问时间，设置为该快捷方式文件的访问时间
}

MsgBox("所有操作已完成！")


;【【【【【要不在MsgBox里加个标题？