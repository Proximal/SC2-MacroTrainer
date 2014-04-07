/*
	_MODULEINFO := "
					(
					  LPVOID lpBaseOfDll;
					  DWORD  SizeOfImage;
					  LPVOID EntryPoint;
				  	)"
*/
; program can be a title, ahk class etc eg. "AHK_EXE SC2.exe"
; if no module is specified, the base address of the process is returned 
getBaseAddressOfModule(program, module := "")
{
	WinGet, pid, pid, %program%
	if pid 							; PROCESS_QUERY_INFORMATION + PROCESS_VM_READ 
		hProc := DllCall("OpenProcess", "uint", 0x0400 | 0x0010 , "int", 0, "uint", pid)
	if !hProc
		return -2
	if !module
	{
		VarSetCapacity(mainExeNameBuffer, 2048 * (A_IsUnicode ? 2 : 1))
		DllCall("psapi\GetModuleFileNameEx", "uint", hProc, "Uint", 0
					, "Ptr", &mainExeNameBuffer, "Uint", 2048 / (A_IsUnicode ? 2 : 1))
		mainExeName := StrGet(&mainExeNameBuffer)
		; mainExeName = main executable module of the process
	}
	size := VarSetCapacity(lphModule, 4)
	loop 
	{
		DllCall("psapi\EnumProcessModules", "uint", hProc, "Ptr", &lphModule
				, "Uint", size, "Uint*", reqSize)
		if ErrorLevel
			return -3, DllCall("CloseHandle","uint",hProc) 
		else if (size >= reqSize)
			break
		else 
			size := VarSetCapacity(lphModule, reqSize)	
	}
	VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1))
	loop % reqSize / A_PtrSize ; sizeof(HMODULE) - enumerate the array of HMODULEs
	{
		DllCall("psapi\GetModuleFileNameEx", "uint", hProc, "Uint", numget(lphModule, (A_index - 1) * 4)
				, "Ptr", &lpFilename, "Uint", 2048 / (A_IsUnicode ? 2 : 1))
		if (!module && mainExeName = StrGet(&lpFilename) || module && instr(StrGet(&lpFilename), module))
		{
			VarSetCapacity(MODULEINFO, 12)
			DllCall("psapi\GetModuleInformation", "UInt", hProc, "UInt", numget(lphModule, (A_index - 1) * 4)
				, "Ptr", &MODULEINFO, "UInt", 12)
			return numget(MODULEINFO, 0, "UInt"), DllCall("CloseHandle","uint",hProc)
		}
	}
	return -1, DllCall("CloseHandle","uint",hProc) ; not found
}
