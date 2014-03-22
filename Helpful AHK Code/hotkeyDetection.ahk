#Persistent
#SingleInstance force
SetBatchLines, -1
OnExit, exit
settimer, exit, 40000 
global aKeys := []
; http://www.autohotkey.com/board/topic/70111-retrieve-key-names-from-onmessage-wm-keydown/page-2
; I removed the line, DllCall("HideCaret", "ptr", 0) because it did not completely remove the "|" sign from the edit box.

; hiding carret is accumulative so might need to check



	gui, hotBox:new
	Gui, hotBox:add, edit, vtest  w90
	Gui, hotBox:add, edit, section vhotBoxEdit1   w200 
	Gui, hotBox:add, CheckBox, x+10 yp vhotBoxCheck1 

	Gui, hotBox:add, edit, xs vhotBoxEdit2   w200 
	Gui, hotBox:add, HotKey, xs   w200 

	;Gui, Add, Picture, w300 xp w200 h20,
	
	gui, hotBox:show, h100, HotBox
	OnMessage(0x201, "enableHooks")
	;OnMessage(0x201, "WM_LBUTTONDOWN")
	OnMessage(0x207, "clearHotkey")
	Gui, hotBox:+LastFound  
	;WinGet hotboxHWND, ID
	;WinWaitClose, ahk_id %hotboxHWND%
	GuiControlGet, focusedId, FocusV 
	if instr(focusedId, "hotBoxEdit")
		DllCall("HideCaret", "ptr", 0)
	;DllCall("ShowCaret", "ptr", 0)
	OnMessage(0x100, "keydown")
	aHotBoxSettings := []
	aHotBoxSettings := {	"hotBoxEdit1": "Neutral shortSyntax"
						,	"hotBoxEdit2": ""}
	return 

keydown(wParam, lParam, msg, hwd)
{
	if instr(A_GuiControl, "hotBoxEdit")
		return 0
}


_hotBoxUpdateEdit:
DllCall("ShowCaret", "ptr", 0)
modifiers := nonModifiers := keys := modifiersShort := nonModifiersShort := "", keyCount := 0
modifiersList := "Control,Shift,Alt,Win"
			. ",LControl,LShift,LAlt,LWin"
			. ",RControl,RShift,RAlt,RWin"
/*
if instr(aHotBoxSettings[hotBoxID], "shortSyntax")	
	delimiter := ""	
else 
	delimiter := " + "	
*/

loop, parse, modifiersList, `,
{
	if aKeys.HasKey(A_LoopField)
	{
		keyCount++
		modifiers .= (modifiers ? " + " : "") A_LoopField
		modifiersShort .= " " A_LoopField ;(modifiersShort ? "  " : " ")
	}
}

for key, v in aKeys 
{
	if key in %modifiersList%
		continue
	keyCount++
	nonModifiers .= ( modifiers ? " + " : "") key 
	nonModifiersShort .= key 
}

clipboard := s " sdf"



keys := modifiers nonModifiers
shortKeys := modifiersShort nonModifiersShort
if (keyCount > 1)
{
	tooltip, % keys
}
GuiControl, hotBox:, %hotBoxID%, %shortKeys%
if nonModifiers
{
	installLLHooks(False)
	hotBoxID := ""
	aKeys := []
	settimer, tooltipOff, -1000
	DllCall("HideCaret", "ptr", 0)
}
soundPlay()
return


convertLongModifers(string)
{
	StringReplace, string, string, LControl, <^
	StringReplace, string, string, RControl, >^
	StringReplace, string, string, Control, ^
	StringReplace, string, string, LShift, <+
	StringReplace, string, string, RShift, >+
	StringReplace, string, string, Shift, +
	StringReplace, string, string, LAlt, <!
	StringReplace, string, string, RAlt, >!
	StringReplace, string, string, Alt, !
	return string
}

shortModifiersToNeutral(string)
{
	StringReplace, string, string, <,, ALL
	StringReplace, string, string, >,, ALL	
	return string 
}

tooltipOff:
tooltip 
return

exit: 
UnhookWindowsHookEx(hHook)
UnhookWindowsHookEx(mHook)
exitapp 

*f1::
exitapp 
return 



/*
If alt is pressed then released
WM_SYSKEYDOWN
WM_KEYUP
hhh
*/
soundPlay()
{	
	soundplay *-1
}


; Detects Prtsc & Pause
; Can't do PrintScr too low level
KeyboardHook(nCode, wParam, lParam)
{
	global aHotBoxSettings, hotBoxID
	static aExtendedRemap := {	"NumpadIns": "Ins"
							,	"NumpadHome": "Home"
							,	"NumpadPgUp": "PgUp"
							,	"NumpadDel": "Delete"
							,	"NumpadEnd": "End"
							,	"NumpadPgDn": "PgDn"
							,	"NumpadLeft": "Left"
							,	"NumpadUp": "Up"
							,	"NumpadDown": "Down"
							,	"NumpadRight": "Right" }

	;		aNeutralRemap := { "LControl": "Control"
	;						, 	"LShift":	"Shift"
	;						,	"LAlt": 	"Alt"
	;						,	"LWin": 	"LWin"}

	static WM_KEYDOWN := 0x100, WM_KEYUP := 0x101, WM_SYSKEYDOWN := 0x0104, WM_SYSKEYUP := 0x0105
	Critical, 250 
	;soundplay *-1
	If !nCode 
	{
		SetFormat, IntegerFast, hex
		vkCode := NumGet(lParam+0, 0)
		key := getKeyName("VK" vkCode)
		;scanCode := NumGet(lParam+0, 4)
		flags := NumGet(lParam+0, 8)
		extended := flags & 1
		if (extended && aExtendedRemap.HasKey(key))
			key := aExtendedRemap[key]
		; Replace left and right modifiers with their neutral equivalent 
		StringReplace, ID, hotBoxID, Edit, Check
		GuiControlGet, Neutral, hotBox:, %ID%
		if (Neutral && (instr(key, "Control") || instr(key, "Shift") || instr(key, "Alt") || instr(key, "Win")))
			key := substr(key, 2)
		if (wParam = WM_KEYDOWN)
			log .= "`nVK " vkCode
				. "`nSC " scanCode
				. "`nvkKey " key
				. "`nSCKey " getKeyName("SC" scanCode)
				. "`nextended " extended
				. "`n================"
		;clipboard .= key "`n"
		if (wParam = WM_KEYDOWN || wParam = WM_SYSKEYDOWN)
		{
			; prevent the context menu appearing with shift + F10
			; prevent win hotkeys doing stuff - cant prevent win + L
			if (key = "F10" && (aKeys.HasKey("Shift") || aKeys.HasKey("LShift") || aKeys.HasKey("RShift"))) 
			|| instr(key, "Win")
				blockKey := True
			if !aKeys.hasKey(key)
				settimer, _hotBoxUpdateEdit, -10
			aKeys[key] := True
		}
		else if (wParam = WM_KEYUP || wParam = WM_SYSKEYUP)
		{
			aKeys.Remove(key)
			settimer, _hotBoxUpdateEdit, -10
		}

	}
   Return  blockKey ? -1 : CallNextHookEx(nCode, wParam, lParam) ; pass the key event onto other programs in the hook chain
}

; mouse has different WM_Messages for each down/up event on each button
/*
WM_MOUSEMOVE = 0x200,
WM_LBUTTONDOWN = 0x201,
WM_LBUTTONUP = 0x202,
WM_LBUTTONDBLCLK = 0x203,
WM_RBUTTONDOWN = 0x204,
WM_RBUTTONUP = 0x205,
WM_RBUTTONDBLCLK = 0x206,
WM_MBUTTONDOWN = 0x207,
WM_MBUTTONUP = 0x208,
WM_MBUTTONDBLCLK = 0x209,
WM_MOUSEWHEEL = 0x20A,
WM_XBUTTONDOWN = 0x20B,
WM_XBUTTONUP = 0x20C,
WM_XBUTTONDBLCLK = 0x20D,
WM_MOUSEHWHEEL = 0x20E
*/

; can call with param -1 to simply find hook state
installLLHooks(Install := False)
{
	static mHook, hHook, keyboardCallback := RegisterCallback("KeyboardHook")
		mouseCallback := RegisterCallback("MouseHook")
	if (Install > 0)
	{
		if !hHook
			hHook := SetWindowsHookEx(13, keyboardCallback)
		if !mHook
			mHook := SetWindowsHookEx(14, mouseCallback)	
	}
	else if (install = 0)
	{
		if hHook
			UnhookWindowsHookEx(hHook), hHook := 0 
		if mHook
			UnhookWindowsHookEx(mHook), mHook := 0
	}
	return hHook
}
enableHooks(wParam, lParam, msg, hwd)
{	
	global hotBoxID, aKeys
	if instr(A_GuiControl, "hotBoxEdit") && !hooksInstalled := installLLHooks(-1)
	{
		
		if (hooksInstalled && A_GuiControl = hotBoxID)   
			return 
		else if (hooksInstalled && A_GuiControl != hotBoxID) ; hooks already installed so user in another editbox
		{
			GuiControl, hotBox:, %hotBoxID%
			aKeys := []
		}
		if !hooksInstalled
		{
			installLLHooks(True)
			DllCall("ShowCaret", "ptr", 0)
		}
		hotBoxID := A_GuiControl
	}
	return 
}
clearHotkey(wParam, lParam)
{	global hotBoxEdit
	if instr(A_GuiControl, "hotBoxEdit") && !installLLHooks(-1)
		GuiControl, hotBox:, %A_GuiControl%, 
	return 
}

MouseHook(nCode, wParam, lParam)
{ 	
	static aMessages := {	"WM_LBUTTONDOWN":	0x201
						,	"WM_RBUTTONDOWN":	0x204
						,	"WM_MBUTTONDOWN":	0x207
						,	"WM_MOUSEWHEEL":	0x20A
						,	"WM_XBUTTONDOWN":	0x20B
						,	"WM_MOUSEHWHEEL":	0x20E }
	global aKeys					
	Critical 1000

	If !nCode 
	{
		If (wParam = aMessages.WM_LBUTTONDOWN)
		{
			
				blockKey := True ; settimer, _HotkeyBoxEditLabel123456, -5

				aKeys["LButton"] := True
		}
		else if (wParam = aMessages.WM_RBUTTONDOWN)
		{
			aKeys["RButton"] := True
			;ControlGetFocus, varID, % "AHK_PID " DllCall("GetCurrentProcessId")
			;if (varID = "hotBoxEdit")
			blockKey := True
			;clipboard := varID
		}
		else if (wParam = aMessages.WM_MBUTTONDOWN)
			aKeys["MButton"] := True
		else 
		{
			mouseData := NumGet(lParam+0, 8, "Int")
			if (wParam = aMessages.WM_XBUTTONDOWN)
				aKeys[((mouseData >> 16) & 1  ? "XButton1" : "XButton2")] := True
			else if (wParam = aMessages.WM_MOUSEWHEEL || wParam = aMessages.WM_MOUSEHWHEEL)
			{
				; This gets the actual +/- rotations which will always be +1/-1 in this case
				; These are stored in the hiword of the dword mouseData
				if (mouseData > 0x7FFFFFFF)
					 rotations := (-(~(mouseData >> 16)) - 1) / 120
				else 
					rotations := (mouseData >> 16) / 120

				if (wParam = aMessages.WM_MOUSEHWHEEL)
					aKeys[(rotations > 0 ? "WheelRight" : "WheelLeft")] := True
				else 
					aKeys[(rotations > 0 ? "WheelUp" : "WheelDown")] := True
			}
			else ; some other message lets not activate the settimer 
				Return CallNextHookEx(nCode, wParam, lParam)
		}
		settimer, _hotBoxUpdateEdit, -10
	}
   	Return blockKey ? -1 : CallNextHookEx(nCode, wParam, lParam) ; make sure other hooks in the chain receive this event if we didn't process it
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