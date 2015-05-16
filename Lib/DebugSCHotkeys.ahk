; noGUI is used just to get the hotkey information without displaying the GUI
; e.g. for bug report email
DebugSCHotkeys(noGUI := False)
{
	static log ; to dump to clipboard
	log := ""
	Gui, DebugSCHotkeys:New  ; destroy previous windows with same name
	
	SC2Keys.getAllKeys() ; Ensure that aNonInterruptibleKeys are set
	for i, keyName in SC2Keys.aNonInterruptibleKeys
		NonInterruptibleKeys .= keyName ", "
	NonInterruptibleKeys := RTrim(NonInterruptibleKeys, ", ")
	process, exist, %GameExe%
	If !errorlevel
		log := "Error: SC is not running!`n`nThe listed hotkeys are the standard default SC keys.`n:Uninterruptible  Keys:`n`t" NonInterruptibleKeys
	else 
	{
		SC2Keys.getHotkeyProfile()
		log := "Note: '?' characters represent replaced account numbers, this maintains privacy.`n`n"
		log .= "Account Folder:`n`t"
		if InStr(FileExist(SC2Keys.debug.accountFolder), "D")
			log .= RegExReplace(SC2Keys.debug.accountFolder, "\d{4}\\", "????\") 
		else log .= "Directory doesn't exist! (" SC2Keys.debug.accountFolder ")", errorLog .= "`n`tAccount folder."

		log .= "`n`nVariables:`n`t"
		if FileExist(SC2Keys.debug.variablesFilePath)
			log .= RegExReplace(SC2Keys.debug.variablesFilePath, "\d{4}\\", "????\") 
		else log .= "Variables file doesn't exist! (" SC2Keys.debug.variablesFilePath ")", errorLog .= "`n`tVariables file"
		
		log .= "`n`nProfile:`n`t" RegExReplace(SC2Keys.debug.hotkeyProfile, "\d{4}\\", "????\") 
			.  "`n`nSuffix:`n`t" SC2Keys.debug.hotkeySuffix "`n"
			. "`nUninterruptible Keys:`n`t" NonInterruptibleKeys
		if (errorLog != "")
			log .= "`nErrors have occured:" errorLog
	} 

	Gui, Add, Edit, w800 r17 hwndHwndEdit readonly, %log%

	Gui, Add, ListView, Grid -LV0x10 NoSortHdr +resize w800 r28, Name|SC Syntax|Sent Keys 1|Sent Keys 2|MT Hotkeys 1|MT Hotkeys 2
	Gui, Add, Button, Default g__DebugSCHotkeysClipboardDump, Dump To Clipboard

	for i, name in SC2Keys.getReferences()
		LV_Add("", name, SC2Keys.StarCraftHotkey(name), SC2Keys.key(name), SC2Keys.key(name, True), SC2Keys.AHKHotkey(name), SC2Keys.AHKHotkey(name, True))

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
