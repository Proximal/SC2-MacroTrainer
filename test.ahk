SetBatchLines, -1

#SingleInstance force


GameIdentifier := "ahk_exe SC2.exe"



a := [] 

;a["hello"] := "helloV"
;a["help"] := "helpV"
;a["sss"] := "sssV"
a.insert("hello", "v1")
a.insert("help", "v2")
test(a)
objtree(a)
msgbox 



test(byref a)
{

	return 0, a.remove("hello")
}










RETURN
		encoding := "utf-16" 
		string := "abc"
		len := StrLen(String)
		includeNullTerminator := True
		encodingSize := (encoding="utf-16"||encoding="cp1200") ? 2 : 1
		requiredSize := StrPut(string, encoding) * encodingSize - (includeNullTerminator ? 0 : encodingSize)
	    VarSetCapacity(buffer, requiredSize, 0)
	    StrPut(string, &buffer, includeNullTerminator ? StrLen(string) : StrLen(string) + 1, encoding)
	    p := &buffer
	    msgbox % chr(*(p+5))
	    msgbox % strget(&buffer, len, encoding)


class memory
{
	static currentProgram, hProcess, insertNullTerminator := True

	openCloseProcess(program, dwDesiredAccess := "")
	{
		If (program != this.currentProgram)
		{
			if dwDesiredAccess is not integer
				dwDesiredAccess :=  (PROCESS_VM_OPERATION := 0x8) | (PROCESS_VM_READ := 0x10) | (PROCESS_VM_WRITE := 0x20)
			WinGet, pid, pid, % this.currentProgram := PROGRAM
			this.hProcess := ( this.hProcess 
								? 0*(closed:=DllCall("CloseHandle","UInt", this.hProcess)) 
								: 0 )+(pid 
											? DllCall("OpenProcess","UInt", dwDesiredAccess,"Int",False,"UInt",pid) 
											: 0) 
		}
		return
	}

	read(address, type := "UInt", aOffsets*)
	{
		
		if aOffsets.maxIndex()
			address := this.getAddressFromOffsets(address, aOffsets*)

		if (type = "UInt" || type = "Int")
			bytes := 4
		else if (type = "UChar" || type = "Char")
			bytes := 1		
		else if (type = "UShort" || type = "Short")
			bytes := 2
		else 
			bytes := 8
		VarSetCapacity(buffer, BYTES, 0)

		If !( this.hProcess && DllCall("ReadProcessMemory","UInt",  this.hProcess,"UInt", adddress,"Str", buffer,"UInt",BYTES,"UInt *",0))
		  return !ProcessHandle ? "Handle Closed: " closed : "Fail"
		if (bytes = 8)
		{
		  loop % BYTES 
		      result += numget(buffer, A_index-1, "Uchar") << 8 *(A_Index-1)
		  return result
		}
		return numget(buffer, 0, Type)
	}


	readString(address, length := 0, encoding := "utf-8", aOffsets*)
	{
		size  :=  (encoding ="utf-16" || encoding = "cp1200") ? 2 : 1
		ahkSize := A_IsUnicode ? 2 : 1
		VarSetCapacity(buffer, length ? length * size : size, 0)
	 
		if aOffsets.maxIndex()
			address := this.getAddressFromOffsets(address, aOffsets*)
	  
	    If !length ; read until terminator found or something goes wrong/error
		{
	        Loop
	        { 
	            success := DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", address + (A_index - 1) * size, "str", buffer, "Uint", 1, "Uint *", 0) 
	            if (ErrorLevel || !success || StrGet(&buffer + (A_index - 1) * ahkSize, Length, encoding) = "")  ; null terminator
	                break
	            string .= Output 
			} 
		}
		Else ; will read X length
		{
	        DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", address, "str", buffer, "Uint", length * size, "Uint *", 0) 
	        ;  Loop % length
	        ;     string .= chr(NumGet(Output, A_Index-1, "Char"))      
	        string := StrGet(&Output, length, encoding)
		}
		return string				
	}

	; include a null at the end of written strings for writeString()
	; can change this property 
	; memory.insertNullTerminator := False

	writeString(address, string, encoding := "utf-8", aOffsets*)
	{
		if aOffsets.maxIndex()
			address := this.getAddressFromOffsets(address, aOffsets*)

		encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1
		requiredSize := StrPut(string, encoding) * encodingSize - (this.insertNullTerminator ? 0 : encodingSize)
	    VarSetCapacity(buffer, requiredSize, 0)
	    StrPut(string, &buffer, this.insertNullTerminator ? StrLen(string) : StrLen(string) + 1, encoding)
	    DllCall("WriteProcessMemory", "UInt", this.hProcess, "UInt", address, "ptr*", buffer, "Uint", size, "Ptr*", BytesWritten)
	    return BytesWritten
	}

	getAddressFromOffsets(address, aOffsets*)
	{
   		lastOffset := aOffsets.Remove() ;remove the highest key so can use pointer to find address
		if aOffsets.maxIndex()
			address := this.pointer(address, "UInt", aOffsets*) ; pointer function requires at least one offset
		return	address += lastOffset		
	}

	write(address, value, type := "Uint", aOffsets*)
	{
		if aOffsets.maxIndex()
			address := this.getAddressFromOffsets(address, aOffsets*)
        If (type = "Int" || type = "UInt" || type = "Float" || type = "UFloat")
            bytes = 4
        Else If (TypeOrLength = "Char" || TypeOrLength = "UChar")
			bytes = 1           
        Else If (type = "Short" || type = "UShort")
            bytes = 2
		else If (type = "Double" || type = "Int64") ; Unsigned64 bit not supported by AHK
            bytes = 8
        else return "Non Supported data type"
        VarSetCapacity(buffer, bytes, 0)
        NumPut(value, buffer, 0, type)
	    DllCall("WriteProcessMemory", "UInt", this.hProcess, "UInt", address, "ptr*", value, "Uint", size, "Ptr*", 0)
		return 
	}


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
		Return this.Read(pointer, finalType)
	}


	; If the AHK.exe is 64 bit, then function will call GetWindowLongPtr
	; otherwise  it calls GetWindowLong

	getProcessBaseAddress(WindowTitle, MatchMode=3)	;WindowTitle can be anything ahk_exe ahk_class etc
	{
		SetTitleMatchMode, %MatchMode%	;mode 3 is an exact match
		WinGet, hWnd, ID, %WindowTitle%
		; AHK32Bit A_PtrSize = 4 | AHK64Bit - 8 bytes
		return := DllCall(A_PtrSize = 4
			? "GetWindowLong" 
			: "GetWindowLongPtr", "Uint", hWnd, "Uint", -6) 
	}


}


























v := 55

p := &v
msgbox %  "ascii Value: " *p ; bin 5 = ascii 53
	. "`n" chr(*p) chr(*(p+2)) ; dereferencing this gives an ascii character value

VarSetCapacity(Buffer, 4, 0)
NumPut(5, Buffer, 0, "Int")
clipboard := dectohex(&Buffer)
p := &Buffer

t := Buffer
pt := &t
msgbox % *pt

msgbox % (*p) 			; dereferencing this gives a binary value 
		. "`n" Buffer 	; buffer variable part fails as its not a string - in memory it would just be "05 00 00 00"
						; But why is it displaying part of the last messagebox? 
						; message box function can't parse the buffer variable, so it's using stored data from the last time it ran?


f2::

cb := RegisterCallback("callbackTest")

VarSetCapacity(Buffer, 4, 0)
address := NumPut(22, Buffer, 0, "Int") - A_PtrSize
msgbox % numget(address+0, "int") " i should = 22" ; expected value
msgbox % clipboard :=  &Buffer "`n" address  "`n`naddresses match" ; addresses match

; This doesn't work quite as i expected. 
; param1 and param2 have different values i.e. addresses.
; The values of param1 intrigues me, where does this address come from?


DllCall(cb, "Int*", Buffer, "ptr", &Buffer)



; This works as expected. I assume Int* causes dllcall to pass the memory address of the binary cache?
; for variable v - so dereferencing it will give a binary number
; "int", &v passes the real memory address of v, where it is stored as an AHK type - Unicode null terminated string

v := 55
DllCall(cb, "Int*", v, "int", &v)


return


callbackTest(param1, param2)
{  
	msgbox  % " p Address | p value | p deref | p numget"
		. "`n" &param1 " | " param1 " | " *param1 " | " numget(param1+0, "int")
		. "`n" &param2 " | " param2 " | " *param2 " | " numget(param2+0, "int")
}

writeStringToVar(byref var, string)
{
	if A_IsUnicode 
		size := 2, type := "short"
	else 
		size := 1, type := "char"

	if (VarSetCapacity(var) < size * len := StrLen(String))
		VarSetCapacity(var, size * len)

	loop, % len
		NumPut(Asc(SubStr(String, A_Index, 1)), var, size * (A_Index - 1), type)
	return
}