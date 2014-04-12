/*
	12/4/14
	RHCP basic memory class:

	This is a basic wrapper for commonly used read and write memory functions.
	This allows scripts to read/write integers and strings of various types.
	Pointer addresses can easily be read/written by passing the base address and offsets to the various read/write functions
	
	Process handles are kept open between reads. This increases speed.
	Note, if a program closes/restarts then the process handle will be invalid
	and you will need to re-open another handle (blank/destroy the object and then recreate the it)

	read(), readString(), write(), and writeString() can be used to read and write memory addresses respectively.

	ReadRawMemory() can be used to dump large chunks of memory, this is considerably faster when
	reading data from a large structure compared to repeated calls to read().
	Although, most people wouldn't notice the performance difference. This does however require you 
	to retrieve the values using AHK's numget()/strGet() from the dumped memory
	
	When the new operator is used this class returns a object which can be used to read that processes 
	memory space.
	To read another process simply create another object.

	process handles are automatically closed when the script exits/restarts.

	Note:
	This was written for 32 bit target processes, but the various read/write functions
	should still work when directly reading/writing an address in a 64 bit process. 
	The pointer parts of these functions wont, as I assume pointers are stored as 64bit values.

	Also very large (unsigned) 64 bit integers may not be read correctly - the current function works 
	for the 64 bit ints I use it on. AHK doesn't directly support 64bit unsigned ints anyway

	If the process has admin privileges, then the AHK script will also require admin privileges to work. 

	
	Usage:

		**Note: If you wish to try this calc example, ensure you run the 32 bit version of calc.exe - 
				which is in C:\Windows\SysWOW64\calc.exe on 64 bit systems. You can still read/write directly to
				a 64 bit calc process address (I doubt pointers will work), but the getBaseAddressOfModule() example will not work. 	

		Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
		You only need to do this once. But if the process closes, then you will need to reopen.
			calc :=	new memory("ahk_exe calc.exe")
			Note: This can be an ahk_exe, ahk_class, ahk_pid, or simply the window title. 

		
		Get the processes base address
			msgbox % calc.BaseAddress
		
		Get the base address of a module
			msgbox % calc.getBaseAddressOfModule("GDI32.dll")
		
		write 1234 to a UInt at address 0x0016CB60
			calc.write(0x0016CB60, 1234, "UInt")

		read a UInt
			value := calc.read(0x0016CB60, "UInt")

		read a pointer with offsets 0x20 and 0x15C which points to a uchar 
			value := calc.read(pointerBase, "UChar", 0x20, 0x15C)

		Note: read(), readString(), ReadRawMemory(), write(), and writeString() all support pointers/offsets
			An array of pointers can be passed directly, i.e.
			arrayPointerOffsets := [0x20, 0x15C]
			value := calc.read(pointerBase, "UChar", arrayPointerOffsets*)
			Or they can be entered manually
			value := calc.read(pointerBase, "UChar", 0x20, 0x15C)

		
		read a utf-16 null terminated string of unknown length at address 0x1234556 - the function will read each character until the null terminator is found
			string := calc.readString(0x1234556, length := 0, encoding := "utf-16")
		
		read a utf-8 encoded 12 character string at address 0x1234556
			string := calc.readString(0x1234556, 12)

		By default a null terminator is included at the end of written strings for writeString()
		The nullterminator property can be used to change this.
	 		memory.insertNullTerminator := False ; This will change the property for all processes
	 		calc.insertNullTerminator := False ; Changes the property for just this process		

*/

class memory
{
	static baseAddress, hProcess
	, insertNullTerminator := True
	, readChunkSize := 128
	, aTypeSize := {	"UChar": 	1, 	"Char":		1
					, 	"UShort":	2, 	"Short":	2
					, 	"UInt": 	4, 	"Int": 		4
					, 	"UFloat": 	4, 	"Float": 	4
					,	"Int64": 	8, 	"Double": 	8} 	

					; Although unsigned 64bit values are not supported, you can read them as int64 or doubles and interpret
					; the negative numbers as large values

	; The byRef handle can be used to check if it opened the process successfully
	; otherwise can check if the returned value is an object
	; Refer to openProcess() method for details on these parameters
	__new(program, dwDesiredAccess := "", byRef handle := "", windowMatchMode := 3)
	{
		if !(handle := this.openProcess(program, dwDesiredAccess, windowMatchMode))
			return ""
		this.BaseAddress := this.getProcessBaseAddress(program, windowMatchMode)
		return this
	}
	__delete()
	{
		this.closeProcess(this.hProcess)
		return
	}

	; program can be an ahk_exe, ahk_class, ahk_pid, or simply the window title. e.g. "ahk_exe SC2.exe" or "Starcraft II"
	; but its safer not to use the window title, as some things can have the same window title - e.g. a folder called "Starcraft II"
	; would have the same window title as the game itself.

	; To use the scripts current setting for SetTitleMatchMode, simply pass 0 or A_TitleMatchMode as
	; the windowMatchMode parameter
	openProcess(program, dwDesiredAccess := "", windowMatchMode := 3)
	{
		; if an application closes/restarts the previous handle becomes invalid so reopen it to be safe (closing a now invalid handle is fine i.e. wont cause an issue)
		
		; This default access level is sufficient to read and write memory addresses.
		; if the program is run using admin privileges, then this script will also need admin privileges
		if dwDesiredAccess is not integer
			dwDesiredAccess := (PROCESS_QUERY_INFORMATION := 0x0400) | (PROCESS_VM_OPERATION := 0x8) | (PROCESS_VM_READ := 0x10) | (PROCESS_VM_WRITE := 0x20)
		if windowMatchMode
		{
			mode :=  A_TitleMatchMode
			SetTitleMatchMode, %windowMatchMode%
		}
		WinGet, pid, pid, % this.currentProgram := program
		if windowMatchMode
			SetTitleMatchMode, %mode%    ; In case executed in autoexec
		if !pid
			return  this.hProcess := 0 
		return this.hProcess := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", pid) ; NULL/Blank if failed to open process for some reason
	}	

	; When the script exits/restarts any open handles will automatically be closed!
	; That is, you don't need to call this function.
	closeProcess(hProcess)
	{
		; if as an error when opening handle, handle will be null
		if hProcess
			return DllCall("CloseHandle", "UInt", hProcess)
		return
	}
	
	; reads various integer type values
	; When reading doubles, adjusting "SetFormat, float, totalWidth.DecimalPlaces" may be required depending on your requirements.
	read(address, type := "UInt", aOffsets*)
	{
      	VarSetCapacity(buffer, bytes := this.aTypeSize[type])
		if !DllCall("ReadProcessMemory","UInt",  this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "UInt", bytes, "Ptr",0)
		  return !this.hProcess ? "Handle Is closed: " this.hProcess : "Fail"
		return numget(buffer, 0, Type)
	}
	; This is used to dump large chunks of memory. Values can later be retried from the buffer using AHK's numget()/strget()
	; this offers a SIGNIFICANT (~30% and up for large areas) performance boost for large memory structures,
	; as calling ReadProcessMemory for 4 bytes takes a similar amount of time as it does to read 1,000 bytes

	ReadRawMemory(address, byref buffer, bytes := 4, aOffsets*)
	{
		VarSetCapacity(buffer, bytes)
		if !DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "UInt", bytes, "Ptr*", bytesRead)
			return !this.hProcess ? "Handle Is closed: " this.hProcess : "Fail"
		return bytesRead
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
				success := DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", address + (A_index - 1) * this.readChunkSize, "Ptr", &buffer, "Uint", this.readChunkSize, "Ptr", 0) 
				if (ErrorLevel || !success)
				{
					if (A_Index = 1 && !this.hProcess)
						return "Handle Is closed: " this.hProcess
					else if (A_index = 1 && this.hProcess)
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
	        if !DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", address, "Ptr", &buffer, "Uint", length * size, "Ptr", 0)   
	        	return !this.hProcess ? "Handle Is closed: " this.hProcess : "Fail"
	        string := StrGet(&buffer, length, encoding)
		}
		return string				
	}

	; by default a null terminator is included at the end of written strings for writeString()
	; This property can be changed i.e.
	; memory.insertNullTerminator := False ; This will change the property for all processes
	; calc.insertNullTerminator := False ; Changes the property for just this process

	writeString(address, string, encoding := "utf-8", aOffsets*)
	{
		encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1
		requiredSize := StrPut(string, encoding) * encodingSize - (this.insertNullTerminator ? 0 : encodingSize)
	    VarSetCapacity(buffer, requiredSize)
	    StrPut(string, &buffer, this.insertNullTerminator ? StrLen(string) : StrLen(string) + 1, encoding)
	    DllCall("WriteProcessMemory", "UInt", this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Uint", requiredSize, "Ptr*", BytesWritten)
	    return BytesWritten
	}

	write(address, value, type := "Uint", aOffsets*)
	{
        if !bytes := this.aTypeSize[type]
	        return "Non Supported data type" ; Unsigned64 bit not supported by AHK
	    VarSetCapacity(buffer, bytes)
        NumPut(value, buffer, 0, type)
	  	return DllCall("WriteProcessMemory", "UInt", this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Uint", bytes, "Ptr", 0) 
	}

	; This can be used to read various numeric pointer types (the the other various read/write functions can do this too!)
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

	; WindowTitle can be anything ahk_exe ahk_class etc
	getProcessBaseAddress(WindowTitle, windowMatchMode := 3)   
	{
		if windowMatchMode
		{
	    	mode := A_TitleMatchMode
	    	SetTitleMatchMode, %windowMatchMode%    ;mode 3 is an exact match
		}
	    WinGet, hWnd, ID, %WindowTitle%
	    if windowMatchMode
	    	SetTitleMatchMode, %mode%    ; In case executed in autoexec
	    if !hWnd
	        return ; return blank failed to find window
	   ; GetWindowLong returns a Long (Int) and GetWindowLongPtr return a Long_Ptr
	    BaseAddress := DllCall(A_PtrSize = 4
	        ? "GetWindowLong"
	        : "GetWindowLongPtr", "Ptr", hWnd, "Uint", -6, "UInt")
	    
	    return BaseAddress ; If DLL call fails, returned value will = 0
	}	

	; http://winprogger.com/getmodulefilenameex-enumprocessmodulesex-failures-in-wow64/
	; http://stackoverflow.com/questions/3801517/how-to-enum-modules-in-a-64bit-process-from-a-32bit-wow-process

	/*
		_MODULEINFO := "
						(
						  LPVOID lpBaseOfDll;
						  DWORD  SizeOfImage;
						  LPVOID EntryPoint;
					  	)"

	*/
	; If no module is specified, the address of the base module - main() e.g. C:\Games\StarCraft II\Versions\Base28667\SC2.exe
	; will be returned. Otherwise specify the module/dll to find e.g. Battle.net.dll.
	; requires PROCESS_QUERY_INFORMATION + PROCESS_VM_READ (which is included by default with this class)
	; Note: A 64 bit AHK can enumerate the modules of a target 64 or 32 bit process.
	;  		A 32 bit AHK can only enumerate the modules of a 32 bit process
	getBaseAddressOfModule(module := "")
	{

		if !this.hProcess
			return -2

		if (A_PtrSize = 4) ; AHK 32bit
		{
			DllCall("IsWow64Process", "Ptr", this.hProcess, "Int*", result)
			if !result 
				return -4 ; AHK is 32bit and target process is 64 bit, this function wont work
		}

		if !module
		{
			VarSetCapacity(mainExeNameBuffer, 2048 * (A_IsUnicode ? 2 : 1))
			DllCall("psapi\GetModuleFileNameEx", "Ptr", this.hProcess, "Uint", 0
						, "Ptr", &mainExeNameBuffer, "Uint", 2048 / (A_IsUnicode ? 2 : 1))
			mainExeName := StrGet(&mainExeNameBuffer)
			; mainExeName = main executable module of the process
		}
		size := VarSetCapacity(lphModule, 4)
		loop 
		{
			DllCall("psapi\EnumProcessModules", "Ptr", this.hProcess, "Ptr", &lphModule
					, "Uint", size, "Uint*", reqSize)
			if ErrorLevel
				return -3
			else if (size >= reqSize)
				break
			else 
				size := VarSetCapacity(lphModule, reqSize)	
		}
		VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1))
		loop % reqSize / A_PtrSize ; sizeof(HMODULE) - enumerate the array of HMODULEs
		{
			DllCall("psapi\GetModuleFileNameEx", "Ptr", this.hProcess, "Uint", numget(lphModule, (A_index - 1) * A_PtrSize)
					, "Ptr", &lpFilename, "Uint", 2048 / (A_IsUnicode ? 2 : 1))

			; Use Instr() as module will contain directory path as well
			if (!module && mainExeName = StrGet(&lpFilename) || module && instr(StrGet(&lpFilename), module))
			{
				VarSetCapacity(MODULEINFO, A_PtrSize = 4 ? 12 : 24)
				DllCall("psapi\GetModuleInformation", "Ptr", this.hProcess, "UInt", numget(lphModule, (A_index - 1) * A_PtrSize)
					, "Ptr", &MODULEINFO, "UInt", A_PtrSize = 4 ? 12 : 24)
				return numget(MODULEINFO, 0, "Ptr")
			}
		}
		return -1 ; not found
	}

}

/*

	ReadRawMemoryTest(address, byref buffer, bytes := 4, byref bytesReadR := 0, aOffsets*)
	{
		VarSetCapacity(buffer, bytes)
		if !DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "UInt", bytes, "Ptr*", bytesRead)
		{
			if !bytesRead
			{
				bytesReadR := bytesRead
				return "Error " DllCall("GetLastError") "`nBytes Read: " bytesRead
			}
		}
		return bytesRead
	}

	; Return values
	; -1 	An odd number of characters were passed via pattern
	;		Ensure you use two digits to represent each byte i.e. 05, 0F and ??, and not 5, F or ?
	; int 	represents the number of non-wildcard bytes in the search pattern/needle

	setPattern(pattern, byRef aOffsets, byRef binaryNeedle)
	{
		StringReplace, pattern, pattern, %A_Space%,, All
		StringReplace, pattern, pattern, %A_Tab%,, All
		pattern := RTrim(pattern, "?")				; can pass patterns beginning with ?? ?? - but it is a little pointless
		loopCount := bufferSize := StrLen(pattern) / 2
		if Mod(StrLen(pattern), 2)
			return -1 
		VarSetCapacity(binaryNeedle, bufferSize)
		aOffsets := [], startGap := 0 ;, prevChar := "??"
		loop, % loopCount
		{
			hexChar := SubStr(pattern, 1 + 2 * (A_Index - 1), 2)
			if (hexChar != "??") && (prevChar = "??" || A_Index = 1)
				binNeedleStartOffset := A_index - 1
			else if (hexChar = "??" && prevChar != "??" && A_Index != 1) 
			{

				aOffsets.Insert({ "binNeedleStartOffset": binNeedleStartOffset
								, "binNeedleSize": A_Index - 1 - binNeedleStartOffset
								, "binNeedleGap": !aOffsets.MaxIndex() ? 0 : binNeedleStartOffset - startGap + 1}) ; equals number of wildcard bytes between two sub needles
				startGap := A_index
			}

			if (A_Index = loopCount) ; last char cant be ??
				aOffsets.Insert({ "binNeedleStartOffset": binNeedleStartOffset
								, "binNeedleSize": A_Index - binNeedleStartOffset
								, "binNeedleGap": !aOffsets.MaxIndex() ? 0 : binNeedleStartOffset - startGap + 1})

			prevChar := hexChar
			if (hexChar != "??")
			{
				numput("0x" . hexChar, binaryNeedle, A_index - 1, "UChar")
				realNeedleSize++
			}
		}
		return realNeedleSize
	}



	; This function will only WORK with AHK 32 bit builds!
	; I'll improve this another time
	; need to setup module / memory area scanning, so it only reads addresses which have read access
	patternScan(pattern, startAddress, maxOffsetMB := 0, byRef returnAddressAndOffset := 0, dumpSizeMB := 50)
	{
		realNeedleSize := this.setPattern(pattern, aOffsets, binaryNeedle)
		if (realNeedleSize = -1 || realNeedleSize = 0)
			return -2 ;invlaid pattern was passed 
		haystackSizeBytes := dumpSizeMB * 1048576   ;1048576 bytes in a MB
		haystackSizeBytes := 30   ;1048576 bytes in a MB
		maxAddress := startAddress + (maxOffsetMB * 1048576)
		bytesRead := 0

		loop 
		{	
			aaaaindex := A_Index
			currentStartAddress := startAddress + bytesRead ; change this so it starts 1 full needle back from edge
			if (maxOffsetMB && currentStartAddress >= maxAddress) 		
				msgbox past final address
			;	return -1 ; notfound 
			
			if (haystackSizeBytes != bytesRead :=  this.ReadRawMemoryTest(currentStartAddress, Haystack, haystackSizeBytes))
			{
				if !bytesRead
				{
					return " read failed - Probably reading part an area which cannot be read"
				}
			}
			;	msgbox % "here currentStartAddress "  chex(currentStartAddress) "`nbytesRead " bytesRead
			;	return -3 ; failed to dump part of the process memory
			currentStartOffstet := 0
			haystackOffset := 0
			aOffset := aOffsets[arrayIndex := 1]

			loop
			{

				if (-1 != foundOffset := this.scanInBuf(&Haystack, &binaryNeedle + aOffset.binNeedleStartOffset, haystackSizeBytes, aOffset.binNeedleSize, haystackOffset))
				{

					if (arrayIndex = 1 || foundOffset = haystackOffset)
					{		
							
						if (arrayIndex = 1)
						{
							currentStartOffstet := aOffset.binNeedleSize + foundOffset ; save the offset of the match for the first part of the needle - if remainder of needle doesn't match,  resume search from here
							tmpfoundAddress := foundOffset
							;msgbox % "tmpfoundAddress " tmpfoundAddress := foundOffset
						}
						if (arrayIndex = aOffsets.MaxIndex())
						{
							foundAddress := tmpfoundAddress - aOffsets[1].binNeedleStartOffset ; deduct the first needles starting offset - in case user passed a pattern beginning with ?? eg "?? ?? 00 55"
							break, 2
						}	
						;msgbox % haystackOffset " haystackOffset" "`ncurrentStartOffstet " currentStartOffstet
						prevNeedleSize := aOffset.binNeedleSize
						aOffset := aOffsets[++arrayIndex]
						;silly := aOffset.binNeedleGap
						;msgbox foundOffset %foundOffset% `nprevNeedleSize %prevNeedleSize%`naOffset.binNeedleGap %silly%
						haystackOffset := foundOffset + prevNeedleSize + aOffset.binNeedleGap   ; move the start of the haystack ready for the next needle - accounting for previous needle size and any gap/wildcard-bytes between the two needles
						;msgbox % haystackOffset " haystackOffset"
						continue
					}
				}
				
				if (arrayIndex = 1) ; couldn't find the first part of the needle so dump the next chunk of memory
				{
					break
				}
				else 		; the subsequent parts of the needle couldn't be found. So resume search from the address immediately next to where the first part of the needle was found
				{	
					aOffset := aOffsets[arrayIndex := 1]
					haystackOffset := currentStartOffstet
				}

			}
		}
		if foundAddress
		 return 1, returnAddressAndOffset += startAddress + foundAddress
		else return 0
	}

	;Doesn't WORK with AHK 64 BIT, only works with AHK 32 bit
	;taken from:
	;http://www.autohotkey.com/board/topic/23627-machine-code-binary-buffer-searching-regardless-of-null/
	; -1 not found else returns offset address (starting at 0)
	scanInBuf(haystackAddr, needleAddr, haystackSize, needleSize, StartOffset = 0)
	{  static fun

		; AHK32Bit a_PtrSize = 4 | AHK64Bit - 8 bytes
		if (a_PtrSize = 8)
		  return -1

		ifequal, fun,
		{
		  h =
		  (  LTrim join
		     5589E583EC0C53515256579C8B5D1483FB000F8EC20000008B4D108B451829C129D9410F8E
		     B10000008B7D0801C78B750C31C0FCAC4B742A4B742D4B74364B74144B753F93AD93F2AE0F
		     858B000000391F75F4EB754EADF2AE757F3947FF75F7EB68F2AE7574EB628A26F2AE756C38
		     2775F8EB569366AD93F2AE755E66391F75F7EB474E43AD8975FC89DAC1EB02895DF483E203
		     8955F887DF87D187FB87CAF2AE75373947FF75F789FB89CA83C7038B75FC8B4DF485C97404
		     F3A775DE8B4DF885C97404F3A675D389DF4F89F82B45089D5F5E5A595BC9C2140031C0F7D0
		     EBF0
		  )
		  varSetCapacity(fun, strLen(h)//2)
		  loop % strLen(h)//2
		     numPut("0x" . subStr(h, 2*a_index-1, 2), fun, a_index-1, "char")
		}

		return DllCall(&fun, "uInt", haystackAddr, "uInt", needleAddr
		              , "uInt", haystackSize, "uInt", needleSize, "uInt", StartOffset)
	}





	

}
http://www.autohotkey.com/board/topic/73813-which-uint-needs-to-be-ptr-for-64bit-scripts/
*/