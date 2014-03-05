/*
; Written by SKAN
; www.autohotkey.com/forum/viewtopic.php?t=64128          CD:24-Nov-2008 / LM:28-May-2010
*/
; modified to return an object containing all info
/*
 Available object properties/keys
	FileDescription
	FileVersion
	InternalName
	LegalCopyright
	OriginalFilename
	ProductName
	ProductVersion
	CompanyName
	PrivateBuild
	SpecialBuild
	LegalTrademarks
*/
fileGetVersionInfo(peFile="") 
{  
	 Static CS, HexVal, Sps="                        ", DLL="Version\"
	 If ( CS = "" )
	  CS := A_IsUnicode ? "W" : "A", HexVal := "msvcrt\s" (A_IsUnicode ? "w": "" ) "printf"
	 If ! FSz := DllCall( DLL "GetFileVersionInfoSize" CS , Str,peFile, UInt,0 )
	   Return "", DllCall( "SetLastError", UInt,1 )
	 VarSetCapacity( FVI, FSz, 0 ), VarSetCapacity( Trans,8 * ( A_IsUnicode ? 2 : 1 ) )
	 DllCall( DLL "GetFileVersionInfo" CS, Str,peFile, Int,0, UInt,FSz, UInt,&FVI )
	 If ! DllCall( DLL "VerQueryValue" CS
	    , UInt,&FVI, Str,"\VarFileInfo\Translation", UIntP,Translation, UInt,0 )
	   Return "", DllCall( "SetLastError", UInt,2 )
	 If ! DllCall( HexVal, Str,Trans, Str,"%08X", UInt,NumGet(Translation+0) )
	   Return "", DllCall( "SetLastError", UInt,3 )
	 aFileInfo := []
	 StringFileInfo := "FileDescription|FileVersion|InternalName|LegalCopyright|OriginalFilename|ProductName|ProductVersion|CompanyName|PrivateBuild|SpecialBuild|LegalTrademarks"
	 Loop, Parse, StringFileInfo, |
	 { 
	 	subBlock := "\StringFileInfo\" SubStr(Trans,-3) SubStr(Trans,1,4) "\" A_LoopField
		If !DllCall( DLL "VerQueryValue" CS, UInt,&FVI, Str,SubBlock, UIntP,InfoPtr, UInt,0 )
	    	Continue
	  	aFileInfo[A_LoopField] := DllCall( "MulDiv", UInt,InfoPtr, Int,1, Int,1, "Str")
	} 
	Return aFileInfo
}