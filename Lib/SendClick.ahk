; Button can be left/right +/- Up down
; or blank 
; all commas are optional with click
SendClick(button := "", x := "", y := "", count := "", Modifiers :="", Blind := True)
{
;	if Modifiers
;	{
	;	ModifierState := readModifierState()
	;	, Shift := (1 & ModifierState)
	;	, Ctrl := (2 & ModifierState)
	;	, Alt := (4 & ModifierState)

;	}
;should really convert modifiers into key down ups

;	if (Blind || BufferInputFast.isInputBlockedOrBuffered())
;	{
;		if instr(Modifiers, "+")
;			pre .= "{VK0x10 Down}", post .= "{VK0x10 Up}"
;		if instr(Modifiers, "^")
;			pre .= "{VK0x11 Down}", post .= "{VK0x11 Up}"
;		if instr(Modifiers, "!")
;			pre .= "{VK0x12 Down}", post .= "{VK0x12 Up}"
;		send, {Blind}%pre%{click %button% %x% %y% %count%}%post%

;	}
;	else send, %Modifiers%{click %button% %x% %y% %count%}
	 send, %Modifiers%{click %button% %x% %y% %count%}
}
