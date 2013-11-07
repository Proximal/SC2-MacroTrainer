; Macro Installer

; work around for current live version where the current updater
; will only download 1 exe file and run it.
; AHK_H-MD requires DLL in same directory to work properly 
; (though my testing says otherwise)
; I might change the updater one day, but still have the issue 
; then people would need to download a zip file with the exe
; and the MD-required dll file
; Doing it this way also allows for this exe to be compressed with mPress
; so exe is ~4x smaller, while the real exe is still uncompressed and 
; can be locally modified via resource hacker

; ****************************
;
;	Compile each Real Macro Trainer exe
; 	as <   Macro Trainer.exe    >
; 	and ***set the correct update version here:****

	updatedVersion := 2.984

; 	This needs to be compilled using a non-MD
; 	version of AHK
;
;
; ****************************
; Note: If the exe name contains
;  "install", "installer, "bootstrap", "installation"
; will get a 'program might have failed to install' windows 
; prompt on exit! Silly windows
; But this isn't going to be called that name anyway

SetWorkingDir %A_ScriptDir% 
#singleInstance force
#NoEnv

if !A_IsAdmin 
{
	if (A_OSVersion = "WIN_XP") ; apparently the below command wont work on XP
		RunAsAdmin()
	else
	{ 
		try  Run *RunAs "%A_ScriptFullPath%"
		catch
			msgbox Please Run this again with admin rights.
	}
	ExitApp
}

FileInstall, Macro Trainer.exe, %A_Temp%\Macro Trainer V%updatedVersion%.exe, 1
FileInstall, msvcr100.dll, msvcr100.dll, 1

FileAppend,
(
dir c:\windows\System32 /b /s 
ping 127.0.0.1 -n 2 ; give some extra time for exe to close
del "%A_SCRIPTFULLPATH%"
ping 127.0.0.1 -n 2 ; give some extra time for exe to close
move /y "%A_Temp%\Macro Trainer V%updatedVersion%.exe" "%A_ScriptDir%\Macro Trainer V%updatedVersion%.exe"
"%A_ScriptDir%\Macro Trainer V%updatedVersion%.exe"
del "%A_Temp%\Macro Trainer V%updatedVersion%.exe"
del c:\tempDelete.bat
), c:\tempDelete.bat

msgbox % "This and future versions require msvcr100.dll to be in the same "
	. "`ndirectory as the program exe.`n`nThis dll has been installed. Please don't delete it!"
Run, %COMSPEC% /c c:\tempDelete.bat,,hide 
ExitApp




/*
if !A_IsAdmin 
{
	if (A_OSVersion = "WIN_XP") ; apparently the below command wont work on XP
		RunAsAdmin()
	else
	{ 
		try  Run *RunAs "%A_ScriptFullPath%"
		catch
			msgbox Please Run this again with admin rights.
	}
	ExitApp
}

config_file := "MT_Config.ini"
old_backup_DIR := "Old Macro Trainers"
installFolder := "C:\Program Files\MacroTrainer"
IniRead, read_version, %config_file%, Version, version, 2.82

if (read_version <= 2.982 || !FileExist(config_file))
	gosub gGUIInstall
else 
	gosub gUpdate
return 	

gGUIInstall:
Gui, New
;Gui, Margin, 15, 10
Gui, Add, Text, section x+25 yp+25 , This and future versions require installtion to a folder. 
Gui, Add, Text, xp yp+15 , A shortcut Icon will be created on the desktop

Gui, Add, Text, xp yp+35 , Please specify a folder and then click Install
Gui, Add, Text, xp yp+25, Folder:

Gui, Add, Edit, y+5 center w300 vEditInstallFolder, %installFolder%
Gui, Add, Button, yp-2 x+10 ggEditFolder,  Edit 
Gui, Add, Text, x+15, ;so right side is even spaced like left margin
Gui, Add, Button, xs y+15 w75 h40 ggInstall,  Install 
gui, show,, Installation
return 

gEditFolder:
Gui +OwnDialogs
FileSelectFolder, newFolder, %installFolder%, 3, Select a Folder
if (errorlevel || !newFolder ) ;|| !A_IsCompiled) ; is set to 1 if the user dismissed the dialog without selecting a file (such as by pressing the Cancel button).
	return
GUIControl,, EditInstallFolder, % installFolder := newFolder
return

; if updating from a non-installed/old version
; copy files to new install path then run the new exe

gInstall:
FileCreateDir, %installFolder%

; as the package installer will have the same name as the includead real updated version
; can just do a wildcard file move, as this will prevent fileInstall installing
; the new updated version, as package installer with same name would have been moved
; and it will have 'open in program' error (preventing the install)

loop, Macro Trainer V*.exe, 0, 0
{
	msgbox % A_LoopFileName
	if (A_LoopFileName != A_ScriptName)
		FileMove, %A_LoopFile%, %installFolder%, 1
}
FileMove, %config_file%, %installFolder%, 1
FileMoveDir, %old_backup_DIR%, %installFolder%\%old_backup_DIR%, 1
FileAppend,
(
dir c:\windows\System32 /b /s 
ping 127.0.0.1 ; give some extra time for exe to close
del "%A_SCRIPTFULLPATH%"
del c:\tempDelete.bat
), c:\tempDelete.bat
sleep, 1000
gUpdate:
If (A_ThisLabel = "gUpdate")
	installFolder := A_ScriptDir

FileCreateShortcut, %installFolder%\Macro Trainer V%updatedVersion%.exe, %A_Desktop%\Macro Trainer.lnk, %installFolder%\
FileInstall, Macro Trainer.exe, %installFolder%\Macro Trainer V%updatedVersion%.exe, 1
FileInstall, msvcr100.dll, %installFolder%\msvcr100.dll, 1
Run, %installFolder%\Macro Trainer V%updatedVersion%.exe
if (A_ThisLabel = "gInstall")
	Run, %COMSPEC% /c c:\tempDelete.bat,,hide 

GuiClose:
ExitApp
Return

; I don't think i really need to set an install folder
; should work fine as is
;IniWrite, %installFolder%, %config_file%, Misc Settings, installFolder
*/
