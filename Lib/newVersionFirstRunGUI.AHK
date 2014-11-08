newVersionFirstRunGUI(ProgramVersion, old_backup_DIR)
{
	old_backup_DIR := A_WorkingDir "\" old_backup_DIR
	StringReplace, old_backup_DIR, old_backup_DIR, \\, \, All ; If in root directory final backslash is not omitted
	Gui, newVersionRun:New, +LastFound +Toolwindow +AlwaysOnTop  ; Don't really need new, but need lastFound.
	GuiHWND := WinExist() 
	Gui, Add, Edit, x145 y10 w350 h128 +ReadOnly HwndHwndEdit, 
		( LTrim
			This appears to be the first time that you have used this version.

			Your old %config_file% and Macro Trainer files have been backed up to: %old_backup_DIR%

			A new config file has been installed which contains your previous personalised settings

			Press Launch to run SC2.

			Otherwise press Options to open the options menu.
		)
	Gui, Add, Button, x145 y145 w70 h27 Default g_newVersionFirstRunGUILaunch, &Launch
	Gui, Add, Button, x+25 y145 w70 h27 g_newVersionFirstRunGUIOptions, &Options

	Gui, Add, Picture, x7 y10, %A_Temp%\UnitPanelMacroTrainer\SCBare128.png
	Gui, Show, w506 h180, v%ProgramVersion%
	selectText(HwndEdit, -1)
	WinWaitClose, ahk_id %GuiHWND%
	return selectedButton != "" ? selectedButton : ""

	_newVersionFirstRunGUILaunch:
	Gui newVersionRun:Destroy
	selectedButton := "Launch"
	return
	_newVersionFirstRunGUIOptions:
	Gui newVersionRun:Destroy
	selectedButton := "Options"
	return 
	; If this label is absent, closing the window simply hides it, which is the same effect as Gui Cancel.
	newVersionRunGUIClose:
	newVersionRunGUIEscape:
	Gui newVersionRun:Destroy
	return 
}