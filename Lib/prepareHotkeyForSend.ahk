; Can be used to send basic AHK hotkeys e.g. A_thishotkey
; doesn't support a & b:: hotkeys
; doesn't support non-standard modified hotkeys such as @:: (shift+2) or <:: (shift+,)
prepareHotkeyForSend(hotkey)
{
	If hotkey in $,*,~
		return hotkey
	for i, char in ["^", "+", "!", "#"]
	{
		if instr(hotkey, char)
			modifiers .= char
	}
	hotkey := RegExReplace(hotkey,"[\*\~\$\#\+\!\^\<\>]")
	return modifiers "{" hotkey "}"
}