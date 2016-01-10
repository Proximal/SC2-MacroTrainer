; speechThread
; returns a string containing the speech script
; to be used by ahktextdll()

; **********
; Major issue to be aware of. Cant use ahkH ahkFunction - must use ahkPostFunction
; otherwise will cause an unknown com error 
;**************

/* List Installed Voices
SAPI := ComObjCreate("SAPI.SpVoice") 
for t in SAPI.GetVoices()
    msgbox % T.GetDescription

item := 0 ; zero based list
SAPI.Voice := SAPI.GetVoices().Item(item) ; sets voice to first installed voice
*/


; http://msdn.microsoft.com/en-us/library/ee431802(v=vs.85).aspx
; SAPI.Speak("<pitch absmiddle = '" pitch "'/>",0x20)    ; pitch : param1 from -10 to 10. 0 is default.

; SAPI COM errors
; http://msdn.microsoft.com/en-us/library/ee431883(v=vs.85).aspx

; SAPI flag values
; http://msdn.microsoft.com/en-us/library/ms720892(v=vs.85).aspx
/*
    Enum SpeechVoiceSpeakFlags
        'SpVoice Flags
        SVSFDefault = 0
        SVSFlagsAsync = 1
        SVSFPurgeBeforeSpeak = 2
        SVSFIsFilename = 4
        SVSFIsXML = 8
        SVSFIsNotXML = 16
        SVSFPersistXML = 32

        'Normalizer Flags
        SVSFNLPSpeakPunc = 64

        'TTS Format
        SVSFParseSapi = 
        SVSFParseSsml = 
        SVSFParseAutoDetect = 

        'Masks
        SVSFNLPMask = 64
        SVSFParseMask = 
        SVSFVoiceMask = 127
        SVSFUnusedFlags = -128
    End Enum
*/

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
    ( Comments %
        #Persistent
        #NoEnv
        chageScriptMainWinTitle()
        global SAPI := ComObjCreate("SAPI.SpVoice") ; This takes 8 ms
        return
        ; Have to blank the SAPI object before terminating speechThread
        ; Otherwise main program will hang when it attempts to terminate this thread
        ; Still sometimes hangs!!
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
        changeVoice(voiceName)
        {
            if (voiceName = "") ; default iniValue is null
                return 
            try obj := SAPI.GetVoices("Name=" voiceName)
            try if obj.count
                try SAPI.Voice := obj.Item(0)
        }
        
        ; Major issue to be aware of. Cant use ahkH ahkFunction - must use ahkPostFunction
        ; otherwise will cause an unknown com error 

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

            ; The 'asynchronous' parameter is really a flag parameter with numerous values.
            ; So make it either 1 for asynchronous (SVSFlagsAsync) or 0 for synchronous (SVSFDefault)
            ; See comments at top for other valid values.

            ; I've just discovered that not using ahkPostFunction will cause a comerror
            ; hence  using ahkPostFunction negates prevents the use of synchronous 
            ; to halt code execution so asynchronous is removed

            ; if SAPIVol is not number
            ;    asynchronous := 1
            ; else if asynchronous
            ;    asynchronous := 1
            ; else
            ;    asynchronous := 0   ; This isn't really required as it has to be a 0 to get here

            try 
            {  
                SAPI.Rate := rate
                SAPI.volume := SAPIVol
                SAPI.Speak(message, 1) ; 1 allows asynchronous, so function returns immediately. This solves all the problems with timings/losing messages                           
            }
            catch, e
            {
                if !A_IsCompiled
                {
                    s := "SAPI:``n" e.What "``n" e.File "``n" e.Line "``n" e.Message "``n" e.Extra
                    FileAppend, =========``n%s%``n========``n, log.txt
                    SAPI := ComObjCreate("SAPI.SpVoice") 
                }
            }
            Return
        }
        chageScriptMainWinTitle(newTitle := "")
        {
            static currentTitle := A_ScriptFullPath " - AutoHotkey"
            prevDetectWindows := A_DetectHiddenWindows
            prevMatchMode := A_TitleMatchMode
            DetectHiddenWindows, On
            SetTitleMatchMode, 2
            if (newTitle = "")
                newTitle := getRandomString_Az09(6, 20)
            WinSetTitle, %currentTitle%,, %newTitle%
            currentTitle := newTitle
            DetectHiddenWindows, %prevDetectWindows%
            SetTitleMatchMode, %prevMatchMode%
            return newTitle
        }
        getRandomString_Az09(minLength, maxLength, insertSpace := True)
        {
            loop, % l := rand(minLength, maxLength)
            {
                if (A_Index > 1 && A_Index != l && insertSpace && !rand(0, 5))
                    s .= A_Space
                else if rand(0, 4)
                    s .= Chr(rand(0, 2) ? rand(97, 122) : rand(65, 90) )  ; a-z : A-Z 
                else 
                    s .= rand(0, 9)   ; 0-9
            }
            return s
        }
        rand(a=0.0, b=1) 
        {
            random, r, a, b
            return r
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