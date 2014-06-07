; General Windows API Call.
; Currently my lib folder is in a mess. 
; But starting now I will try to put associated functions
; in a single lib.

; On Win7 0-31 
; 0 being slowest
getKeyRepeatRate()
{
    if !DLLCall("SystemParametersInfo", "UInt", SPI_GETKEYBOARDSPEED := 0x000A, "UInt", 0, "Uint*", speed, "UInt", 0)
        return -1 ; error 
    else return speed
}

; Win 7 0-3
; 0 being shortest delay
getKeyDelay()
{
    if !DLLCall("SystemParametersInfo", "UInt", SPI_GETKEYBOARDDELAY := 0x0016, "UInt", 0, "Uint*", delay, "UInt", 0)
        return -1 ; error 
    else return delay
}