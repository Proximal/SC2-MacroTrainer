; Interesting note:
; Although handles are 64-bit pointers, only the less significant 32 bits are employed in them for the purpose 
; of better compatibility (for example, to enable 32-bit and 64-bit processes interact with each other)
; Here are examples of such types: HANDLE, HWND, HMENU, HPALETTE, HBITMAP, etc. (but i you will need to read them as uInts)


; The base address for some programs is dynamic. This can retrieve the current base address of the main module (e.g. SC2.exe), 
; which can then be added to your various offsets.	
; This function will return the correct address regardless of the 
; bitness (32 or 64 bit) of both the AHK exe and the target process.
; That is they can both be 32 bit or 64 bit, or the target process
; can be 32 bit while ahk is 64bit

; Return values:
;   Null        The process's window couldn't be found.
;   0           The GetWindowLong or GetWindowLongPtr call failed.
;   Non-Zero    The base address of the process (success).

getProcessBaseAddress(WindowTitle, windowMatchMode := "3")    ;WindowTitle can be anything ahk_exe ahk_class etc
{
    if (windowMatchMode && A_TitleMatchMode != windowMatchMode)
    {
        mode := A_TitleMatchMode ; This is a string and will not contain the 0x prefix
        StringReplace, windowMatchMode, windowMatchMode, 0x ; remove hex prefix as SetTitleMatchMode will throw a run time error. This will occur if integer mode is set to hex and matchmode param is passed as an number not a string.
        SetTitleMatchMode, %windowMatchMode%    ;mode 3 is an exact match
    }
    WinGet, hWnd, ID, %WindowTitle%
    if mode
        SetTitleMatchMode, %mode%    ; In case executed in autoexec
    if !hWnd
        return ; return blank failed to find window
    else return DllCall( A_PtrSize = 4
                            ? "GetWindowLong"
                            : "GetWindowLongPtr"
                        , "Ptr", hWnd
                        , "Int", -6
                        , "Int64") ; Use Int64 to prevent negative overflow when AHK is 32 bit and target process is 64bit
     ; If DLL call fails, returned value will = 0
}   