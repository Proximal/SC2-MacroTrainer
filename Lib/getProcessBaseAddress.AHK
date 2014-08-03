; Interesting note:
; Although handles are 64-bit pointers, only the less significant 32 bits are employed in them for the purpose 
; of better compatibility (for example, to enable 32-bit and 64-bit processes interact with each other)
; Here are examples of such types: HANDLE, HWND, HMENU, HPALETTE, HBITMAP, etc. (but i you will need to read them as uInts)


; The base adress for some programs is dynamic. This can retrieve the current base address of the main module (e.g. SC2.exe), 
; which can then be added to your various offsets.	
; This function will return the correct address regardless of the 
; bitness (32 or 64 bit) of both the AHK exe and the target process.
; That is they can both be 32 bit or 64 bit, or the target process
; can be 32 bit while ahk is 64bit

; using quotes around the MatchMode "3", so if setFormat Hex is in effect, it won't give an error with SetTitleMatchMode
getProcessBaseAddress(WindowTitle, MatchMode := "3")    ;WindowTitle can be anything ahk_exe ahk_class etc
{
    mode :=  A_TitleMatchMode
    SetTitleMatchMode, %MatchMode%    ;mode 3 is an exact match
    WinGet, hWnd, ID, %WindowTitle%
    SetTitleMatchMode, %mode%    ; In case executed in autoexec
    if !hWnd
        return ; return blank failed to find window
    else return DllCall(  A_PtrSize = 4
                        ? "GetWindowLong"
                        : "GetWindowLongPtr"
                        , "Ptr", hWnd
                        , "Uint", -6
                        , "Int64") ; Use Int64 to prevent negative overflow when AHK is 32 bit and target process is 64bit
     ; If DLL call fails, returned value will = 0
}	