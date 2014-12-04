DebugSCHotkeys()
{
	Gui, DebugSCHotkeys:New  ; destroy previous windows with same name
	
	process, exist, %GameExe%
	If !errorlevel
		log := "Error: SC is not running!`n`nThe listed hotkeys are the standard default SC keys."
	else 
	{
		SC2Keys.getHotkeyProfile()
		log := "Account Folder:`n`n`t"
		if InStr(FileExist(SC2Keys.debug.accountFolder), "D")
			log .= SC2Keys.debug.accountFolder
		else log .= "Directory doesn't exist! (" SC2Keys.debug.accountFolder ")", errorLog .= "`n`tAccount folder."

		log .= "`n`nVariables:`n`n`t"
		if FileExist(SC2Keys.debug.variablesFilePath)
			log .= SC2Keys.debug.variablesFilePath
		else log .= "Variables file doesn't exist! (" SC2Keys.debug.variablesFilePath ")", errorLog .= "`n`tVariables file"
		
		log .= "`n`nProfile:`n`n`t" SC2Keys.debug.hotkeyProfile
			.  "`n`nSuffix:`n`n`t" SC2Keys.debug.hotkeySuffix "`n"
		if (errorLog != "")
			log .= "`nErrors have occured:" errorLog
	} 
	
	Gui, Add, Edit, w570 r16 hwndHwndEdit readonly, %log%

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
