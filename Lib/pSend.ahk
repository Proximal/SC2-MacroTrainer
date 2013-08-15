; WM_CHAR is required to send text to chat boxes and the like within sc2

pSend(Sequence, IncludeWM_CHAR := 0)
{
	Global GameIdentifier
	static WM_KEYDOWN := 0x100, WM_KEYUP := 0x101, WM_CHAR := 0x102

	SetFormat, IntegerFast, hex
	aSend := []
	C_Index := 1
;	StringReplace, Sequence, Sequence, %A_Space% ,, All ;stuffs up {shift down}
	StringReplace, Sequence, Sequence, `t , %A_Space%, All 
	Currentmodifiers := []
	length := strlen(Sequence) 
	while (C_Index <= length)
	{
		char := SubStr(Sequence, C_Index, 1)
		if (char = " ")
		{
			C_Index++
			continue
		}
		if char in +,^,!
		{		
			if (char = "+")
				Modifier := GetKeyVK("Shift")
			else if (char = "^")
				Modifier := GetKeyVK("Ctrl")
			else if (char = "!")
				Modifier := GetKeyVK("Alt")

			Currentmodifiers.insert(Modifier)
			aSend.insert({	  "wm": WM_KEYDOWN
							, "key": Modifier})
			C_Index++
			continue
			
		}
		if (char = "{") 							; send {}} will fail with this test but cant use that
		{ 												; hotkey anyway in program would be ]
			if (Position := instr(Sequence, "}", False, C_Index, 1)) ; lets find the closing bracket) n
			{
				key := trim(substr(Sequence, C_Index+1, Position -  C_Index - 1))
				C_Index := Position ;PositionOfClosingBracket
				while (if instr(key, A_space A_space))
					StringReplace, key, key, %A_space%%A_space%, %A_space%, All
				StringSplit, outputKey, key, %A_Space%
				if (outputKey0 = 2)
				{

					if instr(outputKey2, "Down")
						aSend.insert({	  "wm": WM_KEYDOWN
										, "key": GetKeyVK(outputKey1)})
					else if instr(outputKey2, "Up")
						aSend.insert({	  "wm": WM_KEYUP
										, "key": GetKeyVK(outputKey1)})					
				}
				else 
				{				
					aSend.insert({	  "wm": WM_KEYDOWN
									, "key": GetKeyVK(outputKey1)})
					if IncludeWM_CHAR
						aSend.insert({	  "wm": WM_CHAR
										, "key": GetKeyVK(outputKey1)})				

					aSend.insert({	  "wm": WM_KEYUP
									, "key": GetKeyVK(outputKey1)})
				}
			}
		}
		Else
		{
			aSend.insert({	  "wm": WM_KEYDOWN
							, "key": GetKeyVK(char)})
			if IncludeWM_CHAR
				aSend.insert({	  "wm": WM_CHAR
								, "key": GetKeyVK(char)})		

			aSend.insert({	  "wm": WM_KEYUP
							, "key": GetKeyVK(char)})
		}
	
		if Modifier
		{
			for index, modifier in Currentmodifiers
				aSend.insert({	  "wm": WM_KEYUP
								, "key": Modifier})
			Modifier := False
		}


		C_Index++
	}
	SetFormat, IntegerFast, d

	for index, message in aSend
	{
		postmessage, % message.wm, % message.key,,, % GameIdentifier
	}

	return aSend
}
