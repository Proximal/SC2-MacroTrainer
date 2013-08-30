; options to be used to specify Up/Down 
; U or D
MTclick(x,y, button := "Left" , Modifiers := "", options := "", count := "", Blind := True)
{
	GLOBAL GameIdentifier
;	setLowLevelInputHooks(False)
	if Blind
		Blind := "{Blind}"
	else Blind := ""

	if instr(modifiers, "+")
		ModifersDown .= "{VK10 Down}", ModifersUp .= "{VK10 Up}"
	if instr(modifiers, "^")
		ModifersDown .= "{VK11 Down}", ModifersUp .= "{VK11 Up}"
	if instr(modifiers, "!")
		ModifersDown .= "{VK12 Down}", ModifersUp .= "{VK12 Up}"
	if ModifersDown
		controlsend,, % Blind ModifersDown, %GameIdentifier%			
	ControlClick, x%x% y%y%, %GameIdentifier%,, %button%, %count%, %options%
	if ModifersUp
		controlsend,, % Blind ModifersUp, %GameIdentifier%	

;	setLowLevelInputHooks(True)

	return
}
