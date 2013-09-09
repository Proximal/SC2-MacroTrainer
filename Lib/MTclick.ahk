MTclick(x,y, button := "Left" , Modifiers := "", count := 1, MouseMove := False)
{

	if instr(modifiers, "+")
		ModifersDown .= "{Shift Down}", ModifersUp .= "{Shift Up}"
	if instr(modifiers, "^")
		ModifersDown .= "{Ctrl Down}", ModifersUp .= "{Ctrl Up}"
	if instr(modifiers, "!")
		ModifersDown .= "{Alt Down}", ModifersUp .= "{Alt Up}"
	if ModifersDown
		pSend(ModifersDown)	
	pClick(x, y, button, count, Modifiers, MouseMove)		
	if ModifersUp
		pSend(ModifersUp)		
	return
}