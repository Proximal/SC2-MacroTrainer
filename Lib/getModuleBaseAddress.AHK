/*
_MODULEINFO:    LPVOID lpBaseOfDll
                DWORD  SizeOfImage
                LPVOID EntryPoint
*/


; Process should be as it appears in task manager e.g. notepad.exe or SC2.exe  - dont user AHK_EXE or window title
; If no module is specified, the adrress of the base module - main() e.g. C:\Games\StarCraft II\Versions\Base28667\SC2.exe
; will be returned. Otherwise specify the module/dll to find.

; Example of a module GDI32.dll or Battle.net.dll

; Note: A 64 bit AHK can enumerate the modules of a target 64 or 32 bit process.
;       A 32 bit AHK (any process actually) can only enumerate the modules of another 32 bit process

getModuleBaseAddress(process, module := "")
{
    Process, Exist, %process%
    if ErrorLevel                             ; PROCESS_QUERY_INFORMATION + PROCESS_VM_READ 
        hProc := DllCall("OpenProcess", "UInt", 0x0400 | 0x0010 , "Int", 0, "UInt", ErrorLevel)
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
        DllCall("psapi\GetModuleFileNameEx", "Ptr", hProc, "UInt", 0
                    , "Ptr", &mainExeNameBuffer, "UInt", 2048 / (A_IsUnicode ? 2 : 1))
        mainExeName := StrGet(&mainExeNameBuffer)
        ; mainExeName = main executable module of the process
    }
    size := VarSetCapacity(lphModule, 4)
    loop 
    {
        DllCall("psapi\EnumProcessModules", "Ptr", hProc, "Ptr", &lphModule
                , "UInt", size, "UInt*", reqSize)
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
                , "Ptr", &lpFilename, "UInt", 2048 / (A_IsUnicode ? 2 : 1))
        ; Use Instr() as module will contain directory path as well
        if (!module && mainExeName = StrGet(&lpFilename) || module && instr(StrGet(&lpFilename), module))
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
This is the same thing which uses Hotkeyit's struct() and sizeof() functions 
I have commented it out as the above function will work fine, so if any one comes across it
They don't need to download these functions - I've posted this on AHK forums.

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

; Note: A 64 bit AHK can enumerate the modules of a target 64 or 32 bit process.
;       A 32 bit AHK can only enumerate the modules of a 32 bit process
; This requies struct function
/*
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