; Can pass an array of offsets by using *
; eg, pointer(game, base, [0x10, 0x30, 0xFF]*)
; or a := [0x10, 0x30, 0xFF]
; pointer(game, base, a*)
; or just type them in manually

pointer(game, base, offsets*)
{ 
	For index, offset in offsets
	{
		if (index = offsets.maxIndex() && A_index = 1)
			pointer := offset + ReadMemory(base, game)
		Else 
		{
			IF (A_Index = 1) 
				pointer := ReadMemory(offset + ReadMemory(base, game), game)
			Else If (index := offsets.MaxIndex() = A_Index)
				pointer += offset
			Else pointer := ReadMemory(pointer + offset, game)
		}
	}	
	Return ReadMemory(pointer, game)
}
