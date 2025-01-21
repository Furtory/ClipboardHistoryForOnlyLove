/*
本AHK由 黑钨重工 制作 免费开源
唯一教程视频发布地址https://space.bilibili.com/52593606
所有开源项目 https://github.com/Furtory
AHK正版官方论坛https://www.autohotkey.com/boards/viewforum.php?f=26
国内唯一完全免费开源AHK论坛请到QQ频道AutoHotKey12
本人所有教程和脚本严禁转载到此收费论坛以防被用于收费盈利 https://www.autoahk.com/

如果你要进行二次开发 以下变量可能帮到你
UserClipboardRecord ; 用户Ctrl+C Ctrl+X等主动操作产生的剪贴板历史记录
OutputClipboardRecord ; 生成内容参数的剪贴板历史记录

ClipboardHistory ; 剪贴板历史记录 是数组 包含多个记录
ClipboardHistoryRecord ; 修改/删除前的剪贴板历史记录 是数组 撤回后会被重置为空数组 只可撤回1次

TopMenuCount ; 当前的顶置菜单数量
TopClipboard ; 最近一次被顶置剪贴板的内容
OldTopClipboardPos ; 最近一次被顶置剪贴板的内容之前在数组中的位置
NewTopClipboardPos ; 最近一次被顶置剪贴板的内容现在在数组中的位置
TopMenuCountRecord ; 修改前的顶置菜单数量记录 撤回后会被重置为空 只可撤回1次

MoveClipboard ; 最近一次被移动剪贴板的内容
OldMoveClipboardPos ; 最近一次被移动剪贴板的内容之前在数组中的位置
NewMoveClipboardPos ; 最近一次被移动剪贴板的内容现在在数组中的位置

ExceedClipboard ; 最近一次超出条目上限被移除的剪贴板的内容
DeleteClipboard ; 最近一次被删除剪贴板的内容
DeleteClipboardPos ; 最近一次被删除剪贴板的内容现在在数组中的位置
*/

管理员模式:
    IfExist, %A_ScriptDir%\History.ini ;如果配置文件存在则读取
    {
        IniRead AdminMode, History.ini, Settings, 管理权限 ;从ini文件读取
        if (AdminMode=1)
        {
            ShellExecute := A_IsUnicode ? "shell32\ShellExecute":"shell32\ShellExecuteA"

            if not A_IsAdmin
            {
                If A_IsCompiled
                    DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_ScriptFullPath, str, params , str, A_WorkingDir, int, 1)
                Else
                    DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """" . A_Space . params, str, A_WorkingDir, int, 1)
                ExitApp
            }
        }
    }

    SendMode Input
    Process Priority, , Realtime
    #MenuMaskKey vkE8
    #WinActivateForce
    #InstallKeybdHook
    #InstallMouseHook
    #Persistent
    #NoEnv
    #SingleInstance Force
    #MaxHotkeysPerInterval 2000
    #KeyHistory 2000
    CoordMode Mouse, Screen
    CoordMode Menu, Screen
    SetBatchLines -1
    SetKeyDelay 30, 50 ; 按键按住时间 和 按键发送间隔 不宜太短 VS code 响应不过来

    Menu Tray, Icon, %A_ScriptDir%\LOGO.ico
    Menu Tray, NoStandard ;不显示默认的AHK右键菜单
    Menu Tray, Add, 使用教程, 使用教程 ;添加新的右键菜单
    Menu Tray, Add
    Menu Tray, Add, 管理权限, 管理权限 ;添加新的右键菜单
    Menu Tray, Add, 开机自启, 开机自启 ;添加新的右键菜单
    Menu Tray, Add, 记录数量, 记录数量 ;添加新的右键菜单
    Menu Tray, Add, 菜单宽度, 菜单宽度 ;添加新的右键菜单
    Menu Tray, Add
    Menu Tray, Add, 新增白名单, 新增白名单 ;添加新的右键菜单
    Menu Tray, Add, 白名单设置, 白名单设置 ;添加新的右键菜单
    Menu Tray, Add
    Menu Tray, Add, 中键呼出, 中键呼出 ;添加新的右键菜单
    Menu Tray, Add, 智能帮助, 智能帮助 ;添加新的右键菜单
    Menu Tray, Add, 颜色转换, 颜色转换 ;添加新的右键菜单
    Menu Tray, Add, Base64编解码, Base64编解码 ;添加新的右键菜单
    Menu Tray, Add
    Menu Tray, Add, 撤回操作, 撤回操作 ;添加新的右键菜单
    Menu Tray, Add, 查看回收站, 回收站 ;添加新的右键菜单
    Menu Tray, Add, 清空回收站, 清空回收站 ;添加新的右键菜单
    Menu Tray, Add
    Menu Tray, Add, 重启软件, 重启软件 ;添加新的右键菜单
    Menu Tray, Add, 退出软件, 退出软件 ;添加新的右键菜单

    autostartLnk:=A_StartupCommon . "\ClipboardHistoryRecorder.lnk" ;开机启动文件的路径
    IfExist, % autostartLnk ;检查开机启动的文件是否存在
    {
        autostart:=1
        Menu Tray, Check, 开机自启 ;右键菜单打勾
    }
    Else
    {
        autostart:=0
        Menu Tray, UnCheck, 开机自启 ;右键菜单不打勾
    }

    ; 定义全局变量用于存储剪贴板历史
    ClipboardHistory := []
    ClipboardHistoryRecord:=[]

    IfExist, %A_ScriptDir%\History.ini
    {
        ; 读取剪贴板设置
        if (AdminMode=1)
            Menu Tray, Check, 管理权限 ;右键菜单打勾

        IniRead TopMenuCount, History.ini, Settings, TopMenuCount ;从ini文件读取

        IniRead WhiteList, History.ini, Settings, 白名单列表 ;从ini文件读取

        Hotkey Mbutton, 中键
        Iniread 中键呼出, History.ini, Settings, 中键呼出 ;从ini文件读取
        if (中键呼出=1)
        {
            Menu Tray, Check, 中键呼出 ;右键菜单打勾
        }
        Else
        {
            Hotkey Mbutton, Off
        }

        Iniread Base64编解码, History.ini, Settings, Base64编解码 ;从ini文件读取
        if (Base64编解码=1)
        {
            Menu HotTray, Add, Base64 Encode编码, Encode ;添加新的右键菜单
            Menu HotTray, Add, Base64 Decode解码, Decode ;添加新的右键菜单
            Menu Tray, Check, Base64编解码 ;右键菜单打勾
        }

        Iniread 颜色转换, History.ini, Settings, 颜色转换 ;从ini文件读取
        if (颜色转换=1)
        {
            if (Base64编解码=1)
            {
                Menu HotTray, Add
            }
            Menu HotTray, Add, RGB Transform转换, RGB_Transform ;添加新的右键菜单
            Menu Tray, Check, 颜色转换 ;右键菜单打勾
        }

        if (Base64编解码!=1) and (颜色转换!=1)
            Hotkey !x, Off

        Iniread PID, History.ini, Settings, 智能帮助ID ;从ini文件读取
        if (PID!="") and (PID!="ERROR")
            oWB:=IE_GetWB(PID).document          
        Iniread 智能帮助, History.ini, Settings, 智能帮助 ;从ini文件读取
        if (智能帮助=1)
            Menu Tray, Check, 智能帮助 ;右键菜单打勾
        Else
            Hotkey F1, Off

        Iniread MaxItem, History.ini, Settings, 记录数量 ;从ini文件读取
        Iniread MenuLength, History.ini, Settings, 菜单宽度 ;从ini文件读取

        ; 读取剪贴板历史
        ClipboardAlreadyRecorded:=1
        Loop %MaxItem% ; 最大条目数量
        {
            IniRead ReadHistory, History.ini, History, ClipboardHistory%A_Index% ;从ini文件读取
            ; ToolTip, ReadHistory`n%ReadHistory%
            ; Sleep, 1000
            if (ReadHistory="") Or (ReadHistory="ERROR") ; 如果该项不存在，则停止读取
            {
                if (A_Index=1) ; 如果第一次就是空不用添加历史记录数组为新条目到剪贴板历史GUI
                    ClipboardAlreadyRecorded:=0
                Break
            }
            ClipboardHistory.InsertAt(1, StrReplace(ReadHistory, "``r``n", "`r`n")) ; 把之前记录为文本的CRLF重新转换回来
        }

        ; 添加历史记录数组为新条目到剪贴板历史GUI
        if (ClipboardAlreadyRecorded=1)
        {
            ; ToolTip, % ClipboardHistory.MaxIndex()
            ; 重新加载菜单
            RefreshMenu()
        }
    }
    Else
    {
        TopMenuCount:=0
        IniWrite %TopMenuCount%, History.ini, Settings, TopMenuCount ;写入设置到ini文件

        AdminMode:=0
        IniWrite %AdminMode%, History.ini, Settings, 管理权限 ;写入设置到ini文件

        中键呼出:=0
        IniWrite %中键呼出%, History.ini, Settings, 中键呼出 ;写入设置到ini文件

        智能帮助:=0
        IniWrite %智能帮助%, History.ini, Settings, 智能帮助 ;写入设置到ini文件

        MaxItem:=20 ; 最大条目数量
        IniWrite %MaxItem%, History.ini, Settings, 记录数量 ;写入设置到ini文件

        MenuLength:=30 ; 最大菜单宽度
        IniWrite %MenuLength%, History.ini, Settings, 菜单宽度 ;写入设置到ini文件

        WhiteList:="Exe===Code.exe|Exe===Notepad--.exe"
        IniWrite %WhiteList%, History.ini, Settings, 白名单列表

        Base64编解码:=0
        IniWrite %Base64编解码%, History.ini, Settings, Base64编解码 ;写入设置到ini文件

        颜色转换:=0
        IniWrite %颜色转换%, History.ini, Settings, 颜色转换 ;写入设置到ini文件
    }

    ; 软件初始运行时记录当前的剪贴板内容
    UserClipboardRecord := A_Clipboard

    if (WhiteList="") or (WhiteList="ERROR")
    {
        WhiteList:="Exe===Code.exe|Exe===Notepad--.exe"
        MsgBox "您还未设置白名单, 请根据提示设置白名单"
        goto 新增白名单
    }
Return

RefreshMenu()
{
    global

    Loop % ClipboardHistory.MaxIndex()
    {
        ; 从ClipboardHistory中提取不超过长度上限的部分字符串
        ; NewClipboard:=ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index] ;逆序
        NewClipboard:=SubStr(ClipboardHistory[A_Index], 1, MenuLength*3) ;顺序

        NewClipboard:=StrReplace(NewClipboard, "`r`n",  " ┇ ") ; 去掉复制内容中的CRLF换行 转为" ┇ "显示
        if (InStr(NewClipboard, " ┇ ")=1) ; 第一个是" ┇ " 提取第四个 菜单名称限制字符串长度
            NewClipboard:=SubStr(NewClipboard, 4)

        NewClipboard:=RegExReplace(NewClipboard, "`t", " ") ; 复制内容中的制表符缩进转为1个空格宽度
        NewClipboard:=RegExReplace(NewClipboard, "\s{2,}", " ") ; 复制内容中连续的空格缩进只显示1个空格宽度
        if (InStr(NewClipboard, A_Space)=1) ; 第一个是空格 提取第二个 菜单名称限制字符串长度
            NewClipboard:=SubStr(NewClipboard, 2)

        NewClipboard:=SubStr(NewClipboard, 1, MenuLength) ; 菜单名称限制字符串长度

        ; 条目名称内如果有宽字符则限制更短的长度
        NarrowCount := 0
        Loop, Parse, % NewClipboard
        {
            ; 判断字符是否为窄字符 0-9 a-z ! " # $ % & ' ( ) * + - . , / < = > ? @ [ \ ] ^ _ ` { | } ~
            if A_IsUnicode ; Unicode 官网http://www.unicode.org/charts/
            {
                if (Asc(A_LoopField) >= 0x30 && Asc(A_LoopField) <= 0x39) or (Asc(A_LoopField) >= 0x61 && Asc(A_LoopField) <= 0x7A) or (Asc(A_LoopField) >= 0x21 && Asc(A_LoopField) <= 0x2F) or (Asc(A_LoopField) >= 0x3A && Asc(A_LoopField) <= 0x40) or(Asc(A_LoopField) >= 0x5B && Asc(A_LoopField) <= 0x60) or(Asc(A_LoopField) >= 0x7B && Asc(A_LoopField) <= 0x7E) or (A_LoopField ~= "^\s*$") or (A_LoopField = "┇")
                {
                    NarrowCount++
                }
            }
            else ; Ascii 官网https://www.unicode.org/charts/PDF/U0000.pdf
            {
                if (Asc(A_LoopField) >= 33 && Asc(A_LoopField) <= 65) or (Asc(A_LoopField) >= 90 && Asc(A_LoopField) <= 126) or (A_LoopField ~= "^\s*$") or (A_LoopField = "┇")
                {
                    NarrowCount++
                }
            }
        }
        ; ToolTip %NarrowCount%`n%NewClipboard%

        if (NarrowCount<MenuLength) ;存在宽字符
        {
            NewClipboard:=SubStr(NewClipboard, 1, MenuLength-Ceil((MenuLength-NarrowCount)/2)) ; 菜单名称限制字符串长度
        }

        Menu ClipboardHistoryMenu, Add, %NewClipboard%, ClickTheHistoryRecord, Radio ; 添加菜单

        if (A_Index<=TopMenuCount)
            Menu ClipboardHistoryMenu, Check, %NewClipboard% ; 给顶置菜单打上点作为标识

        if (A_Index=TopMenuCount)
            Menu ClipboardHistoryMenu, Add ; 顶置菜单和非顶置菜单之间增加一条分割线
    }
    Return
}

使用教程:
    MsgBox, , 独爱剪贴板使用教程, 记录独爱白名单软件内 用户主动行为产生的剪贴板历史`n主动行为指使用 Ctrl + C 或 Ctrl + X 快捷键`n自定义的主动行为快捷键和白名单需要修改源码`n相同的内容不会添加为重复的条目`n而是将重复的条目挪到菜单最上面`n即使重启电脑也不会丢失剪贴板历史记录`n菜单中显示的剪贴板历史记录保存在软件同目录下的History.ini内`n超出记录长度上限或被删除的剪贴板历史记录会存在软件同目录下的HistoryRecycleBin.txt内`n`n呼出剪贴板历史记录菜单`n    按下Alt+V打开剪贴板历史记录菜单`n    修改呼出菜单的快捷键需要修改源码`n    你还可以在右键菜单中启用中键快捷呼出`n    按下 Ctrl + Shift + D 清除全部的剪贴板历史记录`n`n呼出后`n    按住右键后再点击 可以顶置剪贴板历史记录`n    按住侧键后再点击 可以上下调整剪贴板历史记录顺序`n    按住Ctrl键后再点击 可以删除选中的剪贴板历史记录`n`n编辑器专属功能`n`n    按下 Ctrl + D 可以根据按下次数复制选中的内容`n    如果是被 ( ) 括起来的 则自动根据前后文在两段括号中间键入 and 或者 or`n    如果开头是 if 或者 是被 { } 括起来的代码段 则在复制的代码段前自动添加 else`n`n    右Shift+花括号右 ] 将选中内容前后加上 { } 包成代码块`n`n    使用Alt+X打开拓展菜单`n    使用 Base64 编码或解码选中的文字`n    颜色 10进制 和 16进制 之间互相转换`n`n    按下F1可以自动打开AutoHotKey帮助并跳转到选中内容`n`n    可指定编辑器内中文输入法下强制使用半角符号`n`n注意:以上编辑器专属功能需要编辑器快捷键配合!`n    向下复制 Shift + Alt + 下箭头`n    缩进格式化 Shift + Alt + F`n`n黑钨重工出品 免费开源 https://github.com/Furtory`n学习交流和更多免费软件 请到QQ频道AutoHotKey12
return

管理权限: ;模式切换
    Critical, On
    if (AdminMode=1)
    {
        AdminMode:=0
        IniWrite %AdminMode%, History.ini, Settings, 管理权限 ;写入设置到ini文件
        Menu Tray, UnCheck, 管理权限 ;右键菜单不打勾
        Critical, Off
        Reload
    }
    Else
    {
        AdminMode:=1
        IniWrite %AdminMode%, History.ini, Settings, 管理权限 ;写入设置到ini文件
        Menu Tray, Check, 管理权限 ;右键菜单打勾
        Critical, Off
        Reload
    }
return

开机自启: ;模式切换
    Critical, On
    if (autostart=1) ;关闭开机自启动
    {
        IfExist, % autostartLnk ;如果开机启动的文件存在
        {
            FileDelete %autostartLnk% ;删除开机启动的文件
        }

        autostart:=0
        Menu Tray, UnCheck, 开机自启 ;右键菜单不打勾
    }
    Else ;开启开机自启动
    {
        IfExist, % autostartLnk ;如果开机启动的文件存在
        {
            FileGetShortcut %autostartLnk%, lnkTarget ;获取开机启动文件的信息
            if (lnkTarget!=A_ScriptFullPath) ;如果启动文件执行的路径和当前脚本的完整路径不一致
            {
                FileCreateShortcut %A_ScriptFullPath%, %autostartLnk%, %A_WorkingDir% ;将启动文件执行的路径改成和当前脚本的完整路径一致
            }
        }
        Else ;如果开机启动的文件不存在
        {
            FileCreateShortcut %A_ScriptFullPath%, %autostartLnk%, %A_WorkingDir% ;创建和当前脚本的完整路径一致的启动文件
        }

        autostart:=1
        Menu Tray, Check, 开机自启 ;右键菜单打勾
    }
    Critical, Off
return

中键呼出: ;模式切换
    Critical, On
    if (中键呼出=1)
    {
        中键呼出:=0
        Hotkey Mbutton, Off
        IniWrite %中键呼出%, History.ini, Settings, 中键呼出 ;写入设置到ini文件
        Menu Tray, UnCheck, 中键呼出 ;右键菜单不打勾
    }
    Else
    {
        中键呼出:=1
        Hotkey Mbutton, On
        IniWrite %中键呼出%, History.ini, Settings, 中键呼出 ;写入设置到ini文件
        Menu Tray, Check, 中键呼出 ;右键菜单打勾
    }
    Critical, Off
return

Base64编解码: ;模式切换
    Critical, On
    if (Base64编解码=1)
    {
        Base64编解码:=0
        Menu HotTray, DeleteAll
        if (颜色转换=1)
        {
            Menu HotTray, Add, RGB Transform转换, RGB_Transform ;添加新的右键菜单

        }
        IniWrite %Base64编解码%, History.ini, Settings, Base64编解码 ;写入设置到ini文件
        Menu Tray, UnCheck, Base64编解码 ;右键菜单不打勾
    }
    Else
    {
        Base64编解码:=1
        if (颜色转换=1)
        {
            Menu HotTray, DeleteAll
        }
        Menu HotTray, Add, Base64 Encode编码, Encode ;添加新的右键菜单
        Menu HotTray, Add, Base64 Decode解码, Decode ;添加新的右键菜单
        if (颜色转换=1)
        {
            Menu HotTray, Add
            Menu HotTray, Add, RGB Transform转换, RGB_Transform ;添加新的右键菜单

        }
        Hotkey !x, On
        IniWrite %Base64编解码%, History.ini, Settings, Base64编解码 ;写入设置到ini文件
        Menu Tray, Check, Base64编解码 ;右键菜单打勾
    }

    if (Base64编解码!=1) and (颜色转换!=1)
        Hotkey !x, Off
    Critical, Off
return

颜色转换:
    Critical, On
    if (颜色转换=1)
    {
        颜色转换:=0
        Menu HotTray, DeleteAll
        if (Base64编解码=1)
        {
            Menu HotTray, Add, Base64 Encode编码, Encode ;添加新的右键菜单
            Menu HotTray, Add, Base64 Decode解码, Decode ;添加新的右键菜单
        }
        IniWrite %颜色转换%, History.ini, Settings, 颜色转换 ;写入设置到ini文件
        Menu Tray, UnCheck, 颜色转换 ;右键菜单不打勾
    }
    Else
    {
        颜色转换:=1
        if (Base64编解码=1)
        {
            Menu HotTray, Add
        }
        Menu HotTray, Add, RGB Transform转换, RGB_Transform ;添加新的右键菜单
        Hotkey !x, On
        IniWrite %颜色转换%, History.ini, Settings, 颜色转换 ;写入设置到ini文件
        Menu Tray, Check, 颜色转换 ;右键菜单打勾
    }

    if (Base64编解码!=1) and (颜色转换!=1)
        Hotkey !x, Off
    Critical, Off
Return

智能帮助: ;模式切换
    Critical, On
    if (智能帮助=1)
    {
        智能帮助:=0
        Hotkey F1, Off
        IniWrite %Adm智能帮助inMode%, History.ini, Settings, 智能帮助 ;写入设置到ini文件
        Menu Tray, UnCheck, 智能帮助 ;右键菜单不打勾

    }
    Else
    {
        智能帮助:=1
        Hotkey F1, On
        IniWrite %智能帮助%, History.ini, Settings, 智能帮助 ;写入设置到ini文件
        Menu Tray, Check, 智能帮助 ;右键菜单打勾
    }
    Critical, Off
return

记录数量:
    MaxItemRecord:=MaxItem
    InputBox MaxItem, 剪贴板历史记录最大数量设置, 剪贴板历史记录最大数量设置`n超出后会把记录末尾的移除`n本地文件不会保存超过最大数量的记录, , , 170, , , Locale, ,%MaxItem%
    if !ErrorLevel
    {
        if (MaxItem<=0)
            MaxItem:=1
        IniWrite %MaxItem%, History.ini, Settings, 记录数量 ;写入设置到ini文件

        ; 清空超过MaxItem的数组和本地文件
        if (ClipboardHistory.MaxIndex() > MaxItem)
            loop % ClipboardHistory.MaxIndex()-MaxItem
            {
                RemoveItem:=MaxItem+A_Index
                ClipboardHistory.RemoveAt(RemoveItem)
                IniWrite "", History.ini, History, ClipboardHistory%RemoveItem%
            }

        ; 删除GUI菜单
        if (ClipboardAlreadyRecorded=1)
            Menu ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        RefreshMenu()
    }
    else
        MaxItem:=MaxItemRecord
Return

菜单宽度:
    MenuLengthRecord:=MenuLength
    InputBox MenuLength, 剪贴板历史记录菜单宽度设置, 剪贴板历史记录菜单宽度设置 单位字符`n菜单中多个空格转为一个空格显示`n菜单中换行会转为一个空格显示, , , 170, , , Locale, ,%MenuLength%
    if !ErrorLevel
    {
        if (MenuLength<=0)
            MenuLength:=1
        IniWrite %MenuLength%, History.ini, Settings, 菜单宽度 ;写入设置到ini文件

        ; 删除GUI菜单
        if (ClipboardAlreadyRecorded=1)
            Menu ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        RefreshMenu()
    }
    else
        MaxItem:=MaxItemRecord
Return

新增白名单:
    KeyWait LButton
    WhiteListType:=1
    loop
    {
        KeyWait Ctrl
        MouseGetPos, , , WinID
        WinGetTitle WinTitle, Ahk_id %WinID%
        WinGet WinExe, ProcessName, Ahk_id %WinID%
        WinGetClass WinClass, Ahk_id %WinID%
        if (WhiteListType=1)
            ToolTip 当前窗口Title: %WinTitle%`n点击左键添加到白名单 点击Ctrl键切换类型
        Else if (WhiteListType=2)
            ToolTip 当前窗口Class: %WinClass%`n点击左键添加到白名单 点击Ctrl键切换类型
        Else if (WhiteListType=3)
            ToolTip 当前窗口Exe: %WinExe%`n点击左键添加到白名单 点击Ctrl键切换类型

        if GetKeyState("Ctrl", "P")
        {
            WhiteListType:=WhiteListType+1
            if (WhiteListType>3)
                WhiteListType:=1
        }
        else if GetKeyState("Esc", "P")
        {
            ToolTip
            Break
        }
        else if GetKeyState("Lbutton", "P")
        {
            if (WhiteListType=1)
            {
                NewWhiteList:="Title==="
                NewWhiteList.=WinTitle
            }
            else if (WhiteListType=2)
            {
                NewWhiteList:="Class==="
                NewWhiteList.=WinClass
            }
            else if (WhiteListType=3)
            {
                NewWhiteList:="Exe==="
                NewWhiteList.=WinExe
            }
            ToolTip
            Sleep 100

            IniRead WhiteListRecord, History.ini, Settings, 白名单列表 ;从ini文件读取
            if (InStr(WhiteListRecord, NewWhiteList)=0) ; 新增白名单
            {
                if (WhiteList="") or (WhiteList="ERROR")
                {
                    WhiteList:="Exe===Code.exe|Exe===Notepad--.exe"
                }
                WhiteList.="|"
                WhiteList.=NewWhiteList
                Sleep 100
                KeyWait LButton
                goto 白名单设置
            }
            else
            {
                LbuttonUp:=0
                loop 50
                {
                    ToolTip 白名单中已存在相同内容`,请重新设置!
                    if !GetKeyState("Lbutton", "P")
                        LbuttonUp:=1

                    if GetKeyState("Lbutton", "P") and (LbuttonUp=1)
                    {
                        ToolTip
                        KeyWait LButton
                        Break
                    }
                    Sleep 30
                }
            }
        }
    }
Return

白名单设置:
    InputBox WhiteList, 白名单设置, 请用 “===” 分隔开 匹配类型 和 匹配特征`n匹配类型有 Title Class Exe`n请用 “|” 分隔开每个窗口`n举例: Title===窗口标题, , A_ScreenHeight, 180, , , Locale, ,%WhiteList%
    if !ErrorLevel
    {
        IniWrite %WhiteList%, History.ini, Settings, 白名单列表 ;写入设置到ini文件
    }
    else
    {
        IniRead WhiteList, History.ini, Settings, 白名单列表 ;写入设置到ini文件
    }
Return

白名单:
    白名单:=0
    MouseGetPos, , , 白名单识别排除ID
    白名单列表:=StrSplit(WhiteList,"|")
    匹配次数:=白名单列表.Length() 
    Loop %匹配次数% ;Title Class Exe
    {
        ; ToolTip % 白名单列表[A_Index]
        if (InStr(白名单列表[A_Index], "Title")!=0)
        {
            排除项位置:=InStr(白名单列表[A_Index], "===")+3
            排除项:=SubStr(白名单列表[A_Index], 排除项位置)
            WinGetTitle 当前特征, ahk_id %白名单识别排除ID%
            ; ToolTip, 排除项%排除项%`n当前特征%当前特征%
            if (当前特征=排除项)
                白名单:=1
        }
        else if (InStr(白名单列表[A_Index], "Class")!=0)
        {
            排除项位置:=InStr(白名单列表[A_Index], "===")+3
            排除项:=SubStr(白名单列表[A_Index], 排除项位置)
            WinGetClass 当前特征, ahk_id %白名单识别排除ID%
            ; ToolTip, 排除项%排除项%`n当前特征%当前特征%
            if (当前特征=排除项)
                白名单:=1
        }
        else if (InStr(白名单列表[A_Index], "Exe")!=0)
        {
            排除项位置:=InStr(白名单列表[A_Index], "===")+3
            排除项:=SubStr(白名单列表[A_Index], 排除项位置)
            WinGet 当前特征, ProcessName, ahk_id %白名单识别排除ID%
            ; ToolTip, 排除项%排除项%`n当前特征%当前特征%
            if (当前特征=排除项)
                白名单:=1
        }
    }
Return

撤回操作:
    if (ClipboardHistoryRecord!="") and (ClipboardHistoryRecord.Length()!=0)
    {
        ; 恢复上一次的顶置菜单数量
        TopMenuCount := TopMenuCountRecord
        TopMenuCountRecord:=""
        IniWrite %TopMenuCount%, History.ini, Settings, TopMenuCount ;写入设置到ini文件

        ; 恢复上一次的剪贴板历史记录
        ClipboardHistory:=[]
        for index, value in ClipboardHistoryRecord
        {
            ClipboardHistory.Push(value)
        }
        TopMenuCountRecord:=[]

        ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
        Loop, % ClipboardHistory.MaxIndex()
            IniWrite % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

        ; 如果有记录则先清空旧条目再生成新条目
        if (ClipboardAlreadyRecorded=1)
            Menu ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        RefreshMenu()
        ClipboardAlreadyRecorded:=1

        loop 50
        {
            ToolTip 已撤回至上次操作
            Sleep 30
        }
        ToolTip
    }
Return

回收站:
    if (FileExist(A_ScriptDir . "\HistoryRecycleBin.txt"))
        Run %A_ScriptDir%\HistoryRecycleBin.txt
    else
    {
        FileAppend, , %A_ScriptDir%\HistoryRecycleBin.txt
        Sleep 500
        Run %A_ScriptDir%\HistoryRecycleBin.txt
    }
Return

清空回收站:
    MsgBox 4, 清空回收站,  是否清空回收站吗?`n此操作不可逆! ;询问是否清空回收站
    ifMsgBox Yes
    {
        if (FileExist(A_ScriptDir . "\HistoryRecycleBin.txt"))
        {
            FileDelete %A_ScriptDir%\HistoryRecycleBin.txt
        }
        ; 创建空白的回收站记录
        FileAppend, , %A_ScriptDir%\HistoryRecycleBin.txt

        loop 50
        {
            ToolTip 回收站已清空
            Sleep 30
        }
        ToolTip
    }
Return

写入回收站:
    InputRecycleBin(InputString)
Return

InputRecycleBin(InputStr)
{
    if (FileExist(A_ScriptDir . "\HistoryRecycleBin.txt"))
    {
        FileRead StringRecord, %A_ScriptDir%\HistoryRecycleBin.txt ; 读取以前的回收站记录
        Trim(StringRecord, " `t`n`r") ; 去掉前后空格和换行符

        FileDelete %A_ScriptDir%\HistoryRecycleBin.txt ; 删除以前的回收站记录

        NewString:= "时间: " . A_YYYY . "年" . A_MM . "月" . A_DD . "日 " . A_Hour . ":" . A_Min . ":" . A_Sec . "`n" . InputStr . "`n`n" . StringRecord  ; 存入新记录前先记录时间

        FileAppend %NewString%, %A_ScriptDir%\HistoryRecycleBin.txt ; 添加新的回收站记录
        Return 1
    }
    else
        Return 0
}

重启软件:
Reload
Return

退出软件:
ExitApp
Return

; 为什么不用OnClipboardChange:文本操作都是用剪贴板实现的 我们只记录快捷键产生的剪贴板内容

; 监听 Ctrl+C 或 Ctrl+X 事件以保存剪贴板内容 在最前面加~不会劫持按键
~$^c::
~$^x::
    ; 不在白名单内不添加到剪贴板内
    GoSub, 白名单
    if (白名单=0)
        Return

    ; 等待新内容复制进来
    ClipWait 1
    ClipboardGetTickCount:=A_TickCount
    Loop
    {
        if (A_Clipboard!=UserClipboardRecord) ; 新内容和旧内容不一样
            Break
        Else if (A_TickCount-ClipboardGetTickCount>200) ; 超时
            Break

        Sleep 30
    }

    ; 确保不是空内容
    if (RegExMatch(A_Clipboard, "^\s*$"))
    {
        UserClipboardRecord:=A_Clipboard ; 记录用户复制的剪贴板内容
        return
    }
    else
        UserClipboardRecord:=A_Clipboard ; 记录用户复制的剪贴板内容

    ; 修改前记录上次的的剪贴板历史
    ClipboardHistoryRecord:=[]
    for index, value in ClipboardHistory
    {
        ClipboardHistoryRecord.Push(value)
    }
    TopMenuCountRecord:=TopMenuCount

    ; 检查是否已经存在相同的条目, 将重复的条目移到最上面
    if (ClipboardHistory!="") and (ClipboardHistory.Length()!=0) and (ClipboardAlreadyRecorded=1)
    {
        for index, entry in ClipboardHistory
        {
            if (entry = A_Clipboard)
            {
                ; ToolTip A_Index%A_Index%
                If (A_Index<=TopMenuCount) ; 是顶置菜单
                {
                    ; 获取菜单内容和序号x
                    MoveClipboard := ClipboardHistory[A_Index]
                    ; 删除
                    ClipboardHistory.RemoveAt(A_Index)
                    ; 添加到顶部
                    ClipboardHistory.InsertAt(1, MoveClipboard)
                }
                Else ;不是顶置菜单
                {
                    ; 获取菜单内容和序号
                    MoveClipboard := ClipboardHistory[A_Index]
                    ; 删除
                    ClipboardHistory.RemoveAt(A_Index)
                    ; 添加到顶部
                    ClipboardHistory.InsertAt(TopMenuCount+1, MoveClipboard)
                }

                ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
                Loop, % ClipboardHistory.MaxIndex()
                    IniWrite % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

                ; 删除GUI菜单
                Menu ClipboardHistoryMenu, DeleteAll

                ; 重新加载菜单
                RefreshMenu()
                Return
            }
        }
    }

    ; 限制历史记录大小为MaxItem个条目
    if (ClipboardHistory.MaxIndex() = MaxItem)
    {
        ExceedClipboard:=ClipboardHistory[ClipboardHistory.MaxIndex()]
        ; ToolTip, %ExceedClipboard%
        InputRecycleBin(ExceedClipboard) ; 删除的内容存入回收站

        ClipboardHistory.RemoveAt(MaxItem) ; 删除最后一个条目
    }

    ; 添加新的剪贴板条目到历史记录数组
    ClipboardHistory.InsertAt(TopMenuCount+1, Clipboard)

    ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
    Loop, % ClipboardHistory.MaxIndex()
        IniWrite % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

    ; 如果有记录则先清空旧条目再生成新条目
    if (ClipboardAlreadyRecorded=1)
        Menu ClipboardHistoryMenu, DeleteAll

    ; 重新加载菜单
    RefreshMenu()
    ClipboardAlreadyRecorded:=1
return

; 显示剪贴板历史供用户选择
中键:
!v:: ; 使用 Alt+V 键作为触发显示剪贴板历史的快捷键

    ; 记录菜单显示位置
    MouseGetPos MouseInScreenX, MouseInScreenY
    ; ToolTip, MouseInScreenX%MouseInScreenX%`nMouseInScreenY%MouseInScreenY%
    if (ClipboardAlreadyRecorded=1)
        Menu ClipboardHistoryMenu, Show
return

; 当用户从菜单选择一项时黏贴剪贴板内容
ClickTheHistoryRecord:
    ExistTopMenu := (TopMenuCount > 0) ? true : false
    If GetKeyState("Rbutton", "P") ; 右键 顶置所选菜单
    {
        ; 修改前记录上次的的剪贴板历史
        ClipboardHistoryRecord:=[]
        for index, value in ClipboardHistory
        {
            ClipboardHistoryRecord.Push(value)
        }
        TopMenuCountRecord:=TopMenuCount

        If (A_ThisMenuItemPos<=TopMenuCount) ; 点击的是右键 顶置所选菜单
        {
            If (TopMenuCount>=1)
                TopMenuCount := TopMenuCount-1
            IniWrite %TopMenuCount%, History.ini, Settings, TopMenuCount

            ; 获取菜单内容和序号
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos]
            OldTopClipboardPos := A_ThisMenuItemPos
            NewTopClipboardPos := TopMenuCount+1
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos)
            ; 添加到顶部
            ClipboardHistory.InsertAt(TopMenuCount+1, TopClipboard)
        }
        Else ;不是顶置菜单 添加到新的
        {
            if (TopMenuCount<ClipboardHistory.MaxIndex())
                TopMenuCount := TopMenuCount+1
            IniWrite %TopMenuCount%, History.ini, Settings, TopMenuCount

            ; 获取菜单内容和序号
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu]
            OldTopClipboardPos := A_ThisMenuItemPos-ExistTopMenu
            NewTopClipboardPos := 1
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos-ExistTopMenu)
            ; 添加到顶部
            ClipboardHistory.InsertAt(1, TopClipboard)
        }

        ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
        Loop, % ClipboardHistory.MaxIndex()
            IniWrite % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

        ; 删除GUI菜单
        Menu ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        RefreshMenu()

        ; 在上次显示菜单位置显示
        Menu ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
        KeyWait LButton
    }
    Else If GetKeyState("Xbutton2", "P") ; 侧键上 向上移动所选菜单
    {
        ; 修改前记录上次的的剪贴板历史
        ClipboardHistoryRecord:=[]
        for index, value in ClipboardHistory
        {
            ClipboardHistoryRecord.Push(value)
        }
        TopMenuCountRecord:=TopMenuCount

        If (A_ThisMenuItemPos<=TopMenuCount) and (A_ThisMenuItemPos>1) ; 点击的是是顶置菜单 向上移动所选菜单
        {
            ; 获取菜单内容和序号
            MoveClipboard := ClipboardHistory[A_ThisMenuItemPos]
            OldMoveClipboardPos := A_ThisMenuItemPos
            NewMoveClipboardPos := A_ThisMenuItemPos-1
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos)
            ; 添加到上一Pos
            ClipboardHistory.InsertAt(A_ThisMenuItemPos-1, MoveClipboard)
        }
        Else If (A_ThisMenuItemPos-ExistTopMenu>TopMenuCount+1) ;不是顶置菜单 向上移动所选菜单
        {
            ; 获取菜单内容和序号
            MoveClipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu]
            OldMoveClipboardPos := A_ThisMenuItemPos-ExistTopMenu
            NewMoveClipboardPos := A_ThisMenuItemPos-1-ExistTopMenu
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos-ExistTopMenu)
            ; 添加到上一Pos
            ClipboardHistory.InsertAt(A_ThisMenuItemPos-1-ExistTopMenu, MoveClipboard)
        }
        Else
        {
            ; 在上次显示菜单位置显示
            Menu ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
            KeyWait LButton
            return ; 菜单不可向上移动
        }

        ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
        Loop, % ClipboardHistory.MaxIndex()
            IniWrite % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

        ; 删除GUI菜单
        Menu ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        RefreshMenu()

        ; 在上次显示菜单位置显示
        Menu ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
        KeyWait LButton
    }
    Else If GetKeyState("Xbutton1", "P") ; 侧键下 向下移动所选菜单
    {
        ; 修改前记录上次的的剪贴板历史
        ClipboardHistoryRecord:=[]
        for index, value in ClipboardHistory
        {
            ClipboardHistoryRecord.Push(value)
        }
        TopMenuCountRecord:=TopMenuCount

        If (A_ThisMenuItemPos<TopMenuCount) and (A_ThisMenuItemPos<TopMenuCount) ; 点击的是是顶置菜单 向下移动所选菜单
        {
            ; 获取菜单内容和序号
            MoveClipboard := ClipboardHistory[A_ThisMenuItemPos]
            OldMoveClipboardPos := A_ThisMenuItemPos
            NewMoveClipboardPos := A_ThisMenuItemPos+1
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos)
            ; 添加到上一Pos
            ClipboardHistory.InsertAt(A_ThisMenuItemPos+1, MoveClipboard)
        }
        Else If (A_ThisMenuItemPos-ExistTopMenu>TopMenuCount) and (A_ThisMenuItemPos-ExistTopMenu<ClipboardHistory.MaxIndex()) ;不是顶置菜单 向下移动所选菜单
        {
            ; 获取菜单内容和序号
            MoveClipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu]
            OldMoveClipboardPos := A_ThisMenuItemPos-ExistTopMenu
            NewMoveClipboardPos := A_ThisMenuItemPos+1-ExistTopMenu
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos-ExistTopMenu)
            ; 添加到上一Pos
            ClipboardHistory.InsertAt(A_ThisMenuItemPos+1-ExistTopMenu, MoveClipboard)
        }
        Else
        {
            ; 在上次显示菜单位置显示
            Menu ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
            KeyWait LButton
            return ; 菜单不可向下移动
        }

        ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
        Loop, % ClipboardHistory.MaxIndex()
            IniWrite % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

        ; 删除GUI菜单
        Menu ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        RefreshMenu()

        ; 在上次显示菜单位置显示
        Menu ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
        KeyWait LButton
    }
    Else If GetKeyState("Ctrl", "P") ; Ctrl 删除所选菜单
    {
        ; 删除前记录上次的的剪贴板历史
        ClipboardHistoryRecord:=[]
        for index, value in ClipboardHistory
        {
            ClipboardHistoryRecord.Push(value)
        }
        TopMenuCountRecord:=TopMenuCount

        If (A_ThisMenuItemPos<=TopMenuCount) ; 点击的是是顶置菜单
        {
            If (TopMenuCount>=1)
                TopMenuCount := TopMenuCount-1
            IniWrite %TopMenuCount%, History.ini, Settings, TopMenuCount

            ; 获取菜单内容和序号
            DeleteClipboard := ClipboardHistory[A_ThisMenuItemPos]
            DeleteClipboardPos:=A_ThisMenuItemPos
            TopMenuCountRecord:=TopMenuCount
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos)
        }
        Else ;不是顶置菜单 删除所选菜单
        {
            ; 获取菜单内容和序号
            DeleteClipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu]
            DeleteClipboardPos := A_ThisMenuItemPos-ExistTopMenu
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos-ExistTopMenu)
        }

        ; ToolTip %DeleteClipboard%
        ; 删除的内容存入回收站 因为菜单显示的时候线程是被阻塞的 所以这里用定时器
        InputString := DeleteClipboard
        SetTimer 写入回收站, -1

        ; 清除ini文件
        Loop %MaxItem%
            IniWrite "", History.ini, History, ClipboardHistory%A_Index%

        ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
        Loop, % ClipboardHistory.MaxIndex()
            IniWrite % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

        ; 删除GUI菜单
        Menu ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        RefreshMenu()

        ; 在上次显示菜单位置显示
        Menu ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
        KeyWait LButton
    }
    Else ; 按下的时候没有按住任何键 黏贴内容
    {
        ; Clipboard := ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_ThisMenuItemPos] ;逆序
        ; ToolTip, A_ThisMenuItemPos%A_ThisMenuItemPos%

        If (A_ThisMenuItemPos<=TopMenuCount) ; 点击的是是顶置菜单
            Clipboard := ClipboardHistory[A_ThisMenuItemPos] ;顺序
        Else
            Clipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu] ;顺序

        BlockInput On
        Send ^v ; 自动粘贴选中的历史项
        BlockInput Off
    }
return

^+d:: ; Ctrl + Shift + D 用于清除历史记录
    ; 删除前记录上次的的剪贴板历史
    ClipboardHistoryRecord:=[]
    for index, value in ClipboardHistory
    {
        ClipboardHistoryRecord.Push(value)
    }
    TopMenuCountRecord:=TopMenuCount

    ; 删除的剪贴板记录存入回收站
    Loop % ClipboardHistory.MaxIndex()
    {
        InputRecycleBin(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index]) ; 删除的内容存入回收站
    }

    ; 清除数组
    ClipboardHistory:=[]

    ; 清除GUI菜单
    if (ClipboardAlreadyRecorded=1)
    {
        Menu ClipboardHistoryMenu, DeleteAll
        ClipboardAlreadyRecorded:=0
    }

    ; 清除ini文件
    Loop %MaxItem%
        IniWrite "", History.ini, History, ClipboardHistory%A_Index%

    ; 清除顶置菜单配置
    TopMenuCount:=0
    IniWrite %TopMenuCount%, History.ini, Settings, TopMenuCount

    Loop, 30
    {
        ToolTip 剪贴板历史已清除
        Sleep 30
    }
    ToolTip
return

; 如果你需要添加白名单请复制并填入对应的进程名
#If WinActive("ahk_exe Code.exe") or WinActive("ahk_exe Notepad--.exe") ; 以下代码只在指定软件内运行
RShift & ]::
    BlockInput On
    ClipboardBefore:=A_Clipboard
    Send {Shift Up}
    Sleep 50
    send ^x
    Send {Ctrl Up}

    ClipWait 1
    ClipboardGetTickCount:=A_TickCount
    Loop
    {
        if (A_Clipboard!=ClipboardBefore) ; 新内容和旧内容不一样
            Break
        Else if (A_TickCount-ClipboardGetTickCount>100) ; 超时
        {
            BlockInput off
            return
        }

        Sleep 10
    }

    ; 确保不是空内容
    if (RegExMatch(A_Clipboard, "^\s*$"))
    {
        UserClipboardRecord:=A_Clipboard ; 记录用户复制的剪贴板内容
        BlockInput off
        return
    }

    ClipboardChoosed:=A_Clipboard
    FirstCRLF:=InStr(ClipboardChoosed, "`r`n")
    if (FirstCRLF=1) ; 如果第一个字符是换行符 则从下一行开始生成代码块
    {
        Send {Enter}
        NewClipboard:="{" . ClipboardChoosed
    }
    Else ;if (FirstCRLF!=1) ; 如果第一个字符不是换行符 则在第一个花括号后换行
    {
        NewClipboard:="{`r`n" . ClipboardChoosed
    }

    EndCRLF:=InStr(ClipboardChoosed, "`r`n", ,0)
    All:=StrLen(ClipboardChoosed)
    ; ToolTip EndCRLF%EndCRLF% All%All%
    if (EndCRLF=StrLen(ClipboardChoosed)-1) ; 如果最后一个字符是换行符 则直接添加花括号再添加换行符
    {
        NewClipboard .= "}`r`n"
    }
    Else ;if (EndCRLF!=StrLen(ClipboardChoosed)-1) ; 如果最后一个字符不是换行符 则先添加换行符再添加花括号
    {
        NewClipboard .= "`r`n}"
    }

    OutputClipboardRecord := NewClipboard ; 此处需要更新生成内容参数的剪贴板历史记录
    Clipboard:=NewClipboard
    send ^v
    Sleep 50
    Send +!{f}
    Clipboard:=UserClipboardRecord
    BlockInput off
    KeyWait RShift
    Send {RShift Up}
Return

^d::
    BlockInput On
    ClipboardBefore:=A_Clipboard
    Send ^c ; 复制选择的内容
    Send {Ctrl Up}

    ; 等待新内容复制进来
    ClipWait 1
    ClipboardGetTickCount:=A_TickCount
    Loop
    {
        if (A_Clipboard!=ClipboardBefore) ; 新内容和旧内容不一样
            Break
        Else if (A_TickCount-ClipboardGetTickCount>100) ; 超时
        {
            BlockInput off
            return
        }

        Sleep 10
    }

    ; 确保不是空内容
    if (RegExMatch(A_Clipboard, "^\s*$"))
    {
        UserClipboardRecord:=A_Clipboard ; 记录用户复制的剪贴板内容
        BlockInput off
        return
    }

    ClipboardChoosed:=A_Clipboard
    if (InStr(ClipboardChoosed, "`r`n")<=0) ;没有换行
    {
        if (InStr(ClipboardChoosed, "(")=1) and (StrLen(ClipboardChoosed)>1) and (InStr(ClipboardChoosed, ")", , 0)=StrLen(ClipboardChoosed)) ; 前面有括号 不止一个字符 最后一个是括号
        {
            send {End 2}
            send {Shift Down}
            send {Home 2}
            send {Shift Up}
            Send ^c ; 复制选择的内容

            ClipWait 1
            if (ErrorLevel || A_Clipboard = "")
            {
                BlockInput off
                return
            }

            ; 等待新内容复制进来
            ClipboardGetTickCount:=A_TickCount
            Loop
            {
                if (A_Clipboard!=ClipboardChoosed) ; ClipboardChoosed
                    Break
                Else if (A_TickCount-ClipboardGetTickCount>100) ; 超时
                {
                    BlockInput off
                    return
                }

                Sleep 10
            }

            NewClipboardStart := SubStr(A_Clipboard, 1, InStr(A_Clipboard, ClipboardChoosed)+StrLen(ClipboardChoosed)-1) ; 提取选择内容及选择内容之前的字符串
            NewClipboardEnd := SubStr(A_Clipboard, InStr(A_Clipboard, ClipboardChoosed)+StrLen(ClipboardChoosed)) ; 提取选择内容之后的字符串
            NewClipboard := NewClipboardStart ; 新的剪贴板导入之前的字符串

            CopyTimes:=1
            CopyCount:=A_TickCount
            loop ; 记录复制次数
            {
                ToolTip CopyTimes%CopyTimes%
                if GetKeyState("D", "P")
                {
                    if (A_Index>1)
                        CopyTimes+=1
                    loop
                    {
                        ToolTip CopyTimes%CopyTimes%
                        if !GetKeyState("D", "P")
                        {
                            CopyCount:=A_TickCount
                            Break
                        }
                        sleep 30
                    }
                }
                Else if (A_TickCount-CopyCount>700)
                    Break
                sleep 30
            }

            loop %CopyTimes% ; 根据复制次数，将选择内容导入新剪贴板
            {
                if (InStr(A_Clipboard, ") || (")!=0) or (InStr(A_Clipboard, ")||(")!=0) or (InStr(A_Clipboard, ") ||(")!=0) or (InStr(A_Clipboard, ")|| (")!=0)
                    NewClipboard .= " || "
                Else if (InStr(A_Clipboard, ") or (")!=0) or (InStr(A_Clipboard, ")or(")!=0) or (InStr(A_Clipboard, ")or (")!=0) or (InStr(A_Clipboard, ") or(")!=0)
                    NewClipboard .= " or "
                Else if (InStr(A_Clipboard, ") && (")!=0) or (InStr(A_Clipboard, ")&&(")!=0) or (InStr(A_Clipboard, ")&& (")!=0) or (InStr(A_Clipboard, ") &&(")!=0)
                    NewClipboard .= " && "
                Else ;if (InStr(A_Clipboard, ") and (")!=0) or (InStr(A_Clipboard, ")and(")!=0) or (InStr(A_Clipboard, ")and (")!=0) or (InStr(A_Clipboard, ") and(")!=0)
                    NewClipboard .= " and "

                NewClipboard .= ClipboardChoosed
            }

            NewClipboard .= NewClipboardEnd ; 新的剪贴板导入之后的字符串
            BlockInput off
            Clipboard := NewClipboard ; 剪贴板写入新的剪贴板

            ; If (Start) or (Test123) or (End)
            ; If (Start) and (Test456) and (End)
            ; If (Start) and (函数(ABC)>1+2+3) and (End)

            Send ^v ; ClipboardChoosed
            ; ToolTip Start%NewClipboardStart%`nEnd%NewClipboardEnd%

            loop 30
            {
                ToolTip CopyTimes%CopyTimes%
                Sleep 30
            }
            ToolTip
        }
        Else
        {    
            Clipboard .= ClipboardChoosed
            Send ^v ; ClipboardChoosed
        }
        ; ToolTip 没有换行
    }
    Else ; 存在换行
    {
        ; 计算换行的数量
        CRLFcount := 0
        pos := 1
        while pos <= StrLen(A_Clipboard) {
            foundPos := InStr(A_Clipboard, "`r`n", , pos)
            if (foundPos = 0)
                break ; 没有更多匹配项时退出循环
            CRLFcount += 1
            pos := foundPos + 2 ; 更新位置以避免重复计数，并跳过已计数的CR-LF序列
        }
        ; FirstCRLF:=InStr(ClipboardChoosed, "`r`n")
        ; ToolTip, CRLFcount%CRLFcount%`nFirstCRLF%FirstCRLF%

        if (CRLFcount=1) ; 只有一个换行 且在开头 跳转到结尾后向下复制
        {
            ; ToolTip % InStr(ClipboardChoosed, "`r`n")
            if (InStr(ClipboardChoosed, "`r`n")=1)
            {
                Send {End}
                Sleep 100
            }
            Send {Shift Down}
            Send {Alt Down}
            Sleep 100
            Send {Down}
            Send {Shift up}
            Send {Alt up}
        }
        Else if (CRLFcount>1) ; 多个换行
        {
            Send {Shift Down}
            FirstCRLF:=InStr(ClipboardChoosed, "`r`n")
            if (FirstCRLF=1) ; 如果第一个字符是换行符 此行不复制向下选择一行
            {
                Send {Right}
                Sleep 100
            }
            Send {Alt Down}
            Sleep 100
            Send {Down}
            Send {Shift up}
            Send {Alt up}

            NewClipboard:=StrReplace(ClipboardChoosed, "`r`n") ; 去掉复制内容中的CRLF换行
            NewClipboard:=RegExReplace(ClipboardChoosed, "\s", "") ; 去掉复制内容中的空格

            FirstBrace:=InStr(NewClipboard, "{")
            EndBrace:=InStr(NewClipboard, "}", , 0)
            ; NewClipboardMax:=StrLen(NewClipboard)
            ; ToolTip, %NewClipboard%`nFirstBrace%FirstBrace% EndBrace%EndBrace% NewClipboardMax%NewClipboardMax%
            if (FirstBrace=1) and (EndBrace=StrLen(NewClipboard)) ; 如果复制内容是代码块 在代码块前加else
            {
                Sleep 100
                Send {Up}
                Send {End}
                Send {Enter}
                Send {Text}else
                Send {Tab}
            }

            IfCodeSection:=InStr(NewClipboard, "if") ; 如果复制内容开头是if 在代码块前加else if并保持同样格式
            if (IfCodeSection=1)
            {
                Sleep 100
                Send {End}
                Send {Home}
                Send {Text}else
                Send {space}
            }
        }
    }
    OutputClipboardRecord := NewClipboard ; 此处需要更新生成内容参数的剪贴板历史记录
    Clipboard:=UserClipboardRecord
    Sleep 50
    BlockInput Off
    KeyWait Ctrl
    Send {Ctrl Up}
Return

$Enter::
    Send {Enter Up}
    BlockInput On
    EnterDown:=A_TickCount
    loop
    {
        if !GetKeyState("Enter", "P")
        {
            KeyWait Enter
            Send {Enter}
            Break
        }
        if (A_TickCount-EnterDown>300)
        {
            Send {Shift Down}
            Sleep 50
            Send {End}
            Send {Shift up}
            Send {Enter}
            KeyWait Enter
            Break
        }
    }
    BlockInput Off
Return

; 打开中文帮助并跳转至对应文档
; 功能修改自 智能F1 https://github.com/telppa/SciTE4AutoHotkey-Plus/tree/master
F1::
    BlockInput On
    ClipboardBefore:=A_Clipboard
    Send ^c
    BlockInput Off

    ; 等待新内容复制进来
    ClipboardGetTickCount:=A_TickCount
    Loop
    {
        if (A_Clipboard!=ClipboardBefore) ; 新内容和旧内容不一样
            Break
        Else if (A_TickCount-ClipboardGetTickCount>200) ; 超时
            Return
        Sleep 30
    }

    AutoHotKeyHelpPath:=A_ScriptDir . "\AutoHotkey.chm"
    if (PID="") or (PID="ERROR") or (WinExist("ahk_pid "PID)=0)                           ; 首次打开或窗口被最小化（为0）或窗口被关闭（为空）。
    {
        Run % AutoHotKeyHelpPath,,,PID                          ; 打开帮助文件。
        IniWrite %PID%, History.ini, Settings, 智能帮助ID ; 记录PID到ini文件
        WinWait ahk_pid %PID%                             ; 这行不能少，否则初次打开无法输入文本并搜索。
        WinActivate ahk_pid %PID%                         ; 这行不能少，否则初次打开无法输入文本并搜索。
        SysGet WorkArea, MonitorWorkArea, 1               ; 获取工作区尺寸，即不含任务栏的屏幕尺寸。
        DPIScale:=A_ScreenDPI/96
        W:=Round((WorkAreaRight-WorkAreaLeft)//3/120)*120
        X:=WorkAreaRight-W-(-1+8)*DPIScale
        Y:=WorkAreaTop
        H:=WorkAreaBottom-Y+(-1+8)*DPIScale
        WinMove ahk_pid %PID%,, X, Y, W, H                ; 显示在屏幕右侧并占屏幕一半尺寸。
        oWB:=IE_GetWB(PID).document                        ; 获取帮助文件的对象。
    }
    Else
    {
        WinGetPos X, Y, W, H, ahk_pid %PID%
        if (X+Y+W+H=0) ; 帮助窗口最小化后无法激活，所以只能杀掉重开。
            Process Close, %PID%
    }
    WinActivate ahk_pid %PID%                           ; 激活。
    WinClose 查找 ahk_pid %PID%                         ; 关掉查找窗口，它存在会无法切换结果。

    oWB.getElementsByTagName("BUTTON")[2].click()        ; 索引按钮。
    oWB.querySelector("INPUT").value := A_Clipboard             ; 输入关键词。
    ControlSend, , {Enter}{Enter}, ahk_pid %PID%         ; 按两下回车进行搜索。
    oWB.getElementsByTagName("BUTTON")[1].click()        ; 目录按钮。
    Clipboard:=UserClipboardRecord
Return

IE_GetWB(PID) { ; get the parent windows & coord from the element
    IID_IWebBrowserApp := "{0002DF05-0000-0000-C000-000000000046}"
        , IID_IHTMLWindow2 := "{332C4427-26CB-11D0-B483-00C04FD90119}"

    WinGet ControlListHwnd, ControlListHwnd, ahk_pid %PID%
    for k, v in StrSplit(ControlListHwnd, "`n", "`r")
    {
        WinGetClass sClass, ahk_id %v%
        if (sClass = "Internet Explorer_Server")
        {
            hCtl := v
            break
        }
    }

    if !(sClass == "Internet Explorer_Server")
        ; document property will fail if no valie com object
            or !(oDoc := ComObject(9, ComObjQuery(Acc_ObjectFromWindow(hCtl), IID_IHTMLWindow2, IID_IHTMLWindow2), 1).document)
        return

    oWin := ComObject(9, ComObjQuery(oDoc, IID_IHTMLWindow2, IID_IHTMLWindow2), 1)
    return, oWB := ComObject(9, ComObjQuery(oWin, IID_IWebBrowserApp, IID_IWebBrowserApp), 1)
}

Acc_Init()
{
    Static  h
    If Not  h
        h:=DllCall("LoadLibrary","Str","oleacc","Ptr")
}

Acc_ObjectFromWindow(hWnd, idObject = -4)
{
    Acc_Init()
    If  DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", hWnd, "UInt", idObject&=0xFFFFFFFF, "Ptr", -VarSetCapacity(IID,16)+NumPut(idObject==0xFFFFFFF0?0x46000000000000C0:0x719B3800AA000C81,NumPut(idObject==0xFFFFFFF0?0x0000000000020400:0x11CF3C3D618736E0,IID,"Int64"),"Int64"), "Ptr*", pacc)=0
        Return  ComObjEnwrap(9,pacc,1)
}

b64Encode(string)
{
    VarSetCapacity(bin, StrPut(string, "UTF-8")) && len := StrPut(string, &bin, "UTF-8") - 1 
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", 0, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    VarSetCapacity(buf, size << 1, 0)
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", &buf, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    return StrGet(&buf)
}

b64Decode(string)
{
    if !(DllCall("crypt32\CryptStringToBinary", "ptr", &string, "uint", 0, "uint", 0x1, "ptr", 0, "uint*", size, "ptr", 0, "ptr", 0))
        throw Exception("CryptStringToBinary failed", -1)
    VarSetCapacity(buf, size, 0)
    if !(DllCall("crypt32\CryptStringToBinary", "ptr", &string, "uint", 0, "uint", 0x1, "ptr", &buf, "uint*", size, "ptr", 0, "ptr", 0))
        throw Exception("CryptStringToBinary failed", -1)
    return StrGet(&buf, size, "UTF-8")
}

!x::
    if (Base64编解码!=1) and (颜色转换!=1)
        Return

    BlockInput On
    ClipboardBefore:=A_Clipboard
    Send ^c ; 复制选择的内容
    Send {Ctrl Up}
    ; 等待新内容复制进来
    ClipWait 1
    ClipboardGetTickCount:=A_TickCount
    Loop
    {
        if (A_Clipboard!=ClipboardBefore) ; 新内容和旧内容不一样
            Break
        Else if (A_TickCount-ClipboardGetTickCount>100) ; 超时
        {
            BlockInput off
            return
        }

        Sleep 10
    }

    ; 确保不是空内容
    if (RegExMatch(A_Clipboard, "^\s*$"))
    {
        UserClipboardRecord:=A_Clipboard ; 记录用户复制的剪贴板内容
        BlockInput off
        return
    }

    HotMenuClipboardChoosed:=A_Clipboard
    HotMenuClipboardChoosed:=StrReplace(HotMenuClipboardChoosed, "`r`n") ; 去掉复制内容中的CRLF换行
    HotMenuClipboardChoosed:=RegExReplace(HotMenuClipboardChoosed, "\s", "") ; 去掉复制内容中的空格
    BlockInput Off
    Menu HotTray, Show
Return

Encode:
    B64Text:=HotMenuClipboardChoosed
    B64Text:=b64Encode(B64Text)
    B64Text:=StrReplace(B64Text, "`r`n")
    Clipboard:=B64Text
    Send ^v
    Sleep 100
    Clipboard:=UserClipboardRecord
    OutputClipboardRecord := B64Text ; 此处需要更新生成内容参数的剪贴板历史记录
Return

Decode:
    B64Text:=HotMenuClipboardChoosed
    B64Text:=b64Decode(B64Text)
    B64Text:=StrReplace(B64Text, "`r`n")
    Clipboard:=B64Text
    Send ^v
    Sleep 100
    Clipboard:=UserClipboardRecord
    OutputClipboardRecord := B64Text ; 此处需要更新生成内容参数的剪贴板历史记录
Return

; 示例颜色值
color := "0xFF5733" ; 16进制颜色值 RGB
color := "FF5733" ; 16进制颜色值 RGB
color := "0xFF57331c" ; 16进制颜色值 RGBA
color := "FF57331c" ; 16进制颜色值 RGBA
color := "255,87,51" ; 10进制颜色值 RGB
color := "255,87,51,28" ; 10进制RGBA颜色值 RGBA

RGB_Transform:
    if (Substr(HotMenuClipboardChoosed, 1, 2) = "0x")
        ColorText:=StrReplace(HotMenuClipboardChoosed, "0x") ; 去掉16进制颜色值前缀
    else
        ColorText:=HotMenuClipboardChoosed

    if (IsHexColor(ColorText)) ; 如果是16进制颜色值
    {
        ; ToolTip 如果是16进制颜色值 %ColorText%
        ColorText := HexToRGB(ColorText)
    }
    else ; 如果是10进制颜色值
    {
        ; ToolTip 如果是10进制颜色值 %ColorText%
        ColorText := "0x" . RGBToHex(ColorText)
    }
    Clipboard:=ColorText
    Send ^v
    Sleep 100
    Clipboard:=UserClipboardRecord
    OutputClipboardRecord := B64Text ; 此处需要更新生成内容参数的剪贴板历史记录
Return

IsHexColor(color) ; 判断是否是16进制颜色值
{
    return RegExMatch(color, "^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$") ; 16进制颜色值返回1 否则0
}

HexToRGB(color) ; 16进制颜色值转10进制颜色值
{
    hex := "0x" . color

    if (StrLen(color) = 8)
    {
        ; RGBA
        r := (hex >> 24) & 0xFF
        g := (hex >> 16) & 0xFF
        b := (hex >> 8) & 0xFF
        a := hex & 0xFF
        return Format("{1}, {2}, {3}, {4}", r, g, b, a)
    }
    else
    {
        ; RGB
        r := (hex >> 16) & 0xFF
        g := (hex >> 8) & 0xFF
        b := hex & 0xFF
        return Format("{1}, {2}, {3}", r, g, b)
    }
}

RGBToHex(color) ; 10进制颜色值转16进制颜色值
{
    SplitColor := StrSplit(color, ",")
    r := Format("{:02X}", SplitColor[1])
    g := Format("{:02X}", SplitColor[2])
    b := Format("{:02X}", SplitColor[3])
    if (SplitColor.Length() == 4)
    {
        a := Format("{:02X}", SplitColor[4])
        return r g b a
    }
    else
    {
        return r g b
    }
}

; 强制半角
$`::Send {Text}``
$[::Send {Text}[
$]::Send {Text}]
$;::Send {Text};
$'::Send {Text}'
$\::Send {Text}\
$,::Send {Text},
$.::Send {Text}.
$/::Send {Text}/
$+1::Send {Text}!
$+4::Send {Text}$
$+6::Send {Text}^
$+9::Send {Text}(
$+0::Send {Text})
$+-::Send {Text}_
$+[::Send {Text}{
$+]::Send {Text}}
$+;::Send {Text}:
$+'::Send {Text}"
$+,::Send {Text}<
$+.::Send {Text}>
$+/::Send {Text}?