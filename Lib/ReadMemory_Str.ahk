; Automatically closes handle when a new (or null) program is indicated
; Otherwise, keeps the process handle open between calls that specify the
; same program. When finished reading memory, call this function with no
; parameters to close the process handle i.e: "Closed := ReadMemory_Str()"

; the lengths probably depend on the encoding style, but for my needs they are always 1

;//function ReadMemory_Str 
ReadMemory_Str(MADDRESS=0, PROGRAM = "StarCraft II", length = 0 , terminator = "")  ; "" = Null
{ 
   Static OLDPROC, ProcessHandle

   If (PROGRAM != OLDPROC || !ProcessHandle)
   {
        WinGet, pid, pid, % OLDPROC := PROGRAM
        ProcessHandle := ( ProcessHandle ? 0*(closed:=DllCall("CloseHandle"
        ,"UInt",ProcessHandle)) : 0 )+(pid ? DllCall("OpenProcess"
        ,"Int",16,"Int",0,"UInt",pid) : 0) ;PID is stored in value pid
   }
   ; length depends on the encoding too
    VarSetCapacity(Output, length ? length : 1, 0)
	If !length ; read until terminator found or something goes wrong/error
	{
        Loop
        { 
            success := DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS++, "str", Output, "Uint", 1, "Uint *", 0) 
            if (ErrorLevel or !success || Output = terminator) 
                break
            teststr .= Output 
		} 
	}		
	Else ; will read until X length
	{
        DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "str", Output, "Uint", length, "Uint *", 0) 
        ;  Loop % length
        ;     teststr .= chr(NumGet(Output, A_Index-1, "Char"))      
        teststr := StrGet(&Output, length, "UTF-8")
	}
	return teststr 	 
}