; returns true if the current Input primary language is English

isInputLanguageEnglish()
{
	WinGet, WinID,, A
	InputLocaleID := DllCall("GetKeyboardLayout", "UInt", DllCall("GetWindowThreadProcessId", "UInt", WinID, "UInt", 0), "UInt")
	primaryLanguageID := InputLocaleID & 0xFF
	if (primaryLanguageID = LANG_ENGLISH := 9)
		return True
	return False
}

/*
http://msdn.microsoft.com/en-us/library/windows/desktop/ms646296(v=vs.85).aspx
http://msdn.microsoft.com/en-us/library/windows/desktop/dd318693(v=vs.85).aspx#NotesPrim

InputLocaleID = DWord
LoWord = SubLanguage and Primary language IDs
HiWord = Device handle to the physical layout of the keyboard

LowWord Layout: HiByte & LoByte
+-------------------------+-------------------------+
|     SubLanguage ID      |   Primary Language ID   |
+-------------------------+-------------------------+
15                    10  9                         0   bit

*/