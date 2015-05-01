#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#singleinstance force
previousVersion := CheckForUpdates("http://www.users.on.net/~jb10/macroTrainerCurrentVersion.ini")

gui, add, radio, y+25 vMajor gRadio section checked, Major Update 
gui, add, radio, y+10 vMinor gRadio, Minor Update 
gui, add, radio, xs+100 ys vCurrent gRadio, Current
gui, add, radio, xs+100 y+10 vCustom gRadio, Custom

Gui, add, text, xs y+20, Version Number:
Gui, Add, Edit, Right x+10 yp-2 w45 disabled vVersionNumber, % round(previousVersion + 0.01, 2) ; because major is the pre-selected
gui, add, button, xs gCompile, Compile!

gui, add, edit, xs w600 h200 vDisplay

Gui, show 
if (previousVersion = "")
	msgbox Failed to download current program version.
return 

radio:
GuiControl, % "enable" (A_GuiControl = "Custom"), VersionNumber
if (A_GuiControl = "Custom")
	GuiControl,, VersionNumber, %previousVersion%
else if (A_GuiControl = "Major")
	GuiControl,, VersionNumber, % round(previousVersion + 0.01, 2)
else if (A_GuiControl = "Minor")
	GuiControl,, VersionNumber, % round(previousVersion + 0.001, 3)
else if (A_GuiControl = "Current")
	GuiControl,, VersionNumber, %previousVersion%
return 

GuiClose:
ExitApp

compile:
UpdateDisplay("", False)
gui, submit, nohide
if VersionNumber is not number
{
  msgbox version is not a number! 
  return 
}
if Current
{
	msgbox, 4, Version, Are you sure you wish to compile using the live version?
	ifmsgbox No 
		return 	
}
if (VersionNumber <= previousVersion && !(VersionNumber = previousVersion && Current))
{
	if Custom
	{
		msgbox, 4, Version, % "The selected version number is " (VersionNumber = previousVersion ? "the same as" :"less than") " the current public version."
		. "`n`nDo you wish to proceed? "
		ifmsgbox No 
			return 
	}
  	else 
  	{
  		msgbox version error 
  		return 
  	}
}
setVariables()
cleanUp() ; Get rid of any old files. Allows FileExist() to somewhat validate ahk2exe compiled files
if filesNotExist() 
	return 
if compileIncludedThread(threadMiniMapSource, threadMiniMapFullExe, threadMiniMapFullAHK)  
	return
if compileIncludedThread(threadOverlaysSource, threadOverlaysFullExe, threadOverlaysFullAHK) 
	return
setVersion(VersionNumber)
if compileAndZipMain()
	return
UpdateDisplay("Finished!")
cleanUp()
Run, %A_WorkingDir%\bin
return 

setVariables()
{
	global 
	binFile := A_ScriptDir "\AHK_H modded Source and Files\AHK used by MacroTrainer\Compiler\MacroTrainerAutoHotkeySC.bin"
	ahk2Exe := A_ScriptDir "\AHK_H modded Source and Files\AHK used by MacroTrainer\Compiler\Ahk2Exe.exe"
	iconFile := A_ScriptDir "\Starcraft-2-32x32.ico"
	msvcrFile :=  A_ScriptDir "\msvcr100.dll"
	zipProgram :=   A_ScriptDir "\bin\7z.exe"
	threadMiniMapSource :=  A_ScriptDir "\threadMiniMap.ahk"
	threadMiniMapFullExe := A_ScriptDir "\bin\threadMiniMapfull.exe"
	threadMiniMapFullAHK := A_ScriptDir "\bin\threadMiniMapfull.ahk"

	threadOverlaysSource := A_ScriptDir "\threadOverlays.ahk"
	threadOverlaysFullExe := A_ScriptDir "\bin\threadOverlaysfull.exe"
	threadOverlaysFullAHK := A_ScriptDir "\bin\threadOverlaysfull.ahk"

	mainScriptSource := A_ScriptDir "\Macro Trainer.ahk"
	mainScriptTempExe := A_ScriptDir "\bin\Macro Trainer v" VersionNumber ".exe"
	aRubbish := [threadMiniMapFullAHK, threadMiniMapFullExe, threadOverlaysFullAHK, threadOverlaysFullExe, mainScriptTempExe, A_ScriptDir "\bin\ziplog.txt"]
	aRequiredFiles := [binFile, ahk2Exe, iconFile, msvcrFile, threadMiniMapSource, threadOverlaysSource, zipProgram, threadMiniMapSource, threadOverlaysSource, "macroTrainerCurrentVersion.ini", "MT_Config.ini"]
}

filesNotExist()
{
	global aRequiredFiles
	for i, file in aRequiredFiles
	{
		if !FileExist(file)
		{
			UpdateDisplay("File missing: " file)
			return True
		}
	}
	return False
}


compileIncludedThread(source, output, tempAHKFile)
{
	global
	UpdateDisplay("Compiling " source "....")
	runwait "%ahk2Exe%" /in "%source%" /out "%output%" /icon "%iconFile%" /bin "%binFile%"
	if !FileExist(output)
	{
		UpdateDisplay("Failed to compile: " output)
		return True, cleanUp()
	}	
	if (script := GetFileResource(output, ">AHK WITH ICON<")) = ""
	{
		UpdateDisplay("Failed to extract script resource from "  output)
		return True, cleanUp()
	}
	deleteAppend(script, tempAHKFile)
	return False	
}

setVersion(version)
{ 
	IniWrite, %version%, macroTrainerCurrentVersion.ini, info, currentVersion
	IniWrite, %version%, MT_Config.ini, Version, version
	deleteAppend("getMacroTrainerVersion()`r`n{`r`n`treturn " version "`r`n}", "lib\getMacroTrainerVersion.ahk")
}

compileAndZipMain()
{
	global 
	UpdateDisplay("Compiling " mainScriptSource "....")
	runwait "%ahk2Exe%" /in "%mainScriptSource%" /out "%mainScriptTempExe%" /icon "%iconFile%" /bin "%binFile%"
	if !FileExist(mainScriptTempExe)
	{
		UpdateDisplay("Failed to compile: " mainScriptTempExe)
		return True, cleanUp()
	}	
	FileDelete, bin\currentMacroTrainer.zip
	UpdateDisplay("Zipping....")
	runwait %comspec% /c "7z.exe a -mx9 -tzip currentMacroTrainer "%mainScriptTempExe%" "%msvcrFile%" > ziplog.txt", %A_WorkingDir%\bin, Hide
	fileread, ziplog, bin\ziplog.txt
	UpdateDisplay(ziplog)
	return !FileExist("bin\currentMacroTrainer.zip")	
}
cleanUp()
{
	global aRubbish
	for i, file in aRubbish
		FileDelete, %file%
	return 
}

UpdateDisplay(s, Append := True)
{
	if Append
		GuiControlGet, current,, display
	GuiControl,, display, % trim(current "`n" s, "`n")
	return
}

GetFileResource(file, scriptResource, type := 10)
{
    HMODULE := DllCall("LoadLibrary", "Str", file)
    res := DllCall("FindResource", "ptr", HMODULE, "str", scriptResource, "ptr", Type, "ptr")
    DataSize := DllCall("SizeofResource", "ptr", HMODULE, "ptr", res, "uint")
    hresdata := DllCall("LoadResource", "ptr", HMODULE, "ptr", res, "ptr")
    if (data := DllCall("LockResource", "ptr", hresdata, "ptr"))
        string := StrGet(data, DataSize, "UTF-8")    ; Retrieve text, assuming UTF-8 encoding.
    DllCall("FreeLibrary", "Ptr", HMODULE)
    return string
}

deleteAppend(text, fileName, Encoding := "CP65001")
{
	FileDelete, %fileName%
	FileAppend, %text%, %fileName%, %Encoding%
	return
}
CheckForUpdates(url)
{
  	URLDownloadToFile, %url%, %A_Temp%\version_checker_temp_file.ini
	if !ErrorLevel 
	{ 
		IniRead, latestVersion, %A_Temp%\version_checker_temp_file.ini, info, currentVersion, %installed_version%
		FileDelete %A_Temp%\version_checker_temp_file.ini
      	Return latestVersion
  	}
 	FileDelete %A_Temp%\version_checker_temp_file.ini
 	Return "" 
}

