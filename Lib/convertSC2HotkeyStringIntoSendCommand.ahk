/* SC2 Hotkey Rules
	
	If no key is assigned then ini key is blank e.g.
		AlertRecall=
	If an alternate hotkey is present, looks like
		TownCamera=Backspace,Space

	Modifiers are written out in this order:
		Control+Alt+Shift+Keyname

	Apparently nothing can be bound to the wheel (i thought you COULD do that in sc2....)

	Neutral modifier keys only.

	Build/control card hotkeys like build worker, observer, move, patrol etc (anything on the control card)
		can only contain one key.
		Can not be a modifier alone
	
	Global Hotkeys
		Can be a single modifier e.g. Control
		Can have multi modifier only hotkey e.g. Control+Shift+Alt
		Can have multi modifier hotkey Control+Shift+Alt+D
		PrintScreen can not be bound
		"Shift+[" in SC2 GUI is written out as Shift+BracketOpen
		"Caps Lock" = CapsLock
		"=" = Equals
		"Pause" = Pause
		"ScrollLock" = ScrollLock



*/

/*
	The file Variables.txt within the root account folder has a key which lists the current 
	hotkey profile

	hotkeyprofile=testhotkey


*/


getSCHotkeys()
{
;	hotkeyIniFile
	
	variablesFilePath := getAccountFolder() "Variables.txt"


}



; This function was written a year or two ago. I would do things differently now,
; But lets go with it.
; takes a hotkey stored in SC2s syntax and the corresponding AHK Send command

convertSC2HotkeyStringIntoSendCommand(String)
{
						;	"SC2Key": "AhkKey"
	static aTranslate := {	"PageUp": "PgUp"
						,	"PageDown": "PgDn"
						,	"NumPadMultiply": "NumpadMult"
						,  	"NumPadDivide": "NumpadDiv"
						,	"NumPadPlus": "NumpadAdd"				
						,	"NumPadMinus": "NumpadSub"

						, 	"Grave": "``" ;note needs escape character!
						, 	"Minus": "-"
						, 	"Equals": "="
						, 	"BracketOpen": "["
						, 	"BracketClose": "]"
						,	"BackSlash": "\"						
						, 	"SemiColon": ";"
						, 	"Apostrophe": "'"
						, 	"Comma": ","
						, 	"Period": "."
						,	"Slash": "/"

						, 	"LeftMouseButton": "LButton"
						, 	"RightMouseButton": "RButton"
						,	"MiddleMouseButton": "MButton"
						, 	"ForwardMouseButton": "XButton1"
						, 	"BackMouseButton": "XButton2" }
						; apparently nothing can be bound to the wheel (i thought you COULD do that in sc2....)

	; NumpadDel maps to real delete key, same for NumpadIns, Home, End and num-UP,Down,Left,Right, and Num-PageUp/Down and enter
	; {NumpadClear} (num5 with numlock off) doesnt map to anything
	; nothing can be mapped to windows keys or app keys

; Easier to use string replace here and have the modifiers separate and outside of the
; aTranslate associative array. As AHK Associative arrays are indexed alphabetically (not in order in which keys were added)
; so this would result in modifier strings being incorrectly converted
; SC2 Hotkeys are done in this Order Control+Alt+Shift+Keyname
StringReplace, String, String, Control+, ^, All ;use modifier+ so if user actually has something bound to it wont cause issue
StringReplace, String, String, Alt+, !, All 
StringReplace, String, String, Shift+, +, All 	;this will also act to remove SC2's joining '+'


	; string replace accounts for differences between AHK send Syntax and SC2 hotkey storage

	for SC2Key, AhkKey in aTranslate
		StringReplace, String, String, %SC2Key%, %AhkKey%, All 

	; I don't think this is required as you can't bind those characters
	; At least, they're not written to the hotkey file like that
	;if String in !,#,+,^,{,} ; string must be 1 character length to match
	;	return "{" String "}"

	aModifiers := ["+", "^", "!"]
	;lets remove the modifiers so can see command length
	for index, modifier in 	aModifiers
		if inStr(string, modifier)
		{
			StringReplace, String, String, %modifier%,, All
			StringModifiers .= modifier
		}

	; lets correct for any difference in the command names
	; CapsLock ScrollLock NumLock
	; cant bind anything to windows key or appskey in game



	if (StrLen(string) > 1)
		string := StringModifiers "{" string "}" ; as AHK commands > 1 are enclosed in brackets
	else string := StringModifiers string

	if (string = "+=") 		; AHK cant send this correctly != and +- work fine
		string := "+{=}" 	; +!= works fine too as does !+= and ^+=

	; lower-case, if want to use with AHKs sendinput a 'H' is equivalent to '+H'
	StringLower, string, string
	return string
}