



/*
	This is a basic wrapper for commonly used read and write memory functions.
	This allows scripts to read/write integers and strings of various types.
	Pointer addresses can easily be read/written by passing the base address and offsets to the various read/write functions
	
	Process handles are kept open between reads. This increases speed.
	Note, if a program closes/restarts then the process handle will be invalid
	and you will need to re-open another handle.

	read(), readString(), write(), and writeString() can be used to read and write memory addresses respectively.

	switchTargetProgram() can be used to facilitate reading memory from multiple processes in the one script.

	ReadRawMemory() can be used to dump large chunks of memory, this is considerably faster when
	reading data from a large structure compared to repeated calls to read().
	Although, most people wouldn't notice the performance difference. This does however require you 
	to retreive the values using AHK's numget()/strGet() from the dumped memory
	
	Note:
	This was written for 32 bit processes, but the various read/write functions
	should still work when directly reading/writing an address. The pointer parts of
	these functions probably wont, as I assume pointers are stored as 64bit values.

	Also very large (unsigned) 64 bit integers may not be read correctly - the current function works 
	for the 64 bit ints I use it on. AHK doesn't directly support 64bit unsigned ints anyway

	
	Usage:

		open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
			memory.openProcess("ahk_exe calc.exe")
		Note: This can be an ahk_exe, ahk_class, ahk_pid, or simply the window title. 

		write 1234 to a UInt
			memory.write(0x0016CB60, 1234, "UInt")

		read a UInt
			value := memory.read(0x0016CB60, "UInt")

		read a pointer with offsets 0x20 and 0x15C which points to a uchar 
			value := memory.read(pointerBase, "UChar", 0x20, 0x15C)

		Note: read(), readString(), ReadRawMemory(), write(), and writeString() all support pointers/offsets
			An array of pointers can be passed directly, i.e.
			arrayPointerOffsets := [0x20, 0x15C]
			value := memory.read(pointerBase, "UChar", arrayPointerOffsets*)
			Or they can be entered manually
			value := memory.read(pointerBase, "UChar", 0x20, 0x15C)

		
		read a utf-16 null terminated string of unknown length at address 0x1234556 - the function will read each character until the null terminator is found
			string := memory.readString(0x1234556, length := 0, encoding := "utf-16")
		
		read a utf-8 encoded 12 character string at address 0x1234556
			string := memory.readString(0x1234556, 12)

		Close ALL currently open handles - this should be done before the script exits
			memory.closeProcess()
		close a handle to an individual program 
			memory.closeProcess("ahk_exe calc.exe")
		Note: You need to pass the exact same program/string that you used to open the process i.e. openProcess("ahk_exe calc.exe")

*/

class memory
{
	static currentProgram, hProcessCurrent, insertNullTerminator := True, aProcessHandles := [], readChunkSize := 128
	, aTypeSize := {	"UChar": 1, 	"Char": 1
					, 	"UShort": 2, 	"Short": 2
					, 	"UInt": 4, 		"Int": 4
					, 	"UFloat": 4, 	"Float": 4
					,	"Int64": 8, 	"Double": 8} 	

					; Although unsigned 64bit values are not supported, you can read them as int64 or doubles and interpret
					; the negative numbers as large values


	; program can be an ahk_exe, ahk_class, ahk_pid, or simply the window title. e.g. "ahk_exe SC2.exe" or "Starcraft II"
	; but its safer not to use the window title, as some things can have the same window title - e.g. a folder called "Starcraft II"
	; would have the same window title as the game itself.

	openProcess(program, dwDesiredAccess := "")
	{
		; if an application closes/restarts the previous handle becomes invalid so reopen it to be safe (closing a now invalid handle is fine i.e. wont cause an issue)
		if this.aProcessHandles.hasKey(program)
			this.closeProcess(program)
		; This default access level is sufficient to read and write memory addresses.
		; if the program is run using admin privileges, then this script will also need admin privileges
		if dwDesiredAccess is not integer
			dwDesiredAccess := (PROCESS_VM_OPERATION := 0x8) | (PROCESS_VM_READ := 0x10) | (PROCESS_VM_WRITE := 0x20)
		WinGet, pid, pid, % this.currentProgram := program
		if !pid
			return 0, this.currentProgram := "" ; Process Doesn't Exist
		this.aProcessHandles.Insert(program, this.hProcessCurrent := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", pid))
		return this.hProcessCurrent	 ; NULL/Blank if failed to open process for some reason
	}	

	; To close all open handles, simply call memory.closeProcess() without a parameter
	; good programming practices says you should call this function before exiting the script
	closeProcess(program := "")
	{
		if !program
		{
			For program, handle in this.aProcessHandles
				closed .= (A_Index = 1 ? "" : "`n") program " - " handle " - " DllCall("CloseHandle", "UInt", handle)
			this.aProcessHandles := []
			this.hProcessCurrent := this.currentProgram := ""
			return closed
		}
		else if this.aProcessHandles.HasKey(program)
		{
			closed := program " - " this.aProcessHandles[program] " - " DllCall("CloseHandle", "UInt", this.aProcessHandles[program])
			this.aProcessHandles.Remove(program)
			if (program = this.currentProgram)
				this.hProcessCurrent := this.currentProgram := ""
			return closed
		}
		else 
			return 0 ; Program didn't have a handle
	}

	; This can be used if you're reading memory from multiple processes e.g multi boxing
	; simply call memory.switchTargetProgram(program) before each call to a different process
	switchTargetProgram(program)
	{
		if this.aProcessHandles.HasKey(program)
			return this.hProcessCurrent := this.aProcessHandles[program], this.currentProgram := program
		else
			return this.OpenProcess(program) ; sets current Program and process handle
	}

	; reads various integer type values
	; When reading doubles, adjusting "SetFormat, float, totalWidth.DecimalPlaces" may be required depending on your requirements.
	read(address, type := "UInt", aOffsets*)
	{
      	VarSetCapacity(buffer, bytes := this.aTypeSize[type])
		if !DllCall("ReadProcessMemory","UInt",  this.hProcessCurrent, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "UInt", bytes, "Ptr",0)
		  return !this.hProcessCurrent ? "Handle Is closed: " this.hProcessCurrent : "Fail"
		return numget(buffer, 0, Type)
	}
	; This is used to dump large chunks of memory. Values can later be retried from the buffer using AHK's numget()/strget()
	; this offers a SIGNIFICANT (~30% and up for large areas) performance boost,
	; as calling ReadProcessMemory for 4 bytes takes a similar amount of time as it does to read 1000 bytes

	ReadRawMemory(address, byref buffer, bytes := 4, aOffsets*)
	{
		VarSetCapacity(buffer, bytes)
		if !DllCall("ReadProcessMemory", "UInt", this.hProcessCurrent, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "UInt", bytes, "Ptr", 0)
			return !this.hProcessCurrent ? "Handle Is closed: " this.hProcessCurrent : "Fail"
		return
	}

	; Encoding refers to how the string is stored in the program's memory - probably uft-8 or utf-16
	; If length is 0, readString() will read the string until it finds a null terminator (or an error occurs)

	readString(address, length := 0, encoding := "utf-8", aOffsets*)
	{
		size  := (encoding ="utf-16" || encoding = "cp1200") ? 2 : 1
		VarSetCapacity(buffer, length ? length * size : (this.readChunkSize < size ? this.readChunkSize := size : this.readChunkSize), 0)
	 
		if aOffsets.maxIndex()
			address := this.getAddressFromOffsets(address, aOffsets*)

		if !length  ; read until null terminator is found or something goes wrong
		{
			VarSetCapacity(string, this.readChunkSize * 2) 		; this is absolutely not needed, but if you're reading large strings from memory
																; performance can be slightly improved by increasing readchunksize
																; e.g. memory.readChunkSize := 1024
																; the *2 multiplier in varsetcapacity() can also be increased to improve long string concatenations. 
			Loop
			{
				; read a chunk of x size, rather than one/two bytes at a time, as each ReadProcessMemory call is relatively slow
				success := DllCall("ReadProcessMemory", "UInt", this.hProcessCurrent, "UInt", address + (A_index - 1) * this.readChunkSize, "Ptr", &buffer, "Uint", this.readChunkSize, "Ptr", 0) 
				if (ErrorLevel || !success)
				{
					if (A_Index = 1 && !this.hProcessCurrent)
						return "Handle Is closed: " this.hProcessCurrent
					else if (A_index = 1 && this.hProcessCurrent)
					 	return "Fail"
					 else 
					 	break
				}
				loop, % this.readChunkSize / size
				{
					if ("" = char := StrGet(&buffer + (A_Index -1) * size, 1, encoding))
						break, 2
					string .= char
				}
			 	; don't need to blank the buffer as it will be completely overwritten, if the readmemory fails (very unlikely) then loop gets broken anyway
			}
		}
		Else ; will read X length
		{
	        if !DllCall("ReadProcessMemory", "UInt", this.hProcessCurrent, "UInt", address, "Ptr", &buffer, "Uint", length * size, "Ptr", 0)   
	        	return !this.hProcessCurrent ? "Handle Is closed: " this.hProcessCurrent : "Fail"
	        string := StrGet(&buffer, length, encoding)
		}
		return string				
	}

	; by default a null terminator is included at the end of written strings for writeString()
	; This property can be changed i.e.
	; memory.insertNullTerminator := False

	writeString(address, string, encoding := "utf-8", aOffsets*)
	{
		encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1
		requiredSize := StrPut(string, encoding) * encodingSize - (this.insertNullTerminator ? 0 : encodingSize)
	    VarSetCapacity(buffer, requiredSize)
	    StrPut(string, &buffer, this.insertNullTerminator ? StrLen(string) : StrLen(string) + 1, encoding)
	    DllCall("WriteProcessMemory", "UInt", this.hProcessCurrent, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Uint", requiredSize, "Ptr*", BytesWritten)
	    return BytesWritten
	}

	write(address, value, type := "Uint", aOffsets*)
	{
        if !bytes := this.aTypeSize[type]
	        return "Non Supported data type" ; Unsigned64 bit not supported by AHK
	    VarSetCapacity(buffer, bytes)
        NumPut(value, buffer, 0, type)
	  	return DllCall("WriteProcessMemory", "UInt", this.hProcessCurrent, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Uint", bytes, "Ptr", 0) 
	}

	; This can be used to read various numeric pointer types (the the other various read functions can do this too!)
	; This function is now mainly used by the other functions to find the final pointer address

	; final type refers to the how the value is stored in the final pointer address
	; Can pass an array of offsets by using *
	; eg, pointer(game, base, [0x10, 0x30, 0xFF]*)
	; or a := [0x10, 0x30, 0xFF]
	; pointer(game, base, a*)
	; or just type them in manually

	pointer(base, finalType := "UInt", offsets*)
	{ 

		For index, offset in offsets
		{
			if (index = offsets.maxIndex() && A_index = 1)
				pointer := offset + this.Read(base)
			Else 
			{
				IF (A_Index = 1) 
					pointer := this.Read(offset + this.Read(base))
				Else If (index = offsets.MaxIndex())
					pointer += offset
				Else pointer := this.Read(pointer + offset)
			}
		}	
		Return this.Read(offsets.maxIndex() ? pointer : base, finalType)
	}

	getAddressFromOffsets(address, aOffsets*)
	{
   		lastOffset := aOffsets.Remove() ;remove the highest key so can use pointer() to find final memory address (minus the last offset)
		return	this.pointer(address, "UInt", aOffsets*) + lastOffset		
	}

	; The base adress for some programs is dynamic. This can retrieve the current base address, 
	; which can then be added to your various offsets

	getProcessBaseAddress(WindowTitle, MatchMode=3)	;WindowTitle can be anything "ahk_exe SC2.exe"  "ahk_class xxxx" window title etc
	{
		SetTitleMatchMode, %MatchMode%	;mode 3 is an exact match
		WinGet, hWnd, ID, %WindowTitle%
		; AHK32Bit A_PtrSize = 4 | AHK64Bit - 8 bytes
		return := DllCall(A_PtrSize = 4
			? "GetWindowLong" 
			: "GetWindowLongPtr", "Uint", hWnd, "Uint", -6) 
	}


}