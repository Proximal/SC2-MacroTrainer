MTclick(x,y, button := "Left" , Modifiers := "", count := 1, MouseMove := False)
{

	if instr(modifiers, "+")
		ModifersDown .= "{Shift Down}", ModifersUp .= "{Shift Up}"
	if instr(modifiers, "^")
		ModifersDown .= "{Ctrl Down}", ModifersUp .= "{Ctrl Up}"
	if instr(modifiers, "!")
		ModifersDown .= "{Alt Down}", ModifersUp .= "{Alt Up}"
	if ModifersDown
		Input.pSend(ModifersDown)	
	Input.pClick(x, y, button, count, Modifiers, MouseMove)		
	if ModifersUp
		Input.pSend(ModifersUp)		
	return
}