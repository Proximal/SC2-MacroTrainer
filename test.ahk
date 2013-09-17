hook=
(
#Persistent
SAPI := ComObjCreate("SAPI.SpVoice")
speak("Test")
	speak(message)
	{
		global SAPI
		msgbox `% message
		SAPI.Speak(message)
		return
	}
)
hookThread := AhkDllThread("C:\Program Files\AutoHotkey\AutoHotkey.dll"), hookThread.ahktextdll(hook)
sleep 2000
hookThread.ahkFunction("speak", "Hello")
hookThread.ahkTerminate()