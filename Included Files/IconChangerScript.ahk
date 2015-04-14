#NoEnv
#SingleInstance force
SetWorkingDir %A_ScriptDir%

global ExeFile, IcoFile, WaitPID, runFilePath

p := []
Loop, %0%
{
	p._Insert(%A_Index%)
}

if (Mod(p._MaxIndex(), 2)) {
	goto BadParams
}

Loop, % p._MaxIndex() // 2
{
	p1 := p[2*(A_Index-1)+1]
	p2 := p[2*(A_Index-1)+2]
	
	if p1 not in /exe,/icon,/pid
		goto BadParams
	
	if p2 =
		goto BadParams
	
	if p1 = /exe
		ExeFile := p2
	else if p1 = /icon
		IcoFile := p2
	else if p1 = /pid
		WaitPID := p2
}

if (!ExeFile || !IcoFile)
	goto BadParams
if !FileExist(ExeFile)
	Util_Error("Exe file doesn't exist: " ExeFile)
if !FileExist(IcoFile)
	Util_Error("Ico file doesn't exist: " IcoFile)

if (WaitPID) {
	WinWaitClose, ahk_pid %WaitPID%,, 7 ; max wait 7 sec
	if (ErrorLevel = 1) {
		Util_Error("Process not closed in 7 sec")
	}
}

module := DllCall("BeginUpdateResource", "str", ExeFile, "uint", 0, "ptr")
if (!module) {
	Util_Error("Error: Error opening the exe file.")
}

icons := [159, 160, 206, 207, 208, 228, 229, 230]
	
if !ReplaceAhkIcon(module, IcoFile, ExeFile) {
	gosub _EndUpdateResource
	Util_Error("Error changing icon: Unable to read icon or icon was of the wrong format.")
}

gosub _EndUpdateResource

MsgBox, Finished`n`nPress ok to relaunch the macro trainer. 

run, %ExeFile%
ExitApp

_EndUpdateResource:
	if !DllCall("EndUpdateResource", "ptr", module, "uint", 0)
		Util_Error("Error: Error opening the destination file.")
return

BadParams:
Util_Error("Command Line Parameters:`n`n" A_ScriptName " /exe file.exe /icon iconfile.ico [/pid PID]")
ExitApp

ReplaceAhkIcon(re, IcoFile, ExeFile, iconID := 159)
{
	global _EI_HighestIconID
	ids := EnumIcons(ExeFile, iconID)

	if !IsObject(ids)
		return false

	f := FileOpen(IcoFile, "r")
	if !IsObject(f)
		return false
	

	VarSetCapacity(igh, 8), f.RawRead(igh, 6)
	if NumGet(igh, 0, "UShort") != 0 || NumGet(igh, 2, "UShort") != 1
		return false

	wCount := NumGet(igh, 4, "UShort")
	
	VarSetCapacity(rsrcIconGroup, rsrcIconGroupSize := 6 + wCount*14)
	NumPut(NumGet(igh, "Int64"), rsrcIconGroup, "Int64") ; fast copy
	
	ige := &rsrcIconGroup + 6
	
	; Delete all the images
	Loop, % ids.MaxIndex()
		DllCall("UpdateResource", "ptr", re, "ptr", 3, "ptr", thisID, "ushort", 0x409)
		;UpdateResource(re, 3, ids[A_Index], 0x409)
	
	Loop, %wCount%
	{
		thisID := ids[A_Index]
		if !thisID
			thisID := ++ _EI_HighestIconID
		
		f.RawRead(ige+0, 12) ; read all but the offset
		NumPut(thisID, ige+12, "UShort")
		
		imgOffset := f.ReadUInt()
		oldPos := f.Pos
		f.Pos := imgOffset
		
		VarSetCapacity(iconData, iconDataSize := NumGet(ige+8, "UInt"))
		f.RawRead(iconData, iconDataSize)
		f.Pos := oldPos
		
		if !DllCall("UpdateResource", "ptr", re, "ptr", 3, "ptr", thisID, "ushort", 0x409, "ptr", &iconData, "uint", iconDataSize, "uint")
			return false
		
		ige += 14
	}

	; UpdateResource returns True on success
	return DllCall("UpdateResource", "ptr", re, "ptr", 14, "ptr", iconID, "ushort", 0x409, "ptr", &rsrcIconGroup, "uint", rsrcIconGroupSize, "uint")
}

EnumIcons(ExeFile, iconID)
{
	; RT_GROUP_ICON = 14
	; RT_ICON = 3
	global _EI_HighestIconID
	static pEnumFunc := RegisterCallback("EnumIcons_Enum")
	
	
	;hModule := LoadLibraryEx(ExeFile, 0, 2)
	hModule := DllCall("LoadLibraryEx", "Str", ExeFile, "Ptr", 0, "UInt", 2)
	if !hModule
		return

	_EI_HighestIconID := 0
	if DllCall("EnumResourceNames","PTR",hModule,"PTR",3,"PTR", pEnumFunc) = 0
	{
		DllCall("FreeLibrary","Ptr", hModule) ;FreeLibrary(hModule)
		return
	}

	hRsrc := DllCall("FindResource", "PTR", hModule, "PTR", iconID, "PTR", 14)
	,hMem := DllCall("LoadResource", "Ptr", hModule, "Ptr", hRsrc) ;LoadResource(hModule, hRsrc)
	,pDirHeader := DllCall("LockResource", "Ptr", hMem) ;LockResource(hMem)
	,pResDir := pDirHeader + 6
	
	wCount := NumGet(pDirHeader+4, "UShort")
	,iconIDs := []
	Loop, %wCount%
	{
		pResDirEntry := pResDir + (A_Index-1)*14
		iconIDs[A_Index] := NumGet(pResDirEntry+12, "UShort")
	}
	DllCall("FreeLibrary","Ptr", hModule) ;FreeLibrary(hModule)
	
	return iconIDs
}

EnumIcons_Enum(hModule, type, name, lParam)
{
	global _EI_HighestIconID
	if (name < 0x10000) && name > _EI_HighestIconID
		_EI_HighestIconID := name
	return 1
}

Util_Error(txt) {
	MsgBox, 16, Error, % txt "`n`nPress ok to relaunch the macro trainer." 
	run, %ExeFile%
	ExitApp
}