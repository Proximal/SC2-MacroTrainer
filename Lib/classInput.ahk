
; As Im not accounting for mouse buttons (just want to see how well this works)
; make sure to check Mousebuttons are not down before calling releaseKeys()
; Same with Windows keys (as releasing these will cause the windows menu to appear) - although the automation
; may still work

; Note** Do not call releaseKeys() while thread is in critical! As the LL-Hooks wont process the input
; until the thread comes out of critical, or an AHK sleep command is used
; Also note, any AHK command which has an internal sleep (including eg controlsend) will cause AHK to check its msg queue
; and the hooks will then process any user pressed key which could interrupt the automation!

class Input 
{
;	static keys := ["LControl", "RControl", "LAlt", "RAlt", "LShift", "RShift", "LWin", "RWin"
	static keys := ["Control", "Alt", "Shift", "LWin", "RWin"  ; use neurtral modifiers as postmessage cant release left/right
				, "AppsKey", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
				, "Left", "Right", "Up", "Down", "Home", "End", "PgUp", "PgDn", "Del", "Ins", "BS", "Capslock", "Numlock", "PrintScreen" 
				, "Pause", "Space", "Enter", "Tab", "Esc", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "B", "C", "D", "E", "F", "G"
				, "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
	 	,	MouseButtons := ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
		,	downSequence
		,	MouseBlocked := False
		,	KybdBlocked := False
		, 	pCurrentClickDelay := -1
		, 	pCurrentSendDelay := -1
		, 	dragLeftClick := False

	; Very Important Note about logical and physical hotkey states
	; if the hotkey has no modifiers, then physical state will be down
	; and the logical will be up (as expected)
	; But if the hotkey has modifiers
	; then both the hotkey key and its modifiers will be physically AND logically down!! 

	releaseKeys(checkMouse := False)
	{
		this.downSequence := this.dragLeftClick := ""
		SetFormat, IntegerFast, hex
		for index, key in this.keys 
			if GetKeyState(key) 	; check the logical state (as AHK will block the physical)
				upsequence .= "{VK" GetKeyVK(key) " Up}", this.downSequence .= "{" key " Down}" 
		SetFormat, IntegerFast, d
		if checkMouse
		{
			for index, key in this.MouseButtons 
			{
				if GetKeyState(key) 	; check the logical state
				{
					upsequence .= "{click " key " Up}"
					if instr(key, "l") ; for left button drag click
						this.dragLeftClick := True, getLastLeftClickPos(x, y), this.downSequence .= "{click " x " " y " " key " Down}" 	
					else this.downSequence .= "{click " key " Down}"
				}
			}
		}
		
		if upsequence
		{
			SendInput, {BLIND}%upsequence%
			return upsequence 	; This will indicate that we should sleep for 15ms (after activating critical)
		}	 					; to prevent out of order command sequence with sendinput vs. post message
		return 
	}

	; If not blocking input, i.e. just buffering/placing thread in critical then can release 
	; pressed keys using postmessage without fear of getting stuck keys outside of sc 

	pReleaseKeys(checkMouse := False)
	{
		this.downSequence := this.dragLeftClick := ""
		for index, key in this.keys 
			if GetKeyState(key) 	; check the logical state (as AHK will block the physical)
				upsequence .= "{" key " Up}", this.downSequence .= "{" key " Down}" 
		if checkMouse
		{
			for index, key in this.MouseButtons 
			{
				if GetKeyState(key) 	; check the logical state
				{
					upsequence .= "{click " key " Up}"
					if instr(key, "l") ; for left button drag click
						this.dragLeftClick := True, getLastLeftClickPos(x, y), this.downSequence .= "{click " x " " y " " key " Down}" 	
					else this.downSequence .= "{click " key " Down}"
					
				}
					
			}
		}
		if upsequence
		{
			this.pSend(upsequence)
			return upsequence 	; This will indicate that we should sleep for 15ms (after activating critical)
		}	 					; to prevent out of order command sequence with sendinput vs. post message
		return 
	}

	revertKeyState()
	{
		if this.downSequence
		{
			this.pSend(this.downSequence)
			if this.dragLeftClick
			{
				; this is so the green box drag will appear in SC.
				; otherwise the box drag wont appear until the user moves the mouse 
				MouseGetPos, x, y
				dllcall("SetCursorPos", "int", x, "int", y)
			}	
		}
		return							
	}
	userInputModified()
	{
		return this.downSequence
	}

	pClickDelay(newDelay := "")
	{
		if newDelay is number
			this.pCurrentClickDelay := newDelay
		return this.pCurrentClickDelay
	}

	pSendDelay(newDelay := "")
	{
		if newDelay is number 
			this.pCurrentSendDelay := newDelay
		return this.pCurrentSendDelay
	}	
	hookBlock(kybd := False, mouse := False)
	{
		this.KybdBlocked := kybd
		this.MouseBlocked := mouse
		return
	}
	iskeyboardBlocked()
	{
		return this.KybdBlocked
	}
	isMouseBlocked()
	{
		return this.KybdBlocked 
	}

	; This command can be used with the same syntax as AHKs sendInput command
	; pSend("^+ap") 		Result:	Control+Shift+a, p
	; pSend("+{click}")		Result: Shift Left click the mouse (down and up event)
	; pSend("{click D " x1 " " y1 "}{Click U " x2 " " y2 "}") ; Result: Box drag the mouse with the LButton

	pSend(Sequence := "")
	{
		Global 	GameIdentifier
		static 	WM_KEYDOWN := 0x100
				, WM_KEYUP := 0x101

		pKeyDelay := this.pCurrentSendDelay
		pClickDelay := this.pCurrentClickDelay

		SetFormat, IntegerFast, hex
		aSend := []
		C_Index := 1
	;	StringReplace, Sequence, Sequence, %A_Space% ,, All ;stuffs up {shift down}
		StringReplace, Sequence, Sequence, `t , %A_Space%, All 
		Currentmodifiers := []
		length := strlen(Sequence) 
		while (C_Index <= length)
		{
			char := SubStr(Sequence, C_Index, 1)
			if (char = " ")
			{
				C_Index++
				continue
			}
			if char in +,^,!
			{		
				if (char = "+")
					Modifier := "Shift"
				else if (char = "^")
					Modifier := "Ctrl"
				else if (char = "!")
					Modifier :="Alt"

				CurrentmodifierString .= char
				Currentmodifiers.insert( {"wParam": GetKeyVK(Modifier) 
								, "sc": GetKeySC(Modifier)})			

				aSend.insert({	  "message": WM_KEYDOWN
								, "sc": GetKeySC(Modifier)
								, "wParam": GetKeyVK(Modifier)})
				C_Index++
				continue
				
			}
			if (char = "{") 							; send {}} will fail with this test but cant use that
			{ 												; hotkey anyway in program would be ]
				if (Position := instr(Sequence, "}", False, C_Index, 1)) ; lets find the closing bracket) n
				{
					key := trim(substr(Sequence, C_Index+1, Position -  C_Index - 1))
					C_Index := Position ;PositionOfClosingBracket
					while (if instr(key, A_space A_space))
						StringReplace, key, key, %A_space%%A_space%, %A_space%, All
								
					if instr(key, "click")
					{
						StringReplace, key, key, click ; remove the word click
					   	StringSplit, clickOutput, key, %A_space%, %A_Space%%A_Tab%`,
					    numbers := []
					    SetFormat, IntegerFast, d ; otherwise A_Index is 0x and doesnt work with var%A_Index%
					    loop, % clickOutput0
					    {
					    
					    	command := clickOutput%A_index% 
					        if command is number
					            numbers.insert(command)    
					    }
					   
					    if (!numbers.maxindex() || numbers.maxindex() = 1)
					    {
					        MouseGetPos, x, y  ; will cause problems if send hex number to insertpClickObject
					        clickCount := numbers.maxindex() = 1 ? numbers.1 : 1
					    }
					    else if (numbers.maxindex() = 2 || numbers.maxindex() = 3)
					        x := numbers.1, y := numbers.2, clickCount := numbers.maxindex() = 3 ? numbers.3 : 1
					    else 
					    {
					    	SetFormat, IntegerFast, hex
					    	continue ; error
					    }	 
					    SetFormat, IntegerFast, hex
				;	  	 msgbox % key "`n" x ", " y "`n" clickCount
					    this.insertpClickObject(aSend, x, y, key, clickCount, CurrentmodifierString, instr(key, "MM")) ; MM - Insert MouseMove
					}
					else 
					{
						StringSplit, outputKey, key, %A_Space%
						if (outputKey0 = 2)
						{

							if instr(outputKey2, "Down")
								aSend.insert({	  "message": WM_KEYDOWN
												, "sc": GetKeySC(outputKey1)
												, "wParam": GetKeyVK(outputKey1)})
							else if instr(outputKey2, "Up")
								aSend.insert({	  "message": WM_KEYUP
												, "sc": GetKeySC(outputKey1)
												, "wParam": GetKeyVK(outputKey1)})					
						}
						else 
						{				
							aSend.insert({	  "message": WM_KEYDOWN
											, "sc": GetKeySC(outputKey1)
											, "wParam": GetKeyVK(outputKey1)})

							aSend.insert({	  "message": WM_KEYUP
											, "sc": GetKeySC(outputKey1)
											, "wParam": GetKeyVK(outputKey1)})
						}
					}
				}
			}
			Else
			{
				aSend.insert({	  "message": WM_KEYDOWN
								, "sc": GetKeySC(char)
								, "wParam": GetKeyVK(char)})


				aSend.insert({	  "message": WM_KEYUP
								, "sc": GetKeySC(char)
								, "wParam": GetKeyVK(char)})
			}
		
			if Modifier
			{
				for index, modifier in Currentmodifiers
					aSend.insert({	  "message": WM_KEYUP
									, "sc": modifier.sc
									, "wParam": modifier.wParam})
				Modifier := False
				CurrentmodifierString := "", Currentmodifiers := []
			}
			C_Index++
		}
		SetFormat, IntegerFast, d


		for index, message in aSend
		{
			
			if (WM_KEYDOWN = message.message)
			{
				 ; repeat code | (scan code << 16)
				lparam := 1 | (message.sc << 16)
				postmessage, message.message, message.wParam, lparam,, % GameIdentifier

			}
			else if (WM_KEYUP = message.message)
			{
				lparam := 1 | (message.sc << 16) | (1 << 31) ; transition state
				postmessage, message.message, message.wParam, lparam,, % GameIdentifier
			}
			else 
			{
				; If mouse move is included it actually strangles moves the mouse!!
				postmessage, message.message, message.wParam, message.lparam,, % GameIdentifier
				if (pClickDelay != -1)
					DllCall("Sleep", Uint, pClickDelay)
				continue
			}
			if (pKeyDelay != -1)
				DllCall("Sleep", Uint, pKeyDelay)
		}
		return aSend
	}

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


		pKeyDelay :=  this.pCurrentClickDelay
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
		; remove the word button eg Lbutton as the U will cause an UP-event to be sent
		StringReplace, button, button, button, %A_Space%, All
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

	insertpClickObject(ByRef sendObject, x, y, button := "L", count := 1, Modifiers := "", MouseMove := False)
	{
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
			sendObject.insert({ "message": WM_MOUSEMOVE
							, "lParam": lParam})

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
			
			sendObject.insert({ "message": WM_MOUSEWHEEL
							, "wParam": WParam |= (direction * count * 120)  << 16
							, "lParam": lParam})
			return	
		}
		else message := "WM_LBUTTON", WParam |= MK_LBUTTON
		; remove the word button eg Lbutton as the U will cause an UP-event to be sent
		StringReplace, button, button, button, %A_Space%, All
		
		if button contains up,U
			message .= "UP"
		else if button contains down,D 
		 	message .= "DOWN"
		else 
		{
			mdown := message . "DOWN"
			mup := message . "UP"
			loop % count 
			{
				sendObject.insert({ "message": %mdown%
								, "wParam": WParam
								, "lParam": lParam})

				sendObject.insert({ "message": %mup%
					, "wParam": WParam
					, "lParam": lParam})
			}	
			return
		}

		sendObject.insert({ "message": %message%
							, "wParam": WParam
							, "lParam": lParam})
		return
	}
}
