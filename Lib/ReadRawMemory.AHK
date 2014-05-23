ReadRawMemory(MADDRESS=0,PROGRAM="", byref Buffer="", BYTES=4)
{
   Static OLDPROC, ProcessHandle

   VarSetCapacity(Buffer, BYTES)

   If (PROGRAM != OLDPROC)
   {
        if ProcessHandle
          closed := DllCall("CloseHandle", "UInt", ProcessHandle), ProcessHandle := 0,  OLDPROC := ""
        if PROGRAM
        {
            WinGet, pid, pid, % OLDPROC := PROGRAM
            if !pid 
               return "Process Doesn't Exist", OLDPROC := "" ;blank OLDPROC so subsequent calls will work if process does exist
            ProcessHandle := DllCall("OpenProcess", "Int", 16, "Int", 0, "UInt", pid)   
        }
   }
    If (ProcessHandle && DllCall("ReadProcessMemory","UInt",ProcessHandle,"UInt",MADDRESS,"Ptr",&Buffer,"UInt",BYTES,"Ptr*",bytesread))
        return bytesread
    return !ProcessHandle ? "Handle Closed:" closed : "Fail"
}



/*
    MEMORY BENCHMARKS   -   NUMGET VS NORMAL METHOD
    
    Numget is ~20x faster when iterating the unit structure and gleaming same amount of information.
      (this is achieved by dumping the entire unit structure, then using numget to retrieve the info for the units)
    It is ~10x faster when iterating same unit structure but getting 2x the information

    To just dump the raw unit structure for 993 units takes 0.050565 ms 
      (this is done via ReadMemoryDump(B_uStructure, GameIdentifier, MVALUE, 0x1C0 * getHighestUnitIndex()))

    Numget is still faster even for a single memory read!
    for example, it takes 0.007222 ms for a single normal memory read e.g. unit x position
    numget (when dumping the entire unit i.e 0x1c0 bytes) takes 0.004794 ms
    numget (when dumping just the int/ x position - 4 bytes) takes 0.004575 ms

    These numbers were averaged over 10,000 reads.

*/