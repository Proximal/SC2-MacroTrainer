getProcessFileVersion(process)
{
	process, exist, %process%
	If (!pid := ErrorLevel)
		return 0
	; msdn states ComObjGet( "winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2" )
	; Could have also used the process name ie -  ("Select * from Win32_Process where Name= '" process "'" )
	for Item in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where ProcessId="  pid)
	{
		; There should (can) only be one SC2, but let it iterate what it finds anyway
		aInfo := fileGetVersionInfo(Item.ExecutablePath)
		if aInfo.FileVersion
			return aInfo.FileVersion
	}	
	return 0
}