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

; Just easy way to install/remove both hooks with one function

; send() uses getState to determine if removing hook is required
setLowLevelInputHooks(Install, getState := 0)
{
	static hKbd := 0, hMse := 0
	
	if getState 
		return hKbd + hMse

	if install 
	{
		hKbd := setMTKeyboardHook(True)
		hMse := setMTMouseHook(True)
		if (hKbd && hMse)
			return 0 
		else return 1 ; error installing
	}
	else
	{
		KbdRemoved := setMTKeyboardHook(False)
		MseRemoved := setMTMouseHook(False)	 ; returns Non-zero on success
		if (KbdRemoved && MseRemoved)
		{
			hKbd := hMse := 0 ; just doing this for testing 
			return 0 	; success 
		}
		else return 1 	; error
	}
}


; only lookup the callback once for each function
setMTKeyboardHook(Install)
{
	static hook, CallBack := RegisterCallback("KeyboardHook")
	if install 
	{
		; Attempt to remove the hook if one is already present, as windows lets you install as many as you want
		if hook
			UnhookWindowsHookEx(hook)
		return hook := SetWindowsHookEx(13, CallBack) ; WH_KEYBOARD_LL := 13
	}
	if hook
		return UnhookWindowsHookEx(hook), hook := 0
	else return -1
}

setMTMouseHook(Install)
{	
	static hook, CallBack := RegisterCallback("MouseHook")
	if install 
	{
		if hook
			UnhookWindowsHookEx(hook)
		return hook := SetWindowsHookEx(14, CallBack) 	; WH_MOUSE_LL := 14 
	}
	if hook
		return UnhookWindowsHookEx(hook), hook := 0
	else return -1
}

MT_InputIdleTime()
{
	return A_mtTimeIdle
}

; Installing these hooks then placing main thread into critical allows
; user input to be delayed until automation finishes (critical ends)
KeyboardHook(nCode, wParam, lParam)
{	
	Critical 1000
   	Return CallNextHookEx(nCode, wParam, lParam) ; make sure other hooks in the chain receive this event if we didn't process it
}

MouseHook(nCode, wParam, lParam)
{
	Critical 1000
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
	keyboardExample(nCode, wParam, lParam)
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