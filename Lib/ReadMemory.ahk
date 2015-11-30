; Automatically closes handle when a new (or null) program is indicated
; Otherwise, keeps the process handle open between calls that specify the
; same program. When finished reading memory, call this function with no
; parameters to close the process handle i.e: "Closed := ReadMemory()"

;The new method using Numget is around 35% faster!!!

;Bytes can take 1,2,3,4 or 8
; wont correctly handle 8 bytes with extreme values
; I've written a memory class which is more extensive than this,
; and other people should just use that.
; Its in lib\classmemory.ahk

; Use if-else ladder with return marginally faster than a type/size lookup array, but only since 4 bytes is first, and most values are 4 bytes
; Faster to have if ProcessHandle && DLLCall("RPM") rather than use ! and have a single ladder
ReadMemory(address := 0, program := "", bytes := 4)
{
    Static prevProgram, ProcessHandle
   
    ; keep buffer a local variable, rather than static so that it is 
    ; quasi thread safe. 
    If (program != prevProgram), VarSetCapacity(buffer, bytes) 
    {
        if ProcessHandle
            closed := DllCall("CloseHandle", "Ptr", ProcessHandle), ProcessHandle := 0, prevProgram := ""
        if program
        {
            WinGet, pid, pid, % prevProgram := program
            if !pid 
                return "Process Doesn't Exist or Not 32-Bit Client.", prevProgram := "" ;blank prevProgram so subsequent calls will work if process does exist
            ProcessHandle := DllCall("OpenProcess", "Int", 16, "Int", 0, "UInt", pid, "Ptr")   
        }
        else return 
    }
    
    If (ProcessHandle && DllCall("ReadProcessMemory", "Ptr", ProcessHandle, "Ptr", address, "Ptr", &buffer, "Ptr", bytes, "Ptr", 0))
    {
        if (bytes = 4)
            return numget(buffer, 0, "UInt")
        else if (bytes = 2)
            return numget(buffer, 0, "UShort")      
        else if (bytes = 1)
            return numget(buffer, 0, "UChar")   
        else return numget(buffer, 0, "Int64") 
    }
    else return ProcessHandle ? "Fail" : "Handle Closed: " closed
}

; Can pass an array of offsets by using *
; eg, pointer(game, base, [0x10, 0x30, 0xFF]*)
; or a := [0x10, 0x30, 0xFF]
; pointer(game, address/baseAddress, a*)
; or just type them in manually

pointer(game, address, offsets*)
{ 
    For index, offset in offsets
        address := ReadMemory(address, game) + offset 
    Return ReadMemory(address, game)
}

pointerAddress(game, address, aOffsets*)
{
    return aOffsets.Remove() + pointer(game, address, aOffsets*) ; remove the highest key so can use pointer() to find final memory address (minus the last offset)       
}
