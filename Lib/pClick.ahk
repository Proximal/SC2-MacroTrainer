; wParam Indicates whether various virtual keys are down. This parameter can be one or more of the following values.
; but doesnt seem to affect sc2

pClick(button, x, y)
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

	If button contains l
		message := "WM_LBUTTON" 
	else if button contains r
		message := "WM_RBUTTON"
	else if button contains M 
		message := "WM_MBUTTON"

	lParam := x & 0xFFFF | (y & 0xFFFF) << 16
	if button contains up
		message .= "UP"
	else if button contains down 
	 	message .= "DOWN"
	else 
	{
		mdown := message . "DOWN"
		mup := message . "UP"
		mdown := %mdown%
		mup := %mup%
		PostMessage, %mdown%, , %lParam%, , %GameIdentifier%  
		PostMessage, %mup%, , %lParam%, ,  %GameIdentifier% 	
		return	
	}
	message := %message%
	PostMessage, %message%, , %lParam%, , %GameIdentifier%
}