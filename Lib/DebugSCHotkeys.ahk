; noGUI is used just to get the hotkey information without displaying the GUI
; e.g. for bug report email
DebugSCHotkeys(noGUI := False)
{
	static log ; to dump to clipboard

	Gui, DebugSCHotkeys:New  ; destroy previous windows with same name
	process, exist, %GameExe%
	If !errorlevel
		log := "Error: SC is not running!`n`nThe listed hotkeys are the standard default SC keys."
	else 
	{
		SC2Keys.getHotkeyProfile()
		log := "Note: '?' characters represent replaced account numbers which maintains privacy.`n`n"
		log .= "Account Folder:`n`n`t"
		if InStr(FileExist(SC2Keys.debug.accountFolder), "D")
			log .= RegExReplace(SC2Keys.debug.accountFolder, "\d{4}\\", "????\") 
		else log .= "Directory doesn't exist! (" SC2Keys.debug.accountFolder ")", errorLog .= "`n`tAccount folder."

		log .= "`n`nVariables:`n`n`t"
		if FileExist(SC2Keys.debug.variablesFilePath)
			log .= RegExReplace(SC2Keys.debug.variablesFilePath, "\d{4}\\", "????\") 
		else log .= "Variables file doesn't exist! (" SC2Keys.debug.variablesFilePath ")", errorLog .= "`n`tVariables file"
		
		log .= "`n`nProfile:`n`n`t" RegExReplace(SC2Keys.debug.hotkeyProfile, "\d{4}\\", "????\") 
			.  "`n`nSuffix:`n`n`t" SC2Keys.debug.hotkeySuffix "`n"
		if (errorLog != "")
			log .= "`nErrors have occured:" errorLog
	} 

	Gui, Add, Edit, w570 r18 hwndHwndEdit readonly, %log%

	Gui, Add, ListView, Grid -LV0x10 NoSortHdr +resize w570 r28, Name|Sent Keys|MT Hotkeys
	Gui, Add, Button, Default g__DebugSCHotkeysClipboardDump, Dump To Clipboard

	for name, hotkey in SC2Keys.getAllKeys()
		LV_Add("", name, hotkey, SC2Keys.AHKHotkey(name))
	loop, % LV_GetCount("Column")
		LV_ModifyCol(A_Index, "AutoHdr") ; resize contents+header
	if noGUI
	{
		r := log "`n`n" ColumnJustify(Table_FromListview())	
		Gui Destroy
		return r
	}
	Gui, Show,, StarCraft Hotkeys
	selectText(HwndEdit, -1)
	return

	DebugSCHotkeysGuiClose:
	DebugSCHotkeysGuiEscape:
	Gui Destroy
	return 

	__DebugSCHotkeysClipboardDump:
	clipboard := log "`n`n" ColumnJustify(Table_FromListview())
	return
}
