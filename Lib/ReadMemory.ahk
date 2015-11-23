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

ReadMemory(MADDRESS=0,PROGRAM="",BYTES=4)
{
   Static OLDPROC, ProcessHandle
   
   ; keep buffer a local variable, rather than static so that it is 
   ; quasi thread safe. 
   VarSetCapacity(buffer, BYTES) 
   If (PROGRAM != OLDPROC)
   {
        if ProcessHandle
          closed := DllCall("CloseHandle", "UInt", ProcessHandle), ProcessHandle := 0, OLDPROC := ""
        if PROGRAM
        {
            WinGet, pid, pid, % OLDPROC := PROGRAM
            if !pid 
               return "Process Doesn't Exist", OLDPROC := "" ;blank OLDPROC so subsequent calls will work if process does exist
            ProcessHandle := DllCall("OpenProcess", "Int", 16, "Int", 0, "UInt", pid)   
        }
        else return 
   }
   
   If !(ProcessHandle && DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Ptr", &buffer, "UInt", BYTES, "Ptr", 0))
      return !ProcessHandle ? "Handle Closed: " closed : "Fail"
   else if (BYTES = 4)
      Type := "UInt"
   else if (BYTES = 2)
      Type := "UShort"         
   else if (BYTES = 1)
      Type := "UChar"
   else 
      Type := "Int64"
   return numget(buffer, 0, Type)
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