/*
 Notes pertaining to Macro Trainer:
 As Im not accounting for mouse buttons (just want to see how well this works)
 make sure to check Mousebuttons are not down before calling releaseKeys()
 Same with Windows keys when using releaseKeys (sendInput) (as this will cause the windows menu to appear) - although the automation
 may still work

 Note** Do not call releaseKeys() (this uses sendInput) while thread is in critical! As the LL-Hooks wont process the input
 until the thread comes out of critical, or an AHK sleep command is used.
 pReleaseKeys uses post message and is fine to use while in critical
 Also note, any AHK command which has an internal sleep (including eg controlsend) will cause AHK to check its msg queue
 and the hooks will then process any user pressed key which could interrupt the automation!
 
 ControlSend is also very slow when looping lots of messages (it seems to wait for response (sendMessage?) or delays to prevent flooding)
 Also it's slightly slower than pSend() when sending a small number of keys
*/

; 30/05. I've noticed something with sendInput.
; Send {blind}A or {blind}{A up}
; This will always send a shift even with setcapsLock state off

; **** Ensure 'coordmode, mouse, window' is in effect before calling any method which clicks at the current cursor location
; otherwise if the game is in true window mode the clicks will be off if the window is not positioned at 0,0
; **** also ensure XframeOffset and YframeOffset are appropriately set if the application is in true window mode
; to do this call systemWindowEdgeSize(Wframe, Hframe, Hcaption) 
; XframeOffset := Wframe
; YframeOffset := Hcaption + Hframe
; These things are required, as clicks are relative to the client area which does not include the
; size of the window frame/border


class Input 
{
;	static keys := ["LControl", "RControl", "LAlt", "RAlt", "LShift", "RShift", "LWin", "RWin"
	static keys := ["Control", "Alt", "Shift", "LWin", "RWin"  ; use neurtral modifiers as postmessage cant release left/right
				, "AppsKey", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
				, "Left", "Right", "Up", "Down", "Home", "End", "PgUp", "PgDn", "Del", "Ins", "BS", "Capslock", "Numlock", "PrintScreen" 
				, "Pause", "Space", "Enter", "Tab", "Esc", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
				, "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m" ; Have to use lower case to prevent sendInput sending extra shifts
				, "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
				, "``", "-", "=", "[", "]", "\", ";", "'", ",", ".", "/" 		; note the "`" has to be escaped 
				, "NumpadDiv", "NumpadMult", "NumpadAdd", "NumpadSub"]
				; NumpadDiv keystate != / keystate etc
				; But keystate "NumpadEnter" = keystate "enter"
				; Should investigate adding numpad keys when numlock is off (but i don't think its required)
				; have to think about numlock off numpad left = left button etc (but obviously scan codes will differ)
	 			; but it shouldnt matter which one is released or pressed back down,  like lctrl vs neutral ctrl
	 			; never the less, i should test it one day.
	 			; Regardless of this, still don't want to send the button down twice 

	 	, numLockKeys := ["Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4"
	 					, "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9"]
						
	 	, modifiers := ["Control", "Alt", "Shift", "LWin", "RWin"]
	 	, aMouseClickButtons := {  "LButton": "L" 	; converts Lbutton or xbutton2 etc into L, x2
								, "RButton": "R"
								, "MButton": "M"
								, "XButton1": "X1"
								, "XButton2": "X2" }
	 	,	MouseButtons := ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
		,	downSequence
		,	MouseBlocked := False
		,	KybdBlocked := False
		, 	pCurrentClickDelay := -1
		, 	pClickPressDuration := -1
		, 	pCurrentSendDelay := -1
		,	pSendPressDuration := -1
		, 	pCurrentCharDelay := -1
		, 	threadSleep := True
		, 	dragLeftClick := False
		, 	LastLeftClickX, LastLeftClickY
		;,	lastKeyboardTick, lastMouseTick
		, 	Control, WinTitle, WinText,	ExcludeTitle, ExcludeText

	; To restore box drags correctly requires a pass through hotkey on lbutton 
	; So we can determine the x, y location of the start of the box drag (where the left button
	; was first pressed down)
	; i.e.
	; *~LButton::
	;	input.setLastLeftClickPos()
	;	return
	setLastLeftClickPos()
	{
		MouseGetPos, x, y
		input.LastLeftClickX := x
		input.LastLeftClickY := y
		return
	}

	getReleaseSequence(checkMouse := True, sendInput := False)
	{
		this.downSequence := this.dragLeftClick := ""
		for index, key in this.keys 
		{
			if GetKeyState(key) 	; check the logical state (as AHK will block the physical)
			{
				; This masks the windows keyup - if its seen as coming up by itself it will make the win bar appear
				; i.e. just as if you pressed it by itself. (This is how AHK does it)
				; This isn't needed when releasing via postmessage.
				if (sendInput) && (key = "LWin" || key = "RWin")
					upsequence .= "{LControl Down}{LControl Up}"
				upsequence .= "{" key " Up}", this.downSequence .= "{" key " Down}"
			} 

		}
		if GetKeyState("NumLock", "T")
		{
			for index, key in this.numLockKeys
			{
				if GetKeyState(key) ; keystate of numpad0 != keystate of 0 key
					upsequence .= "{" key " Up}", this.downSequence .= "{" key " Down}" 
			}
		}

		if checkMouse
		{
			for index, key in this.MouseButtons 
			{
				if GetKeyState(key) 	; check the logical state
				{
					key := this.aMouseClickButtons[key]
					upsequence .= "{click " key " Up}"
					if instr(key, "l") ; for left button drag click
						this.dragLeftClick := True, this.downSequence .= "{click " input.LastLeftClickX " " input.LastLeftClickY " " key " Down}" 	
					else this.downSequence .= "{click " key " Down}"
				}	
			}
		}					
		; This will indicate that we should sleep for at least 15ms (after activating critical)
		; to prevent out of order command sequence with sendinput vs. post message
		return upsequence
	}

	
	; releaseKeys() uses SendInput to release any logically down
	; keys. If checkMouse is true, then the mouse keys will be 
	; checked and released as appropriate.

	; releaseKeys() should only be used when your hook is blocking
	; physical non-injected input. And when this is done, revertKeyState()
	; should not be called when your automation has finished, as there is no
	; guarantee that the keys are still down leading to stuck keys. 


	; Note: Logical vs physical hotkey key states
	; if the hotkey has no modifiers, then physical state will be down
	; and the logical will be up (as expected). But if the hotkey has modifiers then 
	; the prefix modifiers will be down 

	releaseKeys(checkMouse := True)
	{
		if (upsequence := this.getReleaseSequence(checkMouse, True))
		{
			SendInput, {BLIND}%upsequence%
			return upsequence 	; This will indicate that we should sleep for 15ms (after activating critical)
		}	 					; to prevent out of order command sequence with sendinput vs. post message
		return 
	}
	; pReleaseKeys() is the same as releaseKeys(), except it uses post message to release the keys.
	; The main advantage of this is that if you place the AHK thread into critical (and you have your own
	; hooks installed) you can perform your automation including sleeps (dllCall sleeps not ahk sleeps)
	; and then restore the key states without fear of stuck keys.

	; If not blocking input, i.e. just buffering/placing thread in critical then can release 
	; pressed keys using postmessage without fear of getting stuck keys outside of sc 
	; Technically I guess you should have a 10ms buffer after starting critical before calling this
	; but i haven't noticed the need. Actually this probably isn't true as hooks work on a 
	; first in last out system.

	pReleaseKeys(checkMouse := True)
	{
		if (upsequence := this.getReleaseSequence(checkMouse, False))
		{
			this.pSend(upsequence)
			return upsequence 	
		}	 					
		return 
	}
	; This ignoreKey was just for testing stuff
	revertKeyState(ignoreKey := "")
	{
		if this.downSequence
		{
			if (ignoreKey != "")
			{
				s := this.downSequence
				StringReplace, s, s, {%ignoreKey% Down}
				this.downSequence := s
			}
			this.pSend(this.downSequence)
			if this.dragLeftClick
			{
				; SetCursorPos is so the green box drag will appear in SC.
				; otherwise the box drag wont appear until the user moves the mouse
				CoordMode, Mouse, Screen ; coordinates are relative to the screen
				MouseGetPos, x, y
				dllcall("SetCursorPos", "int", x, "int", y)
			}	
		}
		return							
	}

	; the new command is handy if you wish to send input to multiple programs
	; inputSC2 := new input(, "Starcraft II")
	; inputSC2.pSendChars("Hello World!")
	__new(Control := "", winTitle := "", winText := "", excludeTitle := "", excludeText := "")
	{
		this.Control := control 
		this.WinTitle := winTitle 
		this.WinText := winText
		this.ExcludeTitle := excludeTitle 
		this.ExcludeText := excludeText
		return this
	}

	; The same as:
	; 			input.KybdBlocked := 1/0, input.MouseBlocked := 1/0
	hookBlock(kybd := False, mouse := False)
	{
		input.KybdBlocked := kybd
		input.MouseBlocked := mouse
		return
	}

	sleep(ms)
	{
		if this.threadSleep 
			DllCall("Sleep", "Uint", ms)	
		Else
			sleep ms
		return	
	}


	; This command is designed to send exact key presses to interact with a game/program, and not to produce text. 
	; For examples, pSend("+7") or pSend("+&")  would send {shift down}{7}{shift up} (7 is the actual key for the '&' character). 
	; If sent to a text field you would only see '7', as generally message/text translation depends 
	; on the state the OS believes the modifiers are in. Since the messages are posted directly to the game,
	; the OS doesn't know the shift key was actually pressed. pSendChar() provides a means to post text to a text field.
	; If the game has an action bound shift+7, then it will respond to it.

	; The syntax is very similar to AHK's send command.
	; Examples:
	; 	pSend("^+ap") 				
	; 	Result:	Control+Shift+a then p
	; 	pSend("{a down}") 			
	;	Result: The 'a' key is pressed down but not released
	; 	pSend("{b 8}")  				
	;	Result: The 'b' key is sent eight times
	; 	pSend("{vk0x41}") or pSend("{vk41}")
	; 	Result: Sends the virtual key 0x41 - the 'a' key (the hex 0x prefix is optional) 
	;			The scan code can also be combined with this or used alone e.g. {vkFFsc159} or {sc159}
	; 	psend("{ctrl down}{alt down}abc{ctrl up}{alt up}")
	;	Result: The a, b, and c keys are sent while the ctrl and alt keys are down.
	; 	Note:	Programs may not respond correctly to left/right modifier keys i.e. {left shift} or {right ctrl down}
	;			so it's best to send the neutral modifiers i.e. {shift down}. The ^+! modifiers will
	; 			send the neutral modifier key. # Will send the left win key, as there is no neutral win key.			

	; To send mouse buttons using pSend, you must use the {click} syntax; sending "{lbutton}" will not work.
	; Click command:
	; 	Syntax:		{Click button x y ClickCount MM}
	; 	Buttons: 	L/Left, R/Right, M/Middle, WU/WheelUp, WD/WheelDown, X1/Xbutton1 and X2/XButton2 are optional. 
	;				If omitted the left button will be sent.
	;	X Y:  		Coordinates are optional. If omitted the current physical cursor coordinates are used.
	;	ClickCount: Optional, but if present it must come after the coordinates (if they are present). 
	;				If omitted, the button is clicked once (consists of a down and an up event)
	;   MM:			If the letters MM are present a WM_MouseMove message is included after the click
	
	; Examples:
	; 	pSend("+{click}")	
	;	Result: Shift Left click the mouse at its current location (down + up event)
	; 	pSend("{click R 400 500 3}")	
	;	Result: The mouse is right clicked three times at coordinates 400 by 500
	; 	pSend("{click D 100 50}{Click U 600 800}") 	
	; 	Result: Box drag the mouse with using the left button from coordinatesx 100, 50 to 600, 800
	; 	Note:	To send a correctly modified box drag you must specify the modifier for the both the down and up event (this is the same as AHKs {click})
	; 			pSend("+{click R D 100 50}+{Click R U 600 800}") ; a fully shift modified box drag using the right mouse button.
	; 	pSend("+{click MM}")			
	;	Result: Shift Left click the mouse at its current location then send a WM_MouseMove message.


	; Tabs, spaces and new lines can also be sent. That is, their escaped character representations will also work.
	; pSend("`n`thello") Would start a tabbed new line with the word 'hello'.
	
	; Notes:
	; Blind mode is enabled by default, that is the keys are sent without modifying the current logical up/down state 
	; of the modifiers. This is because for my purposes I use pReleasekeys() to release any down keys (includes modifiers), send the keys, then 
	; restore their previous state with revertKeyState().
	; If blind mode is disabled, then pSend will release logically down modifiers, send the key sequence,
	; and then restore the modifiers to their correct positions. This is how AHK's send command works. 

	; The AHK keyboard hook needs to be installed to allow discrimination between logically and physically pressed keys.
	; **Be aware** that if you release the keys using pRelease/postmessage, then use pSend with blind disabled, the modifiers will be up within the game but AHK will still see
	; them as logically/physically down, so they will be released again, the key sequence will be sent, and then the modifiers will be
	; PRESSED DOWN again. Since they're pressed down again, if pSend is called again with blind enabled, then the sent keys will be modified by the down modifiers (e.g. shift/control down).
	; This shouldn't be an issue providing you consistently use pSend with blind disabled in any subsequent calls to pSend

	; This is designed to send exact key presses to interact with a game/program, and not to produce text. 
	; For example psend("AB CD") would send "ab cd" - non capitalised. 
	; Depending on the program, pSend("{shift down}ab cd{shift up}") or psend("+a+b +c+d") may capitalise the text, but this usually
	; isn't the case.
	; For most purposes, it is better to use pSendChars() to send lengths of text to text/input fields.
	; For example pSendChars("I ♥ NY!") will appear as "I ♥ NY!"


/*
Bits	Meaning
0-15	The repeat count for the current message. The value is the number of times the keystroke is autorepeated as a result of the user holding down the key. The repeat count is always 1 for a WM_KEYUP message.
16-23	The scan code. The value depends on the OEM.
24		Indicates whether the key is an extended key, such as the right-hand ALT and CTRL keys that appear on an enhanced 101- or 102-key keyboard. The value is 1 if it is an extended key; otherwise, it is 0.
25-28	Reserved; do not use.
29		The context code. The value is always 0 for a WM_KEYUP message.
30		The previous key state. The value is always 1 for a WM_KEYUP message.
31		The transition state. The value is always 1 for a WM_KEYUP message.
		
I should look into testing if setting the repeat count actually does anything
*/

	pSend(Sequence := "", blind := True)
	{
		static 	WM_KEYDOWN := 0x100, WM_KEYUP := 0x101
			  , WM_SYSKEYDOWN := 0x104, WM_SYSKEYUP := 0x105

		caseMode := A_StringCaseSense
		StringCaseSense, Off 

		if !blind
		{
			for index, key in this.modifiers
			{
				if GetKeyState(key) 	; check the logical state (as AHK will block the physical for some)
					Sequence := "{" key " Up}" Sequence "{" key " Down}" 
			}			
		}
		aSend := []
		C_Index := 1
		Currentmodifiers := []
		length := strlen(Sequence) 
		while (C_Index <= length)
		{
			char := SubStr(Sequence, C_Index, 1)
			if char in +,^,!,#
			{		
				if (char = "+")
					Modifier := "Shift"
				else if (char = "^")
					Modifier := "Ctrl"
				else if (char = "#")
					Modifier := "LWin"	; no common win key				
				else 
					Modifier := "Alt"

				CurrentmodifierString .= char
				Currentmodifiers.insert( {"wParam": GetKeyVK(Modifier) ; used to release modifiers
								, "sc": GetKeySC(Modifier)
								, "message": char = "!" ? WM_SYSKEYUP : WM_KEYUP})			

				aSend.insert({	  "message": char = "!" ? WM_SYSKEYDOWN : WM_KEYDOWN
								, "sc": GetKeySC(Modifier)
								, "wParam": GetKeyVK(Modifier)})
				C_Index++
				continue
				
			}
			if (char = "{") 								; send {}} will fail with this test. It could be fixed with another if statement
			{ 												; but cant use that key anyway, as a ] is really shift+] 
				if (Position := instr(Sequence, "}", False, C_Index, 1)) ; lets find the closing bracket) n
				{
					key := trim(substr(Sequence, C_Index+1, Position -  C_Index - 1))
					C_Index := Position ;PositionOfClosingBracket				
					
					key := RegExReplace(key, "\s{2,}|\t", " ") ; ensures tabs replaced with a space - and there is only one space between params
					if instr(key, "click")
					{
						StringReplace, key, key, click ; remove the word click
					   	StringSplit, clickOutput, key, %A_space%, %A_Space%%A_Tab%`,
					    numbers := []
					    loop, % clickOutput0
					    {
					    	command := clickOutput%A_index% 
					        if command is number
					            numbers.insert(command)    
					    }
					   
					    if (!numbers.maxindex() || numbers.maxindex() = 1)
					    {
					        MouseGetPos, x, y  ; will cause problems if send hex number to insertpClickObject the regex below fixes this
					        clickCount := numbers.maxindex() ? numbers.1 : 1
					    }
					    else if (numbers.maxindex() = 2 || numbers.maxindex() = 3)
					        x := numbers.1, y := numbers.2, clickCount := numbers.maxindex() = 3 ? numbers.3 : 1
					    else continue ; error
					    ; replace MM, as this could cause a middle click	 
					    if (mousemove := instr(key, "MM"))
					    	StringReplace, key, key, MM,, All				    
					    
					    ; at this point key variable will look like this  D 1920 1080, U 1920 1080, U L 1920 1080 
					    ; I don't need to refine the actual button any more, as the else-if in the function
					    ; will still correctly identify the button
					    ; e.g.  Middle 1920 1080 will still click the middle button, even though there is a d in middle
					    ; This regex will remove any numbers/hex which are not part of a text word i.e. xbutton1 is fine
					    ; Otherwise if coordinates were in hex, and it contained the number D, it could be seen as a down event

					    key := RegExReplace(key, "i)(?:\b\d+\b)|(:?0x[a-f0-9]+)", "")
					    this.pClick(x, y, key, clickCount, CurrentmodifierString, mousemove, aSend) 
						skip := True ; as already inserted a mouse click event
					}
						; This RegExMatch takes ~0.02ms (after its first cached)
					else if RegExMatch(key, "iS)(?<key>[^\s]+)\s*(?<event>\b(?:up|u|down|d)\b)?\s*(?<count>(?:-?0x[a-f0-9]+\b)|-?\d+\b)?", send)
					&& getkeyVK(sendKey) ; if key is valid
					{
						instr(sendKey, "alt") 
						? (downMessage := WM_SYSKEYDOWN, upMessage := WM_SYSKEYUP)
						: (downMessage := WM_KEYDOWN, upMessage := WM_KEYUP)

						if instr(sendEvent, "d") || instr(sendEvent, "u")
						{
							message := instr(sendEvent, "d") ? downMessage : upMessage
							loop, % sendCount != "" ? sendCount : 1
							{						
								aSend.insert({	  "message": message		 
												, "sc": GetKeySC(sendKey)
												, "wParam": GetKeyVK(sendKey)})
							}									
						}
						else ; its a complete press down + up
						{
							loop, % sendCount != "" ? sendCount*2 : 2
							{
								aSend.insert({	  "message": mod(A_index, 2) ? downMessage : upMessage
												, "sc": GetKeySC(sendKey)
												, "wParam": GetKeyVK(sendKey)})
							}
						}
						skip := True ; skip sending char, as key was sent here instead
					}
					else skip := True ; use of { without a valid click or key syntax
				}
				else skip := True ; something went wrong 
			}

			if skip
				skip := False
			else ; its a char without a specified click count or down/up event
			{
				loop, 2
					aSend.insert({	  "message": A_Index = 1 ? WM_KEYDOWN : WM_KEYUP
									, "sc": GetKeySC(char)
									, "wParam": GetKeyVK(char)})
			}

			if Modifier
			{
				for index, modifier in Currentmodifiers
					aSend.insert({	  "message": modifier.message
									, "sc": modifier.sc
									, "wParam": modifier.wParam})
				Modifier := False
				CurrentmodifierString := "", Currentmodifiers := []
			}
			C_Index++
		}
		
		for index, message in aSend
		{
			if (WM_KEYDOWN = message.message || WM_SYSKEYDOWN = message.message)
			{
				 ; repeat code | (scan code << 16)
				lparam := 1 | (message.sc << 16)
				postmessage, message.message, message.wParam, lparam, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
				if (this.pSendPressDuration != -1)
					this.sleep(this.pSendPressDuration)
			
			}
			else if (WM_KEYUP = message.message || WM_SYSKEYUP = message.message)
			{
				 ; repeat code | (scan code << 16) | (previous state << 30) | (transition state << 31)
				lparam := 1 | (message.sc << 16) | (1 << 30) | (1 << 31)
				postmessage, message.message, message.wParam, lparam, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
				if (this.pCurrentSendDelay != -1)
					this.sleep(this.pCurrentSendDelay)		
			}
			else ; mouse event
			{
				; If mouse move is included it actually moves the mouse for an instant!
				postmessage, message.message, message.wParam, message.lparam, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
				if (message.HasKey("delay") && message.delay != -1)
					this.sleep(message.delay)
			}
		}
		StringCaseSense, %caseMode%
		return aSend
	}
	; For use in chat boxes and text fields. 
	; can send ascii art and capitalised letters i.e. just text  eg GLF♥HF! 
	; Some characters depend on the logical state of modifiers keys (due to key/message translation)
	; for example if the shift key is logically down sending a "." wont do anything in notepad
	pSendChars(Sequence := "")
	{
		static WM_CHAR := 0x102
		
		loop, % strlen(Sequence) 
		{
			char := SubStr(Sequence, A_Index, 1)
			postmessage, WM_CHAR, Asc(char),, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
			if (this.pCurrentCharDelay != -1)
				this.sleep(this.pCurrentCharDelay)	
		}	
		return	
	}

	; pClickDrag: 
	;	This will perform a box drag/select, i.e., mouse button down at x1, y1 and mouse button up at x2, y2.
	
	; Modifiers parameter:
	; 	The modifiers here can be used to literally modify the drag box e.g. shift drag
	; 	They can consist of one or more of the following characters.
	;	control = ^, shift = +, alt = !, win = #
	
	; Refer to the pClick description for a list of acceptable buttons.

	pClickDrag(x1, y1, x2, y2, button := "L", modifiers := "", MouseMove := False)
	{
	    this.pSend(modifiers "{click D " button (MouseMove ? " MM " : " ") x1 " " y1 "}" modifiers "{Click U " button (MouseMove ? " MM " : " ") x2 " "  y2 "}")
	    return
	}

	; pClick(x, y, button := "L", count := 1, keyStates := "", MouseMove := False, ByRef sendObject := "")
	; ====================================================================================================

	; x, y parameters:
	;	If one or both of these are omitted then the current cursor position is used.

	; Button parameter:
	;	Which button to press. This can be l or left, r or right, m or middle, x1, x2 (not xbutton1/xbutton2),
	;	WheelUp or WU, or WheelDown or WD. If no button is specified, the left button is used. 
	; 	If the word down or letter d is specified after the button then only a down event is sent.
	;	If the word up or letter u is specified then only an up event is sent

	; Count parameter:
	;	If it is a normal click, then the button is clicked x many times (each click consists of a down and up event)
	;	If a down or up event is specified (in the button parameter), then this type of event is sent x number of times (though
	;	it will likely only have the same effect as sending it once)
	
	; KeyStates parameter:
	; 	The click will likely be correctly interpreted without setting this value (so try it without).
	; 	This ensures the wParam part of the message reflects the states of certain virtual keys. 
	;	You shouldn't specify the button being clicked in this string, it is done automatically.
	; 	This value isn't required in SC, and AHK's control click doesn't bother with it either.
	; 	This parameter can be a string consisting of one or more of the following characters. 
	; 	+ = shift, ^ = control, x1 = xbutton1, x2 = xbutton2, m = mbutton, l = left button, and r = right button
 	
 	; MouseMove parameter:
	; 	A WM_MOUSEMOVE message may be required in some situations to have the event correctly register. 
	;	E.g. In SC when the chat box is up and the cursor is not in the viewport (e.g over the control cards).
	; 	If doing a click or box drag near the screen edge (in SC2) - if you send a mouseMove event, the screen will move slightly

	; SendObject parameter:
	;	You should leave this parameter blank. It is only used internally, when pClick is called via pSend
	;	in response to a click command.

	; Note: 
	;	To send a modified click (shift, control, etc) using this method, you still need to 
	; 	use pSend (prior to this) to press the modifiers down, and then use pSend afterwards to release the modifiers


	

	pClick(x := "", y := "", button := "L", count := 1, keyStates := "", MouseMove := False, ByRef sendObject := "")
	{
		static	  WM_MOUSEFIRST := 0x200
				, WM_MOUSEMOVE := 0x200
				, WM_LBUTTONDOWN := 0x201
				, WM_LBUTTONUP := 0x202
				, WM_LBUTTONDBLCLK := 0x203  	; double click
				, WM_RBUTTONDOWN := 0x204
				, WM_RBUTTONUP := 0x205
				, WM_RBUTTONDBLCLK := 0x206
				, WM_MBUTTONDOWN := 0x207
				, WM_MBUTTONUP := 0x208
				, WM_MBUTTONDBLCLK := 0x209
				, WM_MOUSEWHEEL := 0x20A
				, WM_MOUSEHWHEEL := 0x20E
				, WM_XBUTTONDOWN := 0x020B
				, WM_XBUTTONUP := 0x020C
				, MK_LBUTTON := 0x0001
				, MK_RBUTTON := 0x0002
				, MK_SHIFT := 0x0004
				, MK_CONTROL := 0x0008
				, MK_MBUTTON := 0x0010
				, MK_XBUTTON1 := 0x0020
				, MK_XBUTTON2 := 0x0040
				, XBUTTON1 := 0x0001
				, XBUTTON2 := 0x0002
		
		caseMode := A_StringCaseSense
		StringCaseSense, Off 
		if (x = "" || y = "")
			MouseGetPos, x, y

		lParam := x & 0xFFFF | (y & 0xFFFF) << 16
		WParam := 0 ; Needed for the |= to work

		; keyStates are used to ensure the WParam sent contains the correct value
		; which reflects these key states. This should reflect the logical keystate
		; that is the current state the game sees the specified keys as.
		; Since I can't check the logical Keystate of these keys (as they have been
		; manipulated using postmessage (and i cant be fucked writing a function to track them)
		; you will need to specify them manually). Luckily SC and likely other programs
		; interpret the click correctly regardless of this WParam/keyStates value
		; Also AHK doesn't bother sending them either, at least for buttons
		; which aren't the button being clicked i.e. a control X1 click
		; will have the WParam set to MK_XBUTTON1, but if the shift key is also down
		; the WParam message wont contain MK_SHIFT

		if instr(keyStates, "+")
			WParam |= MK_SHIFT
		if instr(keyStates, "^")
			WParam |= MK_CONTROL
		if instr(keyStates, "x1")
			WParam |= MK_XBUTTON1
		if instr(keyStates, "x2")
			WParam |= MK_XBUTTON2
		if instr(keyStates, "r")
			WParam |= MK_RBUTTON
		if instr(keyStates, "m")
			WParam |= MK_MBUTTON
		if instr(keyStates, "l")
			WParam |= MK_LBUTTON
		; WParamUp should not contain button which was actually clicked
		; (The exception to this is the higher order word for xbutons which contains either 0x0001 or 0x0002 on down AND up
		;  clearing the lower order MK_XBUTTON1/MK_XBUTTON2 on up event still applies)
		; WParamUp will be used to clear the clicked bits, and then is sent with the up event
		WParamUp := WParam  

		; In game when physically performing actions, WM_MouseMove occurs after the key release and is not sent for wheelmove 

		if button contains r
			message := "WM_RBUTTON", WParam |= MK_RBUTTON, WParamUp &= ~MK_RBUTTON
		else if button contains M 
			message := "WM_MBUTTON", WParam |= MK_MBUTTON, WParamUp &= ~MK_MBUTTON
		else if button contains x1,XButton1 
			message := "WM_XBUTTON", WParam |= MK_XBUTTON1 | (XBUTTON1 << 16), WParamUp := (WParam & ~MK_XBUTTON1) | (XBUTTON1 << 16)	; WParamUp not &= as have to set the higher order word
		else if button contains x2,XButton2 																							; unlike the other mouse buttons
			message := "WM_XBUTTON", WParam |= MK_XBUTTON2 | (XBUTTON2 << 16), WParamUp := (WParam & ~MK_XBUTTON2) | (XBUTTON2 << 16)
		else if button contains WheelUp,WU,WheelDown,WD  
		{
			; A physical WM_MOUSEWHEEL does not invoke a WM_MouseMove
			if button contains WheelUp,WU
				direction := 1
			else direction := -1
			WParam |= (direction * count * 120) << 16
			if isObject(sendObject)
				sendObject.insert({ "message": WM_MOUSEWHEEL, "wParam": WParam, "lParam": lParam, "delay": this.pCurrentClickDelay})			
			else
			{
				PostMessage, %WM_MOUSEWHEEL%, %WParam%, %lParam%, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
				if (this.pCurrentClickDelay != -1)
					this.sleep(this.pCurrentClickDelay)						
			}	
			StringCaseSense, %caseMode%		
			return	
		}
		else message := "WM_LBUTTON", WParam |= MK_LBUTTON, WParamUp &= ~MK_LBUTTON
		; remove the word button eg Lbutton as the U will cause an UP-event to be sent (in case user entered xbutton1 instead of x1)
		; or middle instead of m (middle contains the letter d)
		StringReplace, button, button, button, %A_Space%, All
		StringReplace, button, button, middle, %A_Space%, All
		if button contains U 
			message .= "UP", wParamSingleEvent := WParamUp, delay := this.pCurrentClickDelay
		else if button contains D 
		 	message .= "DOWN", wParamSingleEvent := WParam, delay := this.pClickPressDuration
		else 
		{
			mdown := message . "DOWN", mup := message . "UP", mdown := %mdown%,	mup := %mup%
			loop % count 
			{
				if isObject(sendObject)
				{
					sendObject.insert({ "message": mdown, "wParam": WParam, "lParam": lParam, "delay": this.pClickPressDuration})
					sendObject.insert({ "message": mup, "wParam": WParamUp, "lParam": lParam, "delay": this.pCurrentClickDelay})					
					if MouseMove
						sendObject.insert({ "message": WM_MOUSEMOVE, "wParam": WParamUp, "lParam": lParam})
				}
				else 
				{
					PostMessage, %mdown%, %WParam%, %lParam%, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
					if (this.pSendPressDuration != -1)
						this.sleep(this.pSendPressDuration)					
					PostMessage, %mup%, %WParamUp%, %lParam%, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
					if MouseMove
						PostMessage, %WM_MOUSEMOVE%, %WParamUp%, %lParam%, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
					if (this.pCurrentClickDelay != -1)
						this.sleep(this.pCurrentClickDelay)	
				}
			}	
			StringCaseSense, %caseMode%
			return	
		}
		; so its a down or up message
		message := %message%
		loop % count ; There probably isn't much point to sending multiple down msgs without an accompanied up, but I will allow it anyway
		{
			if isObject(sendObject)
			{
				sendObject.insert({ "message": message, "wParam": wParamSingleEvent, "lParam": lParam, "delay": delay})
				if MouseMove
					sendObject.insert({ "message": WM_MOUSEMOVE, "wParam": wParamSingleEvent, "lParam": lParam})
			}
			else 
			{
				PostMessage, %message%, %wParamSingleEvent% , %lParam%, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
				if MouseMove
						PostMessage, %WM_MOUSEMOVE%, %wParamSingleEvent%, %lParam%, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
				if (delay != -1)
					this.sleep(delay)
			}
		}
		StringCaseSense, %caseMode%
		return
	}

}



/*
some regex examples which I might update code with 

if instr{click xxxx}
{
    ; get event type
    if !"i)\b(?P<Event>up|down|u|d)"
        Event := 0 ; indicated a complete click down+up
    else event = objectEventRemap
    ; get button
    if "i)\b(?P<Key>left|right|L|R|x1|x2|M|Middle)"
        button := objectKeyRemap
    else button := left 
    ; get coords and count
    if RegExMatch("click 23, , left, , 25, , 12", "?", out)
    {
        if (out.count() = 2 || out.count() = 3)
            x := out.value(1), y := out.value(2)
        if (out.count() = 3)
            count := out.value(3)
        ; have to consider counr and up/down or single event
        else if (out.count() = 1)
        {
            count := out.value(1)
            MouseGetPos, x, y
        }
    }
    else "click down+up" ; no numbers were found

    if !event ; down+up
    {
        "click object down"
        "click object up"
    }
    else 
    {
        "loop count"
            "click eventType"
    }
}

*/

/*
AHK key codes
A2  01D	 	LControl       	     	     	
A3  11D	 	RControl 

SC will not respond to left or right modifiers, but it does respond to the neutral modifier key
Here are the message logs. These logs are identical to those produced by controlSend

input.pSend("{Lctrl down}1{lctrl up}")
; Result: The 1 key is recognised, but it isn't ctrl modified
<00001> 00811852 P WM_KEYDOWN nVirtKey:VK_LCONTROL cRepeat:1 ScanCode:1D fExtended:0 fAltDown:0 fRepeat:0 fUp:0
<00002> 00811852 P WM_KEYDOWN nVirtKey:'1' cRepeat:1 ScanCode:02 fExtended:0 fAltDown:0 fRepeat:0 fUp:0
<00003> 00811852 P WM_KEYUP nVirtKey:'1' cRepeat:1 ScanCode:02 fExtended:0 fAltDown:0 fRepeat:1 fUp:1
<00004> 00811852 P WM_KEYUP nVirtKey:VK_LCONTROL cRepeat:1 ScanCode:1D fExtended:0 fAltDown:0 fRepeat:1 fUp:1
<00005> 00811852 P WM_CHAR chCharCode:'0031' (49) cRepeat:1 ScanCode:02 fExtended:0 fAltDown:0 fRepeat:0 fUp:0

input.pSend("{Rctrl down}1{Rctrl up}")
; Result: The 1 key is recognised, but it isn't ctrl modified
<00001> 00811852 P WM_KEYDOWN nVirtKey:VK_RCONTROL cRepeat:1 ScanCode:1D fExtended:1 fAltDown:0 fRepeat:0 fUp:0
<00002> 00811852 P WM_KEYDOWN nVirtKey:'1' cRepeat:1 ScanCode:02 fExtended:0 fAltDown:0 fRepeat:0 fUp:0
<00003> 00811852 P WM_KEYUP nVirtKey:'1' cRepeat:1 ScanCode:02 fExtended:0 fAltDown:0 fRepeat:1 fUp:1
<00004> 00811852 P WM_KEYUP nVirtKey:VK_RCONTROL cRepeat:1 ScanCode:1D fExtended:1 fAltDown:0 fRepeat:1 fUp:1
<00005> 00811852 P WM_CHAR chCharCode:'0031' (49) cRepeat:1 ScanCode:02 fExtended:0 fAltDown:0 fRepeat:0 fUp:0


; works as expected.
input.pSend("{ctrl down}1{ctrl up}")
<00001> 00811852 P WM_KEYDOWN nVirtKey:VK_CONTROL cRepeat:1 ScanCode:1D fExtended:0 fAltDown:0 fRepeat:0 fUp:0
<00002> 00811852 P WM_KEYDOWN nVirtKey:'1' cRepeat:1 ScanCode:02 fExtended:0 fAltDown:0 fRepeat:0 fUp:0
<00003> 00811852 P WM_KEYUP nVirtKey:'1' cRepeat:1 ScanCode:02 fExtended:0 fAltDown:0 fRepeat:1 fUp:1
<00004> 00811852 P WM_KEYUP nVirtKey:VK_CONTROL cRepeat:1 ScanCode:1D fExtended:0 fAltDown:0 fRepeat:1 fUp:1
<00005> 00811852 P WM_CHAR chCharCode:'0031' (49) cRepeat:1 ScanCode:02 fExtended:0 fAltDown:0 fRepeat:0 fUp:0

*/