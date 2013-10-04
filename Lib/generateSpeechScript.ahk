; speechThread
; returns a string containing the speech script
; to be used by ahktextdll()

generateSpeechScript()
{
	script = 
	(
		#Persistent
		global aMessages := []
		global SAPI := ComObjCreate("SAPI.SpVoice")
		setAHKVol(AHKVol)
		{
			if A_OSVersion NOT in WIN_XP,WIN_2003,WIN_2000 	; below vista this sets system volume rather than
			{										; process/program volume
				v := AHKVol*655.35
			    DllCall("winmm\waveOutSetVolume", "int", device-1, "uint", v|(v<<16))
			}	
			return
		}
		speak(message, SAPIVol := 100)
		{
		; 	This is commented out, as user can just modify volume via SAPI.
		;	Also this will prevent the AHK Speech thread showing up in the sound mixer 	
		;	if A_OSVersion NOT in WIN_XP,WIN_2003,WIN_2000 	; below vista this sets system volume rather than
		;	{										; process/program volume
		;		v := AHKVol*655.35
		;	    DllCall("winmm\waveOutSetVolume", "int", device-1, "uint", v|(v<<16))
		;	}	

			aMessages.insert({ "message": message 
							, "volume": SAPIVol})
			SetTimer,Speak,-10 ;-1 works too
			Return

			Speak:
				for index, message in aMessages
				{
					if (message.volume != preSAPIVol)
					{
						SAPI.volume := message.volume
						preSAPIVol := message.volume
					}
					try SAPI.Speak(message.message)
				}
				aMessages := []	
				Return
		}
	)
	return script
}

		; 	Using an object works well, and allows messages arriving near each other to be 
		; 	spoken without interfering with each other, that is, the speak function can be called 
		; 	again and again (with or without delay) and all of the messages will be spoken

/*	Testing

	Case 1:
		loop 30
			tSpeak(A_index, 100)
	
	Case 2:
		loop 30
		{
			tSpeak(A_index, 100)
			sleep 5
		}
	
	Result: All messages were spoken.
	
*/
