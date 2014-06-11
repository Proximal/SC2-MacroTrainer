; Parameters:
;   Program - Can be any window title/class e.g "AHK_EXE SC2.exe"
;   Module - The file name of the module/dll to find e.g. "GDI32.dll", "Battle.net.dll" etc
;            If no module is specified, the address of the base module - main() (program) will be returned e.g. C:\Games\StarCraft II\Versions\Base28667\SC2.exe

; Return Values: 
;   Positive integer - Module base address
;   -1 - Module not found
;   -2 - Couldn't find the process. The program isn't running or you passed an incorrect program identifier parameter
;   -3 - Couldn't open the process. If the target process is running with admin rights, then the script will also need to be ran as admin. 
;   -4 - Problem with EnumProcessModules. This shouldn't happen.
;   -5 - The AHK script is 32 bit and you are trying to access the modules of a 64 bit target process.

; Note: A 64 bit AHK can enumerate the modules of a target 64 or 32 bit process.
;       A 32 bit AHK (any process actually) can only enumerate the modules of another 32 bit process

getModuleBaseAddress(program, module := "")
{
    WinGet, pid, pid, %program%
    if pid                              ; PROCESS_QUERY_INFORMATION + PROCESS_VM_READ 
        hProc := DllCall("OpenProcess", "UInt", 0x0400 | 0x0010 , "Int", 0, "UInt", pid)
    else return -2
    if !hProc
        return -3
    if (A_PtrSize = 4) ; AHK 32bit
    {
        DllCall("IsWow64Process", "Ptr", hProc, "Int*", result)
        if !result 
            return -5 ; AHK is 32bit and target process is 64 bit, this function wont work 
    }
    if (module = "")
    {        
        VarSetCapacity(mainExeNameBuffer, 2048 * (A_IsUnicode ? 2 : 1))
        DllCall("psapi\GetModuleFileNameEx", "Ptr", hProc, "UInt", 0
                    , "Ptr", &mainExeNameBuffer, "UInt", 2048 / (A_IsUnicode ? 2 : 1))
        mainExeFullPath := StrGet(&mainExeNameBuffer)
        ; mainExeName = main executable module of the process (will include full directory path)
    }
    size := VarSetCapacity(lphModule, 4)
    loop 
    {
        DllCall("psapi\EnumProcessModules", "Ptr", hProc, "Ptr", &lphModule
                , "UInt", size, "UInt*", reqSize)
        if ErrorLevel
            return -4, DllCall("CloseHandle","Ptr",hProc) 
        else if (size >= reqSize)
            break
        else 
            size := VarSetCapacity(lphModule, reqSize)    
    }
    VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1))
    loop % reqSize / A_PtrSize ; sizeof(HMODULE) - enumerate the array of HMODULEs
    {
        DllCall("psapi\GetModuleFileNameEx", "Ptr", hProc, "Ptr", numget(lphModule, (A_index - 1) * A_PtrSize)
                , "Ptr", &lpFilename, "UInt", 2048 / (A_IsUnicode ? 2 : 1))
        ; module will contain directory path as well e.g C:\Windows\syswow65\GDI32.dll
        moduleFullPath := StrGet(&lpFilename) 
        SplitPath, moduleFullPath, fileName ; strips the path so = GDI32.dll
        if (module = "" && mainExeFullPath = moduleFullPath) || (module != "" && module = filename)
        {
            VarSetCapacity(MODULEINFO, A_PtrSize = 4 ? 12 : 24)
            DllCall("psapi\GetModuleInformation", "Ptr", hProc, "Ptr", numget(lphModule, (A_index - 1) * A_PtrSize)
                , "Ptr", &MODULEINFO, "UInt", A_PtrSize = 4 ? 12 : 24)
            return numget(MODULEINFO, 0, "Ptr"), DllCall("CloseHandle","Ptr",hProc)
        }
    }
    return -1, DllCall("CloseHandle","Ptr",hProc) ; not found
}

/*
_MODULEINFO:    LPVOID lpBaseOfDll
                DWORD  SizeOfImage
                LPVOID EntryPoint
*/

/*
    http://stackoverflow.com/questions/14467229/get-base-address-of-process
    Open the process using OpenProcess -- if successful, the value returned is a handle to the process, which is just an opaque token used by the kernel to identify a kernel object. Its exact integer value (0x5c in your case) has no meaning to userspace programs, other than to distinguish it from other handles and invalid handles.
    Call GetProcessImageFileName to get the name of the main executable module of the process.
    Use EnumProcessModules to enumerate the list of all modules in the target process.
    For each module, call GetModuleFileNameEx to get the filename, and compare it with the executable's filename.
    When you've found the executable's module, call GetModuleInformation to get the raw entry point of the executable.
*/
/*
; This is the same function but uses uses Hotkeyit's struct() and sizeof() functions 
; I have commented it out as the above function will work fine, so if any one comes across it
; They don't need to download these functions - I've posted this on AHK forums.

getProcessBassAddressFromModules(process, module := "")
{
    _MODULEINFO := "
                    (
                      LPVOID lpBaseOfDll;
                      DWORD  SizeOfImage;
                      LPVOID EntryPoint;
                    )"
    Process, Exist, %process%
    if ErrorLevel                           ; PROCESS_QUERY_INFORMATION + PROCESS_VM_READ 
        hProc := DllCall("OpenProcess", "uint", 0x0400 | 0x0010 , "int", 0, "uint", ErrorLevel)
    if !hProc
        return -2
    if (A_PtrSize = 4) ; AHK 32bit
    {
        DllCall("IsWow64Process", "Ptr", hProc, "Int*", result)
        if !result 
            return -4 ; AHK is 32bit and target process is 64 bit, this function wont work
    }

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
        DllCall("psapi\EnumProcessModules", "Ptr", hProc, "Ptr", &lphModule
                , "Uint", size, "Uint*", reqSize)
        if ErrorLevel
            return -3, DllCall("CloseHandle","Ptr",hProc) 
        else if (size >= reqSize)
            break
        else 
            size := VarSetCapacity(lphModule, reqSize)  
    }
    VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1))
    loop % reqSize / A_PtrSize ; sizeof(HMODULE) - enumerate the array of HMODULEs
    {
        DllCall("psapi\GetModuleFileNameEx", "Ptr", hProc, "Ptr", numget(lphModule, (A_index - 1) * A_PtrSize)
                , "Ptr", &lpFilename, "Uint", 2048 / (A_IsUnicode ? 2 : 1))
        ;clipboard .= "`n" StrGet(&lpFilename)
        ;if 0
        if (!module && mainExeName = StrGet(&lpFilename) || module && instr(StrGet(&lpFilename), module))
        {
            moduleInfo := struct(_MODULEINFO) ; 12 bytes on 32 bit AHK, 24 on 64bit
            DllCall("psapi\GetModuleInformation", "Ptr", hProc, "Ptr", numget(lphModule, (A_index - 1) * A_PtrSize)
                , "Ptr", moduleInfo[], "Uint", SizeOf(moduleInfo))
            ;return moduleInfo.SizeOfImage, DllCall("CloseHandle","uint",hProc)
            return moduleInfo.lpBaseOfDll, DllCall("CloseHandle","Ptr",hProc)
        }
    }
    return -1, DllCall("CloseHandle","Ptr",hProc) ; not found
}

*/