#Persistent
#SingleInstance force
SetBatchLines, -1
OnExit, exit
settimer, exit, 40000 
global aKeys := []


Gui, add, edit, vEditkey gTest w200
Gui, add, edit,  w90
Gui, Add, Hotkey, vChosenHotkey
gui, show, w220 h100
;settimer, updateEdit, 1000
return 

f1::
if !hHook
	hHook := SetWindowsHookEx(13, RegisterCallback("KeyboardHook"))
return 

updateEdit:
nonModifiers := keys := ""
modifiers := "Control,Shift,Alt,Win"
			. ",LControl,LShift,LAlt,LWin"
			. ",RControl,RShift,RAlt,RWin"
loop, parse, modifiers, `,
{
	if aKeys.HasKey(A_LoopField)
		keys .= ( keys ? " + " : "") A_LoopField
}
for key, v in aKeys 
{
	if key in %modifiers%
		continue
	keys .= ( keys ? " + " : "") key 
	nonModifiers := True

}
;clipboard := keys
if nonModifiers && 0
{
	UnhookWindowsHookEx(hHook), hHook := 0, aKeys := []
	soundPlay()
}
;msgbox % keys
GuiControl,,Editkey, %keys%
return

exit: 
UnhookWindowsHookEx(hHook)
UnhookWindowsHookEx(mHook)
exitapp 

f2::
if !hHook
	hHook := SetWindowsHookEx(13, RegisterCallback("KeyboardHook"))
if !mHook
	mHook := SetWindowsHookEx(14, RegisterCallback("MouseHook"))
;send {delete}{NumpadDel}
clipboard := log
log := ""
objtree(aKeys)
;UnhookWindowsHookEx(hHook)
;UnhookWindowsHookEx(mHook)
return 
test:

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

/*
; delete key
VK 0x2e
SC 0x53
vkKey NumpadDel
SCKey NumpadDel
extended 0x1
================
Numpad Del
VK 0x2e
SC 0x53
vkKey NumpadDel
SCKey NumpadDel
extended 0x0
================
VK 0x71
SC 0x3c
vkKey F2
SCKey F2
extended 0x0
================
Numpad del/dot with numlock
VK 0x6e
SC 0x53
vkKey NumpadDot
SCKey NumpadDel
extended 0x0
*/
; Detects Prtsc & Pause
; Can't do PrintScr too low level
KeyboardHook(nCode, wParam, lParam)
{
	global log
	static aExtendedRemap := {	"NumpadIns": "Ins"
							,	"NumpadHome": "Home"
							,	"NumpadPgUp": "PgUp"
							,	"NumpadDel": "Delete"
							,	"NumpadEnd": "End"
							,	"NumpadPgDn": "PgDn"}
			aNeutralRemap := { "LControl": "Control"
							, 	"LShift":	"Shift"
							,	"LAlt": 	"Alt"
							,	"LWin": 	"LWin"}

	static WM_KEYDOWN := 0x100, WM_KEYUP := 0x101, WM_SYSKEYDOWN := 0x0104, WM_SYSKEYUP := 0x0105
	Critical, 250 
	;soundplay *-1
	If !nCode 
	{
		vkCode := NumGet(lParam+0, 0)

		SetFormat, IntegerFast, hex
		vkCode := NumGet(lParam+0, 0)
		scanCode := NumGet(lParam+0, 4)
		flags := NumGet(lParam+0, 8)
		extended := flags & 1
		key := getKeyName("VK" vkCode)
		if (extended && aExtendedRemap.HasKey(key))
			key := aExtendedRemap[key]
		; Replace left and right modifiers with their neutral equivalent 
		if (neutralMap && (instr(key, "Control") || instr(key, "Shift") || instr(key, "Alt")))
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
			aKeys[key] := True
			settimer, updateEdit, -10
		}
		;else 
		;	aKeys.Remove(key)
	}
   Return CallNextHookEx(nCode, wParam, lParam) ; pass the key event onto other programs in the hook chain
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
f3::
clipboard := ""
sendEvent {WheelLeft}

return 
; (number >> 16) & 0xffff	
;	WheelMove := wParam > 0x7FFFFFFF ? HiWord(-(~wParam)-1)/120 :  HiWord(wParam)/120 

MouseHook(nCode, wParam, lParam)
{ 	static aMessages := {	"WM_LBUTTONDOWN":	0x201
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
			aKeys["LButton"] := True
		else if (wParam = aMessages.WM_RBUTTONDOWN)
			aKeys["RButton"] := True
		else if (wParam = aMessages.WM_MBUTTONDOWN)
			aKeys["MButton"] := True
		else 
		{
			mouseData := NumGet(lParam+0, 8, "Int")
			if (wParam = aMessages.WM_XBUTTONDOWN)
				aKeys[((mouseData >> 16) & 1  ? "XButton1" : "XButton2")] := True
			else if (wParam = aMessages.WM_MOUSEWHEEL || wParam = aMessages.WM_MOUSEHWHEEL)
			{
				; This gets the actual +/- rotations which will always be +1/-1
				; These are stored in the hiword of the dword mouseData
				if (mouseData > 0x7FFFFFFF)
					 rotations := (-(~(mouseData >> 16)) - 1)/120
				else 
					rotations := (mouseData >> 16) / 120

				if (wParam = aMessages.WM_MOUSEHWHEEL)
					aKeys[(rotations > 0 ? "WheelRight" : "WheelLeft")] := True
				else 
					aKeys[(rotations > 0 ? "WheelUp" : "WheelDown")] := True
			}
		}

	}
   	Return CallNextHookEx(nCode, wParam, lParam) ; make sure other hooks in the chain receive this event if we didn't process it
}
/*
				if (mouseData & 0x80000000)
					rotations := ((-(~mouseData)-1) >> 16)/120
				else 
					rotations := ((mouseData >> 16) & 0xFFFF)/120

				if (mouseData > 0x7FFFFFFF)
					rotations := (-(~(mouseData & 0x80000000 ? mouseData >> 16 : (mouseData >> 16) & 0xffff))-1)/120
				else 
					rotations := (((mouseData & 0x80000000 ? mouseData >> 16 : (mouseData >> 16) & 0xffff)))/120
					clipboard := rotations					

*/

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