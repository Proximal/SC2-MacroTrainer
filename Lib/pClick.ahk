; wParam Indicates whether various virtual keys are down. This parameter can be one or more of the following values.
; but doesnt seem to affect sc2

; Note WM_MOUSEMOVE May be required in some situations. E.g. when the chat box is up and the cursor is not 
; in the viewport ie over the control cards


pClick(x, y, button := "L", count := 1, Modifiers := "", MouseMove := False)
{
	Global GameIdentifier
	static	  WM_MOUSEFIRST := 0x200
			, WM_MOUSEMOVE = 0x200
			, WM_LBUTTONDOWN = 0x201
			, WM_LBUTTONUP = 0x202
			, WM_LBUTTONDBLCLK = 0x203  	; double click
			, WM_RBUTTONDOWN = 0x204
			, WM_RBUTTONUP = 0x205
			, WM_RBUTTONDBLCLK = 0x206
			, WM_MBUTTONDOWN = 0x207
			, WM_MBUTTONUP = 0x208
			, WM_MBUTTONDBLCLK = 0x209
			, WM_MOUSEWHEEL = 0x20A
			, WM_MOUSEHWHEEL = 0x20E
			, WM_XBUTTONDOWN := 0x020B
			, WM_XBUTTONUP := 0x020C
			, MK_LBUTTON := 0x0001
			, MK_RBUTTON := 0x0002
			, MK_SHIFT := 0x0004
			, MK_CONTROL := 0x0008
			, MK_MBUTTON := 0x0010
			, MK_XBUTTON1 := 0x0020
			, MK_XBUTTON2 := 0x0040


	pKeyDelay :=  Input.pClickDelay()
	lParam := x & 0xFFFF | (y & 0xFFFF) << 16
	WParam := 0 ; Needed for the |= to work

	if instr(Modifiers, "+")
		WParam |= MK_SHIFT
	if instr(Modifiers, "^")
		WParam |= MK_CONTROL
	if instr(Modifiers, "x1")
		WParam |= MK_XBUTTON1
	if instr(Modifiers, "x2")
		WParam |= MK_XBUTTON2
	if MouseMove
		PostMessage, %WM_MOUSEMOVE%, , %lParam%, , %GameIdentifier%

	if button contains r
		message := "WM_RBUTTON", WParam |= MK_RBUTTON
	else if button contains M 
		message := "WM_MBUTTON", WParam |= MK_MBUTTON
	else if button contains x1 
		message := "WM_XBUTTON", WParam |= MK_XBUTTON1
	else if button contains x2 
		message := "WM_XBUTTON", WParam |= MK_XBUTTON2
	else if button contains WheelUp,WU,WheelDown,WD  
	{
		if button contains WheelUp,WU
			direction := 1
		else direction := -1
		WParam |= (direction * count * 120)  << 16
		PostMessage, %WM_MOUSEWHEEL%, %WParam%, %lParam%, , %GameIdentifier%  
		return	
	}
	else message := "WM_LBUTTON", WParam |= MK_LBUTTON

	if button contains up,U
		message .= "UP"
	else if button contains down,D 
	 	message .= "DOWN"
	else 
	{
		mdown := message . "DOWN"
		mup := message . "UP"
		mdown := %mdown%
		mup := %mup%
		loop % count 
		{
			PostMessage, %mdown%, %WParam%, %lParam%, , %GameIdentifier%  
			if (pKeyDelay != -1)
				DllCall("Sleep", Uint, pKeyDelay)
			PostMessage, %mup%, %WParam%, %lParam%, ,  %GameIdentifier% 
		}	
		return	
	}
	message := %message%
	PostMessage, %message%, %WParam% , %lParam%, , %GameIdentifier%
	return
}


