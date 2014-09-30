CriticalSection(LPCRITICAL_SECTION="ÿÿÿÿ"){
  static
  If (LPCRITICAL_SECTION!="" and LPCRITICAL_SECTION!="ÿÿÿÿ"){
    DllCall("DeleteCriticalSection","Uint",LPCRITICAL_SECTION)
    Return
  } else if (LPCRITICAL_SECTION=""){
    Loop % (count){
      DllCall("DeleteCriticalSection","Uint",&CriticalSection%count%)
      count:=0
    }
    Return
  }
  count++
  VarSetCapacity(CriticalSection%count%,24)
  DllCall("InitializeCriticalSection","Uint",&CriticalSection%count%)
  Return &CriticalSection%count%
}