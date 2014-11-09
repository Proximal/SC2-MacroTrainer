firstRunGUI(ProgramVersion)
{
	Gui, firstRun:New, +LastFound +Toolwindow +AlwaysOnTop  ; Don't really need new, but need lastFound.
	GuiHWND := WinExist() 
	Gui, Add, Edit, x145 y10 w300 h128 +ReadOnly HwndHwndEdit, 
		( LTrim
			This appears to be the first time you have run this program.

			Please take a moment to familiarise yourself with the settings and to edit them as you see fit.
		)
	Gui, Add, Button, x145 y145 w70 h27 gfirstRunGUIClose, OK
	Gui, Add, Picture, x7 y10, %A_Temp%\SCBare128.png
	Gui, Show, w456 h180, v%ProgramVersion%
	selectText(HwndEdit, -1)
	WinWaitClose, ahk_id %GuiHWND%
	return	
	; If this label is absent, closing the window simply hides it, which is the same effect as Gui Cancel.
	firstRunGUIClose:
	firstRunGUIEscape:
	Gui firstRun:Destroy
	return 
}
