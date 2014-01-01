SetBatchLines, -1
#SingleInstance force
#InstallKeybdHook
#UseHook On
SendMode Input

/* Tested
"11 11 22 11 22 00 00 5E 68 00 5E 68 11 5E 68"
"11 22 ?? ?? 5E ??"
"11 11 22 11 22"


*/

                                  ;0  1  2  3  4  5  6  7  8  9  10 11 12 13 14
haystackSize := hexToBinaryBuffer("11 44 22 11 22 00 00 5E 68 00 5E 68 11 5E 68", Haystack)
;msgbox % scanInBuf(&Haystack, &needle, haystackSize, needleSize, 1)
realNeedleSize := makePattern(                   "00 00 5E ?? ?? ?? 68 ?? ?? 68", aOffsets, binaryNeedle)
objtree(aOffsets)
;0   1  2  3  4 5  6  7
;22 ?? 22 ?? ?? ?? 33 33
makePattern(pattern, byRef aOffsets, byRef binaryNeedle)
{
	StringReplace, pattern, pattern, %A_Space%,, All
	StringReplace, pattern, pattern, %A_Tab%,, All
	pattern := Trim(pattern, "?")
	loopCount := bufferSize := StrLen(pattern) / 2
	VarSetCapacity(binaryNeedle, bufferSize)
	aOffsets := [], startGap := 0
	loop, % loopCount
	{
		hexChar := SubStr(pattern, 1 + 2 * (A_Index - 1), 2)
		if (hexChar != "??" && prevChar = "??" || A_Index = 1)
			binNeedleStartOffset := A_index - 1
		else if (hexChar = "??" &&  prevChar != "??") ; last char cant be ??
		{

			aOffsets.Insert({ "binNeedleStartOffset": binNeedleStartOffset
							, "binNeedleSize": A_Index - 1 - binNeedleStartOffset
							, "binNeedleGap": !aOffsets.MaxIndex() ? 0 : binNeedleStartOffset - startGap + 1}) ; 1 refers to next byte
			startGap := A_index
		}

		if (A_Index = loopCount)
			aOffsets.Insert({ "binNeedleStartOffset": binNeedleStartOffset
							, "binNeedleSize": A_Index - binNeedleStartOffset
							, "binNeedleGap": binNeedleStartOffset - startGap + 1})

		prevChar := hexChar
		if (hexChar != "??")
		{
			numput("0x" . hexChar, binaryNeedle, A_index - 1, "UChar")
			realNeedleSize++
		}
	}
	return realNeedleSize
}




;			  0  1 2  3  4  5  6  7  8  9  10 11 12 13 14
find :=    	"11 11 22 11 22 00 00 5E 68 00 5E 68 11 5E 68"
pattern :=	"            22 ?? ?? 5E ?? ?? 5E"

aOffset := []	
loop 1
{
	foundAddress := -1
	;dumpSize := 1048576	* 50				; 1048576 bytes in a MB - want 50 MB chunks
	;dumpSize += mod(dumpSize, realNeedleSize)  ; ensure the needle evenly divides into the dump
	currentStartOffstet := 0
	aOffset := aOffsets[arrayIndex := 1]
	haystackChunkOffset := 0

	loopCount := dumpSize / realNeedleSize
	loopCount := haystackSize / realNeedleSize

	loop,
	{
		lookingFor := ""
		loop % aOffset.binNeedleSize
		{
			lookingFor .= chex(numget(&binaryNeedle, aOffset.binNeedleStartOffset + A_Index -1, "Uchar")) " "
		}
		;msgbox % "haystackChunkOffset " haystackChunkOffset
		;	. "`n" lookingFor
		;	. "`nAt need Offset " aOffset.binNeedleStartOffset 
		

		if (-1 != foundOffset := scanInBuf(&Haystack, &binaryNeedle + aOffset.binNeedleStartOffset, haystackSize, aOffset.binNeedleSize, haystackChunkOffset))
		{
			;msgbox % arrayIndex  "arrayIndex`n" 
			;	. "foundOffset "foundOffset " aOffset.binNeedleGap " aOffset.binNeedleGap  " + " " haystackChunkOffset " haystackChunkOffset


			if (arrayIndex = 1 || foundOffset = haystackChunkOffset)
			{		
					
				if (arrayIndex = 1)
				{
					currentStartOffstet := aOffset.binNeedleSize + foundOffset
					tmpfoundAddress := foundOffset
					;msgbox % "tmpfoundAddress " tmpfoundAddress := foundOffset
				}
				if (arrayIndex = aOffsets.MaxIndex())
				{
					foundAddress := tmpfoundAddress
					break, 2
				}	
				;msgbox % haystackChunkOffset " haystackChunkOffset" "`ncurrentStartOffstet " currentStartOffstet
				prevNeedleSize := aOffset.binNeedleSize
				aOffset := aOffsets[++arrayIndex]
				silly := aOffset.binNeedleGap
				;msgbox foundOffset %foundOffset% `nprevNeedleSize %prevNeedleSize%`naOffset.binNeedleGap %silly%
				haystackChunkOffset := foundOffset + prevNeedleSize + aOffset.binNeedleGap
				;msgbox % haystackChunkOffset " haystackChunkOffset"
				continue
			}
		}
		
		if (arrayIndex = 1)
		{
			msgbox fsd
			break, 2
		}
		else ;if (arrayIndex != 1)
		{	
			;msgbox arrayIndex = %arrayIndex%
			aOffset := aOffsets[arrayIndex := 1]
			haystackChunkOffset := currentStartOffstet
		}
		
		;haystackChunkOffset += aOffset.end - aOffset.start 
		;haystackChunkOffset++
	}
}

if (foundAddress != -1)
	msgbox % foundAddress " found"
else 
	msgbox not found
return

hexToBinaryBuffer(hexString, byRef buffer)
{
	StringReplace, hexString, hexString, %A_Space%,, All
	StringReplace, hexString, hexString, %A_Tab%,, All	
	if !length := strLen(hexString)
	{
		msgbox nothing was passed to hexToBinaryBuffer
		return 0
	}
	if mod(length, 2)
	{
		msgbox Odd Number of characters passed to hexToBinaryBuffer`nEnsure two digits are used for each byte e.g. 0E 
		return 0
	}
	byteCount := length/ 2
	VarSetCapacity(buffer, byteCount)
	loop, % byteCount
		numput("0x" . substr(hexString, 1 + (A_index - 1) * 2, 2), buffer, A_index - 1, "UChar")
	return byteCount

}

cHex(dec, useClipboard := True)
{
	return useClipboard ? clipboard := substr(dectohex(dec), 3) : substr(dectohex(dec), 3)
}


f1::

VarSetCapacity(binaryNeedle, 1)
VarSetCapacity(haystack, 1)
numput(122, binaryNeedle, 0, "Char")
numput(6, haystack, 0, "Char")

msgbox % scanInBuf(&haystack, &binaryNeedle, 1, 1)
return


;DO NOT WORK WITH AHK 64 BIT, only work with AHK 32 BIT
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

; Creates an object which facilitates storage of binary data.
BinObject()
{
    static BinObjectType
    ; Initialize base object, once only.
    if !BinObjectType
        BinObjectType
        := Object("__get"   , "BinObject_Get"
                , "__set"   , "BinObject_Set"
                , "__delete", "BinObject_Delete")
    ; Construct new object.
    return Object("_data"   , Object()          ; Array of pointers.
                , "_names"  , ","               ; List of field names.
                , "base"    , BinObjectType)
}

BinObject_Get(obj, field, prm1="")
{
    if ptr := obj._data[field]
        ; Return current address of this data field.
        return ptr
    if field = BinSize
        ; Return size of specified data field.
        return BinObject_GetCapacity(obj, prm1)
}

BinObject_Set(obj, field, prm1, value)
{
    if field = BinSize
        ; Update size of specified data field.
        return BinObject_SetCapacity(obj, prm1, value)
}

BinObject_Delete(obj)
{
    ; Remove leading and trailing comma.
    _names := SubStr(obj._names, 2, -1)
    ; Free each data field.
    Loop, Parse, _names, `,
        DllCall("GlobalFree", "uint", obj._data[A_LoopField])
}

BinObject_GetCapacity(obj, field)
{
    if ptr := obj._data[field]
        return DllCall("GlobalSize", "uint", ptr)
}

BinObject_SetCapacity(obj, field, capacity)
{
    _data := obj._data  ; For performance.
    if capacity < 0     ; For possible future use.
        return
    ptr := _data[field]
    if capacity
    {   ; Allocate or reallocate this field, if necessary.
        if ! existing_ptr := ptr
            ptr := DllCall("GlobalAlloc", "uint", 0x40, "uint", capacity)
        else if DllCall("GlobalSize", "uint", ptr) != capacity
            ptr := DllCall("GlobalReAlloc", "uint", ptr, "uint", capacity, "uint", 0x42)
        ; Check for failure before updating object.
        if !ptr
            return
        ; Update pointer in internal array.
        _data[field] := ptr
        if !existing_ptr ; Add new field to the list.
            obj._names := obj._names . field . ","
        return DllCall("GlobalSize", "uint", ptr)
    }
    else if ptr
    {   ; Remove and free this field.
        _names := obj._names
        StringReplace, _names, _names, `,%field%`,, `,
        obj._names := _names
        _data._Remove(field)
        DllCall("GlobalFree", "uint", ptr)
    }
}