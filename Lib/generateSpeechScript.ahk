; speechThread
; returns a string containing the speech script
; to be used by ahktextdll()

; http://msdn.microsoft.com/en-us/library/ee431802(v=vs.85).aspx
; SAPI.Speak("<pitch absmiddle = '" pitch "'/>",0x20)    ; pitch : param1 from -10 to 10. 0 is default.

/*
    ; This line returns within .2ms, but if first time creatng com
    ; then calls to SAPI.Speak are delayed for the next ~110ms
    SAPI := ComObjCreate("SAPI.SpVoice")
    SAPI.Rate := 0
    SAPI.volume := 100
    SAPI.Speak("this is a very long sentence, laughing not really!", 1)

    When fully initialised (as it normally is)
    its takes ~4ms to make a speak call, so best to place it in its own thread
    Takes 0.008 ms to call when in another thread via postFunction
*/

generateSpeechScript()
{
    script = 
    ( Comments 
        #Persistent
        #NoEnv
        global SAPI := ComObjCreate("SAPI.SpVoice")
        return
        clearSAPI:
        SAPI := []
        return
        setAHKVol(AHKVol)
        {
            if A_OSVersion NOT in WIN_XP,WIN_2003,WIN_2000         ; below vista this sets system volume rather than
            {                                                                                ; process/program volume
                v := AHKVol*655.35
                DllCall("winmm\waveOutSetVolume", "int", device-1, "uint", v|(v<<16))
            }        
            return
        }
        speak(message, SAPIVol := 100, rate := 0)
        {
        ;         This is commented out, as user can just modify volume via SAPI.
        ;        Also this will prevent the AHK Speech thread showing up in the sound mixer         
        ;        if A_OSVersion NOT in WIN_XP,WIN_2003,WIN_2000         ; below vista this sets system volume rather than
        ;        {                                                                                ; process/program volume
        ;                v := AHKVol*655.35
        ;            DllCall("winmm\waveOutSetVolume", "int", device-1, "uint", v|(v<<16))
        ;        }        
        ; if volume or rate are outside 0-100 and -10-10 respectively, then will give a runtime error
        ; when setting rate or volume. (decmials dont give an error)
        ; but this is suppressed by the try statement anyway and the words are spoken   

            if SAPIVol is not number
                SAPIVol := 100  
            else if (SAPIVol < 0)
                SAPIVol := 0
            else if (SAPIVol > 100)
                 SAPIVol := 100
           
            if rate is not number
                rate := 0 ; default
            else if (rate < -10)
                rate := -10
            else if(rate > 10)
                rate := 10 

            try 
            {  
                SAPI.Rate := rate
                SAPI.volume := SAPIVol
                SAPI.Speak(message, 1)  ; 1 allows asynchronous, so function returns immediately. This solves all the problems                             
            }
            Return
        }
    )
    return script
}

/*

;some errorcodes
E_INVALIDARG            = 0x80070057
NOERROR                 = 0x00000000 
CO_E_CLASSSTRING        = 0x800401F3 
REGDB_E_CLASSNOTREG     = 0x80040154 
REGDB_E_READREGDB       = 0x80040150 
CLASS_E_NOAGGREGATION   = 0x80040110 
E_NOINTERFACE           = 0x80004002
E_POINTER               = 0x80004003
E_HANDLE                = 0x80070006
E_ABORT                 = 0x80004004
E_FAIL                  = 0x80004005
E_ACCESSDENIED          = 0x80070005
E_PENDING               = 0x8000000A

E_FAIL = general failure
*/

        ; 8/12/13 
        ; I have suspected for a while that some messages were being discarded. 
        ; After testing on my PC the messages were being lost if tspeak was called rapidly
        ; Changing to asynchronous fixed this (should have checked if this method was available ages ago)

/*        Testing

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