IconChanger(dotIcoFile)
{
	if !A_IsCompiled
		return
	msgbox This will attempt to change the included icons inside the binary file.`n`nThis may not work!`n`nOnly .ico files are compatible.`n`nThe program will close and attempt the operation.
	FileInstall, Included Files\IconChangerScript.ahk, %A_Temp%\IconChangerScript.ahk, 1
	pid := DllCall("GetCurrentProcessId")
	run, %A_Temp%\AHK.exe "%A_Temp%\IconChangerScript.ahk" /exe "%A_ScriptFullPath%" /icon "%dotIcoFile%" /pid "%pid%"
	exitapp 
}