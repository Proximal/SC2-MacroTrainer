; speechThread
#Persistent

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
	static m, SAPI := ComObjCreate("SAPI.SpVoice")
	SAPI.volume := SAPIVol

; 	This is commented out, as user can just modify volume via SAPI.
;	Also this will prevent the AHK Speech thread showing up in the sound mixer 	
;	if A_OSVersion NOT in WIN_XP,WIN_2003,WIN_2000 	; below vista this sets system volume rather than
;	{										; process/program volume
;		v := AHKVol*655.35
;	    DllCall("winmm\waveOutSetVolume", "int", device-1, "uint", v|(v<<16))
;	}	

	m:=message
	SetTimer,Speak,-10 ;-1 works too
	Return

	Speak:
	try SAPI.Speak(m)
	Return
}
