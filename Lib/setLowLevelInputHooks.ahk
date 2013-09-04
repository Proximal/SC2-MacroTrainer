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



setLowLevelInputHooks(Install, KeyboardFunction := "KeyboardHookT", MouseFunction := "MouseHookT")
{
	; WH_KEYBOARD_LL := 13, WH_MOUSE_LL := 14

	static hHooks := [], CallBacks := [] ; only lookup the callback once for each function

	if Install
	{
		if (KeyboardFunction && !CallBacks[KeyboardFunction])
			hHooks.hHookKeybd  := SetWindowsHookEx(13, CallBacks[KeyboardFunction] := RegisterCallback(KeyboardFunction))
		else if KeyboardFunction
			hHooks.hHookKeybd := SetWindowsHookEx(13, CallBacks[KeyboardFunction])

		if (MouseFunction && !CallBacks[MouseFunction])
			hHooks.hHookMouse  := SetWindowsHookEx(14, CallBacks[MouseFunction] := RegisterCallback(MouseFunction))
		else if MouseFunction
			hHooks.hHookMouse := SetWindowsHookEx(14, CallBacks[MouseFunction])
  		return
  	}
  	else
  	{
  		if (KeyboardFunction && hHooks.hHookKeybd) ; Don't attempt to remove it if it was never properly installed
			UnhookWindowsHookEx(hHooks.hHookKeybd), hHooks.hHookKeybd := False
		if (MouseFunction && hHooks.hHookMouse)	
			UnhookWindowsHookEx(hHooks.hHookMouse), hHooks.hHookMouse := False	
	}
  	return	
}

MT_InputIdleTime(NewInputTickCount := 0)
{
	static LastInputTickCount
	if !NewInputTickCount
		return A_TickCount - LastInputTickCount
	LastInputTickCount := NewInputTickCount
	return 
}


; these keyboard hooks are used to track to update MT_InputIdleTime, which is used to track the time 
; since the user's last input (ignoring mousemovement)
; holding down a keyboard button will cause the hook to fire (auto repeat) and reset the idle count
; This does not occur for mouse buttons!

; ** This is highly affected by the 'repeat delay' and 'repeat rate' settings in windows

; ncode < 0 means the message shouldn't be processed and I should Return CallNextHookEx(nCode, wParam, lParam)
; ncode 0 - message contains information
; return a negative value to prevent other programs reading the key

KeyboardHookT(nCode, wParam, lParam)
{	
	Critical 1000
	static WM_KEYUP := 0x101
	Global MT_HookBlock
	If !nCode ; if this var contains some info about a keyboard event, then process it
		MT_InputIdleTime(A_TickCount)

	; Input is blocked and this is a user pressed / released button	
  	if (MT_HookBlock && !(NumGet(lParam+8) & 0x10)) ; LLKHF_INJECTED
  	{	
  		; Track user released keys.
  		; User pressed keys will begin auto-repeating anyway
  		;if (wParam = WM_KEYUP)
   		;	input.insertUserReleasedKey(NumGet(lParam+0, 0)) ;vkCode
  		return -1 
  	}

   	Return CallNextHookEx(nCode, wParam, lParam) ; make sure other hooks in the chain receive this event if we didn't process it
}
MouseHookT(nCode, wParam, lParam)
{
;	static 	WM_LBUTTONUP := 0x202, , WM_RBUTTONUP := 0x205, WM_MBUTTONUP := 0x208
;		  	, WM_XBUTTONUP := 0x020C

	Global MT_HookBlock
	Critical 1000
	If (!nCode && wParam != 0x200)  ;WM_MOUSEMOVE := 0x200
	{
		MT_InputIdleTime(A_TickCount)
		; Input is blocked and this is a user pressed / released button	
		if (MT_HookBlock && !(NumGet(lParam+12) & 0x10))  ; LLKHF_INJECTED
		{
			;removed stuff
			return -1
		}
	}
   	Return CallNextHookEx(nCode, wParam, lParam) ; make sure other hooks in the chain receive this event if we didn't process it
}


KeyboardHook(nCode, wParam, lParam)
{	
	Critical 1000
	If !nCode ; if this var contains some info about a keyboard event, then process it
		MT_InputIdleTime(A_TickCount)
   	Return CallNextHookEx(nCode, wParam, lParam) ; make sure other hooks in the chain receive this event if we didn't process it
}

MouseHook(nCode, wParam, lParam)
{
;	static 	MK_CONTROL := 0x0008, MK_MBUTTON := 0x0010, MK_RBUTTON := 0x0002
;			MK_SHIFT := 0x0004, MK_XBUTTON1 := 0x0020, MK_XBUTTON2 := 0x0040

	Critical 1000
	If (!nCode && wParam != 0x200)  ;WM_MOUSEMOVE := 0x200
		MT_InputIdleTime(A_TickCount)
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