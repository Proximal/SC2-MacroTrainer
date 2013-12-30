SetBatchLines, -1

#SingleInstance force
var := 0

msgbox % test() " " var
msgbox % var



test()
{
	global 
	var := 0
	return ++var, ++var
}










start := A_TickCount
type := "UShort"
loop, % count := 20000000	
{
	if !bytes := aTypeSize[type]
		break

}
msgbox % (A_TickCount - start) / count "`n" bytes
return 

	if (type = "UInt" || type = "Int")
		bytes := 4
	else if (type = "UChar" || type = "Char")
		bytes := 1		
	else if (type = "UShort" || type = "Short")
		bytes := 2
	else 
		bytes := 8
; .000308
; .000205
StrPutVar(string, ByRef var, encoding)
{
    ; Ensure capacity.
    VarSetCapacity( var, StrPut(string, encoding)
        ; StrPut returns char count, but VarSetCapacity needs bytes.
        * ((encoding="utf-16"||encoding="cp1200") ? 2 : 1) )
    ; Copy or convert the string.
    return StrPut(string, &var, encoding)
}

; Calculate required buffer space for a string.
bytes_per_char := A_IsUnicode ? 2 : 1
max_chars := 500
max_bytes := max_chars * bytes_per_char

Loop 2
{
    ; Allocate space for use with DllCall.
    VarSetCapacity(buf, max_bytes)

    if A_Index = 1
        ; Alter the variable indirectly via DllCall.
        DllCall("wsprintf", "ptr", &buf, "str", "0x%08x", "uint", 4919)
    else
        ; Use "str" to update the length automatically:
    	DllCall("wsprintf", "str", buf, "str", "0x%08x", "uint", 4919)

    ; Concatenate a string to demonstrate why the length needs to be updated:
    wrong_str := buf . "<end>"
    wrong_len := StrLen(buf)

    ; Update the variable's length.
    VarSetCapacity(buf, -1)

    right_str := buf . "<end>"
    right_len := StrLen(buf)

    MsgBox,
    (
    Before updating
      String: %wrong_str%
      Length: %wrong_len%

    After updating
      String: %right_str%
      Length: %right_len%
    )
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