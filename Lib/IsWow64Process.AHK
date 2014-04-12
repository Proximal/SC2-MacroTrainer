/*
    Result:
    TRUE if the process is running under WOW64 - 32bit app on 64bit OS.
    If the process is running under 32-bit Windows, the value is set to FALSE. 
    If the process is a 64-bit application running under 64-bit Windows, the value is also set to FALSE.
*/

IsWow64Process(processName := "", windowTitle := "", windowMatchMode := 3)
{
    if processName
    {
        Process, Exist, %processName%
        PID := ErrorLevel
    }
    else if windowTitle
    {
        mode :=  A_TitleMatchMode
        SetTitleMatchMode, %windowMatchMode%    ;mode 3 is an exact match
        WinGet, PID, PID, %windowTitle%    
        SetTitleMatchMode, %mode%    ; In case executed in autoexec    
    }
    if PID                           ; PROCESS_QUERY_INFORMATION
    {
        hProcess := DllCall("OpenProcess", "uint", 0x0400, "int", False, "uint", PID)
        if DllCall("IsWow64Process", "Ptr", hProcess, "Int*", result) ; if succeeds
            return result,  DllCall("CloseHandle", "uint", hProcess)  
        DllCall("CloseHandle", "uint", hProcess)  
    }
    return ; return blank if failed to find the process, window, open process or isWoW64Process fails
}

/*
If you have a process handle, use IsWow64Process() with GetSystemInfo() (or GetNativeSystemInfo() if your app is a 32-bit app running under WOW64).

If IsWow64Process() returns true, the process is 32-bit running on a 64-bit OS.

If IsWow64Process() returns false (or does not exist), then the process is 32-bit on a 32-bit OS and 64-bit on a 64-bit OS.  Get(Native)SystemInfo() tells you if the OS itself is 32-bit or 64-bit.

*/
