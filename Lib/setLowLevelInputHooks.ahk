/*
	nCode [in]
	Type: int
	A code the hook procedure uses to determine how to process the message. If nCode is less than zero, the hook procedure must pass the message to the CallNextHookEx function without further processing and should return the value returned by CallNextHookEx. This parameter can be one of the following values.
	Value	Meaning
	HC_ACTION
	0
	The wParam and lParam parameters contain information about a keyboard message.
	 
	wParam [in]
	Type: WPARAM
	The identifier of the keyboard message. This parameter can be one of the following messages: WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, or WM_SYSKEYUP.
	lParam [in]
	Type: LPARAM
	A pointer to a KBDLLHOOKSTRUCT structure.
*/



setLowLevelInputHooks(Install, KeyboardFunction := "KeyboardHook", MouseFunction := "MouseHook")
{
	static hHooks := []
	if (Install && !hHooks.maxindex())
	{
		hHooks.insert( hHookKeybd := SetWindowsHookEx(WH_KEYBOARD_LL := 13, RegisterCallback(KeyboardFunction, "Fast")) )
  		hHooks.insert( hHookMouse := SetWindowsHookEx(WH_MOUSE_LL  	 := 14, RegisterCallback(MouseFunction, "Fast")) )
  		return hHooks
  	}
  	else if (!install && hHooks.maxindex())
  	{
  		for index, handle in hHooks
			UnhookWindowsHookEx(handle)	
		hHooks := []
	}
  	return	
}

MT_TimeIdleInput(NewInputTickCount := 0)
{
	static LastInputTickCount
	if !NewInputTickCount
		return A_TickCount - LastInputTickCount
	LastInputTickCount := NewInputTickCount
	return 
}


; these keyboard hooks are used to track to update MT_TimeIdleInput, which is used to track the time 
; since the user's last input (ignoring mousemovement)
; holding down a keyboard button will cause the hook to fire (auto repeat) and reset the idle count
; This does not occur for mouse buttons!

; ** This is highly affected by the 'repeat delay' and 'repeat rate' settings in windows

KeyboardHook(nCode, wParam, lParam)
{	
	Critical
	If (nCode >= 0) ; if this var contains some info about a keyboard event, then process it
		MT_TimeIdleInput(A_TickCount)
   	Return CallNextHookEx(nCode, wParam, lParam) ; make sure other hooks in the chain receive this event if we didn't process it
}

MouseHook(nCode, wParam, lParam)
{
;	static 	MK_CONTROL := 0x0008, MK_MBUTTON := 0x0010, MK_RBUTTON := 0x0002
;			MK_SHIFT := 0x0004, MK_XBUTTON1 := 0x0020, MK_XBUTTON2 := 0x0040

	; !nCode ; so if this var contains some info about a keyboard event, then process it
	; wParam is only 512 when the mouse is moved, i.e. wparam is different if a button is pressed
	Critical
	If (nCode >= 0 && wParam != 512)
		MT_TimeIdleInput(A_TickCount)
   	Return CallNextHookEx(nCode, wParam, lParam) ; make sure other hooks in the chain receive this event if we didn't process it
}

SetWindowsHookEx(idHook, pfn)
{
   Return DllCall("SetWindowsHookEx", "int", idHook, "Uint", pfn, "Uint", DllCall("GetModuleHandle", "Uint", 0), "Uint", 0)
}

UnhookWindowsHookEx(hHook)
{
   Return DllCall("UnhookWindowsHookEx", "Uint", hHook)
}

CallNextHookEx(nCode, wParam, lParam, hHook = 0)
{
   Return DllCall("CallNextHookEx", "Uint", hHook, "int", nCode, "Uint", wParam, "Uint", lParam)
}

/*
	KeyboardOridingal(nCode, wParam, lParam)
	{
	   Critical
	   If !nCode ; if this var contains some info about a keyboard event, then process it
	   {
	      vkCode := NumGet(lParam+0, 0)
	      scanCode := NumGet(lParam+0, 4)

	      If ( scanCode = 59 ) ; 59 = 0x3b = F1 key scan code
	      {
	         If ( wParam = 257 ) ; 257 = 0x0101 = WM_KEYUP message
	            SetTimer, DoStuff, 50 ; allow func to return then trigger what we want

	         Return -1 ; indicate that we processed this message amd dont want anything else in the hook chain to recieve it
	      }
	   }

	   Return CallNextHookEx(nCode, wParam, lParam) ; make sure other hooks in the chain receive this event if we didn't process it
	}

	DoStuff:
	   SetTimer, DoStuff, Off ; important otherwise the below code will keep repeating.
	   ; ....
	   MsgBox, Hi from AHK Script - do some stuff here
	   ; ...
	Return
*/