/*
本AHK由 黑钨重工 制作 免费开源
唯一教程视频发布地址https://space.bilibili.com/52593606
所有开源项目 https://github.com/Furtory
AHK正版官方论坛https://www.autohotkey.com/boards/viewforum.php?f=26
国内唯一完全免费开源AHK论坛请到QQ频道AutoHotKey12
本人所有教程和脚本严禁转载到此收费论坛以防被用于收费盈利 https://www.autoahk.com/
*/

管理员模式:
    IfExist, %A_ScriptDir%\History.ini ;如果配置文件存在则读取
    {
        IniRead, AdminMode, History.ini, Settings, 管理权限
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

    SendMode, Event
    Process, Priority, , Realtime
    #MenuMaskKey vkE8
    #WinActivateForce
    #InstallKeybdHook
    #InstallMouseHook
    #Persistent
    #NoEnv
    #SingleInstance Force
    #MaxHotkeysPerInterval 2000
    #KeyHistory 2000
    CoordMode, Mouse, Screen
    CoordMode, Menu, Screen
    SetBatchLines -1
    SetKeyDelay, 30, 50 ; 按键按住时间 和 按键发送间隔 不宜太短 VS code 响应不过来

    Menu, Tray, Icon, %A_ScriptDir%\LOGO.ico
    Menu, Tray, NoStandard ;不显示默认的AHK右键菜单
    Menu, Tray, Add, 使用教程, 使用教程 ;添加新的右键菜单
    Menu, Tray, Add
    Menu, Tray, Add, 管理权限, 管理权限 ;添加新的右键菜单
    Menu, Tray, Add, 开机自启, 开机自启 ;添加新的右键菜单
    Menu, Tray, Add, 中键呼出, 中键呼出 ;添加新的右键菜单
    Menu, Tray, Add, 智能帮助, 智能帮助 ;添加新的右键菜单
    Menu, Tray, Add
    Menu, Tray, Add, 重启软件, 重启软件 ;添加新的右键菜单
    Menu, Tray, Add, 退出软件, 退出软件 ;添加新的右键菜单

    MaxItem:=30 ; 最大条目数量

    autostartLnk:=A_StartupCommon . "\ClipboardHistoryRecorder.lnk" ;开机启动文件的路径
    IfExist, % autostartLnk ;检查开机启动的文件是否存在
    {
        autostart:=1
        Menu, Tray, Check, 开机自启 ;右键菜单打勾
    }
    Else
    {
        autostart:=0
        Menu, Tray, UnCheck, 开机自启 ;右键菜单不打勾
    }

    ; 定义全局变量用于存储剪贴板历史
    ClipboardHistory := []

    IfExist, %A_ScriptDir%\History.ini
    {
        ; 读取剪贴板设置
        IniRead, AdminMode, Settings.ini, 设置, 管理权限 ;从ini文件读取设置
        if (AdminMode=0)
        {
            Menu, Tray, UnCheck, 管理权限 ;右键菜单不打勾
        }
        Else
        {
            Menu, Tray, Check, 管理权限 ;右键菜单打勾
        }

        IniRead, TopMenuCount, History.ini, Setting, TopMenuCount

        Hotkey, $Mbutton, 中键
        Iniread, 中键呼出, History.ini, Settings, 中键呼出 ;写入设置到ini文件
        if (中键呼出=1)
        {
            Menu, Tray, Check, 中键呼出 ;右键菜单打勾
        }
        Else
        {
            Hotkey, $Mbutton, Off
        }

        Iniread, 智能帮助, History.ini, Settings, 智能帮助 ;写入设置到ini文件
        if (智能帮助=1)
            Menu, Tray, Check, 智能帮助 ;右键菜单打勾
        Else
            Hotkey, $F1, Off

        ; 读取剪贴板历史
        ClipboardAlreadyRecorded:=1
        Loop %MaxItem% ; 最大条目数量
        {
            IniRead, ReadHistory, History.ini, History, ClipboardHistory%A_Index%
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
            Loop % ClipboardHistory.MaxIndex()
            {
                ; NewClipboard:=ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index] ;逆序
                NewClipboard:=ClipboardHistory[A_Index] ;顺序
                ; ToolTip, %A_Index%`nNewClipboard`n%NewClipboard%
                ; Sleep, 100
                if (StrLen(NewClipboard)>30) ;菜单名称限制字符串长度
                    NewClipboard:=SubStr(StrReplace(NewClipboard, "`r`n", ""), 1, 30) ; 去掉复制内容中的CRLF换行
                Menu, ClipboardHistoryMenu, Add, %NewClipboard%, ClipTheHistoryRecord, Radio ; 添加菜单

                if (A_Index<=TopMenuCount)
                    Menu, ClipboardHistoryMenu, Check, %NewClipboard% ; 给顶置菜单打上点作为标识

                if (A_Index=TopMenuCount)
                    Menu, ClipboardHistoryMenu, Add ; 顶置菜单和非顶置菜单之间增加一条分割线
            }
        }
    }
    Else
    {
        TopMenuCount:=0
        IniWrite, %TopMenuCount%, History.ini, Setting, TopMenuCount ;写入设置到ini文件

        AdminMode:=0
        IniWrite, %AdminMode%, History.ini, Settings, 管理权限 ;写入设置到ini文件

        中键呼出:=0
        IniWrite, %中键呼出%, History.ini, Settings, 中键呼出 ;写入设置到ini文件

        智能帮助:=0
        IniWrite, %智能帮助%, History.ini, Settings, 智能帮助 ;写入设置到ini文件
    }

    ; 软件初始运行时记录当前的剪贴板内容
    OldClipboardHistory := A_Clipboard
Return

使用教程:
    MsgBox, , 剪贴板历史记录使用教程, 剪贴板历史记录会保存在本地的History.ini内`n即使重启电脑也不会丢失剪贴板历史记录`n`n呼出剪贴板历史记录`n按下Alt+V打开剪贴板历史记录菜单`n你也可以在右键菜单中启用中键快捷呼出`n`n呼出后`n按住右键后再点击 可以顶置剪贴板历史记录`n按住侧键后再点击 可以上下调整剪贴板历史记录顺序`n按住Ctrl键后再点击 可以删除选中的剪贴板历史记录`n按下Ctrl + Shift + D 清除全部的剪贴板历史记录`n`nVS code专属功能`n按下Ctrl+D可以根据按下次数复制选中的内容`n你可以添加白名单让其他软件也可以使用`n`n按下F1可以自动打开AutoHotKey帮助并跳转到选中内容`n可指定编辑器内中文输入法下强制使用半角符号`n`n黑钨重工出品 免费开源`n更多免费软件请到QQ频道AutoHotKey12
return

管理权限: ;模式切换
    Critical, On
    if (AdminMode=1)
    {
        AdminMode:=0
        IniWrite, %AdminMode%, History.ini, Settings, 管理权限 ;写入设置到ini文件
        Menu, Tray, UnCheck, 管理权限 ;右键菜单不打勾
        Critical, Off
        Reload
    }
    Else
    {
        AdminMode:=1
        IniWrite, %AdminMode%, History.ini, Settings, 管理权限 ;写入设置到ini文件
        Menu, Tray, Check, 管理权限 ;右键菜单打勾
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
            FileDelete, %autostartLnk% ;删除开机启动的文件
        }

        autostart:=0
        Menu, Tray, UnCheck, 开机自启 ;右键菜单不打勾
    }
    Else ;开启开机自启动
    {
        IfExist, % autostartLnk ;如果开机启动的文件存在
        {
            FileGetShortcut, %autostartLnk%, lnkTarget ;获取开机启动文件的信息
            if (lnkTarget!=A_ScriptFullPath) ;如果启动文件执行的路径和当前脚本的完整路径不一致
            {
                FileCreateShortcut, %A_ScriptFullPath%, %autostartLnk%, %A_WorkingDir% ;将启动文件执行的路径改成和当前脚本的完整路径一致
            }
        }
        Else ;如果开机启动的文件不存在
        {
            FileCreateShortcut, %A_ScriptFullPath%, %autostartLnk%, %A_WorkingDir% ;创建和当前脚本的完整路径一致的启动文件
        }

        autostart:=1
        Menu, Tray, Check, 开机自启 ;右键菜单打勾
    }
    Critical, Off
return

中键呼出: ;模式切换
    Critical, On
    if (中键呼出=1)
    {
        中键呼出:=0
        Hotkey, $Mbutton, Off
        IniWrite, %中键呼出%, History.ini, Settings, 中键呼出 ;写入设置到ini文件
        Menu, Tray, UnCheck, 中键呼出 ;右键菜单不打勾
    }
    Else
    {
        中键呼出:=1
        Hotkey, $Mbutton, On
        IniWrite, %中键呼出%, History.ini, Settings, 中键呼出 ;写入设置到ini文件
        Menu, Tray, Check, 中键呼出 ;右键菜单打勾
    }
    Critical, Off
return

智能帮助: ;模式切换
    Critical, On
    if (智能帮助=1)
    {
        智能帮助:=0
        Hotkey, $F1, Off
        IniWrite, %Adm智能帮助inMode%, History.ini, Settings, 智能帮助 ;写入设置到ini文件
        Menu, Tray, UnCheck, 智能帮助 ;右键菜单不打勾

    }
    Else
    {
        智能帮助:=1
        Hotkey, $F1, On
        IniWrite, %智能帮助%, History.ini, Settings, 智能帮助 ;写入设置到ini文件
        Menu, Tray, Check, 智能帮助 ;右键菜单打勾
    }
    Critical, Off
return

重启软件:
Reload
Return

退出软件:
ExitApp
Return

; 为什么不用OnClipboardChange:文本操作都是用剪贴板实现的 我们只记录快捷键产生的剪贴板内容

; 监听 Ctrl+C 或 Ctrl+X 事件以保存剪贴板内容
~^c::
~^x::
    ; 确保不是空内容
    ClipWait 1
    if (ErrorLevel || Clipboard = "")
        return

    ; 等待新内容复制进来
    ClipboardGetTickCount:=A_TickCount
    Loop
    {
        if (A_Clipboard!=OldClipboardHistory) ; 新内容和旧内容不一样
            Break
        Else if (A_TickCount-ClipboardGetTickCount>1000) ; 超时
            Return

        Sleep, 30
    }
    OldClipboardHistory := A_Clipboard ; 此处需要更新记录用于下次对比

    ; 检查是否已经存在相同的条目，避免重复添加
    for index, entry in ClipboardHistory
        if (entry = Clipboard)
            return

        ; 限制历史记录大小为MaxItem个条目
        if (ClipboardHistory.MaxIndex() = MaxItem)
            ClipboardHistory.RemoveAt(MaxItem)

        ; 添加新的剪贴板条目到历史记录数组
        ClipboardHistory.InsertAt(TopMenuCount+1, Clipboard)

    ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
    Loop, % ClipboardHistory.MaxIndex()
        IniWrite, % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

    ; 如果有记录则先清空旧条目再生成新条目
    if (ClipboardAlreadyRecorded=1)
        Menu, ClipboardHistoryMenu, DeleteAll

    ; 添加历史记录数组为新条目到剪贴板历史GUI
    Loop % ClipboardHistory.MaxIndex()
    {
        ; NewClipboard:=ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index] ;逆序
        NewClipboard:=ClipboardHistory[A_Index] ;顺序
        if (StrLen(NewClipboard)>30) ;菜单名称限制字符串长度
            NewClipboard:=SubStr(NewClipboard, 1, 30)
        Menu, ClipboardHistoryMenu, Add, %NewClipboard%, ClipTheHistoryRecord, Radio ; 添加菜单

        if (A_Index<=TopMenuCount)
            Menu, ClipboardHistoryMenu, Check, %NewClipboard% ; 给顶置菜单打上点作为标识

        if (A_Index=TopMenuCount)
            Menu, ClipboardHistoryMenu, Add ; 顶置菜单和非顶置菜单之间增加一条分割线
    }
    ClipboardAlreadyRecorded:=1
return

; 显示剪贴板历史供用户选择
中键:
!v:: ; 使用 Alt+V 键作为触发显示剪贴板历史的快捷键
    ; 记录菜单显示位置
    MouseGetPos, MouseInScreenX, MouseInScreenY
    ; ToolTip, MouseInScreenX%MouseInScreenX%`nMouseInScreenY%MouseInScreenY%
    if (ClipboardAlreadyRecorded=1)
        Menu, ClipboardHistoryMenu, Show
return

; 当用户从菜单选择一项时黏贴剪贴板内容
ClipTheHistoryRecord:
    ExistTopMenu := (TopMenuCount > 0) ? true : false
    If GetKeyState("Rbutton", "P") ; 右键 顶置所选菜单
    {
        If (A_ThisMenuItemPos<=TopMenuCount) ; 点击的是右键 顶置所选菜单
        {
            If (TopMenuCount>=1)
                TopMenuCount := TopMenuCount-1
            IniWrite, %TopMenuCount%, History.ini, Setting, TopMenuCount

            ; 获取菜单内容
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos]
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos)
            ; 添加到顶部
            ClipboardHistory.InsertAt(TopMenuCount+1, TopClipboard)
        }
        Else ;不是顶置菜单 添加到新的
        {
            if (TopMenuCount<ClipboardHistory.MaxIndex())
                TopMenuCount := TopMenuCount+1
            IniWrite, %TopMenuCount%, History.ini, Setting, TopMenuCount

            ; 获取菜单内容
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu]
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos-ExistTopMenu)
            ; 添加到顶部
            ClipboardHistory.InsertAt(1, TopClipboard)
        }

        ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
        Loop, % ClipboardHistory.MaxIndex()
            IniWrite, % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

        ; 删除GUI菜单
        Menu, ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        Loop % ClipboardHistory.MaxIndex()
        {
            ; NewClipboard:=ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index] ;逆序
            NewClipboard:=ClipboardHistory[A_Index] ;顺序
            if (StrLen(NewClipboard)>30) ;菜单名称限制字符串长度
                NewClipboard:=SubStr(NewClipboard, 1, 30)
            Menu, ClipboardHistoryMenu, Add, %NewClipboard%, ClipTheHistoryRecord, Radio ; 添加菜单

            if (A_Index<=TopMenuCount)
                Menu, ClipboardHistoryMenu, Check, %NewClipboard% ; 给顶置菜单打上点作为标识

            if (A_Index=TopMenuCount)
                Menu, ClipboardHistoryMenu, Add ; 顶置菜单和非顶置菜单之间增加一条分割线
        }

        ; 在上次显示菜单位置显示
        Menu, ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
        KeyWait, LButton
    }
    Else If GetKeyState("Xbutton2", "P") ; 侧键上 向上移动所选菜单
    {
        If (A_ThisMenuItemPos<=TopMenuCount) and (A_ThisMenuItemPos>1) ; 点击的是是顶置菜单 向上移动所选菜单
        {
            ; 获取菜单内容
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos]
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos)
            ; 添加到上一Pos
            ClipboardHistory.InsertAt(A_ThisMenuItemPos-1, TopClipboard)
        }
        Else If (A_ThisMenuItemPos-ExistTopMenu>TopMenuCount+1) ;不是顶置菜单 向上移动所选菜单
        {
            ; 获取菜单内容
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu]
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos-ExistTopMenu)
            ; 添加到上一Pos
            ClipboardHistory.InsertAt(A_ThisMenuItemPos-1-ExistTopMenu, TopClipboard)
        }
        Else
        {
            ; 在上次显示菜单位置显示
            Menu, ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
            KeyWait, LButton
            return ; 菜单不可向上移动
        }

        ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
        Loop, % ClipboardHistory.MaxIndex()
            IniWrite, % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

        ; 删除GUI菜单
        Menu, ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        Loop % ClipboardHistory.MaxIndex()
        {
            ; NewClipboard:=ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index] ;逆序
            NewClipboard:=ClipboardHistory[A_Index] ;顺序
            if (StrLen(NewClipboard)>30) ;菜单名称限制字符串长度
                NewClipboard:=SubStr(NewClipboard, 1, 30)
            Menu, ClipboardHistoryMenu, Add, %NewClipboard%, ClipTheHistoryRecord, Radio ; 添加菜单

            if (A_Index<=TopMenuCount)
                Menu, ClipboardHistoryMenu, Check, %NewClipboard% ; 给顶置菜单打上点作为标识

            if (A_Index=TopMenuCount)
                Menu, ClipboardHistoryMenu, Add ; 顶置菜单和非顶置菜单之间增加一条分割线
        }

        ; 在上次显示菜单位置显示
        Menu, ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
        KeyWait, LButton
    }
    Else If GetKeyState("Xbutton1", "P") ; 侧键下 向下移动所选菜单
    {
        If (A_ThisMenuItemPos<TopMenuCount) and (A_ThisMenuItemPos<TopMenuCount) ; 点击的是是顶置菜单 向下移动所选菜单
        {
            ; 获取菜单内容
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos]
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos)
            ; 添加到上一Pos
            ClipboardHistory.InsertAt(A_ThisMenuItemPos+1, TopClipboard)
        }
        Else If (A_ThisMenuItemPos-ExistTopMenu>TopMenuCount) and (A_ThisMenuItemPos-ExistTopMenu<ClipboardHistory.MaxIndex()) ;不是顶置菜单 向下移动所选菜单
        {
            ; 获取菜单内容
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu]
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos-ExistTopMenu)
            ; 添加到上一Pos
            ClipboardHistory.InsertAt(A_ThisMenuItemPos+1-ExistTopMenu, TopClipboard)
        }
        Else
        {
            ; 在上次显示菜单位置显示
            Menu, ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
            KeyWait, LButton
            return ; 菜单不可向下移动
        }

        ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
        Loop, % ClipboardHistory.MaxIndex()
            IniWrite, % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

        ; 删除GUI菜单
        Menu, ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        Loop % ClipboardHistory.MaxIndex()
        {
            ; NewClipboard:=ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index] ;逆序
            NewClipboard:=ClipboardHistory[A_Index] ;顺序
            if (StrLen(NewClipboard)>30) ;菜单名称限制字符串长度
                NewClipboard:=SubStr(NewClipboard, 1, 30)
            Menu, ClipboardHistoryMenu, Add, %NewClipboard%, ClipTheHistoryRecord, Radio ; 添加菜单

            if (A_Index<=TopMenuCount)
                Menu, ClipboardHistoryMenu, Check, %NewClipboard% ; 给顶置菜单打上点作为标识

            if (A_Index=TopMenuCount)
                Menu, ClipboardHistoryMenu, Add ; 顶置菜单和非顶置菜单之间增加一条分割线
        }

        ; 在上次显示菜单位置显示
        Menu, ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
        KeyWait, LButton
    }
    Else If GetKeyState("Ctrl", "P") ; Ctrl 删除所选菜单
    {
        If (A_ThisMenuItemPos<=TopMenuCount) ; 点击的是是顶置菜单
        {
            If (TopMenuCount>=1)
                TopMenuCount := TopMenuCount-1
            IniWrite, %TopMenuCount%, History.ini, Setting, TopMenuCount

            ; 获取菜单内容
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos]
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos)
        }
        Else ;不是顶置菜单 删除所选菜单
        {
            ; 获取菜单内容
            TopClipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu]
            ; 删除
            ClipboardHistory.RemoveAt(A_ThisMenuItemPos-ExistTopMenu)
        }

        ; 清除ini文件
        Loop %MaxItem%
            IniWrite, "", History.ini, History, ClipboardHistory%A_Index%

        ; 剪贴板记录保存到本地ini配置文件内 注意应当把换行CR-LF给替换为不换行文本储存 需要逆序
        Loop, % ClipboardHistory.MaxIndex()
            IniWrite, % StrReplace(ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index], "`r`n", "``r``n"), History.ini, History, ClipboardHistory%A_Index%

        ; 删除GUI菜单
        Menu, ClipboardHistoryMenu, DeleteAll

        ; 重新加载菜单
        Loop % ClipboardHistory.MaxIndex()
        {
            ; NewClipboard:=ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_Index] ;逆序
            NewClipboard:=ClipboardHistory[A_Index] ;顺序
            if (StrLen(NewClipboard)>30) ;菜单名称限制字符串长度
                NewClipboard:=SubStr(NewClipboard, 1, 30)
            Menu, ClipboardHistoryMenu, Add, %NewClipboard%, ClipTheHistoryRecord, Radio ; 添加菜单

            if (A_Index<=TopMenuCount)
                Menu, ClipboardHistoryMenu, Check, %NewClipboard% ; 给顶置菜单打上点作为标识

            if (A_Index=TopMenuCount)
                Menu, ClipboardHistoryMenu, Add ; 顶置菜单和非顶置菜单之间增加一条分割线
        }

        ; 在上次显示菜单位置显示
        Menu, ClipboardHistoryMenu, Show, %MouseInScreenX%, %MouseInScreenY%
        KeyWait, LButton
    }
    Else ; 按下的时候没有按住任何键 黏贴内容
    {
        ; Clipboard := ClipboardHistory[ClipboardHistory.MaxIndex()+1-A_ThisMenuItemPos] ;逆序
        ; ToolTip, A_ThisMenuItemPos%A_ThisMenuItemPos%

        If (A_ThisMenuItemPos<=TopMenuCount) ; 点击的是是顶置菜单
            Clipboard := ClipboardHistory[A_ThisMenuItemPos] ;顺序
        Else
            Clipboard := ClipboardHistory[A_ThisMenuItemPos-ExistTopMenu] ;顺序

        BlockInput, On
        Send ^v ; 自动粘贴选中的历史项
        BlockInput, Off
    }
return

; 清除剪贴板历史
^+d:: ; Ctrl + Shift + D 用于清除历史记录
    ; 清除数组
    ClipboardHistory := []

    ; 清除GUI菜单
    if (ClipboardAlreadyRecorded=1)
    {
        Menu, ClipboardHistoryMenu, DeleteAll
        ClipboardAlreadyRecorded:=0
    }

    ; 清除ini文件
    Loop %MaxItem%
        IniWrite, "", History.ini, History, ClipboardHistory%A_Index%

    ; 清除顶置菜单配置
    TopMenuCount:=0
    IniWrite, %TopMenuCount%, History.ini, Setting, TopMenuCount

    Loop, 30
    {
        ToolTip, 剪贴板历史已清除
        Sleep, 30
    }
    ToolTip
return

; 如果你需要添加白名单请复制下面这行代码填入对应的进程名
#IfWinActive, ahk_exe Code.exe ; 以下代码只在指定软件内运行

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

^d::
    ; 确保不是空内容
    BlockInput, On
    Send ^c ; 复制选择的内容
    Send, {Ctrl Up}
    ClipWait 1
    if (ErrorLevel || Clipboard = "")
        return

    ; 等待新内容复制进来
    ClipboardGetTickCount:=A_TickCount
    Loop
    {
        if (A_Clipboard!=OldClipboardHistory) ; ClipboardChoosed
            Break
        Else if (A_TickCount-ClipboardGetTickCount>100) ; 超时
            Break

        Sleep, 10
    }

    ClipboardChoosed:=A_Clipboard
    ; ToolTip, %A_Clipboard%
    if (InStr(ClipboardChoosed, "`r`n")<=0) ;没有换行
    {
        if (InStr(ClipboardChoosed, "(")=1) and (StrLen(ClipboardChoosed)>1) and (InStr(ClipboardChoosed, ")", , 0)=StrLen(ClipboardChoosed))
        {
            send {End 2}
            send {Shift Down}
            send {Home 2}
            send {Shift Up}
            Send ^c ; 复制选择的内容
            NewClipboardStar := SubStr(A_Clipboard, 1, InStr(A_Clipboard, ClipboardChoosed)+StrLen(ClipboardChoosed)-1)
            NewClipboardEnd := SubStr(A_Clipboard, InStr(A_Clipboard, ClipboardChoosed)+StrLen(ClipboardChoosed))
            NewClipboard := NewClipboardStar

            CopyTimes:=1
            CopyCount:=A_TickCount
            loop
            {
                ToolTip, CopyTimes%CopyTimes%
                if GetKeyState("D", "P")
                {
                    if (A_Index>1)
                        CopyTimes+=1
                    loop
                    {
                        ToolTip, CopyTimes%CopyTimes%
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

            loop %CopyTimes%
            {
                if (InStr(A_Clipboard, ") or (")!=0) or (InStr(A_Clipboard, ")or(")!=0) or (InStr(A_Clipboard, ")or (")!=0) or (InStr(A_Clipboard, ") or(")!=0)
                    NewClipboard .= " or "
                Else if (InStr(A_Clipboard, ") || (")!=0) or (InStr(A_Clipboard, ")||(")!=0) or (InStr(A_Clipboard, ") ||(")!=0) or (InStr(A_Clipboard, ")|| (")!=0)
                    NewClipboard .= " || "
                Else if (InStr(A_Clipboard, ") and (")!=0) or (InStr(A_Clipboard, ")and(")!=0) or (InStr(A_Clipboard, ")and (")!=0) or (InStr(A_Clipboard, ") and(")!=0)
                    NewClipboard .= " and "
                Else if (InStr(A_Clipboard, ") && (")!=0) or (InStr(A_Clipboard, ")&&(")!=0) or (InStr(A_Clipboard, ")&& (")!=0) or (InStr(A_Clipboard, ") &&(")!=0)
                    NewClipboard .= " && "

                NewClipboard .= ClipboardChoosed
            }

            NewClipboard .= NewClipboardEnd
            BlockInput, off
            Clipboard := NewClipboard

            ; If (Start) or (Test123) or (End)
            ; If (Start) and (Test456) and (End)
            ; If (Start) and (函数(ABC)>1+2+3) and (End)

            Sleep, 100
            Send ^v ; ClipboardChoosed

            loop 30
            {
                ToolTip, CopyTimes%CopyTimes%
                Sleep, 30
            }
            ToolTip
        }
        Else
        {    
            Clipboard .= ClipboardChoosed
            Sleep, 100
            Send ^v ; ClipboardChoosed
        }
        ; ToolTip 没有换行
    }
    Else ; 存在换行
    {
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
        
        if (CRLFcount=1)
        {
            ; ToolTip % InStr(ClipboardChoosed, "`r`n")
            if (InStr(ClipboardChoosed, "`r`n")=1)
            {
                Send, {End}
                Sleep, 100
            }
            Send, {Shift Down}
            Send, {Alt Down}
            Sleep, 100
            Send, {Down}
            Send, {Shift up}
            Send, {Alt up}
        }
        Else if (CRLFcount>1)
        {
            Send, {Shift Down}
            FirstCRLF:=InStr(ClipboardChoosed, "`r`n")
            if (FirstCRLF=1)
            {
                Send, {Right}
                Sleep, 100
            }
            Send, {Alt Down}
            Sleep, 100
            Send, {Down}
            Send, {Shift up}
            Send, {Alt up}

            NewClipboard:=StrReplace(ClipboardChoosed, "`r`n") ; 去掉复制内容中的CRLF换行
            NewClipboard:=StrReplace(NewClipboard, " ") ; 去掉复制内容中的空格
            FirstBrace:=InStr(NewClipboard, "{")
            EndBrace:=InStr(NewClipboard, "}", , 0)
            ; NewClipboardMax:=StrLen(NewClipboard)
            ; ToolTip, %NewClipboard%`nFirstBrace%FirstBrace% EndBrace%EndBrace% NewClipboardMax%NewClipboardMax%
            
            if (FirstBrace=1) and (EndBrace=StrLen(NewClipboard))
            {
                Sleep, 100
                Send, {Up}
                Send, {End}
                Send, {Enter}
                Send, {Text}else
                Send, {Tab}
            }
        }
    }
    Sleep, 100
    Clipboard:=OldClipboardHistory
    BlockInput, Off
    KeyWait, Ctrl
    Send, {Ctrl Up}
Return

$Enter::
    EnterDown:=A_TickCount
    BlockInput, On
    Send, {Enter Up}
    loop
    {
        if !GetKeyState("Enter", "P")
        {
            Send, {Enter}
            Break
        }
        if (A_TickCount-EnterDown>300)
        {
            Send, {Shift Down}
            Sleep, 50
            Send, {End}
            Send, {Shift up}
            Send, {Enter}
            KeyWait, Enter
            Break
        }
    }
    BlockInput, Off
Return

; 打开中文帮助并跳转至对应文档
; 功能修改自 智能F1 https://github.com/telppa/SciTE4AutoHotkey-Plus/tree/master
$F1::
    BlockInput, On
    Send, ^c
    BlockInput, Off

    ; 等待新内容复制进来
    ClipboardGetTickCount:=A_TickCount
    Loop
    {
        if (A_Clipboard!=OldClipboardHistory) ; 新内容和旧内容不一样
            Break
        Else if (A_TickCount-ClipboardGetTickCount>1000) ; 超时
            Return
        Sleep, 30
    }

    AutoHotKeyHelpPath:=A_ScriptDir
    AutoHotKeyHelpPath.="\AutoHotkey.chm"
    if (PID="") or (PID="ERROR") or (WinExist("ahk_pid "PID)=0)                           ; 首次打开或窗口被最小化（为0）或窗口被关闭（为空）。
    {
        Run, % AutoHotKeyHelpPath,,,PID                          ; 打开帮助文件。
        WinWait, ahk_pid %PID%                             ; 这行不能少，否则初次打开无法输入文本并搜索。
        WinActivate, ahk_pid %PID%                         ; 这行不能少，否则初次打开无法输入文本并搜索。
        SysGet, WorkArea, MonitorWorkArea, 1               ; 获取工作区尺寸，即不含任务栏的屏幕尺寸。
        DPIScale:=A_ScreenDPI/96
        W:=(WorkAreaRight-WorkAreaLeft)//2
        X:=WorkAreaLeft+W+(-1+8)*DPIScale
        Y:=WorkAreaTop
        H:=WorkAreaBottom-Y+(-1+8)*DPIScale
        WinMove, ahk_pid %PID%,, X, Y, W, H                ; 显示在屏幕右侧并占屏幕一半尺寸。
        oWB:=IE_GetWB(PID).document                        ; 获取帮助文件的对象。
    }
    Else
    {
        WinGetPos, X, Y, W, H, ahk_pid %PID%
        if (X+Y+W+H=0) ; 帮助窗口最小化后无法激活，所以只能杀掉重开。
            Process, Close, %PID% 
    }
    WinActivate, ahk_pid %PID%                           ; 激活。
    WinClose, 查找 ahk_pid %PID%                         ; 关掉查找窗口，它存在会无法切换结果。

    oWB.getElementsByTagName("BUTTON")[2].click()        ; 索引按钮。
    oWB.querySelector("INPUT").value := A_Clipboard             ; 输入关键词。
    ControlSend, , {Enter}{Enter}, ahk_pid %PID%         ; 按两下回车进行搜索。
    oWB.getElementsByTagName("BUTTON")[1].click()        ; 目录按钮。
    Clipboard:=OldClipboardHistory
Return

IE_GetWB(PID) { ; get the parent windows & coord from the element
    IID_IWebBrowserApp := "{0002DF05-0000-0000-C000-000000000046}"
        , IID_IHTMLWindow2 := "{332C4427-26CB-11D0-B483-00C04FD90119}"

    WinGet, ControlListHwnd, ControlListHwnd, ahk_pid %PID%
    for k, v in StrSplit(ControlListHwnd, "`n", "`r")
    {
        WinGetClass, sClass, ahk_id %v%
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