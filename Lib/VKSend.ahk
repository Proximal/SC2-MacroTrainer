VKSend(Sequence)
{
	SetFormat, IntegerFast, hex
	C_Index := 1
	StringReplace, Sequence, Sequence, %A_Space% ,, All
	l := strlen(Sequence) 
	while (C_Index <= l)
	{
		char := SubStr(Sequence, C_Index, 1)
		if (char = "+")
		{
			string .= "{ VK" GetKeyVK("Shift") " down}"
			ReleaseModifiers .= "{ VK" GetKeyVK("Shift") " up}"
		}
		else if (char = "^")
		{
			string .= "{ VK" GetKeyVK("Ctrl") " down}"
			ReleaseModifiers .= "{ VK" GetKeyVK("Ctrl") " up}"
		}
		else if (char = "!")
		{
			string .= "{ VK" GetKeyVK("Alt") " down}"
			ReleaseModifiers .= "{ VK" GetKeyVK("Alt") " up}"

		}
		if (char = "{")
		{
			if (Position := instr(Sequence, "}", False, C_Index, 1)) ; lets find the closing bracket)
			{
				key := trim(substr(Sequence, C_Index+1, Position -  C_Index - 1))
				C_Index := Position ;PositionOfClosingBracket
				string .= "{ VK" GetKeyVK(key) "}" 
			}
		}
		Else
			string .= "{ VK" GetKeyVK(char) "}" 
	C_Index++
	}
	SetFormat, IntegerFast, d
	return	string .= ReleaseModifiers
}