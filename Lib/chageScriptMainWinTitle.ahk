; This will prevent singleInstance working
; could save current title to iniFile and use that as a check
; and/or have just one random title for each user
chageScriptMainWinTitle(newTitle := "")
{
	static currentTitle := A_ScriptFullPath " - AutoHotkey"
	prevDetectWindows := A_DetectHiddenWindows
	prevMatchMode := A_TitleMatchMode
	DetectHiddenWindows, On
	SetTitleMatchMode, 2
	if (newTitle = "")
	{
		loop, % rand(2,20)
		{
			if rand(0,4)
				newTitle .= Chr(rand(97, 122)) 	; a-z
			else 
				newTitle .= Chr(rand(48, 57))   ; 0-9
		}
			
	}
	WinSetTitle, %currentTitle%,, %newTitle%
	currentTitle := newTitle
	DetectHiddenWindows, %prevDetectWindows%
	SetTitleMatchMode, %prevMatchMode%
	return newTitle
}
 
