; This is only supports UTF-8 (which SC2 Uses). Though you could easily tweak this.
; Use the memory class for more options and string settings
; It's in lib\classmemory.ahk

; Automatically closes handle when a new (or null) program is indicated
; Otherwise, keeps the process handle open between calls that specify the
; same program. When finished reading memory, call this function with no
; parameters to close the process handle i.e: "Closed := ReadMemory_Str()"

; Size is in bytes. If size = 0, read until null terminator is found
ReadMemory_Str(MADDRESS := 0, PROGRAM := "", size := 0)  ; "" = Null
{ 
    Static OLDPROC, ProcessHandle

   If (PROGRAM != OLDPROC)
   {
        if ProcessHandle
        {
            closed := DllCall("CloseHandle", "UInt", ProcessHandle)
            ProcessHandle := 0, OLDPROC := ""
            if !PROGRAM
                return closed
        }
        if PROGRAM
        {
            WinGet, pid, pid, % OLDPROC := PROGRAM
            if !pid 
               return "Process Doesn't Exist", OLDPROC := "" ;blank OLDPROC so subsequent calls will work if process does exist
            ProcessHandle := DllCall("OpenProcess", "Int", 16, "Int", 0, "UInt", pid)   
        }
   }
    ; size depends on the encoding too, but this is just for UTF-8 SC2
    bufferSize := VarSetCapacity(Output, size ? size : 100, 0)
    If !size ; read until terminator found or something goes wrong/error
    {
        ; In AHK_L increasing the buffer size will blank the current contents
        ; In AHK_H the contents are copied, but there is a bug in the unicode versions (the end of a string is missing)
        ; UTF-8 can have multi byte characters (latin are all 1 bytes), so need to convert the string in one go
        ; otherwise characters will be incorrect.
        ; I want to keep this function compatible with AHK_L, incase others wish to use it.

        ; I could keep the numGet numbers in an array and then use numPut to place them
        ; into a buffer after finding the null terminator. But i think this is a cleaner looking solution. 
        ; Tested and this method is ~32% faster - probably more for longer strings too.
        Loop ; Until Null is found
        {   
            success := DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS + A_Index - 1, "Ptr", &Output, "Uint", 1, "Ptr", 0) 
            if (ErrorLevel || !success)
                return 
            else if (0 = NumGet(Output, 0, "Char")) ; null
            {
                if (bufferSize < size := A_Index) ; A_Index will equal the size of the string in bytes
                    VarSetCapacity(Output, size)
                break
            }               
        } 
    }       
    DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Ptr", &Output, "Uint", size, "Ptr", 0)    
    return StrGet(&Output,, "UTF-8")
}
