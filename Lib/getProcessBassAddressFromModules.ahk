/*
	http://stackoverflow.com/questions/14467229/get-base-address-of-process
	Open the process using OpenProcess -- if successful, the value returned is a handle to the process, which is just an opaque token used by the kernel to identify a kernel object. Its exact integer value (0x5c in your case) has no meaning to userspace programs, other than to distinguish it from other handles and invalid handles.
	Call GetProcessImageFileName to get the name of the main executable module of the process.
	Use EnumProcessModules to enumerate the list of all modules in the target process.
	For each module, call GetModuleFileNameEx to get the filename, and compare it with the executable's filename.
	When you've found the executable's module, call GetModuleInformation to get the raw entry point of the executable.
*/
; Process should be as it appears in task manager e.g. notepad.exe or SC2.exe
; If no module is specified, the adrress of the base module - main() e.g. C:\Games\StarCraft II\Versions\Base28667\SC2.exe
; will be returned. Otherwise specify the module/dll to find.

getProcessBassAddressFromModules(process, module := "")
{
	_MODULEINFO := "
					(
					  LPVOID lpBaseOfDll;
					  DWORD  SizeOfImage;
					  LPVOID EntryPoint;
				  	)"
	Process, Exist, %process%
	if ErrorLevel 							; PROCESS_QUERY_INFORMATION + PROCESS_VM_READ 
		hProc := DllCall("OpenProcess", "uint", 0x0400 | 0x0010 , "int", 0, "uint", ErrorLevel)
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
		;clipboard .= "`n" StrGet(&lpFilename)
		;if 0
		if (!module && mainExeName = StrGet(&lpFilename) || module && instr(StrGet(&lpFilename), module))
		{
			moduleInfo := struct(_MODULEINFO)
			DllCall("psapi\GetModuleInformation", "uint", hProc, "Uint", numget(lphModule, (A_index - 1) * 4)
				, "Ptr", moduleInfo[], "Uint", SizeOf(moduleInfo))
			;return moduleInfo.SizeOfImage, DllCall("CloseHandle","uint",hProc)
			return moduleInfo.lpBaseOfDll, DllCall("CloseHandle","uint",hProc)
		}
	}
	return -1, DllCall("CloseHandle","uint",hProc) ; not found
}