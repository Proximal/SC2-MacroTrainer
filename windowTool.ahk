;Uncomment the next #-lines for a 'prettier' stand alone version
;#NoTrayIcon
;#SingleInstance Ignore
Menu, Tray, NoIcon
AWI_standalone=1
;Assume the lines above don't execute when included in another script

AWI_GuiShow:
    isUpd := true
    txtNotFrozen := "(Win+A to freeze display)"
    txtFrozen := "(Win+A to unfreeze display)"

    Gui, 13:New, LabelAWI_Gui hwndAWI_hGui AlwaysOnTop Resize MinSize
    Gui, Add, Text,, Window Title, Class and Process:
    Gui, Add, Edit, w320 r3 ReadOnly -Wrap vCtrl_Title
    Gui, Add, Text,, Mouse Position:
    Gui, Add, Edit, w320 r3 ReadOnly vCtrl_MousePos
    Gui, Add, Text,, Control Under Mouse Position:
    Gui, Add, Edit, w320 r3 ReadOnly vCtrl_MouseCur
    Gui, Add, Text,, Active Window Position:
    Gui, Add, Edit, w320 r2 ReadOnly vCtrl_Pos
    Gui, Add, Text,, Status Bar Text:
    Gui, Add, Edit, w320 r2 ReadOnly vCtrl_SBText
    Gui, Add, Checkbox, vCtrl_IsSlow, Slow TitleMatchMode
    Gui, Add, Text,, Visible Text:
    Gui, Add, Edit, w320 r2 ReadOnly vCtrl_VisText
    Gui, Add, Text,, All Text:
    Gui, Add, Edit, w320 r2 ReadOnly vCtrl_AllText
    Gui, Add, Text, w320 r1 vCtrl_Freeze, % txtNotFrozen
    IfExist, %A_ScriptDir%\..\toolicon.icl ; Seems useful enough to support standalone operation.
        Loop, 2
            DllCall( "PostMessage", UInt, AWI_hGui, UInt, 0x80, UInt, A_Index-1, UInt, DllCall("LoadImage", uint, DllCall("GetModuleHandle", str, A_ScriptDir . "\..\toolicon.icl"), uint, 9, uint, 1, int, 0, int, 0, uint, 0x40) )
    Else
        Loop, 2
            DllCall( "PostMessage", UInt, AWI_hGui, UInt, 0x80, UInt, A_Index-1, UInt, DllCall("LoadImage", uint, DllCall("GetModuleHandle", str, "shell32.dll"), uint, 281, uint, 1, int, 0, int, 0, uint, 0x40) ) ;Set GUI icon without disturbing tray icon
    Gui, Show,, Active Window Info
    GetClientSize(AWI_hGui, temp)
    horzMargin := temp*96//A_ScreenDPI - 320
    SetTimer, AWI_Update, 250
return

AWI_GuiSize:
    Gui %AWI_hGui%:Default
    if !horzMargin
        return
    ctrlW := A_GuiWidth - horzMargin
    list = Title,MousePos,MouseCur,Pos,SBText,VisText,AllText,Freeze
    Loop, Parse, list, `,
        GuiControl, Move, Ctrl_%A_LoopField%, w%ctrlW%
return

AWI_Update:
    SetBatchLines, -1
    Gui %AWI_hGui%:Default
    curWin := WinExist("A")
    if (curWin = AWI_hGui)
        return
    CoordMode, Pixel, Screen
    WinGetTitle, t1
    WinGetClass, t2
    WinGet, t3, ProcessName
    GuiControl,, Ctrl_Title, % t1 "`nahk_class " t2 "`nahk_exe " t3
    CoordMode, Mouse, Screen
    MouseGetPos, msX, msY, msWin, msCtrlHwnd, 2
    CoordMode, Mouse, Relative
    MouseGetPos, mrX, mrY,, msCtrl
    CoordMode, Mouse, Client
    MouseGetPos, mcX, mcY
    GuiControl,, Ctrl_MousePos, % "Absolute:`t" msX ", " msY " (less often used)`nRelative:`t" mrX ", " mrY " (default)`nClient:`t" mcX ", " mcY " (recommended)"
    PixelGetColor, mClr, %msX%, %msY%, RGB
    mClr := SubStr(mClr, 3)
    mText := "`nColor:`t" mClr " (Red=" SubStr(mClr, 1, 2) " Green=" SubStr(mClr, 3, 2) " Blue=" SubStr(mClr, 5) ")"
    if (curWin = msWin)
    {
        ControlGetText, ctrlTxt, %msCtrl%
        mText := "ClassNN:`t" msCtrl "`nText:`t" textMangle(ctrlTxt) mText
    } else mText := "`n" mText
    GuiControl,, Ctrl_MouseCur, % mText
    WinGetPos, wX, wY, wW, wH
    GetClientSize(curWin, wcW, wcH)
    GuiControl,, Ctrl_Pos, % "x: " wX "`ty: " wY "`tw: " wW "`th: " wH "`nClient:`t`tw: " wcW "`th: " wcH
    sbTxt := ""
    Loop
    {
        StatusBarGetText, ovi, %A_Index%
        if ovi =
            break
        sbTxt .= "(" A_Index "):`t" textMangle(ovi) "`n"
    }
    StringTrimRight, sbTxt, sbTxt, 1
    GuiControl,, Ctrl_SBText, % sbTxt
    GuiControlGet, bSlow,, Ctrl_IsSlow
    SetTitleMatchMode, % bSlow ? "Slow" : "Fast"
    DetectHiddenText, Off
    WinGetText, ovVisText
    DetectHiddenText, On
    WinGetText, ovAllText
    GuiControl,, Ctrl_VisText, % ovVisText
    GuiControl,, Ctrl_AllText, % ovAllText
return

AWI_GuiClose:
    If AWI_standalone
        ExitApp
    isUpd := false
    SetTimer, AWI_Update, Off
    Gui, Destroy
Return

GetClientSize(hWnd, ByRef w := "", ByRef h := "")
{
    VarSetCapacity(rect, 16)
    DllCall("GetClientRect", "ptr", hWnd, "ptr", &rect)
    w := NumGet(rect, 8, "int")
    h := NumGet(rect, 12, "int")
}

textMangle(x)
{
    if pos := InStr(x, "`n")
        x := SubStr(x, 1, pos-1), elli := true
    if StrLen(x) > 40
    {
        StringLeft, x, x, 40
        elli := true
    }
    if elli
        x .= " (...)"
    return x
}

#IfWinExist, Active Window Info
#a::
    Gui %AWI_hGui%:Default
    isUpd := !isUpd
    SetTimer, AWI_Update, % isUpd ? "On" : "Off"
    GuiControl,, Ctrl_Freeze, % isUpd ? txtNotFrozen : txtFrozen
return
#IfWinNotExist, Active Window Info
#a::Goto, AWI_GuiShow
#If,