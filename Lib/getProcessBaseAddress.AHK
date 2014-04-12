; Interesting note:
; Although handles are 64-bit pointers, only the less significant 32 bits are employed in them for the purpose 
; of better compatibility (for example, to enable 32-bit and 64-bit processes interact with each other)
; Here are examples of such types: HANDLE, HWND, HMENU, HPALETTE, HBITMAP, etc. 


; The base adress for some programs is dynamic. This can retrieve the current base address of the main module (e.g. SC2.exe), 
; which can then be added to your various offsets.	
; This function will return the correct address regardless of the 
; bitness (32 or 64 bit) of both the AHK exe and the target process.
; That is they can both be 32 bit or 64 bit, or the target process
; can be 32 bit while ahk is 64bit

getProcessBaseAddress(WindowTitle, MatchMode=3)    ;WindowTitle can be anything ahk_exe ahk_class etc
{
    mode :=  A_TitleMatchMode
    SetTitleMatchMode, %MatchMode%    ;mode 3 is an exact match
    WinGet, hWnd, ID, %WindowTitle%
    SetTitleMatchMode, %mode%    ; In case executed in autoexec
    if !hWnd
        return ; return blank failed to find window
   ; GetWindowLong returns a Long (Int) and GetWindowLongPtr return a Long_Ptr
    BaseAddress := DllCall(A_PtrSize = 4
        ? "GetWindowLong"
        : "GetWindowLongPtr", "Ptr", hWnd, "Uint", -6, "UInt")
    return BaseAddress ; If DLL call fails, returned value will = 0
}	