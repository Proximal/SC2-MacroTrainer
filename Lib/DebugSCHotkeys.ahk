DebugSCHotkeys()
{
	Gui, DebugSCHotkeys:New  ; destroy previous windows with same name
	
	process, exist, %GameExe%
	If !errorlevel
		isRunning := False 

	SC2Keys.getHotkeyProfile(ignore1, ignore2)
	Gui, Add, Edit, w570 r16 hwndHwndEdit readonly, % ""
	 	.		"Account Folder:`n`n" 
	 	.			 A_tab SC2Keys.debug.accountFolder "`n`n"
		. 		"Variables:`n`n"
		. 			A_Tab SC2Keys.debug.variablesFilePath "`n`n"
		. 		"Profile:`n`n" 
		.			A_Tab SC2Keys.debug.hotkeyProfile "`n`n"
		. 		"Suffix:`n`n" 
		.			A_Tab SC2Keys.debug.hotkeySuffix "`n"


	Gui, Add, ListView, Grid -LV0x10 NoSortHdr +resize w570 r28, Name|Hotkey

	for name, hotkey in SC2Keys.getAllKeys()
		LV_Add("", name, hotkey)
	loop, % LV_GetCount("Column")
		LV_ModifyCol(A_Index, "AutoHdr") ; resize contents+header
	Gui, Show,, StarCraft Hotkeys
	selectText(HwndEdit, -1)
	return 

	DebugSCHotkeysGuiClose:
	DebugSCHotkeysGuiEscape:
	Gui Destroy
	return 
}
