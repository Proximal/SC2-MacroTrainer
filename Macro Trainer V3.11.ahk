;-----------------------
;	For updates:
; ** check the multi inject option for this update
;	Change version number in exe and config file
;	Upload the changelog, file version  and new exe files to the ftp server
; 	check dont have debugging hotkeys and clipboards at end of script
;	check dont have the 'or debug' uncommented
;-----------------------
;	git add -A
;	git commit -m "Msg"
;	git push
;-----------------------

;***********
; 20/03/14
; There is a minor issue with the quick select save feature
; While editing i noticed an old item was still present, then apon saving everything moved 
; one item to the left, and item one was discarded.
; -------------
; Noticed a problem with Ctrl+shift deselecting unit types in quick select function.
; occurs for units which share a tab position eg stank/tanks, hellions/hellbats etc
; Fixed it by just shift clicking every unit
; Could add an exception list which ensures only these type of units can be shift clicked
; but i dont wont to muck around with it atm.
;***********

; if script re-copied from github should save it using UTF-8 with BOM (otherwise some of the ascii symbols like • wont be displayed correctly)
/*	Things to do
	Check if chrono structures are powered - It seems to be a behaviour ' Power User (Queue) '
*/

/*	
	Known Problems:
		Pressing Esc to cancel chat while having one base selected will cancel auto production for 4.5 seconds

	SC2 will not respond to a 'tab'-next subgroup command if the chat is open even when its not in focus
	the Shift+Tab (previous subgroup) does however work
*/

/*
	For Updates: 
	Disable Auto-Inject
	Disable Auto Grouping
	Disable Hostile colour assist
	Change ToggleWorkerState to #F2
	Local player colour
	Disable Spread and RemoveUnit

	remove log in unit panel for missing upgrades

*/

SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force 
#MaxHotkeysPerInterval 99999	; a user requested feature (they probably have their own macro script)
#InstallMouseHook
#InstallKeybdHook
#UseHook
#KeyHistory 0 ; don't need it
;#KeyHistory 500 ; testing
#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#MaxThreads 20 ; don't know if this will affect anything
If 0 ; ignored by script but installed by compiler
{
  	FileInstall, Included Files\ahkH\AutoHotkeyMini.dll, this param is ignored
   	FileInstall, Included Files\ahkH\AutoHotkey.dll, this param is ignored
}
SetStoreCapslockMode, off ; needed in case a user binds something to the capslock key in sc2 - other AHK always sends capslock to adjust for case.
ListLines(False) 
SetControlDelay -1 	; make this global so buttons dont get held down during controlclick
SetKeyDelay, -1	 	; Incase SendInput reverts to Event - and for controlsend delay
SetMouseDelay, -1
SetBatchLines, -1
SendMode, Input 
Menu, Tray, Icon 
if !A_IsAdmin 
{
	if (A_OSVersion = "WIN_XP") ; apparently the below command wont work on XP
		RunAsAdmin()
	else
	{ 
		try  Run *RunAs "%A_ScriptFullPath%"
		; The catch is here, as I had someone say
		; that the program just exited without
		; prompting for admin rights
		catch
			msgbox Please Run this again with admin rights.
	}
	ExitApp
}
OnExit, ShutdownProcedure
scriptWinTitle := changeScriptMainWinTitle()


; Just testing this - doesn't seem to make a difference
;if !A_IsCompiled
;	Process, Priority,, H

; This is here in case the user deletes the dll
; although, the AHK-MD shouldn't launch if it doesn't exist
; (and there's not one in sys32)
if (!FileExist("msvcr100.dll") && A_IsCompiled)
{
	FileInstall, msvcr100.dll, msvcr100.dll, 0
	reload ; already have admin rights
	sleep 1000 ; this sleep is needed to prevent the script continuing execution before this instance is closed
}
;if A_IsCompiled
;	Gosub, SingleInstanceCheck

InstallSC2Files() ; Run this before the gosub pre_startup  - otherwise menu items will be missing!

Menu Tray, Add, &Settings && Options, options_menu
Menu Tray, Add, &Check For Updates, TrayUpdate
Menu Tray, Add, &Homepage, Homepage
Menu Tray, Add, &Reload, g_reload
Menu Tray, Add, Exit, ExitApp ;this is actually a label not the command!
Menu Tray, Default, &Settings && Options
If A_IsCompiled
	Menu Tray, NoStandard
Else
{
	Menu Tray, Icon, Included Files\Used_Icons\Starcraft-2.ico

	global debugGame := False 
	debugShutdown := True
	hotkey, ^+!F12, g_GiveLocalPlayerResources
	hotkey, *>!F12, g_testKeydowns ; Just for testing will remove soon
}
Menu, Tray, Icon,,, 1 ; freeze the icon


RegRead, wHookTimout, HKEY_CURRENT_USER, Control Panel\Desktop, LowLevelHooksTimeout
if (ErrorLevel || wHookTimout < 600)
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Control Panel\Desktop, LowLevelHooksTimeout, 600
; This will up the timeout from  300 (default). Though probably isn't required

Global aThreads := CriticalObject() ; Thread safe object
aThreads.Speech := AhkDllThread("Included Files\ahkH\AutoHotkeyMini.dll")
aThreads.Speech.ahktextdll(generateSpeechScript())

global aLocalUnitData := []
global localUnitDataCriSec := CriticalSection()

start:
global config_file := "MT_Config.ini"
old_backup_DIR := "Old Macro Trainers"
url := []
url.CurrentVersionInfo := "http://www.users.on.net/~jb10/macroTrainerCurrentVersion.ini"
url.changelog := "http://www.users.on.net/~jb10/MT_ChangeLog.html"
url.HelpFile := "http://www.users.on.net/~jb10/MTSite/helpfulAdvice.html"
url.Downloads := "http://www.users.on.net/~jb10/MTSite/downloads.html"
url.ChronoRules := "http://www.users.on.net/~jb10/MTSite/chronoBoost.html"
url.Overlays := "http://www.users.on.net/~jb10/MTSite/miniMapOverlays.html"
url.Homepage := "http://www.users.on.net/~jb10/MTSite/overview.html"
url.PixelColour := url.homepage "Macro Trainer/PIXEL COLOUR.htm"
url.BugReport := "http://mt.9xq.ru/"

MT_CurrentInstance := [] ; Used to store random info about the current run
program := []
program.info := {"IsUpdating": 0} ; program.Info.IsUpdating := 0 ;has to stay here as first instance of creating infor object

ProgramVersion := 3.11

l_GameType := "1v1,2v2,3v3,4v4,FFA"
l_Races := "Terran,Protoss,Zerg"
GLOBAL GameWindowTitle := "StarCraft II"
GLOBAL GameIdentifier := "ahk_exe SC2.exe"
GLOBAL GameExe := "SC2.exe"
global a_pBitmap ; Used by the autoBUild In game GUI

input.winTitle := GameIdentifier
; For some reason this has to come before Gdip_Startup() for reliability 
DllCall("RegisterShellHookWindow", UInt, getScriptHandle())

pToken := Gdip_Startup()
Global aUnitID, aUnitName, aUnitSubGroupAlias, aUnitTargetFilter
Global aAGHotkeys := []
SetupUnitIDArray(aUnitID, aUnitName)
getSubGroupAliasArray(aUnitSubGroupAlias)
setupTargetFilters(aUnitTargetFilter)
	
CreatepBitmaps(a_pBitmap, aUnitID)
Menu, Tray, Tip, MT_V%ProgramVersion% Coded By Kalamity

If InStr(A_ScriptDir, old_backup_DIR)
{
	Msgbox, 4372, Launch Directoy?, This program has been launched from the "%old_backup_DIR%" directory.`nThis could be caused by running  the program via a shortcut/link after the program has updated.`nThis is due to the fact that the windows shortcut is updated to the old versions 'new/backup' location.`nIn future, please don't run this program using shortcuts.`n`nI recommend pressing NO to EXIT.`n`n %A_Tab% Continue?
	IfMsgBox No
		ExitApp
}
Gosub, pre_startup ; go read the ini file

if MTCustomIcon 
	Menu, Tray, Tip, %A_Space% ;clear the tool tip on mouse over

SetProgramWaveVolume(programVolume)

;	this is required to enable drag and drop onto AHK control on vista and above 
;	systems while running with admin privileges 
; 	this has a 'process wide' scope (tested it, and it seems to mean what it says i.e. 
;	it reverts on closing)

if A_OSVersion in WIN_8,WIN_7,WIN_VISTA
{  
	DllCall("ChangeWindowMessageFilter", uint, 0x49, uint, 1) 	; WM_COPYGLOBALDATA 1 allows message to be received 
	DllCall("ChangeWindowMessageFilter", uint, 0x233, uint, 1) 	; WM_DROPFILES
}

;-----------------------
;	Startup
;-----------------------

If (auto_update AND A_IsCompiled AND url.UpdateZip := CheckForUpdates(ProgramVersion, latestVersion, url.CurrentVersionInfo))
{
	gosub autoUpdateFound
	return			
}

LaunchClose:
Launch: ; Used by the buttons in the GUI auto update (disable & cancel)
If (A_GuiControl = "Disable_Auto_Update")
{
	; need to specify the options: gui as this thread wasn't spawned from the options menu
	GuiControl, Options:, auto_update, 0 ; Uncheck - when first installed the options GUI will appear before the
								; Update box - so user could click disable and the box in the GUI would still be checked and the state changed back to on when they save the options menu
	Iniwrite, % auto_update := 0, %config_file%, Misc Settings, auto_check_updates
}
If (A_GuiControl = "Disable_Auto_Update" || A_GuiControl = "Cancel_Auto_Update"
|| A_ThisLabel = "LaunchClose")
	Gui Destroy

If launch_settings
	gosub options_menu

if (MTCustomProgramName && A_ScriptName != MTCustomProgramName && A_IsCompiled)
{
	FileCopy, %A_ScriptName%, %MTCustomProgramName%, 1
	FullPath := A_ScriptDir "\" MTCustomProgramName
	if (A_OSVersion = "WIN_XP") ; apparently the below command wont work on XP
		try RunAsAdmin(FullPath, A_ScriptDir)
	else try Run *RunAs "%FullPath%"
	ExitApp
}

if (!isInputLanguageEnglish() && !MT_HasWarnedLanguage)
{
	IniWrite, 1, %config_file%, Misc Info, MT_HasWarnedLanguage
	msgbox, % 32 + 4096, Non-English Input Language, % "It seems you are using a non-English language/character-set.`nThis program may not function correctly with non-English keyboard layouts."
			. "`n`nIf you experience problems, perhaps try changing your keyboard-input layout/language to English."
			. "`n`nYou will not see this warning again."
}

; 	Note:	Emergency Restart Hotkey - Something to keep in mind if actually using the Real BlockInput Command 
;	Certain types of hook hotkeys can still be triggered when BlockInput is on. 
;	Examples include MButton (mouse hook) and LWin & Space
;	 ***(KEYBOARD HOOK WITH EXPLICIT PREFIX RATHER THAN MODIFIERS "$#")***.
;	hence <#Space wont work

CreateHotkeys()			;create them before launching the game in case users want to edit them
releaseLogicallyStuckKeys(True) ; in case a key is logically stuck and user doesn't use emergency button
process, exist, %GameExe%
If !errorlevel
{
	MT_CurrentInstance.SCWasRunning := False
	if (LauncherMode = "Battle.net" && StarcraftExePath())
		run, % StarcraftExePath(), % StarcraftInstallPath(), UseErrorLevel ; try doesn't seem to work now after reinstaling SC - so use errorlevel to suppress runtime errors
	else if (LauncherMode = "Starcraft" && switcherExePath())
		run, % switcherExePath(), % StarcraftInstallPath(), UseErrorLevel
}
else MT_CurrentInstance.SCWasRunning := True
Process, wait, %GameExe%	
	
; 	waits for starcraft to exist
; 	give time for SC2 to fully launch. This may be required on slower or stressed computers
;	to give time for the  window to fully launch and activate to allow the
; 	WinGet("EXStyle") style checks to work properly
;  	Placed here, as it will also give extra time before trying to get 
;	base address (though it shouldn't be required for this)

if !MT_CurrentInstance.SCWasRunning
	sleep 2000 
WinWait, %GameIdentifier%
while (!(B_SC2Process := getProcessBaseAddress(GameIdentifier)) || B_SC2Process < 0)		;using just the window title could cause problems if a folder had the same name e.g. sc2 folder
	sleep 400				; required to prevent memory read error - Handle closed: error 		
SC2hWnd := WinExist(GameIdentifier)
OnMessage(DllCall("RegisterWindowMessage", Str,"SHELLHOOK" ), "ShellMessage")
versionMatch := loadMemoryAddresses(B_SC2Process, clientVersion := getProcessFileVersion(GameExe))
settimer, timer_exit, 500, -100 ; Put this here so if user closes and Reopens SC while a version mismatch is displayed the RPM() won't fail
if (!versionMatch && clientVersion && A_IsCompiled) ; clientVersion check if true - if function fails (shouldn't) it will be 0/blank
{
	IniRead, clientVersionWarning, %config_file%, clientVersionWarning, clientVersionWarning, 1 
	if (clientVersion != clientVersionWarning)
	{
		IniWrite, %clientVersion%, %config_file%, clientVersionWarning, clientVersionWarning
		msgbox, % 48 + 4096, Version Mismatch, % "Current Client Version: " clientVersion
			. "`n`nMacro Trainer does not support this SC version and may function incorrectly."
			. "`n`nTry playing a game against an AI to see if it works. (Use a standard ladder map)"
			. "`nAlternatively, from the options menu click Settings --> Pattern Scan. If all the cells are green then the program will probably work."
			. "`n`nAn update will be released shortly."
			, 20 ; timeout 
	}
}
; it would have been better to assign all the addresses to one super global object
; but i tried doing this once before and it caused issues because i forgot to update some address 
; names in the functions.... so i cant be bothered taking the risk
settimer, clock, 250
; now using a shell monitor to keep destroy overlays
;SetTimer, OverlayKeepOnTop, 2000, -2000	;better here, as since WOL 2.0.4 having it in the "clock" section isn't reliable 	

;l_Changeling := aUnitID["ChangelingZealot"] "," aUnitID["ChangelingMarineShield"] ","  aUnitID["ChangelingMarine"] 
;				. ","  aUnitID["ChangelingZerglingWings"] "," aUnitID["ChangelingZergling"]


if A_OSVersion in WIN_7,WIN_VISTA ; win8 should probably be here too - need read up on DWM in windows8
{
	if !DwmIsCompositionEnabled() && !MT_DWMwarned && !MT_Restart && A_IsCompiled ; so not restarted via hotkey or icon 
	{
		ChangeButtonNames.set("DWM is Disabled?", "Help", "Ignore") 
		; msgbox with exclamation and Ok, Cancel Buttons
		MsgBox, 49, DWM is Disabled?
		,	% "Desktop Widows Management (DWM) is disabled!`n`n" 
		.	"This will cause significant performance issues while using this program.`n"
		.  	"Your FPS can be expected to decrease by 50-70%`n`n" 
		.	"Click  'Help' to launch some URLs explaining how to enable DWM.`n`n"
		.	"You will not see this warning again!"	
		IniWrite, % MT_DWMwarned := True, %config_file%, Misc Info, MT_DWMwarned
		ifMsgbox Ok ; 'Help'
		{
			run http://answers.microsoft.com/en-us/windows/forum/windows_vista-desktop/need-to-enable-desktop-window-manager/7e011e13-1005-467b-8dc0-10342f8f71e6
			run http://www.petri.co.il/enable_windows_vista_aero_graphics.htm
		}
	}
}

; SC2 Window Modes EXStyle
; Windowed FullScreen 	:= 0x00040000
; FullScreen 			:= 0x00040008
; Windowed 				:= 0x00040100
 
; Breakdown
; WS_THICKFRAME       =   0x00040000 ; WindowedFullScreen
; WS_EX_TOPMOST       =   0x00000008
; WS_EX_WINDOWEDGE    =   0x00000100
; winset fails when attempting to modify these values

; 	Style or ExStyle: Retrieves an 8-digit hexadecimal number representing style 
;	or extended style (respectively) of a window. 
;	If there are no matching windows, OutputVar is made blank. 
SC2WindowEXStyles := []
	SC2WindowEXStyles.WindowedFullScreen := 0x00040000
	SC2WindowEXStyles.FullScreen := 0x00040008
	SC2WindowEXStyles.Windowed := 0x00040100

If WinGet("EXStyle", GameIdentifier) = SC2WindowEXStyles.FullScreen
&& (DrawMiniMap || DrawAlerts || DrawSpawningRaces
|| DrawIncomeOverlay || DrawResourcesOverlay || DrawArmySizeOverlay
|| DrawWorkerOverlay || DrawIdleWorkersOverlay || DrawLocalPlayerColourOverlay
|| DrawUnitOverlay || DrawUnitUpgrades || DrawAPMOverlay || DrawMacroTownHallOverlay || DrawLocalUpgradesOverlay)
&& !MT_Restart && A_IsCompiled ; so not restarted via hotkey or icon 
{
	ChangeButtonNames.set("SC2 Is NOT in 'windowed Fullscreen' mode!", "Disable", "Continue") 
	; OK/Cancel messagebox
	MsgBox, 49, SC2 Is NOT in 'windowed Fullscreen' mode!
	, % "Starcraft seems to be in 'fullscreen' mode and you have overlays enabled within"
	. " the Macro Trainer.`n`n"
	. "The Minimap hack and overlays will only be visible while in 'windowed Fullscreen' mode.`n`n"
	. "This setting can be changed within the SC2 options menu.`n`n"
	. "Click 'Disable' to turn off all the overlays in Macro Trainer.`n"
	. "Click 'Continue' if you intend on changing the SC2 Window Mode."
	ifMsgbox Ok ; 'Disable'
	{
		DrawMiniMap := DrawAlerts := DrawSpawningRaces := DrawIncomeOverlay := DrawResourcesOverlay
		:= DrawArmySizeOverlay := DrawWorkerOverlay := DrawIdleWorkersOverlay 
		:= DrawLocalPlayerColourOverlay := DrawUnitOverlay := DrawUnitUpgrades 
		:= DrawAPMOverlay := DrawMacroTownHallOverlay := DrawLocalUpgradesOverlay := 0
		gosub, ini_settings_write
	}
}
;settimer, g_CheckForScriptToGetGameInfo, -3600000 ; 1hour
return
;-----------------------
; End of execution
;-----------------------
#Include <Gdip>
#Include <SC2_MemoryAndGeneralFunctions>
#Include <classInput>
#Include <setLowLevelInputHooks>
#Include <WindowsAPI> 
#include %A_ScriptDir%\Included Files\Class_ChangeButtonNames.AHk
; Contains labels/routines for the chrono boost section of the GUI
#include <classMemory>
#Include, Included Files\Class_SCPatternScan.ahk
#Include, Included Files\chronoGUIMainScript.ahk
#include <Class_SC2Keys>

ColourSelector:
; A_GuiControl = #AssociatedVariable
; Removes the prefixed # and so gets the name of the associated variable 
; allowing the colour to be retrieved and saved 
; The hwnd variable name is this with a prefixed '_' ie _AssociatedVariable
ChooseColourVariable := SubStr(A_GuiControl, 2)	
pictureColour := %ChooseColourVariable% ; get the current colour value
pictureHwnd := "_" ChooseColourVariable
pictureHwnd := %pictureHwnd%
Gui +hwndOptionsGuiHwnd ; get hwnd to disable options GUI until colour is picked
; When specifying the selected colour the alpha channel is must be 00 (otherwise the displayed colour is black). 
; The alpha channel must be 0 in the custom colour palette colours as well.
selectedColour := ChooseColor(pictureColour & 0x00FFFFFF, OptionsGuiHwnd,,,aChooseColourCustomPalette)
if !ErrorLevel ; User clicked ok/accept
{
	; Set Alpha channel to max as this function doesn't set it.
	; Save the value in hex RGB format in the ini rather than a random decimal value.
	; The alpha channel will be blank, so set it to FF
	%ChooseColourVariable% := dectohex(selectedColour | 0xFF000000) 
	if (ChooseColourVariable = "TransparentBackgroundColour") ; so the alpha component gets drawn
		gosub, UpdateTransparentGUIColour
	else paintPictureControl(pictureHwnd, %ChooseColourVariable%)
}
return

UpdateTransparentGUIColour:
GuiControlGet, value,, TransparentBackgroundSlider
if !ErrorLevel
{
	value := (value * 2.55 ) & 0xFF ; limit it to 0 - 255 (shouldn't be required).
	paintPictureControl(_TransparentBackgroundColour, TransparentBackgroundColour := (TransparentBackgroundColour & 0x00FFFFFF) | (value << 24))
}	
return 

ResetTransparentBackgroundColour:
TransparentBackgroundColour := 0x78000000
GuiControl,, TransparentBackgroundSlider, % round((TransparentBackgroundColour >> 24) / 2.55)
paintPictureControl(_TransparentBackgroundColour, TransparentBackgroundColour)
return 

paintPictureControl(Handle, Colour, RoundCorner := 0, ControlW := "", ControlH := "")
{ 
	; GuiControlGet will only work for the current GUI thread. Could add a another variable for
	; this if required
	If (ControlW = "" OR ControlH = "")
		GuiControlGet, Control, Pos, %Handle%

	pBitmap  := Gdip_CreateBitmap(ControlW, ControlH)
	G := Gdip_GraphicsFromImage(pBitmap)
	pBrushBackground  := Gdip_BrushCreateSolid("0xFFF0F0F0") 	;cover the edges of the pic
	Gdip_FillRectangle(G, pBrushBackground, 0, 0, ControlW, ControlH)
	pBrush  := Gdip_BrushCreateSolid(Colour)
	if RoundCorner
	{
		Gdip_SetSmoothingMode(G, 4)
		Gdip_FillRoundedRectangle(G, pBrush, 0, 0, ControlW, ControlH, RoundCorner)
	}
	Else 
	{
		Gdip_FillRectangle(G, pBrush, 0, 0, ControlW, ControlH)
		pPen := Gdip_CreatePen(0xFF000000, 1)
		Gdip_DrawRectangle(G, pPen, 0, 0, ControlW-1, ControlH-1) 
		Gdip_DeletePen(pPen)	
	}	
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(Handle, HBitmap)	
	Gdip_DeleteBrush(pBrush), Gdip_DeleteBrush(pBrushBackground), Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
	Return
}

;2147483647  - highest priority so if i ever give something else a high priority, this key combo will still interupt (if thread isnt critical)
;#MaxThreadsBuffer on
;<#Space::

g_EmergencyRestart:	
Thread, NoTimers, True
setLowLevelInputHooks(false)	
; if ahk loses track of logical state, can still get stuck keys, which this wont fix
releaseLogicallyStuckKeys(True) 		
settimer, EmergencyInputCountReset, -5000
EmergencyInputCount++		 
If (EmergencyInputCount = 1)
	CreateHotkeys()
else If (EmergencyInputCount >= 3)
{
	IniWrite, Hotkey, %config_file%, Misc Info, RestartMethod ; could have achieved this using running the new program with a parameter then checking %1%
	SoundPlay, %A_Temp%\Windows Ding.wav
	gosub, g_Restart
	return
}
SoundPlay, %A_Temp%\Windows Ding2.wav	
return	

g_reload:
; This is from the menu tray icon, so release the keys in case the user has stuck keys
; and doesn't know about the restart hotkey

; Disabled as releaseLogicallyStuckKeys will do that same thing and if invoked via tray icon, 
; reading the state of the keys from SC will do nothing as SC resets its internal keystate when
; it loses window focus
; Also hopefully all the changes in v3.00 will make stuck keys a thing of the past - they're extremely rare anyway atm. 
releaseLogicallyStuckKeys(True) 
IniWrite, Icon, %config_file%, Misc Info, RestartMethod
g_Restart:
Thread, NoTimers, True
; removing AHKs hooks helps reduce the lock time if the crash issue occurs
; This shouldn't be required anymore as I've fixed the crash on exit issues.
;suspend, on 
setLowLevelInputHooks(False) ; This shouldn't do anything anymore - as they are only installed when required
if (time && alert_array[GameType, "Enabled"])
	aThreads.MiniMap.ahkFunction("doUnitDetection", 0, 0, 0, 0, "Save")	
restartTrainer := True
ExitApp	;does the shutdown procedure.
return 

EmergencyInputCountReset:
	EmergencyInputCount := 0
	Return

; this is required as the 'exit' on the tray icon can only launch labels
; and if it actually goes to " ShutdownProcedure: " the shudown procedure will actaually get run twice! (not a big deal....)
; Once from the label, and a second time due to the first use of ExitApp command 
ExitApp:
	ExitApp ; invokes the shutdown procedure
return 

debugListVars:
	ListVars
	return

; This is useful for aligning various GUI controls
degbugGUIStats:
GuiControlGet, currentText,, %A_GuiControl%
if !instr(currentText, "Off")
{
	GuiControl,, %A_GuiControl%, Off
	settimer, debugGUIStatsTimer, -1
}
else GuiControl,, %A_GuiControl%, Control Pos
return 	

debugGUIStatsTimer:
Gui Options:+LastFound ; set last found for !winExist().
loop 
{
	MouseGetPos, x, y, WinTitle, control, 2
	guicontrolget, output, Options: pos, %control% ; Needs Options: pos if not launched via GUI button
	ToolTip, % outputx ", " outputy A_Tab "x, y" ; x, y
		. "`n" (outputx+outputw) ", " (outputy+outputh) A_Tab "x, y bot right corner" ; Right bottom corner x, y
		. "`n" outputW ", " outputH A_Tab "w, h" ; w, h
	sleep 50
	GuiControlGet, currentText, Options:, degbugGUIVar
} until !WinExist() || !instr(currentText, "Off")
ToolTip 
return

DrawSCUIOverlay:

if !aThreads.Overlays.ahkReady()
{
	launchOverlayThread()
	; if launched from replay or out of game and before thread has been loaded once
	; need to give time for it to load memory addresses to draw the minimap pos
	sleep 500
}
if aThreads.Overlays.ahkFunction("drawUIPositions", 0, 1)
{
	aThreads.Overlays.ahkPostFunction("drawUIPositions", 1)
	GuiControl,, %A_GuiControl%, SC UI Pos
}
else 
{
	aThreads.Overlays.ahkPostFunction("drawUIPositions")
	GuiControl,, %A_GuiControl%, Off
}
return

PerformPatternScan:
Process, exist, %GameExe%
if ErrorLevel
{
	SCPatternScan := new _ClassSCPatternScan() 
	SCPatternScan.listView()
	SCPatternScan := "" ; destroy the object closing the opened process handle
}
else msgbox, , derp, Starcraft needs to be running....., 15
return 

g_GetDebugData:
	clipboard := debugData := DebugData()
	IfWinExist, DebugData Vr: %ProgramVersion%
		WinClose
	Gui, New 
	Gui, Add, Edit, x12 y+10 w980 h640 hwndHwndEdit readonly -E0x200, % LTrim(debugData)
	Gui, Show,, DebugData Vr: %ProgramVersion%
	selectText(HwndEdit, -1) ; Deselect edit box text
return

g_DebugKey:
	IfWinExist, MT Key States Vr: %ProgramVersion%
		WinClose
	Gui, New 
	Gui, Add, Edit, x12 y+10 w250 h250 hwndHwndEdit readonly, % "Currently down keys:`n`n" debugAllKeyStates()
	. "`nLogical refers to the state applications see the key in."
	. "`n`nPhysical refers to the actual physical state which MacroTrainer believes the key is in."
	Gui, Show,, MT Key States Vr: %ProgramVersion%
	selectText(HwndEdit, -1) ; Deselect edit box text
return	

Stealth_Exit:
	ExitApp
	return

g_PlayModifierWarningSound:
	SoundPlay, %A_Temp%\ModifierDown.wav
return

ping:
	if getMiniMapPingIconPos(x, y)
	{
		critical, 1000
		input.pReleaseKeys(True)
		setLowLevelInputHooks(True)
		if isChatOpen()
			input.psend("{click " x ", " y "}{click}{Enter}")
		else input.psend("{click " x ", " y "}{click}")
		Input.revertKeyState()
		setLowLevelInputHooks(False)
	}
Return

g_DoNothing:
Return			

g_LbuttonDown:	;Get the location of a dragbox
	input.setLastLeftClickPos()
return 

g_GiveLocalPlayerResources:
	SetPlayerMinerals()
	SetPlayerGas()
return	

g_GLHF:
	critical, 1000
	setLowLevelInputHooks(True)
	input.pReleaseKeys(True)
	if !isChatOpen()
		input.pSend("+{Enter}")
	input.pSendChars("GL♥HF!")
	input.pSend("{Enter}") ; this wont close the chat box if the alt key is down
	input.revertKeyState()
	setLowLevelInputHooks(False)
return 

; Remove the top left unit in currently displayed selection panel page.
g_DeselectUnit:
if (getSelectionCount() > 1)
{
	ClickUnitPortrait(0, X, Y, Xpage, Ypage) ; -1 as selection index begins at 0 i.e 1st unit at pos 0 top left
	input.pSend("+{Click " x " " y "}")
}
return

; Check != / = "" due to 0 key
isaKeyPhysicallyOrLogicallyDown(Keys)
{
  if isobject(Keys)
  {
    for Index, Key in Keys
      if getkeystate(Key, "P") || getkeystate(Key)
        return key ; This won't work for the 0 key!
  }
  else if getkeystate(Keys, "P") || getkeystate(Keys)
  	return Keys ;keys!
  return 
}

g_FineMouseMove:
	FineMouseMove(A_ThisHotkey)
Return

FineMouseMove(Hotkey, tooltipPos := False)
{
	if (Hotkey = "Left")
		mousemove, -1, 0, 0, R
	else if (Hotkey = "Right")
		mousemove, 1, 0, 0, R
	else if (Hotkey = "Up")
		mousemove, 0, -1, 0, R
	else if (Hotkey = "Down")
		mousemove, 0, 1, 0, R
	if tooltipPos
	{
		MouseGetPos, x, y
		tooltip % x ", " y, x+25, y+25
	}
	return
}

g_FindTestPixelColourMsgbox:
	IfWinExist, Pixel Colour Finder
	{	
		WinActivate
		Return 					
	}
	Gui, New
	Gui +Toolwindow	+AlwaysOnTop
	Gui, Font, S10 CDefault Bold, Verdana
	Gui, Add, Text, x+40 y+10 w220, Colour Finder:
	Gui, Font,
	Gui, Add, Text, x20 y+10, Click " Help "  to learn how to set the pixel colour.
	Gui, Add, Text, x20 Y+10, Click " Start "  to begin.
	Gui, Add, Text, x20 y+10, Click " Cancel "  to leave.
	Gui, Add, Button, Default x30 y+30 w100 h30 default gg_PixelColourFinderHelpFile, &Help
	Gui, Add, Button, Default x+30  w100 h30 gg_FindTestPixelColour, Start
	Gui, Add, Button, Default x+30  w100 h30 gGuiReturn, Cancel
	Gui, Font, Norm 
	gui, show,, Pixel Colour Finder
return

g_PixelColourFinderHelpFile:
	IfWinExist, Pixel Finder - How To:
	{	WinActivate
		Return 					
	}
	Gui, New 
	Gui Add, ActiveX, xm w980 h640 vWB, Shell.Explorer
	WB.Navigate(url.PixelColour)
	Gui, Show,, Pixel Finder - How To:
	sleep, 1500 	; needs 50ms to prevent wb unknown comm error
	try WB.Refresh() 	; So it updates to current changelog (not one in cache)
Return

g_FindTestPixelColour:
	Gui, Destroy
	g_FindTestPixelColour()
Return

g_FindTestPixelColour()
{ 	global AM_MiniMap_PixelColourAlpha, AM_MiniMap_PixelColourRed, AM_MiniMap_PixelColourGreen, AM_MinsiMap_PixelColourBlue
	SoundPlay, %A_Temp%\Windows Ding.wav
	l_DirectionalKeys := "Left,Right,Up,Down"
	loop, parse, l_DirectionalKeys, `,
		hotkey, %A_loopfield%, g_FineMouseMove, on
	loop
	{
		pBitMap := GDIP_BitmapFromScreen()
		MouseGetPos, MX, MY
		FoundColour := GDIP_GetPixel(pbitmap, MX, MY) ;ARGB format
		GDIP_DisposeImage(pBitMap)
		tooltip, % "Found Colour: "  A_Tab FoundColour "`n`nUse the Left/Right/Up/Down Arrows to move the mouse accurately`n`n" A_Tab "Press Enter To Save`n`n" A_Tab "Press Backspace To Cancel", MX+50, MY-70
		if getkeystate("Enter", "P")
		{
			SoundPlay, %A_Temp%\Windows Ding.wav
			Gdip_FromARGB(FoundColour, A, R, G, B)	
			guicontrol, Options:, AM_MiniMap_PixelColourAlpha, %A%
			guicontrol, Options:, AM_MiniMap_PixelColourRed, %R%
			guicontrol, Options:, AM_MiniMap_PixelColourGreen, %G%
			guicontrol, Options:, AM_MinsiMap_PixelColourBlue, %B%
			break
		}
		else if getkeystate("Backspace", "P")
			break
	}
	tooltip
	loop, parse, l_DirectionalKeys, `,
		hotkey, %A_loopfield%, g_FineMouseMove, off
return
}

g_PrevWarning:
	aThreads.MiniMap.ahkPostFunction("announcePreviousUnitWarning")
Return


; Not sure what would happen if this hotkey thread activates while an overlay function
; is drawn. Not sure if changing the priority here is retroActive allowing the interrupted drawing
; thread/routine to (finish and then) interrupt this hotkey and redraw/update size. 
; Never observed the overlays not responding to this.

Adjust_overlay:
autoBuildGameGUI.setDrag(True)
; use sendmessage as it's more reliable 
aThreads.Overlays.AhkAssign.Dragoverlay := Dragoverlay := True
aThreads.Overlays.AhkLabel.overlayTimer
aThreads.Overlays.AhkLabel.unitPanelOverlayTimer
aThreads.Overlays.AhkFunction("increaseOverlayTimer") ; Increase Freq (it will automatically restore to default after 60 seconds)
SoundPlay, %A_Temp%\On.wav
sleep 500
KeyWait, % gethotkeySuffix(AdjustOverlayKey), T40
SoundPlay, %A_Temp%\Off.wav
WinActivate, %GameIdentifier%
WinWaitActive, %GameIdentifier%,, 2 ; wait max 2 seconds
; Bug: 
;	If adjust overlay, then move mouse so that it is no longer on top of an overlay
; 	and release adjust button, overlays (except minimap) will be hidden.
; Fix: 
; Gosub to them so that they save their new positions	
; Destroy and remake them.
; Gosub again so they are redrawn instantly
autoBuildGameGUI.setDrag(False)
aThreads.Overlays.AhkAssign.Dragoverlay := Dragoverlay := False	 
aThreads.Overlays.AhkLabel.overlayTimer
aThreads.Overlays.AhkLabel.unitPanelOverlayTimer
aThreads.Overlays.AhkFunction("DestroyOverlays")
aThreads.Overlays.AhkLabel.overlayTimer
aThreads.Overlays.AhkLabel.unitPanelOverlayTimer
aThreads.Overlays.AhkFunction("restoreOverlayTimer")
Return	

Toggle_Identifier:
aThreads.Overlays.ahkFunction("toggleIdentifier")
OverlayIdent := aThreads.Overlays.ahkgetvar.OverlayIdent
Return


Overlay_Toggle:
	If (A_ThisHotkey = ToggleMinimapOverlayKey "")
	{
		; Disable the minimap, but still draws detected units/non-converted gates
		aThreads.MiniMap.ahkPostFunction("toggleMinimap")
		return	
	}
	else 
	{
		if !aThreads.Overlays.ahkReady()
		{
			launchOverlayThread()
			while !aThreads.Overlays.ahkReady()
				sleep 10
		}
		aThreads.Overlays.ahkFunction("overlayToggle", A_ThisHotkey) ; easiest to wait for function to finish and then update any changed vars
		DrawIncomeOverlay := aThreads.Overlays.ahkgetvar.DrawIncomeOverlay
		DrawResourcesOverlay := aThreads.Overlays.ahkgetvar.DrawResourcesOverlay
		DrawArmySizeOverlay := aThreads.Overlays.ahkgetvar.DrawArmySizeOverlay
		DrawAPMOverlay := aThreads.Overlays.ahkgetvar.DrawAPMOverlay
		DrawUnitOverlay := aThreads.Overlays.ahkgetvar.DrawUnitOverlay
		DrawUnitUpgrades := aThreads.Overlays.ahkgetvar.DrawUnitUpgrades
	}
return 


mt_pause_resume:
	if (mt_Paused := !mt_Paused)
	{
		isInMatch := False ; with this clock = 0 when not in game 
		timeroff("clock", "money", "gas", "scvidle", "supply", "worker", "inject", "Auto_Group", "AutoGroupIdle", "g_autoWorkerProductionCheck", "cast_ForceInject", "auto_inject", "find_races_timer", "advancedInjectTimerFunctionLabel")
		inject_timer := 0	;ie so know inject timer is off
		Try DestroyOverlays()
		aThreads.MiniMap.ahkPause.1
		aThreads.Overlays.ahkPause.1
		aThreads.MiniMap.ahkPostFunction("DestroyOverlays")
		aThreads.Overlays.ahkPostFunction("DestroyOverlays")
		tSpeak("Paused")
	}	
	Else
	{
		settimer, clock, 100
		aThreads.MiniMap.ahkPause.0
		aThreads.Overlays.ahkPause.0
		tSpeak("Resumed")
	}
	keywait, % gethotkeySuffix(warning_toggle_key), T2
return

;------------
;	clock
;------------
clock:
	time := GetTime()
	; Cant jus't check getLocalPlayerNumber() != 16 as it loads too early and lots of memory stuff isn't correct 
	if (!time && isInMatch) || (UpdateTimers) ; time=0 outside game
	{	
		isInMatch := False ; with this clock = 0 when not in game (while in game at 0s clock = 44)	
		timeroff("money", "gas", "scvidle", "supply", "worker", "inject", "Auto_Group", "AutoGroupIdle", "g_autoWorkerProductionCheck", "cast_ForceInject", "auto_inject", "find_races_timer", "advancedInjectTimerFunctionLabel")
		; Don't call these thread functions if just updating settings. 
		; They will be called below. When everything is turned back on.
		; Resetting the unit detections here probably increased the chances of the warning not
		; being resume from the saved version (though this should really happen anyway)
		; I realise it would be a cleaner solution to call the function and pass some 'isUpdating' param
		; but I don't feel like modifying anything and this works fine. Also have to consider
		; when the program restarts during a match.
		if !UpdateTimers ; Game has ended
		{
			if aThreads.MiniMap.ahkReady()
			{
				aThreads.MiniMap.ahkassign.TimeReadRacesSet := 0
				aThreads.MiniMap.ahkFunction("gameChange")
			}
			if aThreads.Overlays.ahkReady()
				aThreads.Overlays.ahkFunction("gameChange")
		}	

		; There is an issue due to shell hook trying to restore the overlay
		; And this function being called in resposne to options GUI settings save/apply
		; If the GUI was visible when leaving SC it will no longer be visible.
		; Not sure of the best/reliable method to prevent this - but its a small issue, and it seems safer - as have to consider 
		; The setBuildObj call which will run in the below else part
		; If user alt tabs back in fast enough (before this function runs) they will see the overlay before it deleted
		autoBuildGameGUI.endGameDestroyOverlay() 

		inject_timer := TimeReadRacesSet := UpdateTimers := PrevWarning := WinNotActiveAtStart := ResumeWarnings := 0 ;ie so know inject timer is off
		isPlaying := EnableAutoWorkerTerran := EnableAutoWorkerProtoss := False ; otherwise if they don't have start enabled they may need to press the hotkey twice to activate
		getAllKeys.aCurrentHotkeys := "" ; Clear the object so next game start the class will retreive the keys again. Safer than solely relying on timer and file modify time
		
		setLowLevelInputHooks(False) ; Shouldn't be required anymore but I'm just gonna leave it anyway
	}
	; > 1,536d or 0600h -> 0.375 ; mischa's reaper bot used this as minimum time. A couple of people reported issues (e.g. auto-worker) - perhaps i wasnt't waiting long enough for game to finish loading
	; since i round to nearest single decimal place, use 0.4
	Else if (time > 0.4 && !isInMatch) && (getLocalPlayerNumber() != 16 || debugGame) ; Local slot = 16 while in lobby/replay - this will stop replay announcements
	{
		isInMatch := true
		AW_MaxWorkersReached := TmpDisableAutoWorker := 0
		aResourceLocations := []
		global aStringTable := []
		global aXelnagas := [] ; global cant come after command expressions
		global MT_CurrentGame := []	; This is a variable which from now on will store
								; Info about the current game for other functions 
								; An easy way to have the info cleared each match
		Global aUnitModel := []
		global aPlayer, aLocalPlayer
		global aEnemyAndLocalPlayer
		global minimap	

		getPlayers(aPlayer, aLocalPlayer, aEnemyAndLocalPlayer)
		GameType := GetGameType(aPlayer)
		If IsInList(aLocalPlayer.Type, "Referee", "Spectator")
			return

		isPlaying := True
		; No longer required but leaving it for now
		setLowLevelInputHooks(False) ; try to remove them first, as can get here from just saving/applying settings in options GUI

		; Just load the minimap and overlay threads unconditionally
		; If they're not used they will not use any CPU once loaded.
		; And saves having to worry about loading/closing them
		; When toggling overlays etc
		if !aThreads.MiniMap.ahkReady()
			launchMiniMapThread()
		else
			aThreads.MiniMap.ahkFunction("gameChange", UserSavedAppliedSettings) ; setting change is for unit detection, to reload saved already warned units
		sleep, -1
		if !aThreads.Overlays.ahkReady()
			launchOverlayThread()
		else aThreads.Overlays.ahkFunction("gameChange")	
		sleep, -1

		SetMiniMap(minimap) ; Used for clicking - not just drawing
		; If I was using the minerals for anything, then if this was called again due to just settings being changed/restart (minerals would have been used up)
		aResourceLocations := getMapInfoMineralsAndGeysers() 
		if WinActive(GameIdentifier)
			ReDrawAPM := ReDrawMiniMap := ReDrawIncome := ReDrawResources := ReDrawArmySize := ReDrawWorker := RedrawUnit := ReDrawIdleWorkers := ReDrawLocalPlayerColour := 1
		if (MaxWindowOnStart && time < 5 && !WinActive(GameIdentifier)) 
		{	
			WinActivate, %GameIdentifier%
			MouseMove A_ScreenWidth/2, A_ScreenHeight/2
			WinNotActiveAtStart := 1
		}
		setupMiniMapUnitLists(aMiniMapUnits)
		l_ActiveDeselectArmy := setupSelectArmyUnits(l_DeselectArmy, aUnitID)
		;ShortRace := substr(LongRace := aLocalPlayer["Race"], 1, 4) ;because i changed the local race var from prot to protoss i.e. short to long - MIGHT NO be needed  now
		setupAutoGroup(aLocalPlayer["Race"], A_AutoGroup, aUnitID, A_UnitGroupSettings)
		findXelnagas(aXelnagas)	

		SC2Keys.getAllKeys()
		disableAllHotkeys()
		CreateHotkeys()	
		if !A_IsCompiled
		{
			Hotkey, If, WinActive(GameIdentifier) && isPlaying
			hotkey, >!g, g_GLHF
			Hotkey, If
		}				

		If (F_Inject_Enable && aLocalPlayer["Race"] = "Zerg")
		{
			zergGetHatcheriesToInject(oHatcheries)
			settimer, cast_ForceInject, %FInjectHatchFrequency%	
		}

		if mineralon
			settimer, money, 500, -5
		if gas_on
			settimer, gas, 1000, -5
		if idleon		;this is the idle worker
			settimer, scvidle, 500, -5	; the idle scv final pointer address changes every game
		if idle_enable	;this is the idle AFK
			settimer, user_idle, 1000, -5

		autoBuild.setBuildObj()
		;LocalPlayerRace := aLocalPlayer["Race"] ; another messy lazy variable but used in a few spots
		;if (EnableAutoWorker%LocalPlayerRace%Start && (aLocalPlayer["Race"] = "Terran" || aLocalPlayer["Race"] = "Protoss") )
		if (EnableAutoWorkerTerranStart && aLocalPlayer["Race"] = "Terran")
		|| (EnableAutoWorkerProtossStart && aLocalPlayer["Race"] = "Protoss")
		{
			if aLocalPlayer["Race"] = "Terran" 
				EnableAutoWorkerTerran := True
			else EnableAutoWorkerProtoss := True			
			SetTimer, g_autoWorkerProductionCheck, 200

			;EnableAutoWorker%LocalPlayerRace% := True
		}
		;if ( Auto_Read_Races AND race_reading ) && !((ResumeWarnings || UserSavedAppliedSettings) && time > 12)
		if (Auto_Read_Races && !ResumeWarnings && !UserSavedAppliedSettings && time <= 12)
			SetTimer, find_races_timer, 1000, -20

		If A_UnitGroupSettings["AutoGroup", aLocalPlayer["Race"], "Enabled"]
		{
			settimer, Auto_Group, %AutoGroupTimer% 						; set to 30 ms via config ini default
																		; WITH Normal 1 priority so it should run once every 30 ms
			settimer, AutoGroupIdle, %AutoGroupTimerIdle%, -9999 		; default ini value 5 ms - Lowest priority so will only run when script is idle! And wont interrupt any other timer
																		; and so wont prevent the minimap or overlay being drawn
																		; note may delay some timers from launching for a fraction of a ms while its in thread, no timers interupt mode (but it takes less than 1 ms to run anyway)
		} 																; Hence with these two timers running autogroup will occur at least once every 30 ms, but generally much more frequently
		UserSavedAppliedSettings := 0
	}
return

setupSelectArmyUnits(l_input, aUnitID)
{
	aUnits := []
	StringReplace, l_input, l_input, %A_Space%, , All ; Remove Spaces
	l_input := Trim(l_input, " `t , |")
	loop, parse, l_input, `,
		l_army .= aUnitID[A_LoopField] ","
	return l_army := Trim(l_army, " `t , |")
}

;-------------------------
;	End of Game 'Setup'
;-------------------------

Cast_ChronoStructure:
Thread, NoTimers, True
for index, object in aAutoChrono["Items"]
{
	; concatenating literal string forces comparison as strings, else 1 = +1 
	; Also check if enabled - as user could have same hotkey for multiple items but one is disabled.
	if ("" object.hotkey = A_ThisHotkey && (object.enabled || object.selectionEnabled))
	{
		MTBlockInput, On
		input.releaseKeys(True) ; don't use postmessage.
		sleep, 60
		Cast_ChronoStructure(aAutoChrono["Items", index, "Units"], aAutoChrono["Items", index, "selectionEnabled"])
		MTBlockInput, Off
		return
	}
}
return

; aStructuresToChrono is an array which keys are the unit types and their values are the chrono order
; lower chrono order is chronoed first
Cast_ChronoStructure(aStructuresToChrono, selectionMode := False)
{	GLOBAL aUnitID, CG_control_group, chrono_key, CG_nexus_Ctrlgroup_key, CG_chrono_remainder, ChronoBoostSleep
	, HumanMouse, HumanMouseTimeLo, HumanMouseTimeHi, NextSubgroupKey

	oStructureToChrono := [], a_gatewaysConvertingToWarpGates := [], a_WarpgatesOnCoolDown := []

	numGetControlGroupObject(oNexusGroup, CG_nexus_Ctrlgroup_key)
	for index, unit in oNexusGroup.units
	{
		if (unit.type = aUnitID.Nexus && !isUnderConstruction(unit.unitIndex))
			nexus_chrono_count += Floor(unit.energy/25)
	}

	IF !nexus_chrono_count
		return
	if !selectionMode
	{
		loop, % DumpUnitMemory(MemDump)
		{
			unit := A_Index - 1
			if isTargetDead(TargetFilter := numgetUnitTargetFilter(MemDump, unit)) || !isOwnerLocal(numgetUnitOwner(MemDump, Unit))
			|| isTargetUnderConstruction(TargetFilter)
		       Continue
	    	if aStructuresToChrono.HasKey(Type := numgetUnitModelType(numgetUnitModelPointer(MemDump, Unit))) && !numgetIsUnitChronoed(MemDump, unit) && numgetIsUnitPowered(MemDump, unit)
	    	{
		    	IF ( type = aUnitID["WarpGate"]) && (cooldown := getWarpGateCooldown(unit))
					a_WarpgatesOnCoolDown.insert({"Unit": unit, "Cooldown": cooldown})
				Else IF (type = aUnitID["Gateway"] && isGatewayConvertingToWarpGate(unit))
						a_gatewaysConvertingToWarpGates.insert(unit) 
				else
				{	
					progress := getBuildStats(unit, QueueSize)	; need && QueueSize as if progress reports 0 when idle it will be added to the list
					if ( (progress < .95 && QueueSize) || QueueSize > 1) ; as queue size of 1 means theres only 1 item in queue being produced
						oStructureToChrono.insert({Unit: unit, QueueSize: QueueSize, progress: progress, userOrder: round(aStructuresToChrono[type])})
				}
	    	}														  
		}	
	}
	else 
	{	
		numGetUnitSelectionObject(aSelection)
		for i, unit in aSelection.Units
		{
			If aLocalPlayer.Slot != unit.owner || isTargetUnderConstruction(getunittargetfilter(unit.UnitIndex))
				continue
			if aStructuresToChrono.HasKey(unit.Type) && !isUnitChronoed(unit.UnitIndex) && isUnitPowered(unit.UnitIndex)
			{
		    	IF (unit.Type = aUnitID["WarpGate"]) && (cooldown := getWarpGateCooldown(unit.UnitIndex))
					a_WarpgatesOnCoolDown.insert({"Unit": unit.UnitIndex, "Cooldown": cooldown})
				Else IF (unit.Type = aUnitID["Gateway"] && isGatewayConvertingToWarpGate(unit.UnitIndex))
					a_gatewaysConvertingToWarpGates.insert(unit.UnitIndex) 
				else
				{	
					progress := getBuildStats(unit.UnitIndex, QueueSize)	; need && QueueSize as if progress reports 0 when idle it will be added to the list
					if ( (progress < .95 && QueueSize) || QueueSize > 1) ; as queue size of 1 means theres only 1 item in queue being produced
						oStructureToChrono.insert({Unit: unit.UnitIndex, QueueSize: QueueSize, progress: progress, userOrder: round(aStructuresToChrono[unit.Type])})
				}				
			}
		}
	}

	if a_WarpgatesOnCoolDown.MaxIndex()
		bubbleSort2DArray(a_WarpgatesOnCoolDown, "Cooldown", 0)	;so warpgates with longest cooldown get chronoed first
	if a_gatewaysConvertingToWarpGates.MaxIndex()	
		RandomiseArray(a_gatewaysConvertingToWarpGates)

	; The 51 for QueueSize ensures that warpgates are chronoed before converting gateways when user presses the chrono warpgates/gateway key
	for index, Warpgate in a_WarpgatesOnCoolDown 			
		oStructureToChrono.insert({Unit: Warpgate.Unit, QueueSize: 51, progress: 1, userOrder: round(aStructuresToChrono[aUnitID.WarpGate])})	; among warpgates longest cooldown gets done first
	; The 50 for QueueSize ensures that converting gateways are chronoed before producing gateways when user presses the chrono warpgates/gateway key
	for index, unit in a_gatewaysConvertingToWarpGates
		oStructureToChrono.insert({Unit: unit, QueueSize: 50, progress: 1, userOrder: round(aStructuresToChrono[aUnitID.Gateway])}) 	; among these gateways, order is random

	bubbleSort2DArray(oStructureToChrono, "progress", 1) ; so the strucutes with least progress gets chronoed (providing have same queue size)
	bubbleSort2DArray(oStructureToChrono, "QueueSize", 0) ; so One with the longest queue gets chronoed first
	bubbleSort2DArray(oStructureToChrono, "userOrder", 1) ; So lower priority Number gets chronoed first
	If !oStructureToChrono.maxIndex()
		return
	
	MouseGetPos, start_x, start_y
	HighlightedGroup := getSelectionHighlightedGroup()
	selectionPage := getUnitSelectionPage()
	max_chronod := nexus_chrono_count - CG_chrono_remainder
	input.pSend((CG_control_group != "Off" ? aAGHotkeys.set[CG_control_group] : "") aAGHotkeys.Invoke[CG_nexus_Ctrlgroup_key])
	timerID := stopwatch()
	sleep, 30 	; Can use real sleep here as not a silent automation
	for  index, object in oStructureToChrono
	{
		If (A_index > max_chronod)
			Break
		sleep, %ChronoBoostSleep%
		getUnitMinimapPos(object.unit, click_x, click_y)
		input.pSend(chrono_key)
		If HumanMouse
			MouseMoveHumanSC2("x" click_x "y" click_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
		Input.pClick(click_x, click_y)
	}
	If HumanMouse
		MouseMoveHumanSC2("x" start_x "y" start_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
	elapsedTimeGrouping := stopwatch(timerID)	
	if (elapsedTimeGrouping < 20)
		sleep, % ceil(20 - elapsedTimeGrouping)	
	if (CG_control_group != "Off")
		restoreSelection(CG_control_group, selectionPage, HighlightedGroup)
	Return 
}

resumeAutoGroup:
settimer, AutoGroupIdle, On, -9999 ;on re-enables timers with previous period
settimer, Auto_Group, On		
return 

AutoGroupIdle:
Auto_Group:
	AutoGroup(A_AutoGroup)
	Return

; 8 units / full selection card
; 0.25 / 1.50
; Old 0.14 /1.56

AutoGroup(byref A_AutoGroup)
{ 	global GameIdentifier, aButtons, AGBufferDelay, AGKeyReleaseDelay, aAGHotkeys

	; needed to ensure the function running again while it is still running
	;  as can arrive here from AutoGroupIdle or Auto_Group
	Thread, NoTimers, true

	; If user presses hotkey during this time (which would still interrupt this thread), it should not defeat the
	; two unit checks - even if the selection changes
	; as they will no longer match
	; I guess it would be possible if the unit died between type and isincontrolGroup
	; and the new different unit with same index was selected - but this be very very rare

	numGetUnitSelectionObject(oSelection)
	for index, Unit in oSelection.Units
	{		
		If (aLocalPlayer.Slot != unit.owner)
			return 
		type := unit.type, CurrentlySelected .= "," unit.UnitIndex
		if !activeList
		{
			For Player_Ctrl_Group, ID_List in A_AutoGroup	;check the array - player_ctrl_group = key 1,2,3 etc, ID_List is the value
			{
				if type in %ID_List%
				{
					activeList := ID_List, activeGroup := Player_Ctrl_Group	
					break		
				}				
			}
			if !activeList ; unit isnt in one of the lists
				return 
		}
		if type not in %activeList%
			return 
		else if (controlGroup = "" && !isInControlGroup(activeGroup, unit.unitIndex))
			controlGroup := activeGroup
	}

	if (controlGroup != "") && WinActive(GameIdentifier) && !isGamePaused() ; note != "" as there is group 0!
	&& !isMenuOpen() && A_mtTimeIdle >= AGKeyReleaseDelay 
	&& !(getkeystate("Shift", "P") && getkeystate("Control", "P") && getkeystate("Alt", "P")
	&& getkeystate("LWin", "P") && getkeystate("RWin", "P"))
	&& !readModifierState() 
	{			
		critical, 1000
		setLowLevelInputHooks(True)
		input.pReleaseKeys(True)
		dSleep(AGBufferDelay)
		numGetUnitSelectionObject(oSelection)
		for index, Unit in oSelection.Units
			PostDelaySelected .= "," unit.UnitIndex

		if (CurrentlySelected = PostDelaySelected)
		{
			input.pSend(aAGHotkeys.Add[controlGroup])
			settimer, AutoGroupIdle, Off
			settimer, Auto_Group, Off
			SetTimer, resumeAutoGroup, -85
			; Need to sleep for a while, as slow computers+lag can cause grouping command
			; to be issued twice causing the camera to move. 
		}
		Input.revertKeyState()
		setLowLevelInputHooks(False)
		critical, off
	}
	Return
}
; This was a relatively simple function. But someone wanted multiple control groups for each unit
; 

AutoGroupNewTesting(byref A_AutoGroup)
{ 	global GameIdentifier, aButtons, AGBufferDelay, AGKeyReleaseDelay, aAGHotkeys

	; needed to ensure the function running again while it is still running
	;  as can arrive here from AutoGroupIdle or 
	Thread, NoTimers, true
	aGroupUnits := [], aGroupUnits.Items := [], aGroupUnits.Types := [], aAttemptTypes := []
	; If user presses hotkey during this time (which would still interrupt this thread), it should not defeat the
	; two unit checks - even if the selection changes
	; as they will no longer match
	; I guess it would be possible if the unit died between type and isincontrolGroup
	; and the new different unit with same index was selected - but this be very very rare

	numGetUnitSelectionObject(oSelection)
    for index, unit in oSelection.Units
    {
        If (aLocalPlayer.Slot != Unit.owner)
           return
        CurrentlySelected .= "," unit.UnitIndex
        if !A_AutoGroup.Units.HasKey(unit.type)
            return ;"No group for this unit"
        ; If unit type not already queued to be grouped       
        if !aAttemptTypes.HasKey(unit.type) 
        {
            for group, in A_AutoGroup.Units[unit.type]
            {
                if !isInControlGroup(group, unit.UnitIndex)
                {
                	if !isObject(aAttemptTypes[unit.type])
                		aAttemptTypes[unit.type] := []
                    aAttemptTypes[unit.type, group] := unit.UnitIndex
                }
                s .= (A_Index != 1 ? "," : "") group  ; create a comma delimited string of the destined ctrl groups for comparison
            }
            ; aGroupUnits.Items Is used to check for control group mismatches (the same groups must exist in all items)
            ; I.e. stalker group 1,2  and sentry group 2,3 = then units only added to group 2
            ; Since being inserted into the object must check if type has already processed
            ; otherwise will get repeated control groups in the grouping string
            if !aGroupUnits.Types.HasKey(unit.type)
                aGroupUnits.Items.Insert(s), aGroupUnits.Types[unit.type] := True
            s := "" 
        }        
    }

 	if !aAttemptTypes.MaxIndex() || !aGroupUnits.Items.MaxIndex()
        return 	;!aAttemptTypes.MaxIndex()  ? "Already grouped" : "No units to group" 
    if aGroupUnits.Items.MaxIndex() = 1
        groupString := aGroupUnits.Items.1
    else 
    {
/*
    aGroupUnits.Items contains destined control groups for each selected unit type (which has defined auto-group control group(s))
    Find the groups which are common to all of these unit types
    If no common groups, then abort 
    E.G.                Example1    Example2        Example3
        Items.1         1           1,3             1,2
        Items.2         1,2         1,3,4,5         2,3
        Items.3         1,2,3       1,2,3           5,6
        Result          = 1         = 1,3           = null
        (groupString = Result)

    Although this adds more code than the old method (which didn't support multiple groups)
    There will only be a handful on items in this list, and there will only be a couple of destined groups 
    (99% of time just 1) for each item
*/
        group1 := aGroupUnits.Items.1
        loop, parse, group1, `,
        {
            ; A_LoopField = the individual ctrl group numbers of the destined ctrl group string in items.1 e.g. 1 or 2 or 3 etc
            Loop, % aGroupUnits.Items.MaxIndex() - 1
            {
                nextGroupString := aGroupUnits.Items[A_Index+1] ;Start at 2 as comparing to groups in 1
                if A_LoopField in %nextGroupString%
                    flag := true 
                else 
                    flag := false                     
            } until !flag ; no point checking the other items as this group is not common to all and so wont be sent
            if flag
            {
                if A_LoopField not in %groupString%
                    groupString .= (groupString ? "," : "") A_LoopField
            }
        }
	    ; Non-common ctrl groups have been removed. It's now possible that all the units already exist in the remaining common group.
	    ; As the group which doesn't contain one of the units has been removed
	    ; So check that at least one of them doesn't exist in the common group - otherwise it will get continually spammed
	    flag := False
	    loop, parse, groupString, `, 
	    {
	    	for type, object in aAttemptTypes
	    	{
	    		if object.HasKey(A_LoopField) ; A_LoopField = ctrl Group
	    		{
					flag := True
					break
	    		}
	    	}
	    }
	   	if !flag 
	   		return
   	}
   	if (groupString = "")
		return ;"No common control group for units"

   	;*/ 
	if oSelection.Count && WinActive(GameIdentifier) && !isGamePaused() ; note <> "" as there is group 0! cant use " controlGroup "
	&& !isMenuOpen() && A_mtTimeIdle >= AGKeyReleaseDelay 
	&& !(getkeystate("Shift", "P") && getkeystate("Control", "P") && getkeystate("Alt", "P")
	&& getkeystate("LWin", "P") && getkeystate("RWin", "P"))
	&& !readModifierState() 
	{			
		critical, 1000
		setLowLevelInputHooks(True)
		input.pReleaseKeys(True)
		dSleep(AGBufferDelay)
		numGetUnitSelectionObject(oSelection)
		for index, Unit in oSelection.Units
			PostDelaySelected .= "," unit.UnitIndex

		if (CurrentlySelected = PostDelaySelected)
		{
			loop, parse, groupString, `, 
				sendString .= aAGHotkeys.Add[A_LoopField]
			input.pSend(sendString)
			; Turn off for slow computers/lag otherwise may send again and cause camera to jump before the buffer is updated
			settimer, AutoGroupIdle, Off
			settimer, Auto_Group, Off
			SetTimer, resumeAutoGroup, -85
			soundplay *-1
		}
		Input.revertKeyState()
		setLowLevelInputHooks(False)
		critical, off
	}
	Return
}
   
g_LimitGrouping:
	LimitGroup(A_AutoGroup, A_ThisHotkey)
Return

LimitGroup(byref UnitList, Hotkey)
{ 
	global aAGHotkeys, AGRestrictBufferDelay
	; CtrlList := "" ;if unit type not in listt add to it - give count of list type
	critical 1000
	setLowLevelInputHooks(True)
	for group, addhotkey in aAGHotkeys.Add
	{
		if (Hotkey = addhotkey "")
		{
			found := True 
			break 
		}	
	}
	if !found 
	{
		for group, addhotkey in aAGHotkeys.Set
		{
			if (Hotkey = addhotkey "")
			{
				found := True 
				break 
			}	
		}
	}

	if found 
	{
		dsleep(AGRestrictBufferDelay)
		If (ID_List := UnitList[group]) ; ie not blank
		{
			loop, % getSelectionCount()		;loop thru the units in the selection buffer
			{
				type := getUnitType(getSelectedUnitIndex(A_Index - 1)) 					;note no -1 (as ctrl index starts at 0)
				if type NOT in %ID_List%
				{
					setLowLevelInputHooks(False)
					Return
				}
			}
		}
	}
	;input.hookBlock(True, True)
	;sleep := Input.releaseKeys()
	;critical 1000
	;input.hookBlock(False, False)
	;if sleep
	;	dSleep(10) 
	
	input.pReleaseKeys(True)
	input.pSend(Hotkey)
	Input.revertKeyState()
	setLowLevelInputHooks(False)
	Return
}	

inject_start:
	if inject_timer
	{
		inject_timer := !inject_timer
		settimer, inject, off
		tSpeak("Inject off")
	}
	else
	{
		inject_set := time
		inject_timer := !inject_timer
		settimer, inject, 250
		tSpeak("Inject on")
	}
	return

inject_reset:
	inject_set := time
	settimer, inject, off
	settimer, inject, 250
	inject_timer := 1
	tSpeak("Reset")
	return

Cast_DisableInject:	
	If (F_Inject_Enable := !F_Inject_Enable)
	{
		tSpeak("Injects On")
		zergGetHatcheriesToInject(oHatcheries)
		settimer, cast_ForceInject, %FInjectHatchFrequency%	
	}
	Else
	{
		settimer, cast_ForceInject, off
		tSpeak("Injects Off")
	}
	Return

;	5/9/13
;	Now using postMessage to send clicks. Note, not going to block or revert key states for the user invoked
;	one-button inject. As Users may have really high internal sleep times which could cause the installed hooks to 
; 	be removed by windows. Also, since the user is invoking this action, they shouldnt be pressing any other keys anyway.
;	also using AHK internal sleep for this function.
; 	the blocking hook allows keyups to pass through anyway so dont have to worry about stuck keys outside windows

cast_inject:
	If (isGamePaused() || isMenuOpen())
		return ;as let the timer continue to check during auto injects
		;menu is always 1 regardless if chat is up
		;chat is 0 when  menu is in focus
	Thread, NoTimers, true  ;cant use critical with input buffer, as prevents hotkey threads launching and hence tracking input				
	MouseGetPos, start_x, start_y
	;input.hookBlock(True, True)
	MTBlockInput, On
	if input.releaseKeys(True)
		sleep 60
	else sleep 40
	castInjectLarva(auto_inject, 0, auto_inject_sleep) ;ie nomral injectmethod
	If HumanMouse
		MouseMoveHumanSC2("x" start_x "y" start_y "t" HumanMouseTimeLo)
	;input.hookBlock()
	MTBlockInput, Off
	Thread, NoTimers, false
	inject_set := getTime()  
	if auto_inject_alert
		settimer, auto_inject, 250
	If GetKeyState(gethotkeySuffix(cast_inject_key), "P")   ; The line below should now be fixed due to changes in hook/AHK source code.
		KeyWait, % gethotkeySuffix(cast_inject_key), T.3	; have to have this short, as sometimes the script sees this key as down when its NOT and so waits for the entire time for it to be let go - so if a user presses  this key multiple times to inject (as hatches arent ready) some of those presses will be ingnored
Return


cast_ForceInject:
	if !F_Inject_Enable
	{
		settimer, cast_ForceInject, off	
		return 
	}
	;For Index, CurrentHatch in oHatcheries
	;	if (CurrentHatch.NearbyQueen && !isHatchInjected(CurrentHatch.Unit)) ;probably should check if hatch is alive and still a hatch...

	If getGroupedQueensWhichCanInject(aControlGroup, 1) ; 1 so it checks their movestate
	{
		; Need this otherwise if all hatcheries get killed injects stop until user toggles auto inject on/off
		; Check every ten seconds so it's a bit quicker than the 35 second check
		; since zergGetHatcheriesToInject() is called on match start (when autoinjects are enabled) and when toggling the function 
		; don't need to worry about MT_CurrentGame.LastHatchCheckTick being null
		IF !oHatcheries.MaxIndex() && A_TickCount - MT_CurrentGame.LastHatchCheckTick >= 10000
			zergGetHatcheriesToInject(oHatcheries)
		; Use 35 seconds as it will be > the 29 real seconds per inject  - so the unit list isn't iterated twice when injects occur or every time this routine runs.
		; So no hatch should remain uninjected for more than 2 inject rounds (~1.3)
		else if (A_TickCount - MT_CurrentGame.LastHatchCheckTick >= 35000) 
			zergGetHatcheriesToInject(oHatcheries)
		; Note oHatcheries is updated each time castInjectLarva() is called.
		; This should be adequate to ensure that new hatches are added, and (with the above !MaxIndex() check) there are always hatches in this list for the below check
		; to determine when to call castInjectLarva() again. Of course some situations may slightly delay the injects but this small trade off is better than constantly iterating the unit array
		; e.g. There is 1 hatch and a new one just finished, but the user injects the old one manually. The new one will not be injected until 
		; The next time castInjectLarva() is called to inject the first hatch (which is in oHatcheries)
		; However i suppose late game with auto-injects and max 200/200 army and not trading then it's possible the list won't be updated for some time (or in the above scenario if the user keeps injecting that first hatch manually)
		; and if make a new hatch with a queen, then this hatch won't get injected. 
		; I've added the MT_CurrentGame.LastHatchCheckTick last check count to account for these situations
		For Index, CurrentHatch in oHatcheries
		{
			For Index, Queen in aControlGroup.Queens
			{
				; call isHatchInjected and getTownHallLarvaCount. As the hatch object will contain old information
				if isQueenNearHatch(Queen, CurrentHatch, MI_QueenDistance) && Queen.Energy >= 25 && !isHatchInjected(CurrentHatch.Unit)
				&& (!InjectConserveQueenEnergy || round(getTownHallLarvaCount(CurrentHatch.Unit)) < 19) 
				{
					Thread, Priority, -2147483648
					sleep % rand(0, 2000)
					Thread, Priority, 0	
					startInjectWait := A_TickCount
				;	while getkeystate("LWin", "P") || getkeystate("RWin", "P")	
				;	|| getkeystate("LWin") || getkeystate("RWin")	
				;	|| getkeystate("LButton", "P") || getkeystate("RButton", "P")
				;	|| getkeystate("LButton") || getkeystate("RButton")
				;	|| getkeystate("Shift") || getkeystate("Ctrl") || getkeystate("Alt")
				;	|| getkeystate("Shift", "P") || getkeystate("Ctrl", "P") || getkeystate("Alt", "P")	
				;	|| getkeystate("Enter") ; required so chat box doesnt get reopened when user presses enter to close the chatbox
				;	|| isUserPerformingAction()
				;	|| MT_InputIdleTime() < 50  ;probably best to leave this in, as every now and then the next command wont be shift modified
				;	|| getPlayerCurrentAPM() > FInjectAPMProtection
				
					While getkeystate("Enter", "P") || GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
					|| getkeystate("Tab", "P") 
					|| isUserBusyBuilding() || isCastingReticleActive() 
					|| getPlayerCurrentAPM() > FInjectAPMProtection
					||  A_mtTimeIdle < 70
					{
						if (A_TickCount - startInjectWait > 1000)
							return
						Thread, Priority, -2147483648
						sleep 1
						Thread, Priority, 0	
					}
					if (!WinActive(GameIdentifier) || isGamePaused() || isMenuOpen() || !isSelectionGroupable(oSelection)) 
						return
					critical 1000
					setLowLevelInputHooks(True)
					input.pReleaseKeys(True)
					dSleep(40)  ; give 10 ms to allow for selection buffer to fully update so we are extra safe. 
					if isSelectionGroupable(oSelection) ; in case it somehow changed/updated 
						castInjectLarva("MiniMap", 1, 0)
					Input.revertKeyState()	
					setLowLevelInputHooks(False)					
					return
				}
			}
		}
	}
	return

 


PixelSearch(Colour, byref X, byref Y,variance=0, X_Margin=6, Y_Margin=6)
{	;supply the approx location via X & Y. Then pixel is returned
	pBitMap := GDIP_BitmapFromScreen()		;im not sure if i have to worry about converting coord mode here
	Gdip_FromARGB(Colour, A, R, G, B)		;i dont belive so, as it should all be relative
	X_Max := X+X_Margin, Y_Max := Y+Y_Margin
	while ((X := X-X_Margin+A_Index-1) <= X_Max)
		while ((Y := Y-Y_Margin+A_Index-1) <= Y_Max)			
			if	((found := !Gdip_FromARGB(GDIP_GetPixel(pbitmap, X, Y), FA, FR, FG, FB) ;Gdip_FromARGB doesnt return a value hence !
			&& (FA >= A - A*variance && FA <= A + A*variance)
			&& (FR >= R - R*variance && FR <= R + R*variance)
			&& (FG >= G - G*variance && FG <= G + G*variance)
			&& (FB >= B - B*variance && FB <= B + B*variance)))
				break, 2
	GDIP_DisposeImage(pBitMap)
	if found
		return 1
	else return 0
}



;----------------------
;	races
;-----------------------
find_races_timer:
If (time < 8)
	Return
SetTimer, find_races_timer, off		

find_races:
if time	;leave this in, so if they press the hotkey while outside of game, wont get gibberish
{
	tSpeak(GetEnemyRaces())
	If (A_ThisLabel = "find_races")
	{
		aThreads.MiniMap.ahkassign.TimeReadRacesSet := time	
		keywait, % gethotkeySuffix(read_races_key), T2
	}
}
return

;--------------------------------------------
;    Minerals -------------
;--------------------------------------------
money:
	if (mineraltrigger <= getPlayerMinerals())
	{
			if (Mineral_i <= sec_mineral)	; sec_mineral sets how many times the alert should be read
			{
				tSpeak(w_mineral)
				settimer, money, % additional_delay_minerals *1000	; will give the second warning after additional seconds
			}
			else 	; this ensures follow up warnings are not delayed by waiting for additional seconds before running timmer
				settimer, money, 500
			Mineral_i++
	}
	else
	{
		Mineral_i = 0
		settimer, money, 500
	}
return

;--------------------------------------------
;    Gas -------------
;--------------------------------------------
gas:	
	if (gas_trigger <= getPlayerGas())
	{
			if (Gas_i <= sec_gas)	; sec_mineral sets how many times the alert should be read
			{
				tSpeak(w_gas)
				settimer, gas, % additional_delay_gas *1000	; will give the second warning after additional seconds
			}
			if (Gas_i >= sec_gas )
				settimer, gas, 1000
			Gas_i++
	}
	else
	{
		Gas_i = 0
		settimer, gas, 1000
	}
return				


;-------
; scv idle
;-------

scvidle:
	if ( time < 5 ) OR ("Fail" = idle_count := getIdleWorkers())
		return
	if ( idle_count >= idletrigger )
	{
		if (Idle_i <= sec_idle )
		{
			tSpeak(w_idle)
			settimer, scvidle, % additional_idle_workers *1000
		}
		Else
			settimer, scvidle, 500
		Idle_i++
	}
	else
	{
		Idle_i = 0
		settimer, scvidle, 500
	}
	return

;------------
;	Inject	Timers
;------------
inject:
	if ( time - inject_set >= manual_inject_time )		;for manual dumb inject alarm  (i.e. dings every X seconds)
	{
		inject_timer := 1
		inject_set := time

		If W_inject_ding_on
			SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
		If W_inject_speech_on
			tSpeak(w_inject_spoken)	
	}		
	return

; This is for the One-Button Injects (not the fully automated injects)

auto_inject:
	if ( time - inject_set >= auto_inject_time ) && (!F_Inject_Enable)
	{
		settimer, auto_inject, off
		If W_inject_ding_on
			loop, 2
			{
				SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
				sleep 150
			}	
		If W_inject_speech_on
			tSpeak(w_inject_spoken)
	}
	return

Return

g_InjectTimerAdvanced:
advancedInjectTimer()
return 

advancedInjectTimer()
{
	global injectTimerAdvancedTime, W_inject_ding_on, W_inject_speech_on, w_inject_spoken
	static injectTime 

	; when tapping the mouse button (while hand off the mouse in order to click for the least possible time) 
	; the lowest I could get for time spent with the button down was 32 ms (did get one 22ms but couldnt repeat it and that one was with
	; A_Tickcount not QPX, so could have been a granularity/resolution thing)
	; clicking normally its around 70 100 ms
								
	numGetSelectionSorted(aSelection)
	if (aSelection.IsGroupable && aSelection.HighlightedId = aUnitID.Queen)
	{
		prevSelections := aSelection.IndicesString
		loopTick := A_Tickcount
		loop 
		{
			if getkeystate("Lbutton", "P")
			{
				; possible for the user to not click on the hatch miss or click menu/friends/options (which would arrive here) or , then to hit esc or rbutton to cancel 
				; but this loop will then either time out or catch the next inject, so it doesn't really matter.

				lButtonTick := A_Tickcount
				; If inject against Ai the below loop finds the larva command after ~15/30 OS_Ticks and on the second loop
				; For a queen which is right next to a hatch, she will have the 'spawnLarva' ability queued for ~1670 ms! 
				; Hence heaps of time for a loop to catch it even with generous sleeps
				loop 
				{
					for i, unit in aSelection.units 
					{
						if (unit.unitID = aUnitID.Queen)
						{
							if instr(getUnitQueuedCommandString(unit.unitIndex), "SpawnLarva")
							{
								injectTime := getTime()
								settimer, advancedInjectTimerFunctionLabel, 1000	
								return				
							}
						}
					}

					Thread, Priority, -2147483648
					sleep 200
					Thread, Priority, 0
					if (A_Tickcount - lButtonTick > 5000)
						return
				}
			}
			else if (getkeystate("Esc") || getkeystate("RButton"))
				return 
			else if (A_Tickcount - loopTick > 3000)
			{
				loopTick := A_Tickcount
				numGetSelectionSorted(aSelection)
				if (!aSelection.IsGroupable || aSelection.HighlightedId != aUnitID.Queen || prevSelections != aSelection.IndicesString)
					return
			}
			Thread, Priority, -2147483648
			sleep 1
			Thread, Priority, 0
		}

	}
	return 

	; I was going put this outside as these commands take a few ms, so it might be possible for function call for a new inject to fail
	; as its waiting for the sound section to finish
	; after other testing, if a function call arrives while a timer inside the function is running the timer will be interrupted! 
	; so its fine to have it here (though it wouldnt really matter either way)

	advancedInjectTimerFunctionLabel:
	if (getTime() >= injectTime + InjectTimerAdvancedTime)
	{
		settimer, %A_ThisLabel%, off 
		If W_inject_ding_on
		{
			loop, 2
			{
				SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
				sleep 150
			}	
		}
		If W_inject_speech_on
			tSpeak(w_inject_spoken)
	}
	return 

}


;----------------
;	User Idle
;----------------
user_idle:
; If only one hook is installed, only its type of physical input affects A_TimeIdlePhysical (the other/non-installed hook's input, both physical and artificial, has no effect).
	time := getTime()
	If ( time > UserIdle_LoLimit AND time < UserIdle_HiLimit) AND  (A_TimeIdlePhysical > idle_time *1000)	;
	{	
		settimer, user_idle, off
		pause_check := getTime()
		sleep, 500			
		if ( pause_check = getTime())
			return	; the game is already paused		
		send, +{enter}%chat_text%{enter} 
		Send, %pause_game%
	}
	Else If ( time > UserIdle_HiLimit )
		settimer, user_idle, off	
return

;------------
;	Worker Count
;------------
worker_count:
	worker_origin := A_ThisHotkey ; so a_hotkey not changed via thread interruption
	IF 	( !time ) ; ie = 0 
	{
		tSpeak("The game has not started")
		keywait, % gethotkeySuffix(worker_origin), T2
		return
	}
	If ( worker_origin = worker_count_enemy_key "")
	{
		if ( GameType <> "1v1" )
		{
			tSpeak("Enemy worker count is only available in 1v1")
			keywait, % gethotkeySuffix(worker_origin), T2
			return
		}	
		For slot_number in aPlayer
		{
			If ( aLocalPlayer["Team"] <> aPlayer[slot_number, "Team"] )
			{
				playernumber := slot_number	
				player_race := aPlayer[slot_number, "Race"]
				Break
			}
		}
	}
	Else
	{
		playernumber := aLocalPlayer["Slot"]
		player_race := 	aLocalPlayer["Race"]
	}
	if ( "Fail" = newcount := getPlayerWorkerCount(playernumber))
	{
		tSpeak("Try Again in a few seconds")
		keywait, % gethotkeySuffix(worker_origin), T2
		return
	}
	Else If ( player_race = "Terran" )
		tSpeak(newcount "SCVs")
	Else If ( player_race = "Protoss" )
		tSpeak(newcount "Probes")
	Else If ( player_race = "Zerg" )
		tSpeak(newcount "Drones")
	Else 
		tSpeak(newcount "Workers")
	keywait, % gethotkeySuffix(worker_origin), T2
return	

; used to monitor the activation/min of the sc2 window
; Also for removing and reinstalling hooks
; for drawing overlays (rather than a timer)
; lParam is the sc2 hWnd
; 4 params are passed if you add more params to shell message definition
; but i dont know what these are.
ShellMessage(wParam, lParam) 
{
	Global
	Static ReDrawOverlays
	; destroy/recreate overlays incase user has low refresh rates (take long time for them to appear/disappear)
	; Not such a big issue for the minimap, as everyone would be using a fast refresh rate for that
	if (wParam = 32772 || wParam = 4) ;  HSHELL_WINDOWACTIVATED := 4 or 32772
	{
		; There's a narrow time window here where you can get inva

		if (SC2hWnd != lParam && !ReDrawOverlays && !Dragoverlay)
		{
			ReDrawOverlays  := True
			autoBuildGameGUI.starcraftLostFocus()
			aThreads.Overlays.AhkFunction("DestroyOverlays")
		}
		else if (SC2hWnd = lParam && getTime() && isInMatch)
		{
			;mt_Paused otherwise will redisplay the hidden and frozen overlays
			if (ReDrawOverlays && !mt_Paused && !IsInList(aLocalPlayer.Type, "Referee", "Spectator")) ; This will redraw immediately - but this isn't needed at all
			{  	
				autoBuildGameGUI.starcraftGainedFocus()
				; If the overlay is called before it finishes reading the iniFile could get a GUI show error
				; due to the x and y values being NULL.
				; This is extremely small window (even when setting the function to always draw i.e. if True 
				; it was still very difficult to induce) as to draw the overlay the overlay thread would have need to have read the
				; enable/draw variable but not the closely placed x, y variable.
				; But better to be safe so call gosubAllOverlays which checks if the ini file has been read fully.

				aThreads.Overlays.AhkLabel.gosubAllOverlays ; does the overlayTimer and unitPanel
				;aThreads.Overlays.AhkLabel.overlayTimer
				;aThreads.Overlays.AhkLabel.unitPanelOverlayTimer
				ReDrawOverlays := False
			}
		}
	}
	return
}

; This will temporarily disable the minimap, but still draw detected units/non-converted gates
g_HideMiniMap:
aThreads.MiniMap.ahkPostFunction("temporarilyHideMinimap")
return

gEasyUnloadDescription:
msgbox,, Easy Unload/Select,
		(LTrim 
		This page has two separate hotkeys which perform three different tasks.

		Unload All:
		If enabled, when you double tap the SC2 unload all key (default is 'd') and transports containing units are the highlighted subgroup, then all of the transports will begin unloading. 

		====================================================

		Easy Select/Cursor Unload:
		If enabled, then the 'Easy Select/Cursor Unload' hotkey will perform one of two functions depending on if it is double tapped or held down.
		
		1) When double tapped this hotkey will select all loaded transports visible on the screen.
		(Ensure the mouse is not hovering above a transport, otherwise it may begin unloading)

		2) When the hotkey is held down the unloading mode will be invoked. Simply wave the mouse cursor over the loaded transports to begin unloading them.
		
		Note: This mouse cursor unloading method is less reliable than the 'Unload All' method, particularly  when the transports are stacked or the mouse is moved very fast.
		)
return 

gYoutubeEasyUnload:
run http://youtu.be/D11tsrjPUTU
return

Homepage:
run % url.homepage
return

gUnitPanelGuide:
run % url.Overlays
return

;------------
;	Exit
;------------                                            

timer_Exit:
if !WinExist(GameIdentifier) ; This is much faster (0.05 ms vs 0.75 ms) than calling proccess, exist
	ExitApp
return

ShutdownProcedure:
debugShutdown ? log("`n`n==================`n" A_hour ":" A_Min ":" A_Sec "`nPerforming Shutdown Procedure") : ""
	;changeScriptMainWinTitle(A_ScriptFullPath " - AutoHotkey v" A_AhkVersion)
	if FileExist(config_file) ; needed if exits due to dll/other-files not being installed
		Iniwrite, % round(GetProgramWaveVolume()), %config_file%, Volume, program	

	setLowLevelInputHooks(False) ; Probably already removed (but the functions internal check allows it be called again)
	ReadMemory()
	ReadRawMemory()
	ReadMemory_Str()
	
debugShutdown ? log("Closing speech thread") : ""
	;aThreads.miniMap.ahkLabel.ShutdownProcedure

	; ahkTerminate is causing issues - I've probably done something wrong
	; so just call the minimap ShutdownProcedure manually (don't really need to do this
	; anyway) and let the threads close when the this process closes
	if aThreads.Speech.ahkReady() 	; if exists
	{
		aThreads.Speech.ahkLabel.clearSAPI
		aThreads.Speech.ahkTerminate() 
	}
debugShutdown ? log("Closing minimap thread") : ""
	if aThreads.miniMap.ahkReady() 	
		aThreads.miniMap.ahkTerminate() 
debugShutdown ? log("Closing overlay thread") : ""
	if aThreads.Overlays.ahkReady() 	
		aThreads.Overlays.ahkTerminate() 	
debugShutdown ? log("Deleting bitmaps") : ""
	deletepBitMaps(a_pBitmap)
	;deletePens(a_pPens)
	;deleteBrushArray(a_pBrushes)

	; Should only be called once from either thread
	; GDI_Unload crash was probably due to calling this function, then having another thread try 
	; to access the GDI library to draw
	; so close GDIP after closing minimapThread

debugShutdown ? log("Shutting down gdip") : ""
	if pToken
		Gdip_Shutdown(pToken) 
	; I thought placing this here after most of the shutdown stuff would
	; help the restart spam issue - but it hasn't :(
	if (restartTrainer && A_OSVersion = "WIN_XP") ; apparently the below command wont work on XP
		try RunAsAdmin()
	else if restartTrainer
		try  Run *RunAs "%A_ScriptFullPath%"
debugShutdown ?	log("exiting.`n`n`n") : ""
	ExitApp
Return

;------------
;	Updates
;------------

GuiReturn:
	Gui Destroy
	Return 

GuiClose:
GuiEscape:
	Gui, Options:-Disabled ; as the colour selector comes here, no need to reenable the options
	Gui Destroy
Return	

; Can only arrive here if cancel or x-close/escape the options menu
; not via save (or apply) buttons

OptionsGuiClose:
OptionsGuiEscape:
Gui, Options:-Disabled  
Gui Destroy
Gosub pre_startup	;so the correct values get read back for time *1000 conversion from ms/s vice versa
Return				

;AUpdate_OnClose: ;from the Auto Update GUI
;	Gui Destroy
;	Goto Launch

autoUpdateFound:
TrayUpdate:
	IfWinExist, Macro Trainer Update
	{	
		WinActivate
		Return 					
	}
	if (A_ThisLabel = "autoUpdateFound")
	|| (A_ThisLabel = "TrayUpdate" && (url.UpdateZip := CheckForUpdates(ProgramVersion, latestVersion, url.CurrentVersionInfo)))
	{
		; Very minor bug - for some reason &Canecel does not underline the 'C' in the button
		; for the trayupdate - but it does for the autoupdate
	;	changelog_text := Url2Var(url.changelog)
		Gui, New
		;Gui +Toolwindow	+LabelAUpdate_On
		if (A_ThisLabel = "autoUpdateFound")
			Gui +LabelLaunch +AlwaysOnTop

		Gui, Font, S12 CDefault Bold, Verdana
		Gui, Add, Text, y10 w220, An update is available!
		Gui, Font, S10
		Gui, Add, Text, section y+15, Installed version: 
		Gui, Add, Text, xs+150 ys, %ProgramVersion%

		Gui, Add, Text, xs y+10, Latest version: 
		Gui, Add, Text, xs+150 yp cRed, %latestVersion%


		Gui, Font, Norm 

		if (A_ThisLabel = "autoUpdateFound")
		{
			Gui, Add, Text, xs+450 y10, Click UPDATE to download the latest version.
			Gui, Add, Text, y+10, Click CANCEL to continue running this version.
			Gui, Add, Text, y+10, Click DISABLE to stop the program automatically`nchecking for updates.

			Gui, Font, S8 CDefault, Verdana
			Gui, Add, Text, y+5, (You can still update via right clicking the tray icon.)
		}
		Gui, Font, S9 CDefault Bold, Verdana
		if (A_ThisLabel = "autoUpdateFound")
			Gui, Add, Text, xs y+5 w80, Changelog:
		else Gui, Add, Text, xs y+10 w80, Changelog:

		Gui, Font, Norm
	;	Gui, Add, Edit, x12 y+10 w560 h220 readonly -E0x200, % LTrim(changelog_text)
		Gui Add, ActiveX, x12  w800 h450  vWB, Shell.Explorer
		WB.Navigate(url.changelog)
		Gui, Font, S8 CDefault, Verdana
		if (A_ThisLabel = "autoUpdateFound")
		{
			Gui, Add, Button, x+-100 y+20 w100 h30 gLaunch vCancel_Auto_Update, &Cancel
			Gui, Add, Button, x+-225 yp w100 h30 gLaunch vDisable_Auto_Update, &Disable
		}
		else 
			Gui, Add, Button, x+-100 y+20 w100 h30 gGuiReturn, &Cancel
		Gui, Font, Bold
		Gui, Add, Button, Default x+-225 yp w100 h30 gUpdate, &Update
		Gui, Font, Norm
		
		Gui, Show,, Macro Trainer Update
		sleep, 1500 	; needs 50ms to prevent wb unknown comm error - There's a way to do this with the comMethods - but I cbf atm.
		try WB.Refresh() 	; So it updates to current changelog (not one in cache)
		return				
	}
	Else if (A_ThisLabel = "TrayUpdate") 
	{
		Gui, New
		Gui +Toolwindow +AlwaysOnTop	
		Gui, Add, Picture, x12 y10 w90 h90 , %A_Temp%\Starcraft-2.ico
		Gui, Font, S10 CDefault, Verdana
		Gui, Add, Text, x112 y15  , You already have the latest version.
		Gui, Add, Text, xp yp+20  , Version:
		Gui, Font, S10 CDefault Bold, Verdana
		Gui, Add, Text, xp+60 yp  , %ProgramVersion%
		Gui, Font, Norm 
		Gui, Font, S8 CDefault Bold, Verdana
		Gui, Font, Norm 
		Gui, Add, Button, Default x160 yp+40  w100 h30 gGuiReturn, &OK
		Gui, Show,, Macro Trainer Update
		Return
	}
return 

Update:
	updateSave := "MacroTrainer" latestVersion ".zip"
	If ( InternetFileRead( binData, url.UpdateZip) > 0 && !ErrorLevel )
	{
		If VarZ_Save(binData, updateSave) 
		{
			Sleep 200
			DLP(1, 1, "Download Complete - Extracting") ; 1 file of 1 with message on complete
			if !FileExist(updateSave)
				goto updateErrorExit

			FileRemoveDir, % extractDir := A_ScriptDir "\MTUpdateFiles", 1
			SmartZip(updateSave, extractDir, 4|16) ; no dialogue and yes to all
			; find the name of the included exe
			; normally just trainer exe and dll in zip file
			launchExe := launchSize := ""
			loop, % extractDir "\Macro*.exe "
			{
				launchExe := A_LoopFileName 
				launchSize := A_LoopFileSizeMB
			}
			FileDelete, %updateSave%
			if (!launchExe || !launchSize) ; trainer will always be => 1MB
			{
				FileRemoveDir, %extractDir%, 1 ; recursive
				goto updateErrorExit
			}
			; Due to this file move and files must be in root directory of the unzipped folder
			FileMove, %extractDir%\*.*, %A_ScriptDir%\*.*, 1
			FileRemoveDir, %extractDir%, 1 ; recursive
			if !FileExist(launchExe)
				goto updateErrorExit

			MsgBox, 262145, Update, Download complete.`n`nClick OK to run the latest version (Vr %latestVersion%)`nClick cancel to continue running this version.
			IfMsgBox Ok ;msgbox 1 = ok/cancel buttons
			{	
				FileCreateDir, %old_backup_DIR%
				FileMove, %A_ScriptName%, %old_backup_DIR%\%A_ScriptName%, 1 ;ie 1 = overwrite	
				Run %launchExe%	
				ExitApp
			}
			Else	
				DLP(False) ;removes the progress
			FileCopy, %A_ScriptName%, %old_backup_DIR%\%A_ScriptName%, 1
		}
	}
	else goto updateErrorExit
	Return

updateErrorExit:
	msgbox, 262145, Update Error, An error has occured.`n`nPress OK to launch the trainer website in your browser to manually download the update. 
	IfMsgBox Ok
		run % url.Downloads
return 

; Not used anymore. I think I fixed the bug (sapi) which was preventing the program from exiting cleanly
SingleInstanceCheck:

; SingleInstance, Force will no longer work, as the main window name has been changed
; so for compiled scripts, this will help to ensure that new instances of the program 
; will close older ones while still allowing them to run their exit routines.
; if it can't close it within 2 seconds, it will try a forceful process close
; and then continue with the script

if A_IsCompiled
{
	prev_DetectHiddenWindows := A_DetectHiddenWindows
	prev_TitleMatchMode := A_TitleMatchMode
	DetectHiddenWindows, On
	SetTitleMatchMode, 2
	; This will return pids for processes with the same
	; name as the current process and wont include the current
	; process in the list
	for i, process in getProcesses(True, A_ScriptName)
	{

	;	Winclose needs to be in a loop, as it will only close 
	;	one window at a time. If process owns multiple windows,
	; 	Then we need to keep closing them until the last/hidden/main window
	; 	is closed
		startTick := A_TickCount
		while WinExist("ahk_pid " process.PID)
		{
			if (A_Index > 1)
				sleep 50
			WinGet, processName, ProcessName, % "ahk_pid " process.PID 
			; Just a safety check, in case another process spawned in the 50ms
			; since we closed the previous one, but this is highly unlikely.
			if (processName = A_ScriptName)
			{
				if (A_TickCount - startTick <= 2000)
					WinClose, % "ahk_pid " process.PID
				else 
				{
					Process, Close, % process.PID
					break
				}	
			}
			else break
		} 
	}
	DetectHiddenWindows, %prev_DetectHiddenWindows%  
	SetTitleMatchMode, %prev_TitleMatchMode%         
}
return 

;------------
;	Startup/Reading the ini file
;------------
pre_startup:

if FileExist(config_file) ; the file exists lets read the ini settings
{
	readConfigFile()
	if (ProgramVersion > read_version) ; its an update and the file exists - better backup the users settings
	{
		if !A_IsCompiled
		{
			msgbox, 
			( Ltrim Off
			    MacroTrainer is running as a script (non-compiled) and there is a program version mismatch.
			   
			    Check the "ProgramVersion" value in the script and the "version" key in the config file. 

			    Macro Trainer will now exit
			)
			ExitApp
			return
		}

		if read_version < 3.10 ; multi-injects was accidentally disabled over a year ago. Lots of people will have it enabled as its checked in the included config
			CanQueenMultiInject := 0 ; disable this option for safety in case it does cause issues. It will get written in iniwrite
		program.Info.IsUpdating := 1 ; used in iniWrite
		FileCreateDir, %old_backup_DIR%
		FileCopy, %config_file%, %old_backup_DIR%\v%read_version%_%config_file%, 1 ;ie 1 = overwrite
		Filemove, Macro Trainer V%read_version%.exe, %old_backup_DIR%\Macro Trainer V%read_version%.exe, 1 ;ie 1 = overwrite		
		FileInstall, MT_Config.ini, %config_file%, 1 ; 1 overwrites
		Gosub, ini_settings_write ;to write back users old settings
		;Gosub, pre_startup ; Read the ini settings again - this updates the 'read version' and also helps with Control group 'ERROR' variable 
		program.Info.IsUpdating := 0
		readConfigFile()
		If newVersionFirstRunGUI(ProgramVersion, old_backup_DIR) = "Options"
			gosub options_menu
	}
	else program.Info.IsUpdating := 0		
}
Else If A_IsCompiled  ; config file doesn't exist
{
	FileInstall, MT_Config.ini, %config_file%, 0 ; includes and install the ini to the working directory - 0 prevents file being overwritten
	firstRunGUI(ProgramVersion)
	Gosub pre_startup
	gosub options_menu
}
Return	; to the startup procedure
	

;------------
;	Backing up the users ini settings
;------------
ini_settings_write:
	; Iniwrites
	Tmp_GuiControl := A_GuiControl ; store this result otherwise it will be empty when it gets to the bottom
	if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply") ;I come from the save menu options Not an update and writing back user settings
	{

		; If a hotkey error occurs inside the try, execution will jump outside of the try and
		; throw the catch error
		; BUT if you use a try on each individual command, execution will continue
		; coulde use the errorlevel setting in hotkey command
		; or just relay on conditional #if hotkey-on variants 
		; Disable hotkeys before we update them with new values
		Try disableAllHotkeys()
		Catch, Error	;error is an object
		{
			clipboard := "Error: " error.message "`nLine: " error.line "`nExtra: "error.Extra
			msgbox % "There was an error while updating the hotkey state.`n`nYour previous hotkeys may still be active until you restart the program.`n`nIf you have just edited the options, then this error is NOT very important, but it has been copied to the clipboard if you wish to report it.`n`nNote:`nIf you have just started the program and are receiving this error, then either your hotkeys in your MT_config.ini are corrupted or you are using a non-English keyboard layout. If the latter, you can try changing your keyboard layout to ""English"".`n`nError: " error.message "`nLine: " error.line "`nSpecifically: " error.Extra
		}
		saveCurrentDisplayedItemsQuickSelect(aQuickSelectCopy)
		saveCurrentAutoChronoItem(aAutoChronoCopy)
		IF (Tmp_GuiControl = "save")
		{
			Gui, Submit
			Gui, Destroy
		}
		Else Gui, Submit, NoHide
	}
	; Else from an update
	; Not via GUI e.g. update so need to set a couple of variables to the values which would have been generated from a gui - mostly variance/percentages
	; which are repented in a more friendly manner in the GUI
	; These are done individually immediately before the writes


	
	;[Auto Inject]
	IniWrite, %auto_inject%, %config_file%, Auto Inject, auto_inject_enable
	IniWrite, %auto_inject_alert%, %config_file%, Auto Inject, alert_enable
	IniWrite, %auto_inject_time%, %config_file%, Auto Inject, auto_inject_time
	IniWrite, %cast_inject_key%, %config_file%, Auto Inject, auto_inject_key
	IniWrite, %Inject_control_group%, %config_file%, Auto Inject, control_group
	IniWrite, %Inject_spawn_larva%, %config_file%, Auto Inject, spawn_larva
	IniWrite, %HotkeysZergBurrow%, %config_file%, Auto Inject, HotkeysZergBurrow

	;[Manual Inject Timer]
	IniWrite, %manual_inject_timer%, %config_file%, Manual Inject Timer, manual_timer_enable
	IniWrite, %manual_inject_time%, %config_file%, Manual Inject Timer, manual_inject_time
	IniWrite, %inject_start_key%, %config_file%, Manual Inject Timer, start_stop_key
	IniWrite, %inject_reset_key%, %config_file%, Manual Inject Timer, reset_key

	IniWrite, %InjectTimerAdvancedEnable%, %config_file%, Manual Inject Timer, InjectTimerAdvancedEnable
	IniWrite, %InjectTimerAdvancedTime%, %config_file%, Manual Inject Timer, InjectTimerAdvancedTime
	IniWrite, %InjectTimerAdvancedLarvaKey%, %config_file%, Manual Inject Timer, InjectTimerAdvancedLarvaKey
	
	;[Inject Warning]
	IniWrite, %W_inject_ding_on%, %config_file%, Inject Warning, ding_on
	IniWrite, %W_inject_speech_on%, %config_file%, Inject Warning, speech_on
	IniWrite, %w_inject_spoken%, %config_file%, Inject Warning, w_inject	
	
		;[Forced Inject]
	section := "Forced Inject"
	IniWrite, %F_Inject_Enable%, %config_file%, %section%, F_Inject_Enable
	IniWrite, %FInjectHatchFrequency%, %config_file%, %section%, FInjectHatchFrequency
	IniWrite, %FInjectHatchMaxHatches%, %config_file%, %section%, FInjectHatchMaxHatches
	IniWrite, %FInjectAPMProtection%, %config_file%, %section%, FInjectAPMProtection
	IniWrite, %F_InjectOff_Key%, %config_file%, %section%, F_InjectOff_Key

	;[Idle AFK Game Pause]
	IniWrite, %idle_enable%, %config_file%, Idle AFK Game Pause, enable
	IniWrite, %idle_time%, %config_file%, Idle AFK Game Pause, idle_time
	IniWrite, %UserIdle_LoLimit%, %config_file%, Idle AFK Game Pause, UserIdle_LoLimit
	if (UserIdle_HiLimit < UserIdle_LoLimit)
		UserIdle_HiLimit := UserIdle_LoLimit + 5
	IniWrite, %UserIdle_HiLimit%, %config_file%, Idle AFK Game Pause, UserIdle_HiLimit
	IniWrite, %chat_text%, %config_file%, Idle AFK Game Pause, chat_text


	;[Starcraft Settings & Keys]
	IniWrite, %pause_game%, %config_file%, Starcraft Settings & Keys, pause_game
	IniWrite, %base_camera%, %config_file%, Starcraft Settings & Keys, base_camera
	IniWrite, %NextSubgroupKey%, %config_file%, Starcraft Settings & Keys, NextSubgroupKey
	IniWrite, %escape%, %config_file%, Starcraft Settings & Keys, escape
	
	; [MiniMap Inject]
	section := "MiniMap Inject"
	IniWrite, %MI_Queen_Group%, %config_file%, %section%, MI_Queen_Group
	IniWrite, %MI_QueenDistance%, %config_file%, %section%, MI_QueenDistance
	
	;[Backspace Inject Keys]
	section := "Backspace Inject Keys"
	IniWrite, %BI_create_camera_pos_x%, %config_file%, %section%, create_camera_pos_x
	IniWrite, %BI_camera_pos_x%, %config_file%, %section%, camera_pos_x
	
	;[Forgotten Gateway/Warpgate Warning]
	section := "Forgotten Gateway/Warpgate Warning"
	IniWrite, %warpgate_warn_on%, %config_file%, %section%, enable
	IniWrite, %sec_warpgate%, %config_file%, %section%, warning_count
	IniWrite, %delay_warpgate_warn%, %config_file%, %section%, initial_time_delay
	IniWrite, %delay_warpgate_warn_followup%, %config_file%, %section%, follow_up_time_delay
	IniWrite, %w_warpgate%, %config_file%, %section%, spoken_warning

	
	;[Chrono Boost Gateway/Warpgate]
	section := "Chrono Boost Gateway/Warpgate"
	IniWrite, %CG_control_group%, %config_file%, %section%, CG_control_group
	IniWrite, %CG_nexus_Ctrlgroup_key%, %config_file%, %section%, CG_nexus_Ctrlgroup_key
	IniWrite, %chrono_key%, %config_file%, %section%, chrono_key
	IniWrite, %CG_chrono_remainder%, %config_file%, %section%, CG_chrono_remainder
	IniWrite, %ChronoBoostSleep%, %config_file%, %section%, ChronoBoostSleep
	iniWriteAndUpdateAutoChrono(aAutoChronoCopy, aAutoChrono)
	
	;[Auto Control Group]
	Short_Race_List := "Terr|Prot|Zerg"
	section := "Auto Control Group"		
	Loop, Parse, l_Races, `, ;Terran ie full name
		while (10 > i := A_index - 1)
		{
			if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply") ; this ensure wont blank the field when version updates
				A_UnitGroupSettings["LimitGroup", A_LoopField, i, "Enabled"] := LG_%A_LoopField%%i%
			IniWrite, % A_UnitGroupSettings["LimitGroup", A_LoopField, i,"Enabled"], %config_file%, %section%, %A_LoopField%_LimitGroup_%i%
		}		
	loop, parse, Short_Race_List, |
	{	
		i := 0 			; for the loop 10 below
		If (A_LoopField = "Terr")
			Race := "Terran"
		Else if (A_LoopField = "Prot")
			Race := "Protoss"
		Else If (A_LoopField = "Zerg")
			Race := "Zerg"	

		if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply")
			A_UnitGroupSettings["AutoGroup", Race, "Enabled"] := AG_Enable_%A_LoopField%
		IniWrite, % A_UnitGroupSettings["AutoGroup", Race, "Enabled"], %config_file%, %section%, AG_Enable_%A_LoopField%		
		loop, 10
		{	if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply")
			{			
				tmp := AG_%Race%%i%
				list := checkList := ""
				loop, parse, tmp, `,
				{
					if aUnitID.HasKey(string := Trim(A_LoopField, "`, `t")) ; get rid of spaces which cause haskey to fail
					{	
						if string not in %checkList%
							checkList := list .= string ", " ; leave a space for the gui
					}
				}
				A_UnitGroupSettings[Race, i] := Trim(list, "`, `t")
			}
			IniWrite, % A_UnitGroupSettings[Race, i], %config_file%, %section%, AG_%A_LoopField%%i%
			i++
		}
	}
	IniWrite, %AGBufferDelay%, %config_file%, %section%, AGBufferDelay
	IniWrite, %AGKeyReleaseDelay%, %config_file%, %section%, AGKeyReleaseDelay
	IniWrite, %AGRestrictBufferDelay%, %config_file%, %section%, AGRestrictBufferDelay

	; hotkeys
	loop 10 
	{
		group := A_index -1
		IniWrite, % AGAddToGroup%group%, %config_file%, %section%, AGAddToGroup%group%
		IniWrite, % AGSetGroup%group%, %config_file%, %section%, AGSetGroup%group%
		IniWrite, % AGInvokeGroup%group%, %config_file%, %section%, AGInvokeGroup%group%
	}		

	;[Advanced Auto Inject Settings]
	IniWrite, %auto_inject_sleep%, %config_file%, Advanced Auto Inject Settings, auto_inject_sleep
	if (Tmp_GuiControl != "save" && Tmp_GuiControl != "Apply")
		Inject_SleepVariance := (Inject_SleepVariance - 1)*100 
	IniWrite, %Inject_SleepVariance%, %config_file%, Advanced Auto Inject Settings, Inject_SleepVariance
	; 30 (%) from the gui back into 1.3
	Inject_SleepVariance := 1 + (Inject_SleepVariance/100)
	IniWrite, %CanQueenMultiInject%, %config_file%, Advanced Auto Inject Settings, CanQueenMultiInject
	IniWrite, %InjectConserveQueenEnergy%, %config_file%, Advanced Auto Inject Settings, InjectConserveQueenEnergy
	IniWrite, %Inject_RestoreSelection%, %config_file%, Advanced Auto Inject Settings, Inject_RestoreSelection
	IniWrite, %Inject_RestoreScreenLocation%, %config_file%, Advanced Auto Inject Settings, Inject_RestoreScreenLocation
	IniWrite, %drag_origin%, %config_file%, Advanced Auto Inject Settings, drag_origin

	;[Read Opponents Spawn-Races]
	IniWrite, %race_reading%, %config_file%, Read Opponents Spawn-Races, enable
	IniWrite, %Auto_Read_Races%, %config_file%, Read Opponents Spawn-Races, Auto_Read_Races
	IniWrite, %read_races_key%, %config_file%, Read Opponents Spawn-Races, read_key
	;IniWrite, %race_speech%, %config_file%, Read Opponents Spawn-Races, speech
	;IniWrite, %race_clipboard%, %config_file%, Read Opponents Spawn-Races, copy_to_clipboard

	;[Worker Production Helper]	
	for i, race in ["Terran", "Protoss", "Zerg"]
	{
		for k, varName in [ "WarningsWorker|Enable", "WarningsWorker|TimeWithoutProduction", "WarningsWorker|MinWorkerCount"
							, "WarningsWorker|MaxWorkerCount", "WarningsWorker|FollowUpCount", "WarningsWorker|FollowUpDelay", "WarningsWorker|SpokenWarning" ]
		{
			StringReplace, varName, varName, |, %race%
			IniWrite, % %varName%, %config_file%, Worker Production Helper, %varName%
		}
	}


	;[Minerals]
	IniWrite, %mineralon%, %config_file%, Minerals, warning_enable
	IniWrite, %mineraltrigger%, %config_file%, Minerals, mineral_trigger

	;[Gas]
	IniWrite, %gas_on%, %config_file%, Gas, warning_enable
	IniWrite, %gas_trigger%, %config_file%, Gas, gas_trigger


	;[Idle Workers]
	IniWrite, %idleon%, %config_file%, Idle Workers, warning_enable
	IniWrite, %idletrigger%, %config_file%, Idle Workers, idle_trigger

	;[Supply]
	IniWrite, %supplyon%, %config_file%, Supply, warning_enable
	IniWrite, %minimum_supply%, %config_file%, Supply, minimum_supply
	IniWrite, %supplylower%, %config_file%, Supply, supplylower
	IniWrite, %supplymid%, %config_file%, Supply, supplymid
	IniWrite, %supplyupper%, %config_file%, Supply, supplyupper
	IniWrite, %sub_lowerdelta%, %config_file%, Supply, sub_lowerdelta
	IniWrite, %sub_middelta%, %config_file%, Supply, sub_middelta
	IniWrite, %sub_upperdelta%, %config_file%, Supply, sub_upperdelta
	IniWrite, %above_upperdelta%, %config_file%, Supply, above_upperdelta

	;[WarningsGeyserOverSaturation]
	section := "WarningsGeyserOverSaturation"
	IniWrite, %WarningsGeyserOverSaturationEnable%, %config_file%, %section%, WarningsGeyserOverSaturationEnable	
	IniWrite, %WarningsGeyserOverSaturationMaxWorkers%, %config_file%, %section%, WarningsGeyserOverSaturationMaxWorkers	
	IniWrite, %WarningsGeyserOverSaturationMaxTime%, %config_file%, %section%, WarningsGeyserOverSaturationMaxTime	
	IniWrite, %WarningsGeyserOverSaturationFollowUpCount%, %config_file%, %section%, WarningsGeyserOverSaturationFollowUpCount	
	IniWrite, %WarningsGeyserOverSaturationFollowUpDelay%, %config_file%, %section%, WarningsGeyserOverSaturationFollowUpDelay	
	IniWrite, %WarningsGeyserOverSaturationSpokenWarning%, %config_file%, %section%, WarningsGeyserOverSaturationSpokenWarning	

	;[Additional Warning Count]-----set number of warnings to make
	IniWrite, %sec_supply%, %config_file%, Additional Warning Count, supply
	IniWrite, %sec_mineral%, %config_file%, Additional Warning Count, minerals
	IniWrite, %sec_gas%, %config_file%, Additional Warning Count, gas
	IniWrite, %sec_idle%, %config_file%, Additional Warning Count, idle_workers

	;[Volume]
	section := "Volume"
	IniWrite, %speech_volume%, %config_file%, %section%, speech
	IniWrite, %programVolume%, %config_file%, %section%, program
	SetProgramWaveVolume(programVolume)
	; theres an iniwrite volume in the exit routine

	;[Warnings]-----sets the audio warning
	IniWrite, %w_supply%, %config_file%, Warnings, supply
	IniWrite, %w_mineral%, %config_file%, Warnings, minerals
	IniWrite, %w_gas%, %config_file%, Warnings, gas
	IniWrite, %w_idle%, %config_file%, Warnings, idle_workers

	;[Additional Warning Delay]
	IniWrite, %additional_delay_supply%, %config_file%, Additional Warning Delay, supply
	IniWrite, %additional_delay_minerals%, %config_file%, Additional Warning Delay, minerals
	IniWrite, %additional_delay_gas%, %config_file%, Additional Warning Delay, gas
	IniWrite, %additional_idle_workers%, %config_file%, Additional Warning Delay, idle_workers

	
		;[Auto Mine]
/*
	section := "Auto Mine"
	IniWrite, %auto_mine%, %config_file%, %section%, enable
	IniWrite, %Auto_Mine_Set_CtrlGroup%, %config_file%, %section%, Auto_Mine_Set_CtrlGroup
	IniWrite, %Auto_mineMakeWorker%, %config_file%, %section%, Auto_mineMakeWorker
	IniWrite, %AutoMineMethod%, %config_file%, %section%, AutoMineMethod
	IniWrite, %WorkerSplitType%, %config_file%, %section%, WorkerSplitType
	IniWrite, %Auto_Mine_Sleep2%, %config_file%, %section%, Auto_Mine_Sleep2
	if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply") ;lets calculate the (possibly) new colour
		AM_PixelColour := Gdip_ToARGB(AM_MiniMap_PixelColourAlpha, AM_MiniMap_PixelColourRed, AM_MiniMap_PixelColourGreen, AM_MinsiMap_PixelColourBlue)
	IniWrite, %AM_PixelColour%, %config_file%, %section%, AM_PixelColour
	IniWrite, %AM_MiniMap_PixelVariance%, %config_file%, %section%, AM_MiniMap_PixelVariance
	IniWrite, %Start_Mine_Time%, %config_file%, %section%, Start_Mine_Time
	IniWrite, %Idle_Worker_Key%, %config_file%, %section%, Idle_Worker_Key
	IniWrite, %AM_KeyDelay%, %config_file%, %section%, AM_KeyDelay
	IniWrite, %Gather_Minerals_key%, %config_file%, %section%, Gather_Minerals_key
	IniWrite, %Base_Control_Group_Key%, %config_file%, %section%, Base_Control_Group_Key
	IniWrite, %Make_Worker_T_Key%, %config_file%, %section%, Make_Worker_T_Key
	IniWrite, %Make_Worker_P_Key%, %config_file%, %section%, Make_Worker_P_Key
	IniWrite, %Make_Worker_Z1_Key%, %config_file%, %section%, Make_Worker_Z1_Key
	IniWrite, %Make_Worker_Z2_Key%, %config_file%, %section%, Make_Worker_Z2_Key
*/

	;[Misc Automation]
	section := "AutoWorkerProduction"	
	IniWrite, %EnableAutoWorkerTerranStart%, %config_file%, %section%, EnableAutoWorkerTerranStart
	IniWrite, %EnableAutoWorkerProtossStart%, %config_file%, %section%, EnableAutoWorkerProtossStart
	IniWrite, %ToggleAutoWorkerState_Key%, %config_file%, %section%, ToggleAutoWorkerState_Key
	IniWrite, %AutoWorkerQueueSupplyBlock%, %config_file%, %section%, AutoWorkerQueueSupplyBlock
	IniWrite, %AutoWorkerAlwaysGroup%, %config_file%, %section%, AutoWorkerAlwaysGroup
	IniWrite, %AutoWorkerWarnMaxWorkers%, %config_file%, %section%, AutoWorkerWarnMaxWorkers
	IniWrite, %AutoWorkerAPMProtection%, %config_file%, %section%, AutoWorkerAPMProtection
	IniWrite, %AutoWorkerStorage_T_Key%, %config_file%, %section%, AutoWorkerStorage_T_Key
	IniWrite, %AutoWorkerStorage_P_Key%, %config_file%, %section%, AutoWorkerStorage_P_Key
	IniWrite, %Base_Control_Group_T_Key%, %config_file%, %section%, Base_Control_Group_T_Key
	IniWrite, %Base_Control_Group_P_Key%, %config_file%, %section%, Base_Control_Group_P_Key
	IniWrite, %AutoWorkerMakeWorker_T_Key%, %config_file%, %section%, AutoWorkerMakeWorker_T_Key
	IniWrite, %AutoWorkerMakeWorker_P_Key%, %config_file%, %section%, AutoWorkerMakeWorker_P_Key
	IniWrite, %AutoWorkerMaxWorkerTerran%, %config_file%, %section%, AutoWorkerMaxWorkerTerran
	IniWrite, %AutoWorkerMaxWorkerPerBaseTerran%, %config_file%, %section%, AutoWorkerMaxWorkerPerBaseTerran
	IniWrite, %AutoWorkerMaxWorkerProtoss%, %config_file%, %section%, AutoWorkerMaxWorkerProtoss
	IniWrite, %AutoWorkerMaxWorkerPerBaseProtoss%, %config_file%, %section%, AutoWorkerMaxWorkerPerBaseProtoss


	section := "AutoBuild"	
	IniWrite, %AutoBuildBarracksGroup%, %config_file%, %section%, AutoBuildBarracksGroup
	IniWrite, %AutoBuildFactoryGroup%, %config_file%, %section%, AutoBuildFactoryGroup
	IniWrite, %AutoBuildStarportGroup%, %config_file%, %section%, AutoBuildStarportGroup
	IniWrite, %AutoBuildGatewayGroup%, %config_file%, %section%, AutoBuildGatewayGroup
	IniWrite, %AutoBuildStargateGroup%, %config_file%, %section%, AutoBuildStargateGroup
	IniWrite, %AutoBuildRoboticsFacilityGroup%, %config_file%, %section%, AutoBuildRoboticsFacilityGroup
	IniWrite, %AutoBuildHatcheryGroup%, %config_file%, %section%, AutoBuildHatcheryGroup
	IniWrite, %AutoBuildLairGroup%, %config_file%, %section%, AutoBuildLairGroup
	IniWrite, %AutoBuildHiveGroup%, %config_file%, %section%, AutoBuildHiveGroup
	IniWrite, %autoBuildMinFreeMinerals%, %config_file%, %section%, autoBuildMinFreeMinerals
	IniWrite, %autoBuildMinFreeGas%, %config_file%, %section%, autoBuildMinFreeGas
	IniWrite, %autoBuildMinFreeSupply%, %config_file%, %section%, autoBuildMinFreeSupply
	IniWrite, %AutoBuildEnableGUIHotkey%, %config_file%, %section%, AutoBuildEnableGUIHotkey
	IniWrite, %AutoBuildGUIkey%, %config_file%, %section%, AutoBuildGUIkey
	IniWrite, %AutoBuildGUIkeyMode%, %config_file%, %section%, AutoBuildGUIkeyMode	
	IniWrite, %AutoBuildEnableInteractGUIHotkey%, %config_file%, %section%, AutoBuildEnableInteractGUIHotkey
	IniWrite, %AutoBuildInteractGUIKey%, %config_file%, %section%, AutoBuildInteractGUIKey
	IniWrite, %AutoBuildInactiveOpacity%, %config_file%, %section%, AutoBuildInactiveOpacity
	IniWrite, %AutoBuildGUIAutoWorkerToggle%, %config_file%, %section%, AutoBuildGUIAutoWorkerToggle
	IniWrite, %AutoBuildGUIAutoWorkerPause%, %config_file%, %section%, AutoBuildGUIAutoWorkerPause
	IniWrite, %AutoBuildGUIAutoWorkerOffButton%, %config_file%, %section%, AutoBuildGUIAutoWorkerOffButton
	IniWrite, %autoBuildEnablePauseAllHotkey%, %config_file%, %section%, autoBuildEnablePauseAllHotkey
	IniWrite, %AutoBuildPauseAllkey%, %config_file%, %section%, AutoBuildPauseAllkey

	section := "AutomationCommon"
	IniWrite, %automationAPMThreshold%, %config_file%, %section%, automationAPMThreshold
	IniWrite, %AutomationTerranCtrlGroup%, %config_file%, %section%, AutomationTerranCtrlGroup
	IniWrite, %AutomationProtossCtrlGroup%, %config_file%, %section%, AutomationProtossCtrlGroup
	IniWrite, %AutomationZergCtrlGroup%, %config_file%, %section%, AutomationZergCtrlGroup


	;[Misc Automation]
	section := "Misc Automation"
	IniWrite, %SelectArmyEnable%, %config_file%, %section%, SelectArmyEnable
	IniWrite, %Sc2SelectArmy_Key%, %config_file%, %section%, Sc2SelectArmy_Key
	IniWrite, %castSelectArmy_key%, %config_file%, %section%, castSelectArmy_key
	IniWrite, %SleepSelectArmy%, %config_file%, %section%, SleepSelectArmy
	IniWrite, %ModifierBeepSelectArmy%, %config_file%, %section%, ModifierBeepSelectArmy
	IniWrite, %SelectArmyDeselectXelnaga%, %config_file%, %section%, SelectArmyDeselectXelnaga
	IniWrite, %SelectArmyOnScreen%, %config_file%, %section%, SelectArmyOnScreen
	IniWrite, %SelectArmyDeselectPatrolling%, %config_file%, %section%, SelectArmyDeselectPatrolling
	IniWrite, %SelectArmyDeselectLoadedTransport%, %config_file%, %section%, SelectArmyDeselectLoadedTransport
	IniWrite, %SelectArmyDeselectQueuedDrops%, %config_file%, %section%, SelectArmyDeselectQueuedDrops
	IniWrite, %SelectArmyDeselectHoldPosition%, %config_file%, %section%, SelectArmyDeselectHoldPosition
	IniWrite, %SelectArmyDeselectFollowing%, %config_file%, %section%, SelectArmyDeselectFollowing

	IniWrite, %SelectArmyControlGroupEnable%, %config_file%, %section%, SelectArmyControlGroupEnable
	IniWrite, %Sc2SelectArmyCtrlGroup%, %config_file%, %section%, Sc2SelectArmyCtrlGroup
	IniWrite, %SplitUnitsEnable%, %config_file%, %section%, SplitUnitsEnable
	IniWrite, %castSplitUnit_key%, %config_file%, %section%, castSplitUnit_key
	IniWrite, %SplitctrlgroupStorage_key%, %config_file%, %section%, SplitctrlgroupStorage_key
	IniWrite, %SleepSplitUnits%, %config_file%, %section%, SleepSplitUnits
	IniWrite, %l_DeselectArmy%, %config_file%, %section%, l_DeselectArmy
	IniWrite, %DeselectSleepTime%, %config_file%, %section%, DeselectSleepTime
	IniWrite, %RemoveUnitEnable%, %config_file%, %section%, RemoveUnitEnable
	IniWrite, %castRemoveUnit_key%, %config_file%, %section%, castRemoveUnit_key
	IniWrite, %RemoveDamagedUnitsEnable%, %config_file%, %section%, RemoveDamagedUnitsEnable	
	IniWrite, %castRemoveDamagedUnits_key%, %config_file%, %section%, castRemoveDamagedUnits_key	
	IniWrite, %RemoveDamagedUnitsCtrlGroup%, %config_file%, %section%, RemoveDamagedUnitsCtrlGroup	
	if (Tmp_GuiControl != "save" && Tmp_GuiControl != "Apply")
	{
		RemoveDamagedUnitsHealthLevel := round(RemoveDamagedUnitsHealthLevel * 100)
		RemoveDamagedUnitsShieldLevel := round(RemoveDamagedUnitsShieldLevel * 100)
	}
	IniWrite, %RemoveDamagedUnitsHealthLevel%, %config_file%, %section%, RemoveDamagedUnitsHealthLevel	
	IniWrite, %RemoveDamagedUnitsShieldLevel%, %config_file%, %section%, RemoveDamagedUnitsShieldLevel	
	RemoveDamagedUnitsHealthLevel := round(RemoveDamagedUnitsHealthLevel / 100, 3)
	RemoveDamagedUnitsShieldLevel := round(RemoveDamagedUnitsShieldLevel / 100, 3)

	IniWrite, %EasyUnloadTerranEnable%, %config_file%, %section%, EasyUnloadTerranEnable
	IniWrite, %EasyUnloadProtossEnable%, %config_file%, %section%, EasyUnloadProtossEnable
	IniWrite, %EasyUnloadZergEnable%, %config_file%, %section%, EasyUnloadZergEnable
	IniWrite, %EasyUnloadAllTerranEnable%, %config_file%, %section%, EasyUnloadAllTerranEnable
	IniWrite, %EasyUnloadAllProtossEnable%, %config_file%, %section%, EasyUnloadAllProtossEnable
	IniWrite, %EasyUnloadAllZergEnable%, %config_file%, %section%, EasyUnloadAllZergEnable
	IniWrite, %EasyUnloadHotkey%, %config_file%, %section%, EasyUnloadHotkey
	IniWrite, %EasyUnloadQueuedHotkey%, %config_file%, %section%, EasyUnloadQueuedHotkey
	IniWrite, %EasyUnload_T_Key%, %config_file%, %section%, EasyUnload_T_Key
	IniWrite, %EasyUnload_P_Key%, %config_file%, %section%, EasyUnload_P_Key
	IniWrite, %EasyUnload_Z_Key%, %config_file%, %section%, EasyUnload_Z_Key
	IniWrite, %EasyUnloadStorageKey%, %config_file%, %section%, EasyUnloadStorageKey

	IniWrite, %smartGeyserEnable%, %config_file%, %section%, smartGeyserEnable
	IniWrite, %smartGeyserCtrlGroup%, %config_file%, %section%, smartGeyserCtrlGroup
	IniWrite, %smartGeyserReturnCargo%, %config_file%, %section%, smartGeyserReturnCargo

	;[Misc Hotkey]
	IniWrite, %EnableWorkerCountSpeechHotkey%, %config_file%, Misc Hotkey, EnableWorkerCountSpeechHotkey
	IniWrite, %worker_count_local_key%, %config_file%, Misc Hotkey, worker_count_key
	IniWrite, %EnableEnemyWorkerCountSpeechHotkey%, %config_file%, Misc Hotkey, EnableEnemyWorkerCountSpeechHotkey	
	IniWrite, %worker_count_enemy_key%, %config_file%, Misc Hotkey, enemy_worker_count
	IniWrite, %EnableToggleMacroTrainerHotkey%, %config_file%, Misc Hotkey, EnableToggleMacroTrainerHotkey
	IniWrite, %warning_toggle_key%, %config_file%, Misc Hotkey, pause_resume_warnings_key
	IniWrite, %EnablePingMiniMapHotkey%, %config_file%, Misc Hotkey, EnablePingMiniMapHotkey
	IniWrite, %ping_key%, %config_file%, Misc Hotkey, ping_map

	;[Misc Settings]
	section := "Misc Settings"
	IniWrite, %input_method%, %config_file%, %section%, input_method
	IniWrite, %EventKeyDelay%, %config_file%, %section%, EventKeyDelay
	IniWrite, %pSendDelay%, %config_file%, %section%, pSendDelay
	IniWrite, %pClickDelay%, %config_file%, %section%, pClickDelay
	if (Tmp_GuiControl = "save" || Tmp_GuiControl = "Apply")
	{
		if LauncherRadioBattleNet
			LauncherMode := "Battle.net" 
		else if LauncherRadioStarCraft
			LauncherMode := "Starcraft"
		else LauncherMode := "Off"
	}
	else if !LauncherMode ; Shouldn't be required
		LauncherMode := "Off"
	IniWrite, %LauncherMode%, %config_file%, %section%, LauncherMode
	IniWrite, %auto_update%, %config_file%, %section%, auto_check_updates
	Iniwrite, %launch_settings%, %config_file%, %section%, launch_settings
	Iniwrite, %MaxWindowOnStart%, %config_file%, %section%, MaxWindowOnStart
	Iniwrite, %HumanMouse%, %config_file%, %section%, HumanMouse
	Iniwrite, %HumanMouseTimeLo%, %config_file%, %section%, HumanMouseTimeLo
	Iniwrite, %HumanMouseTimeHi%, %config_file%, %section%, HumanMouseTimeHi
	;Iniwrite, %UnitDetectionTimer_ms%, %config_file%, %section%, UnitDetectionTimer_ms
	Iniwrite, %MTCustomIcon%, %config_file%, %section%, MTCustomIcon

	if (MTCustomProgramName && A_IsCompiled)
	{
		if (substr(MTCustomProgramName, -3) != ".exe") ; extract last four chars (0 gets the last char) - case insensitive
			MTCustomProgramName .= ".exe"
		Iniwrite, %MTCustomProgramName%, %config_file%, %section%, MTCustomProgramName	
	}
	else Iniwrite, %MTCustomProgramName%, %config_file%, %section%, MTCustomProgramName		


; 	Iniwrite was causing a space character to get appended to the key each time
; 	rather than overwriting the spaces with a single space
; 	so would end up with a string of spaces... weird
;	so use a blank variable rather than A_Space
;	Iniwrite, %A_Space%, %config_file%, %section%, MTCustomProgramName	

	
	;[Key Blocking]
	section := "Key Blocking"
	IniWrite, %BlockingStandard%, %config_file%, %section%, BlockingStandard
	IniWrite, %BlockingFunctional%, %config_file%, %section%, BlockingFunctional
	IniWrite, %BlockingNumpad%, %config_file%, %section%, BlockingNumpad
	IniWrite, %BlockingMouseKeys%, %config_file%, %section%, BlockingMouseKeys
	IniWrite, %BlockingMultimedia%, %config_file%, %section%, BlockingMultimedia
	IniWrite, %SC2AdvancedEnlargedMinimap%, %config_file%, %section%, SC2AdvancedEnlargedMinimap
	IniWrite, %LwinDisable%, %config_file%, %section%, LwinDisable
	IniWrite, %Key_EmergencyRestart%, %config_file%, %section%, Key_EmergencyRestart

	;[Alert Location]
	IniWrite, %Playback_Alert_Key%, %config_file%, Alert Location, Playback_Alert_Key
	IniWrite, %EnableLastAlertPlayBackHotkey%, %config_file%, Alert Location, EnableLastAlertPlayBackHotkey

	;[Overlays]
	section := "Overlays"
	list := "IncomeOverlay,ResourcesOverlay,ArmySizeOverlay,WorkerOverlay,IdleWorkersOverlay,UnitOverlay,LocalPlayerColourOverlay,APMOverlay,MacroTownHallOverlay,LocalUpgradesOverlay"
	loop, parse, list, `,
	{
		drawname := "Draw" A_LoopField,	drawvar := %drawname%
		scalename := A_LoopField "Scale", scalevar := %scalename%
		Togglename := "Toggle" A_LoopField "Key", Togglevar := %Togglename%
		IniWrite, %drawvar%, %config_file%, %section%, %drawname%
		Iniwrite, %scalevar%, %config_file%, %section%, %scalename%
		if (Togglevar != "") ; as some won't have a toggle key
			Iniwrite, %Togglevar%, %config_file%, %section%, %Togglename% 	
	}
	Iniwrite, %EnableHideMiniMapHotkey%, %config_file%, %section%, EnableHideMiniMapHotkey	
	Iniwrite, %EnableToggleMiniMapHotkey%, %config_file%, %section%, EnableToggleMiniMapHotkey	
	Iniwrite, %EnableToggleIncomeOverlayHotkey%, %config_file%, %section%, EnableToggleIncomeOverlayHotkey	
	Iniwrite, %EnableToggleResourcesOverlayHotkey%, %config_file%, %section%, EnableToggleResourcesOverlayHotkey	
	Iniwrite, %EnableToggleArmySizeOverlayHotkey%, %config_file%, %section%, EnableToggleArmySizeOverlayHotkey	
	Iniwrite, %EnableToggleWorkerOverlayHotkey%, %config_file%, %section%, EnableToggleWorkerOverlayHotkey	
	Iniwrite, %EnableToggleUnitPanelOverlayHotkey%, %config_file%, %section%, EnableToggleUnitPanelOverlayHotkey	
	Iniwrite, %EnableCycleIdentifierHotkey%, %config_file%, %section%, EnableCycleIdentifierHotkey	
	Iniwrite, %EnableAdjustOverlaysHotkey%, %config_file%, %section%, EnableAdjustOverlaysHotkey	

	Iniwrite, %ToggleMinimapOverlayKey%, %config_file%, %section%, ToggleMinimapOverlayKey	
	Iniwrite, %AdjustOverlayKey%, %config_file%, %section%, AdjustOverlayKey	
	Iniwrite, %ToggleIdentifierKey%, %config_file%, %section%, ToggleIdentifierKey	
	;Iniwrite, %CycleOverlayKey%, %config_file%, %section%, CycleOverlayKey	
		If (OverlayIdent = "Hidden")	
			OverlayIdent := 0
		Else If (OverlayIdent = "Name (White)")	
			OverlayIdent := 1				
		Else If (OverlayIdent = "Name (Coloured)")	
			OverlayIdent := 2		
		Else If (OverlayIdent = "Coloured Race Icon")	
			OverlayIdent := 3
		Else if OverlayIdent NOT in 0,1,2,3
			OverlayIdent := 3	
	Iniwrite, %OverlayIdent%, %config_file%, %section%, OverlayIdent	
	Iniwrite, %SplitUnitPanel%, %config_file%, %section%, SplitUnitPanel	
	Iniwrite, %unitPanelAlignNewUnits%, %config_file%, %section%, unitPanelAlignNewUnits	
	Iniwrite, %DrawUnitUpgrades%, %config_file%, %section%, DrawUnitUpgrades
	Iniwrite, %unitPanelDrawStructureProgress%, %config_file%, %section%, unitPanelDrawStructureProgress
	Iniwrite, %unitPanelDrawUnitProgress%, %config_file%, %section%, unitPanelDrawUnitProgress
	Iniwrite, %unitPanelDrawUpgradeProgress%, %config_file%, %section%, unitPanelDrawUpgradeProgress
	Iniwrite, %unitPanelDrawLocalPlayer%, %config_file%, %section%, unitPanelDrawLocalPlayer
;	Iniwrite, %OverlayBackgrounds%, %config_file%, %section%, OverlayBackgrounds	
	Iniwrite, %MiniMapRefresh%, %config_file%, %section%, MiniMapRefresh	
	Iniwrite, %OverlayRefresh%, %config_file%, %section%, OverlayRefresh	
	Iniwrite, %UnitOverlayRefresh%, %config_file%, %section%, UnitOverlayRefresh
	Iniwrite, %APMOverlayMode%, %config_file%, %section%, APMOverlayMode
	Iniwrite, %drawLocalPlayerResources%, %config_file%, %section%, drawLocalPlayerResources
	Iniwrite, %drawLocalPlayerIncome%, %config_file%, %section%, drawLocalPlayerIncome
	Iniwrite, %drawLocalPlayerArmy%, %config_file%, %section%, drawLocalPlayerArmy
	Iniwrite, %localUpgradesItemsPerRow%, %config_file%, %section%, localUpgradesItemsPerRow
	Iniwrite, %IdleWorkerOverlayThreshold%, %config_file%, %section%, IdleWorkerOverlayThreshold


	; convert from 0-100 to 0-255
	loopList := "overlayIncomeTransparency,overlayMatchTransparency,overlayResourceTransparency,overlayArmyTransparency,overlayAPMTransparency"
			.	",overlayHarvesterTransparency,overlayIdleWorkerTransparency,overlayLocalColourTransparency,overlayMinimapTransparency"
			.   ",overlayMacroTownHallTransparency,overlayLocalUpgradesTransparency"
	loop, parse, loopList, `,
	{
		if (Tmp_GuiControl = "save" || Tmp_GuiControl = "Apply")
			%A_LoopField% := ceil(%A_LoopField% * 2.55) 
		if (%A_LoopField% > 255 || %A_LoopField% < 0) ; I dont think this can happen
			%A_LoopField% := 255
		Iniwrite, % %A_LoopField%, %config_file%, %section%, %A_LoopField%
	}

	if (Tmp_GuiControl = "save" || Tmp_GuiControl = "Apply")
		TransparentBackgroundColour := (TransparentBackgroundColour & 0x00FFFFFF) | (round(TransparentBackgroundSlider * 2.55) << 24)
	Iniwrite, % dectohex(TransparentBackgroundColour), %config_file%, %section%, TransparentBackgroundColour

	Iniwrite, %BackgroundIncomeOverlay%, %config_file%, %section%, BackgroundIncomeOverlay
	Iniwrite, %BackgroundResourcesOverlay%, %config_file%, %section%, BackgroundResourcesOverlay
	Iniwrite, %BackgroundArmySizeOverlay%, %config_file%, %section%, BackgroundArmySizeOverlay
	Iniwrite, %BackgroundAPMOverlay%, %config_file%, %section%, BackgroundAPMOverlay
	Iniwrite, %BackgroundIdleWorkersOverlay%, %config_file%, %section%, BackgroundIdleWorkersOverlay
	Iniwrite, %BackgroundWorkerOverlay%, %config_file%, %section%, BackgroundWorkerOverlay
	Iniwrite, %BackgroundMacroTownHallOverlay%, %config_file%, %section%, BackgroundMacroTownHallOverlay
	Iniwrite, %BackgroundMacroAutoBuildOverlay%, %config_file%, %section%, BackgroundMacroAutoBuildOverlay

	;[MiniMap]
	section := "MiniMap" 

	lKeys := "UnitHighlightList1,UnitHighlightList2,UnitHighlightList3,UnitHighlightList4"
		   . ",UnitHighlightList5,UnitHighlightList6,UnitHighlightList7"	
		   . ",UnitHighlightExcludeList"
	
	; the actual unit lists
	loop, parse, lKeys, `,
	{
		list := checkList := ""	
		highlistList := %A_LoopField%
		loop, parse, highlistList, `,
		{
			if aUnitID.HasKey(string := Trim(A_LoopField, "`n`, `t")) ; get rid of spaces which cause haskey to fail
			{	
				if string not in %checkList%
					list .= string ", "

			}
		}
		IniWrite, % Trim(list, "`n`, `t"), %config_file%, %section%, %A_LoopField%
		; IniWrite, %UnitHighlightList1%, %config_file%, %section%, UnitHighlightList1	;the list
	}
	; dectohex() so colours are saved in 0xFFF95AB2 format - easier to look at in config file
	loop, 7 ; 7 colours
		IniWrite, % dectohex(UnitHighlightList%A_Index%Colour), %config_file%, %section%, UnitHighlightList%A_Index%Colour ;the colour

	IniWrite, %HighlightInvisible%, %config_file%, %section%, HighlightInvisible
	IniWrite, % dectohex(UnitHighlightInvisibleColour), %config_file%, %section%, UnitHighlightInvisibleColour

	IniWrite, %HighlightHallucinations%, %config_file%, %section%, HighlightHallucinations
	IniWrite, % dectohex(UnitHighlightHallucinationsColour), %config_file%, %section%, UnitHighlightHallucinationsColour


	IniWrite, %DrawMiniMap%, %config_file%, %section%, DrawMiniMap
	IniWrite, %TempHideMiniMapKey%, %config_file%, %section%, TempHideMiniMapKey
	IniWrite, %DrawSpawningRaces%, %config_file%, %section%, DrawSpawningRaces
	IniWrite, %DrawAlerts%, %config_file%, %section%, DrawAlerts
	IniWrite, %DrawUnitDestinations%, %config_file%, %section%, DrawUnitDestinations
	IniWrite, %DrawPlayerCameras%, %config_file%, %section%, DrawPlayerCameras
	IniWrite, %HostileColourAssist%, %config_file%, %section%, HostileColourAssist

	iniWriteAndUpdateQuickSelect(aQuickSelectCopy, aQuickSelect)

	;this writes back the unit detection lists and settings

	loop, parse, l_GameType, `,
	{
		alert_array[A_LoopField, "Enabled"] := BAS_on_%A_LoopField%
		IniWrite, % alert_array[A_LoopField, "Enabled"], %config_file%, Building & Unit Alert %A_LoopField%, enable	;alert system on/off
	}

	if (program.Info.IsUpdating && A_IsCompiled)	;as both of these have there own write routines which activate on clicking 'save' in their on guis
	{
		saveAlertArray(alert_array)
		;;;	Gosub, g_SaveCustomUnitPanelFilter      **** Can't use this, as there has been no created List View gui variables so the list view class wont work!!!!!!
		; solution 
		;[UnitPanelFilter]
		section := "UnitPanelFilter" 
		loop, parse, l_Races, `,
		{
			race := A_LoopField
			list := convertObjectToList(aUnitPanelUnits[race, "FilteredCompleted"], "|")
			IniWrite, %List%, %config_file%, %section%, % race "FilteredCompleted"
			list := convertObjectToList(aUnitPanelUnits[race, "FilteredUnderConstruction"], "|")
			IniWrite, %List%, %config_file%, %section%, % race "FilteredUnderConstruction"
			list := ""
		}
	}
	IF (Tmp_GuiControl = "save" or Tmp_GuiControl = "Apply")
	{
		initialiseBrushColours(aHexColours, a_pBrushes) ; So Changes to brushes are updated for autoBuild GUI
		if aThreads.MiniMap.ahkReady()
		{
			aThreads.MiniMap.ahkFunction("updateUserSettings")
			if (time && alert_array[GameType, "Enabled"])
				 aThreads.MiniMap.ahkFunction("doUnitDetection", 0, 0, 0, 0, "Save")
		}
		if aThreads.Overlays.ahkReady()
			aThreads.Overlays.ahkFunction("updateUserSettings")

		Tmp_GuiControl := ""
		CreateHotkeys()	; to reactivate the hotkeys that were disabled by disableAllHotkeys()
		UserSavedAppliedSettings := 1
		If isInMatch  ; so if they change settings during match will update timers
			UpdateTimers := 1
	}
Return

g_CreateUnitListsAndObjects:

l_UnitNames := "Colossus|TechLab|Reactor|InfestorTerran|BanelingCocoon|Baneling|Mothership|PointDefenseDrone|Changeling|ChangelingZealot|ChangelingMarineShield|ChangelingMarine|ChangelingZerglingWings|ChangelingZergling|InfestedTerran|CommandCenter|SupplyDepot|Refinery|Barracks|EngineeringBay|MissileTurret|Bunker|SensorTower|GhostAcademy|Factory|Starport|Armory|FusionCore|AutoTurret|SiegeTankSieged|SiegeTank|VikingAssault|VikingFighter|CommandCenterFlying|BarracksTechLab|BarracksReactor|FactoryTechLab|FactoryReactor|StarportTechLab|StarportReactor|FactoryFlying|StarportFlying|SCV|BarracksFlying|SupplyDepotLowered|Marine|Reaper|Ghost|Marauder|Thor|ThorHighImpactPayload|Hellion|Medivac|Banshee|Raven|Battlecruiser|Nuke|Nexus|Pylon|Assimilator|Gateway|Forge|FleetBeacon|TwilightCouncil|PhotonCannon|Stargate|TemplarArchive|DarkShrine|RoboticsBay|RoboticsFacility|CyberneticsCore|Zealot|Stalker|HighTemplar|DarkTemplar|Sentry|Phoenix|Carrier|VoidRay|WarpPrism|Observer|Immortal|Probe|Interceptor|Hatchery|CreepTumor|Extractor|SpawningPool|EvolutionChamber|HydraliskDen|Spire|UltraliskCavern|InfestationPit|NydusNetwork|BanelingNest|RoachWarren|SpineCrawler|SporeCrawler|Lair|Hive|GreaterSpire|Egg|Drone|Zergling|Overlord|Hydralisk|Mutalisk|Ultralisk|Roach|Infestor|Corruptor|BroodLordCocoon|BroodLord|BanelingBurrowed|DroneBurrowed|HydraliskBurrowed|RoachBurrowed|ZerglingBurrowed|InfestorTerranBurrowed|QueenBurrowed|Queen|InfestorBurrowed|OverlordCocoon|Overseer|PlanetaryFortress|UltraliskBurrowed|OrbitalCommand|WarpGate|OrbitalCommandFlying|ForceField|WarpPrismPhasing|CreepTumorBurrowed|SpineCrawlerUprooted|SporeCrawlerUprooted|Archon|NydusCanal|BroodlingEscort|Mule|Larva|HellBat|MothershipCore|Locust|SwarmHostBurrowed|SwarmHost|Oracle|Tempest|WidowMine|Viper|WidowMineBurrowed"
l_UnitNamesTerran := "TechLab|Reactor|PointDefenseDrone|CommandCenter|SupplyDepot|Refinery|Barracks|EngineeringBay|MissileTurret|Bunker|SensorTower|GhostAcademy|Factory|Starport|Armory|FusionCore|AutoTurret|SiegeTankSieged|SiegeTank|VikingAssault|VikingFighter|CommandCenterFlying|BarracksTechLab|BarracksReactor|FactoryTechLab|FactoryReactor|StarportTechLab|StarportReactor|FactoryFlying|StarportFlying|SCV|BarracksFlying|SupplyDepotLowered|Marine|Reaper|Ghost|Marauder|Thor|ThorHighImpactPayload|Hellion|Medivac|Banshee|Raven|Battlecruiser|Nuke|PlanetaryFortress|OrbitalCommand|OrbitalCommandFlying|MULE|HellBat|WidowMine|WidowMineBurrowed"
l_UnitNamesProtoss := "Colossus|Mothership|Nexus|Pylon|Assimilator|Gateway|Forge|FleetBeacon|TwilightCouncil|PhotonCannon|Stargate|TemplarArchive|DarkShrine|RoboticsBay|RoboticsFacility|CyberneticsCore|Zealot|Stalker|HighTemplar|DarkTemplar|Sentry|Phoenix|Carrier|VoidRay|WarpPrism|Observer|Immortal|Probe|Interceptor|WarpGate|WarpPrismPhasing|Archon|MothershipCore|Oracle|Tempest"
l_UnitNamesZerg := "InfestorTerran|BanelingCocoon|Baneling|Changeling|ChangelingZealot|ChangelingMarineShield|ChangelingMarine|ChangelingZerglingWings|ChangelingZergling|InfestedTerran|Hatchery|CreepTumor|Extractor|SpawningPool|EvolutionChamber|HydraliskDen|Spire|UltraliskCavern|InfestationPit|NydusNetwork|BanelingNest|RoachWarren|SpineCrawler|SporeCrawler|Lair|Hive|GreaterSpire|Egg|Drone|Zergling|Overlord|Hydralisk|Mutalisk|Ultralisk|Roach|Infestor|Corruptor|BroodLordCocoon|BroodLord|BanelingBurrowed|DroneBurrowed|HydraliskBurrowed|RoachBurrowed|ZerglingBurrowed|InfestorTerranBurrowed|QueenBurrowed|Queen|InfestorBurrowed|OverlordCocoon|Overseer|UltraliskBurrowed|CreepTumorBurrowed|SpineCrawlerUprooted|SporeCrawlerUprooted|NydusCanal|BroodlingEscort|Larva|Locust|SwarmHostBurrowed|SwarmHost|Viper"

l_UnitNamesTerranArmy := "SiegeTankSieged|SiegeTank|VikingAssault|VikingFighter|Marine|Reaper|Ghost|Marauder|Thor|ThorHighImpactPayload|Hellion|Medivac|Banshee|Raven|Battlecruiser|HellBat|WidowMine|WidowMineBurrowed"
l_UnitNamesProtossArmy := "Colossus|Mothership|Zealot|Stalker|HighTemplar|DarkTemplar|Sentry|Phoenix|Carrier|VoidRay|WarpPrism|Observer|Immortal|WarpPrismPhasing|Archon|MothershipCore|Oracle|Tempest"
l_UnitNamesZergArmy := "InfestorTerran|BanelingCocoon|Baneling|InfestedTerran|Zergling|Hydralisk|Mutalisk|Ultralisk|Roach|Infestor|Corruptor|BroodLordCocoon|BroodLord|BanelingBurrowed|HydraliskBurrowed|RoachBurrowed|ZerglingBurrowed|InfestorTerranBurrowed|InfestorBurrowed|OverlordCocoon|Overseer|UltraliskBurrowed|SwarmHostBurrowed|SwarmHost|Viper"
l_UnitNamesArmy := l_UnitNamesTerranArmy "|" l_UnitNamesProtossArmy "|" l_UnitNamesZergArmy

l_UnitNamesQuickSelectTerran := "SiegeTankSieged|SiegeTank|VikingAssault|VikingFighter|Marine|Reaper|Ghost|Marauder|Thor|ThorHighImpactPayload|Hellion|Medivac|Banshee|Raven|Battlecruiser|HellBat|WidowMine|WidowMineBurrowed|SCV|Mule|PointDefenseDrone"
l_UnitNamesQuickSelectProtoss := "Colossus|Mothership|Zealot|Stalker|HighTemplar|DarkTemplar|Sentry|Phoenix|Carrier|VoidRay|WarpPrism|Observer|Immortal|WarpPrismPhasing|Archon|MothershipCore|Oracle|Tempest|Probe"
l_UnitNamesQuickSelectZerg := "InfestorTerran|BanelingCocoon|Baneling|InfestedTerran|Zergling|Hydralisk|Mutalisk|Ultralisk|Roach|Infestor|Corruptor|BroodLordCocoon|BroodLord|BanelingBurrowed|HydraliskBurrowed|RoachBurrowed|ZerglingBurrowed|InfestorTerranBurrowed|InfestorBurrowed|OverlordCocoon|Overseer|UltraliskBurrowed|SwarmHostBurrowed|SwarmHost|Viper|Queen|QueenBurrowed|Drone|DroneBurrowed|Overlord|Changeling|ChangelingZealot|ChangelingMarineShield|ChangelingMarine|ChangelingZerglingWings|ChangelingZergling"

l_UnitPanelTerran := "TechLab|Reactor|PointDefenseDrone|CommandCenter|SupplyDepot|Refinery|Barracks|EngineeringBay|MissileTurret|Bunker|SensorTower|GhostAcademy|Factory|Starport|Armory|FusionCore|AutoTurret|SiegeTank|VikingFighter|SCV|Marine|Reaper|Ghost|Marauder|Thor|ThorHighImpactPayload|Hellion|Medivac|Banshee|Raven|Battlecruiser|Nuke|PlanetaryFortress|OrbitalCommand|MULE|HellBat|WidowMine"
l_UnitPanelZerg := "BanelingCocoon|Baneling|Changeling|InfestedTerran|Hatchery|CreepTumor|Extractor|SpawningPool|EvolutionChamber|HydraliskDen|Spire|UltraliskCavern|InfestationPit|NydusNetwork|BanelingNest|RoachWarren|SpineCrawler|SporeCrawler|Lair|Hive|GreaterSpire|Egg|Drone|Zergling|Overlord|Hydralisk|Mutalisk|Ultralisk|Roach|Infestor|Corruptor|BroodLordCocoon|BroodLord|Queen|OverlordCocoon|Overseer|NydusCanal|Larva|SwarmHost|Viper"
l_UnitPanelProtoss := "Colossus|Mothership|Nexus|Pylon|Assimilator|Gateway|Forge|FleetBeacon|TwilightCouncil|PhotonCannon|Stargate|TemplarArchive|DarkShrine|RoboticsBay|RoboticsFacility|CyberneticsCore|Zealot|Stalker|HighTemplar|DarkTemplar|Sentry|Phoenix|Carrier|VoidRay|WarpPrism|Observer|Immortal|Probe|WarpGate|WarpPrismPhasing|Archon|MothershipCore|Oracle|Tempest"

aUnitLists := [], aUnitLists["All"] := []

ConvertListToObject(aUnitLists["All"], l_UnitNames)
loop, parse, l_Races, `,
{
	race := A_LoopField, list := "l_UnitNames" race, list := %list%
	aUnitLists[race] := []
	ConvertListToObject(aUnitLists[race], list)
	list := "l_UnitPanel" race, list := %list%
	aUnitLists["UnitPanel", race] := []
	ConvertListToObject(aUnitLists["UnitPanel", race], list)
}
return


options_menu:
/*
IfWinExist, V%ProgramVersion% Settings
{
	WinActivate
	Return 									; prevent error due to reloading gui 
}
*/
; different way to do the same thing.
Gui Options:+LastFoundExist
IfWinExist 
{
	WinActivate
	Return 									; prevent error due to reloading gui 
}

; this Try is a fix for people with shitty slow computers.
; so if they quadruple click the icon AHK wont give a thread exit error due to duplicate 
; gui variables because their computer was to slow to load the gui window the first time

try 
{
	Gui, Options:New
	gui, font, norm s9	;here so if windows user has +/- font size this standardises it. But need to do other menus one day
	;Gui, +ToolWindow  +E0x40000 ; E0x40000 gives it a icon on taskbar (+ToolWindow doesn't have an icon)
	options_menu := "home32.png|map32.png|Inject32.png|Group32.png|QuickGroup32.png|Worker32.png|autoBuild32.png|reticule32.png|Robot32.png|key.png|warning32.ico|miscB32.png|bug32.png|settings.ico"
	optionsMenuTitles := "Home|MiniMap/Overlays|Injects|Auto Grouping|Quick Select|Auto Worker|Auto Build|Chrono Boost|Misc Automation|SC2 Keys|Warnings|Misc Abilities|Bug Report|Settings"

	Gosub, g_CreateUnitListsAndObjects ; used for some menu items, and for the custom unit filter gui

	ImageListID := IL_Create(10, 5, 1)  ; Create an ImageList with initial capacity for 10 icons, grows it by 5 if need be, and 1=large icons
	 
	loop, parse, options_menu, | ; | = delimter
		IL_Add(ImageListID, A_Temp "\" A_LoopField) 

	guiMenuHeight := 460

	Gui, Add, TreeView, -Lines ReadOnly ImageList%ImageListID% h%guiMenuHeight% w150 gOptionsTree vGUIListViewIdentifyingVariableForRedraw
	loop, parse, optionsMenuTitles, |
		TV_Add(A_LoopField, 0, "Icon" A_Index)  
		
			Gui, Font, s10
			GUIButtonPosition := guiMenuHeight + 13
			Gui, Add, Button, x403 y%GUIButtonPosition% w54 h25 gIni_settings_write, Save
			Gui, Add, Button, x+20 w54 h25 gOptionsGuiClose, Cancel
			Gui, Add, Button, x+20 w54 h25 gIni_settings_write, Apply
			Gui, Font, 

	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% ys x165 vInjects_TAB, Info||Basic|Auto|Settings|Alerts
	GuiControlGet, MenuTab, Pos, Injects_TAB
	Gui, Tab,  Basic
		Gui, Add, GroupBox, y+15 w200 h230 section vOriginTab, One Button Inject
				GuiControlGet, OriginTab, Pos
			Gui, Add, Text,xp+10 yp+25, Method:		
					If (auto_inject = 0 OR auto_inject = "Disabled")
						droplist_var := 4
					Else If (auto_inject = "MiniMap")
						droplist_var := 1
					Else if (auto_inject = "Backspace Adv") || (auto_inject = "Backspace CtrlGroup")
						droplist_var := 2  
					Else droplist_var := 3
					Gui, Add, DropDownList,x+10 yp-2 w130 vAuto_inject Choose%droplist_var% gBasicInjectToggleOptionsGUI, MiniMap||Backspace CtrlGroup|Backspace|Disabled
					tmp_xvar := OriginTabx + 10


			Gui, Add, Text, xs+10 yp+45 vSillyGUIControlIdentVariable, Inject Hotkey:
			GuiControlGet, XTab, Pos, SillyGUIControlIdentVariable ;XTabX = x loc
			Gui, Add, Edit, Readonly yp-2 xs+85 center w65 R1 vcast_inject_key gedit_hotkey, %cast_inject_key%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#cast_inject_key,  Edit ;have to use a trick eg '#' as cant write directly to above edit var, or it will activate its own label!
			
			Gui, Add, Text, xs+10 y+20, Sleep time (ms):`n(Lower is faster)
			Gui, Add, Edit, Number Right xs+145 yp-2 w45 vEdit_pos_var 
				Gui, Add, UpDown,  Range0-100000 vAuto_inject_sleep, %auto_inject_sleep%

			Gui, Add, Text, xs+10 yp+35, Sleep variance `%:
			Gui, Add, Edit, Number Right xs+145 yp-2 w45 vEdit_Inject_SleepVariance
				Gui, Add, UpDown,  Range0-100000 vInject_SleepVariance, % (Inject_SleepVariance - 1) * 100  

			Gui, Add, Checkbox, xs+10 y+12 vInject_RestoreSelection checked%Inject_RestoreSelection%, Restore Unit Selection 					
			Gui, Add, Checkbox, xs+10 y+10 vInject_RestoreScreenLocation checked%Inject_RestoreScreenLocation%, Restore Screen Location
			
		Gui, Add, GroupBox, xs ys+250 w400 h70, Notes:
			Gui, Add, Text,yp+57 xp+10 yp+25 w380, This is a semi-automated function. Each time the hotkey is pressed your hatches will be injected.

		hide := !instr(auto_inject, "Backspace")
		Gui, Add, GroupBox, w200 h230 ys xs+210 section hidden%hide% vBackspaceGroupBoxID, Backspace Settings
			Gui, Add, Text, xs+10 yp+25 hidden%hide% vBackspaceTextCameraStoreID, Create Camera: %A_space% %A_space% (Location Storge)
				Gui, Add, Edit, Readonly y+10 xs+60 w90 R1 center vBI_create_camera_pos_x hidden%hide%, %BI_create_camera_pos_x%
					Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#BI_create_camera_pos_x hidden%hide%,  Edit

			Gui, Add, Text, xs+10 yp+40 hidden%hide% vBackspaceTextCameraGotoID, Camera Position: %A_space% %A_space% (Goto Location)
				Gui, Add, Edit, Readonly y+10 xs+60 w90 R1 center vBI_camera_pos_x hidden%hide%, %BI_camera_pos_x%
					Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#BI_camera_pos_x hidden%hide%,  Edit
			Gui, Add, Text, % "xs+10 yp+40 vBackspaceDragTextID hidden" (auto_inject != "Backspace"), Drag Origin:
			; Drag origin should be only be unhidden for true backspace method
			Gui, Add, DropDownList, % "x+60 yp-2 w50 vDrag_origin Choose" (Drag_origin = "Right" ? 2 : 1) " hidden" (auto_inject != "Backspace"), Left|Right


	Gui, Tab,  Settings

		Gui, Add, GroupBox, Y+15 w225 h270 section, Common Settings
			Gui, Add, Text, xs+10 yp+25, Spawn Larvae Key:
			Gui, Add, Edit, Readonly yp-2 xs+110 w65 R1 center vInject_spawn_larva, %Inject_spawn_larva%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#Inject_spawn_larva,  Edit

			Gui, Add, Text, xs+10 y+15, Control Group Storage:
			Gui, Add, DropDownList,  % "xp+160 yp-2 w45 center vInject_control_group gGUIControlGroupCheckInjects Choose" (Inject_control_group = 0 ? 10 : Inject_control_group), 1|2|3|4|5|6||7|8|9|0

			Gui, Add, Text, xs+10 y+15, Queen Control Group:
			; i have a dropdown menu now so user has to put a number, cant use another key as I use this to check the control groups
				Gui, Add, DropDownList,  % "xp+160 w45 center vMI_Queen_Group gGUIControlGroupCheckInjects Choose" (MI_Queen_Group = 0 ? 10 : MI_Queen_Group), 1|2|3|4|5|6|7||8|9|0
			;	Gui, Add, Edit, Readonly y+10 xs+60 w90 center vMI_Queen_Group, %MI_Queen_Group%
			;		Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#MI_Queen_Group,  Edit			

			Gui, Add, Text, xs+10 y+15, Max Queen Distance:`n%A_Space% %A_Space% (From Hatch)
				Gui, Add, Edit, Number Right xp+160 yp w45 vTT2_MI_QueenDistance
						Gui, Add, UpDown,  Range1-100000 vMI_QueenDistance, %MI_QueenDistance%	

			Gui, Add, Checkbox, xs+10 y+15 vCanQueenMultiInject checked%CanQueenMultiInject%, Queen Can Inject Multiple Hatcheries* 
			Gui, Add, Checkbox, xs+10 y+10 vInjectConserveQueenEnergy checked%InjectConserveQueenEnergy%, Conserve Queen Energy
			

			Gui, Add, Text, xs+10 y+20 w205, These settings apply to BOTH the one-button (manual) and fully automated injects.
		;Gui, Add, GroupBox, xs ys+210 w365 h165, Notes:
			



	Gui, Tab,  Info
			gui, font, norm bold s10
			Gui, Add, Text, X%OriginTabX% y+15 cFF0000, Note:
			gui, font, norm s11
			gui, Add, Text, w410 y+15, If a queen has inadequate energy (or is too far from her hatchery), her hatchery will not be injected. 
			gui, Add, Text, w410 y+20, The Minimap && Backspace CtrlGroup methods require queens to be hotkeyed. In other words, hatches without a nearby HOTKEYED queen will not be injected.
			gui, Add, Text, w410 y+20, Both Backspace methods require the camera hotkeys to be set.
			;gui, Add, Text, w410 y+20, Auto-Injects will not occur while the modifier keys are pressed.
			gui, font, norm s11
			gui, font, norm bold s10
			Gui, Add, Text, X%OriginTabX% y+20 cFF0000, Problems:
			gui, font, norm s11
			gui, Add, Text, w410 y+15, If you are consistently missing hatcheries while using the one button inject method, try increasing the sleep time. 
			gui, Add, Text, w410 y+15, If something really goes wrong, you can reload the program by pressing "RWin && space" three times.
			gui, font, norm s10
			gui, font, 		

	Gui, Tab,  Auto
		Gui, Add, GroupBox, y+15 w225 h215 section, Fully Automated Injects
			Gui, Add, Checkbox,xp+10 yp+30 vF_Inject_Enable checked%F_Inject_Enable%, Enable on match start
		
			Gui, Add, Text,y+15 xs+10 w140, Max injects per round: 
				Gui, Add, Edit, Number Right x+5 yp-2 w60 vTT_FInjectHatchMaxHatches
					Gui, Add, UpDown, Range1-100000 vFInjectHatchMaxHatches, %FInjectHatchMaxHatches%

			Gui, Add, Text,y+15 xs+10 w140, Check Hatches Every (ms): 
				Gui, Add, Edit, Number Right x+5 yp-2 w60 vTT_FInjectHatchFrequency
					Gui, Add, UpDown, Range0-100000 vFInjectHatchFrequency, %FInjectHatchFrequency%					

			Gui, Add, Text, y+15 xs+10 w140, APM Delay:
				Gui, Add, Edit, Number Right x+5 yp-2 w60 vTT_FInjectAPMProtection
					Gui, Add, UpDown,  Range0-100000 vFInjectAPMProtection, %FInjectAPMProtection%		

			Gui, Add, Text, xs+10 yp+30, Enable/Disable Hotkey:
				Gui, Add, Edit, Readonly y+10 xp+45 w120 R1 vF_InjectOff_Key center gedit_hotkey, %F_InjectOff_Key%
				Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#F_InjectOff_Key,  Edit				

		Gui, Add, GroupBox, xs ys+235 w400 h165, Notes:
		Gui, Add, Text, yp+57 xp+10 yp+25 w380,
		(LTrim 
		Auto injects will begin after you control group your queen to the correct (inject) queen control group.

		Auto injects are performed using the 'MiniMap' method. In addition to the normal rules, individual queens will not auto-inject while they are performing or queued to perform attacks, transfuses, build tumours, patrol, or spawn larvae.

		Please ensure you have correctly set the 'Common Settings' under the 'Settings' tab.
		)

	Gui, Tab,  Alerts
			Gui, Add, GroupBox, y+10 w417 h50 section, Alert Types
			Gui, Add, Checkbox, xp+10 yp+20 vW_inject_ding_on checked%W_inject_ding_on%, Windows Ding
			Gui, Add, Checkbox, x+80 yp vW_inject_speech_on checked%W_inject_speech_on%, Spoken Warning:
			;Gui, Add, Text,y+15, Spoken Warning:
			Gui, Add, Edit, x+10 yp-2 w115 vW_inject_spoken center R1, %w_inject_spoken%

		Gui, Add, GroupBox, w417 h75  xs ys+65 section, One Button Inject Alert
			Gui, Add, Checkbox, xs+10 yp+20 vauto_inject_alert checked%auto_inject_alert%, Enable
			Gui, Add, Text, x456 yp, Alert After (s): 
			Gui, Add, Edit, Number Right x+25 yp-2 w45 vTT_auto_inject_time
				Gui, Add, UpDown, Range1-100000 vauto_inject_time, %auto_inject_time% ;these belong to the above edit	
			Gui, Add, Text, xs+10 y+10 w400,  This will sound x (in game) seconds after your last one-button inject.

		Gui, Add, GroupBox,  w417 h105  xs ys+90 section, Advanced Inject Timer
			Gui, Add, Checkbox, xp+10 yp+20 vInjectTimerAdvancedEnable checked%InjectTimerAdvancedEnable%, Enable
				
			Gui, Add, Text, xs+10 yp+25 w95, Spawn Larvae Key:	
				Gui, Add, Edit, Readonly yp-2 x+15 w90 center R1 vInjectTimerAdvancedLarvaKey, %InjectTimerAdvancedLarvaKey%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#InjectTimerAdvancedLarvaKey,  Edit
					Gui, Add, Text, x+28 yp+4, Alert After (s): 
					Gui, Add, Edit, Number Right x+25 yp-2 w45 
						Gui, Add, UpDown, Range1-100000 vInjectTimerAdvancedTime, %InjectTimerAdvancedTime%
			Gui, Add, Text, xs+10 y+15 w400,  This will sound x (in game) seconds after your last inject.

		Gui, Add, GroupBox,  w417 h140 xs ys+120 section, Manual Inject Timer	;h185
				Gui, Add, Checkbox, xp+10 yp+20 vmanual_inject_timer checked%manual_inject_timer%, Enable
				Gui, Add, Text, xs+10 yp+25 w90, Start/Stop Hotkey:
				Gui, Add, Edit, Readonly yp-2 x+20 w90 R1 vinject_start_key center gedit_hotkey, %inject_start_key%
				Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#inject_start_key,  Edit
					Gui, Add, Text, x+28 yp+4, Alert After (s): 
					Gui, Add, Edit, Number Right x+25 yp-2 w45 
						Gui, Add, UpDown, Range1-100000 vmanual_inject_time, %manual_inject_time%				
				Gui, Add, Text, xs+10 yp+35 w90, Reset Hotkey:
				Gui, Add, Edit, Readonly yp-2 x+20 w90 R1 vinject_reset_key center gedit_hotkey, %inject_reset_key%
				Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#inject_reset_key,  Edit
				Gui, Add, Text, xs+10 y+15 w400,  This is a very basic timer. It simply sounds every x seconds.


	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vKeys_TAB, SC2 Keys|Set/Add Group|Invoke Group
		Gui, Add, GroupBox, w280 h185, Common Keys:
			Gui, Add, Text, xs+10 yp+30 w90, Pause Game: 
			Gui, Add, Edit, Readonly yp-2 x+10 w120 R1 center vpause_game , %pause_game%
			Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#pause_game,  Edit

			Gui, Add, Text, xs+10 yp+35 w90, Escape/Cancel:
			Gui, Add, Edit, Readonly yp-2 x+10 w120 R1 center vescape , %escape%
			Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#escape,  Edit

			Gui, Add, Text, xs+10 yp+35 w90, Base Camera:
			Gui, Add, Edit, Readonly yp-2 x+10 w120 R1 center vbase_camera , %base_camera%
			Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#base_camera,  Edit

			Gui, Add, Text, xs+10 yp+35 w90, Next Subgroup:
			Gui, Add, Edit, Readonly yp-2 x+10 w120 R1 center vNextSubgroupKey , %NextSubgroupKey%
			Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#NextSubgroupKey,  Edit

			Gui, Add, Text, xs+10 yp+35 w90, Select Army:
			Gui, Add, Edit, Readonly yp-2 x+10 w120 R1 center vSc2SelectArmy_Key , %Sc2SelectArmy_Key%
			Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#Sc2SelectArmy_Key,  Edit					

			gui, font, s10
			Gui, Add, Text,  xs+-15 y+50 +wrap, Ensure the following keys match the associated SC2 Functions.
			Gui, Add, Text,  xs+-15 y+5 +wrap, (either change these settings here or in the SC2 Hotkey options/menu)
			gui, font, 		

			Gui, Tab, Set/Add Group
			Gui, Add, GroupBox, x+25 Y+25 w175 h380 section, Add To Control Group Keys
			loop 10 
			{
				group := A_index -1
				if (A_index = 1)
					Gui, Add, Text, xs+20 ys+30 w10, %group%
				else 
					Gui, Add, Text, xs+20 y+15 w10, %group%
				Gui, Add, Edit, Readonly yp-2 x+15 w65 R1 center vAGAddToGroup%group%, % AGAddToGroup%group%
					Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#AGAddToGroup%group%,  Edit
			}

			Gui, Add, GroupBox, xs+205 Ys w175 h380 section, Set Control Group Keys
			loop 10 
			{
				group := A_index -1
				if (A_index = 1)
					Gui, Add, Text, xs+20 ys+30 w10, %group%
				else 
					Gui, Add, Text, xs+20 y+15 w10, %group%
				Gui, Add, Edit, Readonly yp-2 x+15 w65 R1 center vAGSetGroup%group%, % AGSetGroup%group%
					Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#AGSetGroup%group%,  Edit
			}
			Gui, Tab, Invoke Group 
			Gui, Add, GroupBox, x+25 Y+25 w175 h380 section, Invoke Control Group Keys
			loop 10 
			{
				group := A_index -1
				if (A_index = 1)
					Gui, Add, Text, xs+20 ys+30 w10, %group%
				else 
					Gui, Add, Text, xs+20 y+15 w10, %group%
				Gui, Add, Edit, Readonly yp-2 x+15 w65 R1 center vAGInvokeGroup%group%, % AGInvokeGroup%group%
					Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#AGInvokeGroup%group%,  Edit
			}

	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vWarnings_TAB, Supply||Macro|Workers|Warpgates|Detection List
	Gui, Tab, Supply	
	; Gui, Add, GroupBox, w420 h335, Supply				
		Gui, Add, Checkbox, X%XTabX% y+30 Vsupplyon checked%supplyon%, Enable Alert


				Gui, Add, GroupBox, X%XTabX% yp+35 w175 h260 section, Supply Ranges && Deltas

				Gui, font, italic
				Gui, Add, Text,xs+10 yp+25 w100, Warn When Below:
				Gui, font, 
					Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_sub_lowerdelta 
						Gui, Add, UpDown, Range1-200 Vsub_lowerdelta, %sub_lowerdelta%

				Gui, Add, Text,xs+10 y+15 w100, Low Range Cutoff:
					Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_supplylower
						Gui, Add, UpDown, Range1-200 Vsupplylower, %supplylower%

				Gui, font, italic 
				Gui, Add, Text,xs+10 y+15 w100,  Warn When Below: 
				Gui, font, 
					Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_sub_middelta
						Gui, Add, UpDown, Range1-200 Vsub_middelta, %sub_middelta%


				Gui, Add, Text,xs+10 y+15 w100, Middle Range Cutoff:
					Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_supplymid
						Gui, Add, UpDown, Range1-200 Vsupplymid, %supplymid%

				Gui, font, italic 
				Gui, Add, Text,xs+10 y+15 w100, Warn When Below: 
				Gui, font, 
					Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_sub_upperdelta
						Gui, Add, UpDown, Range1-200 Vsub_upperdelta, %sub_upperdelta%


				Gui, Add, Text,xs+10 y+15 w100, Upper Range Cutoff:
					Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_supplyupper
						Gui, Add, UpDown, Range1-200 Vsupplyupper, %supplyupper%		

				Gui, font, italic 
				Gui, Add, Text,xs+10 y+15 w100,  Warn When Below:
				Gui, font, 
					Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_above_upperdelta
						Gui, Add, UpDown, Range1-200 Vabove_upperdelta, %above_upperdelta%					

						2XTabX := XTabX -10
			Gui, Add, GroupBox, ys x+30 w200 h260, Warnings

				Gui, Add, Text,xp+10 yp+25 w125 section, Silent If Supply Below:
				Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_minimum_supply
				Gui, Add, UpDown, Range1-200 Vminimum_supply, %minimum_supply%	

				Gui, Add, Text,xs y+15 w125, Follow Up Warnings:
					Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_sec_supply
						Gui, Add, UpDown, Range0-200 Vsec_supply, %sec_supply%

				Gui, Add, Text,y+15 xs w125, Follow Up Delay:
					Gui, Add, Edit, Number Right x+10 yp-2 w45 vTT_additional_delay_supply
						Gui, Add, UpDown, Range0-200 Vadditional_delay_supply, %additional_delay_supply%

				Gui, Add, Text,y+15 xs w125, Spoken Warning:
					Gui, Add, Edit, w180 R1 Vw_supply center, %w_supply%

	Gui, Tab, Macro	
		Gui, Add, GroupBox, y+15 w185 h175 section, Minerals
			Gui, Add, Checkbox, xs+10 yp+20  Vmineralon checked%mineralon%, Enable Alert
			Gui, Add, Text, xs+10 y+10 w105, Trigger Amount:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_mineraltrigger
					Gui, Add, UpDown, Range1-20000 Vmineraltrigger, %mineraltrigger%

			Gui, Add, Text, xs+10 y+10 w105, Follow Up Warnings:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_sec_mineral
					Gui, Add, UpDown, Range0-20000 Vsec_mineral, %sec_mineral%

			Gui, Add, Text, xs+10 y+10 w105, Follow Up Delay:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_additional_delay_minerals
					Gui, Add, UpDown, Range1-20000 Vadditional_delay_minerals, %additional_delay_minerals%

			Gui, Add, Text, xs+10 y+5 w125, Spoken Warning:
				Gui, Add, Edit, w165 R1 Vw_mineral center, %w_mineral%		

		Gui, Add, GroupBox, xs y+20  w185 h205, Gas
			Gui, Add, Checkbox, xp+10 yp+20  Vgas_on checked%gas_on%, Enable Alert

			Gui, Add, Text, y+10 w105, Trigger Amount:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_gas_trigger
					Gui, Add, UpDown, Range1-20000 Vgas_trigger, %gas_trigger%

			Gui, Add, Text, xs+10 y+10 w105, Follow Up Warnings:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_sec_gas
					Gui, Add, UpDown, Range0-20000 Vsec_gas, %sec_gas%

			Gui, Add, Text, xs+10 y+10 w105, Follow Up Delay:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_additional_delay_gas
					Gui, Add, UpDown, Range1-20000 Vadditional_delay_gas, %additional_delay_gas%

			Gui, Add, Text, xs+10 y+5 w125, Spoken Warning:
				Gui, Add, Edit, w165 R1 Vw_gas center, %w_gas%		

		Gui, Add, GroupBox, xs+215 ys w185 h175 section Vmacro_R_TopGroup, Idle Worker	;h185
		GuiControlGet, macro_R_TopGroup, Pos, macro_R_TopGroup

			Gui, Add, Checkbox, xs+10 yp+20  Vidleon checked%idleon%, Enable Alert
			Gui, Add, Text, xs+10 y+10 w105, Trigger Amount:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_idletrigger
					Gui, Add, UpDown, Range1-20000 Vidletrigger, %idletrigger%

			Gui, Add, Text, xs+10 y+10 w105, Follow Up Warnings:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_sec_idle
					Gui, Add, UpDown, Range0-20000 Vsec_idle, %sec_idle%

			Gui, Add, Text, xs+10 y+10 w105, Follow Up Delay:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_additional_idle_workers
					Gui, Add, UpDown, Range1-20000 Vadditional_idle_workers, %additional_idle_workers%

			Gui, Add, Text, xs+10 y+5 w125, Spoken Warning:
				Gui, Add, Edit, w165 R1 Vw_idle center, %w_idle%

		
		Gui, Add, GroupBox, xs y+20 w185 h205 section, Geyser Oversaturation	;h185

			Gui, Add, Checkbox, xs+10 yp+20  VWarningsGeyserOverSaturationEnable checked%WarningsGeyserOverSaturationEnable%, Enable Alert
			Gui, Add, Text, xs+10 y+10 w105, Trigger Amount:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_WarningsGeyserOverSaturationMaxWorkers
					Gui, Add, UpDown, Range4-200 vWarningsGeyserOverSaturationMaxWorkers, %WarningsGeyserOverSaturationMaxWorkers%
		
			Gui, Add, Text, xs+10 y+10 w105, Trigger Time:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_WarningsGeyserOverSaturationMaxTime
					Gui, Add, UpDown, Range4-200 vWarningsGeyserOverSaturationMaxTime, %WarningsGeyserOverSaturationMaxTime%					

			Gui, Add, Text, xs+10 y+10 w105, Follow Up Warnings:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_WarningsGeyserOverSaturationFollowUpCount
					Gui, Add, UpDown, Range0-20000 vWarningsGeyserOverSaturationFollowUpCount, %WarningsGeyserOverSaturationFollowUpCount%

			Gui, Add, Text, xs+10 y+10 w105, Follow Up Delay:
				Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_WarningsGeyserOverSaturationFollowUpDelay
					Gui, Add, UpDown, Range1-20000 vWarningsGeyserOverSaturationFollowUpDelay, %WarningsGeyserOverSaturationFollowUpDelay%

			Gui, Add, Text, xs+10 y+5 w125, Spoken Warning:
				Gui, Add, Edit, w165 R1 VWarningsGeyserOverSaturationSpokenWarning center, %WarningsGeyserOverSaturationSpokenWarning%


	Gui, Tab, Workers
		;Gui, Add, GroupBox, y+20 x%macro_R_TopGroupX% w185 h205, Worker Production	

		Gui, Add, Button, x+90 y+30 w65 h25 vMacroWarningsWorkerTerranButtonGUI gGUIMacroWarningsWorkerDisplayRace, Terran
		Gui, Add, Button, x+20 w65 h25 gGUIMacroWarningsWorkerDisplayRace, Protoss
		Gui, Add, Button, x+20 w65 h25 gGUIMacroWarningsWorkerDisplayRace, Zerg
		
		GuiControlGet, MacroWarningsWorkerTerranButtonGUI, Pos
		for k, race in ["Terran", "Protoss", "Zerg"]
		{
			Gui, Add, GroupBox, % "x" MacroWarningsWorkerTerranButtonGUIx " y" (MacroWarningsWorkerTerranButtonGUIy + 50) " w235 h255 vMacroWarningsWorker" race "GroupBoxGUI hidden" (A_index != 1) , %race% Worker Production
			Gui, Add, Checkbox, % "xp+15 yp+25  VWarningsWorker" race "Enable checked" WarningsWorker%race%Enable " hidden" (A_index != 1) , Enable Alert
			Gui, Add, Text, y+10 section w125, Time Without Production:
				Gui, Add, Edit, % "Number Right x+15 yp-2 w65 vTT_WarningsWorker" race "TimeWithoutProduction hidden" (A_index != 1)
					Gui, Add, UpDown, % "Range1-20000 vWarningsWorker" race "TimeWithoutProduction hidden" (A_index != 1), % WarningsWorker%race%TimeWithoutProduction

			Gui, Add, Text,xs y+20 w125, Silenced Below:
				Gui, Add, Edit, % "Number Right x+15 yp-2 w65 vTT_WarningsWorker" race "MinWorkerCount hidden" (A_index != 1)
					Gui, Add, UpDown, % "Range0-20000 vWarningsWorker" race "MinWorkerCount hidden" (A_index != 1), % WarningsWorker%race%MinWorkerCount
			
			Gui, Add, Text,xs y+20 w125, Silenced Above:
				Gui, Add, Edit, % "Number Right x+15 yp-2 w65 vTT_WarningsWorker" race "MaxWorkerCount hidden" (A_index != 1)
					Gui, Add, UpDown, % "Range0-20000 vWarningsWorker" race "MaxWorkerCount hidden" (A_index != 1), % WarningsWorker%race%MaxWorkerCount

			Gui, Add, Text,xs y+20 w125, Follow Up Warnings:
				Gui, Add, Edit, % "Number Right x+15 yp-2 w65 vTT_WarningsWorker" race "FollowUpCount hidden" (A_index != 1)
					Gui, Add, UpDown, % "Range0-20000 vWarningsWorker" race "FollowUpCount hidden" (A_index != 1), % WarningsWorker%race%FollowUpCount

			Gui, Add, Text,xs y+10 w125, Follow Up Delay:
				Gui, Add, Edit, % "Number Right x+15 yp-2 w65 vTT_WarningsWorker" race "FollowUpDelay hidden" (A_index != 1)
					Gui, Add, UpDown, % "Range1-20000 vWarningsWorker" race "FollowUpDelay hidden" (A_index != 1), % WarningsWorker%race%FollowUpDelay

			Gui, Add, Text, xs y+10 w85, Warning:
				Gui, Add, Edit, % "yp x+20 W100 R1 vWarningsWorker" race "SpokenWarning center hidden" (A_index != 1), % WarningsWorker%race%SpokenWarning	
		}
	Gui, Tab, Warpgates
	Gui, Add, GroupBox, y+20 w410 h135, Forgotten Gateway/Warpgate Warning

			Gui, Add, Checkbox,xp+10 yp+25 Vwarpgate_warn_on checked%warpgate_warn_on%, Enable Alert

			Gui, Add, Text, y+10 section w105, Warning Count:
				Gui, Add, Edit,  Number Right x+5 yp-2 w55 vTT_sec_warpgate
					Gui, Add, UpDown, Range1-20000 Vsec_warpgate, %sec_warpgate%		

			Gui, Add, Text,  x%xtabx% y+10  w105, Warning Delay:
				Gui, Add, Edit,  Number Right x+5 yp-2 w55 vTT_delay_warpgate_warn
					Gui, Add, UpDown, Range1-20000 Vdelay_warpgate_warn, %delay_warpgate_warn%			

			Gui, Add, Text, x%xtabx% y+10  w105, Follow Up Delay:
				Gui, Add, Edit,  Number Right x+5 yp-2 w55 vTT_delay_warpgate_warn_followup
					Gui, Add, UpDown, Range1-20000 Vdelay_warpgate_warn_followup, %delay_warpgate_warn_followup%						

			Gui, Add, Text, x+30 ys w75, Warning:
				Gui, Add, Edit, yp-2 x+10 w110 R1 Vw_warpgate center, %w_warpgate%		
		
		Gui, Font, s10 BOLD
		Gui, add, text, xs ys+110 cRED, Note:
		Gui, Font, s9 norm
		;Gui, Font, s10 norm
		Gui, add, text, xp+50 yp w340, These warnings will become active AFTER you convert your first warpgate.`n`nThe gateway will also be marked on the minimap providing the 'Display Alerts' option is enabled. (MiniMap/Overlays-->General)
		;Gui, Font, s9 norm	

	Gui, Tab, Detection List
		loop, parse, l_GameType, `,
			BAS_on_%A_LoopField% := alert_array[A_LoopField, "Enabled"]
		
		Gui, Add, GroupBox, x+45 y+60 w120 h110 section, Enable Warnings
			Gui, Add, Checkbox, xp+15 yp+25 vBAS_on_1v1 checked%BAS_on_1v1%, 1v1
			Gui, Add, Checkbox, x+15 yp vBAS_on_2v2 checked%BAS_on_2v2%, 2v2
			Gui, Add, Checkbox, xs+15 y+15 vBAS_on_3v3 checked%BAS_on_3v3%, 3v3
			Gui, Add, Checkbox, x+15 yp vBAS_on_4v4 checked%BAS_on_4v4%, 4v4
			Gui, Add, Checkbox, xs+15 y+15 vBAS_on_FFA checked%BAS_on_FFA%, FFA 
		
		Gui, Add, GroupBox, Xs+140 ys w200 h55, Playback Last Alert
			Gui, Add, Checkbox, xp+10 yp+25 vEnableLastAlertPlayBackHotkey checked%EnableLastAlertPlayBackHotkey%, Enable 			
			;Gui, Add, Text, xp+10 yp+25 w40,Hotkey:
				Gui, Add, Edit, Readonly yp-2 x+5 w80 R1 center vPlayback_Alert_Key , %Playback_Alert_Key%
					Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#Playback_Alert_Key,  Edit	
		Gui, Font, s10
		Gui, Add, Button, center Xs+140 ys+60 w200 h50 gAlert_List_Editor vAlert_List_Editor, Launch Alert List Editor
		Gui, Font,

	Gui, Add, GroupBox, Xs ys+130 w340 h145, About
		Gui, Add, Text, xp+15 yp+25 w320, 
		(LTrim 
		This function provides a verbal warning for the specified item (unit/building).

		It can also display a visual 'X' marker on the minimap, thereby indicating the items location.

		To enable this visual feature check the 'Display Alerts' checkbox listed under MiniMap/Overlays --> MiniMap --> General.
		)	


	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vMisc_TAB, Misc Abilities
		Gui, Add, GroupBox, w240 h150 section, Misc Hotkeys

			;Gui, Add, Text, xp+10 yp+30 w80, Worker Count:
			Gui, Add, Checkbox, xs+10 yp+25 w95 vEnableWorkerCountSpeechHotkey checked%EnableWorkerCountSpeechHotkey%, Worker Count:
				Gui, Add, Edit, Readonly yp-2 xp+100 w80 R1 center Vworker_count_local_key , %worker_count_local_key%
					Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#worker_count_local_key, Edit

			; I don't know whats up with AHK, but had to change edit box to yp+2. Something to do with check box and check box text positioning
			;Gui, Add, Text, X%XTabX% yp+35 w80, Enemy Workers:
			Gui, Add, Checkbox, xs+10 yp+35 w95 vEnableEnemyWorkerCountSpeechHotkey checked%EnableEnemyWorkerCountSpeechHotkey%, Enemy Workers:
				Gui, Add, Edit, Readonly yp+2 xp+100 w80 R1 center Vworker_count_enemy_key, %worker_count_enemy_key%
					Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#worker_count_enemy_key, Edit		

			;Gui, Add, Text, X%XTabX% yp+35 w80, Trainer On/Off:
			Gui, Add, Checkbox, xs+10 yp+35 w95 vEnableToggleMacroTrainerHotkey checked%EnableToggleMacroTrainerHotkey%, Trainer On/Off:
				Gui, Add, Edit, Readonly yp-2 xp+100 w80  R1 center Vwarning_toggle_key , %warning_toggle_key%
					Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#warning_toggle_key, Edit

			;Gui, Add, Text, X%XTabX% yp+35 w80, Ping Map:
			Gui, Add, Checkbox, xs+10 yp+35 w95 vEnablePingMiniMapHotkey checked%EnablePingMiniMapHotkey%, Ping Map:
				Gui, Add, Edit, Readonly yp-2 xp+100 w80 R1 center Vping_key, %ping_key%
					Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#ping_key, Edit

		Gui, Add, GroupBox, x+20 ys w160 h150, Announce Spawning Races
			Gui, Add, Checkbox, xp+10 yp+30 vAuto_Read_Races checked%Auto_Read_Races%, Run on match start
			Gui, Add, Checkbox, yp+30 Vrace_reading checked%race_reading%, Enable Hotkey
			;Gui, Add, Checkbox, y+10 Vrace_speech checked%race_speech%, Speak Races
			;Gui, Add, Checkbox, y+10 Vrace_clipboard checked%race_clipboard%, Copy to Clipboard

			;Gui, Add, Text, yp+20 w20, Hotkey:
				Gui, Add, Edit, Readonly yp+25 w100 center Vread_races_key , %read_races_key%
					Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#read_races_key,  Edit

		Gui, Add, GroupBox, xs ys+160 w410 h110, Auto Game Pause - Idle/AFK@Start

		Gui, Add, Checkbox,xp+10 yp+25 Vidle_enable checked%idle_enable%, Enable
		;	Gui, Add, Checkbox,xp+10 yp+25 Vidle_enable checked0 disabled, Enable

			Gui, Add, Text,xp y+10, User Idle Time:
				Gui, Add, Edit,  Number Right x+10 yp-2 w40 vTTidle_time  
					Gui, Add, UpDown, Range1-20000 Vidle_time , %idle_time%
			tmpX := XTabX+200
				Gui, Add, Text, X%tmpX% yp-25 w105, Don't Pause Before:
					Gui, Add, Edit,  Number Right x+5 yp-2 w40 vTTUserIdle_LoLimit 
						Gui, Add, UpDown, Range1-20000 VUserIdle_LoLimit , %UserIdle_LoLimit%

				Gui, Add, Text, X%tmpX% y+10 w105 vTTTUserIdle_HiLimit , Don't Pause After:
					Gui, Add, Edit,  Number Right x+5 yp-2 w40  vTTUserIdle_HiLimit 
						Gui, Add, UpDown, Range1-20000 VUserIdle_HiLimit , %UserIdle_HiLimit%					

			Gui, Add, Text, x%xtabx% y+10, Chat Message:
				Gui, Add, Edit, yp-2 x+10 w310 Vchat_text center, %chat_text%	

		Gui, Add, GroupBox, xs y+20 w410 h140 section, Misc		
			Gui, Add, Checkbox, xs+10 yp+25 VMaxWindowOnStart Checked%MaxWindowOnStart%, Maximise Starcraft on match start		
			Gui, Add, Checkbox, xs+10 yp+30 gHumanMouseWarning VHumanMouse Checked%HumanMouse%, Use human like mouse movements
			Gui, Add, Text, yp+30 xs+10, Time range for each mouse movement (ms):
			Gui, Add, Text, yp xs+240, Lower limit:
			Gui, Add, Edit, Number Right x+25 yp-2 w45 
				Gui, Add, UpDown,  Range1-300 vHumanMouseTimeLo, %HumanMouseTimeLo%, ;these belong to the above edit		Gui, Add, Text,yp xp+10, Lower limit:
			Gui, Add, Text,yp+30 xs+240, Upper limit:
			Gui, Add, Edit, Number Right x+25 yp-2 w45 
				Gui, Add, UpDown,  Range1-300 vHumanMouseTimeHi, %HumanMouseTimeHi%, ;these belong to the above edit



	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vSettings_TAB, Settings				
		Gui, Add, GroupBox, w161 h110 section, Misc
			Gui, Add, Checkbox, xp+10 yp+25 vSC2AdvancedEnlargedMinimap gSC2AdvancedEnlargedMinimapWarning checked%SC2AdvancedEnlargedMinimap%, SC2Advanced Minimap
/*
			Gui, Add, Text, xs+10 yp+35 w60, Send Delay:
			Gui, Add, Edit, Number Right x+30 yp-2 w45 vTT_pSendDelay
				Gui, Add, UpDown,  Range-1-300 vpSendDelay, %pSendDelay%

			Gui, Add, Text, xs+10 yp+40 w60, Click Delay:
			Gui, Add, Edit, Number Right x+30 yp-2 w45 vTT_pClickDelay
				Gui, Add, UpDown,  Range-1-300 vpClickDelay, %pClickDelay%
*/
			
			;yp+30

		Gui, Add, GroupBox, xs ys+115 w161 h85, Launcher 
			Gui, Add, Radio, % "xp+10 yp+25 vLauncherRadioBattleNet checked" (LauncherMode = "Battle.net"), Battle.net 
			Gui, Add, Radio, % "vLauncherRadioStarCraft checked" (LauncherMode = "Starcraft"), Starcraft 
			Gui, Add, Radio, % "vLauncherRadioDisabled checked" (LauncherMode = "Off" || (LauncherMode != "Battle.net" && LauncherMode != "Starcraft")), Disabled 

		Gui, Add, GroupBox, xs ys+205 w161 h80, Key Blocking
			Gui, Add, Checkbox, xp+10 yp+25 vLwinDisable checked%LwinDisable%, Disable Left Windows Key
		;	Gui, Add, Checkbox,xp+10 yp+25 vBlockingStandard checked%BlockingStandard%, Standard Keys	
		;	Gui, Add, Checkbox, y+10 vBlockingFunctional checked%BlockingFunctional%, Functional F-Keys 	
		;	Gui, Add, Checkbox, y+10 vBlockingNumpad checked%BlockingNumpad%, Numpad Keys	
		;	Gui, Add, Checkbox, y+10 vBlockingMouseKeys checked%BlockingMouseKeys%, Mouse Buttons	
		;	Gui, Add, Checkbox, y+10 vBlockingMultimedia checked%BlockingMultimedia%, Mutimedia Buttons	
			

		Gui, Add, GroupBox, xs ys+290 w161 h60, Updates
			Gui, Add, Checkbox,xs+10 yp+25 Vauto_update checked%auto_update%, Auto Check For Updates

	/*
		Gui, Add, GroupBox, xs yp+35 w161 h60, Unit Deselection
			Gui, Add, Text, xp+10 yp+25, Sleep Time:
			Gui, Add, Edit, Number Right x+25 yp-2 w45 vTT_DeselectSleepTime
				Gui, Add, UpDown,  Range0-300 vDeselectSleepTime, %DeselectSleepTime%,
	*/

		Gui, Add, GroupBox, Xs+171 ys w245 h110, Volume
			Gui, Add, Text, xp+10 yp+30 w45, Speech:
				Gui, Add, Slider, ToolTip  NoTicks w140 x+2 yp-2  Vspeech_volume, %speech_volume%
					Gui, Add, Button, x+5 yp w30 h23 vTest_VOL_Speech gTest_VOL, Test

			Gui, Add, Text, xs+181 y+15 w45, Overall:
				Gui, Add, Slider, ToolTip  NoTicks w140 x+2 yp-2  VprogramVolume, %programVolume%
					Gui, Add, Button, x+5 yp w30 h23 vTest_VOL_All gTest_VOL, Test

		Gui, Add, GroupBox, Xs+171 ys+116 w245 h170, Debugging
			Gui, Add, Button, % "xp+10 yp+25 GdebugListVars w75 h25 disabled" round(A_IsCompiled),  List Variables
			Gui, Add, Button, xp+90 yp gDrawSCUIOverlay  w75 h25, SC UI Pos
			Gui, Add, Button, xp yp+30 gPerformPatternScan  w75 h25, Pattern Scan
			Gui, Add, Button, xp-90 yp  Gg_GetDebugData w75 h25,  Debug Data
			Gui, Add, Button, xp yp+30  Gg_DebugKey w75 h25,  Key States
			Gui, Add, Button, xp+90 yp gDebugSCHotkeys  w75 h25, SC Hotkeys
			Gui, Add, Button, xp-90 yp+30  GdegbugGUIStats vdegbugGUIVar w75 h25, Control Pos

			


		Gui, Add, GroupBox, Xs+171 ys+290 w245 h60, Emergency Restart Key
			Gui, Add, Text, xp+10 yp+25 w40,Hotkey:
				Gui, Add, Edit, Readonly yp-2 x+15 w100 R1 center vKey_EmergencyRestart , %Key_EmergencyRestart%
					Gui, Add, Button, yp-2 x+15 gEdit_hotkey v#Key_EmergencyRestart,  Edit	

		Gui, Add, GroupBox, Xs ys+360 w161 h60, Custom Program Name
		Gui, Add, Text, xp+10 yp+25 w40,Name:
			Gui, Add, Edit, yp-2 x+5 w100 R1 center vMTCustomProgramName, %MTCustomProgramName%

		; Can't just use the menu, Icon change command to change the icon, 
		; as the compiled icon will still show up in the sound mixer
		; hence have to change the internal compiled icon
		; Also as using resource hacker to change icon, cant use mpress :(
		; so the compiled exe will be ~4x bigger!
		Gui, Add, GroupBox, Xs+171 ys+360 w245 h60, Custom Icon
			;	Gui, Add, Edit, Readonly yp-2 x+15 w100  center vKey_EmergencyRestart , %Key_EmergencyRestart%

				A_Iscompiled ? icon := A_ScriptFullPath : icon := "Starcraft-2-32x32.ico"
				Gui, Add, Picture,  xp+35 yp+18 vMTIconPreview gG_MTChageIcon w35 h-1, %icon%
				Gui, Add, Button, x+30 yp+10 vMTChageIconButton Gg_MTChageIcon, Change 
				Gui, Add, Button, x+10 vMTChageIconDefaultButton Gg_MTChageIconDefault, Default 
				;Gui, Add, Edit, Readonly yp-2 xp-90 w80 Hidden vMTCustomIcon , %MTCustomIcon% ; invis and used to store the name

	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vBug_TAB, Bug Report
		Gui, Add, Text, x+60 y+20 section, Your Email Address:%A_Space%%A_Space%%A_Space%%A_Space%%A_Space%(optional) 
		Gui, Add, Edit, xp y+10 w350 vReport_Email,
		Gui, Add, Text, xp y+10, Problem Description:


	BugText =  
	(ltrim

	A return email address is REQUIRED if you are looking for a follow up to your query.

	Bugs may not occur on all systems, so please be as SPECIFIC as possible when describing the problem.

	Screenshots and replays may be attached below.

	(please remove this text when filling in this form).

	)
		Gui, Add, Edit, xp y+10 w350 h160 vReport_TXT, %BugText%

		GUI, Add, ListView, xp y+15 w350 H100 vEmailAttachmentListViewID, Attachments
		LV_Add("", A_ScriptDir "\" config_file) ;includes the MT_Config.ini file ; this can not be removed by the user	
		LV_ModifyCol()  ; Auto-size all columns to fit their contents
		Gui, Add, Button, xp-55 yp+40 w50 h25 gg_AddEmailAttachment, Add
		Gui, Add, Button, xp yp+35 w50 h25 gg_RemoveEmailAttachment, Remove
		Gui, Add, Button, vB_Report gB_Report xp+195 y+8 w80 h50, Send

	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vChronoBoost_TAB, Settings||Items
	Gui, Tab, Settings	
		Gui, Add, GroupBox, w190 h160 x+15 y+25 section, SC2 Keys && Control Groups			
			Gui, Add, Text, xp+10 yp+25 , Storage Ctrl Group:
			Gui, Add, DropDownList,  % "xs+125 yp w45 center gGUIControGroupCheckChrono vCG_control_group Choose" (CG_control_group = 0 ? 10 : (CG_control_group = "Off" ? 11 : CG_control_group)), 1|2|3|4|5|6|7||8|9|0|Off
				
			;	Gui, Add, Edit, Readonly xp+25 y+10  w100  center vCG_control_group , %CG_control_group%
			;		Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#CG_control_group,  Edit				
			Gui, Add, Text, xs+10 yp+35, Nexus Ctrl Group:
			Gui, Add, DropDownList, % "xs+125 yp w45 center gGUIControGroupCheckChrono vCG_nexus_Ctrlgroup_key Choose" (CG_nexus_Ctrlgroup_key = 0 ? 10 : CG_nexus_Ctrlgroup_key), 1|2|3|4||5|6|7|8|9|0
			;	Gui, Add, Edit, Readonly xp+25 y+10  w100  center vCG_nexus_Ctrlgroup_key , %CG_nexus_Ctrlgroup_key%
			;		Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#CG_nexus_Ctrlgroup_key,  Edit		
			Gui, Add, Text, xs+10 yp+35 ,Chrono Boost Key:
				Gui, Add, Edit, Readonly xp+25 y+10  w100 R1 center vchrono_key , %chrono_key%
					Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#chrono_key,  Edit	

		Gui, Add, GroupBox, xs ys+180 w190 w400 h220, About
			Gui, Add, Text, xp+10 yp+25 w380, % "This is a semi-automatic function. It allows you to create a group of structures which will be chronoed "
											. "when the assigned hotkey is pressed.`n`n"
											. "Structures are chronoed according to their listed order in the group (higher structures come first).`n`n"
											. "For structures of the same type, structures with larger production queues will chronoed first."
											. "When structures have an equal queue size, they will be chronoed in order of progress (lowest first). "
											. "Structures which are idle (or not on cooldown), already chronoed, or have no additional queued units and a progress of 95% or greater will not be chronoed."
											. "`n`nGateways which are being converted to warpgates will be chronoed before gateways which have a unit in production."

		Gui, Add, GroupBox, ys xs+210  w190 h160 section, Misc. Settings				
			Gui, Add, Text, xp+10 yp+25, Sleep time (ms):
			Gui, Add, Edit, Number Right xp+120 yp-2 w45 vTT_ChronoBoostSleep 
				Gui, Add, UpDown,  Range0-1000 vChronoBoostSleep, %ChronoBoostSleep%						
			Gui, Add, Text, xs+10 yp+35, Chrono Remainder:`n    (1 = 25 mana)
			Gui, Add, Edit, Number Right xp+120 yp-2 w45 vTT_CG_chrono_remainder 
				Gui, Add, UpDown,  Range0-1000 vCG_chrono_remainder, %CG_chrono_remainder%		



	Gui, Tab, Items

	aAutoChronoCopy["IndexGUI"] := 1
	if !aAutoChronoCopy["MaxIndexGUI"]
		aAutoChronoCopy["MaxIndexGUI"] := 1

	Gui, Add, GroupBox, x+25 Y+25 w380 h65 section vGroupBoxAutoChrono, % " Chrono Navigation " aAutoChronoCopy["IndexGUI"] " of " aAutoChronoCopy["MaxIndexGUI"]
		 Gui, Add, Button, xp+15 yp+25 w65 h25 vPreviousAutoChrono gAutoChronoGui, Previous
		 Gui, Add, Button, x+20 w65 h25 vNextAutoChrono gAutoChronoGui, Next
		 Gui, Add, Button, x+45 w65 h25 vNewAutoChrono gAutoChronoGui, New
		 Gui, Add, Button, x+20 w65 h25 vDeleteAutoChrono gAutoChronoGui, Delete

	Gui, Add, GroupBox, xs Ys+85 w380 h280 section vGroupBoxItemAutoChrono, % "Chrono Item " aAutoChronoCopy["IndexGUI"] 
		Gui, Add, Checkbox, xs+15 yp+25 vAutoChronoEnabled gGUIAutoChronoEnableCheck, Enable all structures
		Gui, Add, Checkbox, xs+15 yp+25 vAutoChronoSelectionEnabled gGUIAutoChronoEnableCheck, Enable selection mode
		Gui, Add, Text, yp+30, Hotkey:
			Gui, Add, Edit, Readonly yp-2 x+10 center w65 R1 vAutoChrono_Key gedit_hotkey, %A_Space%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#AutoChrono_Key,  Edit	
		
		; Specify -LV0x10 to prevent the user from dragging column headers to the left or right to reorder them.
		; But this doesn't stop them resizing the only column. I could Auto resize after every event like the unit panel LV does.
		; This is aligned with New and Delete buttons above
		Gui, Add, ListView, section xs+210 ys+25 r11 w150 vAutoChronoListView -LV0x10 NoSortHdr NoSort, Structures/Order

		Gui, Add, Button, xs ys+220 gAddUnitAutoChrono vAddUnitAutoChrono hWndhWndButton w25 h25 ;y+6
		GuiButtonIcon(hWndButton, A_Temp "\MacroTrainerFiles\GUI\Add Plus Green.ico", 1, "w15 h15 a4")
		Gui, Add, Button, x+10 gRemoveUnitAutoChrono vRemoveUnitAutoChrono hWndhWndButton w25 h25
		GuiButtonIcon(hWndButton, A_Temp "\MacroTrainerFiles\GUI\Remove Minus Red.ico", 1, "w15 h15 a4")
		Gui, Add, Button, x+30 yp gMoveUpUnitAutoChrono vMoveUpUnitAutoChrono hWndhWndButton w25 h25
		GuiButtonIcon(hWndButton, A_Temp "\MacroTrainerFiles\GUI\Up Arrow Blue.ico", 1, "w15 h15 a4")
		Gui, Add, Button, x+10 yp gMoveDownUnitAutoChrono vMoveDownUnitAutoChrono hWndhWndButton w25 h25
		GuiButtonIcon(hWndButton, A_Temp "\MacroTrainerFiles\GUI\Down Arrow Blue.ico", 1, "w15 h15 a4")

		state := aAutoChronoCopy["MaxIndexGUI"] > 1 ? True : False
		GUIControl, Enable%state%, NextAutoChrono
		GUIControl,  Enable%state%, PreviousAutoChrono
		showAutoChronoItem(aAutoChronoCopy)
Gui, Add, Button, x402 y430 gg_ChronoRulesURL w150, Rules/Criteria

	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vAutoGroup_TAB, Terran|Protoss|Zerg|Delays|Info||Info2	
	Short_Race_List := "Terr|Prot|Zerg"
	loop, parse, Short_Race_List, |
	{
		if (A_LoopField = "Terr")
		{	Gui, Tab, Terran
			Tmp_LongRace := "Terran"
		}
		Else if (A_LoopField = "Prot")
		{	Gui, Tab, Protoss
			Tmp_LongRace := "Protoss"
		}
		Else 
		{	Gui, Tab, Zerg
			Tmp_LongRace := "Zerg"
		}
		checked := A_UnitGroupSettings["AutoGroup", Tmp_LongRace, "Enabled"]
		AGX := MenuTabX + 20, AGY := MenuTabY +50
		Gui, Add, Checkbox, X%AGX%  Y%AGY%  vAG_Enable_%A_LoopField% checked%checked%, Enable Auto Grouping
		checked := A_UnitGroupSettings["LimitGroup", Tmp_LongRace, "Enabled"]
	;	Gui, Add, Checkbox, X%AGX% Y+10 v%Tmp_LongRace%_LimitGroup checked%checked%, Restrict Unit Grouping
		Gui, Add, Text, yp X540 Center, Restrict Unit`nGrouping:
		XLeft := XTabX - 10
		loop, 10
		{		
			if (10 = i := A_Index)	; done like this so 0 comes after 9
				i := 0
			Units := A_UnitGroupSettings[Tmp_LongRace, i]

			Gui, add, text, y+20 X%XLeft%, Group %i%
			Gui, Add, Edit, yp-2 x+10 w280  center r1 vAG_%Tmp_LongRace%%i%, %Units%
		;	Gui, Add, Edit, yp-2 x+10 w280  center r1 vAG_%A_LoopField%%i%, %Units%
		;	Gui, Add, Button, yp-2 x+10 gEdit_AG v#AG_%A_LoopField%%i%,  Edit ;old
			Gui, Add, Button, yp-2 x+10 gEdit_AG v#AG_%Tmp_LongRace%%i%,  Edit
			checked := A_UnitGroupSettings["LimitGroup", Tmp_LongRace, i,"Enabled"]
			Gui, Add, Checkbox, yp+4 x+20 vLG_%Tmp_LongRace%%i% checked%checked%
		}	
	}

	Gui, Tab, Info
		Gui, Font, s10
		Gui, Font, s10 BOLD
		Gui, add, text, x+25 y+12 w380,Auto Unit Grouping
		Gui, Font, s10 norm
		Gui, add, text, xp y+15 w380,
		(LTrim
		This function will add selected units to their predetermined control groups, providing:

		• One of the selected units in not in said control group.
		• All of the selected units 'belong'  in this control group.

		Units are added after all keys/buttons have been released.
		)
		Gui, Font, s10 BOLD
		Gui, add, text, y+15 w380,Restrict Unit Grouping
		Gui, Font, s10 norm
		Gui, add, text, y+15 w380,
		(LTrim
		If units have been specified for a particular control group, when manually control grouping (add-to or set group), only these preselected units can be added to that control group.

		If the selection contains a unit which doesn't belong in this group, the grouping command will be ignored.

		This prevents erroneously adding units to a control group.

		Any unit can be added to a blank control group.
		)
		Gui, Font, s10 BOLD
		Gui, add, text, xp y+12 cRED, Note:
		Gui, Font, s10 norm
		Gui, add, text, xp+50 yp w340, Auto and Restrict Unit grouping functions are not exclusive, i.e. they can be used together or alone!
		Gui, Font, s9 norm	

	Gui, Tab, Info2
		Gui, Font, s10
		Gui, Font, s10 BOLD
		Gui, add, text, x+25 y+12 w380, SC Key Setup
		Gui, Font, s10 norm
		Gui, add, text, xp y+15 w380,
		(LTrim
		When using Auto-Grouping you must ensure the corresponding group keys listed in "Set Control Group keys" match your SC2 hotkey setup. (under SC2 Keys on the left)

		Restrict unit grouping uses both "Add To Control Group Keys" and "Set Control Group keys". 
		)
		Gui, Font, s10 BOLD
		Gui, add, text, xp y+12 w380, Reliability
		Gui, Font, s10 norm
		Gui, add, text, xp y+20 w380, 
		(LTrim 
		Due to how SC works, it's impossible for an external program like MacroTrainer to perform auto-groupings with 100`% accuracy.

		This function will work perfectly for some, average for others, or it may be completely unusable.

		Increasing the "Key Event Delay" and the "Safety Buffer" within the delays section should help prevent misgroupings. 
		(Read their associated tooltips for more information)
		)
		Gui, Font, s9 norm

	Gui, Tab, Delays
		Gui, Add, GroupBox, x+25 Y+25 w175 h120 section, Auto Grouping
			Gui, Add, Text, xs+10 ys+35 w90, Key Event Delay (ms):
			Gui, Add, Edit, Number Right x+20 yp-2 w45 vTT_AGKeyReleaseDelay
			Gui, Add, UpDown,  Range50-700 vAGKeyReleaseDelay , %AGKeyReleaseDelay%
			
			Gui, Add, Text, xs+10 y+25 w90, Safety Buffer (ms):
			Gui, Add, Edit, Number Right x+20 yp-2 w45 vTT_AGBufferDelay 
			Gui, Add, UpDown,  Range40-200 vAGBufferDelay , %AGBufferDelay%

		Gui, Add, GroupBox, xs+205 ys w175 h120 section, Restrict Grouping
			Gui, Add, Text, xs+10 ys+35 w90, Safety Buffer (ms):
			Gui, Add, Edit, Number Right x+20 yp-2 w45 vTT_AGRestrictBufferDelay 
			Gui, Add, UpDown,  Range40-200 vAGRestrictBufferDelay , %AGRestrictBufferDelay%
			
	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vQuickSelect_TAB, Terran||Protoss|Zerg|Info

	loop, parse, l_Races, `,
	{	

		Gui, Tab, %A_LoopField%

		aQuickSelectCopy[A_LoopField "IndexGUI"] := 1
		if !aQuickSelectCopy[A_LoopField "MaxIndexGUI"]
			aQuickSelectCopy[A_LoopField "MaxIndexGUI"] := 1

		Gui, Add, GroupBox, x+10 Y+5 w410 h55 section vGroupBox%A_LoopField%QuickSelect, % " Quick Select Navigation " aQuickSelectCopy[A_LoopField "IndexGUI"] " of " aQuickSelectCopy[A_LoopField "MaxIndexGUI"]
			 Gui, Add, Button, xp+15 yp+20 w65 h25 vPrevious%A_LoopField%QuickSelect gg_QuickSelectGui, Previous
			 Gui, Add, Button, x+20 w65 h25 vNext%A_LoopField%QuickSelect gg_QuickSelectGui, Next
			 Gui, Add, Button, x+75 w65 h25 vNew%A_LoopField%QuickSelect gg_QuickSelectGui, New
			 Gui, Add, Button, x+20 w65 h25 vDelete%A_LoopField%QuickSelect gg_QuickSelectGui, Delete

		Gui, Add, GroupBox, xs Ys+65 w410 h355 section vGroupBoxItem%A_LoopField%QuickSelect, % "Quick Select Item " aQuickSelectCopy[A_LoopField "IndexGUI"] 

			Gui, Add, Checkbox, xs+25 yp+20 vquickSelect%A_LoopField%Enabled, Enable
			;Gui, Add, Text, y+10, Hotkey:
			Gui, Add, Groupbox, xs+15 y+10 w180 h50, Hotkey
				Gui, Add, Edit, Readonly xp+10 yp+20 center w105 R1 vquickSelect%A_LoopField%_Key gedit_hotkey, %A_Space%
			Gui, Add, Button, yp-2 x+15 gEdit_hotkey v#quickSelect%A_LoopField%_Key,  Edit	
			Gui, Add, Groupbox, xs+15 y+20 w180 h50, Starting Selection 
			Gui, Add, DropDownList, xp+10 yp+20 w105 center vQuickSelect%A_LoopField%BaseSelection gQuickSelectGUBaseSelectionZergTransportCheck Choose1, Army|Units On Screen|Current Selection|Control Group 1|Control Group 2|Control Group 3|Control Group 4|Control Group 5|Control Group 6|Control Group 7|Control Group 8|Control Group 9|Control Group 0
			
			Gui, Add, Groupbox, xs+15 y+20 width w180 h180, Filter Unit Types
			Gui, Add, Checkbox, xp+10 yp+20 vquickSelect%A_LoopField%SelectUnitTypes gQuickSelectGUISelectTypesCheck, Keep these types
			Gui, Add, Checkbox, xp y+5 vquickSelect%A_LoopField%DeselectUnitTypes gQuickSelectGUISelectTypesCheck, Remove these types
			;Gui, Add, Text, xs+15 y+10, Units
			Gui, Add, Edit, y+5 w160  r6 vquickSelect%A_LoopField%UnitsArmy, %A_Space%
			Gui, Add, Button, y+6 gEdit_AG v#quickSelect%A_LoopField%UnitsArmy w160 h25,  Add

			Gui, Add, Groupbox, xs+225 ys+20 width w170 h65, Store Selection
			Gui, Add, Checkbox, xp+10 yp+20 vquickSelect%A_LoopField%CreateControlGroup gQuickSelectGUICreateAddToGroupCheck, Create group
			Gui, Add, Checkbox, xp y+10 vquickSelect%A_LoopField%AddToControlGroup gQuickSelectGUICreateAddToGroupCheck, Add to group
			Gui, Add, DropDownList, x+15 yp-3 w45 center vQuickSelect%A_LoopField%StoreSelection Choose10, 1|2|3|4|5|6|7|8|9|0|

			Gui, add, GroupBox, xs+225 ys+90 w170 h256, Modify By Attributes
			Gui, add, Text, xp+10 yp+25, Mode: 
			Gui, Add, DropDownList, x+15 yp-3 w90 center vQuickSelect%A_LoopField%AttributeMode Choose1, Remove|Keep

			Gui, Add, Checkbox, xs+235 y+10 vquickSelect%A_LoopField%DeselectXelnaga, Holding Xelnaga tower
			Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectPatrolling, Patrol
			Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectAttacking, Attack	
			Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectFollowing, Follow
			Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectHoldPosition, Hold position
			Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectIdle, Idle		
			Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectLoadedTransport gQuickSelectGUIEmptyLoadedTransportCheck, Loaded transports
			Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectEmptyTransport gQuickSelectGUIEmptyLoadedTransportCheck, Empty transports
			Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectQueuedDrops, Transports queued to drop
			if A_LoopField = Protoss 
			{
				Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectHallucinations, Hallucinations
				Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectLowHP, Shield`% below:
			}
			else 
			{ 
				; Technically i shouldn't disable for zerg and should have a shield level as they can make protoss units via neural parasiting probes/sentries but thats never gonna happen
				Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectHallucinations disabled, Hallucinations
				Gui, Add, Checkbox, Xp y+5 vquickSelect%A_LoopField%DeselectLowHP, HP`% below:
			} 
			Gui, Add, Edit, Number Right x+10 yp-3 w45 vEdit_quickSelect%A_LoopField%DeselectLowHP
				Gui, Add, UpDown,  Range1-99 vquickSelect%A_LoopField%HPValue, 40
		
		state := aQuickSelectCopy[A_LoopField "MaxIndexGUI"] > 1 ? True : False
		GUIControl, Enable%state%, Next%A_LoopField%QuickSelect
		GUIControl,  Enable%state%, Previous%A_LoopField%QuickSelect
		showQuickSelectItem(A_LoopField, aQuickSelectCopy)
	}

	Gui, Tab, Info
		Gui, add, GroupBox, section y+25 w405 h305
		Gui, Font, s10 BOLD
		Gui, add, text, xs+10 ys+25 w380, Quick Select 
		;Gui, Font, s10 norm
		Gui, Font, s9 norm
		Gui, add, text, xp+10 y+15 w360, 
		( LTrim
			This is a powerful feature with many possible uses.

			In its simplest form, it allows you to instantly select any number of unit types with a single hotkey. In other words, it is like selecting a predefined control group, but you never have to issue the initial grouping command.		

			Structures are automatically removed, however non-army units (workers, queens, mules, overlords etc) are not. If the starting selection is set to anything other than 'Army' and you are not specifying the unit types to keep, you should consider enabling the 'Remove these types' option and specifying these non-army units there.
		)
		Gui, Font, s10 BOLD
		Gui, add, text, xp y+25 cRed, Note:
		Gui, Font, s9 norm
		Gui, add, text, xp+10 y+10 w360, You will need to ensure the keys found under 'SC2 keys' (on the left) match your SC2 hotkey.

		;Gui, Font, s9
	;	Gui, add, text, xp y+15 w380, Test 
		;Gui, add, text, xp y+15 w380, Test 


	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vAutoWorker_TAB, Auto||Info
	;Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vAutoWorker_TAB, Auto||Info		
	Gui, Tab, Auto
		Gui, Add, GroupBox, x+25 Y+10 w370 h85 section, General 
		Gui, Add, Text, xp+10 yp+20, Toggle State:

			Gui, Add, Edit, Readonly yp-2 x+10 center w65 R1 vToggleAutoWorkerState_Key gedit_hotkey, %ToggleAutoWorkerState_Key%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleAutoWorkerState_Key,  Edit ;have to use a trick eg '#' as cant write directly to above edit var, or it will activate its own label!

		Gui, Add, Text, xs+10 y+15 w85, APM Delay:
			Gui, Add, Edit, Number Right x+4 yp-2 w50 vTT_AutoWorkerAPMProtection
					Gui, Add, UpDown,  Range0-100000 vAutoWorkerAPMProtection, %AutoWorkerAPMProtection%		

	;	Gui, Add, Text, xs+220 yp+25 w85, Queue While Supply Blocked:			
		Gui, Add, Checkbox, xs+205 ys+20 vAutoWorkerQueueSupplyBlock Checked%AutoWorkerQueueSupplyBlock%, Queue while supply blocked
		Gui, Add, Checkbox, xp yp+20 vAutoWorkerAlwaysGroup Checked%AutoWorkerAlwaysGroup%, Always group selection **  
		Gui, Add, Checkbox, xp yp+20 vAutoWorkerWarnMaxWorkers Checked%AutoWorkerWarnMaxWorkers%, Max worker warning

		thisXTabX := XTabX + 12
		Gui, Add, GroupBox, xs ys+98 w370 h150 section, Terran 
			Gui, Add, Checkbox, xp+10 yp+25 vEnableAutoWorkerTerranStart Checked%EnableAutoWorkerTerranStart%, Enable on match start

			Gui, Add, Text, X%thisXTabX% y+15 w100, Base Ctrl Group:
				if (Base_Control_Group_T_Key = 0)
					droplist_var := 10
				else 
					droplist_var := Base_Control_Group_T_Key  	; i have a dropdown menu now so user has to put a number, cant use another key as I use this to check the control groups
				Gui, Add, DropDownList,  xs+130 yp w45 center gGUIControlGroupCheckAutoWorkerTerran vBase_Control_Group_T_Key Choose%droplist_var%, 1|2|3|4|5|6|7|8|9|0

			Gui, Add, Text, X%thisXTabX% yp+35 w100, Storage Ctrl Group:
				if (AutoWorkerStorage_T_Key = 0)
					droplist_var := 10
				else 
					droplist_var := AutoWorkerStorage_T_Key  	; i have a dropdown menu now so user has to put a number, cant use another key as I use this to check the control groups
				Gui, Add, DropDownList,  xs+130 yp w45 center gGUIControlGroupCheckAutoWorkerTerran vAutoWorkerStorage_T_Key Choose%droplist_var%, 1|2|3|4|5|6|7|8|9|0


			Gui, Add, Text, X%thisXTabX% yp+35 w100, Make SCV Key:
			Gui, Add, Edit, Readonly yp-2 x+2 w65 R1 center vAutoWorkerMakeWorker_T_Key, %AutoWorkerMakeWorker_T_Key%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#AutoWorkerMakeWorker_T_Key,  Edit

			Gui, Add, Text, xs+240 ys+55, Max SCVs:
				Gui, Add, Edit, Number Right x+15 yp-2 w45 vTT_AutoWorkerMaxWorkerTerran
						Gui, Add, UpDown,  Range1-100000 vAutoWorkerMaxWorkerTerran, %AutoWorkerMaxWorkerTerran%		

			Gui, Add, Text, xs+240 yp+35, Max SCVs:`n(Per Base)
				Gui, Add, Edit, Number Right x+15 yp w45 vTT_AutoWorkerMaxWorkerPerBaseTerran
						Gui, Add, UpDown,  Range1-100000 vAutoWorkerMaxWorkerPerBaseTerran, %AutoWorkerMaxWorkerPerBaseTerran%	


		Gui, Add, GroupBox, xs ys+165 w370 h150 section, Protoss 
			Gui, Add, Checkbox, xp+10 yp+25 vEnableAutoWorkerProtossStart Checked%EnableAutoWorkerProtossStart%, Enable on match start

			Gui, Add, Text, X%thisXTabX% y+15 w100, Base Ctrl Group:
				if (Base_Control_Group_P_Key = 0)
					droplist_var := 10
				else 
					droplist_var := Base_Control_Group_P_Key  	; i have a dropdown menu now so user has to put a number, cant use another key as I use this to check the control groups
				Gui, Add, DropDownList, xs+130 yp w45 center gGUIControlGroupCheckAutoWorkerProtoss vBase_Control_Group_P_Key Choose%droplist_var%, 1|2|3|4|5|6|7|8|9|0

			Gui, Add, Text, X%thisXTabX% yp+35 w100, Storage Ctrl Group:
				if (AutoWorkerStorage_P_Key = 0)
					droplist_var := 10
				else 
					droplist_var := AutoWorkerStorage_P_Key  	; i have a dropdown menu now so user has to put a number, cant use another key as I use this to check the control groups
				Gui, Add, DropDownList,  xs+130 yp w45 center gGUIControlGroupCheckAutoWorkerProtoss vAutoWorkerStorage_P_Key Choose%droplist_var%, 1|2|3|4|5|6|7|8|9|0	

			Gui, Add, Text, X%thisXTabX% yp+35 w100, Make Probe Key:
			Gui, Add, Edit, Readonly yp-2 x+2 w65 R1 center vAutoWorkerMakeWorker_P_Key, %AutoWorkerMakeWorker_P_Key%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#AutoWorkerMakeWorker_P_Key,  Edit

			Gui, Add, Text, xs+240 ys+55, Max Probes:
				Gui, Add, Edit, Number Right x+15 yp-2 w45 vTT_AutoWorkerMaxWorkerProtoss
						Gui, Add, UpDown,  Range1-100000 vAutoWorkerMaxWorkerProtoss, %AutoWorkerMaxWorkerProtoss%		

			Gui, Add, Text, xs+240 yp+35, Max Probes:`n(Per Base)
				Gui, Add, Edit, Number Right x+15 yp w45 vTT_AutoWorkerMaxWorkerPerBaseProtoss
						Gui, Add, UpDown,  Range1-100000 vAutoWorkerMaxWorkerPerBaseProtoss, %AutoWorkerMaxWorkerPerBaseProtoss%	

	Gui, Tab, Info
			gui, font, norm bold s10
			Gui, Add, Text, X%OriginTabX% y+15 cFF0000, Note:
			gui, font, norm s11

			gui, Add, Text, w400 y+15, When trying to lift a Command Centre or Orbital, or convert a Command Centre into an orbital, an SCV will likely already be queued.
			gui, Add, Text, w400 y+15, There's no need to toggle (turn off) this function, simply  select the building/base (so that only ONE unit is selected e.g. the CC) and press the 'ESCAPE' button to cancel the queued worker.
			gui, Add, Text, w400 y+15, This will temporarily disable the function for four seconds - providing adequate time to convert or lift the Command Centre.
			gui, Add, Text, w400 y+15, This also works if you need to cancel a probe to make a mumma ship core.

			gui, Add, Text, w400 y+20, Although you will most likely not notice this, workers will not be produced while:
			;gui, Add, Text, w400 y+5, • The control, alt, shift, or windows keys are held down.
			gui, Add, Text, w400 y+5, • A spell is being cast (includes attack)
			gui, Add, Text, w400 y+5, • The construction card i.e. the basic or advanced building card is displayed.
			gui, Add, Text, w400 y+5, • A non-self unit is selected e.g. a mineral patch or an enemy/allied unit (or no unit is selected).

			gui, font, norm s10
			gui, font, 		

	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vAutoBuild_TAB, Notes||Settings|GUI|Hotkeys|	
	
	Gui, Tab, Notes 
		Gui, add, GroupBox, y+25 w400 h130, Note
		gui, add, text, xp+10 yp+25 w380, 
		( Ltrim off 			
			This feature is still under development and relies on a number of new functions, including reading the active SC hotkey profile.
			
			If you experience any issues please submit a bug report.

			Refining unit production vs. resource allowance is on the to-do list e.g. balancing simultaneous hellion and tank production while mineral starved.
		)
		
	Gui, Tab, Settings 
		Gui, add, GroupBox, y+10 w400 h195, Structure Control Group
		Gui, Add, Text, section xp+15 yp+25, Barracks:
		Gui, Add, DropDownList,  % "xp+100 yp-2 w40 center vAutoBuildBarracksGroup Choose" (AutoBuildBarracksGroup = 0 ? 10 : AutoBuildBarracksGroup), 1|2|3|4|5||6|7|8|9|0

		Gui, Add, Text, xs, Factory:
		Gui, Add, DropDownList,  % "xp+100 yp-2 w40 center vAutoBuildFactoryGroup Choose" (AutoBuildFactoryGroup = 0 ? 10 : AutoBuildFactoryGroup), 1|2|3|4|5||6|7|8|9|0

		Gui, Add, Text, xs, Starport:
		Gui, Add, DropDownList,  % "xp+100 yp-2 w40 center vAutoBuildStarportGroup Choose" (AutoBuildStarportGroup = 0 ? 10 : AutoBuildStarportGroup), 1|2|3|4|5||6|7|8|9|0

		Gui, Add, Text, xs+220 ys, Gateway:
		Gui, Add, DropDownList,  % "xp+100 yp-2 w40 center vAutoBuildGatewayGroup Choose" (AutoBuildGatewayGroup = 0 ? 10 : AutoBuildGatewayGroup), 1|2|3|4|5||6|7|8|9|0
	
		Gui, Add, Text, xs+220 y+10, Stargate:
		Gui, Add, DropDownList,  % "xp+100 yp-2 w40 center vAutoBuildStargateGroup Choose" (AutoBuildStargateGroup = 0 ? 10 : AutoBuildStargateGroup), 1|2|3|4|5||6||7|8|9|0
	
		Gui, Add, Text, xs+220 y+10, Robotics Facility:
		Gui, Add, DropDownList,  % "xp+100 yp-2 w40 center vAutoBuildRoboticsFacilityGroup Choose" (AutoBuildRoboticsFacilityGroup = 0 ? 10 : AutoBuildRoboticsFacilityGroup), 1|2|3|4|5|6||7|8|9|0
	
		Gui, Add, Text, xs yp+30, Hatchery:
		Gui, Add, DropDownList,  % "xp+100 yp-2 w40 center vAutoBuildHatcheryGroup Choose" (AutoBuildHatcheryGroup = 0 ? 10 : AutoBuildHatcheryGroup), 1|2|3|4||5|6|7|8|9|0
	
		Gui, Add, Text, xs, Lair:
		Gui, Add, DropDownList,  % "xp+100 yp-2 w40 center vAutoBuildLairGroup Choose" (AutoBuildLairGroup = 0 ? 10 : AutoBuildLairGroup), 1|2|3|4||5|6|7|8|9|0
	
		Gui, Add, Text, xs, Hive:
		Gui, Add, DropDownList,  % "xp+100 yp-2 w40 center vAutoBuildHiveGroup Choose" (AutoBuildHiveGroup = 0 ? 10 : AutoBuildHiveGroup), 1|2|3|4||5|6|7|8|9|0

		Gui, add, GroupBox, xs-15 y+25 section w400 h100, Guaranteed Free Resources

		Gui, Add, Text, xp+10 ys+25, Minerals:
			Gui, Add, Edit, Number Right xp+50 yp-2 w50 vTT_autoBuildMinFreeMinerals
					Gui, Add, UpDown,  Range0-3000 vAutoBuildMinFreeMinerals, %autoBuildMinFreeMinerals%	
		Gui, Add, Text, x+35 ys+25, Gas:
			Gui, Add, Edit, Number Right xp+50 yp-2 w50 vTT_autoBuildMinFreeGas
					Gui, Add, UpDown,  Range0-3000 vAutoBuildMinFreeGas, %autoBuildMinFreeGas%	
		Gui, Add, Text, x+35  ys+25, Supply:
			Gui, Add, Edit, Number Right xp+50 yp-2 w50 vTT_autoBuildMinFreeSupply
					Gui, Add, UpDown,  Range0-20 vAutoBuildMinFreeSupply, %autoBuildMinFreeSupply%	
		Gui, Add, Text, xs+10 y+15 w380, This helps to ensure you have enough resources to build depots/pylons and to start upgrades. 

		Gui, add, GroupBox, xs+140 ys+115 w125 h60, APM Delay 
		;Gui, Add, Text, xs section y+25 w85, APM Delay:
			Gui, Add, Edit, Number Right xp+30 yp+25 w50 vTT_automationAPMThreshold
					Gui, Add, UpDown,  Range0-100000 vAutomationAPMThreshold, %automationAPMThreshold%	

		Gui, add, GroupBox, xs ys+115 w125 h100, Control Group Storage 
		Gui, Add, Text, xp+10 yp+25 section, Terran:
		Gui, Add, DropDownList,  % "xp+60 yp-2 w45 center vAutomationTerranCtrlGroup Choose" (AutomationTerranCtrlGroup = 0 ? 10 : AutomationTerranCtrlGroup), 1|2|3|4||5|6|7|8|9|0
		Gui, Add, Text, xs, Protoss:
		Gui, Add, DropDownList,  % "xp+60 yp-2 w45 center vAutomationProtossCtrlGroup Choose" (AutomationProtossCtrlGroup = 0 ? 10 : AutomationProtossCtrlGroup), 1|2|3|4||5|6|7|8|9|0
		Gui, Add, Text, xs, Zerg:
		Gui, Add, DropDownList,  % "xp+60 yp-2 w45 center vAutomationZergCtrlGroup Choose" (AutomationZergCtrlGroup = 0 ? 10 : AutomationZergCtrlGroup), 1|2|3|4||5|6|7|8|9|0

	Gui, Tab, GUI
		
		Gui, add, GroupBox, y+10 w325 h275 section, Settings
		Gui, Add, Text, section xp+15 yp+25, Hotkey Mode:
		Gui, Add, DropDownList, yp-2 xp+130 vAutoBuildGUIkeyMode gAutoBuildOptionsMenuHotkeyModeCheck, Toggle||KeyDown
		GuiControl, ChooseString, AutoBuildGUIkeyMode, %AutoBuildGUIkeyMode%		

		Gui, Add, Checkbox, xs y+10 vAutoBuildEnableGUIHotkey checked%AutoBuildEnableGUIHotkey%, In-game GUI:
		Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vAutoBuildGUIkey gedit_hotkey, %AutoBuildGUIkey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#AutoBuildGUIkey, Edit
		
		Gui, Add, Checkbox, section xs y+20 vAutoBuildEnableInteractGUIHotkey gAutoBuildOptionsMenuHotkeyModeCheck checked%AutoBuildEnableInteractGUIHotkey%, Interact Key
		Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vAutoBuildInteractGUIKey gedit_hotkey, %AutoBuildInteractGUIKey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#AutoBuildInteractGUIKey, Edit 

		Gui, add, text, xs y+10 w40 vInactiveOpacticyTextAssociatedVariable, Inactive Opacity:
			Gui, Add, Slider, NoTicks w210 x+10 yp+4 vAutoBuildInactiveOpacity range30-255, %AutoBuildInactiveOpacity%
		Gui, Add, Checkbox, xs y+15 vAutoBuildGUIAutoWorkerToggle checked%AutoBuildGUIAutoWorkerToggle%, Include worker button
		Gui, Add, Checkbox, xs vAutoBuildGUIAutoWorkerPause checked%AutoBuildGUIAutoWorkerPause%, Pause button disables worker production 
		Gui, Add, Checkbox, xs vAutoBuildGUIAutoWorkerOffButton checked%AutoBuildGUIAutoWorkerOffButton%, Off button disables worker production 
		gui, add, text, xs yp+25 w295, *Worker production is performed using the auto worker function. Therefore you must also configure that function if you wish to build workers.

		Gui, add, GroupBox, xs-15 y+20 w325 h125 section, About 
		gui, add, text, xp+15 yp+25 w295, 
		( ltrim off 
			This GUI/overlay is the primary method used to control auto production. Like other overlays it may be moved, however it cannot be resized.
			
			Right clicking anywhere inside this GUI will produce the same result as pressing the GUI 'pause' button. Middle clicking is equivalent to pressing the 'off' button.
		)

		gosub, AutoBuildOptionsMenuHotkeyModeCheck

	Gui, Tab, Hotkeys
		GUI, Add, button, gLaunchAutoBuildEditor +disabled, Profile Editor
		Gui, Add, Checkbox, vAutoBuildEnablePauseAllHotkey checked%autoBuildEnablePauseAllHotkey% +disabled, Pause All 
		Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vAutoBuildPauseAllkey gedit_hotkey +disabled, %AutoBuildPauseAllkey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#AutoBuildPauseAllkey +disabled, Edit

	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vMiscAutomation_TAB, Select Army||Spread|Remove Units|Easy Select/Unload|Smart Geyser
	Gui, Tab, Select Army
		Gui, add, GroupBox, y+15 w405 h130 section, Select Army
		Gui, Add, Checkbox, Xs+15 yp+25 vSelectArmyEnable Checked%SelectArmyEnable% , Enable Select Army Function		
		Gui, Add, Text, yp+35, Hotkey:
		Gui, Add, Edit, Readonly yp-2 xs+85 center w65 R1 vcastSelectArmy_key gedit_hotkey, %castSelectArmy_key%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#castSelectArmy_key,  Edit ;have to use a trick eg '#' as cant write directly to above edit var, or it will activate its own label!

		;Gui, Add, Checkbox, Xs yp+35 vSelectArmyControlGroupEnable Checked%SelectArmyControlGroupEnable%, Control group the units
		Gui, Add, Text, Xs+15 yp+35 w70, Ctrl Group:
		Gui, Add, DropDownList,  % "xs+85 yp w45 Center vSc2SelectArmyCtrlGroup Choose" (Sc2SelectArmyCtrlGroup = 0 ? 10 : (Sc2SelectArmyCtrlGroup = "Off" ? 11 : Sc2SelectArmyCtrlGroup)), 1|2|3|4|5|6|7||8|9|0|Off||

		;Gui, Add, Edit, Readonly yp-2 xs+85 w65 center vSc2SelectArmyCtrlGroup , %Sc2SelectArmyCtrlGroup%
		;	Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#Sc2SelectArmyCtrlGroup,  Edit
	
		;Gui, Add, Text, Xs yp+40, Deselect These Units:
		Gui, add, GroupBox, xs y+35 w405 h155, Deselect These Units
		Gui, Add, Checkbox, Xs+15 yp+25 vSelectArmyDeselectXelnaga Checked%SelectArmyDeselectXelnaga%, Xelnaga (tower) units
		Gui, Add, Checkbox, xs+215 yp vSelectArmyOnScreen Checked%SelectArmyOnScreen%, Outside of camera view
		Gui, Add, Checkbox, Xs+15 yp+20 vSelectArmyDeselectPatrolling Checked%SelectArmyDeselectPatrolling%, Patrolling units
		Gui, Add, Checkbox, xs+215 yp vSelectArmyDeselectFollowing Checked%SelectArmyDeselectFollowing%, On follow command
		Gui, Add, Checkbox, Xs+15 yp+20 vSelectArmyDeselectQueuedDrops Checked%SelectArmyDeselectQueuedDrops%, Transports queued to drop
		Gui, Add, Checkbox, xs+215 yp vSelectArmyDeselectHoldPosition Checked%SelectArmyDeselectHoldPosition%, On hold position
		Gui, Add, Checkbox, Xs+15 yp+20 vSelectArmyDeselectLoadedTransport Checked%SelectArmyDeselectLoadedTransport%, Loaded transports
		
		Gui, add, text, Xs+15 y+20, Units:
		Gui, Add, Edit, yp-2 x+10 w300 center r1 vl_DeselectArmy, %l_DeselectArmy%
		Gui, Add, Button, yp-2 x+10 gEdit_AG v#l_DeselectArmy,  Edit

		Gui, Font, s10 BOLD
		Gui, add, text, xs+15 y+30 cRed, Note:
		Gui, Font, s10 norm
		Gui, add, text, xs+15 y+10 w380, You will need to ensure the 'Select Army' key found under 'SC2 keys'->'Common' (on the left) matches your SC2 hotkey.
		Gui, Font, s9		

	Gui, Tab, Spread
		Gui, Add, Checkbox, y+25 x+25 vSplitUnitsEnable Checked%SplitUnitsEnable% , Enable Spread Unit Function	
		Gui, Add, Text, section yp+35, Hotkey:
		Gui, Add, Edit, Readonly yp-2 xs+85 center w65 R1 vcastSplitUnit_key gedit_hotkey, %castSplitUnit_key%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#castSplitUnit_key,  Edit
		Gui, Add, Text, Xs yp+35 w70, Ctrl Group Storage:
		Gui, Add, DropDownList,  % "xs+85 yp w45 Center vSplitctrlgroupStorage_key Choose" (SplitctrlgroupStorage_key = 0 ? 10 : SplitctrlgroupStorage_key), 1|2|3|4|5|6|7|8|9||0

		Gui, Add, Text, Xs yp+100 w360, This can be used to spread your workers when being attack by hellbats/hellions.`n`nWhen 30`% of the selected units are worksers, the units will be spread over a much larger area
		Gui, Add, Text, Xs yp+80 w360, Note: When spreading army/attacking units this is designed to spread your units BEFORE the engagement - Dont use it while being attacked!`n`n****This is in a very beta stage and will be improved later***

	Gui, Tab, Remove Units
		Gui, add, GroupBox, y+15 w405 h165 section, Remove Single Unit
			Gui, Add, Checkbox, yp+25 xs+15 vRemoveUnitEnable Checked%RemoveUnitEnable%, Enable	
			Gui, Add, Text, xp yp+25, Hotkey:
			Gui, Add, Edit, Readonly yp-2 xs+105 center w65 R1 vcastRemoveUnit_key gedit_hotkey, %castRemoveUnit_key%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#castRemoveUnit_key,  Edit
			Gui, Add, Text, Xs+15 yp+45 w360, This removes the first unit (top left of selection card) from the selected units.`n`nThis is useful for 'cloning' workers to geisers or sending 1 ling towards a group of banelings etc.
		Gui, add, GroupBox, xs ys+195 w405 h190, Remove Damaged Units
			Gui, Add, Checkbox, yp+25 xs+15 vRemoveDamagedUnitsEnable Checked%RemoveDamagedUnitsEnable%, Enable	
			Gui, Add, Text, xp yp+25, Hotkey:
			Gui, Add, Edit, Readonly yp-2 xs+64 center w65 R1 vcastRemoveDamagedUnits_key gedit_hotkey, %castRemoveDamagedUnits_key%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#castRemoveDamagedUnits_key,  Edit	
			Gui, Add, Text, xs+15 yp+35, Storage Group:
			Gui, Add, DropDownList,  % "xs+125 yp w45 Center vRemoveDamagedUnitsCtrlGroup Choose" (RemoveDamagedUnitsCtrlGroup = 0 ? 10 : RemoveDamagedUnitsCtrlGroup), 1|2|3|4|5|6|7|8|9||0

			Gui, Add, Text, xs+15 yp+35, Shield Level `%:
			Gui, Add, Edit, Number Right xs+125 yp-2 w45 vEdit_RemoveDamagedUnitsShieldLevel
				Gui, Add, UpDown,  Range1-99 vRemoveDamagedUnitsShieldLevel, % Round(RemoveDamagedUnitsShieldLevel * 100) 

			Gui, Add, Text, xs+15 yp+35, Health Level `%:
			Gui, Add, Edit, Number Right xs+125 yp-2 w45 vEdit_RemoveDamagedUnitsHealthLevel
				Gui, Add, UpDown,  Range1-99 vRemoveDamagedUnitsHealthLevel, % Round(RemoveDamagedUnitsHealthLevel * 100) 

			Gui, Add, Text, X380 y284 w195, Units with health/shields lower than the specified values will be removed from selection and moved to the current mouse cursor position each time the hotkey is pressed. Stalkers will be blinked.`n`nThis is very helpful when microing small numbers of units!
	
	Gui, Tab, Easy Select/Unload
		Gui, Add, GroupBox, x+65 y+15 w95 h50 w205 section, Enable Easy Select/Cursor Unload 
			Gui, Add, Checkbox, xp+10 yp+25 vEasyUnloadTerranEnable Checked%EasyUnloadTerranEnable%, Terran	
			Gui, Add, Checkbox, x+10 yp vEasyUnloadProtossEnable Checked%EasyUnloadProtossEnable%, Protoss	
			Gui, Add, Checkbox, x+10 yp vEasyUnloadZergEnable Checked%EasyUnloadZergEnable%, Zerg
	
		Gui, Add, GroupBox, xs+230 ys w100 h110, Storage Ctrl Group
		;Gui, Add, Text, xs+10 yp+35, Storage Ctrl Group:
			if (EasyUnloadStorageKey = 0)
				droplist_var := 10
			else 
				droplist_var := EasyUnloadStorageKey  	; i have a dropdown menu now so user has to put a number, cant use another key as I use this to check the control groups
			Gui, Add, DropDownList,  xp+20 yp+50 w45 center vEasyUnloadStorageKey Choose%droplist_var%, 1|2|3|4|5|6|7|8|9|0


		Gui, Add, GroupBox, xs ys+60 w95 h50 w205, Enable Unload All
			Gui, Add, Checkbox, xp+10 yp+25 vEasyUnloadAllTerranEnable Checked%EasyUnloadAllTerranEnable%, Terran	
			Gui, Add, Checkbox, x+10 yp vEasyUnloadAllProtossEnable Checked%EasyUnloadAllProtossEnable%, Protoss	
			Gui, Add, Checkbox, x+10 yp vEasyUnloadAllZergEnable Checked%EasyUnloadAllZergEnable%, Zerg
			


		Gui, Add, GroupBox, xs y+25 w205 h55, Easy Select/Cursor Unload  Hotkey
			Gui, Add, Text, Xp+10 yp+25 w85, Hotkey:
				Gui, Add, Edit, Readonly yp-2 xs+85 center w65 R1 vEasyUnloadHotkey gedit_hotkey, %EasyUnloadHotkey%
				Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#EasyUnloadHotkey,  Edit 	

	;		Gui, Add, Text, Xs+10 yp+35 w85, Queued:
	;			Gui, Add, Edit, Readonly yp-2 xs+85 center w65 vEasyUnloadQueuedHotkey gedit_hotkey, %EasyUnloadQueuedHotkey%
	;			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#EasyUnloadQueuedHotkey,  Edit 			
		
		Gui, Add, GroupBox, xs y+25 w205 h120, SC2 Unload All Key / Unload All Hotkey
			Gui, Add, Text, Xp+10 yp+25 w85, Terran:
			Gui, Add, Edit, Readonly yp-2 xs+85 w65 R1 center vEasyUnload_T_Key, %EasyUnload_T_Key%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#EasyUnload_T_Key,  Edit
			
			Gui, Add, Text, Xs+10 yp+35 w85, Protoss:
			Gui, Add, Edit, Readonly yp-2 xs+85 w65 R1 center vEasyUnload_P_Key, %EasyUnload_P_Key%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#EasyUnload_P_Key,  Edit
			
			Gui, Add, Text, Xs+10 yp+35 w85, Zerg:
			Gui, Add, Edit, Readonly yp-2 xs+85 w65 R1 center vEasyUnload_Z_Key, %EasyUnload_Z_Key%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#EasyUnload_Z_Key,  Edit
		Gui, Add, GroupBox, xs y+25 w205 h60, How-To Guide
			Gui, Font, s11     
			Gui, Add, Button, xp+30 yp+25 w50 h25 ggYoutubeEasyUnload, Video
			Gui, Add, Button, x+45 yp w50 h25 ggEasyUnloadDescription, About
			Gui, Font,

/*
	Gui, Add, Tab2, w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vAutoMine_TAB, Settings||Hotkeys|
	Gui, Tab, Settings	
		Gui, Add, GroupBox, y+20 w195 h300 section, Settings
			Gui, Add, Checkbox, xp+10 yp+30 vAuto_mine checked%auto_mine%, Enable
			Gui, Add, Checkbox, yp+25 vAuto_mineMakeWorker checked%Auto_mineMakeWorker%, Make Worker
			Gui, Add, Checkbox, yp+25 vAuto_Mine_Set_CtrlGroup checked%Auto_Mine_Set_CtrlGroup%, Set Base Ctrl Group

			Gui, Add, Text,y+20 w85, Split Type: 
			if WorkerSplitType
				droplist3_var := substr(WorkerSplitType, 0, 1)
			else droplist3_var := 1
			Gui, Add, DropDownList, x+35 yp-2 w45 vWorkerSplitType Choose%droplist3_var%, 6x1|3x2||2x3	

			Gui, Add, Text, X%XTabX% y+20 w65, Method:
			droplist3_var := AutoMineMethod = "MiniMap" ? 2 : 1		
			Gui, Add, DropDownList, x+35 yp-2 w65 gg_GuiSetupAutoMine vAutoMineMethod Choose%droplist3_var%, Normal||MiniMap	

			Gui, Add, Text, X%XTabX% y+20 w85, Sleep (ms):castSplitUnit_key
			Gui, Add, Edit, Number Right x+35 yp-2 w45 vAuto_Mine_Sleep2
				Gui, Add, UpDown, Range1-100000 vTT_Auto_Mine_Sleep2, %Auto_Mine_Sleep2%		

			Gui, Add, Text, X%XTabX% y+20 w85, Input Delay (ms):
				Gui, Add, Edit, Number Right X+35 yp-2 w45 vTT_AM_KeyDelay
					Gui, Add, UpDown,  Range0-10 vAM_KeyDelay, %AM_KeyDelay%			

			Gui, Add, Text,X%XTabX% y+20 w85, Start Mining at (s): 
			Gui, Add, Edit, Number Right x+35 yp-2 w45 vStart_Mine_Time
				Gui, Add, UpDown, Range0-100000, %Start_Mine_Time%	
			Gui, Font, s10
			Gui, Add, Text,Xs y+40 , Note: The "Normal" method will only function at 1920 x 1080 resolution.
			Gui, Font,
			XMenu := 390
			Gui, Add, GroupBox, ys x%XMenu% w195 h300 vAMGUI1, MiniMap Settings
			Gui, Font, underline
			Gui, Add, Text, xp+10 yp+20 vAMGUI2, Pixel Colour
			Gui, Font
			XMenu += 30
			Gui, Add, Text, x%XMenu% y+15 w55 vAMGUI3, Alpha:
				Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MiniMap_PixelColourAlpha, %AM_MiniMap_PixelColourAlpha%
			Gui, Add, Text, x%XMenu% y+15 w55 vAMGUI4, Red:
				Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MiniMap_PixelColourRed, %AM_MiniMap_PixelColourRed%
			Gui, Add, Text, x%XMenu% y+15 w55 vAMGUI5, Green:
				Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MiniMap_PixelColourGreen, %AM_MiniMap_PixelColourGreen%
			Gui, Add, Text, x%XMenu% y+15 w55 vAMGUI6, Blue:
				Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MinsiMap_PixelColourBlue, %AM_MinsiMap_PixelColourBlue%

			Gui, Add, Button, x%XMenu% y+15 w60 h23 gg_GuiSetupResetPixelColour v#ResetPixelColour,  Reset	
			Gui, Add, Button, x+30 yp  w60 h23 gg_FindTestPixelColourMsgbox v#FindPixelColour,  Find	

			XMenu -= 20
			Gui, Add, Text,  x%XMenu% y+20 w85 vAMGUI7, Variance:
				Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MiniMap_PixelVariance
				Gui, Add, UpDown, Range0-100 vTT_AM_MiniMap_PixelVariance, %AM_MiniMap_PixelVariance%	
			Gui, Add, Button, xp-60 y+15 w60 h23 gg_PixelColourFinderHelpFile vAMGUI8,  About	
			gosub, g_GuiSetupAutoMine	;hide/show the minimap items



	Gui, Tab, Hotkeys	
	Gui, Add, GroupBox, xs y+20 w235 h210 section, SC2 HotKeys
			Gui, Add, Text, X%XTabX% yp+25  w80 , Idle Worker:
			Gui, Add, Edit, Readonly yp-2 x+10 w80  center vIdle_Worker_Key , %Idle_Worker_Key%
					Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Idle_Worker_Key,  Edit			
			Gui, Add, Text, X%XTabX% yp+30  w80, Gather Minerals:
			Gui, Add, Edit, Readonly yp-2 x+10 w80  center vGather_Minerals_key , %Gather_Minerals_key%
					Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Gather_Minerals_key,  Edit		
			Gui, Add, Text, X%XTabX% yp+30 w80 , Base Ctrl Group:
			Gui, Add, Edit, Readonly yp-2 x+10 w80  center vBase_Control_Group_Key , %Base_Control_Group_Key%
					Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Base_Control_Group_Key,  Edit	
			Gui, Add, Text, X%XTabX% yp+30  w80, Make SCV:
			Gui, Add, Edit, Readonly yp-2 x+10 w80  center vMake_Worker_T_Key , %Make_Worker_T_Key%
					Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Make_Worker_T_Key,  Edit			
			Gui, Add, Text, X%XTabX% yp+30  w80, Make Probe:
			Gui, Add, Edit, Readonly yp-2 x+10 w80  center vMake_Worker_P_Key , %Make_Worker_P_Key%
					Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Make_Worker_P_Key,  Edit						
			Gui, Add, Text, X%XTabX% yp+30  w80, Select Larvae:
			Gui, Add, Edit, Readonly yp-2 x+10 w80  center vMake_Worker_Z1_Key , %Make_Worker_Z1_Key%
					Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Make_Worker_Z1_Key,  Edit							
			Gui, Add, Text, X%XTabX% yp+30  w80, Make Drone:
			Gui, Add, Edit, Readonly yp-2 x+10 w80  center vMake_Worker_Z2_Key , %Make_Worker_Z2_Key%
					Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Make_Worker_Z2_Key,  Edit	
			Gui, Font, s11
			Gui, Add, Text, X%XTabX% yp+60, Note:
			Gui, Add, Text, xp+40  w340, Ensure the correct ('backspace') base camera key is set in the "SC2 Keys Section" (below Auto Mine - on the left).
			Gui, Font, s10
			Gui, Font,
	*/

	Gui, Tab, Smart Geyser
		Gui, add, GroupBox, y+10 w325 h155 section, Settings
		Gui, Add, Checkbox, xp+10 yp+25 vSmartGeyserEnable checked%smartGeyserEnable% gSmartGeyserOptionsMenuEnableCheck, Enable Smart Geyser 
		Gui, Add, Checkbox, xp y+10 vSmartGeyserReturnCargo checked%smartGeyserReturnCargo%, Return Cargo
		Gui, Add, text, xp y+10, Storage Ctrl Group:
	 	Gui, Add, DropDownList,  % "x+15 yp-2 w45 Center vSmartGeyserCtrlGroup Choose" (smartGeyserCtrlGroup = 0 ? 10 : smartGeyserCtrlGroup), 1|2|3|4|5|6|7|8|9||0
	 	Gui, Add, text, xs+10 y+15 w305, Right clicking a group of workers towards a refinery, assimilator, or extractor will only send the correct amount of workers to harvest gas.
	 	gosub SmartGeyserOptionsMenuEnableCheck

	Gui, Add, Tab2, w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vHome_TAB, Home||Emergency
	Gui, Tab, Home
			Gui, Add, Button, y+30 gTrayUpdate w150, Check For Updates
			Gui, Add, Button, y+20 gB_HelpFile w150, Read The Help File
			Gui, Add, Button, y+20 gB_ChangeLog w150 vSillyGUIControlIdentVariable2, Read The ChangeLog
			Gui, Add, Checkbox,y+30 Vlaunch_settings checked%launch_settings%, Show this menu on startup	

			GuiControlGet, HomeButtonLocation, Pos, SillyGUIControlIdentVariable2 ;

			Gui, Add, Button, X360 y%HomeButtonLocationY% gHomepage w150, Homepage


			Gui, Add, Picture, x170 y320 h90 w90, %A_Temp%\Protoss90.png
			Gui, Add, Picture, x+50 yp-20 h128 w128, %A_Temp%\Terran90.png
			Gui, Add, Picture, x+50  yp+20 h90 w90, %A_Temp%\Zerg90.png

	Gui, Tab, Emergency	
		Gui, Font, S14 CDefault bold UNDERLINE, Verdana
		Gui, Add, Text, x+20 y+20 center cRed, IMPORTANT
		Gui, Font, s10 norm 
		Gui, Add, Text, xp y+20 w405, This program blocks user input and simulates keystrokes.`nOn RARE occasions it is possible that you will lose keyboard and mouse input OR a key e.g. ctrl, shift, or alt becomes 'stuck' down.`n`nIn this event, use the EMERGENCY HOTKEY!`nWhen pressed it should release any 'stuck' key and restore user input.`n`nIf this fails, press the hotkey THREE times in quick succession to have the program restart.`nIf you're still having a problem, then the key is likely physically stuck down.
		Gui, Font, S14 CDefault bold, Verdana
		Gui, Add, Text,xp+10 y+20 cRed, Windows Key && Spacebar`n        (Right)
		Gui, Font, norm 
		Gui, Font,
		Gui, Add, Text, xp y+15 w405, The deult key can be changed via the 'settings' Tab on the left.
		Gui, Add, Text, xp y+20 w405, Note: The windows key must not be disabled within the SC options.`nThis program is capable of blocking the Left windows key (check settings tab).

	Gui, Add, Tab2, hidden w440 h%guiMenuHeight% X%MenuTabX%  Y%MenuTabY% vMiniMap_TAB, MiniMap||MiniMap2|Overlays|Background|Hotkeys|Info

	Gui, Tab, MiniMap

		currentGuiTabX := XTabX -5
		groupboxGuiX := CurrentGuiTabX - 10
		Gui, add, GroupBox, y+10 x%groupboxGuiX% w410 h195, General

			Gui, Add, Checkbox, X%CurrentGuiTabX% Yp+25 vDrawMiniMap Checked%DrawMiniMap% gG_GuiSetupDrawMiniMapDisable, Enable MiniMap Hack
			Gui, Add, Checkbox, xp Y+9 vDrawSpawningRaces Checked%DrawSpawningRaces%, Display Spawning Races
			Gui, Add, Checkbox, Y+9 vDrawAlerts Checked%DrawAlerts%, Display Alerts
			Gui, Add, Checkbox, Y+9 vHostileColourAssist Checked%HostileColourAssist%, Hostile Colour Assist
			Gui, Add, Checkbox, Y+9 vDrawUnitDestinations Checked%DrawUnitDestinations%, Unit Destinations
			Gui, Add, Checkbox, Y+9 vDrawPlayerCameras Checked%DrawPlayerCameras%, Player Cameras

			GuiControlGet, tmpOutput, Pos, DrawMiniMap

			xTmp := tmpOutputX + tmpOutputW + 95
			Gui, Add, Checkbox, x%xTmp% Y%tmpOutputY% vHighlightInvisible Checked%HighlightInvisible%, Highlight Invisible units
			Gui, add, text, y+12 Xp+20, Colour:
			Gui, Add, Picture, xp+60 yp-4 w50 h22 0xE HWND_UnitHighlightInvisibleColour v#UnitHighlightInvisibleColour gColourSelector ;0xE required for GDI
			paintPictureControl(_UnitHighlightInvisibleColour, UnitHighlightInvisibleColour)	

			Gui, Add, Checkbox, x%xTmp% Y+10 vHighlightHallucinations Checked%HighlightHallucinations%, Highlight hallucinated units
			Gui, add, text, y+12 Xp+20, Colour:
			Gui, Add, Picture, XP+60 yp-4 w50 h22 0xE HWND_UnitHighlightHallucinationsColour v#UnitHighlightHallucinationsColour gColourSelector ;0xE required for GDI
			paintPictureControl(_UnitHighlightHallucinationsColour, UnitHighlightHallucinationsColour)	

			GuiControlGet, tmpOutput, Pos, DrawPlayerCameras
			xguiUnitBox :=CurrentGuiTabX + 50
			tmpY := tmpOutputY + 30

			Gui, add, text, y%tmpY% X%CurrentGuiTabX% w45, Exclude:
			Gui, Add, Edit, yp-2 x%xguiUnitBox% w300  center r1 vUnitHighlightExcludeList, %UnitHighlightExcludeList%
			Gui, Add, Button, yp x+10 gEdit_AG v#UnitHighlightExcludeList,  Edit 

	;	Gui, add, text, y+15 X%CurrentGuiTabX%, Custom Unit Highlights:
		
		Gui, add, GroupBox, y+25 x%groupboxGuiX% w410 h210, Custom Unit Highlights

			Gui, add, text, yp+30 X%CurrentGuiTabX%, Unit:
			Gui, Add, Edit, yp-2 x%xguiUnitBox% w300 section  center r1 vUnitHighlightList1, %UnitHighlightList1%
			Gui, Add, Button, yp x+10 gEdit_AG v#UnitHighlightList1,  Edit
			Gui, add, text, y+9 X%CurrentGuiTabX%, Colour:
			Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList1Colour v#UnitHighlightList1Colour gColourSelector ;0xE required for GDI
			paintPictureControl(_UnitHighlightList1Colour, UnitHighlightList1Colour)	

			Gui, add, text, y+12 X%CurrentGuiTabX%, Unit:
			Gui, Add, Edit, yp-2 x%xguiUnitBox% w300  center r1 vUnitHighlightList2, %UnitHighlightList2%
			Gui, Add, Button, yp x+10 gEdit_AG v#UnitHighlightList2,  Edit
			Gui, add, text, y+9 X%CurrentGuiTabX%, Colour:
			Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList2Colour v#UnitHighlightList2Colour gColourSelector ;0xE required for GDI
			paintPictureControl(_UnitHighlightList2Colour, UnitHighlightList2Colour)		
			Gui, add, text, y+12 X%CurrentGuiTabX%, Unit:
			Gui, Add, Edit, yp-2 x%xguiUnitBox% w300  center r1 vUnitHighlightList3, %UnitHighlightList3%
			Gui, Add, Button, yp x+10 gEdit_AG v#UnitHighlightList3,  Edit
			Gui, add, text, y+9 X%CurrentGuiTabX%, Colour:
			Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList3Colour v#UnitHighlightList3Colour gColourSelector ;0xE required for GDI
			paintPictureControl(_UnitHighlightList3Colour, UnitHighlightList3Colour)

			Gui, Font, s8 
			Gui, add, text, x+3 yp+5, <--- Click
			Gui, Font, norm 


	Gui, Tab, MiniMap2
		
	/*
		Gui, Add, Checkbox, X%CurrentGuiTabX% Y+15 vHighlightInvisible Checked%HighlightInvisible%, Highlight Invisible units

			Gui, add, text, y+12 Xp+20, Colour:
			Gui, Add, Picture, xp+60 yp-4 w50 h22 0xE HWND_UnitHighlightInvisibleColour v#UnitHighlightInvisibleColour gColourSelector ;0xE required for GDI
			paintPictureControl(_UnitHighlightInvisibleColour, UnitHighlightInvisibleColour)	

		Gui, Add, Checkbox, X%CurrentGuiTabX% Y+10 vHighlightHallucinations Checked%HighlightHallucinations%, Highlight hallucinated units
			Gui, add, text, y+12 Xp+20, Colour:
			Gui, Add, Picture, XP+60 yp-4 w50 h22 0xE HWND_UnitHighlightHallucinationsColour v#UnitHighlightHallucinationsColour gColourSelector ;0xE required for GDI
			paintPictureControl(_UnitHighlightHallucinationsColour, UnitHighlightHallucinationsColour)	
	*/
		;	Gui, add, text, y+40 X%CurrentGuiTabX%, Additional Custom Unit Highlights:
			Gui, add, GroupBox, y+15 x%groupboxGuiX% w410 h270, Additional Custom Unit Highlights

				Gui, add, text, yp+30 X%CurrentGuiTabX%, Unit:
				Gui, Add, Edit, yp-2 x%xguiUnitBox% w300  center r1 vUnitHighlightList4, %UnitHighlightList4%
				Gui, Add, Button, yp x+10 gEdit_AG v#UnitHighlightList4,  Edit
				Gui, add, text, y+9 X%CurrentGuiTabX%, Colour:
				Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList4Colour v#UnitHighlightList4Colour gColourSelector ;0xE required for GDI
				paintPictureControl(_UnitHighlightList4Colour, UnitHighlightList4Colour)	


				Gui, add, text, y+12 X%CurrentGuiTabX%, Unit:
				Gui, Add, Edit, yp x%xguiUnitBox% w300  center r1 vUnitHighlightList5, %UnitHighlightList5%
				Gui, Add, Button, yp-1 x+10 gEdit_AG v#UnitHighlightList5,  Edit
				Gui, add, text, y+9 X%CurrentGuiTabX%, Colour:
				Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList5Colour v#UnitHighlightList5Colour gColourSelector ;0xE required for GDI
				paintPictureControl(_UnitHighlightList5Colour, UnitHighlightList5Colour)	


				Gui, add, text, y+12 X%CurrentGuiTabX%, Unit:
				Gui, Add, Edit, yp x%xguiUnitBox% w300  center r1 vUnitHighlightList6, %UnitHighlightList6%
				Gui, Add, Button, yp-1 x+10 gEdit_AG v#UnitHighlightList6,  Edit
				Gui, add, text, y+9 X%CurrentGuiTabX%, Colour:
				Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList6Colour v#UnitHighlightList6Colour gColourSelector ;0xE required for GDI
				paintPictureControl(_UnitHighlightList6Colour, UnitHighlightList6Colour)	

				Gui, add, text, y+12 X%CurrentGuiTabX%, Unit:
				Gui, Add, Edit, yp x%xguiUnitBox% w300  center r1 vUnitHighlightList7, %UnitHighlightList7%
				Gui, Add, Button, yp-1 x+10 gEdit_AG v#UnitHighlightList7,  Edit
				Gui, add, text, y+9 X%CurrentGuiTabX%, Colour:
				Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList7Colour v#UnitHighlightList7Colour gColourSelector ;0xE required for GDI
				paintPictureControl(_UnitHighlightList7Colour, UnitHighlightList7Colour)	

	Gui, Tab, Overlays
			;Gui, add, text, y+20 X%XTabX%, Display Overlays:
			Gui, Add, GroupBox, y+15 x+20 w195 h270 section, Display Overlays:
				Gui, Add, Checkbox, xp+10 yp+20 vDrawIncomeOverlay Checked%DrawIncomeOverlay%, Income
					Gui, Add, Checkbox, xp+95 yp vDrawLocalPlayerIncome Checked%drawLocalPlayerIncome%, Include Self
				Gui, Add, Checkbox, xs+10 y+13 vDrawResourcesOverlay Checked%DrawResourcesOverlay%, Resources
					Gui, Add, Checkbox, xp+95 yp vDrawLocalPlayerResources Checked%drawLocalPlayerResources%, Include Self
				Gui, Add, Checkbox, xs+10 y+13 vDrawArmySizeOverlay Checked%DrawArmySizeOverlay%, Army Size
					Gui, Add, Checkbox, xp+95 yp vDrawLocalPlayerArmy Checked%drawLocalPlayerArmy%, Include Self
				Gui, Add, Checkbox, xs+10 y+13 vDrawAPMOverlay Checked%DrawAPMOverlay%, APM
					Gui, Add, Checkbox, xp+95 yp vAPMOverlayMode Check3 Checked%APMOverlayMode%, Mode
				Gui, Add, Checkbox, xs+10 y+13 vDrawIdleWorkersOverlay Checked%DrawIdleWorkersOverlay%, Idle Workers
					Gui, Add, Text, x+15 yp, Min:
					Gui, Add, Edit, Number Right x+18 yp-2 w40 vTT_IdleWorkerOverlayThreshold
					Gui, Add, UpDown,  Range1-200 vIdleWorkerOverlayThreshold, %IdleWorkerOverlayThreshold%	

				Gui, Add, Checkbox, xs+10 y+7 vDrawWorkerOverlay Checked%DrawWorkerOverlay%, Local Harvester Count
				Gui, Add, Checkbox, xp y+13 vDrawLocalPlayerColourOverlay Checked%DrawLocalPlayerColourOverlay%, Local Player Colour
				Gui, Add, Checkbox, xp y+13 vDrawMacroTownHallOverlay Checked%DrawMacroTownHallOverlay%, Town Hall Macro
				Gui, Add, Checkbox, xp y+13 vDrawLocalUpgradesOverlay Checked%DrawLocalUpgradesOverlay% Check3, Local Upgrades
			
			;	Gui, Add, Edit, Number Right x+25 yp-2 w50 vTT_localUpgradesItemsPerRow
			;		Gui, Add, UpDown,  Range0-100 vlocalUpgradesItemsPerRow, %localUpgradesItemsPerRow%	
				Gui, Add, Text, x+10 yp, Size:
				Gui, Add, DropDownList, % "x+5 yp-3 w40 vlocalUpgradesItemsPerRow Choose" (localUpgradesItemsPerRow != "" ? localUpgradesItemsPerRow + 1 : 1), 0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16


				Gui, Add, GroupBox, ys XS+220 w170 h270, Match Overlay:
				Gui, Add, Checkbox, xp+10 yp+20 vDrawUnitUpgrades Checked%DrawUnitUpgrades%, Show Upgrades
				Gui, Add, Checkbox, xp y+13 vDrawUnitOverlay Checked%DrawUnitOverlay%, Show Unit Count/Production
				Gui, Add, Checkbox, xp y+13 vSplitUnitPanel ggToggleAlignUnitGUI Checked%SplitUnitPanel% , Split Units/Buildings
				Gui, Add, Checkbox, % "xp y+13 vUnitPanelAlignNewUnits Checked" unitPanelAlignNewUnits " disabled" !SplitUnitPanel, Align New units
				Gui, Add, Checkbox, xp y+13 vUnitPanelDrawStructureProgress Checked%unitPanelDrawStructureProgress%, Show Structure Progress 
				Gui, Add, Checkbox, xp y+13 vUnitPanelDrawUnitProgress Checked%unitPanelDrawUnitProgress%, Show Unit Progress 
				Gui, Add, Checkbox, xp y+13 vUnitPanelDrawUpgradeProgress Checked%unitPanelDrawUpgradeProgress%, Show Upgrade Progress 
				Gui, Add, Checkbox, xp y+13 vunitPanelDrawLocalPlayer Checked%unitPanelDrawLocalPlayer%, Include Self 

				;Gui, Add, Button, center xp+15 y+10 w100 h30 vUnitPanelFilterButton Gg_GUICustomUnitPanel, Unit Filter
				Gui, Add, Button, center xp y+15 w70 h30 vUnitPanelFilterButton Gg_GUICustomUnitPanel, Unit Filter
				Gui, Add, Button, center x+10 yp w70 h30 vUnitPanelGuideButton GgUnitPanelGuide, Guide

			Gui, Add, GroupBox, XS ys+280 w195 h55 section, Player Identifier:	
			;	Gui, Add, Text, yp+25 xp+10 w80, Player Identifier:
				if OverlayIdent in 0,1,2,3
					droplist3_var := OverlayIdent + 1
				Else droplist3_var := 3 
				Gui, Add, DropDownList, xp+10 yp+20 vOverlayIdent Choose%droplist3_var%, Hidden|Name (White)|Name (Coloured)|Coloured Race Icon
		
			Gui, Add, GroupBox, XS ys+65 w195 h55, Opacity:	
			; transparency is max 255/0xFF
			;Gui, Add, Text, yp+35 xs+10, Opacity:
				Gui, Add, DropDownList, xp+10 yp+20 vOpacityOverlayIdent w100 gG_SwapOverlayOpacitySliders, Army||Harvester|Idle Worker|Income|Local Colour|Match/Unit|Minimap|Resource|APM|Town Hall|Local Upgrades
					Gui, Add, Slider, ToolTip  NoTicks w80 x+0 yp+2   vOverlayArmyTransparency, % ceil(overlayArmyTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayIncomeTransparency, % ceil(overlayIncomeTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayMatchTransparency, % ceil(overlayMatchTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayResourceTransparency, % ceil(overlayResourceTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayHarvesterTransparency, % ceil(overlayHarvesterTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayIdleWorkerTransparency, % ceil(overlayIdleWorkerTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayLocalColourTransparency, % ceil(overlayLocalColourTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayMinimapTransparency, % ceil(overlayMinimapTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayAPMTransparency, % ceil(overlayAPMTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayMacroTownHallTransparency, % ceil(overlayMacroTownHallTransparency / 2.55) 
					Gui, Add, Slider, ToolTip  NoTicks wp xp yp  Hidden vOverlayLocalUpgradesTransparency, % ceil(overlayLocalUpgradesTransparency / 2.55) 
				
			Gui, Add, GroupBox, XS+220 ys w170 h120 section, Refresh Intervals:
			Gui, Add, Text, xs+10  yp+25, General:
				Gui, Add, Edit, Number Right xp+90 yp-2 w55 vTT_OverlayRefresh
					Gui, Add, UpDown,  Range50-5000 vOverlayRefresh, %OverlayRefresh%
			Gui, Add, Text, xs+10 yp+35, Unit Panel:
				Gui, Add, Edit, Number Right xp+90 yp-2 w55 vTT_UnitOverlayRefresh
					Gui, Add, UpDown,  Range100-15000 vUnitOverlayRefresh, %UnitOverlayRefresh%
			Gui, Add, Text, xs+10 yp+35, MiniMap:
				Gui, Add, Edit, Number Right xp+90 yp-2 w55 vTT_MiniMapRefresh
					Gui, Add, UpDown,  Range50-1500 vMiniMapRefresh, %MiniMapRefresh%	

	Gui, Tab, Background
		Gui, Add, GroupBox, x+20 y+15 w285 h255 section, Enable Background:
			Gui, Add, Checkbox, xp+10 yp+20 vBackgroundIncomeOverlay Checked%BackgroundIncomeOverlay%, Income
			Gui, Add, Checkbox, xp y+10 vBackgroundResourcesOverlay Checked%BackgroundResourcesOverlay%, Resources
			Gui, Add, Checkbox, xp y+10 vBackgroundArmySizeOverlay Checked%BackgroundArmySizeOverlay%, Army Size
			Gui, Add, Checkbox, xp y+10 vBackgroundAPMOverlay Checked%BackgroundAPMOverlay%, APM
			Gui, add, text, xs+10 y+30 w40, Colour:
			Gui, Add, Picture, x+10 yp-10 w210 h35 0xE HWND_TransparentBackgroundColour v#TransparentBackgroundColour gColourSelector ;0xE required for GDI
			paintPictureControl(_TransparentBackgroundColour, TransparentBackgroundColour)	
			Gui, add, text, xs+10 y+25 w40, Opacity:
			Gui, Add, Slider, ToolTip  NoTicks w210 x+10 yp vTransparentBackgroundSlider gUpdateTransparentGUIColour AltSubmit, % round(((TransparentBackgroundColour & 0xFF000000) >> 24) / 2.55)  ;& it in case higher bits got set somehow (should never occur). Use round not ceil
			Gui, Add, Button, xs+10 y+10 gResetTransparentBackgroundColour, Default Colour
			Gui, Add, Checkbox, xs+150 ys+20 vBackgroundIdleWorkersOverlay Checked%BackgroundIdleWorkersOverlay%, Idle Workers
			Gui, Add, Checkbox, xp y+10 vBackgroundWorkerOverlay Checked%BackgroundWorkerOverlay%, Local Harvester Count
			Gui, Add, Checkbox, xp y+10 vBackgroundMacroTownHallOverlay Checked%BackgroundMacroTownHallOverlay%, Town Hall Macro
			Gui, Add, Checkbox, xp y+10 vBackgroundMacroAutoBuildOverlay Checked%BackgroundMacroAutoBuildOverlay%, Auto Build

	Gui, Tab, Hotkeys 
		Gui, add, GroupBox, x+20 y+15 w285 h320, Overlay Hotkeys
			;Gui, Add, Text, section xp+15 yp+25, Temp. Hide MiniMap:
			Gui, Add, Checkbox, section xp+15 yp+25 vEnableHideMiniMapHotkey checked%EnableHideMiniMapHotkey%, Temp. Hide MiniMap:
			Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vTempHideMiniMapKey gedit_hotkey, %TempHideMiniMapKey%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#TempHideMiniMapKey, Edit 	

			;Gui, Add, Text, xs yp+35, Toggle Minimap:
			Gui, Add, Checkbox, section xs yp+35 vEnableToggleMiniMapHotkey checked%EnableToggleMiniMapHotkey%, Toggle Minimap:
			Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vToggleMinimapOverlayKey gedit_hotkey, %ToggleMinimapOverlayKey%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleMinimapOverlayKey, Edit 	

			;Gui, Add, Text, xs yp+35, Toggle Income:
			Gui, Add, Checkbox, section xs yp+35 vEnableToggleIncomeOverlayHotkey checked%EnableToggleIncomeOverlayHotkey%, Toggle Income:
			Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vToggleIncomeOverlayKey gedit_hotkey, %ToggleIncomeOverlayKey%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleIncomeOverlayKey, Edit 		

			;Gui, Add, Text, xs yp+35, Toggle Resources:
			Gui, Add, Checkbox, section xs yp+35 vEnableToggleResourcesOverlayHotkey checked%EnableToggleResourcesOverlayHotkey%, Toggle Resources:
			Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vToggleResourcesOverlayKey gedit_hotkey, %ToggleResourcesOverlayKey%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleResourcesOverlayKey, Edit 		

			;Gui, Add, Text, xs yp+35, Toggle Army Size:
			Gui, Add, Checkbox, section xs yp+35 vEnableToggleArmySizeOverlayHotkey checked%EnableToggleArmySizeOverlayHotkey%, Toggle Army Size:
			Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vToggleArmySizeOverlayKey gedit_hotkey, %ToggleArmySizeOverlayKey%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleArmySizeOverlayKey, Edit 		

			;Gui, Add, Text, xs yp+35, Toggle Workers:
			Gui, Add, Checkbox, section xs yp+35 vEnableToggleWorkerOverlayHotkey checked%EnableToggleWorkerOverlayHotkey%, Toggle Resources:
			Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vToggleWorkerOverlayKey gedit_hotkey, %ToggleWorkerOverlayKey%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleWorkerOverlayKey, Edit 		

			;Gui, Add, Text, xs yp+35, Toggle Unit Panel:
			Gui, Add, Checkbox, section xs yp+35 vEnableToggleUnitPanelOverlayHotkey checked%EnableToggleUnitPanelOverlayHotkey%, Toggle Unit Panel:
			Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vToggleUnitOverlayKey gedit_hotkey, %ToggleUnitOverlayKey%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleUnitOverlayKey, Edit 		

			;Gui, Add, Text, xs yp+35, Cycle Overlays:
			;Gui, Add, Edit, Readonly yp-2 xp+120 center w85 R1 vCycleOverlayKey gedit_hotkey, %CycleOverlayKey%
			;Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#CycleOverlayKey,  Edit 		

			;Gui, Add, Text, xs yp+35, Cycle Identifier:
			Gui, Add, Checkbox, section xs yp+35 vEnableCycleIdentifierHotkey checked%EnableCycleIdentifierHotkey%, Cycle Identifier:
			Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vToggleIdentifierKey gedit_hotkey, %ToggleIdentifierKey%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleIdentifierKey, Edit 		
			gui, font, Underline
			;Gui, Add, Text, xs yp+35, *Adjust Overlays:
			Gui, Add, Checkbox, section xs yp+30 vEnableAdjustOverlaysHotkey checked%EnableAdjustOverlaysHotkey%, *Adjust Overlays:
			gui, font, Norm 
			Gui, Add, Edit, Readonly yp-2 xp+130 center w85 R1 vAdjustOverlayKey gedit_hotkey, %AdjustOverlayKey%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#AdjustOverlayKey,  Edit 
			Gui, Add, Text, xs yp+30, * See 'Info' Tab for Instructions		

	Gui, Tab, Info
	;	Gui, Add, Text, section x+10 y+15,	
		Gui, add, GroupBox, section y+15 w405 h395
		Gui, Font, s10 CDefault bold, Verdana
		Gui, Add, Text, xs+10 yp+25, Adjusting Overlays:	
		Gui, Font, s10 norm 
		
	text = 
	( ltrim
	Hold down (and do not release) the "Adjust Overlays" Hotkey (%AdjustOverlayKey% key).
		
	You will hear a beep - all the overlays (excluding the minimap) are now adjustable.When you're done, release the "Adjust Overlays" Hotkey. 
	)
		Gui, Add, Text, xs+25 y+10 w370, %text%
		Gui, Font, CDefault bold, Verdana
		Gui, Add, Text, xs+10 y+20, Moving:
		Gui, Font, s10 norm 
		Gui, Add, Text, xs+25 y+10 w370, Simply left click somewhere on the text or graphics of the overlay (not a blank area) and drag the overlay to its new position.
	 	Gui, Font, CDefault bold, Verdana
	 	Gui, Add, Text, xs+10 y+20, Resizing:
	 	Gui, Font, norm 
	 	Gui, Add, Text, xs+25 y+10 w370, Simply left click somewhere on the overlay and then rotate the mouse wheel forward/backward.

		Gui, Font, s9 CDefault bold, Verdana
		Gui, Add, Text, center xs+10 y+25 w370 cRed, The MiniMap and Overlays will only work when SC is in 'Windowed (fullscreen)' mode.
		Gui, Font, s10 norm 

	if !ZergPic_TT
	{
		auto_inject_alert_TT := "This alert will sound X seconds after your last one-button inject, prompting you to inject again."
		W_inject_ding_on_TT := "Note: Due to an inconsistency with the programming language, some systems may not hear the 'windows ding'."
		auto_inject_time_TT := TT_auto_inject_time_TT :=  "This is in 'SC2' Seconds."
		#cast_inject_key_TT := cast_inject_key_TT := "When pressed the program will inject all of your hatcheries.`n`nThis Hotkey is ONLY active while playing as zerg!"
		Auto_inject_sleep_TT := "Lower this to make the inject round faster, BUT this will make it more obvious that it is being automated!"
		CanQueenMultiInject_TT := "During minimap injects (and auto-Injects) a SINGLE queen may attempt to (shift-queue) inject multiple hatcheries providing:`nShe is the only nearby queen and she has enough energy.`n`nThis may increase the chance of having queens go walkabouts - but I have never observed this. "
		InjectConserveQueenEnergy_TT := "Hatches which already have 19 larvae will not be injected, thereby saving queen energy.`n"
									. "This setting is ignored by the 'Backspace' method.`n`n"
									 . "Note: In SC a hatch can have a maximum of 19 larvae, that is, further injects will not yield additional larvae."
		Inject_RestoreSelection_TT := "This will store your currently selected units in a control group, which is recalled at the end inject round."
		Inject_RestoreScreenLocation_TT := "This will save your screen/camera location and restore it at the end of the inject round.`n`n"
								. "This option only affects the 'backspace' methods."

		Inject_SleepVariance_TT := Edit_Inject_SleepVariance_TT := "This will increase each sleep period by a random percentage from 0% up to this set value.`n`n"
								. "This does not affect the auto-injects."						

		HotkeysZergBurrow_TT := #HotkeysZergBurrow_TT := "Please ensure this matches the 'Burrow' hotkey in SC2 & that you only have one active hotkey to burrow units i.e. No alternate burrow key!`n`nThis is used during auto injects to help prevent accidentally burrowing queens due to the way windows/SC2 buffers these repeated keypresses."
		Simulation_speed_TT := "How fast the mouse moves during inject rounds. 0 = Fastest - try 1,2 or 3 if you're having problems."
		Drag_origin_TT := "This sets the origin of the box drag to the top left or right corners. Hence making it compatible with (clickable) internal observer panel hacks.`n`nThis is only used by the 'Backspace' method."
		BI_create_camera_pos_x_TT := #BI_create_camera_pos_x_TT := "The hotkey used to save a camera location."
									. "`n`nThis should correspond to one of the five SC2 'create camera' hotkeys."
									. "`nPlease set this to a camera hotkey which you don't actually use."
									. "`n`nThis is used by both backspace inject methods."


		BI_camera_pos_x_TT := #BI_camera_pos_x_TT :=  "The hotkey used to invoke the above saved camera location."
													. "`n`nThis is used by both backspace inject methods."

		EnableLastAlertPlayBackHotkey_TT := EnableHideMiniMapHotkey_TT := EnableToggleMiniMapHotkey_TT := EnableToggleIncomeOverlayHotkey_TT := EnableToggleResourcesOverlayHotkey_TT
		:= EnableToggleArmySizeOverlayHotkey_TT := EnableToggleWorkerOverlayHotkey_TT := EnableToggleUnitPanelOverlayHotkey_TT := EnableCycleIdentifierHotkey_TT 
		:= EnableAdjustOverlaysHotkey_TT := EnableWorkerCountSpeechHotkey_TT := EnableEnemyWorkerCountSpeechHotkey_TT := EnableToggleMacroTrainerHotkey_TT := EnablePingMiniMapHotkey_TT
		:= "Enables/Disables the associated hotkey."											


		manual_inject_time_TT := "The time between alerts."
		inject_start_key_TT := "The hotkey used to start or stop the timer."
		inject_reset_key_TT := "The hotkey used to reset (or start) the timer."
		Alert_List_Editor_TT := "Use this to edit and create alerts for any SC2 unit or building."
		#base_camera_TT := base_camera_TT := "The key used to cycle between hatcheries/bases."
		escape_TT := #escape_TT := "The key which cancels the current action.`nUsually 'escape'."
		#NextSubgroupKey_TT := NextSubgroupKey_TT := "The key used to cycle forward though a selection group."
		#control_group_TT := control_group_TT := "Set this to a control group you DON'T use - It stores your unit selection during an inject round."
		create_camera_pos_x_TT := #create_camera_pos_x_TT := "The hotkey used to 'save' a camera location. - Ensure this isn't one you use."
		#camera_pos_x_TT := camera_pos_x_TT := "The hotkey associated with the 'create/save' camera location above."
		spawn_larva_TT := #spawn_larva_TT := Tspawn_larva_TT := "Please set the key or alternate key for ""spawn larvae"" in SC2 to "" e "". - This prevents problems!"
		sub_lowerdelta_TT := TT_sub_lowerdelta_TT := "A warning will be heard when the 'free' supply drops below this number. (while your supply is below the 'Low Range Cutoff')."
		sub_middelta_TT := TT_sub_middelta_TT := "A warning will be heard when the 'free' supply drops below this number. (While your supply is greater than the 'Low Range Cutoff' but less than the 'Middle Range Cutoff')."
		sub_upperdelta_TT := TT_sub_upperdelta_TT := "A warning will be heard when the 'free' supply drops below this number. (While your supply is greater than the 'Middle Range Cutoff' but less than the 'Upper Range Cutoff')."
		above_upperdelta_TT := TT_above_upperdelta_TT := "A warning will be heard when the 'free' supply drops below this number. (While your supply is greater than the 'Upper Range Cutoff')."
		minimum_supply_TT := TT_minimum_supply_TT := "Alerts are only active while your supply is above this number."

		WarningsGeyserOverSaturationSpokenWarning_TT := w_supply_TT := w_warpgate_TT := WarningsWorkerTerranSpokenWarning_TT := WarningsWorkerProtossSpokenWarning_TT := WarningsWorkerZergSpokenWarning_TT := w_gas_TT := w_idle_TT := w_mineral_TT := "This text is spoken during a warning."
		TT_WarningsWorkerTerranFollowUpCount_TT :=	TT_WarningsWorkerProtossFollowUpCount_TT := TT_WarningsWorkerZergFollowUpCount_TT := WarningsWorkerTerranFollowUpCount_TT := WarningsWorkerProtossFollowUpCount_TT := WarningsWorkerZergFollowUpCount_TT
		:= sec_idle_TT := sec_gas_TT := sec_mineral_TT := sec_supply_TT := TT_sec_supply_TT := TT_sec_mineral_TT := TT_sec_gas_TT := TT_sec_idle_TT := TT_sec_warpgate_TT := sec_warpgate_TT 
		:= TT_WarningsGeyserOverSaturationFollowUpCount_TT := WarningsGeyserOverSaturationFollowUpCount_TT := "Sets how many additional warnings are to be given after the first initial warning (assuming the resource does not fall below the inciting value) - the warnings then turn off."
		additional_delay_supply_TT := TT_additional_delay_supply_TT := additional_delay_minerals_TT := additional_delay_gas_TT := additional_idle_workers_TT 
		:= TT_additional_delay_minerals_TT := TT_additional_delay_gas_TT := TT_additional_idle_workers_TT := TT_delay_warpgate_warn_followup_TT := delay_warpgate_warn_followup_TT := "This sets the delay between the initial warning, and the additional/follow-up warnings. (in real seconds)"
		
		TT_WarningsWorkerTerranFollowUpDelay_TT := 	TT_WarningsWorkerProtossFollowUpDelay_TT := TT_WarningsWorkerZergFollowUpDelay_TT 
		:= WarningsWorkerTerranFollowUpDelay_TT := WarningsWorkerProtossFollowUpDelay_TT := WarningsWorkerZergFollowUpDelay_TT 
		:= TT_WarningsGeyserOverSaturationFollowUpDelay_TT := WarningsGeyserOverSaturationFollowUpDelay_TT := "This sets the delay between the initial warning, and the additional/follow-up warnings. (in SC2 seconds)"
		TT_WarningsWorkerZergTimeWithoutProduction_TT := WarningsWorkerZergTimeWithoutProduction_TT := "A warning will be heard if a drone has not started (being produced) in this amount of time (SC2 seconds)" 
		
		TT_WarningsWorkerTerranTimeWithoutProduction_TT := WarningsWorkerTerranTimeWithoutProduction_TT
		:= TT_WarningsWorkerProtossTimeWithoutProduction_TT := WarningsWorkerProtossTimeWithoutProduction_TT := "If all nexi/CC/Orbitals/PFs are idle for this amount of time (SC2 seconds), a warning will be made.`n`nNote: A main is considered idle if it has no unit in production and is not currently flying or morphing."
		TT_WarningsWorkerTerranMinWorkerCount_TT := TT_WarningsWorkerProtossMinWorkerCount_TT := TT_WarningsWorkerZergMinWorkerCount_TT 
 		:= WarningsWorkerTerranMinWorkerCount_TT := WarningsWorkerProtossMinWorkerCount_TT := WarningsWorkerZergMinWorkerCount_TT := "Warnings are silenced while your worker count is below this number."
		TT_WarningsWorkerTerranMaxWorkerCount_TT := TT_WarningsWorkerProtossMaxWorkerCount_TT := TT_WarningsWorkerZergMaxWorkerCount_TT 
		:= WarningsWorkerTerranMaxWorkerCount_TT := WarningsWorkerProtossMaxWorkerCount_TT := WarningsWorkerZergMaxWorkerCount_TT :=  "Warnings are silenced while your worker count is greater than this number."

		delay_warpgate_warn_TT := "If a gateway has been unconverted for this period of time (real seconds) then a warning will be made."
		warpgate_warn_on_TT := "Enables warnings for unconverted gateways.`nNote: The warnings become active after your first gateway is converted."
		idletrigger_TT := gas_trigger_TT := mineraltrigger_TT := TT_mineraltrigger_TT := TT_gas_trigger_TT := TT_idletrigger_TT := "The required amount to invoke a warning."
		supplylower_TT := TT_supplylower_TT := TT_supplymid_TT := supplymid_TT := supplyupper_TT := TT_supplyupper_TT := "Dictactes when the next or previous supply delta/threashold is used."
		
		TT_WarningsGeyserOverSaturationMaxWorkers_TT := WarningsGeyserOverSaturationMaxWorkers_TT := "When this many (or more) workers have been mining from a geyser for too long a warning will be issued.`n`nNote:  The geyser will also be marked on the minimap providing the 'Display Alerts' option is enabled. (MiniMap/Overlays-->General)"
		TT_WarningsGeyserOverSaturationMaxTime_TT := WarningsGeyserOverSaturationMaxTime_TT := "A warning is issued when the geyser has been oversaturated (too many harvesters) for longer than this period of time (SC seconds). "
																							. "`n`nNote:  The geyser will also be marked on the minimap providing the 'Display Alerts' option is enabled. (MiniMap/Overlays-->General)"
		WarningsGeyserOverSaturationEnable_TT := "When too many workers are mining from a gas geyser for too long a warning is issued.`n`nNote:  The geyser will also be marked on the minimap providing the 'Display Alerts' option is enabled. (MiniMap/Overlays-->General)"
		delay_warpgate_warn_TT := TT_delay_warpgate_warn_TT := "A warning will be heard when an unconverted gateway exists for this period of time.`nThis is in SC/in-game seconds.`n`nNote: An additional delay of up to three (real) seconds can be expected"

		TT_delay_warpgate_warn_followup_TT := delay_warpgate_warn_followup_TT := "This sets the delay between the initial warning and the additional/follow-up warnings.`n`nNote: This is in SC2 (in game) seconds."
		DrawMiniMap_TT := "Draws enemy units on the minimap i.e. A Minimap Hack"
		DrawSpawningRaces_TT := "Displays a race icon over the enemy's spawning location at the start of the match."

		DrawAlerts_TT := "While using the 'detection list' function an 'x' will be briefly displayed on the minimap during a unit warning.`n`nUnconverted gateways and oversaturated geysers will also be marked (if those macros are enabled)."

		UnitHighlightExcludeList_TT := #UnitHighlightExcludeList_TT := "These units will not be displayed on the minimap."

		loop, 7
		{
			UnitHighlightList%A_index%_TT := #UnitHighlightList%A_index%_TT
			:= "Units of this type will be drawn using the specified colour."
			. "`n`nTo disable this feature, simply remove the units listed in this field."
		 	#UnitHighlightList%A_Index%Colour_TT := "Click Me!`n`nUnits of this type will appear this colour."
		 									. "`n`nTo disable this feature, simply remove the units listed in the above field."
		}
		#TransparentBackgroundColour_TT := "Click Me!"

		DrawAPMOverlay_TT := "This enables/disables the overlay."
						. "`nThe mode can be set with via the 'mode' checkbox on right"

		DrawWorkerOverlay_TT := "Displays your current harvester count with a worker icon"
		DrawIdleWorkersOverlay_TT := "A worker icon with the current idle worker count is displayed when the idle count is greater than or equal to the minimum value.`n`nThe size and position can be changed easily so that it grabs your attention."
		TT_IdleWorkerOverlayThreshold_TT := IdleWorkerOverlayThreshold_TT := "The idle worker overlay is only visible when your idle count is greater than or equal to this minimum value."

		DrawUnitOverlay_TT := "Displays an overlay similar to the 'observer panel', listing the current and in-production unit counts.`n`nUse the 'unit panel filter' to selectively remove/display units.`n`nNote: To disable the match overlay uncheck both 'Show Upgrades' and 'Show Unit Count/Production'."
		DrawUnitUpgrades_TT := "Displays the current enemy upgrades.`n`nNote: To disable the match overlay uncheck both 'Show Upgrades' and 'Show Unit Count/Production'."
		
		UnitPanelFilterButton_TT := "Allows units to be selectively removed from the overlay."

		ToggleAutoWorkerState_Key_TT := #ToggleAutoWorkerState_Key_TT := "Toggles (enables/disables) this function for the CURRENT match.`n`nWill only work during a match"
		AutoWorkerProtectionDelay_TT := TT_AutoWorkerProtectionDelay_TT := "After a round a of workers has been made the function will sleep for this period of time (ms).`nThis helps prevent queueing too many workers.`n`n"
									. "If more than one worker is commonly being queued-up and/or you have a laggy connection perhaps try increasing this value."

		AutoWorkerQueueSupplyBlock_TT := "While you are supply blocked a worker will be queued-up.`n"
				. "This aims to make the automation a little more subtle. If disabled, the instant you have free supply all of your bases will make a worker."
				. "`n`nNote: The program won't queue multiple workers while supply blocked."

		AutoWorkerAlwaysGroup_TT := "When enabled, your current unit selection will always be stored in a control group and then restored post automation."
				. "`nThis provides the greatest reliability."
				. "`n`nWhen disabled, the program will not control-group your selection nor restore it if you already have your bases (CC/nexi) selected. It will however"
				. "`nstill send the control group key for your bases."
				. "`n`nThis helps make the automation a little more subtle, especially in the early game. But it may not work correctly for everyone."
				. "`nIf it fails, you will end up with your base control group selected rather than your previous units."
				. "`n`nNote: Prior to v2.986 'disabled' was the default nature."
		
		AutoWorkerWarnMaxWorkers_TT := "A spoken warning is issued when the maximum worker count has been reached.`nWarning: ""Maxed Workers"""

		automationAPMThreshold_TT := TT_automationAPMThreshold_TT := TT_AutoWorkerAPMProtection_TT := AutoWorkerAPMProtection_TT
		:= TT_FInjectAPMProtection_TT := FInjectAPMProtection_TT := "Automations will be delayed while your instantaneous APM is greater than this value.`n"
				. "`nThis can be used to make the automations a little more subtle."
				. "`n`nAlthough this shouldn't occur, if you are experiencing misgroupings or altered rally points lowering this value may help."

		EnableAutoWorkerTerranStart_TT := EnableAutoWorkerProtossStart_TT := "Enables/Disables this function."
		AutoWorkerStorage_T_Key_TT := #AutoWorkerStorage_T_Key_TT 
		:= AutoWorkerStorage_P_Key_TT := #AutoWorkerStorage_P_Key_TT := "During an automation cycle your selected units will be temporarily stored in this control group.`n`nSpecify a control group that you do NOT use in game."
																	. "`n`nYou must ensure the corresponding ""Set Control Group keys"" and ""Invoke Group Keys"" (under SC2 Keys on the left) match your SC2 hotkey setup."
		#Base_Control_Group_T_Key_TT := Base_Control_Group_T_Key_TT 
		:= Base_Control_Group_P_Key_TT := #Base_Control_Group_P_Key_TT := "The control group which contains your command centres/orbitals/planetary-fortresses/nexi."
																	. "`n`nYou must ensure the corresponding ""Invoke Group Keys"" (under SC2 Keys on the left) match your SC2 hotkey setup."

		AutoWorkerMakeWorker_T_Key_TT := #AutoWorkerMakeWorker_T_Key_TT := "The keyboard hotkey used to build an SCV.`nUsually 'S'."
		AutoWorkerMakeWorker_P_Key_TT := #AutoWorkerMakeWorker_P_Key_TT := "The keyboard hotkey used to build a probe.`nUsually 'E'."

		TT_AutoWorkerMaxWorkerTerran_TT := TT_AutoWorkerMaxWorkerProtoss_TT := AutoWorkerMaxWorkerTerran_TT := AutoWorkerMaxWorkerProtoss_TT := "Worker production will stop for the remainder of the game when this number of workers exist.`n"
						. "Workers can then be 'sacked' and the function will remain off!`n`nIf you wish to turn it back on, simply use the 'toggle hotkey' twice."
						. "`nNote: For added randomness your final worker count will be within +/- 2 of this value."
		TT_AutoWorkerMaxWorkerPerBaseTerran_TT := TT_AutoWorkerMaxWorkerPerBaseProtoss_TT := AutoWorkerMaxWorkerPerBaseTerran_TT := AutoWorkerMaxWorkerPerBaseProtoss_TT :=  "Worker production will stop when this number is exceeded by`n"
					. "the current worker count per the number of fully constructed (and control grouped) main-bases`n"
					. "WHICH are within 8 map units of a gas geyser.`n`n"
					. "Note: A properly situated base is usually 7-7.5 map units from a geyser."

		AutoBuildBarracksGroup_TT := AutoBuildFactoryGroup_TT := AutoBuildStarportGroup_TT := AutoBuildGatewayGroup_TT := AutoBuildStargateGroup_TT := AutoBuildRoboticsFacilityGroup_TT := AutoBuildHatcheryGroup_TT := AutoBuildLairGroup_TT
		:= AutoBuildHiveGroup_TT := "The control group which contains this structure."

	TT_autoBuildMinFreeMinerals_TT := autoBuildMinFreeMinerals_TT := TT_autoBuildMinFreeGas_TT := autoBuildMinFreeGas_TT := TT_autoBuildMinFreeSupply_TT 
	:= autoBuildMinFreeSupply_TT := "These values influence how many units can be made during a production cycle.`nAt the end of each cycle you will be left with a minimum of each resource value."

		AutoBuildGUIkeyMode_TT := "Determines how the 'in-game GUI' hotkey works.`n`nToggle: The GUI is toggled on/off with each press.`n`nKeyDown: The GUI is only visible while the hotkey is depressed."
		AutoBuildEnableGUIHotkey_TT := "Enables/Disables the hokey.`n`nThis hokey displays an in-game GUI which can be used to control unit production.`n`nToggle: The GUI is toggled on/off with each press.`n`nKeyDown: The GUI is only visible while this hotkey is depressed."
		AutoBuildGUIkey_TT := "Displays an in-game GUI which can be used to control unit production.`n`nToggle: The GUI is toggled on/off with each press.`n`nKeyDown: The GUI is only visible while this hotkey is depressed."

		AutoBuildEnableInteractGUIHotkey_TT := "When enabled the GUI can only be interacted with while this hotkey is depressed.`n`nThis allows the GUI to be visible in-game yet not clickable."
		AutoBuildInteractGUIKey_TT := "When enabled the GUI can only be interacted with while this hotkey is depressed.`n`nThis allows the GUI to be visible in-game yet not clickable."
		AutoBuildInactiveOpacity_TT := "While inactive (the interact key is not depressed) the GUI is drawn with this opacity."

		AutoBuildGUIAutoWorkerToggle_TT := "Includes a worker icon in the GUI. This allows the auto-worker function to be toggled on/off."
		AutoBuildGUIAutoWorkerPause_TT := "When enabled the GUI pause button will turn off the auto-worker function.`n`nNote: Unlike the other units, the auto-worker function will remain off if the pause button is pressed again to resume production."
		AutoBuildGUIAutoWorkerOffButton_TT := "When enabled the GUI off button (the red 'x') will also turn off the auto-worker function."

		Inject_spawn_larva_TT := #Inject_spawn_larva_TT := "This needs to correspond to your SC2 'spawn larvae' button.`n`nThis key is sent during an inject to invoke Zerg's 'spawn larvae' ability."

		MI_Queen_Group_TT := #MI_Queen_Group_TT := "The queens in this control are used to inject hatcheries."
								. "`n`nHence you must add your injecting queens to this control group!"
								. "`n`nYou must ensure the corresponding ""Invoke Group Keys"" (under SC2 Keys on the left) match your SC2 hotkey setup."			
		F_InjectOff_Key_TT := #F_InjectOff_Key_TT := "During a match this hotkey will toggle (either disable or enable) automatic injects."

		SplitUnitPanel_TT := "When enabled the overlay will display units on a separate line to structures."

		UnitPanelAlignNewUnits_TT := "
						( LTrim
							This setting is only active when the unit panel is split (structures/buildings). 
							It determines where the first new unit and first new structure are drawn.
							
							When enabled new units and new structures will be drawn aligned along the x-axis. 
							When disabled new units and new structures will be drawn along their own x-axes independent of one another.

							A 'new' unit/structure is a unit which is in production and the unit owner does not already have an existing (completed) unit of this type. 
							
							Click the guide button below for a clearer illustration. (Pictures highlighting this setting are listed under ""Unit Panel"")
						)"
		UnitPanelGuideButton_TT := "Opens the Macro Trainer overlay web page."
							. "`nClick the ""Visual Help Guide"" link for a guide to the information presented in the unit panel."

		unitPanelDrawStructureProgress_TT := "Displays a progress bar below any structure under construction."
		unitPanelDrawUnitProgress_TT := "Displays a progress bar below any unit in production."
		unitPanelDrawUpgradeProgress_TT := "Displays a progress bar below the current upgrades."
		unitPanelDrawLocalPlayer_TT := "Includes the local player in the match panel."
		OverlayIdent_TT := "Changes or disables the method of identifying players in the overlays.`n`nThe 'cycle identifier' hotkey allows you to change this setting during a match."

		Playback_Alert_Key_TT := #Playback_Alert_Key_TT := "Repeats the previous alert"

		worker_count_local_key_TT := "This will read aloud your current worker count."
		worker_count_enemy_key_TT := "This will read aloud your enemy's worker count. (only in 1v1)"
		warning_toggle_key_TT := "Pauses and resumes the program."
		ping_key_TT := "This hotkey will ping the map at the current mouse cursor location."
		race_reading_TT := read_races_key_TT := "When this hotkey is pressed the enemys' spawning races are read aloud "
		Auto_Read_Races_TT := "At the start of the match enemys' spawning races are automatically read aloud."
		idle_enable_TT := "If the user has been idle for longer than a set period of time (real seconds) then the game will be paused."
		TTidle_time_TT := idle_time_TT := "How long the user must be idle for (in real seconds) before the game is paused.`nNote: This value can be higher than the ""Don't Pause After"" parameter!"
		TTUserIdle_LoLimit_TT  := UserIdle_LoLimit_TT := "The game will not be paused before this time. (In game/SC2 seconds)"
		TTUserIdle_HiLimit_TT := UserIdle_HiLimit_TT := "The game will not be paused after this time. (In game/SC2 seconds)"

		speech_volume_TT := "The relative volume of the speech engine."
		programVolume_TT := "The overall program volume. This affects both the speech volume and the 'beeps'."
		speaker_volume_up_key_TT := speaker_volume_down_key_TT := "Changes the windows master volume."
		speech_volume_down_key_TT := speech_volume_up_key_TT := "Changes the programs TTS volume."
		program_volume_up_key_TT := program_volume_down_key_TT := "Changes the programs overall volume."
		input_method_TT := "Sets the method of artificial input.`n"
			. "Post message is now the only available method."
		;	. "Technically ""Event"" is the most 'reliable' across systems, but ""Input"" offers considerably better performance, key buffering and will work with almost all systems.`n"
		;	. "Using ""Input"" will also reduce the likelihood of the program interfering with user game play during automations`n`n"
		;	. "Hence, use ""Input"" unless it doesn't work."
		TT_EventKeyDelay_TT := EventKeyDelay_TT := "Sets the mouse and key delay (in ms) used when in SendEvent mode.`nLower values sends keystrokes faster - but setting this too low MAY cause some strokes to be missed.`nCommon values are (-1 to 10).`nNote: These delays are accumulative, and for functions which require numerous keystrokes e.g. split this delay can become quite substantial`n`nSendInput is faster and generally more reliable, hence SendInput should be used if it works on your system."

		TT_pClickDelay_TT := pClickDelay_TT := TT_pSendDelay_TT := pSendDelay_TT := "Sets the sleep time (in ms) between individual keystrokes/mousecliks."	
							. "`n`nNote: -1 (no delay) should work for everyone, but if unit selections are not being saved/restored, perhaps try increasing this to 2 or 3"
							. "`n`nValid values are:"
							. "`n-1: no delay"
							. "`n 0: Yields the remaining time slice to any other process (if requested)"
							. "`nAny positive integer."

		auto_update_TT := "While enabled the program will automatically check for new versions during startup."
		launch_settings_TT := "Display the options menu on startup."

		HideTrayIcon_TT := "Hides the tray icon and all popups/menus."
		TT2_MI_QueenDistance_TT := MI_QueenDistance_TT := "The edge of the hatchery creep is approximately 14`nThis helps prevent queens injecting on remote hatches - It works better with lower numbers"
		TT_F_Max_Injects_TT := F_Max_Injects_TT := "The max. number of 'forced' injects which can occur after a user 'F5'/auto-inject.`nSet this to a high number if you want the program to inject for you."
		TT_F_Alert_PreTime_TT := F_Alert_PreTime_TT := "The alert will sound X seconds before the forced inject."
		TT_F_Sleep_Time_TT := F_Sleep_Time_TT := "The amount of time spent idle after injecting each hatch.`n"
				. "This should be set as low as reliably possible so that the inject rounds are shorter and there is less chance of it affecting your gameplay.`n`n"
				. "This will vary for users, but 0 ms works reliably for me.`n"
				. "If 0 ms is not reliable, try increasing this value in increments of 1 ms."
		TT_FInjectHatchFrequency_TT := FInjectHatchFrequency_TT := "How often the larvae state of the hatcheries are checked. (In ms/real-time)`nAny uninjected hatches will then be injected.`n`nIncreasing this value will delay injects, that is, a hatch will remain uninjected for longer."
		TT_FInjectHatchMaxHatches_TT := FInjectHatchMaxHatches_TT := "The maximum number of hatches to be injected during an inject round"

		TT_AM_KeyDelay_TT := AM_KeyDelay_TT := TT_I_KeyDelay_TT := I_KeyDelay_TT := TT_CG_KeyDelay_TT := CG_KeyDelay_TT := "This sets the delay between key/mouse events`nLower numbers are faster, but they may cause problems.`n0-10`n`nWith regards to speed, changing the 'sleep' time will generally have a larger impact."
		TT_ChronoBoostSleep_TT := ChronoBoostSleep_TT := "Sets the amount of time that the program sleeps for during each automation cycle.`nThis has a large effect on the speed, and hence how 'human' the automation appears.`n`n"
				. "If you want instant chronoboosts, a value of 0 ms works reliably for me.`n"
				. "If 0 ms is not reliable for you, try increasing the sleep time in one or two ms increments. (it doesn't require much)"
		CG_chrono_remainder_TT := TT_CG_chrono_remainder_TT := "This is how many full chronoboosts will remain afterwards between all your nexi.`nA setting of 1 will leave 1 full chronoboost (or 25 energy) on one of your nexi."
		
		AutoChronoEnabled_TT := "All of the listed structures will be chronoed."
		AutoChronoSelectionEnabled_TT := "Only the currently selected structures will be chronoed."
										. "`n`nNote: The structures must still be listed in the panel on the right."

		AddUnitAutoChrono_TT := "Adds a new structure to the current list."
		RemoveUnitAutoChrono_TT := "Removes selected structure(s)."
		MoveUpUnitAutoChrono_TT := "Increases the selected structure's chrono priority."
		MoveDownUnitAutoChrono_TT := "Decreases the selected structure's chrono priority."

		 Inject_control_group_TT :=  #Inject_control_group_TT := "This refers to the control group used to store the current unit selection."
				. "`nThis allows the selected units to be restored after performing the automation."
				. "`n`nNote: Use a control group which you DO NOT use in game."
				. "`n`nYou must ensure the corresponding ""Set Control Group keys"" and ""Invoke Group Keys"" (under SC2 Keys on the left) match your SC2 hotkey setup."

		CG_control_group_TT := #CG_control_group_TT := "This refers to the control group used to store the current unit selection."
				. "`nThis allows the selected units to be restored after performing the automation."
				. "`n`n If ""Off"" is selected, the current unit selection will not be saved or restored."
				. "`n`nNote: Use a control group which you DO NOT use in game."
				. "`n`nYou must ensure the corresponding ""Set Control Group keys"" and ""Invoke Group Keys"" (under SC2 Keys on the left) match your SC2 hotkey setup."

		CG_nexus_Ctrlgroup_key_TT := "The control group which contains your nexuses."
				. "`n`nYou must ensure the corresponding ""Invoke Group Keys"" (under SC2 Keys on the left) match your SC2 hotkey setup."

		WorkerSplitType_TT := "Defines how many workers are rallied to each mineral patch."

		Auto_inject_sleep_TT := Edit_pos_var_TT := "Sets the amount of time that the program sleeps for during each automation cycle for the 'one button inject' method.`nThis has a large effect on the speed, and hence how 'human' the automation appears'.`n`n"
				. "The lowest reliable values will vary for users, but for myself the minimap method can be used with a sleep time of 0 ms.`n"
				. "The backspace methods require at least 8 ms."

		AutomationTerranCtrlGroup_TT := AutomationProtossCtrlGroup_TT := AutomationZergCtrlGroup_TT := "This refers to the control group used to store the current unit selection."
				. "`nThis allows the selected units to be restored after performing the automation."
				. "`n`nNote: Use a control group which you DO NOT use in game." 	

		AM_MiniMap_PixelColourAlpha_TT := AM_MiniMap_PixelColourRed_TT := AM_MiniMap_PixelColourGreen_TT := AM_MinsiMap_PixelColourBlue_TT := "The ARGB pixel colour of the mini map mineral field."
		#ResetPixelColour_TT := "Resets the pixel colour and variance to their default settings."
		#FindPixelColour_TT := "This sets the pixel colour for your exact system."
		AM_MiniMap_PixelVariance_TT := TT_AM_MiniMap_PixelVariance_TT := "A match will result if  a pixel's colour lies within the +/- variance range.`n`nThis is a percent value 0-100%"
		TT_AGDelay_TT := AG_Delay_TT := "The program will wait this period of time before adding the selected units to a control group.`nUse this if you want the function to look more 'human'.`n`nNote: Values greater than 0 probably the increase likelihood of miss-grouping units (especially on slow computers or during large battles with high APM)."
		TT_AGKeyReleaseDelay_TT := AGKeyReleaseDelay_TT := "An auto-group attempt will not occur until no key events (messages) have occurred for this amount of time."
				. "`n`nThis helps increase the robustness of the function."
				. "`nIf incorrect groupings are occurring try increasing this value."
				. "`n`nIf this value has been raised considerably (and depending on your Windows keyboard repeat rate) after selecting " 
				. "`nthe unit you might need to release any pressed key(s) for a fraction of a second before the grouping is attempted."
				. "`nMoving the mouse does not interrupt/influence this."
				. "`n`nValid values are: 50-700 ms"
		TT_AGBufferDelay_TT := AGBufferDelay_TT := "When an auto-group action IS attempted user input will be buffered for this period of time, I.E. button presses and mouse movements`nwill be delayed during this period."
				. "`n`nThis helps ensure the currently selected units are ones which should be grouped."
				. "`nIf incorrect groupings are occurring, you can try increasing this value."
				. "`nValid values are: 40-200 ms"

		TT_AGRestrictBufferDelay_TT := AGRestrictBufferDelay_TT := "When a 'restrict grouping' action is performed user input will be buffered for this period of time, I.E. button presses and mouse movements`nwill be delayed during this period."
				. "`n`nThis helps ensure the currently selected units are ones which should be grouped."
				. "`nIf incorrect groupings are occurring, you can try increasing this value."
				. "`nValid values are: 40-200 ms"


		Loop, 10
		{
			group := A_Index - 1
			AGAddToGroup%group%_TT := #AGAddToGroup%group%_TT := "The SC2 hotkey used to ADD units to control group " group "`n`nThis is usually Shift + " group
			AGSetGroup%group%_TT := #AGSetGroup%group%_TT := "The SC2 hotkey used to set the current unit selection to control group " group "`n`nThis is usually Control + " group
			AGInvokeGroup%group%_TT := #AGInvokeGroup%group%_TT := "The SC2 hotkey used to invoke/restore control group " group "`n`nThis is usually " group
		}


		TempHideMiniMapKey_TT := #TempHideMiniMapKey_TT := "This will disable the minimap overlay for three seconds,`nthereby allowing you to determine if you legitimately have vision of a unit or building."
		
		OpacityOverlayIdent_TT := "Select the overlay of interest then use the slider below to alter its transparency."

		loopList := "overlayIncomeTransparency,overlayMatchTransparency,overlayResourceTransparency,overlayArmyTransparency,overlayHarvesterTransparency,overlayIdleWorkerTransparency,overlayLocalColourTransparency,overlayMinimapTransparency,overlayMacroTownHallTransparency,overlayLocalUpgradesTransparency"
		loop, parse, loopList, `,
			%A_LoopField%_TT := "Sets the transparency of the overlay."
								. "`n`n100 = Fully opaque"
								. "`n0 = Fully transparent"
		

		ToggleUnitOverlayKey_TT := #ToggleUnitOverlayKey_TT := "Toggles the unit panel between the following states:"
							. "`n`n  -Units/structures"
							. "`n  -Units/structures + Upgrades"
							. "`n  -Upgrades"
							. "`n  -Off"
		ToggleIdentifierKey_TT := #ToggleIdentifierKey_TT := "Cycles the player identifier in the overlay.`n`nI.E. Hidden, names, or icons."
		CycleOverlayKey_TT := #CycleOverlayKey_TT := "Cycles through most of the overlays. (disabling/enabling)"

		AdjustOverlayKey_TT := #AdjustOverlayKey_TT := "Used to move and resize the overlays."
		TT_UserMiniMapXScale_TT := TT_UserMiniMapYScale_TT := UserMiniMapYScale_TT := UserMiniMapXScale_TT := "Adjusts the relative size of units on the minimap."
		TT_MiniMapRefresh_TT := MiniMapRefresh_TT := "Dictates how frequently the minimap is redrawn."
												. "`n`nNote: This is in ms and lower values result in the overlay being redrawn more frequently."
		BlendUnits_TT := "This will draw the units 'blended together', like SC2 does.`nIn other words, units/buildings grouped together will only have one border around all of them"

		TT_OverlayRefresh_TT := OverlayRefresh_TT := "Determines how frequently these overlays are refreshed:`nIncome, Resource, Army, Local Harvesters, Idle Workers, and Town Hall Macro."
												. "`n`nNote: This is in ms and lower values result in the overlays being redrawn more frequently."
		TT_UnitOverlayRefresh_TT := UnitOverlayRefresh_TT := "Determines how frequently the unit panel and local upgrades overlays are refreshed."
							. "`n`nThese require more resources than the other overlays and so they have a separate refresh rate."
							. "`nCare should be taken with very low values, as this can significantly increase CPU usage when there are many units on the map e.g. late game 4v4."
							. "`n`nLower this value if you want the progress bars to increase in a smoother manner."

		DrawLocalPlayerColourOverlay_TT := "During team games and while using hostile colours (green, yellow, and red) a small circle is drawn which indiactes your local player colour.`n`n"
											. "This is helpful when your allies refer to you by colour."
		HostileColourAssist_TT := "During team games while using hostile colours (green, yellow, and red) enemy bases will still be displayed using player colours.`n`n"
								. "This helps when co-ordinating attacks e.g. Let's attack yellow!"

		DrawUnitDestinations_TT := "Draws blue, green, orange, yellow, and red lines on the minimap to indicate an enemy unit's current move state and destination."
								. "`nAlso draws an alert icon at the destination of nuclear strikes."
								. "`n`nBlue - Patrol"
								. "`nGreen - Move"
								. "`nOrange - Transport unload"
								. "`nYellow - Nuclear strike (a nuke symbol is also displayed)"
								. "`nRed - Attack move"

		drawLocalPlayerIncome_TT := "Displays your own values at the bottom of the income overlay."	
		drawLocalPlayerResources_TT := "Displays your own values at the bottom of the resources overlay."						
		drawLocalPlayerArmy_TT := "Displays your own values at the bottom of the army overlay."	

		localUpgradesItemsPerRow_TT := "Defines the number of items displayed per row in the 'Local Upgrades' overlay."
									. "`n`nValues:"
									. "`n0: All items are drawn along a single row."
									. "`n1: All items are drawn in a single column."
									. "`n1-16: Each row will be limited to displaying this number of items."

		DrawMacroTownHallOverlay_TT := "Displays basic macro attributes for your current race."
									. "`n`nTerran: Available scans/mules. If none are available, (real) time until next scan."
									. "`nProtoss: Available chrono boosts. If none are available, (real) time until next chrono."
									. "`nZerg: Available larvae."
									. "`n`nWith regards to Terran and Protoss the scan/chrono count includes a decimal fraction indicating how close the next scan/chrono is to being available."
									. "`nMorphing orbitals are accounted for in this decimal fraction and the time until next scan."
									. "`n`nNote: Non-control-grouped town halls and flying orbitals are not included."										
		DrawLocalUpgradesOverlay_TT := "Displays your current upgrade items and their chrono state (if Protoss)."
									. "`nThis includes morphing hatches, lairs, spires, and command centres."
									. "`n`nUnchecked = Off"
									. "`nChecked = Progress bar (percent complete)"
									. "`nGreyed  = Time remaining"

		APMOverlayMode_TT := "Sets the drawing mode for the APM overlay."
							. "`n`n Unchecked = Enemies"
							. "`n Checked = Self"
							. "`n Greyed = Enemies + self (self is at bottom)"
		DrawPlayerCameras_TT := "Draws the enemy's camera on the minimap, i.e. it indicates the map area the player is currently looking at."
							. "`n`nNote: AI/computer players will not be drawn, as they never move the camera."
		SleepSplitUnit_TT := TT_SleepSplitUnits_TT := TT_SleepSelectArmy_TT := SleepSelectArmy_TT := "Increase this value if the function doesn't work properly`nThis time is required to update the selection buffer."
		Sc2SelectArmy_Key_TT := #Sc2SelectArmy_Key_TT := "The in game (SC2) button used to select your entire army.`nDefault is F2"
		ModifierBeepSelectArmy_TT := "Will play a beep if a modifer key is being held down.`nModifiers include the ctrl, alt, shift and windows keys."
		castSelectArmy_key_TT := #castSelectArmy_key_TT := "The button used to invoke this function."
		SelectArmyDeselectXelnaga_TT := "Units controlling the xelnaga watch towers will be removed from the selection group."
		SelectArmyOnScreen_TT := "When checked, only the units currently on screen will be selected.`n`nThis is new and hasn't been tested much.`nNote: If no units are on screen, then your previously selected units will remain selected."
		
		SelectArmyDeselectPatrolling_TT := "Units with a patrol command queued will be removed from the selection group.`n`nThis is very useful if you dont want to select some units e.g. banes/lings at your base or a drop ship waiting outside a base!`nJust set them to patrol and they will not be selected with your army."
		SelectArmyDeselectHoldPosition_TT := "Units with a hold position command queued will be removed from the selection group."
		SelectArmyDeselectFollowing_TT := "Units with a follow command queued will be removed from the selection group."
		SelectArmyDeselectLoadedTransport_TT := "Removes loaded medivacs and warp prisms"
		SelectArmyDeselectQueuedDrops_TT := "Removes transports which have a drop command queued`n`nDoesn't include tranports which have begun unloading."

	EasyUnloadHotkey_TT := #EasyUnloadHotkey_TT := "This hotkey performs two functions depending on if it is double tapped or held down."
													. "`n`nFunction 1) Double tap this key to select any loaded transports visible on the screen."
													. "`n`nFunction 2) Hold this button and wave the mouse over the loaded transports to begin unloading them."		
													. "`n`nClick the 'About' button below for more information."
		EasyUnload_T_Key_TT := EasyUnload_P_Key_TT := EasyUnload_Z_Key_TT := "This needs to correspond to the SC2 unload all key."
															. "`nThis key is used by both the 'Easy Select/Cursor Unload' and 'Unload All' functions."
															. "`n`nIf the unload all feature is enabled, then when you double tap this key (and transports are the selected and highlighted unit type) all of the transports will immediately begin unloading."

		loop, parse, l_Races, `,
		{
			New%A_LoopField%QuickSelect_TT := "Creates a new quick select item."
			Delete%A_LoopField%QuickSelect_TT := "Delete the currently displayed item."
			quickSelect%A_LoopField%Enabled_TT := "Enables this item during a match"
			#quickSelect%A_LoopField%_Key_TT := quickSelect%A_LoopField%_Key_TT := "The hotkey used to invoke this quick select item."
			
			QuickSelect%A_LoopField%BaseSelection_TT := "This determines which units are initially selected. After this initial selection units are either kept or removed as required by the other options."
														. "`n`nArmy: The SC select all army hotkey is used."
														. "`nUnits On Screen: The units currently on the screen are selected. This produces the same result as the 'remove units outside of camera view' option in previous MacroTrainer versions."
														. "`nCurrent Selection: The currently selected units are used."
														. "`nControl Groups: The specified control group is used."
														. "`n`nNote:"
														. "`nStructures are automatically removed, but non-army units such as workers, queens, mules, overlords etc are not!"
														. "`nIf the starting selection is set to anything other than 'Army' and you are not specifying the unit types to keep, you should enable the 'Remove these types' option and specify them there."

			quickSelect%A_LoopField%SelectUnitTypes_TT := "When enabled the specified units are kept selected. All other types of units are removed."
														. "`n`nNote: Disabling both the 'Keep these types' and 'Remove these types' options, disables filtering by unit type."
			quickSelect%A_LoopField%DeselectUnitTypes_TT := "When enabled the specified unit types are removed."
														. "`n`nNote: Disabling the 'Keep these types' and 'Remove these types' options, disables filtering by unit type."
			quickSelect%A_LoopField%UnitsArmy_TT := #quickSelect%A_LoopField%UnitsArmy_TT := "These units types will either be removed from selection or kept in the selection as governed by the checkboxes above."
													. "`nIf both of the checkboxes are unticked then this list is ignored."
			quickSelect%A_LoopField%CreateControlGroup_TT := "The remaining selected units will be stored in the specified control group."
			quickSelect%A_LoopField%AddToControlGroup_TT := "The remaining selected units will be added to the specified control group."

			QuickSelect%A_LoopField%StoreSelection_TT := "Units are either assigned or added to this control group depending upon the specified options."
										. "`n`nNote: This uses the specified 'control group' keys as defined in the SC2 Keys section (on the left)."

			QuickSelect%A_LoopField%AttributeMode_TT := "Determines how the below attributes alters the selection."
													. "`nRemove: Units which have one or more of the marked attributes are removed."
													. "`nKeep: Units which have one or more of the marked attributes are kept. (All others are removed.)"

			quickSelect%A_LoopField%DeselectXelnaga_TT := "Units which have control of a Xelnaga tower."
			;quickSelect%A_LoopField%OnScreen_TT := SelectArmyOnScreen_TT
			quickSelect%A_LoopField%DeselectPatrolling_TT := "Units which are patrolling or queued to perform a patrol command."
			quickSelect%A_LoopField%DeselectAttacking_TT := "Units which are attacking or queued to perform an attack command."
			quickSelect%A_LoopField%DeselectHoldPosition_TT := "Units which are on hold position or queued to perform a hold position command."
			quickSelect%A_LoopField%DeselectIdle_TT := "Units which are not performing any action/command."
			quickSelect%A_LoopField%DeselectFollowing_TT := "Units which are following another unit or queued to perform a follow command."		
			quickSelect%A_LoopField%DeselectLoadedTransport_TT := "Refers to medivacs, warp prisms, phasing warp prisms, and overlords which contain units."
																. "`n`nNote: With regards to zerg, this option is disabled if the 'starting selection' is set to 'Army', as the army selection does not contain overlords."
			quickSelect%A_LoopField%DeselectEmptyTransport_TT := "Refers to medivacs, warp prisms, phasing warp prisms, and overlords which do not contain units."
																. "`n`nNote: With regards to zerg, this option is disabled if the 'starting selection' is set to 'Army', as the army selection does not contain overlords."
			quickSelect%A_LoopField%DeselectQueuedDrops_TT := "Refers to medivacs, warp prisms, phasing warp prisms, and overlords are set/queued to perform an unload command."
																. "`n`nNote: With regards to zerg, this option is disabled if the 'starting selection' is set to 'Army', as the army selection does not contain overlords."
		
			quickSelect%A_LoopField%DeselectLowHP_TT := "Refers to units with" (A_LoopField = "Protoss" ? " shields " : " health ") "lower than the specified (percentage) value. "
			Edit_quickSelect%A_LoopField%DeselectLowHP_TT := quickSelect%A_LoopField%HPValue_TT := "This is a percentage value i.e. 40 = 40%."
		}

		castRemoveDamagedUnits_key_TT := #castRemoveDamagedUnits_key_TT := castRemoveUnit_key_TT := #castRemoveUnit_key_TT 
			:= castSplitUnit_key_TT := #castSplitUnit_key_TT := "The hotkey used to invoke this function."
		RemoveDamagedUnitsCtrlGroup_TT := SplitctrlgroupStorage_key_TT := #SplitctrlgroupStorage_key_TT := "This refers to the control group used to store the current unit selection."
				. "`nThis allows the selected units to be restored after performing the automation."
				. "`n`nNote: Use a control group which you DO NOT use in game."
				. "`n`nYou must ensure the corresponding ""Set Control Group keys"" and ""Invoke Group Keys"" (under SC2 Keys on the left) match your SC2 hotkey setup."

		TT_DeselectSleepTime_TT :=  DeselectSleepTime_TT := "Time between deselecting units from the unit panel.`nThis is used by the split and select army, and deselect unit functions"

		Edit_RemoveDamagedUnitsHealthLevel_TT := RemoveDamagedUnitsHealthLevel_TT := "Terran and Zerg units with health lower than or equal to this percent will be removed from selection`n"
										. "and moved to the current mouse cursor position."
		Edit_RemoveDamagedUnitsShieldLevel_TT := RemoveDamagedUnitsShieldLevel_TT := "Protoss units with shields lower than or equal to this percent will be removed from selection`n"
										. "and moved to the current mouse cursor position."

		#Sc2SelectArmyCtrlGroup_TT := Sc2SelectArmyCtrlGroup_TT := "The control Group (key) in which to store the army.`nE.G. 1,2,3-0"
															. "`n`nSelect 'Off' to disable grouping."
															. "`n`nYou must ensure the corresponding ""Set Control Group keys"" match your SC2 hotkey setup."

		l_DeselectArmy_TT := #l_DeselectArmy_TT := "These unit types will be deselected."
		
		EasyUnloadStorageKey_TT := "The selected/unloaded transports will be stored in this control group."		
							. "`n`nYou must ensure the corresponding ""Set Control Group keys"", ""Add to Control Group Keys"",`nand ""Invoke Group Keys"" (under SC2 Keys on the left) match your SC2 hotkey setup."									

		F_Inject_ModifierBeep_TT := "If the modifier keys (Shift, Ctrl, or Alt) or Windows Keys are held down when an Inject is attempted, a beep will heard.`nRegardless of this setting, the inject round will not begin until after these keys have been released."
		BlockingStandard_TT := BlockingFunctional_TT := BlockingNumpad_TT := BlockingMouseKeys_TT := BlockingMultimedia_TT := BlockingMultimedia_TT := BlockingModifier_TT := "During certain automations these keys will be buffered or blocked to prevent interruption to the automation and your game play."
		SC2AdvancedEnlargedMinimap_TT := "This option alters the size and position of the minimap."
									. "`n`nThese minimap coordinates are used for both drawing and automations."
									. "`nTherefore only enable this setting if you have used the 'SC2-Advanced' hack to enlarge the minimap!"
		LauncherRadioBattleNet_TT := LauncherRadioStarCraft_TT := LauncherRadioDisabled_TT := "During startup MacroTrainer will attempt to launch either the Battle.net app or Starcraft."


		LwinDisable_TT := "Disables the Left Windows Key while in a SC2 match.`n`nMacro Trainer Left windows hotkeys (and non-overridden windows keybinds) will still function."
		Key_EmergencyRestart_TT := #Key_EmergencyRestart_TT := "If pressed three times, this hotkey will restart the program.`n"
					. "This is useful in the rare event that the program malfunctions or you lose keyboard/mouse input"

		HighlightInvisible_TT := #UnitHighlightInvisibleColour_TT := "All invisible, cloaked, and burrowed units will be drawn with this colour.`n"
					. "This will instantly tell you if it's safe to look at the unit i.e. would you legitimately have vision of it."
					. "`n`nNote: If a unit already has a custom colour highlight, then that unit will be drawn using its specific highlight colour."
		HighlightHallucinations_TT := #UnitHighlightHallucinationsColour_TT := "Hallucinated units will be drawn using this colour."

		MTCustomProgramName_TT := "This will create a new copy of the program with the specified program/process name.`n`nAfter applying the changes you MUST reload the script or launch the newly created .exe file"
								. "`n`nTo change back to the original name and exe, simply clear/blank the name field, save the settings, exit the program and then use the original exe file"

		MTChageIconButton_TT := "This will attempt to replace the program's included icon files with a .ico file of your choosing.`n`nThis is not guaranteed to work!"

		MTChageIconDefaultButton_TT := "This will attempt to restore the program's default icons.`n`nThis is not guaranteed to work!"

		Short_Race_List := "Terr|Prot|Zerg"
		loop, parse, l_races, `,
			while (10 > i := A_index-1)
				LG_%A_LoopField%%i%_TT := "Only the specified units below can be bound to their respective control groups.`nAny unit can be grouped to a blank group.`nThis can be used with or without 'Auto Grouping'."

			loop, parse, Short_Race_List, |
			AG_Enable_%A_LoopField%_TT := "Selected units will be automatically added to their set control groups."

		Report_Email_TT := "Required if you are looking for a response"
	}
	OnMessage(0x200, "mainThreadMessageHandler")
	Gosub, G_GuiSetupDrawMiniMapDisable ; Disable controls based on current drawing settings
	GuI, Options:Show, w615 h505, V%ProgramVersion% Settings
}
Return

HumanMouseWarning:
	GuiControlGet, Checked, ,HumanMouse 
	if Checked
		msgbox, 16, Human Mouse Movement Warning, The only reason to possibly use this setting, is if you are streaming your games and want your viewers to think you're legit.`n`nThis affects injects and chronoboost movements.`nThis setting moves the mouse in a somewhat random arc/line.`n`nThe 'Time' setting dictates the duration of each individual mouse movement. For each movement, a random move time is generated using the upper and lower time bounds.`n`nI repeat DO NOT USE this unless you're a streamer! It offers no advantages!
Return


G_SwapOverlayOpacitySliders:
GuiControlGet, selection, , %A_GuiControl%
GuiControl, % "show" instr(selection, "Income"), overlayIncomeTransparency
GuiControl, % "show" instr(selection, "Match"), overlayMatchTransparency
GuiControl, % "show" instr(selection, "Resource"), overlayResourceTransparency
GuiControl, % "show" instr(selection, "Army"), overlayArmyTransparency
GuiControl, % "show" instr(selection, "Harvester"), overlayHarvesterTransparency
GuiControl, % "show" instr(selection, "Idle Worker"), overlayIdleWorkerTransparency
GuiControl, % "show" instr(selection, "Local Colour"), overlayLocalColourTransparency
GuiControl, % "show" instr(selection, "Minimap"), overlayMinimapTransparency
GuiControl, % "show" instr(selection, "APM"), overlayAPMTransparency
GuiControl, % "show" instr(selection, "Town Hall"), overlayMacroTownHallTransparency
GuiControl, % "show" instr(selection, "Local Upgrades"), overlayLocalUpgradesTransparency
return

gToggleAlignUnitGUI:
GuiControlGet, state,, SplitUnitPanel
GUIControl, Enable%state%, unitPanelAlignNewUnits
return 


GUIMacroWarningsWorkerDisplayRace:
GuiControlGet, RaceGUI,, %A_GuiControl%
for i, race in ["Terran", "Protoss", "Zerg"]
{
	for k, controlID in [	"MacroWarningsWorker|GroupBoxGUI"
						, "WarningsWorker|Enable"
						, "TT_WarningsWorker|TimeWithoutProduction"
						, "WarningsWorker|TimeWithoutProduction"
						, "TT_WarningsWorker|MinWorkerCount"
						, "WarningsWorker|MinWorkerCount"
						, "TT_WarningsWorker|MaxWorkerCount"
						, "WarningsWorker|MaxWorkerCount"
						, "TT_WarningsWorker|FollowUpCount"
						, "WarningsWorker|FollowUpCount"
						, "TT_WarningsWorker|FollowUpDelay"
						, "WarningsWorker|FollowUpDelay"
						, "WarningsWorker|SpokenWarning" ]
	{
		StringReplace, controlID, controlID, |, %race%,
		GuiControl, % "hide " (race != RaceGUI) , %controlID%
	}
}
return 


BasicInjectToggleOptionsGUI:
GuiControlGet, selectedItem,, %A_GuiControl%
for i, controlID in ["BackspaceGroupBoxID", "BackspaceDragTextID", "Drag_origin", "BackspaceTextCameraStoreID", "BI_create_camera_pos_x", "#BI_create_camera_pos_x", "BackspaceTextCameraGotoID", "BI_camera_pos_x", "#BI_camera_pos_x"]
{
	if 	(controlID = "BackspaceDragTextID" || controlID = "Drag_origin") ; This should only be shown for the true backspace method
		GuiControl, % "hide" (selectedItem != "Backspace"), %controlID%
	else GuiControl, % "hide" !instr(selectedItem, "Backspace" ), %controlID%
}
return 

AutoBuildOptionsMenuHotkeyModeCheck:
GuiControlGet, g1,, AutoBuildGUIkeyMode
if (g1 := g1 = "KeyDown")
	GuiControl,, AutoBuildEnableInteractGUIHotkey, 0 ; Uncheck it if keyDown
GuiControl, Disable%g1%, AutoBuildEnableInteractGUIHotkey
GuiControl, Disable%g1%, #AutoBuildInteractGUIKey
GuiControl, Disable%g1%, AutoBuildInactiveOpacity
GuiControl, Disable%g1%, InactiveOpacticyTextAssociatedVariable
GuiControlGet, g1,, AutoBuildEnableInteractGUIHotkey
if !g1
{
	GuiControl, Disable, AutoBuildInactiveOpacity
	GuiControl, Disable, InactiveOpacticyTextAssociatedVariable
}
return 

SmartGeyserOptionsMenuEnableCheck:
GuiControlGet, g1,, SmartGeyserEnable
GuiControl, Enable%g1%, SmartGeyserReturnCargo
GuiControl, Enable%g1%, SmartGeyserCtrlGroup
return 


GUIControlGroupCheckInjects:
GuiControlGet, g1,, Inject_control_group
GuiControlGet, g2,, MI_Queen_Group
if (g1 = g2)
	msgbox, 48, Config Warning!, The storage and queen control groups must NOT be the same.`nRefer to their respective tooltips for more information.
return
GUIControGroupCheckChrono:
GuiControlGet, g1,, CG_control_group
GuiControlGet, g2,, CG_nexus_Ctrlgroup_key
if (g1 = g2)
	msgbox, 48, Config Warning!, The storage and nexus control groups must NOT be the same.`nRefer to their respective tooltips for more information.
return
GUIControlGroupCheckAutoWorkerTerran:
GUIControlGroupCheckAutoWorkerProtoss:
GuiControlGet, g1,, % A_ThisLabel = "GUIControlGroupCheckAutoWorkerTerran" ? "Base_Control_Group_T_Key" : "Base_Control_Group_P_Key"
GuiControlGet, g2,, % A_ThisLabel = "GUIControlGroupCheckAutoWorkerTerran" ? "AutoWorkerStorage_T_Key" : "AutoWorkerStorage_P_Key"
if (g1 = g2)
	msgbox, 48, Config Warning!, The base and storage control groups must NOT be the same.`nRefer to their respective tooltips for more information.
return


SC2AdvancedEnlargedMinimapWarning:
GuiControlGet, g1,, SC2AdvancedEnlargedMinimap
if g1
	msgbox, 48, Config Warning!, % "Only enable this setting if you have used the 'SC2-Advanced' hack ('Minimal-Interface' option) to enlarge the minimap!"
								. "`n`nDue to the altered UI none of the automations are guaranteed to work correctly even if they 'appear' to work. "
								. "The only exception to this is the auto-grouping function."
return
QuickSelectGUBaseSelectionZergTransportCheck:
; Zerg army selection will not include transports (orverlords) so uncheck them and disable
if instr(A_GuiControl, "Zerg")
{
	GuiControlGet, g1,, QuickSelectZergBaseSelection
	if g1 = Army
	{
		GuiControl,, quickSelectZergDeselectLoadedTransport, 0
		GuiControl,, quickSelectZergDeselectEmptyTransport, 0
		GuiControl, Disable, quickSelectZergDeselectLoadedTransport
		GuiControl, Disable, quickSelectZergDeselectEmptyTransport
	}
	else 
	{
		GuiControl, Enable, quickSelectZergDeselectLoadedTransport
		GuiControl, Enable, quickSelectZergDeselectEmptyTransport		
	}
}
return

QuickSelectGUIEmptyLoadedTransportCheck:
GuiControlGet, g1,, % A_GuiControl
if g1
{
	if instr(A_GuiControl, "Empty")
		g2 := "DeselectLoadedTransport"
	else g2 := "DeselectEmptyTransport"
	if instr(A_GuiControl, "Terran")
		GuiControl,, % "quickSelectTerran" g2, 0
	else if instr(A_GuiControl, "Protoss")
		GuiControl,, % "quickSelectProtoss" g2, 0
	else GuiControl,, % "quickSelectZerg" g2, 0
}
return
QuickSelectGUISelectTypesCheck:
if instr(A_GuiControl, "Terran")
	race := "Terran"
else if instr(A_GuiControl, "Protoss")
	race := "Protoss"
else race := "Zerg"

GuiControlGet, g1,, quickSelect%race%SelectUnitTypes
GuiControlGet, g2,, quickSelect%race%DeselectUnitTypes
if !g1 && !g2 
{
	GuiControl, disable, quickSelect%race%UnitsArmy
	GuiControl, disable, #quickSelect%race%UnitsArmy
	return ; cos enabling below
}
else (g1 && g2)
{
	if instr(A_GuiControl, "DeselectUnitTypes")
		GuiControl,, quickSelect%race%SelectUnitTypes, 0
	else 
		GuiControl,, quickSelect%race%DeselectUnitTypes, 0
}
GuiControl, enable, quickSelect%race%UnitsArmy
GuiControl, enable, #quickSelect%race%UnitsArmy
return
QuickSelectGUICreateAddToGroupCheck:
if instr(A_GuiControl, "Terran")
	race := "Terran"
else if instr(A_GuiControl, "Protoss")
	race := "Protoss"
else race := "Zerg"

GuiControlGet, g1,, quickSelect%race%CreateControlGroup 
GuiControlGet, g2,, quickSelect%race%AddToControlGroup
if !g1 && !g2
{
	GuiControl, hide, QuickSelect%race%StoreSelection
	return
}
if (g1 && g2) ; need to uncheck one
{
	if instr(A_GuiControl, "CreateControlGroup")
		GuiControl,, quickSelect%race%AddToControlGroup, 0
	else GuiControl,, quickSelect%race%CreateControlGroup, 0
}
GuiControlGet, g1,, quickSelect%race%CreateControlGroup 
GuiControlGet, g2,, quickSelect%race%AddToControlGroup
if g1
{
	GuiControlGet, controlPos, Pos, quickSelect%race%CreateControlGroup 
	GuiControl, Move, QuickSelect%race%StoreSelection, %  "y" controlPosy-3
	GuiControl, Show, QuickSelect%race%StoreSelection  
}
else if g2
{
	GuiControlGet, controlPos, Pos, quickSelect%race%AddToControlGroup 
	GuiControl, Move, QuickSelect%race%StoreSelection, %  "y" controlPosy-3 
	GuiControl, Show, QuickSelect%race%StoreSelection   	
}
return


; Still need to save the currently displayed item (incase user hasnt clicked a button
; which goes here to save)

g_QuickSelectGui:
if instr(A_GuiControl, "Terran")
	race := "Terran"
else if instr(A_GuiControl, "Protoss")
	race := "Protoss"
else 
	race := "Zerg"

if instr(A_GuiControl, "New")
{
	; Due to changes in quickSelect the unit tab can now be empty and still be valid
	; so these checks are disabled
	; I should probably add a warning though if 'select/Remove these types' are checked and unit tab is empty
	;GuiControlGet, units, , quickSelect%Race%UnitsArmy ; comma delimited list
	;if !trim(units, " `t`,")
	;{
	;	msgbox, % 64 + 8192 + 262144, New Item, The current unit field is empty.`n`nPlease add some units before creating a new item.
	;	return
	;}
	;saveCurrentQuickSelect(race, aQuickSelectCopy)
	;if blankIndex := quickSelectFindPosiitionWithNoUnits(race, aQuickSelectCopy) 
	;{
	;	aQuickSelectCopy[race "IndexGUI"] := blankIndex
	;	showQuickSelectItem(race, aQuickSelectCopy)
	;}
	;else 
	;{
		aQuickSelectCopy[race "IndexGUI"] := aQuickSelectCopy[race "MaxIndexGUI"] := round(aQuickSelectCopy[race "MaxIndexGUI"] + 1)	
		blankQuickSelectGUI(race)
	;}
}
else if instr(A_GuiControl, "Delete")
{

	aQuickSelectCopy[Race].remove(aQuickSelectCopy[race "IndexGUI"])

	if (aQuickSelectCopy[race "MaxIndexGUI"] = 1)
	{
		blankQuickSelectGUI(race)
		return
	}
	if (aQuickSelectCopy[race "IndexGUI"] > 1)
		aQuickSelectCopy[race "IndexGUI"] := round(aQuickSelectCopy[race "IndexGUI"] - 1)
	aQuickSelectCopy[race "MaxIndexGUI"] := round(aQuickSelectCopy[race "MaxIndexGUI"] - 1)
	showQuickSelectItem(race, aQuickSelectCopy)
}
else if instr(A_GuiControl, "Next")
{
	if (aQuickSelectCopy[race "MaxIndexGUI"] = 1)
		return 
	saveCurrentQuickSelect(race, aQuickSelectCopy)
	if (aQuickSelectCopy[race "IndexGUI"] = aQuickSelectCopy[race "MaxIndexGUI"])
		aQuickSelectCopy[race "IndexGUI"] := 1
	else 
		aQuickSelectCopy[race "IndexGUI"] := round(aQuickSelectCopy[race "IndexGUI"] + 1)
	showQuickSelectItem(race, aQuickSelectCopy)		
}
else if instr(A_GuiControl, "Previous")
{

	if (aQuickSelectCopy[race "MaxIndexGUI"] = 1)
		return 
	saveCurrentQuickSelect(race, aQuickSelectCopy)
	if (aQuickSelectCopy[race "IndexGUI"] = 1)
		aQuickSelectCopy[race "IndexGUI"] := aQuickSelectCopy[race "MaxIndexGUI"]
	else 
		aQuickSelectCopy[race "IndexGUI"] := round(aQuickSelectCopy[race "IndexGUI"] - 1)
	showQuickSelectItem(race, aQuickSelectCopy)
}
; so doesnt get set to 0
if !aQuickSelectCopy[Race "IndexGUI"] 
	aQuickSelectCopy[Race "IndexGUI"] := 1
if !aQuickSelectCopy[race "MaxIndexGUI"]
	aQuickSelectCopy[race "MaxIndexGUI"] := 1	
GUIControl, , GroupBox%race%QuickSelect, % " Quick Select Navigation " aQuickSelectCopy[Race "IndexGUI"] " of " aQuickSelectCopy[race "MaxIndexGUI"]	
GUIControl, , GroupBoxItem%race%QuickSelect, % " Quick Select Item " aQuickSelectCopy[Race "IndexGUI"]
state := aQuickSelectCopy[race "MaxIndexGUI"] > 1 ? True : False
GUIControl, Enable%state%, Next%race%QuickSelect
GUIControl,  Enable%state%, Previous%race%QuickSelect

return 

checkQuickSelectHotkey(race, byRef aQuickSelectCopy)
{
	arrayPosition := aQuickSelectCopy[race "IndexGUI"]
	GuiControlGet, hotkey, , quickSelect%Race%_Key
	if !hotkey
	{
		msgbox, % 64 + 8192 + 262144, New Item, You forgot to assign a hotkey.`n`nPlease set the hotkey before proceeding.
		return True
	}
}

; Doesn't check for validity of units. But other functions/checks should ensure this anyway.
quickSelectHasUnits(race, byRef aQuickSelectCopy, arrayPosition)
{
	return round(aQuickSelectCopy[Race, arrayPosition, "units"].MaxIndex())
}

quickSelectFindPosiitionWithNoUnits(race, byRef aQuickSelectCopy)
{
	loop, 1000
	{
		if !IsObject(aQuickSelectCopy[race, A_Index])
			break
		if !aQuickSelectCopy[race, A_Index, "units"].MaxIndex()
			return A_Index
	}
	return 0
}

; need to save the current displayed items as they might not be saved yet
; e.g. terran item 3 of 3 is displayed but might not be saved

saveCurrentDisplayedItemsQuickSelect(byRef aQuickSelectCopy)
{
	saveCurrentQuickSelect("Terran", aQuickSelectCopy)
	saveCurrentQuickSelect("Protoss", aQuickSelectCopy)
	saveCurrentQuickSelect("Zerg", aQuickSelectCopy)
}

iniWriteAndUpdateQuickSelect(byRef aQuickSelectCopy, byRef aQuickSelect)
{
	
	; save the currently displayed items for each race (as they might not be saved already)
	lRaces := "Terran,Protoss,Zerg"
	; I've noticed sometimes the terran items will disappear (except for the first one - maybe couple)
	; Cant pinpoint when this occurs. Perhaps if program restarts after deleting the section below
	; but before finishing writing out the units??? 
	; This only seems to occur when im restarting a lot and testing stuff in the options menu
	; I've added a critcal section here - this should delay the restart hotkey firing (but not if closed via tray icon)
	; But I doubt this is what is causing the issue - probably a bug elsewhere but I can't seem to work out how to invoke it
	critical, on
	loop, parse, lRaces, `, 
	{
		race := A_LoopField
		section := "quick select " race
		IniDelete, %config_file%, %section% ;clear the list
		for index, object in aQuickSelectCopy[race]
		{	
			; Use the loop index in case something went wrong and there is a gap in the index of the object 1-->2-->4 
			; as iniread function will stop at first non-existent item
			itemNumber := A_Index 
			for key, value in object
			{
				if (key = "units")
				{
					value := ""
					for i, unitId in  object["units"]
						value .= aUnitName[unitId] ","
					while InStr(value, ",,")
						StringReplace, value, value, `,`,, `,, All	; remove double commands if the name lookup failed and resulted in empty then comma
					value := Trim(value, " `t`,") ; remove the last comma
					sort, value, D`, U ;remove duplicates 
				}
				IniWrite, %value%, %config_file%, %section%, %itemNumber%_%key%
			}
		}
	}
	aQuickSelect := aQuickSelectCopy
	critical, off
	return
}

iniReadQuickSelect(byRef aQuickSelectCopy, byRef aQuickSelect)
{
	lRaces := "Terran,Protoss,Zerg"
	
	aQuickSelectCopy := [], aQuickSelect := []

	loop, parse, lRaces, `, 
	{
		arrayPosition := 0
		race := A_LoopField
		section := "quick select " race
		loop 
		{
			arrayPosition++
			; itemNumber := arrayPosition
			; Use A_Index, as if no unit exists, then will decrement arrayPosition
			; causing an infinite loop as it reads the same ini key
			itemNumber := A_Index
			IniRead, enabled, %config_file%, %section%, %itemNumber%_enabled, error

			if (enabled = "error")
				break 

			IniRead, hotkey, %config_file%, %section%, %itemNumber%_hotkey, %A_Space%
			IniRead, units, %config_file%, %section%, %itemNumber%_units, %A_Space%
			IniRead, CreateControlGroup, %config_file%, %section%, %itemNumber%_CreateControlGroup, 0 
			IniRead, AddToControlGroup, %config_file%, %section%, %itemNumber%_AddToControlGroup, 0 
			IniRead, storeSelection, %config_file%, %section%, %itemNumber%_storeSelection, 0 
			IniRead, BaseSelection, %config_file%, %section%, %itemNumber%_BaseSelection, Army 
			IniRead, AttributeMode, %config_file%, %section%, %itemNumber%_AttributeMode, Remove 
			IniRead, SelectUnitTypes, %config_file%, %section%, %itemNumber%_SelectUnitTypes, 1 
			IniRead, DeselectUnitTypes, %config_file%, %section%, %itemNumber%_DeselectUnitTypes, 0 
			IniRead, DeselectXelnaga, %config_file%, %section%, %itemNumber%_DeselectXelnaga, 0 
			IniRead, DeselectPatrolling, %config_file%, %section%, %itemNumber%_DeselectPatrolling, 0 
			IniRead, DeselectLoadedTransport, %config_file%, %section%, %itemNumber%_DeselectLoadedTransport, 0 
			IniRead, DeselectEmptyTransport, %config_file%, %section%, %itemNumber%_DeselectEmptyTransport, 0 
			IniRead, DeselectHallucinations, %config_file%, %section%, %itemNumber%_DeselectHallucinations, 0 
			IniRead, DeselectIdle, %config_file%, %section%, %itemNumber%_DeselectIdle, 0 
			IniRead, DeselectQueuedDrops, %config_file%, %section%, %itemNumber%_DeselectQueuedDrops, 0 
			IniRead, DeselectHoldPosition, %config_file%, %section%, %itemNumber%_DeselectHoldPosition, 0 
			IniRead, DeselectAttacking, %config_file%, %section%, %itemNumber%_DeselectAttacking, 0 
			IniRead, DeselectFollowing, %config_file%, %section%, %itemNumber%_DeselectFollowing, 0 
			IniRead, DeselectLowHP, %config_file%, %section%, %itemNumber%_DeselectLowHP, 0 
			IniRead, HPValue, %config_file%, %section%, %itemNumber%_HPValue, 40 

		    aQuickSelectCopy[Race, arrayPosition] := []
		    aQuickSelectCopy[Race, arrayPosition, "enabled"] := enabled
		    aQuickSelectCopy[Race, arrayPosition, "hotkey"] := hotkey
		    aQuickSelectCopy[Race, arrayPosition, "units"] := []

		    unitExists := false
		    sort, units, D`, U ;remove duplicates 
		    loop, parse, units, `,
		    {
		    	unitName := A_LoopField

		    	if aUnitID.HasKey(unitName) 
		    	{
		    		aQuickSelectCopy[Race, arrayPosition, "units"].insert(aUnitID[unitName])
		    		unitExists := True
		    	}
		    }

		    if !unitExists
		    	SelectUnitTypes := DeselectUnitTypes := 0

		    aQuickSelectCopy[Race, arrayPosition, "SelectUnitTypes"] := SelectUnitTypes
		    aQuickSelectCopy[Race, arrayPosition, "DeselectUnitTypes"] := DeselectUnitTypes
		    aQuickSelectCopy[Race, arrayPosition, "CreateControlGroup"] := CreateControlGroup
		    aQuickSelectCopy[Race, arrayPosition, "AddToControlGroup"] := AddToControlGroup
		    aQuickSelectCopy[Race, arrayPosition, "storeSelection"] := storeSelection
		    aQuickSelectCopy[Race, arrayPosition, "BaseSelection"] := BaseSelection
		    aQuickSelectCopy[Race, arrayPosition, "AttributeMode"] := AttributeMode
		    aQuickSelectCopy[Race, arrayPosition, "DeselectXelnaga"] := DeselectXelnaga
		    aQuickSelectCopy[Race, arrayPosition, "DeselectPatrolling"] := DeselectPatrolling
		    aQuickSelectCopy[Race, arrayPosition, "DeselectLoadedTransport"] := DeselectLoadedTransport
		    aQuickSelectCopy[Race, arrayPosition, "DeselectEmptyTransport"] := DeselectEmptyTransport
		    aQuickSelectCopy[Race, arrayPosition, "DeselectHallucinations"] := DeselectHallucinations
		    aQuickSelectCopy[Race, arrayPosition, "DeselectIdle"] := DeselectIdle
		    aQuickSelectCopy[Race, arrayPosition, "DeselectQueuedDrops"] := DeselectQueuedDrops
		    aQuickSelectCopy[Race, arrayPosition, "DeselectHoldPosition"] := DeselectHoldPosition
		    aQuickSelectCopy[Race, arrayPosition, "DeselectAttacking"] := DeselectAttacking
		    aQuickSelectCopy[Race, arrayPosition, "DeselectFollowing"] := DeselectFollowing
		    aQuickSelectCopy[Race, arrayPosition, "DeselectLowHP"] := DeselectLowHP
		    aQuickSelectCopy[Race, arrayPosition, "HPValue"] := HPValue

		    ;if !unitExists
		    ;	aQuickSelectCopy[Race].remove(arrayPosition--) ;post-decrement 
		}
		aQuickSelectCopy[race "MaxIndexGui"] := Round(aQuickSelectCopy[race].MaxIndex())
	}	
	aQuickSelect := aQuickSelectCopy
	return 
}



blankQuickSelectGUI(race)
{
	GUIControl, , quickSelect%Race%Enabled, 0
	GUIControl, , quickSelect%Race%_Key,
	GUIControl, , quickSelect%Race%UnitsArmy,
	GUIControl, , quickSelect%Race%UnitsArmy,
	GUIControl, , quickSelect%Race%CreateControlGroup, 0
	GUIControl, , quickSelect%Race%AddToControlGroup, 0
	GuiControl, hide, QuickSelect%race%StoreSelection ; hide it
	GuiControl, ChooseString, QuickSelect%Race%StoreSelection, 0
	GuiControl, ChooseString, QuickSelect%Race%BaseSelection, Army
	GuiControl, ChooseString, QuickSelect%Race%AttributeMode, Remove

	GUIControl, , quickSelect%Race%SelectUnitTypes, 1
	GUIControl, , quickSelect%Race%DeselectUnitTypes, 0
	GUIControl, , quickSelect%Race%DeselectXelnaga, 0
	GUIControl, , quickSelect%Race%DeselectPatrolling, 0
	GUIControl, , quickSelect%Race%DeselectLoadedTransport, 0
	GUIControl, , quickSelect%Race%DeselectEmptyTransport, 0
	if race = zerg
	{ 
		GUIControl, Disable, quickSelect%Race%DeselectLoadedTransport
		GUIControl, Disable, quickSelect%Race%DeselectEmptyTransport
	}
	GUIControl, , quickSelect%Race%DeselectHallucinations, 0
	GUIControl, , quickSelect%Race%DeselectIdle, 0
	GUIControl, , quickSelect%Race%DeselectQueuedDrops, 0
	GUIControl, , quickSelect%Race%DeselectHoldPosition, 0
	GUIControl, , quickSelect%Race%DeselectAttacking, 0
	GUIControl, , quickSelect%Race%DeselectFollowing, 0
	GUIControl, , quickSelect%Race%DeselectLowHP, 0
	GUIControl, , quickSelect%Race%HPValue, 40
}

showQuickSelectItem(Race, byRef aQuickSelectCopy)
{
	arrayPosition := aQuickSelectCopy[race "IndexGUI"]
	for index, unitName in aQuickSelectCopy[Race, arrayPosition, "units"]
	{
		if aUnitName.haskey(unitName)
			units .= aUnitName[unitName] (index != aQuickSelectCopy[Race, arrayPosition, "units"].MaxIndex() ? "`n" : "")
	}

	GUIControl, , quickSelect%Race%enabled, % round(aQuickSelectCopy[Race, arrayPosition, "enabled"])
	
	GuiControl, % "enable" (aQuickSelectCopy[Race, arrayPosition, "SelectUnitTypes"] || aQuickSelectCopy[Race, arrayPosition, "DeselectUnitTypes"]), quickSelect%race%UnitsArmy
	GuiControl, % "enable" (aQuickSelectCopy[Race, arrayPosition, "SelectUnitTypes"] || aQuickSelectCopy[Race, arrayPosition, "DeselectUnitTypes"]), #quickSelect%race%UnitsArmy		
	if aQuickSelectCopy[Race, arrayPosition, "SelectUnitTypes"]
	{
		GuiControl,, quickSelect%race%SelectUnitTypes, 1
		GuiControl,, quickSelect%race%DeselectUnitTypes, 0
	}
	else if aQuickSelectCopy[Race, arrayPosition, "DeselectUnitTypes"]
	{
		GuiControl,, quickSelect%race%SelectUnitTypes, 0
		GuiControl,, quickSelect%race%DeselectUnitTypes, 1	
	}
	else 
	{
		GuiControl,, quickSelect%race%SelectUnitTypes, 0
		GuiControl,, quickSelect%race%DeselectUnitTypes, 0		
	}

	GUIControl, , quickSelect%Race%_Key, % aQuickSelectCopy[Race, arrayPosition, "hotkey"]
	GUIControl, , quickSelect%Race%UnitsArmy, %units%
	GuiControl, ChooseString, QuickSelect%Race%StoreSelection, % aQuickSelectCopy[Race, arrayPosition, "storeSelection"] != ""
																	? aQuickSelectCopy[Race, arrayPosition, "storeSelection"] 
																	: "0"
	GuiControl, ChooseString, QuickSelect%Race%BaseSelection, % aQuickSelectCopy[Race, arrayPosition, "BaseSelection"]
																? aQuickSelectCopy[Race, arrayPosition, "BaseSelection"] 
																: "Army"																
	GuiControl, ChooseString, QuickSelect%Race%AttributeMode, % aQuickSelectCopy[Race, arrayPosition, "AttributeMode"]
																? aQuickSelectCopy[Race, arrayPosition, "AttributeMode"] 
																: "Remove"
	if (race = "Zerg" && aQuickSelectCopy[Race, arrayPosition, "BaseSelection"] = "Army")														
	{ 
		GUIControl, Disable, quickSelect%Race%DeselectLoadedTransport
		GUIControl, Disable, quickSelect%Race%DeselectEmptyTransport
		GUIControl, , quickSelect%Race%DeselectLoadedTransport, 0
		GUIControl, , quickSelect%Race%DeselectEmptyTransport, 0
	}
	else if (race != "Zerg" || aQuickSelectCopy[Race, arrayPosition, "BaseSelection"] != "Army")	
	{
		GUIControl, Enable, quickSelect%Race%DeselectLoadedTransport ; No need to enable for Toss/Terran, but saves anther if else
		GUIControl, Enable, quickSelect%Race%DeselectEmptyTransport		
		GUIControl, , quickSelect%Race%DeselectLoadedTransport, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectLoadedTransport"])
		GUIControl, , quickSelect%Race%DeselectEmptyTransport, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectEmptyTransport"])
	}

	if aQuickSelectCopy[Race, arrayPosition, "CreateControlGroup"]
	{
		GUIControl, , quickSelect%Race%CreateControlGroup, 1
		GUIControl, , quickSelect%Race%AddToControlGroup, 0
		GuiControlGet, controlPos, Pos, quickSelect%race%CreateControlGroup 
		GuiControl, Move, QuickSelect%race%StoreSelection, %  "y" controlPosy-3
		GuiControl, Show, QuickSelect%race%StoreSelection   		
	}
	else if aQuickSelectCopy[Race, arrayPosition, "AddToControlGroup"]
	{
		GUIControl, , quickSelect%Race%AddToControlGroup, 1
		GUIControl, , quickSelect%Race%CreateControlGroup, 0
		GuiControlGet, controlPos, Pos, quickSelect%race%AddToControlGroup 
		GuiControl, Move, QuickSelect%race%StoreSelection, %  "y" controlPosy-3
		GuiControl, Show, QuickSelect%race%StoreSelection   		
	}
	else 
	{
		GUIControl, , quickSelect%Race%AddToControlGroup, 0
		GUIControl, , quickSelect%Race%CreateControlGroup, 0
		GuiControl, Hide, QuickSelect%race%StoreSelection 		
	}

	GUIControl, , quickSelect%Race%DeselectXelnaga, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectXelnaga"])
	GUIControl, , quickSelect%Race%DeselectPatrolling, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectPatrolling"])

	GUIControl, , quickSelect%Race%DeselectHallucinations, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectHallucinations"])
	GUIControl, , quickSelect%Race%DeselectIdle, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectIdle"])
	GUIControl, , quickSelect%Race%DeselectQueuedDrops, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectQueuedDrops"])
	GUIControl, , quickSelect%Race%DeselectHoldPosition, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectHoldPosition"])
	GUIControl, , quickSelect%Race%DeselectAttacking, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectAttacking"])
	GUIControl, , quickSelect%Race%DeselectFollowing, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectFollowing"])
	GUIControl, , quickSelect%Race%DeselectLowHP, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectLowHP"])
	if !aQuickSelectCopy[Race, arrayPosition, "HPValue"] || aQuickSelectCopy[Race, arrayPosition, "HPValue"] < 1 || aQuickSelectCopy[Race, arrayPosition, "HPValue"] > 99
		aQuickSelectCopy[Race, arrayPosition, "HPValue"] := 40
	GUIControl, , quickSelect%Race%HPValue, % round(aQuickSelectCopy[Race, arrayPosition, "HPValue"])
	
	return
}

saveCurrentQuickSelect(Race, byRef aQuickSelectCopy)
{
	GuiControlGet, enabled, , quickSelect%Race%enabled
	GuiControlGet, SelectUnitTypes, , quickSelect%Race%SelectUnitTypes
	GuiControlGet, DeselectUnitTypes, , quickSelect%Race%DeselectUnitTypes
	GuiControlGet, hotkey, , quickSelect%Race%_Key
	GuiControlGet, units, , quickSelect%Race%UnitsArmy ; comma delimited list
	
	GuiControlGet, CreateControlGroup, , QuickSelect%Race%CreateControlGroup  
	GuiControlGet, AddToControlGroup, , QuickSelect%Race%AddToControlGroup  
	GuiControlGet, storeSelection, , QuickSelect%Race%StoreSelection  ; 0-9 or Off
	GuiControlGet, BaseSelection, , QuickSelect%Race%BaseSelection 
	GuiControlGet, AttributeMode, , QuickSelect%Race%AttributeMode 
	GuiControlGet, DeselectXelnaga, , quickSelect%Race%DeselectXelnaga
	GuiControlGet, DeselectPatrolling, , quickSelect%Race%DeselectPatrolling
	GuiControlGet, DeselectLoadedTransport, , quickSelect%Race%DeselectLoadedTransport
	GuiControlGet, DeselectEmptyTransport, , quickSelect%Race%DeselectEmptyTransport
	GuiControlGet, DeselectHallucinations, , quickSelect%Race%DeselectHallucinations
	GuiControlGet, DeselectIdle, , quickSelect%Race%DeselectIdle
	GuiControlGet, DeselectQueuedDrops, , quickSelect%Race%DeselectQueuedDrops
	GuiControlGet, DeselectHoldPosition, , quickSelect%Race%DeselectHoldPosition
	GuiControlGet, DeselectAttacking, , quickSelect%Race%DeselectAttacking
	GuiControlGet, DeselectFollowing, , quickSelect%Race%DeselectFollowing
	GuiControlGet, DeselectLowHP, , quickSelect%Race%DeselectLowHP
	GuiControlGet, HPValue, , quickSelect%Race%HPValue


	arrayPosition := aQuickSelectCopy[race "IndexGUI"]
	aQuickSelectCopy[Race, arrayPosition] := []
	aQuickSelectCopy[Race, arrayPosition, "enabled"] := enabled
	aQuickSelectCopy[Race, arrayPosition, "hotkey"] := hotkey
	aQuickSelectCopy[Race, arrayPosition, "units"] := []
	
	includesTransport := False
	StringReplace, units, units, `,, `n, All ; in case user writes a comma
	StringReplace, units, units, %A_Space%, `n, All 
	StringReplace, units, units, `r,, All
	while InStr(units, "`n`n")
		StringReplace, units, units, `n`n, `n, All 
	sort, units, D`n U ;remove duplicates 
	loop, parse, units, `n
	{
		if aUnitID.haskey(unit := trim(A_LoopField," `t`n`,"))
		{
			aQuickSelectCopy[Race, arrayPosition, "units"].insert(aUnitID[unit])	
			if unit in Medivac,WarpPrism,WarpPrismPhasing,Overlord
				includesTransport := True
		}
	}
	if !aQuickSelectCopy[Race, arrayPosition, "units"].maxIndex()
		SelectUnitTypes := DeselectUnitTypes := False
	; lets just save it anyway so that if the click previous to go back and they havent filled in the units part, 
	; they wont lose what they just entered
;	if !aQuickSelectCopy[Race, arrayPosition, "units"].maxIndex()
;	{
;		GUIControl, , quickSelect%Race%UnitsArmy,
;		aQuickSelectCopy[Race].remove(arrayPosition)
;		return 1 ; No real units were in the text field
;	}
	if (SelectUnitTypes && !includesTransport)
	|| (DeselectUnitTypes && includesTransport)
	|| (race = "Zerg" && BaseSelection = "Army")
		DeselectLoadedTransport := DeselectEmptyTransport := DeselectQueuedDrops := False
	if SelectUnitTypes
		DeselectUnitTypes := false
	DeselectHallucinations := (DeselectHallucinations && race = "Protoss") ; if not toss set to 0

	aQuickSelectCopy[Race, arrayPosition, "SelectUnitTypes"] := SelectUnitTypes
	aQuickSelectCopy[Race, arrayPosition, "DeselectUnitTypes"] := DeselectUnitTypes
	aQuickSelectCopy[Race, arrayPosition, "CreateControlGroup"] := CreateControlGroup
	aQuickSelectCopy[Race, arrayPosition, "AddToControlGroup"] := AddToControlGroup
	aQuickSelectCopy[Race, arrayPosition, "storeSelection"] := storeSelection
	aQuickSelectCopy[Race, arrayPosition, "BaseSelection"] := BaseSelection
	aQuickSelectCopy[Race, arrayPosition, "AttributeMode"] := AttributeMode
	aQuickSelectCopy[Race, arrayPosition, "DeselectXelnaga"] := DeselectXelnaga
	aQuickSelectCopy[Race, arrayPosition, "DeselectPatrolling"] := DeselectPatrolling
	aQuickSelectCopy[Race, arrayPosition, "DeselectLoadedTransport"] := DeselectLoadedTransport
	aQuickSelectCopy[Race, arrayPosition, "DeselectEmptyTransport"] := DeselectEmptyTransport
	aQuickSelectCopy[Race, arrayPosition, "DeselectHallucinations"] := DeselectHallucinations
	aQuickSelectCopy[Race, arrayPosition, "DeselectIdle"] := DeselectIdle
	aQuickSelectCopy[Race, arrayPosition, "DeselectQueuedDrops"] := DeselectQueuedDrops
	aQuickSelectCopy[Race, arrayPosition, "DeselectHoldPosition"] := DeselectHoldPosition
	aQuickSelectCopy[Race, arrayPosition, "DeselectAttacking"] := DeselectAttacking
	aQuickSelectCopy[Race, arrayPosition, "DeselectFollowing"] := DeselectFollowing
	aQuickSelectCopy[Race, arrayPosition, "DeselectLowHP"] := DeselectLowHP
	; I think it might be possible to enter an invalid number and then click next so just check
	if !aQuickSelectCopy[Race, arrayPosition, "HPValue"] || aQuickSelectCopy[Race, arrayPosition, "HPValue"] < 1 || aQuickSelectCopy[Race, arrayPosition, "HPValue"] > 99
		aQuickSelectCopy[Race, arrayPosition, "HPValue"] := 40	
	aQuickSelectCopy[Race, arrayPosition, "HPValue"] := HPValue
	return 
}

g_GuiSetupDrawMiniMapDisable:
	
	; the commented out controls here are ones which can still be active 
	; even when the 'Minimap Hack' is not being used
	GuiControlGet, Checked, ,DrawMiniMap 
	if !Checked
	{	
	;	GUIControl, Disable, DrawSpawningRaces
	;	GUIControl, Disable, DrawAlerts
	;	GUIControl, Disable, TT_MiniMapRefresh
	;	GUIControl, Disable, TempHideMiniMapKey
	;	GUIControl, Disable, #TempHideMiniMapKey
		GUIControl, Disable, HostileColourAssist
		GUIControl, Disable, DrawUnitDestinations
		GUIControl, Disable, DrawPlayerCameras
		GUIControl, Disable, HighlightInvisible
		GUIControl, Disable, HighlightHallucinations
		GUIControl, Disable, UnitHighlightExcludeList
		GUIControl, Disable, #UnitHighlightExcludeList

		list := "UnitHighlightList|#UnitHighlightList"
		loop, parse, list, |
			loop, 7 ; as 5 colour indexes
			{
				variable := A_LoopField A_Index
				GUIControl, Disable, %variable%
				GUIControl, Disable, #UnitHighlightList1Colour
			}
		loop, 7 
			GUIControl, Disable, #UnitHighlightList%A_Index%Colour

		GUIControl, Disable, #UnitHighlightInvisibleColour
		GUIControl, Disable, #UnitHighlightHallucinationsColour
	}
	Else
	{	
	;	GUIControl, Enable, DrawSpawningRaces
	;	GUIControl, Enable, DrawAlerts
		GUIControl, Enable, UnitHighlightExcludeList
		GUIControl, Enable, #UnitHighlightExcludeList

	;	GUIControl, Enable, TT_MiniMapRefresh
	;	GUIControl, Enable, TempHideMiniMapKey
	;	GUIControl, Enable, #TempHideMiniMapKey
		GUIControl, Enable, HostileColourAssist
		GUIControl, Enable, DrawUnitDestinations
		GUIControl, Enable, DrawPlayerCameras
		GUIControl, Enable, HighlightInvisible
		GUIControl, Enable, HighlightHallucinations

		list := "UnitHighlightList|#UnitHighlightList"
		loop, parse, list, |
			loop, 7 ; as 5 colour indexes
			{
				variable := A_LoopField A_Index
				GUIControl, Enable, %variable%
			}
		loop, 7 
			GUIControl, Enable, #UnitHighlightList%A_Index%Colour
		GUIControl, Enable, #UnitHighlightInvisibleColour
		GUIControl, Enable, #UnitHighlightHallucinationsColour

	}
Return	
g_GuiSetupResetPixelColour:
	guicontrol, Options:, AM_MiniMap_PixelColourAlpha, 255
	guicontrol, Options:, AM_MiniMap_PixelColourRed, 126
	guicontrol, Options:, AM_MiniMap_PixelColourGreen, 191
	guicontrol, Options:, AM_MinsiMap_PixelColourBlue, 241
	guicontrol, Options:, AM_MiniMap_PixelVariance, 0
return

g_GuiSetupAutoMine:
	GuiControlGet, Item, ,AutoMineMethod 
	if (item = "Normal")
		state := 1
	else state := 0
	l_control = AMGUI1,AMGUI2,AMGUI3,AMGUI4,AMGUI5,AMGUI6,AMGUI7,AMGUI8,AM_MiniMap_PixelColourAlpha,AM_MiniMap_PixelColourRed,AM_MiniMap_PixelColourGreen,AM_MinsiMap_PixelColourBlue,#ResetPixelColour,#FindPixelColour,AM_MiniMap_PixelVariance,TT_AM_MiniMap_PixelVariance
	loop, parse, l_control, `,
		GuiControl, Hide%state%, %A_LoopField%
return


B_HelpFile:
	run % url.HelpFile
	Return

g_ChronoRulesURL:
	run % url.ChronoRules
	Return

B_ChangeLog:
	IfWinExist, ChangeLog Vr: %ProgramVersion%
	{
		WinActivate
		Return 									
	}
	Gui, New 
	Gui Add, ActiveX, xm w980 h640 vWB, Shell.Explorer
	WB.Navigate(url.changelog)
	Gui, Show,,ChangeLog Vr: %ProgramVersion%
	sleep, 1500 	; needs 50ms to prevent wb unknown comm error
	; try is required as if user closes gui during sleep com will give error
	try WB.Refresh() 	; So it updates to current changelog (not one in cache)
Return

B_Report:
	GuiControlGet, Report_Email,
	GuiControlGet, Report_TXT,
	R_check:= trim(Report_TXT, "`n `t") ;remove tabs and new lines (and spaces)
	R_length := StrLen(R_check)

	BugText =  ; this needs to equal the txt i use in txt field of the bug report
(

A return email address is REQUIRED if you are looking for a follow up to your query.

Bugs may not occur on all systems, so please be as SPECIFIC as possible when describing the problem.

Screenshots and replays may be attached below.

(please remove this text when filling in this form).

)	
	if (Report_Email != "" && !isValidEmail(Report_Email))
	{
		msgbox, 49, Invalid Email Address, % "Your email address appears to be invalid.`n`n"
					. "Press 'OK' to send the bug report anyway."
		IfMsgBox Cancel
			return
	}
	if (R_check = "" || R_check = trim(BugText, "`n `t") )
		msgbox, 48, Why Spam?, You didn't write anything.`nPlease don't spam this function.
	Else if ( R_length < 18 )
		msgbox, 32, Don't Spam, Please provide more information.
	Else
	{
		Gui, ListView, EmailAttachmentListViewID ;note all future and current threads now refer to this listview!
		attachments := ""
		loop % LV_GetCount()
		{
			LV_GetText(AttachmentPath, A_Index) ; start at 1 as 0 retrieves the column header
			attachments .= AttachmentPath ","
		}

		if FileExist(A_Temp "\MacroTrainerDebugData.txt")
			FileDelete, %A_Temp%\MacroTrainerDebugData.txt
		FileAppend, % DebugData(), %A_Temp%\MacroTrainerDebugData.txt
		attachments .= A_Temp "\MacroTRainerDebugData.txt,"	
		if FileExist(A_Temp "\MacroTrainerSystemDebugData.txt")
			FileDelete, %A_Temp%\MacroTrainerSystemDebugData.txt
		FileAppend, % WMISystemInfo_Summary(), %A_Temp%\MacroTrainerSystemDebugData.txt
		attachments .= A_Temp "\MacroTrainerSystemDebugData.txt,"
		attachments := Trim(attachments, " `t`,")

		if ((error := bugReportPoster(Report_Email, "Bug Report:`n`n" Report_TXT, attachments, ticketNumber)) >= 1)
		{
			FileDelete, %A_Temp%\MacroTRainerDebugData.txt ; Try to delete as there is a return here
			GuiControl, ,Report_TXT, %Report_TXT%`n`n`nAuto Bug Report Error:`n%error%
			msgbox, % 49 + 4096, Error, % "There was an error submitting your report"
				. "`n`nError: " error
				. "`n`nPress OK to submit the report using your web browser"
				. "`n`nOtherwise Press cancel"
			IfMsgBox, OK
				run % url.BugReport
			else return 
		}
		else if (error = -1)
		{
			; icon exclamation + task modal
			msgbox, % 48 + 4096, File Size Limit, % "The attached files are too large."
				. "`n`nIndividual attachments cannot be greater than 1MB."
				. "`nThe combined size of the attachments cannot be greater than 7MB."
				. "`n`nPlease remove (or compress) some attachments and try again."
		}
		else 
		{
			GuiControl, Disable, B_Report
			GuiControl, ,Report_Email,
			GuiControl, ,Report_TXT, `n`n`n`n`n`n%a_tab%%a_tab%Thank You!
			msgbox, 64, , Report Sent`n`nTicket Number: %ticketNumber%, 10
		}
		FileDelete, %A_Temp%\MacroTRainerDebugData.txt ; Try to delete
	}
	return

;could hide everything each time, then unhide once, but that causes every so slightly more blinking on gui changes
; Note this is launched automatically when the GUI is first created, as the first TV item (Home) is automatically selected
OptionsTree:
	
	; In case ever add another tree view ensure correct one is being accessed/manipulated
	Gui, TreeView, GUIListViewIdentifyingVariableForRedraw
	; Key = MenuTitles: Value = Tab ID
	if !isObject(aGUITabs)
		aGUITabs := { 	"Home": "Home_TAB" 
					,	"MiniMap/Overlays": "MiniMap_TAB"
					,	"Injects": "Injects_TAB"
					,	"Auto Grouping": "AutoGroup_TAB"
					,	"Quick Select": "quickSelect_TAB"
					,	"Auto Worker": "AutoWorker_TAB"
					,	"Auto Build": "AutoBuild_TAB"
					,	"Chrono Boost": "ChronoBoost_TAB"
					,	"Misc Automation": "MiscAutomation_TAB"
					,	"SC2 Keys": "Keys_TAB"
					,	"Warnings": "Warnings_TAB"
					, 	"Misc Abilities": "Misc_TAB"
					,	"Bug Report": "Bug_TAB"
					,	"Settings": "Settings_TAB"}	

	OptionTreeEvent := A_GuiEvent
	OptionTreeEventInfo := A_EventInfo
	TV_GetText(Menu_TXT, TV_GetSelection())
	if (Menu_TXT && unhidden_menu)  ; there's a bug in AHK with the right click - have GUI on second monitor and right click, Menu_TXT will be blank
		GUIcontrol, Hide, %unhidden_menu%
	if aGUITabs.HasKey(Menu_TXT)
		GUIcontrol, Show, % unhidden_menu := aGUITabs[Menu_TXT]
	else return 

	WinSet, Redraw,, V%ProgramVersion% Settings 				; redrawing whole thing as i noticed very very rarely (when a twitch stream open?) the save/cancel/apply buttons disappear
; 	 GUIControl, MoveDraw, GUIListViewIdentifyingVariableForRedraw ; this is the same as redraw (but just for a control? - although it still seems to flicker the entire thing)
 	Return															; this prevents the problem where some of the icons would remain selected
 																	; so multiple categories would have the blue background
 	
 	
;can arrive here from the GUI +/add button, or via the GuiDropFiles: label which is activated when a user drags and drops files onto a control
g_AddEmailAttachment:
if (A_GuiControl = "EmailAttachmentListViewID") 
	FilePath := A_GuiEvent 		; contains the names separated by `n each file has its full directory path
else 							; this is different to the multi file select, where the directory folder is only in A_index 1
{
	FileSelectFile, FilePath, M1, , Attach Files      (Individual attachments must be less than 1MB)
	if (errorlevel || !FilePath) ; is set to 1 if the user dismissed the dialog without selecting a file (such as by pressing the Cancel button).
		return 
	Else
	{
		Loop, parse, FilePath, `n ;`n is used to separate multiple selected files
			AttachmentCount := A_Index

		; this acts to convert the multi-selected files so that each one has a full directory listing
		; and is separated from the next by `n - so it should now be identical to the syntax used if a user had dragged
		; and dropped the files

		if (AttachmentCount > 1)
		{
			Loop, parse, FilePath, `n
			{	
				if (A_Index = 1) 	; when multiple files are selected (they all must come from the same folder)
				{					; This folder path is only included in Index 1
					tmpFilePaths := ""
					BaseDirectory := A_LoopField
					if (SubStr(BaseDirectory, 0, 1) != "\") ; as root directories will contain '\' but other ending directories wont
						BaseDirectory .= "\" 
					continue
				}
				else tmpFilePaths .= BaseDirectory A_LoopField "`n"
			}		
			FilePath := RTrim(tmpFilePaths, "`n") ; remove the `n from the final path, so dont get an empty list view filed  
		}

	}
}
Gui, ListView, EmailAttachmentListViewID ;note all future and current threads now refer to this listview!
Loop, parse, FilePath, `n
	LV_Add("", A_LoopField)
LV_ModifyCol()  ; Auto-size all columns to fit their contents
return 


g_RemoveEmailAttachment:
Gui, ListView, EmailAttachmentListViewID ;note all future and current threads now refer to this listview!
EmailRowNumber := 0
UserTriedToRemoveIniAttachment := False  
Loop
{
    EmailRowNumber := LV_GetNext(EmailRowNumber)  ; Resume the search at the row after that found by the previous iteration.
    if !EmailRowNumber  ; The above returned zero, so there are no more selected rows.
        break
    LV_GetText(RowText, EmailRowNumber)
    if instr(RowText, config_file)
    	UserTriedToRemoveIniAttachment := True
    else 
    {
    	LV_Delete(EmailRowNumber)
    	goto g_RemoveEmailAttachment ; otherwise some items wont get deleted as lv_next gets confused in loop
    }
}
LV_ModifyCol()  ; Auto-size all columns to fit their contents
if UserTriedToRemoveIniAttachment
	msgbox Your config file is always attached to a bug report.`nIt can not be removed.
return 

; activated when a user drags and drops files onto a control
; so far only used for email attachments

;Note GuiDropFiles: is the general label, but Have changed the options menu label to Options hence 'OptionsGuiDropFiles'
OptionsGuiDropFiles: 
if (A_GuiControl = "EmailAttachmentListViewID")
	Gosub, g_AddEmailAttachment 
return 

	; Can't just use the menu, Icon change command to change the icon, 
	; as the compiled icon will still show up in the sound mixer
	; hence have to change the internal compiled icon
	; Also as using resource hacker to change icon, cant use mpress :(
	; so the compiled exe will be ~4x bigger!

g_MTChageIcon:
FileSelectFile, NewIconFile, S3, , Select an icon file, *.ico ; only *.ico will work with reshacker
if (errorlevel || !NewIconFile || !A_IsCompiled) ; is set to 1 if the user dismissed the dialog without selecting a file (such as by pressing the Cancel button).
	return
;GUIControl,, MTCustomIcon, %NewIconFile% 
;GUIControl,, MTIconPreview, %NewIconFile%  ;update the little pic ; width height omitted, so pic scaled to fit control
Iniwrite, %NewIconFile%, %config_file%, Misc Settings, MTCustomIcon
ResourHackIcons(NewIconFile)  ;this function quits and reloads the script
return 
g_MTChageIconDefault:
;GUIControl,, MTCustomIcon, %A_Space% ;blank it
if !MTCustomIcon ; don't do anything already using the standard Icon
	return 
Iniwrite, %A_Space%, %config_file%, Misc Settings, MTCustomIcon ; use this to check if display my tool tip lol
ResourHackIcons(A_Temp "\Starcraft-2.ico") ;this function quits and reloads the script
return

Test_VOL:
	;original_programVolume := programVolume
	GuiControlGet, TmpSpeechVol,, speech_volume
	TmpSpeechVol := Round(TmpSpeechVol, 0)
	GuiControlGet, TmpTotalVolume,, programVolume
	TmpTotalVolume := Round(TmpTotalVolume, 0)

	If ( A_GuiControl = "Test_VOL_All")
	{
		SetProgramWaveVolume(TmpTotalVolume)
		loop, 2
		{
			SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
			sleep 150
		}
	}	
	;Random, Rand_joke, 1, 8


	; The easy approach would be to use ahkFunction so AHK runs the function and waits for it to return
	; Make SAPI speak synchronously so that the code execution is halted
	; and the program volume isn't changed before the speech is finished.
	; **********
	; But due to com/AHK_H bug ahkFunction will give an unknown comError
	; So I can't use this method. Also this wouldn't allow the volume slider changes to dynamically
	; influence the spoken volume

	; SAPI offers some methods to like wait until done, but using postFunction this will
	; not halt the execution of code in this thread. 
	; Could create a thread global sapi object and call it directly from here using this method or synch mode
	; But I'm just gonna be lazy and create a temporary sapi object in this script/thread

	; Unlike tSpeak() which doesn't call the speech module if volume is 0
	; sapiMenuVolumeTester()  allows the text to start speaking even at 0 volume
	; hence allowing users to observe the volume change as the slider is moved.

	Rand_joke++
	If ( Rand_joke = 1 )
		sapiMenuVolumeTester("Protoss is OPee")
	Else If ( Rand_joke = 2 )
		sapiMenuVolumeTester("A templar comes back to base with a terrified look on his face. The zealots asks - what happened? You look like you've seen a ghost")
	Else If ( Rand_joke = 3 )
	{
		sapiMenuVolumeTester("A Three Three Protoss army walks into a bar and asks")
		sleep 100
		sapiMenuVolumeTester("Where is the counter?")
	}
	Else If ( Rand_joke = 4 )
	{
		sapiMenuVolumeTester("What computer does IdrA use?")
		sleep 500
		sapiMenuVolumeTester("An EYE BM")
	}
	Else If ( Rand_joke = 5 )
	{
		sapiMenuVolumeTester("Why did the Cullosus fall over ?")
		sleep 500
		sapiMenuVolumeTester("because it was imbalanced")
	}
	Else If ( Rand_joke = 6 )
	{
		sapiMenuVolumeTester("How many Zealots does it take to change a lightbulb?")
		sleep 500
		sapiMenuVolumeTester("None, as they cannot hold")	
	}
	Else If ( Rand_joke = 7 )
	{
		sapiMenuVolumeTester("How many Infestors does it take to change a lightbulb?")
		sleep 500
		sapiMenuVolumeTester("One, you just have to make sure he doesn't over-power it")	
	}
	Else
	{
		sapiMenuVolumeTester("How many members of the Starcraft 2 balance team does it take to change a lightbulb?")
		sleep 500
		sapiMenuVolumeTester("All three of them, and Ten patches")	
		rand_joke := 0
	}
	SetProgramWaveVolume(programVolume)
return

; This function is only used by the volume tester in the options menu.
; It uses asynchronous mode and WaitUntilDone()+sleep to allow the mouse to move
; and the gui/program to respond to input. 
; It also checks and alters the SAPI volume during the test if the slider is moved
; The function won't return until the messages has been fully spoken

sapiMenuVolumeTester(message)
{
	; Don't have to specify the GUIs name/ID as this is launched in response to clicking the 'test' button
	; in the options GUI
	GuiControlGet, prevSpeechVol,, speech_volume
	; The GUI was closed. Since some of the jokes are 2 parts and have sleeps (could probably use xml or something to insert pauses into the text)
	; allowing the gui to be closed between them. So just return rather than speaking at 0 volume
	if ErrorLevel
		return
	prevSpeechVol := Round(prevSpeechVol, 0)
	GuiControlGet, prevTotalVol,, programVolume
	if ErrorLevel
		return
	prevTotalVol := Round(prevTotalVol, 0)	
	; The sliders for these controls limit value between 0 - 100. Don't think rounder is necessary either
	try 
	{
		SAPI := ComObjCreate("SAPI.SpVoice")
		SAPI.volume := prevSpeechVol
		; use asynchronous so doesn't freeze this script - i.e. cant move the mouse etc
		SAPI.Speak(message, 1) 
		; waits infinite until done. Can't use this as it will freeze like above - could cause hooks to be removed! and it looks crappy.
		;SAPI.WaitUntilDone(-1) 
	}
	; can't encase everything in a try as GuiControlGet will cause it to exit out of the try
	; if the control doesn't exist any more (gui closes) - though it's not prompt type error (if try isn't used)
	; cant use try with while, as braces will cause try to be in effect for GuiControlGet

	loop, 1000 ; with a sleep of 50+5, this will loop for ~55 seconds if something goes wrong with the break/WaitUntilDone 
	{
		; If something were to go wrong with the com, the catch should break the loop
		; but just in case, set break to true prior to call.
		break := True 
		try break := SAPI.WaitUntilDone(5) ; AHK is obviously unresponsive during this call
		catch 
			break
		if break
			break

		sleep 50	
		GuiControlGet, speechVol,, speech_volume
		; the GUI was probably closed - speechVol should not be changed from it's previous value 
		; but lets just continue the loop anyway
		if ErrorLevel
			continue 
		speechVol := Round(speechVol, 0)
		if (prevSpeechVol != speechVol)
		{
			prevSpeechVol := speechVol
			try SAPI.volume := speechVol
		}
		GuiControlGet, totalVol,, programVolume
		if ErrorLevel
			continue
		totalVol := Round(totalVol, 0)	
		if (prevTotalVol != totalVol)
		{
			prevTotalVol := totalVol
			SetProgramWaveVolume(totalVol)
		}
	}
	return
}

Edit_SendHotkey:
	if (SubStr(A_GuiControl, 1, 1) = "#") ;this is a method to prevent launching. Edit: launching when what else happens ????? these var names are stupid. 
	{
		hotkey_name := SubStr(A_GuiControl, 2)	;This will contain the name of the hotkey variable
		GuiControlGet, currentKey,, %hotkey_name%
		hotkey_var := SendGUI("Options", currentKey,,,"Select Key:   " hotkey_name) ;the hotkey
		if (hotkey_var <> "")
			GUIControl,, %hotkey_name%, %hotkey_var%
	}
Return

;		Example of how to disable modifiers
;		hotkey_var := HotkeyGUI("Options",%hotkey_name%, 2+4+8+16+32+64+128+256+512+1024, "Select Hotkey:   " hotkey_name) 	

edit_hotkey:
	if (SubStr(A_GuiControl, 1, 1) = "#") ;this is a method to prevent launching 
	{
		hotkey_name := SubStr(A_GuiControl, 2)	;this label (and hotkeygui) for a 2nd time 
		if instr(hotkey_name, "quickSelect")
		{
			if instr(hotkey_name, "Terran")
				race := "Terran"
			else if instr(hotkey_name, "Protoss")
				race := "Protoss"
			else 
				race := "Zerg"
			GuiControlGet, hotkey, , quickSelect%Race%_Key
			hotkey_var := HotkeyGUI("Options", hotkey,, "Select Hotkey:   " hotkey_name) ;the hotkey
		}
		else 
		{
			GuiControlGet, currentKey,, %hotkey_name%
			; Force at least one Right side modifiers and force the wildcard option (disable and check)
			; this is done as if have stuck modifier then this could prevent the hotkey firing.
			if (hotkey_name = "Key_EmergencyRestart")  
				hotkey_var := HotkeyGUI("Options", currentKey, 1, "Select Hotkey:   " hotkey_name, 0, 0, 10, 14) ;the hotkey
			Else 
				hotkey_var := HotkeyGUI("Options", currentKey,, "Select Hotkey:   " hotkey_name) ;the hotkey							
		}
		if (hotkey_var <> "")
			GUIControl,, %hotkey_name%, %hotkey_var%
	}
return


Alert_List_Editor:
IfWinExist, Alert List Editor 
{
	WinActivate
	Return 									
}
Gui, New 
alert_list_fields :=  "Name,DWB,DWA,Repeat,IDName"
SetupUnitIDArray(aUnitID, aUnitName)
Editalert_array := [],	Editalert_array := createAlertArray()

Gui -MaximizeBox
Gui, Add, GroupBox,  w220 h370 section, Current Detection List
Gui, Add, TreeView, xp+20 yp+20 gMyTree r20 w180

loop, parse, l_GameType, `,
{
	p%A_Index% := TV_Add(A_LoopField)	;p1 = 1v1, p2 =2v2 etc	
	P# := A_Index 						;set var p# for inner loop	
	loop, % Editalert_array[A_LoopField, "list", "size"]				;loop their names
	{
		p_LvL_2 = p%P#%c%A_Index%							;child number
		%p_LvL_2% := TV_Add(Editalert_array[A_LoopField, A_Index, "Name"], p%P#%)	;building name
	}			
}

Gui, Add, GroupBox, ys x+30 w245 h185 vOriginTabRAL, Parameters
GuiControlGet, OriginTabRAL, Pos
	Gui, Add, Text,xp+10 yp+20 section, Name/Warning:
	Gui, Add, Text,y+10 w80, Don't Warn if Exists Before (s):
	Gui, Add, Text,y+10 w80, Don't Warn if Made After (s):
	Gui, Add, Text,y+12, Repeat on New?
	Gui, Add, Text,y+16, ID Code:

	Gui, Add, Edit, Right ys xs+85 section w135 vEdit_Name	
	Gui, Add, Edit, Number Right y+11 w135 vTT_Edit_DWB
		Gui, Add, UpDown,  Range0-100000 vEdit_DWB, 0
	Gui, Add, Edit, Number Right y+11 w135 vTT_Edit_DWA
		Gui, Add, UpDown,  Range1-100000 vEdit_DWA, 54000

	Gui, Add, DropDownList, xs+90  y+8 w45 right VEdit_RON, Yes||No|	
	DetectionUnitListNames := 	"ID List||" l_UnitNames	;get the ID List Txt first in the shared list
	Gui, Add, DropDownList, xs y+10 w135 Vdrop_ID sort, %DetectionUnitListNames%

Gui, Add, GroupBox, y+30 x%OriginTabRALX% w245 h175, Alert Submission	
	Gui, Add, Button, xp+10 yp+20 w225 section vB_Modify_Alert gB_Modify_Alert, Modify Alert
	Gui, Add, Text,xs ys+27 w225 center, OR
	Gui, Add, Button, xs y+5 w225 section gDelete_Alert vB_Delete_Alert Center, Delete Alert
	gui, Add, Text, Readonly yp+5 x+15 w90 center vCurrent_Selected_Alert2, `n`n
	Gui, Add, Text,xs ys+27 w225 center, OR

Gui, Add, GroupBox, y+5 xs-5 w235 h55 section, New Alert	
	Gui, Add, Button, xs+5 yp+20 w120 vB_Add_New_Alert gB_Add_New_Alert, Add This Alert to List
	Gui, Add, Checkbox, checked x+10 yp-5 section vC_Add_1v1, 1v1
	Gui, Add, Checkbox, checked x+10 vC_Add_3v3, 3v3
	Gui, Add, Checkbox, checked yp+20 vC_Add_4v4, 4v4
	Gui, Add, Checkbox, checked xs yp vC_Add_2v2, 2v2

Gui, Add, Button, xp-100 y+30 vB_ALert_Cancel gGuiClose w100 h50, Cancel
Gui, Add, Button, xp-200 yp vB_ALert_Save gB_ALert_Save w100 h50, Save Changes

Gui, Show, w490 h455, Alert List Editor  ; Show the window and its TreeView.

OnMessage(0x200, "mainThreadMessageHandler")

	Edit_Name_TT := "This text is read aload during the warning"
	Edit_DWB_TT := TT_Edit_DWB_TT := "If the unit/building exists before this time, no warning will be made - this is helpful for creating multiple warnings for the same unit"
	Edit_DWA_TT := TT_Edit_DWA_TT := "If the unit is made after this time, no warning will be made -  this is helpful for creating multiple warnings for the same unit"
	Edit_RON_TT := "If ''Yes'' this SPECIFIC warning will be heard for each new unit/building (of this type)."
	Edit_ID_TT := "This value is used to identify buildings and units within SC2 (the list below can be used)"
	drop_ID_TT := "Use this list to find a units ID"
	B_Modify_Alert_TT := "This updates the currently selected alert with the above parameters."
	Delete_Alert_TT := "Removes the currently selected alert."
	B_Add_New_Alert_TT := "Creates an alert using the above parameters for the selected game modes."
	B_ALert_Cancel_TT := "Disregard changes"
;	B_ALert_Save_TT := "This will save any changes made"
return

Drop_ID:
	GuiControlGet, Edit_Unit_name,, drop_ID ;get txt of selection
	Edit_ID := aUnitID[Edit_Unit_name]	;look up the associated ID by unit Title
	GUIControl,, Edit_ID, %Edit_ID%	;set the edit box
return

Delete_Alert:
	Gui, Submit, NoHide
	TV_item := TV_CountP()
	TV_GetText(GameTypeTV,TV_GetParent(TV_GetSelection()))
	del_correction := Editalert_array[GameTypeTV, "list", "size"] - TV_item
	alert_list_fields :=  "Name,DWB,DWA,Repeat,IDName"
	loop, parse, alert_list_fields, `, ;comma is the separator
	{
		loop, % del_correction
		{
			TV_item_next := TV_item + A_Index
			TV_item_previous := TV_item_next - 1	
			Editalert_array[GameTypeTV, TV_item_previous, A_LoopField] :=  Editalert_array[GameTypeTV, TV_item_next, A_LoopField]	;copy data back 1 space
		}
	}
	Editalert_array[GameTypeTV].remove(Editalert_array[GameTypeTV, "list", "size"])

	Editalert_array[GameTypeTV, "list", "size"] -= 1	;decrease list size by 1
	TV_Delete(TV_GetSelection())
	GUIControl,, B_Delete_Alert, Delete Alert - %GameTypeTV% %ItemTxt% ;update tne name on button
	GUIControl,, B_Modify_Alert, Modify Alert - %GameTypeTV% %ItemTxt%

Return

B_Modify_Alert:

	Gui, Submit, NoHide
	if ( Edit_Name = "" OR Edit_DWB = "" OR Edit_DWA = "" OR  drop_ID = "ID List" ) ; Edit_RON cant be blank
		MsgBox Blank parameters are not acceptable.
	Else
	{
		TV_item := TV_CountP()
		TV_GetText(GameTypeTV,TV_GetParent(TV_GetSelection()))
		TV_Modify(TV_GetSelection(), %Space%, Edit_Name) ; update name in tree view - %Space% workaround for blank option bug
		Editalert_array[GameTypeTV, TV_item, "Name"] := Edit_Name
		Editalert_array[GameTypeTV, TV_item, "DWB"] := Edit_DWB
		Editalert_array[GameTypeTV, TV_item, "DWA"] := Edit_DWA
		if (Edit_RON = "Yes")
			Editalert_array[GameTypeTV, TV_item, "Repeat"] := 1
		Else Editalert_array[GameTypeTV, TV_item, "Repeat"] := 0
		Editalert_array[GameTypeTV, TV_item, "IDName"] := drop_ID	
	}
	Return
  
B_Add_New_Alert:
	Gui, Submit, NoHide
	if ( Edit_Name = "" OR Edit_DWB = "" OR Edit_DWA = "" OR  drop_ID = "ID List" ) ; Edit_RON cant be blank
		MsgBox Blank parameters are not acceptable.
	Else if ((C_Add_1v1 + C_Add_2v2 + C_Add_3v3 + C_Add_4v4) = 0)
		msgbox You must select at least one game mode. 
	Else
	{
		Add_to_GameType := []
		loop, parse, l_GameType, `,
		{
			if C_Add_%A_LoopField%
				Add_to_GameType[A_Index] := A_LoopField
		}

		For index, game_mode in Add_to_GameType
		{	
			New_Item_Pos := Editalert_array[game_mode, "list", "size"] += 1
			Editalert_array[game_mode, New_Item_Pos, "Name"] := Edit_Name
			Editalert_array[game_mode, New_Item_Pos, "DWB"] := Edit_DWB
			Editalert_array[game_mode, New_Item_Pos, "DWA"] := Edit_DWA
			if (Edit_RON = "Yes")
				Editalert_array[game_mode, New_Item_Pos, "Repeat"] := 1
			Else Editalert_array[game_mode, New_Item_Pos, "Repeat"] := 0
			Editalert_array[game_mode, New_Item_Pos, "IDName"] := drop_ID	

			loop, parse, l_GameType, `, ; 1s,2s,3s,4s
			{		
				if ( game_mode = A_LoopField )
					TV_Add(Edit_Name, p%a_index%) ; TV p1 = 1v1, p2 =2v2 etc
			}	
		}
	}
	WinSet, Redraw,, Alert List Editor, Current Detection List ;forces a redraw as the '+' expander doesnt show (until a mouseover) if the parent had no items when the gui was initially drawn
	Return

MyTree:
	TV_GetText(GameTypeTV,TV_GetParent(TV_GetSelection()))
	If (GameTypeTV = "1v1" or GameTypeTV = "2v2" or GameTypeTV = "3v3" or GameTypeTV = "4v4" or GameTypeTV = "FFA") ;your in the unit name/list
	{
		GUIControl, Enable, B_Delete_Alert
		GUIControl, Enable, B_Modify_Alert
		ItemID := TV_GetChild(TV_GetParent(TV_GetSelection()))
		TV_GetText(ItemTxt, (TV_GetSelection()))
		Count_TVItem := 0, OutputTxt := "" ;blank OutputTxt to prevent error when clicking on unit with same name in different gamemode list
		Loop
		{
			If (ItemID = 0 OR ItemTxt = OutputTxt) ; No more items in tree. (FUNCTIONS RETURNS 0 LAST ONE)
				break
			TV_GetText(OutputTxt, ItemID)
			ItemID := TV_GetNext(ItemID)
			Count_TVItem ++
		}
		GUIControl,, Edit_Name,% Editalert_array[GameTypeTV, Count_TVItem, "Name"]

		GUIControl,, Edit_DWB,% Editalert_array[GameTypeTV, Count_TVItem, "DWB"]
		GUIControl,, Edit_DWA,% Editalert_array[GameTypeTV, Count_TVItem, "DWA"]
		if (Editalert_array[GameTypeTV, Count_TVItem, "Repeat"])
			GUIControl, ChooseString, Edit_RON, Yes
		Else GUIControl, ChooseString, Edit_RON, No
		GUIControl,, Edit_ID,% Editalert_array[GameTypeTV, Count_TVItem, "IDName"]
		GUIControl,ChooseString, drop_ID, % Editalert_array[GameTypeTV, Count_TVItem, "IDName"]
		GUIControl,, B_Delete_Alert, Delete Alert - %GameTypeTV% %ItemTxt%
		GUIControl,, B_Modify_Alert, Modify Alert - %GameTypeTV% %ItemTxt%

	}
	Else ; youre in the gamemode part of the list
	{
		GUIControl,, B_Delete_Alert, Delete Alert
		GUIControl,, B_Modify_Alert, Modify Alert
		GUIControl, Disable, B_Delete_Alert
		GUIControl, Disable, B_Modify_Alert

	}
	return

B_ALert_Save:
	alert_array := Editalert_array
	saveAlertArray(Editalert_array)
	If (A_ThisLabel <> "Alert_Array_General_Write")
		Gui, Destroy
Return



saveAlertArray(alert_array)
{	GLOBAL
	loop, parse, l_GameType, `, 
	{
		IniDelete, %config_file%, Building & Unit Alert %A_LoopField% ;clear the list - prevent problems if now have less keys than b4
		IniWrite, % alert_array[A_LoopField, "Enabled"], %config_file%, Building & Unit Alert %A_LoopField%, enable	;alert system on/off
		;IniWrite, % alert_array[A_LoopField, "Clipboard"], %config_file%, Building & Unit Alert %A_LoopField%, copy2clipboard
		loop, % alert_array[A_LoopField, "list", "size"]  ;loop 1v1 etc units
		{
			IniWrite, % alert_array[A_LoopField, A_Index, "Name"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_name_warning
			Iniwrite, % alert_array[A_LoopField, A_Index, "DWB"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_Dont_Warn_Before_Time
			IniWrite, % alert_array[A_LoopField, A_Index, "DWA"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_Dont_Warn_After_Time
			IniWrite, % alert_array[A_LoopField, A_Index, "Repeat"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_repeat_on_new
			IniWrite, % alert_array[A_LoopField, A_Index, "IDName"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_IDName
		}
	}
	return
}

TV_CountP()
{
	ItemID := TV_GetChild(TV_GetParent(TV_GetSelection()))
	TV_GetText(ItemTxt, (TV_GetSelection()))
	Loop
	{
		If (ItemID = 0 OR ItemTxt = OutputTxt) ; No more items in tree. (FUNCTIONS RETURNS 0 LAST ONE)
			break
		TV_GetText(OutputTxt, ItemID)
		ItemID := TV_GetNext(ItemID)
		Count_Item ++
	}
	Return Count_Item
}

OptionsGUITooltips()
{
	static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.

    CurrControl := A_GuiControl
    If (CurrControl != PrevControl && !InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, -400
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    ;SetTimer, DisplayToolTip, Off
	Try	ToolTip % %CurrControl%_TT  ; try guards against illegal character error (when a controls text is passed as it doesn't have an associated variable)
	; Average reading words/minute = 250-300. 180 when proof reading on a monitor (so use this)
	; Average English word length is ~ 5 (could just use regex to find word count)
   	try displayTime := strlen(%CurrControl%_TT) / 5 / 180 * 60000
    SetTimer, RemoveToolTip, % -1 * (displayTime > 9000 ? displayTime : 9000)
    return

    RemoveToolTip:
    ;SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

g_UnitFilterInfo:
IfWinExist, MT Unit Filter Info
{
	WinActivate
	Return 									; prevent error due to reloading gui 
}
Gui, UnitFilterInfo:New
Text := "
	( LTrim
		These filters will remove the selected units from the unit panel.

		The unit panel displays two types of units, those which exist on the map (or are completed) and those which are being produced.

		For each race there are two filters which are always active.

		Filter 1: 'Completed' - This will remove completed (or fully built) units of the selected types.

		Filter 2: 'Under Construction' - This will remove units which are under construction/being produced. This includes the PhotonOverCharge ability for Protoss

		These filters can be used to effectively create a production only, unit only, or structure only panel.

		Please Note: 

		It is best to actually use the unit panel first and then decide on which units you wish to filter.

		Some units are automatically removed, these include interceptors, locusts, broodlings, completed creep tumours, completed reactors, and completed techlabs.
	)"

Gui, Add, Edit, HwndHwndEdit x12 y+10 w360 h380 readonly -E0x200, % Text
Gui, UnitFilterInfo:Show,, MT Unit Filter Info
selectText(HwndEdit, -1) ; Deselect edit box text
return


g_GUICustomUnitPanel:
IfWinExist, MT Custom Unit Filter - Unit Panel
{
	WinActivate
	Return 									; prevent error due to reloading gui 
}
if LV_UnitPanelFilter 
	LV_UnitPanelFilter := ""  ; destroy the object so isobject() will force a reload of units (prevents problem when closing and the items remaining in the object when it gets reopened next)
Gui, CustomUnitPanel:New
Gui, Add, Text, x50 y+20 w60, Race: 
Gui, Add, DropDownList, x+15 vGUI_UnitPanelRace gg_UnitPanelGUI, Terran||Protoss|Zerg
Gui, Add, Text, x50 y+15 w60, Unit Filter: 
Gui, Add, DropDownList, x+15 vGUI_UnitPanelListType gg_UnitPanelGUI, Completed||Under construction
Gui, Add, Button, x+15 y20 w50   gg_SaveCustomUnitPanelFilter,  Save 
Gui, Add, Button, xp y+13 w50  gGuiClose,  Cancel 
Gui, Add, Button, x+10 yp w50  gg_UnitFilterInfo,  Info 

Gui, Add, ListView, x30 y90 r15 w160 Sort vUnitPanelFilteredUnitsCurrentRace gg_UnitPanelRemoveUnit, Currently Filtered ; This stores the currently displayed race which is  being displayed in the filtered LV as gui submit doesnt affect listview variable

Gui, Add, ListView, x+20  r15 w160 Sort vUnitPanelAvailableUnits gg_UnitPanelAddUnit, Units
GUI_UnitPanelMenu := []	;stores information used to manipualte the menus
GUI_UnitPanelMenu.race  := UnitPanelAvailableUnits := "Terran"
Gosub, g_UnitPanelGUI ; This sets the display race to terran

Gui, Add, Button, x30 y+5 w160 h40  gg_UnitPanelRemoveUnit,  Remove 
Gui, Add, Button, x+20 w160 h40  gg_UnitPanelAddUnit,  Add 

GuI, CustomUnitPanel:Show, w400 h430, MT Custom Unit Filter - Unit Panel
return


g_UnitPanelRemoveUnit:
if (A_GuiEvent = "DoubleClick" || A_GuiEvent = "Normal") 
	LV_UnitPanelFilter[GUI_UnitPanelMenu.ListType, GUI_UnitPanelMenu.race ].MoveSelectedCurrentToAvailable()
return

g_UnitPanelAddUnit:
if (A_GuiEvent = "DoubleClick" || A_GuiEvent = "Normal") ;this only allows the add button and double LEFT clicks to add units
	LV_UnitPanelFilter[GUI_UnitPanelMenu.ListType, GUI_UnitPanelMenu.race ].MoveSelectedAvailableToCurrent()
return



g_SaveCustomUnitPanelFilter:
gosub, g_CheckLV_UnitPanelObject	;this ensure that LV_UnitPanelFilter exists and is filled with the current lists
section := "UnitPanelFilter"
if !RaceObject
	RaceObject := new cSC2Functions()
for index, ListType in ["FilteredCompleted", "FilteredUnderConstruction"]
	for index, LoopRace in ["Terran", "Protoss", "Zerg"] 
	{
		List := convertObjectToList(LV_UnitPanelFilter[ListType, LoopRace, "CurrentItems"], "|")
		IniWrite, %List%, %config_file%, %section%, % LoopRace ListType
		if !IsObject(aUnitPanelUnits[LoopRace, ListType])
			aUnitPanelUnits[LoopRace, ListType] := []
		aUnitPanelUnits[LoopRace, ListType]	:= 	LV_UnitPanelFilter[ListType, LoopRace, "CurrentItems"] ;note the race and list type have been reversed here
	}
Gui, CustomUnitPanel:Destroy  ;as there is a gosub here during an update/ini-transfer - dont want to detroy the wrong gui.
return


;	This menu can be arrived at by three methods
;		1. From a gosub which is used when the GUI is first created - "A_GuiControl" Will be blank 
;		2. From clicking the T, P, Or Z buttons - A_GuiControl will contain the name of the race button e.g "Terran"
;		3. From using the dropdown list (filer list type) A_GuiControl - will contain "GUI_UnitPanelListType"
;
;	This label helps create an object of the TwoPanelSelection_LV class; these are used to keep track of the 
;	filtered units for the Unit panel (both the 'completed filtered' and 'under construction filtered' lists)

g_UnitPanelGUI:
;GUIcontrol := A_GuiControl

GuiControlGet, GUIcontrol,, GUI_UnitPanelRace 
IfInString, GUIcontrol, Protoss
	GUI_UnitPanelMenu.race := "Protoss"
else IfInString, GUIcontrol, Zerg
	GUI_UnitPanelMenu.race  := "Zerg"
else IfInString, GUIcontrol, Terran
	GUI_UnitPanelMenu.race  := "Terran"

GuiControlGet, CurrentList,, GUI_UnitPanelListType 
if (CurrentList = "Completed")
	GUI_UnitPanelMenu.ListType := CurrentList := "FilteredCompleted"
else if (CurrentList = "Under Construction")
	GUI_UnitPanelMenu.ListType := CurrentList := "FilteredUnderConstruction"

if (GUIcontrol = "") ; blank for the first gosub
	GUI_UnitPanelMenu.PreviousListType := GUI_UnitPanelMenu.ListType := CurrentList		


if (!GUI_UnitPanelMenu.PreviousRace)	;these vars store the previous race - save as gui submit doesnt affect them
	GUI_UnitPanelMenu.PreviousRace := GUI_UnitPanelMenu.race 
Else
{
	LV_UnitPanelFilter[GUI_UnitPanelMenu.PreviousListType, GUI_UnitPanelMenu.PreviousRace].storeItems()
	GUI_UnitPanelMenu.PreviousRace := GUI_UnitPanelMenu.race
	GUI_UnitPanelMenu.PreviousListType := GUI_UnitPanelMenu.ListType
}
gosub, g_CheckLV_UnitPanelObject

LV_UnitPanelFilter[GUI_UnitPanelMenu.ListType, GUI_UnitPanelMenu.race ].restoreItems()
return

;this is used by the above routine, It cannot be used during an update!!!!, as there was no listview gui & variables and its class wont work
g_CheckLV_UnitPanelObject:
if !aUnitLists
	Gosub, g_CreateUnitListsAndObjects ; used for some menu items, and for the custom unit filter gui remnant from unsuccessfull method of transferring ini settings during update - but no harm leaving it in.
if !IsObject(LV_UnitPanelFilter)
{
	LV_UnitPanelFilter := []
	for index, ListType in ["FilteredCompleted", "FilteredUnderConstruction"]
		for index, LoopRace in ["Terran", "Protoss", "Zerg"] 	;so this object will be full of the info ready for saving - no checks needed!
		{
			LV_UnitPanelFilter[ListType, LoopRace] := new TwoPanelSelection_LV("UnitPanelAvailableUnits", "UnitPanelFilteredUnitsCurrentRace")
			LV_UnitPanelFilter[ListType, LoopRace].removeAllitems() ; so ready for new units
			if aUnitPanelUnits[LoopRace,  ListType].maxindex()	;this prevents adding 1 'blank' spot/unit to the list when its empty
				LV_UnitPanelFilter[ListType, LoopRace].AddItemsToCurrentPanel(aUnitPanelUnits[LoopRace,  ListType], 1)
			if aUnitLists["UnitPanel", LoopRace].maxindex() ;this isnt really needed, as these lists always have units
			{
				LV_UnitPanelFilter[ListType, LoopRace].AddItemsToAvailablePanel(aUnitLists["UnitPanel", LoopRace], 1)
				; So Photon Overcharge is only displayed in the underConstruction panel. Dirty hacks.
				if (LoopRace = "Protoss" && ListType = "FilteredUnderConstruction")
					LV_UnitPanelFilter[ListType, LoopRace].AddItemsToAvailablePanel("PhotonOverCharge", 1)
			}
			LV_UnitPanelFilter[ListType, LoopRace].storeItems()
		}
}
return

class TwoPanelSelection_LV
{
	__New(AvailablePanel, CurrentListPanel) 
	{
		this.Available 	:= AvailablePanel	; eg associated var
		this.Current 	:= CurrentListPanel	; eg associated var
		this.CurrentItems := []
		this.AvailableItems := []
	}

	ModifyCol(panel = "")
	{
		if panel
			ModifyColListView(panel, "AutoHdr") 
		else 
		{
			ModifyColListView(this.Available, "AutoHdr")		;auto resizes columns
			ModifyColListView(this.Current, "AutoHdr")
		}		
	}
	removeAllitems(panel = "")
	{
		if panel
			removeAllItemsFromListView(panel)
		else ;remove all
		{
			removeAllItemsFromListView(this.Available)		;clears the fields
			removeAllItemsFromListView(this.Current)
		}
		this.ModifyCol()
	}
	restoreItems()
	{
			this.removeAllitems()
			this.AddItemsToCurrentPanel(this.CurrentItems, 1)
			this.AddItemsToAvailablePanel(this.AvailableItems, 1)
			this.ModifyCol()
	}
	storeItems()
	{
		this.storeCurrentItems()
		this.storeAvailabletItems()
	}
	storeAvailabletItems()
	{
		this.AvailableItems := retrieveItemsFromListView(this.Available)
	}	
	storeCurrentItems()
	{
		this.CurrentItems := retrieveItemsFromListView(this.Current)
	}
	otherPanel(Panel)
	{
		if (panel = this.Available)
			return this.Current 
		else if (panel = this.Current)
			return this.Available 
		else return 0
	}
	AddItemsToAvailablePanel(Items, CheckOtherPanel = "")
	{
		this.AddItemsToPanel(Items, this.Available, CheckOtherPanel)
		this.ModifyCol()
		return
	}
	AddItemsToCurrentPanel(Items, CheckOtherPanel = "")
	{
		this.AddItemsToPanel(Items, this.current, CheckOtherPanel)
		this.ModifyCol()
		return
	}

	AddItemsToPanel(Items, Panel, checkPanel = "")
	{
		if checkPanel 	;this is used to prevent an item from showing up in both panels when first adding them
			checkPanel := this.otherPanel(Panel)
		if isobject(Items)
		{
			for index, item in items
				if (!isItemInListView(Item, Panel) && ( (checkPanel && !isItemInListView(Item, checkPanel)) || !checkPanel) )
					addItemToListview(item, Panel)
		}
		Else
			if (!isItemInListView(Items, Panel) && ( (checkPanel && !isItemInListView(Item, checkPanel)) || !checkPanel) )
				addItemToListview(Items, Panel)
		this.ModifyCol()
		return
	}
	MoveSelectedAvailableToCurrent()
	{
		aSelected := retrieveSelectedItemsFromListView(this.Available)
		for index, item in aSelected
			this.TransferItemsBetweenPanels(this.Available, this.current, item)
		this.ModifyCol()
		this.storeItems()
		return

	}

	MoveSelectedCurrentToAvailable()
	{
		aSelected := retrieveSelectedItemsFromListView(this.current)
		for index, item in aSelected
			this.TransferItemsBetweenPanels(this.current, this.Available, item)
		this.ModifyCol()
		this.storeItems()
		return

	}

	TransferItemsBetweenPanels(Origin, Deistination, Items, RemoveOriginals = True)
	{
		if isobject(Items)
		{
			for index, item in items
			{
				if !isItemInListView(Item, Deistination)
					addItemToListview(item, Deistination)
				if RemoveOriginals
					removeItemFromListView(Item, Origin)
			}
		}
		Else
		{
			if !isItemInListView(Items, Deistination)
					addItemToListview(Items, Deistination)	
			if RemoveOriginals
					removeItemFromListView(Items, Origin)
		}
		this.ModifyCol()
		this.storeItems()
		return
	}
}

	ModifyColListView(ListView = "", options = "")
	{
		if ListView
			Gui, ListView, %ListView% ;note all future and current threads now refer to this listview!
		if options
		{
			Columns := LV_GetCount("Column") 	;needed, as you must do each column individually if specifying options
			while (A_Index <= Columns)
				LV_ModifyCol(A_Index, options)	
		}
		else LV_ModifyCol()	
		return
	}
	; returns the row number if item is present
	isItemInListView(Item, ListView="")
	{
		if ListView
			Gui, ListView, %ListView% ;note all future and current threads now refer to this listview!
		a := []
		while (a_index <= LV_GetCount())
		{
			LV_GetText(OutputVar, a_index)
			if (OutputVar = Item)
				return a_index
		}
		return 0
	}
	; The index of the array equals the row number
	retrieveSelectedItemsFromListView(ListView="", byref count = "")
	{ 

		if ListView
			Gui, ListView, %ListView% ;note all future and current threads now refer to this listview!
		a := []
		while (nextItem := LV_GetNext(nextItem)) ;return next item number for selected items - then returns 0 when done
		{
			LV_GetText(OutputVar, nextItem)
			a[nextItem] := OutputVar
			count++
		}
		return a
	}



	addItemToListview(item, ListView="")
	{
		if ListView
			Gui, ListView, %ListView% ;note all future and current threads now refer to this listview!
		LV_Add("", item, "")
		return
	}

	removeItemFromListView(Item, ListView="")
	{
		if ListView
			Gui, ListView, %ListView% ;note all future and current threads now refer to this listview!
		a := []
		while (a_index <= LV_GetCount())
		{
			LV_GetText(OutputVar, a_index)
			if (OutputVar = Item)
				LV_Delete(a_index) 
		}
		return
	}
	retrieveItemsFromListView(ListView="")
	{

		if ListView
			Gui, ListView, %ListView% ;note all future and current threads now refer to this listview!
		a := []
		while (a_index <= LV_GetCount())
		{
			LV_GetText(OutputVar, a_index)
			a.insert(OutputVar)
		}
		return a
	}
	removeAllItemsFromListView(ListView="")
	{	
		if ListView
			gui, ListView, %ListView% ;note all future and current threads now refer to this listview!
		return LV_Delete() ; 1 on success 
	}
	GetItemCountFromListView(ListView="")
	{	
		if ListView
			gui, ListView, %ListView% ;note all future and current threads now refer to this listview!
		return LV_GetCount() ;
	}

local_minerals(ByRef Return_Base_index, SortBy="Index") ;Returns a list of [Uints] index position for minerals And optionaly the [unit] index for the local base
{	;	Nexus = 90 CommandCenter = 48 Hatchery = 117
	;sc2_unit_count := getUnitCount()		;can put the count outside the loop for this
	While (A_Index <= getHighestUnitIndex()) 
	{
		unit := A_Index - 1
		type := getUnitType(unit)
		IF isUnitLocallyOwned(unit)
		AND ( type = 90 OR type = 48 OR type = 117 )
			Base_loc_index := unit	;
		Else IF type = 253 ; 253 = Normal Mineral patch
			MineraList .= unit "|"  ; x|x|
	}
	MineraList := SubStr(MineraList, 1, -1)	;remove the trailing |
	loop, parse, MineraList, | 
	{
		IF areUnitsNearEachOther( A_LoopField, Base_loc_index, 8, 8) ; 1 if near
			Result .= A_LoopField "|"
	}
	MineraList := RTrim(Result, "| ")
	If (SortBy = "Distance")
		MineraList := sortUnitsByDistance(Base_loc_index, MineraList) 
	IF IsByRef(Return_Base_index)
		Return_Base_index := Base_loc_index
	Return MineraList
}

sortUnitsByDistance(Base, unitlist="", units*)
{ 	; accepts a "|" delimeter list, OR a variadic list
	List := []		;used to sort mineral patches by closest
	if unitlist		;but still doesnt find the 3 relative closest patches
	{				;probably due to where 'nexus' is - look at this later.
		units := []	;actually unit x,y seems to be from the centre of the unit.
		loop, parse, unitlist, |
			units[A_index] := A_LoopField
	}	
	for index, unit in units
	{
		Base_x := getUnitPositionX(Base), Base_y := getUnitPositionY(Base)
		unit_x := getUnitPositionX(unit), unit_y := getUnitPositionY(unit)
		List[A_Index] := {Unit:unit,Distance:Abs(Base_x - unit_x) + Abs(Base_y - unit_y)}	
	}
	bubbleSort2DArray(List, "Distance")
	For index, obj in List
		SortedList .= List[index].Unit "|"
	return RTrim(SortedList, "|")
} 

SortUnitsByMapOrder(unitlist="", units*)
{ 	; accepts a "|" delimeter list, OR a variadic list
	List := []		;used to sort mineral patches by from left to right, or top to bottom
	if unitlist		
	{			
		units := []
		loop, parse, unitlist, |
			units[A_index] := A_LoopField
	}	
	for index, unit in units
		List[A_Index] := {Unit:unit, X: getUnitPositionX(unit), Y: getUnitPositionY(unit)}	

	bubbleSort2DArray(List, "X") ;3rd param def 1 OR ascending
	For index, obj in List
	{
		If (index = List.minindex())
			X_Min := List[index].X
		If (index = List.MaxIndex())
			X_Max := List[index].X
	}
	bubbleSort2DArray(List, "Y")
	For index, obj in List
	{
		If (index = List.minindex())
			Y_Min := List[index].Y
		If (index = List.MaxIndex())
			Y_Max := List[index].Y
	}		 
	If (X_Delta := Abs(X_Max-X_Min)) > (Y_Delta := Abs(Y_Max-Y_Min))
	{
		bubbleSort2DArray(List, "X")
		For index, obj in List
			SortedList .= List[index].Unit "|"
	}
	else 
	{
		bubbleSort2DArray(List, "Y")
		For index, obj in List
			SortedList .= List[index].Unit "|"	
	}
	return RTrim(SortedList, "|")
} 


areUnitsNearEachOther(unit1, unit2, x_max_dist = "", y_max_dist = "", compareZ = 1)
{
	if !(x_max_dist || y_max_dist)
		Return "One max distance is required!"
	Else If  !y_max_dist
		y_max_dist := x_max_dist
	Else x_max_dist := y_max_dist

	x_dist := Abs(getUnitPositionX(unit1) - getUnitPositionX(unit2))
	y_dist := Abs(getUnitPositionY(unit1) - getUnitPositionY(unit2))																									
																								; there is a substantial difference in height even on 'flat ground' - using a max value of 1 should give decent results
	Return Result := (x_dist > x_max_dist) || (y_dist > y_max_dist) || (compareZ && Abs(getUnitPositionZ(unit1) - getUnitPositionZ(unit2)) > 1) ? 0 : 1 ; 0 Not near
}





Get_Bmap_pixel(u_array_index_number, ByRef Xvar, ByRef Yvar)
{
local u_x, u_y, tx, ty

	P_Xcam := getPlayerCameraPositionX()
	P_Ycam := getPlayerCameraPositionY() + (7142/4096)

	u_x := getUnitPositionX(u_array_index_number)
	u_y := getUnitPositionY(u_array_index_number)


	X_Bmap_conv := 950/(61954/4096)  ; pixel/map_X
	if (u_x >= P_Xcam)
	{
		u_x := u_x - P_Xcam 	; Hence relative to camera
		tx := u_x * X_Bmap_conv
		tx := 960 + tx
	}
	Else
	{
		u_x := P_Xcam  - u_x
		tx := u_x * X_Bmap_conv
		tx := 960 - tx
	}

	if (u_y >= P_Ycam)
	{
	;	SoundPlay *-1
		u_y := u_y - P_Ycam
	;	Y_Bmap_conv_T := 375/(41661/4096)		 ; (for top)
	;	Y_Bmap_conv := (375/7.89) *.7
	;	Y_Bmap_conv := (u_y/(41661/4096)) *	375/(41661/4096) *1.3
		Y_Bmap_conv :=  375/ (10.17114 - (5.6 + (u_y/(41661/4096)))*.1)

		ty := u_y * Y_Bmap_conv	
		ty := 375 - ty
	}
	Else
	{
		u_y := P_Ycam - u_y
		Y_Bmap_conv := 375/ (7.89 - (5.6 - (u_y/(22976/4096)) *	3.5 ))
		ty := u_y * Y_Bmap_conv	
		ty := 375 + ty
	}
	If IsByRef(Xvar)
		Xvar := Round(tx)
	IF IsByRef(Yvar)
		Yvar := Round(ty)
	if (Xvar < 15 || Xvar > A_ScreenWidth-15) || (Yvar < 15) ; the mouse will push on/move the screen 
		Return 1
}
getBuildingList(F_building_var*)	
{ 
	loop, % DumpUnitMemory(MemDump)
	{
		unit := A_Index - 1
	    if isTargetDead(TargetFilter := numgetUnitTargetFilter(MemDump, unit)) || !isOwnerLocal(owner := numgetUnitOwner(MemDump, Unit))
	       Continue
	    pUnitModel := numgetUnitModelPointer(MemDump, Unit)
	    Type := numgetUnitModelType(pUnitModel)
	    For index, building_type in F_building_var
		{	
			IF (type = building_type && !isTargetUnderConstruction(TargetFilter))
				List .= unit "|"  ; x|x|	
		}

	}	
	List := SubStr(List, 1, -1)	
	sort list, D| Random
	Return List
}

isTargetDead(TargetFilter)
{	global aUnitTargetFilter
	return TargetFilter & aUnitTargetFilter.Dead
}

isTargetUnderConstruction(TargetFilter)
{	global aUnitTargetFilter
	return TargetFilter & aUnitTargetFilter.UnderConstruction
}

; Note Currently used!
isUserCastingOrBuilding()	;note auto casting e.g. swarm host will always activate this. There are separate bool values indicating buildings at certain spells
{	global
	return pointer(GameIdentifier, P_IsUserCasting, O1_IsUserCasting, O2_IsUserCasting, O3_IsUserCasting, O4_IsUserCasting)
}


filterSlectionTypeByEnergy(EnergyFilter="", F_utype*) ;Returns the [Unit] index number
{	
	selection_i := getSelectionCount()
	while (A_Index <= selection_i)		;loop thru the units in the selection buffer	
	{	
		unit := getSelectedUnitIndex(A_Index -1)
		type := getUnitType(Unit)
		If (EnergyFilter = "")
			For index, F_Found in F_utype
			{
				If (F_Found = type)
					Result .= unit "|"		;  selctio buffer refers to 0 whereas my [unit] did begin at 1
			}		
		Else
			For index, F_Found in F_utype
			{
				If (F_Found = type) AND (EnergyFilter <= getUnitEnergy(unit))
					Result .= unit "|"	
			}	
	}	
	Return Result := SubStr(Result, 1, -1)		
}

Edit_AG:	;AutoGroup and Unit include/exclude come here
	TMP_AG_ControlName := SubStr(A_GuiControl, 2)
	GuiControlGet, TMP_EditAG_Units,, %TMP_AG_ControlName% ;checks if field is empty for delimiter 
	list := ""
	IfInString, A_GuiControl, Terran
		Race := "Terran"
	else IfInString, A_GuiControl, Protoss
		Race := "Protoss"
	else IfInString, A_GuiControl, Zerg
		Race := "Zerg"
	Else
	{
		IfInString, A_GuiControl, Army
			list := "l_UnitNamesArmy"
		else 
			list := "l_UnitNames"
	}
	if instr(A_GuiControl, "QuickSelect")
		list := "l_UnitNamesQuickSelect" race
	else if !list 
	{	
		IfInString, A_GuiControl, Army
			list := "l_UnitNames" Race "Army"
		else 
			list := "l_UnitNames" Race
	}

	list := %list%

	IfInString, A_GuiControl, UnitHighlight
		TMP_EditAG_Units .= (TMP_EditAG_Units ? ", " : "") GUISelectionList("Select Unit",, list, "|", ","), delimiter := ","
	Else IfInString, A_GuiControl, quickSelect
		TMP_EditAG_Units .= (TMP_EditAG_Units ? "`n" : "") GUISelectionList("Select Unit",, list, "|", "`n"), delimiter := "`n"
	Else
		TMP_EditAG_Units .= (TMP_EditAG_Units ? ", " : "") GUISelectionList(!instr(A_GuiControl, "Army") ? "Auto Group " SubStr(A_GuiControl, 0, 1) : "Select Unit",, list, "|", ","), delimiter := "," ;retrieve the last character of name ie control number 0/1/2 etc		
	
	list := checkList := ""
	loop, parse, TMP_EditAG_Units, %delimiter%
	{
		if aUnitID.HasKey(string := Trim(A_LoopField, "`n`, `t")) ; get rid of spaces which cause haskey to fail
		{	
			if string not in %checkList%
				list .= string (delimiter = "`n" ? delimiter : delimiter A_Space),  checkList .= string "," ; leave a space for the gui if comma delimiter

		}
	}
	GUIControl,, %TMP_AG_ControlName%, % Trim(list, "`,`n `t")
Return

; If multiSelectionDelimiter is true (not null/0) then multiple items can be selected and returned.
; multiSelectionDelimiter should be the delimiter used to separate the returned items

GUISelectionList(Title = "", textField := "Select Unit Type(s):", list := "Error", listdelimiter := "|", multiSelectionDelimiter := "|")
{
	static F_drop_Name 	; as a controls variable must by global or static

	StringReplace, list, list, %listdelimiter%, |, All

	Gui, Add2AG:+LastFound
	GuiHWND := WinExist() 
	Gui, Add2AG:Add, Text, x5 y+10, %textField%
	Gui, Add2AG:Add, ListBox, % "x5 y+10 w150 h280 VF_drop_Name sort " (multiSelectionDelimiter ? "Multi" : ""), %list%
	Gui, Add2AG:Add, Button, y+20 x5 w60 h35 gB_ADDAdd2AG, Add
	Gui, Add2AG:Add, Button, yp+0 x95 w60 h35  gB_closeAdd2AG, Close
	GUI, Add2AG:+AlwaysOnTop +ToolWindow
	GUI, Add2AG:Show, w160 h380, %Title%
	Gui, Add2AG:+OwnerOptions
	Gui, Options:+Disabled
 	;return ;cant use return here, otherwise script will continue running immeditely after the functionc call
	;pause	
	WinWaitClose, ahk_id %GuiHWND%
						; ****also note, the function will jump to bclose but aftwards will continue from here linearly down
	B_ADDAdd2AG:				;hence have to check whether to return any value
	Gui, Options:-Disabled
	Gui, Options:Show		;required to keep from minimising
	Gui, Add2AG:Submit
	Gui Add2AG:Destroy
	;GuiControlGet, Edit_Unit_name,, F_drop_Name
	;pause off

	if !close
	{
		if multiSelectionDelimiter
			StringReplace, F_drop_Name, F_drop_Name, |, %multiSelectionDelimiter%, All
		Return F_drop_Name
	}
	Return 

	B_closeAdd2AG:
	Add2AGGUIEscape:
    Add2AGGUIClose:
	Close := 1
	Gui, Options:-Disabled
	Gui Add2AG:Destroy
	;pause off
	Return ;this is needed to for the above if (if the cancel/escape gui)

}


; So will turn off autoworker for 5 seconds only if user presses esc and only that main is selected
; dont check TmpDisableAutoWorker so if cancels another builder a few seconds later it will still update it 
g_temporarilyDisableAutoProduction:
delayAutoProduction()
return 


g_AutoBuildGUIToggleAutoWorkerState: ; AutoBuild GUI calls this label so that SAPI doesnt speak
g_UserToggleAutoWorkerState: 		; this launched via the user hotkey combination

if (aLocalPlayer["Race"] = "Terran" && (EnableAutoWorkerTerran := !EnableAutoWorkerTerran))
|| (aLocalPlayer["Race"] = "Protoss" && (EnableAutoWorkerProtoss := !EnableAutoWorkerProtoss))
{
	AW_MaxWorkersReached := TmpDisableAutoWorker := 0 		; just incase the timers bug out and this gets stuck in enabled state
	MT_CurrentGame.MaxWorkers := ""				; This is here so that if you lose a bunch of workers and turn it back on, it won't make the exact same about again 
	autoBuildGameGUI.enableItems("SCV,Probe", False)
	if (A_ThisLabel = "g_UserToggleAutoWorkerState")
		tSpeak("On")											
	SetTimer, g_autoWorkerProductionCheck, 200
}
else 
{
	SetTimer, g_autoWorkerProductionCheck, off
	autoBuildGameGUI.disableItems("SCV,Probe")
	if (A_ThisLabel = "g_UserToggleAutoWorkerState")
		tSpeak("Off")
}

return 

delayAutoProduction()
{
	global TmpDisableAutoWorker, EnableAutoWorkerTerran, EnableAutoWorkerProtoss
	if getSelectionCount() = 1
	{
		type := getUnitType(unitIndex := getSelectedUnitIndex())
		if isUnderConstruction(unitIndex) || aLocalPlayer["slot"] != getUnitOwner(unitIndex)
			return

		if (aLocalPlayer["Race"] = "Terran" && EnableAutoWorkerTerran && (type = aUnitID["OrbitalCommand"] || type = aUnitID["PlanetaryFortress"] || type = aUnitID["CommandCenter"]))
		|| (aLocalPlayer["Race"] = "Protoss" && EnableAutoWorkerProtoss && type = aUnitID["Nexus"])
		{
			getBuildStats(unitIndex, QueueSize)
			if (QueueSize <= 2) ; so wont toggle timer if cancelling extra queued workers
			{
				TmpDisableAutoWorker := True
				SetTimer, g_RenableAutoWorkerState, -4500 ; give time for user to morph/lift base ; use timer so dont have this function queueing up
			}			
		}
		else if autoBuild.getRaceFromStructureName(aUnitName[type])	&& autoBuild.isStructureActive(aUnitName[type]) ; getRaceFromStructureName Just checks if its a structure which is handled by autoBuild
		{
			getBuildStats(unitIndex, QueueSize)
			if (QueueSize <= 2) ; even if reactor is present this is good. As the repeated esc presses will trigger this if they cancel enough of the units
			{
				autoBuild.TmpDisableAutoBuild := True
				SetTimer, g_RenableAutoBuildState, -4500
			}
		}	
	}
	return 
	g_RenableAutoWorkerState:
	TmpDisableAutoWorker := False
	return 
	g_RenableAutoBuildState:
	autoBuild.TmpDisableAutoBuild := False
	return 
}


resumeAutoWorker:
SetTimer, g_autoWorkerProductionCheck, 200
return 

g_autoWorkerProductionCheck:
;if (WinActive(GameIdentifier) && time && EnableAutoWorker%LocalPlayerRace% && !TmpDisableAutoWorker && !AW_MaxWorkersReached)
if WinActive(GameIdentifier) && time && !TmpDisableAutoWorker && !AW_MaxWorkersReached
&& ((aLocalPlayer["Race"] = "Terran" && EnableAutoWorkerTerran) || (aLocalPlayer["Race"] = "Protoss" && EnableAutoWorkerProtoss))
	autoWorkerProductionCheck()
return



autoWorkerProductionCheck()
{	GLOBAl aUnitID, aLocalPlayer, Base_Control_Group_T_Key, AutoWorkerStorage_P_Key, AutoWorkerStorage_T_Key, Base_Control_Group_P_Key, NextSubgroupKey
	, AutoWorkerMakeWorker_T_Key, AutoWorkerMakeWorker_P_Key, AutoWorkerMaxWorkerTerran, AutoWorkerMaxWorkerPerBaseTerran
	, AutoWorkerMaxWorkerProtoss, AutoWorkerMaxWorkerPerBaseProtoss, AW_MaxWorkersReached
	, aResourceLocations, aButtons, EventKeyDelay
	, AutoWorkerAPMProtection, AutoWorkerQueueSupplyBlock, AutoWorkerAlwaysGroup, AutoWorkerWarnMaxWorkers, MT_CurrentGame, aUnitTargetFilter
	, EnableAutoWorkerTerran, EnableAutoWorkerProtoss
	
	static TickCountRandomSet := 0, randPercent,  UninterruptedWorkersMade, waitForOribtal := 0, lastMadeWorkerTime := -50

	if (aLocalPlayer["Race"] = "Terran") 
	{
		mainControlGroup := Base_Control_Group_T_Key
		controlstorageGroup := AutoWorkerStorage_T_Key
		makeWorkerKey := AutoWorkerMakeWorker_T_Key
		maxWorkers := AutoWorkerMaxWorkerTerran
		maxWorkersPerBase := AutoWorkerMaxWorkerPerBaseTerran
	}
	else if (aLocalPlayer["Race"] = "Protoss") 
	{
		mainControlGroup := Base_Control_Group_P_Key
		controlstorageGroup := AutoWorkerStorage_P_Key
		makeWorkerKey := AutoWorkerMakeWorker_P_Key
		maxWorkers := AutoWorkerMaxWorkerProtoss
		maxWorkersPerBase := AutoWorkerMaxWorkerPerBaseProtoss
	}
	else return

	; This simply adds a bit more randomness.
	; So if checking match history, you dont stop at exactly 70 workers
	; ever game

	if !MT_CurrentGame.MaxWorkers 
		MT_CurrentGame.MaxWorkers := maxWorkers + rand(-3, 2)
	maxWorkers := MT_CurrentGame.MaxWorkers

	workers := getPlayerWorkerCount()

	if (workers >= maxWorkers)
	{ 
		AW_MaxWorkersReached := True
	;	UninterruptedWorkersMade := 0 
		settimer, g_autoWorkerProductionCheck, Off 
		if (aLocalPlayer["Race"] = "Terran")  ; This is so you don't have to press the toggle button twice to turn it back on after losing workers.
			EnableAutoWorkerTerran := 0
		else EnableAutoWorkerProtoss := 0
		if AutoWorkerWarnMaxWorkers
			tSpeak("Maxed Workers")
		return 
	}
	if isGamePaused() || isMenuOpen() ;chat is 0 when  menu is in focus
		return ;as let the timer continue to check

	numGetControlGroupObject(oMainbaseControlGroup, mainControlGroup)
	workersInProduction := Basecount := almostComplete := idleBases := halfcomplete := nearHalfComplete := 0 ; in case there are no idle bases
	aRecentlyCompletedCC := []

	if !IsObject(MT_CurrentGame.TerranCCUnderConstructionList) ; because MT_CurrentGame gets cleared each game
		MT_CurrentGame.TerranCCUnderConstructionList := []

	time := getTime()
	; Prevent queuing during small lag events
	; Note that the hooks may still be installed & removed, as lastMadeWorkerTime is only set when a worker is actually made.
	if (Abs(time - lastMadeWorkerTime) < 1) 
		return
	; This will change the random percent every 12 seconds - otherwise
	; 200ms timer kind of negates the +/- variance on the progress meter
	if (A_TickCount - TickCountRandomSet > 12000) 
	{
		TickCountRandomSet := A_TickCount
		randPercent := rand(-0.10, .20) ; rand(-0.04, .15) 
	}
	
	for index, object in oMainbaseControlGroup.units
	{
		if ( object.type = aUnitID["CommandCenter"] || object.type = aUnitID["OrbitalCommand"]
		|| object.type = aUnitID["PlanetaryFortress"] || object.type = aUnitID["Nexus"] )
		{
			if !isUnderConstruction(object.unitIndex) 
			{
				nearGeyser := False
				; this is for terran, so if build cc inside base, wont build up to 60 workers even though 2 bases, but just 1 mining
				for index, geyser in aResourceLocations.geysers
				{
					if isUnitNearUnit(geyser, object, 7.9) ; 7.9 also compares z but for 1 map unit ; so if the base is within 8 map units it counts. It seems geysers are generally no more than 7 or 7.5 away
					{
						Basecount++ ; for calculating max workers per base
						nearGeyser := True
						break
					}
				}
				if (townHallStatus := isWorkerInProduction(object.unitIndex)) <= 0 ; also accounts for if morphing/flying 
				{
					; this will prevent a recently converted orbital which is not near a geyser from making a working for 20 seconds
					; giving time to lift it off and land it at the correct position
					if (!nearGeyser && townHallStatus = -1 && aUnitID["OrbitalCommand"] = isCommandCenterMorphing(object.unitIndex))
						MT_CurrentGame.TerranCCUnderConstructionList[object.unitIndex] := time

					; This is used to prevent a worker being made at a CC which has been completed or obital which has just finished morphing 
					; for less than 20 in game seconds or a just landed CC for 10 seconds
				
					; 31/12/14 - Actually I don't think this is required for CCs (it is for completed orbitals), as CCs have the lowest build priority
					; if OC,PF, and CC are selected the queue goes PF->OC->CC
					; But it is also required when you have multiple CC
					if (MT_CurrentGame.TerranCCUnderConstructionList.HasKey(object.unitIndex) && (time - MT_CurrentGame.TerranCCUnderConstructionList[object.unitIndex]) <= 20)
					|| (MT_CurrentGame.TerranCCJustLandedList.HasKey(object.unitIndex) && (time - MT_CurrentGame.TerranCCJustLandedList[object.unitIndex]) <= 10)
					{
						removeRecentlyCompletedCC := True 
						aRecentlyCompletedCC.insert(object.unitIndex)
					}	
					else if townHallStatus = 0
						idleBases++
				}
				else 
				{
					if (object.type = aUnitID["PlanetaryFortress"])
						progress := getBuildStatsPF(object.unitIndex, QueueSize)
					else
						 progress := getBuildStats(object.unitIndex, QueueSize) ; returns build percentage
					 if (QueueSize = 1)
					 {
					 	if (progress >= .97)
					 		almostComplete++
					 	else if (progress - randPercent >= .65)
					 		halfcomplete++
					 	else if (progress >= .35)
					 		nearHalfComplete++
					 }
					 workersInProduction += QueueSize

				}
				TotalCompletedBasesInCtrlGroup++
				;L_ActualBasesIndexesInBaseCtrlGroup .= "," object.unitIndex
			}
			else if (aLocalPlayer.race = "Terran")
				MT_CurrentGame.TerranCCUnderConstructionList[object.unitIndex] := time
		}
		else if ( object.type = aUnitID["CommandCenterFlying"] || object.type = aUnitID["OrbitalCommandFlying"] )
		{
			Basecount++ 	; so it will (account for flying base) and keep making workers at other bases if already at max worker/base	
			; This is so a recently landed CC wont make a worker for 10 in game seconds - so can convert to orbital
			if (object.type = aUnitID["CommandCenterFlying"])
			{
				if !IsObject(MT_CurrentGame.TerranCCJustLandedList) ; because MT_CurrentGame gets cleared each game
					MT_CurrentGame.TerranCCJustLandedList := []
				MT_CurrentGame.TerranCCJustLandedList[object.unitIndex] := time
			}

		}
		L_BaseCtrlGroupIndexes .= "," object.unitIndex ; this is just used as a means to check the selection
	}

	if (workers / Basecount >= maxWorkersPerBase)
		return
	
	if (AutoWorkerQueueSupplyBlock && getPlayerSupply() < 200)
		MaxWokersTobeMade := howManyUnitsCanBeProduced(50)
	else MaxWokersTobeMade := howManyUnitsCanBeProduced(50, 0, 1)

	if (MaxWokersTobeMade > TotalCompletedBasesInCtrlGroup) 	
		MaxWokersTobeMade := TotalCompletedBasesInCtrlGroup

	if (MaxWokersTobeMade > idleBases + almostComplete + halfcomplete)
		MaxWokersTobeMade := idleBases + almostComplete + halfcomplete

	if (MaxWokersTobeMade + workersInProduction + workers >= maxWorkers)
		MaxWokersTobeMade := maxWorkers - workers - workersInProduction

	; this will give the player a few seconds or so to convert the orbital before it makes another worker

	; Rax takes 65s to build - has 1000 hp  so 15.3866 hp/s
	; worker takes 17s to build

	; lowest 55% completed of a svc before another is made- so 7.65 s remaining on scv build time
	; 7.65 * 15.3866 = 876.9072 - so rax should have more than 876 hp
	; obviously this wont work correctly if the rax is being attacked 
	
	; Update:Now uses construction % not hp

	if (MaxWokersTobeMade && TotalCompletedBasesInCtrlGroup <= 2 && aLocalPlayer["Race"] = "Terran" && !MT_CurrentGame.HasSleptForObital)
	{
		; So the user is a noob and isn't making an orbital 
		; lets not iterate all of the units unnecessarily
		if (getPlayerWorkersBuilt() > 20)
			MT_CurrentGame.HasSleptForObital := True

		for index, base in oMainbaseControlGroup.units
		{	
		;	; user already has at least one upgraded CC so lets not bother
			if (base.type = aUnitID["OrbitalCommand"] 
			|| base.type = aUnitID["OrbitalCommandFlying"] 
			|| base.type = aUnitID["PlanetaryFortress"])
				MT_CurrentGame.HasSleptForObital := True

			; this will prevent a pause if the user has no CCs
			; or 1 is already being upgraded
			if (base.type = aUnitID["CommandCenter"])
			{
				if isCommandCenterMorphing(base.UnitIndex)
					MT_CurrentGame.HasSleptForObital := True
				else 
					CommandCenterInCtrlGrp := True
			}
		}

		; No command centre, so lets not bother
		if !CommandCenterInCtrlGrp
			MT_CurrentGame.HasSleptForObital := True

		if !MT_CurrentGame.HasSleptForObital
		{
			loop, % DumpUnitMemory(MemDump)
			{
				TargetFilter := numgetUnitTargetFilter(MemDump, unit := A_Index - 1)
				if (TargetFilter & aUnitTargetFilter.Dead 
				|| numgetUnitOwner(MemDump, Unit) != aLocalPlayer["Slot"]
				|| numgetUnitModelType(numgetUnitModelPointer(MemDump, Unit)) != aUnitID["Barracks"])
			    	Continue

			    if !(TargetFilter & aUnitTargetFilter.UnderConstruction)
			    {
			    	BarracksHasFinished := True
			    	break
			    }

			    if (mostCompletedRax < thisRax := getBuildProgress(getUnitAbilityPointer(unit), aUnitID.Barracks))
			    	mostCompletedRax := thisRax

			}
		}																	
		if (!MT_CurrentGame.HasSleptForObital && (mostCompletedRax > 0.83 || BarracksHasFinished))
		{
			MT_CurrentGame.HasSleptForObital := True 

			; As this thread has a default priority of 0, higher than some others, if we dont lower it,
			; other waiting timers/threads with a lower priority cannot interrupt this thread while it 
			; is sleeping!!
			; Don't need to change the priority back, as the timer will automatically launch this routine
			; with its default priority

			;Thread, Priority, -2147483648
			;sleep, 11000
			SetTimer, g_autoWorkerProductionCheck, Off
			SetTimer, resumeAutoWorker, -11000
			return
		}
	}

	; This will on occasion queue more than 1 workers, only if the player is floating a lot of extra minerals though
	; Just to make the automation a little bit more random
	if (MaxWokersTobeMade && rand(1, 5) = 1) 
	{
		pMinerals := getPlayerMinerals() 
		if (TotalCompletedBasesInCtrlGroup = 1 && pMinerals >= 540 && getPlayerWorkersBuilt() > 18)
			MaxWokersTobeMade := 2
		else if (TotalCompletedBasesInCtrlGroup >= 2 && pMinerals >= 1500)
			MaxWokersTobeMade := round(MaxWokersTobeMade * 2.2)
		else if (TotalCompletedBasesInCtrlGroup >= 2 && pMinerals >= 800)
			MaxWokersTobeMade := round(MaxWokersTobeMade * 1.75)
	}

	currentWorkersPerBase := (workers + workersInProduction)  / Basecount
	if ( (MaxWokersTobeMade / Basecount) + currentWorkersPerBase >= maxWorkersPerBase )
		MaxWokersTobeMade := round((maxWorkersPerBase - currentWorkersPerBase) * Basecount)

	; this attempts to minimise the number of 'auto productions' per worker production cycle.
	; to reduce the chances of interfering with user input
	; it will make workers if a worker is >= 95% complete (and only 1 in queue) or there are idle bases
	; when it does this it will also make workers for bases where the worker is >= 65% complete  (and only 1 in queue)
	; no workers will be made there are workers between 45% and 65% and no idle bases or almost completed queues

	if (MaxWokersTobeMade >= 1) && (idleBases || almostComplete || (halfcomplete && !nearHalfComplete)  ) ; i have >= 1 in case i stuffed the math and end up with a negative number or a fraction
	{
		While ( isUserBusyBuilding() || isCastingReticleActive() 
		|| GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
		|| getkeystate("Enter", "P") 
		|| getkeystate("Tab", "P") 
		|| getPlayerCurrentAPM() > AutoWorkerAPMProtection
		||  A_mtTimeIdle < 50)
		{
			if (A_index > 36)
				return ; (actually could be 480 ms - sleep 1 usually = 20ms)
			Thread, Priority, -2147483648	
			sleep 1
			Thread, Priority, 0	
		}

		; as can be stuck in the loop above for a while, lets check still have minerals to build the workers
		if (MaxWokersTobeMade > currentMax := howManyUnitsCanBeProduced(50))
			MaxWokersTobeMade := currentMax
		
		if (!isSelectionGroupable(oSelection) || isGamePaused() || isMenuOpen() || !MaxWokersTobeMade) ; MaxWokersTobeMade could be 0 after the loop above
			return
		Thread, NoTimers, true
		critical, 1000
		setLowLevelInputHooks(True)
		;dsleep(20)
		dsleep(10)


		; The reason the camera jumps with current code is due to user currently pressing the town hall ctrl group 
		; e.g. 4, pReleases it, then presses it down again - it effectively creates this 4s4


		; I should change this so pReleaseKeys isn't called until absolutely necessary
		; that way wont get a double press when build aborts 
		releasedKeys := input.pReleaseKeys(True)
		input.pSend("{shift up}{ctrl up}") ; testing if this reduces control bug (or if its a timing issue latery)
		;dSleep(40) ; increase safety ensure selection buffer fully updated
		dSleep(25) ; give it a reasonable amount of time for it to at least begin updating

		HighlightedGroup := getSelectionHighlightedGroup()
		selectionPage := getUnitSelectionPage()

		If numGetSelectionSorted(oSelection) && oSelection.IsGroupable ; = 0 as nothing is selected so cant restore this/control group it
		{ 
			; This function is mainly for the auto-control group. So when a user clicks on a finished CC
			; it will get auto-grouped, but wont immediately make an SCV (which would prevent converting
			; it into an orbital), the user has 4 real seconds from clicking it to convert it
			; before SCV production recommences
			; Dont need to check if locally owned CC as the function above already 
			; did this

			if (TotalCompletedBasesInCtrlGroup >= 2 && oSelection.count = 1
				&& oSelection.units[1].unitID = aUnitID.CommandCenter
				&& isInControlGroup(mainControlGroup, oSelection.units[1].UnitIndex) )
			{
				if !IsObject(MT_CurrentGame.CommandCenterPauseList) ; because MT_CurrentGame gets cleared each game
					MT_CurrentGame.CommandCenterPauseList := []
				else 
				{
					for index, UnitIndex in MT_CurrentGame.CommandCenterPauseList
					{
						if (UnitIndex = oSelection.units[1].UnitIndex)
						{
							CommandCenterInList := True
							break 
						}
					}
				}
				if !CommandCenterInList
				{
					MT_CurrentGame.CommandCenterPauseList.insert(oSelection.units[1].UnitIndex)
					Input.revertKeyState()
					setLowLevelInputHooks(False)
					critical, off
					SetTimer, g_autoWorkerProductionCheck, Off
					settimer, resumeAutoWorker, -4500
					return
				}
			}

			if (releasedKeys = "")
			{
				bufferSize := selectionBufferFromGroup(predictedSelectionBuffer, mainControlGroup) 
				BaseControlGroupNotSelected := !compareSelections(predictedSelectionBuffer, bufferSize, 0) ; 0 so runs once 
				if !BaseControlGroupNotSelected ; so the townhall group is selected
				{
					dsleep(20) ; so a total of 45 ms since pReleaseKeys was called -should be enough to at least allow the selection buffer to update / begin updating
					; during most of the game 
					; we can afford to sleep a little longer here, as this will only occur when the control group and selection buffers match
					; lets sleep a little longer and re-check the control group - 
					bufferSize := selectionBufferFromGroup(predictedSelectionBuffer, mainControlGroup) 
					BaseControlGroupNotSelected := !compareSelections(predictedSelectionBuffer, bufferSize, 0) ; 0 so runs once 
				}
			}
			else BaseControlGroupNotSelected := True ; Force it to use the temp ctrl group
			; This will prevent the camera jumping when the user currently has the town hall ctrl group key depressed 

			if (AutoWorkerAlwaysGroup || BaseControlGroupNotSelected || removeRecentlyCompletedCC)  
			{
				setControlGroup := True
				input.pSend(aAGHotkeys.set[controlstorageGroup])
				stopWatchCtrlID := stopwatch()
			}
			if BaseControlGroupNotSelected
			{
				input.psend("{click 0 0}" aAGHotkeys.Invoke[mainControlGroup]) ; need to click in case townhall group was just pressed (to prevent camera jump)
				compareSelections(predictedSelectionBuffer, bufferSize, 35) 
				dsleep(10)
				numGetSelectionSorted(oSelection)
			}

			; Some times recently completed CCs aren't removed. 
			; Perhaps not giving enough time for selection window to fully load so the
			; deselect clicks are being ignored
			; 

			; This is only required for recently converted orbitals which are out of position
			if removeRecentlyCompletedCC
			{
				aDeselect := []
				for i, unit in oSelection.units
				{
					for index, completedCCIndex in aRecentlyCompletedCC
					{
						if (unit.unitIndex = completedCCIndex)
							aDeselect.insert(unit.unitPortrait)
					}
				}
				if BaseControlGroupNotSelected
					dSleep(10)
				; else has already slept for longer than this
				reverseArray(aDeselect)
				clickUnitPortraits(aDeselect)
				dsleep(15)
				numGetSelectionSorted(oSelection)
			}

			; These terran mains are in order as they
			; would appear in the  selection group
			if (aLocalPlayer.Race = "Protoss")
				tabPosition := oSelection.TabPositions[aUnitId.Nexus]
			else if oSelection.TabPositions.HasKey(aUnitId.OrbitalCommand)
				tabPosition := oSelection.TabPositions[aUnitId.OrbitalCommand]
			else if oSelection.TabPositions.HasKey(aUnitId.CommandCenter)
				tabPosition := oSelection.TabPositions[aUnitId.CommandCenter]
			else if oSelection.TabPositions.HasKey(aUnitId.PlanetaryFortress)
				tabPosition := oSelection.TabPositions[aUnitId.PlanetaryFortress]
			else tabPosition := ""	; This should never occur

			if (tabPosition != "")
			{
				if BaseControlGroupNotSelected
					sendSequence .= sRepeat(NextSubgroupKey, tabPosition)
				else if (oSelection.HighlightedId != aUnitId.Nexus
				&& oSelection.HighlightedId != aUnitId.OrbitalCommand
				&& oSelection.HighlightedId != aUnitId.CommandCenter
				&& oSelection.HighlightedId != aUnitId.PlanetaryFortress)
					sendSequence .= sRepeat(NextSubgroupKey, tabPositionChanged := oSelection["Types"]  - HighlightedGroup + tabPosition)

				; other function gets spammed when user incorrectly adds a unit to the main control group 
				; (as it will take subgroup 0) and for terran tell that unit to 'stop' when sends s
				sendSequence .= sRepeat(makeWorkerKey, MaxWokersTobeMade)

				input.pSend(sendSequence), sendSequence := ""
			}

			if setControlGroup
			{
				elapsedTimeGrouping := stopwatch(stopWatchCtrlID)	
				if (elapsedTimeGrouping < 20)
					dSleep(ceil(20 - elapsedTimeGrouping))
				restoreSelection(controlstorageGroup, selectionPage, HighlightedGroup)			
			}
			else if tabPositionChanged ; eg the ebay or floating CC is selected is the selected tab in the already selected base control group
				input.pSend(sRepeat(NextSubgroupKey, oSelection["Types"]  - tabPosition + HighlightedGroup ))	
			WorkerMade := True
		}
		Input.revertKeyState()
		setLowLevelInputHooks(False)
		critical, off
		Thread, NoTimers, false 

		if WorkerMade
		{
			SetTimer, g_autoWorkerProductionCheck, Off
			SetTimer, resumeAutoWorker, -800 ; this will prevent the timer running again otherwise sc2 slower to update 'isin production' 
			lastMadeWorkerTime := time ; so will send another build event and queueing more workers ; 400 worked find for stable connection, but on Kr sever needed more. 800 seems to work well
		}		 					
	}
	return
}


; Used for Reversing SC
openCloseProcess(programOrHandle := "", Close := False)
{
	if close 
		return DllCall("CloseHandle","UInt",programOrHandle)
	else 
	{
		WinGet, pid, pid, % programOrHandle
		return DllCall("OpenProcess","Int",0x0800,"Int",0,"UInt",pid)
	}
}

; Used for RE
SuspendProcess(hProcess)
{
	return DllCall("ntdll\NtSuspendProcess","uint",hProcess)
}

; Used for RE
ResumeProcess(hProcess)
{
	return DllCall("ntdll\NtResumeProcess","uint",hProcess)
}



/*
Test: Game against AI

ctrl group 1 had 1 marine in it set to patrol
ctrl group 2 was empty
selection was of 113 units of different terran types

ctrl group selection
retrieve group 1,  order stop patrolling
sleep
restore ctrl group 2

Result 

; WHEN ctrl group empty, 12ms wasnt enough 13 is if the units which were ctrl grouped were idle
; if they have patrol commands (or doing other stuff probably too) then it takes longer
; 15 ms was adequate with command queue full of patrol commands for 113 units


f1::
input.pClickDelay(-1)
input.pSendDelay(-1)
critical, on
input.pSend("^2" "1" "s")
dsleep(15)
input.pSend(2)
critical off 
return

*/


/*

getZergProduction(EggUnitIndex)
{
	pAbilities := getUnitAbilityPointer(EggUnitIndex)
	base := readmemory(pAbilities + 0x20, GameIdentifier)
	p := readmemory(base - 0x48, GameIdentifier)
	p := readmemory(p, GameIdentifier)
	p := readmemory(p + 0xf4, GameIdentifier)
	p := readmemory(p, GameIdentifier)
	p := readmemory(p+4, GameIdentifier)
	s := ReadMemory_Str(p, GameIdentifier)
	msgbox % chex(p) " " s
	return

}


*/

isSelectionGroupable(ByRef oSelection)
{	GLOBAl aLocalPlayer
	if !numGetUnitSelectionObject(oSelection) 	; No units selected
		return False
	visibleUnit := False
	for index, object in oSelection.units 	; non-self unit selected, other wise will continually
	{
		if (object.owner != aLocalPlayer.slot)
			return False
		if !visibleUnit && !(getUnitTargetFilter(object.UnitIndex) & aUnitTargetFilter.Hidden)	; e.g. worker entering refinery does not change selection panel - but marines into a bunker or medivac does
			visibleUnit := True	
	}
	return visibleUnit
}

selectGroup(group, preSleep := -1, postSleep := 2)
{
	if (preSleep != -1)
		DllCall("Sleep", "Uint", preSleep)
	input.pSend(group)
	if (postSleep != -1)
		DllCall("Sleep", "Uint", postSleep)
	return	
}

ClickMinimapPlayerView()
{
	mapToMinimapPos(x := getPlayerCameraPositionX(), y := getPlayerCameraPositionY())
	input.pClick(x, y)
	return
}

varInMatchList(var, Matchlist)
{
	if var in %Matchlist%
		return 1
	else return 0
}


howManyUnitsCanBeProduced(mineralCost := 0, gasCost := 0, supplyUsage := 0)
{
	params := []
	if mineralCost
		params.insert(floor(getPlayerMinerals() / mineralCost))
	if gasCost
		params.insert(floor(getPlayerGas() / gasCost))
	if supplyUsage
		params.insert(floor(getPlayerFreeSupply() / supplyUsage))
	return lowestValue(params*)
}

lowestValue(aValues*)
{
	smallest := aValues[1]
	for index, value in aValues 
		if (value < smallest)
			smallest := value 
	return smallest
}

largestValue(aValues*)
{
	largest := aValues[1]
	for index, value in aValues 
		if (value > largest)
			largest := value 
	return largest
}

getPlayerFreeSupply(player="")
{ 	global aLocalPlayer
	If (player = "")
		player := aLocalPlayer["Slot"]
	freeSupply := getPlayerSupplyCap(player) - getPlayerSupply(player)
	if (freeSupply >= 0)
		return freeSupply 
	else return 0 ; as a negative value counts as true and would prevent using this in 'if freesupply() do' scenario
}

getSelectionType(units*) 
{
	if !units.MaxIndex() ;no units passed to function
		loop % getSelectionCount()				
			list .= getUnitType(getSelectedUnitIndex(A_Index - 1)) "|"
	Else
		for key, unit in units
			list .= getUnitType(getSelectedUnitIndex(A_Index - 1)) "|"
	Return SubStr(list, 1, -1)
}

setupAutoGroupNewTesting(Race, ByRef A_AutoGroup, aUnitID, A_UnitGroupSettings)
{
	A_AutoGroup := [], A_AutoGroup.Groups := [], A_AutoGroup.Units := []
	loop, 10
	{	
		ControlGroup := A_index - 1		;for control group 0			
		List := A_UnitGroupSettings[Race, ControlGroup]				
		StringReplace, List, List, %A_Space%, , All ; Remove Spaces
		StringReplace, List, List, |, `,, All ;replace | with ,
		List := Rtrim(List, "`, |") ;checks the last character
		checkList := ""
		If (List <> "")
		{
			loop, parse, List, `, 
			{
				if !aUnitID.HasKey(unitName := Trim(A_LoopField, "`n`, `t"))
					continue 
				unitID := aUnitID[unitName]
				if !A_AutoGroup.Units.HasKey(unitID)
					A_AutoGroup.Units[unitID] := []
				A_AutoGroup.Units[unitID, ControlGroup] := True

				if unitName not in %checkList%
				{
					A_AutoGroup.Groups[ControlGroup] .= (A_AutoGroup.Groups[ControlGroup] ? "," : "") unitID  ;assign the unit ID based on name from iniFile	
					checkList .= unitName ","
				}
			}
		}		 
	}
	Return
}

setupAutoGroup(Race, ByRef A_AutoGroup, aUnitID, A_UnitGroupSettings)
{
	A_AutoGroup := []
	loop, 10
	{	
		ControlGroup := A_index - 1		;for control group 0			
	;	Race := substr(Race, 1, 4)	;cos used Terr in ini
		List := A_UnitGroupSettings[Race, ControlGroup]				
		StringReplace, List, List, %A_Space%, , All ; Remove Spaces
		StringReplace, List, List, |, `,, All ;replace | with ,
		List := Rtrim(List, "`, |") ;checks the last character
		checkList := ""
		If (List <> "")
		{
			loop, parse, List, `, 
			{
				unitName := Trim(A_LoopField, "`n`, `t")
				if unitName not in %checkList%
				{
					A_AutoGroup[ControlGroup] .= aUnitID[unitName] ","	;assign the unit ID based on name from iniFile	
					checkList .= unitName ","
				}
			}
			A_AutoGroup[ControlGroup] := RTrim(A_AutoGroup[ControlGroup], ",") 
		}		 
	}
	Return
}

;	Some commands which can come in handy for some functions (obviously have to use within the hotkey command)
; 	#MaxThreadsBuffer on 		- this will buffer a hotkeys own key for 1 second, hence this is more in series - subsequent threads will begin when the previous one finishes
;	#MaxThreadsPerHotkey 3 		- this will allow a simultaneous 'thread' of hotkeys i.e. parallel
;	#MaxThreadsPerHotkey 1 		- 
;	#MaxThreadsBuffer off

; these hotkeys will be blocked and wont be activated if the user presses them while blocked - the keys that make themup will then be sent if it was buffered
; send level doesnt seem to fix this

CreateHotkeys()
{	global
	local unloadAllHotkey
	Hotkeys:	

 	input.pCurrentSendDelay := -1
 	input.pCurrentClickDelay := -1
 	input.pCurrentCharDelay := -1
 	input.pSendPressDuration := -1
 	input.pClickPressDuration := -1


 	EventKeyDelay := -1

	#If, WinActive(GameIdentifier)
	#If, WinActive(GameIdentifier) && isPlaying	
	#If, WinActive(GameIdentifier) && isPlaying && !isChatOpen()
	#If, WinActive(GameIdentifier) && isPlaying && !isMenuOpen()
	#If, WinActive(GameIdentifier) && isPlaying && (!isMenuOpen() || isChatOpen()) 
	;#If, ((aLocalPlayer["Race"] = "Terran" && EnableAutoWorkerTerran) || (aLocalPlayer["Race"] = "Protoss" && EnableAutoWorkerProtoss)) && WinActive(GameIdentifier) && isPlaying && !isMenuOpen() 
	;#If, WinActive(GameIdentifier) && time && !isMenuOpen() && EnableAutoWorker`%LocalPlayerRace`%
	#if isPlaying && WinActive(GameIdentifier) && !isCastingReticleActive() && GeyserStructureHoverCheck(hoveredGeyserUnitIndex)
	#If

	Hotkey, If, WinActive(GameIdentifier)
		if EnableToggleMacroTrainerHotkey
			hotkey, %warning_toggle_key%, mt_pause_resume, on		
		hotkey, *~LButton, g_LbuttonDown, on

	Hotkey, If, WinActive(GameIdentifier) && isPlaying && (!isMenuOpen() || isChatOpen()) 
		if EnablePingMiniMapHotkey
			hotkey, %ping_key%, ping, on									;on used to re-enable hotkeys as were 
	Hotkey, If, WinActive(GameIdentifier) && isPlaying	;turned off during save to allow for swaping of keys
		if LwinDisable
			hotkey, Lwin, g_DoNothing, on
	Hotkey, If, WinActive(GameIdentifier) && isPlaying && !isChatOpen()	
		if EnableWorkerCountSpeechHotkey
			hotkey, %worker_count_local_key%, worker_count, on
		if EnableEnemyWorkerCountSpeechHotkey
			hotkey, %worker_count_enemy_key%, worker_count, on
		if EnableLastAlertPlayBackHotkey
			hotkey, %Playback_Alert_Key%, g_PrevWarning, on
		if EnableHideMiniMapHotkey					
			hotkey, %TempHideMiniMapKey%, g_HideMiniMap, on
		if EnableAdjustOverlaysHotkey	
			hotkey, %AdjustOverlayKey%, Adjust_overlay, on
		if EnableCycleIdentifierHotkey
			hotkey, %ToggleIdentifierKey%, Toggle_Identifier, on
		if EnableToggleMiniMapHotkey
			hotkey, %ToggleMinimapOverlayKey%, Overlay_Toggle, on
		if EnableToggleIncomeOverlayHotkey
			hotkey, %ToggleIncomeOverlayKey%, Overlay_Toggle, on
		if EnableToggleResourcesOverlayHotkey
			hotkey, %ToggleResourcesOverlayKey%, Overlay_Toggle, on
		if EnableToggleArmySizeOverlayHotkey
			hotkey, %ToggleArmySizeOverlayKey%, Overlay_Toggle, on
		if EnableToggleWorkerOverlayHotkey
			hotkey, %ToggleWorkerOverlayKey%, Overlay_Toggle, on
		if EnableToggleUnitPanelOverlayHotkey
			hotkey, %ToggleUnitOverlayKey%, Overlay_Toggle, on
		; hotkey, %CycleOverlayKey%, Overlay_Toggle, on

		if race_reading 
			hotkey, %read_races_key%, find_races, on
		if manual_inject_timer
		{	
			hotkey, %inject_start_key%, inject_start, on
			hotkey, %inject_reset_key%, inject_reset, on
		}	

	; Note: for double reference need to use ` to escape % in current command so that is evaluated when hotkey fires
	; could also do if, % "EasyUnload%LocalPlayerRac%"
	;Hotkey, If, WinActive(GameIdentifier) && !isMenuOpen() && EasyUnload`%LocalPlayerRace`%Enable && time

	autoBuild.createHotkeys(aLocalPlayer.race) ; **This function has a "Hotkey, If"!! But it falls into the below firing condition
	Hotkey, If, WinActive(GameIdentifier) && isPlaying && !isMenuOpen()
		if AutoBuildEnableGUIHotkey
			hotkey, %AutoBuildGUIkey%, AutoBuildGUIkeyPress, on
		if (AutoBuildEnableInteractGUIHotkey && AutoBuildGUIkeyMode = "Toggle")
			hotkey, %AutoBuildInteractGUIKey%, AutoBuildGUIInteractkeyPress, on
		if autoBuildEnablePauseAllHotkey
			hotkey, %AutoBuildPauseAllkey%, autoBuildPauseHotkeyPress, on

		if (InjectTimerAdvancedEnable && aLocalPlayer["Race"] = "Zerg")
		{	
			hotkey,  ~^%InjectTimerAdvancedLarvaKey%, g_InjectTimerAdvanced, on
			hotkey,  ~+%InjectTimerAdvancedLarvaKey%, g_InjectTimerAdvanced, on
			hotkey,  ~^+%InjectTimerAdvancedLarvaKey%, g_InjectTimerAdvanced, on
			hotkey,  ~%InjectTimerAdvancedLarvaKey%, g_InjectTimerAdvanced, on
		}		
		if (aLocalPlayer["Race"] = "Terran" && EasyUnloadTerranEnable)
		|| (aLocalPlayer["Race"] = "Protoss" && EasyUnloadProtossEnable)
		|| (aLocalPlayer["Race"] = "Zerg" && EasyUnloadZergEnable)
			hotkey, %EasyUnloadHotkey%, gEasyUnload, on

		; Converting a send key to a hotkey so need to remove '{' and '}' if present e.g. {F1}
		; sc ability hotkeys can only be 1 key
		if (aLocalPlayer["Race"] = "Terran" && EasyUnloadAllTerranEnable)
			hotkey, % "~" (SubStr(EasyUnload_T_Key, 1 , 1) != "{" ? EasyUnload_T_Key : SubStr(EasyUnload_T_Key, 2, StrLen(EasyUnload_T_Key)-2)), UnloadAllTransports, on
		else if (aLocalPlayer["Race"] = "Protoss" && EasyUnloadAllProtossEnable)
			hotkey, % "~" (SubStr(EasyUnload_P_Key, 1 , 1) != "{" ? EasyUnload_P_Key : SubStr(EasyUnload_P_Key, 2, StrLen(EasyUnload_P_Key)-2)), UnloadAllTransports, on
		else if (aLocalPlayer["Race"] = "Zerg" && EasyUnloadAllZergEnable)
			hotkey, % "~" (SubStr(EasyUnload_Z_Key, 1 , 1) != "{" ? EasyUnload_Z_Key : SubStr(EasyUnload_Z_Key, 2, StrLen(EasyUnload_Z_Key)-2)), UnloadAllTransports, on
		
		if SelectArmyEnable
			hotkey, %castSelectArmy_key%, g_SelectArmy, on  ; buffer to make double tap better remove 50ms delay
		if SplitUnitsEnable
			hotkey, %castSplitUnit_key%, g_SplitUnits, on	
		if RemoveUnitEnable
			hotkey, %castRemoveUnit_key%, g_DeselectUnit, on		
		if RemoveDamagedUnitsEnable
			hotkey, %castRemoveDamagedUnits_key%, gRemoveDamagedUnit, on	
		if (aLocalPlayer["Race"] = "Protoss")
		{
			for i, object in aAutoChrono["Items"]
			{
				if ((object.enabled || object.selectionEnabled) && object.Units.MaxIndex())
					try hotkey, % object.hotkey, Cast_ChronoStructure, on	
			}
		}
		while (10 > group := A_index - 1)
		{
			if A_UnitGroupSettings["LimitGroup", aLocalPlayer["Race"], group, "Enabled"] 
			{
				
				try hotkey, % aAGHotkeys.Add[group], g_LimitGrouping, on
				try hotkey, % aAGHotkeys.Set[group], g_LimitGrouping, on
				;hotkey, ^+%i%, g_LimitGrouping, on
			}
		}
		; Have this after the limit grouping so quick select
		; will override any duplicates
		if aQuickSelect[aLocalPlayer["Race"]].maxIndex()
		{
			for i, object in aQuickSelect[aLocalPlayer["Race"]]
			{
				if object.enabled ;&& object.Units.MaxIndex() ; You may not want to filter by unit type, so remove this check
					try hotkey, % object.hotkey, g_QuickSelect, on
			}
		}
		hotkey, *~Esc, g_temporarilyDisableAutoProduction, on	; cant use !ischatopen() - as esc will close chat before memory reads value so wont see chat was open

	Hotkey, If, WinActive(GameIdentifier) && isPlaying && !isChatOpen() 	
		if (aLocalPlayer["Race"] = "Zerg") && (auto_inject <> "Disabled")
			hotkey, %cast_inject_key%, cast_inject, on	
		if (aLocalPlayer["Race"] = "Zerg")
			hotkey, %F_InjectOff_Key%, Cast_DisableInject, on	
		if (aLocalPlayer["Race"] = "Terran" || aLocalPlayer["Race"] = "Protoss")
			hotkey, %ToggleAutoWorkerState_Key%, g_UserToggleAutoWorkerState, on	

	Hotkey, If, isPlaying && WinActive(GameIdentifier) && !isCastingReticleActive() && GeyserStructureHoverCheck(hoveredGeyserUnitIndex)
	if SmartGeyserEnable
		hotkey, RButton, g_SmartGeyserControlGroup, on	

	Hotkey, If
	; Note : I have the emergency hotkey here if the user decides to set another hotkey to <#Space, so it cant get changed
	; but i think this could cause issues when the hotkey fails to get rebound somtimes? I dont think this actually happens

; 	Note:	Emergency Restart Hotkey - Something to keep in mind if actually using the REAL BlockInput Command 
;	Certain types of hook hotkeys can still be triggered when BlockInput is on. 
;	Examples include MButton (mouse hook) and LWin & Space
;	 ***(KEYBOARD HOOK WITH EXPLICIT PREFIX RATHER THAN MODIFIERS "$#")***.
;	hence <#Space wont work
	hotkey, %key_EmergencyRestart%, g_EmergencyRestart, B P2147483647
;	BufferInputFast.setEmergencyRestartKey(key_EmergencyRestart, "g_EmergencyRestart", "B P2147483647" ) ;buffers the hotkey and give it the highest possible priority
	Return
}

disableAllHotkeys()
{
	global
	Hotkey, If, WinActive(GameIdentifier)						
		try hotkey, %warning_toggle_key%, off			; 	deactivate the hotkeys
														; 	so they can be updated with their new keys
	Hotkey, If, WinActive(GameIdentifier) && isPlaying && (!isMenuOpen() || isChatOpen()) 
		try Hotkey, %ping_key%, off	 
												; Anything with a try command has an 'if setting is on' section in the
												; create hotkeys section
												; still left the overall try just incase i missed something
												; gives the user a friendlier error
	Hotkey, If, WinActive(GameIdentifier) && isPlaying	
		try hotkey, Lwin, off
	Hotkey, If, WinActive(GameIdentifier) && isPlaying && !isChatOpen()
		try hotkey, %worker_count_local_key%, off
		try hotkey, %worker_count_enemy_key%, off
		try hotkey, %Playback_Alert_Key%, off
		try hotkey, %TempHideMiniMapKey%, off
		try hotkey, %AdjustOverlayKey%, off
		try hotkey, %ToggleIdentifierKey%, off
		try hotkey, %ToggleMinimapOverlayKey%, off
		try hotkey, %ToggleIncomeOverlayKey%, off
		try hotkey, %ToggleResourcesOverlayKey%, off
		try hotkey, %ToggleArmySizeOverlayKey%, off			
		try hotkey, %ToggleWorkerOverlayKey%, off	
		try hotkey, %ToggleUnitOverlayKey%, off						
		; try hotkey, %CycleOverlayKey%, off		
		Try	hotkey, %read_races_key%, off
		try	hotkey, %inject_start_key%, off
		try	hotkey, %inject_reset_key%, off	

	autoBuild.disableHotkeys() ; **This function has a "Hotkey, If"!! But it falls into the below firing condition
	Hotkey, If, WinActive(GameIdentifier) && isPlaying && !isMenuOpen()
		try hotkey, %AutoBuildGUIkey%, off
		try hotkey, %AutoBuildInteractGUIKey%, off
		try hotkey, %AutoBuildPauseAllkey%, off
		try hotkey,  ~^%InjectTimerAdvancedLarvaKey%, off
		try hotkey,  ~+%InjectTimerAdvancedLarvaKey%, off
		try hotkey, ~^+%InjectTimerAdvancedLarvaKey%, off
		try hotkey,  ~%InjectTimerAdvancedLarvaKey%, off
		try hotkey, %EasyUnloadHotkey%, off
		try hotkey, % "~" (SubStr(EasyUnload_T_Key, 1 , 1) != "{" ? EasyUnload_T_Key : SubStr(EasyUnload_T_Key, 2, StrLen(EasyUnload_T_Key)-2)), off
		try hotkey, % "~" (SubStr(EasyUnload_P_Key, 1 , 1) != "{" ? EasyUnload_P_Key : SubStr(EasyUnload_P_Key, 2, StrLen(EasyUnload_P_Key)-2)), off
		try hotkey, % "~" (SubStr(EasyUnload_Z_Key, 1 , 1) != "{" ? EasyUnload_Z_Key : SubStr(EasyUnload_Z_Key, 2, StrLen(EasyUnload_Z_Key)-2)), off
		try hotkey, %castSelectArmy_key%, off
		try hotkey, %castSplitUnit_key%, off
		try hotkey, %castRemoveUnit_key%, off
		try hotkey, %castRemoveDamagedUnits_key%, off
		for i, object in aAutoChrono["Items"]
			try hotkey, % object.hotkey, off
		while (10 > group := A_index - 1)
		{
			try hotkey, % aAGHotkeys.Add[group], off
			try hotkey, % aAGHotkeys.Set[group], off
		}
		loop, parse, l_races, `,
		{
			race := A_LoopField
			for i, object in aQuickSelect[race]
				try hotkey, % object.hotkey, off
		}
	Hotkey, If, WinActive(GameIdentifier) && isPlaying && !isChatOpen()		
		try hotkey, %cast_inject_key%, off
		try hotkey, %F_InjectOff_Key%, off
		try hotkey, %ToggleAutoWorkerState_Key%, off	
	
	Hotkey, If, isPlaying && WinActive(GameIdentifier) && !isCastingReticleActive() && GeyserStructureHoverCheck(hoveredGeyserUnitIndex)
		try hotkey, RButton, off

	Hotkey, If
	; Recreate this key in case user has another fcuntion bound to it and it was turned off above.
	hotkey, %key_EmergencyRestart%, g_EmergencyRestart, B P2147483647
	return 
}

getCamCenteredUnit(UnitList) ; |delimited ** ; needs a minimum of 70+ ms to update cam location
{
	CamX := getPlayerCameraPositionX(), CamY := getPlayerCameraPositionY()
	loop, parse, UnitList, |
	{
		delta := Abs(CamX-getUnitPositionX(A_loopfield)) + Abs(CamY-getUnitPositionY(A_loopfield))
		if (delta < delta_closest || A_index = 1)
		{
			delta_closest := delta
			unit_closest := A_loopfield
		}
	}
	StringReplace, UnitList, UnitList,|%unit_closest%
	if !ErrorLevel ;none found
		StringReplace, UnitList, UnitList,%unit_closest%|	
	return unit_closest
}

castInjectLarva(Method := "Backspace", ForceInject := 0, sleepTime := 80)	;SendWhileBlocked("^" CG_control_group)
{	global
	LOCAL 	click_x, click_y, BaseCount, oSelection, SkipUsedQueen, MissedHatcheries, QueenCount, FoundQueen
			, start_x, start_y
			, QueenMultiInjects, MaxInjects, CurrentQueenInjectCount
			, HatchIndex, Dx1, Dy1, Dx2, Dy2, QueenIndex
			, stopWatchCtrlID, Xpage, Ypage, x, y

	LOCAL HighlightedGroup := getSelectionHighlightedGroup()
	LOCAL selectionPage := getUnitSelectionPage()

	if ForceInject
		sleepTime := 0

	if (Method = "MiniMap" OR ForceInject)
	{
		local xNew, yNew, injectedHatches

		; there could be an issue here with the selection buffer not being updated (should sleep for 10ms)

		oHatcheries := [] ; Global used to check if successful without having to iterate again. And it will update the list of hatches when using fully automated injects (which is checked to determine when to call this function)
		local BaseCount := zergGetHatcheriesToInject(oHatcheries)
		Local oSelection := []
		local MissedHatcheries := []
																		
		; use check the ctrl group, rather than the selection buffer, then wont have to sleep for selection buffer
		; getSelectedQueensWhichCanInject(oSelection, ForceInject)) 
		
		; there is an issue with multi injects causing patrolling queens to inject.
		; its because im not removing patrolling queens from the inject group for an auto inject
		; so while moving between hatches to do a multi inject, this queen will be seen as able to inject so cause 
		; injects to occur by other queens on next run through of the timer.

		If (Local QueenCount := getGroupedQueensWhichCanInject(oSelection, ForceInject)) ; this wont fetch burrowed queens!! so dont have to do a check below - as burrowed queens can make cameramove when clicking their hatch
		{
			if (ForceInject || Inject_RestoreSelection)
				input.pSend(aAGHotkeys.set[Inject_control_group]), stopWatchCtrlID := stopwatch()
			input.pSend(aAGHotkeys.Invoke[MI_Queen_Group])
			dsleep(20)

			if ForceInject
			{
				local lRemoveQueens, removedCount := 0
				; some queens shouldnt inject and this deselects them from the selection panel
				; this will remove queens which are patrolling or laying a tumour or doing other things
				; as since they are in the ctrl group if they are closer than a queen who should be doing the inject
				; then they will do the inject instead!

				if (oSelection.Queens.MaxIndex() != oSelection.AllQueens.MaxIndex())
				{
					for index, groupedQueens in oSelection.AllQueens
					{
						local flag := False
						for index, injectingQueens in oSelection.Queens
						{
							if (groupedQueens.unit = injectingQueens.unit)
							{
								flag := True
								break 
							}
						}
						if !flag
							lRemoveQueens .= groupedQueens.unit ",", removedCount++	
					}
					if (lRemoveQueens := SubStr(lRemoveQueens, 1, -1))
					{
						local selectionCount := getSelectionCount()
						ClickSelectUnitsPortriat(lRemoveQueens, "+")
						clickSelectionPage(1)
						while (getSelectionCount() != selectionCount - removedCount && A_Index <= 20)
							dSleep(1)
						dsleep(5)
					}
				}
			}

			For Index, CurrentHatch in oHatcheries
			{
				Local FoundQueen := 0
				if CurrentHatch.isInjected || (InjectConserveQueenEnergy && CurrentHatch.LarvaCount >= 19) 
					continue
				For Index, Queen in oSelection.Queens
				{
					if Queen.HasInjected 
						continue
						; Just looking through the code now... dont know why isInControlGroup and Queen energy are checked
					; They should be always true...., perhaps a copy and paste from old code which used a different method
					if (isQueenNearHatch(Queen, CurrentHatch, MI_QueenDistance) && Queen.Energy >= 25) ; previously queen type here (unit id/tpye) doesnt seem to work! weird
					{
						FoundQueen := CurrentHatch.NearbyQueen := Queen.HasInjected := 1 																		
						input.pSend(Inject_spawn_larva)
						click_x := CurrentHatch.MiniMapX, click_y := CurrentHatch.MiniMapY
						If HumanMouse
							MouseMoveHumanSC2("x" click_x "y" click_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
						Input.pClick(click_x, click_y)
						if sleepTime
							sleep % ceil(sleepTime * rand(1, Inject_SleepVariance)) ; eg rand(1, 1.XXXX) as the second parameter will always have a decimal point, dont have to worry about it returning just full integers eg 1 or 2 or 3
						Queen.Energy -= 25	
						injectedHatches++
						if (ForceInject && injectedHatches >= FInjectHatchMaxHatches)
							break, 2
						Break
					}
					else CurrentHatch.NearbyQueen := 0
				}
				if !FoundQueen
					MissedHatcheries.insert(CurrentHatch)
			}
		;	/* ; THIS Is trying to do multi injects 
			; just realised that can only do one multi inject per inject round
			; i.e. one queen can inject multiple hatcheries 
			; Could do more using the {click 0, 0} trick
			if (MissedHatcheries.maxindex() && CanQueenMultiInject)
			{
				local QueenMultiInjects := []
				For Index, Queen in oSelection.Queens
				{
					For Index, CurrentHatch in MissedHatcheries 
					{
						if (ForceInject && injectedHatches >= FInjectHatchMaxHatches)
							break, 2							
						if isQueenNearHatch(Queen, CurrentHatch, MI_QueenDistance) && Queen.Energy >= 25
						{
							if !isobject(QueenMultiInjects[Queen.unit])
								QueenMultiInjects[Queen.unit] := []
							QueenMultiInjects[Queen.unit].insert(CurrentHatch)
							Queen.Energy -= 25
							injectedHatches++
						}
						if Queen.Energy < 25
							break
					}
				}

				For QueenIndex, QueenObject in QueenMultiInjects
				{
					for index, CurrentHatch in QueenObject
					{
						if (index = QueenObject.MinIndex())
						{
							ClickSelectUnitsPortriat(QueenIndex) 
							while (getSelectionCount() != 1 && A_Index <= 15)
								dSleep(1) 
							dSleep(2) 
						}
						input.pSend(Inject_spawn_larva) ;always need to send this, otherwise might left click minimap for somereason
						click_x := CurrentHatch.MiniMapX, click_y := CurrentHatch.MiniMapY
						If HumanMouse
							MouseMoveHumanSC2("x" click_x "y" click_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
					;	MTclick(click_x, click_y, "Left", "+")
						input.psend("+{click " click_x ", " click_y "}")
						if sleepTime
							sleep % ceil(sleepTime * rand(1, Inject_SleepVariance))

						if (index = QueenObject.maxIndex())
						{
							break, 2
							; cant do multi inject on more than one hatch as sending the queen ctrl group key
							; more than 1 within a second (even after other buttons) will cause the camera to jump/focus
							; on the queens
							; could send another ctrl group then the queen group key or the {click 0, 0}

							;input.pSend(MI_Queen_Group)
							;dSleep(8) 
						}				
					}
				}					
			}
		}
		else return ; no queens in control group - no actions were take
	}	
	else if ((Method = "Backspace Adv") || (Method = "Backspace CtrlGroup")) ; I.E. I have disabled this feature until i get around to finding the centred hatch better ((Method="Backspace Adv") || (Method = "Backspace CtrlGroup")) ;cos i changed the name in an update
	{		; this is really just the minimap method made to look like the backspace

		oHatcheries := [] ; Global used to check if successfuly without having to iterate again
		local BaseCount := zergGetHatcheriesToInject(oHatcheries)
		Local oSelection := []
		Local SkipUsedQueen := []
		local MissedHatcheries := []

	    For Index, CurrentHatch in oHatcheries 	; so (for the most part) the inject order should match the basecamera order - though there are more rules than just age
	    	CurrentHatch.Age := getUnitTimer(CurrentHatch.unit)
	    bubbleSort2DArray(oHatcheries, "Age", 0) ; 0 = descending
	    Local QueenCount
	    Local FoundQueen
		If QueenCount := getGroupedQueensWhichCanInject(oSelection)  ; this wont fetch burrowed queens!! so dont have to do a check below - as burrowed queens can make cameramove when clicking their hatch
		{
			if Inject_RestoreSelection
				input.pSend(aAGHotkeys.set[Inject_control_group]), stopWatchCtrlID := stopwatch()
			if Inject_RestoreScreenLocation
				input.pSend(BI_create_camera_pos_x)
			input.pSend(aAGHotkeys.Invoke[MI_Queen_Group])
			For Index, CurrentHatch in oHatcheries
			{
				if sleepTime
					sleep % ceil( (sleepTime/2) * rand(1, Inject_SleepVariance)) 
		;		send {click Left %click_x%, %click_y%}
				Input.pClick(CurrentHatch.MiniMapX, CurrentHatch.MiniMapY)
				if sleepTime
					sleep % ceil( (sleepTime/2) * rand(1, Inject_SleepVariance))
				if CurrentHatch.isInjected || (InjectConserveQueenEnergy && CurrentHatch.LarvaCount >= 19) 
					continue
				For Index, Queen in oSelection.Queens
				{
					if isQueenNearHatch(Queen, CurrentHatch, MI_QueenDistance)
					{
						CurrentHatch.NearbyQueen := 1 																		
						input.pSend(Inject_spawn_larva)
						Input.pClick(CurrentHatch.MiniMapX, CurrentHatch.MiniMapY)
						oSelection.Queens.Remove(Index) ; this queen wont inject again
						Break
					}
					else CurrentHatch.NearbyQueen := 0
				}
			}
			if Inject_RestoreScreenLocation
			{
				sleep % ceil( (sleepTime/1.5) * rand(1, Inject_SleepVariance)) ; so this will actually mean the inject will sleep longer than user specified, but make it look a bit more real
				input.pSend(BI_camera_pos_x) 										
			}
		}
		else return ; no queens
	}
	else ; if (Method="Backspace")
	{

		; 	Note: When a queen has inadequate energy for an inject, after pressing the inject larvae key nothing will actually happen 
		;	so the subsequent left click on the hatch will actually select the hatch (as the spell wasn't cast)
		;	this was what part of the reason queens were sometimes being cancelled
		if Inject_RestoreSelection
			input.pSend(aAGHotkeys.set[Inject_control_group]), stopWatchCtrlID := stopwatch()

		HatchIndex := getBuildingList(aUnitID["Hatchery"], aUnitID["Lair"], aUnitID["Hive"])
		if Inject_RestoreScreenLocation
			input.pSend(BI_create_camera_pos_x)
		If (drag_origin = "Right" OR drag_origin = "R") And !HumanMouse ;so left origin - not case sensitive
			Dx1 := A_ScreenWidth-25, Dy1 := 45, Dx2 := 35, Dy2 := A_ScreenHeight-240	
		Else ;left origin
			Dx1 := 25, Dy1 := 25, Dx2 := A_ScreenWidth-40, Dy2 := A_ScreenHeight-240
		loop, % getPlayerBaseCameraCount()	
		{
			input.pSend(base_camera)
			sleep % ceil( (sleepTime/2) * rand(1, Inject_SleepVariance))	;need a sleep somerwhere around here to prevent walkabouts...sc2 not registerings box drag?
			if isCastingReticleActive() ; i.e. cast larva
				input.pSend(Escape) ; (deselects queen larva) (useful on an already injected hatch) this is actually a variable
			If (drag_origin = "Right" OR drag_origin = "R") And HumanMouse ;so left origin - not case sensitive
				Dx1 := A_ScreenWidth-15-rand(0,(360/1920)*A_ScreenWidth), Dy1 := 45+rand(5,(200/1080)*A_ScreenHeight), Dx2 := 40+rand((-5/1920)*A_ScreenWidth,(300/1920)*A_ScreenWidth), Dy2 := A_ScreenHeight-240-rand((-5/1080)*A_ScreenHeight,(140/1080)*A_ScreenHeight)
			Else If (drag_origin = "Left" OR drag_origin = "L") AND HumanMouse ;left origin
				Dx1 := 25+rand((0/1920)*A_ScreenWidth,(360/1920)*A_ScreenWidth), Dy1 := 25+rand((-5/1080)*A_ScreenHeight,(200/1080)*A_ScreenHeight), Dx2 := A_ScreenWidth-40-rand((-5/1920)*A_ScreenWidth,(300/1920)*A_ScreenWidth), Dy2 := A_ScreenHeight-240-rand((-5/1080)*A_ScreenHeight,(140/1080)*A_ScreenHeight)					
			If HumanMouse
			{
				MouseMoveHumanSC2("x" Dx1 "y" Dy1 "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
				input.pSend("{click down}")
				MouseMoveHumanSC2("x" Dx2 "y" Dy2 "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
				input.pSend("{click up}")
			}
			Else 
				input.pSend("{click D " Dx1 " " Dy1 "}{Click U " Dx2 " " Dy2 "}")
			sleep % ceil( (sleepTime/2) * rand(1, Inject_SleepVariance))
			if (QueenIndex := filterSlectionTypeByEnergy(25, aUnitID["Queen"]))
			{																	
				input.pSend(Inject_spawn_larva)							;have to think about macro hatch though
				click_x := A_ScreenWidth/2 , click_y := A_ScreenHeight/2		;due to not using Shift - must have 2 queens if on same screen
																				;as will inject only 1 (as it will go to 1 hatch, then get the order to go the other before injecting the 1s)
				If HumanMouse
				{	click_x += rand((-75/1920)*A_ScreenWidth,(75/1080)*A_ScreenHeight), click_y -= 100+rand((-75/1920)*A_ScreenWidth,(75/1080)*A_ScreenHeight)
					MouseMoveHumanSC2("x" click_x  "y" click_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
					input.pSend("{click Left " click_x ", " click_y "}")
				}
				Else Input.pClick(click_x, click_y)
			}
		}	
		if Inject_RestoreScreenLocation
		{
			sleep % ceil( (sleepTime/2) * rand(1, Inject_SleepVariance))	; so this will actually mean the inject will sleep longer than user specified, but make it look a bit more real
			input.pSend(BI_camera_pos_x)										
		}
	}
	if (ForceInject || Inject_RestoreSelection)
	{
		elapsedTimeGrouping := stopwatch(stopWatchCtrlID)	
		if (elapsedTimeGrouping < 20)
			dSleep(ceil(20 - elapsedTimeGrouping))
		restoreSelection(Inject_control_group, selectionPage, HighlightedGroup)
	}
	return
}

/*
f1::
sleep 500
input.pSend("{tab}{Tab}")
dsleep(2)
ClickUnitPortrait(0, X, Y, Xpage, Ypage, 1 + 1) ; for this function numbers start at 1, hence +1
input.pClick(Xpage, Ypage)
return
f2::
sleep 500
input.psend(6)
dsleep(15)
restoreSelection(7, 3)
return 
*/

; This function is designed to restore the unit selection and selection window exactly as it was
; prior to an automation i.e. selected units, selection page, and tab (sub group) position.

; The page cannot be changed until the tab position has been changed (otherwise the tabs are ignored)
; When changing between selections/groups the page position will remain the same, unless there are not
; enough pages in the new selection - then it will be left of the highest page.
; The Tab/subgroup is always reset to the first (0) when changing selections.

restoreSelection(controlGroup, selectionPage, highlightedTab)
{ 
	global NextSubgroupKey

	input.pSend(aAGHotkeys.Invoke[controlGroup])
	dsleep(15) ; This might not be long enough in big battles/large control group
	if (highlightedTab && highlightedTab < getSelectionTypeCount())	; highlightedTab is zero based - TypeCount is 1 based hence < not <=
	{
		input.pSend(sRepeat(NextSubgroupKey, highlightedTab))
		; Although unlikely due to speed of automation, it is possible for a unit to die and for there to be 1 less
		; sub group now present, hence if trying to access the previously highest (and now now non existent) subgroup 
		; this could stall here. Perhaps have a look for a max subgroup pos
		while (getSelectionHighlightedGroup() != highlightedTab && A_Index < 40) ; Raised from 25
			dsleep(1)
		dsleep(4) ; This static sleep wasn't required during testing but i added it anyway. (as i didn't do in-depth testing)	
	}	
	; There's no point checking if the selection page still exists - if it doesn't the click
	; will be ignored anyway
	if selectionPage 
	{
		ClickUnitPortrait(0, X, Y, Xpage, Ypage, selectionPage + 1) ; for this function numbers start at 1, hence +1
		input.pClick(Xpage, Ypage)
	}
	return	
}

; Always return all hatches/lairs/hives. As this is used to monitor all of them until in the fully auto-injects, the function is called again.
 zergGetHatcheriesToInject(byref Object)
 { 	global aUnitID, InjectConserveQueenEnergy
 	Object := [], MT_CurrentGame.LastHatchCheckTick := A_TickCount
 	loop, % DumpUnitMemory(MemDump)
 	{
 		unit := A_Index - 1
 		if isTargetDead(TargetFilter := numgetUnitTargetFilter(MemDump, unit)) || !isOwnerLocal(numgetUnitOwner(MemDump, Unit)) || isTargetUnderConstruction(TargetFilter) 
	       Continue
	    pUnitModel := numgetUnitModelPointer(MemDump, Unit)
	    Type := numgetUnitModelType(pUnitModel)
	
		IF (type = aUnitID["Hatchery"] || type = aUnitID["Lair"] || type = aUnitID["Hive"])
		{
			MiniMapX := x := numGetUnitPositionX(MemDump, Unit)
			MiniMapY := y := numGetUnitPositionY(MemDump, Unit)
			z :=  numGetUnitPositionZ(MemDump, Unit)
			mapToMinimapPos(MiniMapX, MiniMapY)
			isInjected := numGetIsHatchInjectedFromMemDump(MemDump, Unit)
			Object.insert( {  "Unit": unit 
							, "x": x
							, "y": y
							, "z": z
							, "MiniMapX": MiniMapX
							, "MiniMapY": MiniMapY
							, "isInjected": isInjected
							, "LarvaCount": round(getTownHallLarvaCount(unit)) } ) ; Rounding isn't necessary as I believe this function should always work
		}		
 	}
 	return Object.maxindex()
 }

g_SplitUnits:
;	input.hookBlock(True, True)
;	sleep := Input.releaseKeys()
;	critical, 1000
;	input.hookBlock(False, False)
;	if sleep
;		dSleep(15) ;
	critical, 1000
	setLowLevelInputHooks(True)
	dSleep(20)
	input.pReleaseKeys()
	SplitUnits(SplitctrlgroupStorage_key)
	setLowLevelInputHooks(False)
return


; 	22/9/13 
;	Using a hookblock doesn't increase robustness when user is constantly holding down the hotkey
;	But this isn't a real issue anyway (and it works well even if they are)


; Testing sleep after selecting army:
/*
for a 146 terran army deslecting all but 1 unit

 10ms - 1 in ~7 times most of the units weren't deselected
 15ms - worked 100%
*/

g_SelectArmy:
selectArmy()
return 

selectArmy()
{
	global 
	if !getArmyUnitCount()
		return 
	;while (GetKeyState("Lbutton", "P") || GetKeyState("Rbutton", "P"))
	; removed loop as this could cause the last key in the hotkey to get stuck
	; don't know if this will affect reliability (as releasing mouse via pSend)
	; so i will increase the sleep if mouse down from 15
;	if (GetKeyState("Lbutton", "P") || GetKeyState("Rbutton", "P"))
;	{
;		sleep 1 
;		MouseDown := True
;	}
	critical, 1000
	setLowLevelInputHooks(True)
	dsleep(30)
	input.pReleaseKeys(True)
	sleep := 0

;	if MouseDown
	if (GetKeyState("Lbutton", "P") || GetKeyState("Rbutton", "P"))
		dSleep(30) 		; dSleep(15)
	if isCastingReticleActive() 	; so can deselect units if attacking reticle was present
		input.pSend(Escape) 		; is a dsleep() >= 15 is performed after select army key is pressed this is not required - 12isnt enough
									; as SC will have enough time to get rid of the selection reticle itself
	
	; If i use the box drag method, then I will need to also remove workers and any allied units (left/shared control)
	If SelectArmyOnScreen
	{
		input.pSend("{click D " 0 " " 0 "}{Click U " A_ScreenWidth " "  A_ScreenHeight "}") ;  A_ScreenHeight-240 "}")
		dSleep(80) 
	}
	else if (getArmyUnitCount() != getSelectionCount())
	{
		input.pSend(Sc2SelectArmy_Key)
		timerArmyID := stopwatch()
		; waits for selection count to match army count 
		; times out after 50 ms - small static sleep afterwards
		; A_Index check is just in case stopwatch fails (it should work on every computer) - get stuck in infinite loop with input blocked
		while (getSelectionCount() != getArmyUnitCount() && stopwatch(timerArmyID, False) < 70 && A_Index < 80)
			dsleep(1)
		dsleep(20)
	} 
	else 
	{
		input.pSend(Sc2SelectArmy_Key)
		dSleep(40) 
	}

	aUnitPortraitLocations := []
	aUnitPortraitLocations := findPortraitsToRemoveFromArmy("", SelectArmyDeselectXelnaga, SelectArmyDeselectPatrolling
									, SelectArmyDeselectHoldPosition, SelectArmyDeselectFollowing, SelectArmyDeselectLoadedTransport 
									, SelectArmyDeselectQueuedDrops, l_ActiveDeselectArmy, SelectArmyOnScreen)
	clickUnitPortraits(aUnitPortraitLocations)
	clickSelectionPage(1)
	dSleep(15)
	if (Sc2SelectArmyCtrlGroup != "Off")
		input.pSend(aAGHotkeys.set[Sc2SelectArmyCtrlGroup])
	dSleep(15)
	if (timerArmyID && stopwatch(timerArmyID) > 35) ; remove the timer and if took long time to select units sleep for longer
		dSleep(15) 									; as every now and again all units can get grouped with previous button press
													; though an increase sleep might be needed before the above grouping command
	
	Input.revertKeyState()
	setLowLevelInputHooks(False)
	critical, off
	Thread, Priority, -2147483648
	sleep, -1
	sleep 20
	return	
}
	; sleep, -1 ensures LL callbacks get processed 
	; without the postive value sleep, its possible to make the input lag/beep
	; after holding down the hotkey for a while and clicking lots perhaps not enough time
	; to process command call backs in the LL hooks before the next hotkey fires? but that doesn't seem right

	; 	Update:
	;	Adding a sleep at the end of the command increases reliability. It prevents the user slowing down SC
	; 	by allowing a small sleep even if the function is constantly repeating (user holding button)
	;	Also seems to give time for any input to clear so reduces chance of interrupting automation
	;	on next loop through 20ms was enough for 146 army

return 

g_QuickSelect:
item := ""
for index, object in aQuickSelect[aLocalPlayer.Race]
{
	if ("" object.hotkey = A_ThisHotkey && object.enabled) ; concatenating literal string forces comparison as strings, else 1 = +1 (shift + 1)
	{
		item := index
		break
	}
}
if (item != "") ; item should never be blank but im just leaving it like this just in case as i cant be bothered checking
	quickSelect(aQuickSelect[aLocalPlayer.Race, item])
return 

;  the ctrl+shift click remove entire group is disabled until i fix the sort with units in same tab eg tanks/stanks + hellions/hellbats
; could use a list of exceptions for the this click, but can't be bothered atm
quickSelect(aDeselect)
{
	global Sc2SelectArmy_Key, aAGHotkeys, Escape
	static getUnitPercentHPReference := Func("getUnitPercentHP"), getUnitPercentShieldReference := Func("getUnitPercentShield")

	if aDeselect.BaseSelection = "Army" && !getArmyUnitCount()
		return 
	while (GetKeyState("Lbutton", "P") || GetKeyState("Rbutton", "P"))
	{
		sleep 1
		MouseDown := True
	}
	critical, 1000
	setLowLevelInputHooks(True)
	dsleep(30)

	input.pReleaseKeys(True)
	if MouseDown
		dSleep(15)

	aLookup := []
	for i, clickUnitType in aDeselect["Units"]
		aLookup[clickUnitType] := True

	; This checks if one of the click unit types exist on the map
	; Otherwise user presses hotkey and is left with all the army unit selection
	; since when selecting unit types were are actually just removing all other types - selection will be left blank, which
	; in most situations is probably worse
	; This is a more complicated now by allowing army, on screen, and control groups
	; theres no protection fro control groups
	if aDeselect.BaseSelection = "Army" && !getArmyUnitCount()
		goto __quickSelectFunctionRemoveHooksExit

	if aDeselect.SelectUnitTypes ; 
	{	
		unitTypesDoesntExist := True
		if aDeselect.BaseSelection = "Current Selection"
		{
			numGetUnitSelectionObject(aSelection)
			for i, unit in aSelection
			{
				if aLookup.hasKey(unit.type)
				{
		    		unitTypesDoesntExist := False
		    		break
		    	}
			}
		}
		else loop, % DumpUnitMemory(MemDump)
		{	
		    if !(numgetUnitTargetFilter(MemDump, unit := A_Index - 1) & DeadFilterFlag) && numgetUnitOwner(MemDump, Unit) = aLocalPlayer["Slot"]
		    && aLookup.hasKey(numgetUnitModelType(numgetUnitModelPointer(MemDump, Unit)))
		    {
		    	unitTypesDoesntExist := False
		    	break
		    }
		}
	}
	if unitTypesDoesntExist
		goto __quickSelectFunctionRemoveHooksExit

	if isCastingReticleActive() 	; so can deselect units if attacking/drop/rally reticle was present
		input.pSend(Escape) 		; in ideal conditions a dsleep() >= 15 is performed after select army key is pressed this is not required - 12isnt enough
									; as SC will have enough time to get rid of the selection reticle itself
	if aDeselect.BaseSelection != "Current Selection"
	{
		if aDeselect.BaseSelection = "Units On Screen"
		{	
			; If reticle was present, no delay is needed between sending escape and box dragging. 
			; Tested by lowering CPU speed to 1.6G Hz and running linx with this function 					
			input.pSend("{click D " 0 " " 0 "}{Click U " A_ScreenWidth " "  A_ScreenHeight "}") ;  A_ScreenHeight-240 "}")
			dSleep(80) 		
		}
		else if instr(aDeselect.BaseSelection, "Control Group")
		{
			controlGroup := Substr(aDeselect.BaseSelection, 0) ; substr() extract last character which is the control group number 0-9
			portraitCount := getControlGroupPortraitCount(controlGroup)
			if !portraitCount
				goto __quickSelectFunctionRemoveHooksExit
			if getSelectionCount() != portraitCount
			{
				input.pSend(aAGHotkeys.Invoke[controlGroup]) 
				timerQuickID := stopwatch()
				while getSelectionCount() != portraitCount && stopwatch(timerQuickID, False) < 60 && A_Index < 80
					dsleep(1)
				stopwatch(timerQuickID)
				dsleep(20)				
			}
			else 
			{
				input.pSend(aAGHotkeys.Invoke[controlGroup]) 
				dSleep(40) 	
			}
		}
		else ;if aDeselect.BaseSelection = "Army" ; Use as blank else 
		{					
			if (getArmyUnitCount() != getSelectionCount())
			{
				input.pSend(Sc2SelectArmy_Key)
				timerQuickID := stopwatch()
				; waits for selection count to match army count 
				; times out after 50 ms - small static sleep afterwards
				; A_Index check is just in case stopwatch fails (it should work on every computer) - get stuck in infinite loop with input blocked
				while (getSelectionCount() != getArmyUnitCount() && stopwatch(timerQuickID, False) < 70 && A_Index < 80)
					dsleep(1)
				stopwatch(timerQuickID)
				dsleep(20)
			} 
			else  
			{
				input.pSend(Sc2SelectArmy_Key)
				dSleep(40) 
			}
		}
	}
	; if on control-group/current selection  remove any structures. 
	; Note if you box drag some units and structures at the same time - only units are selected
	; however if you *Shift* box drag again (and don't select any currently unselected units) the structures will be selected.
	; And overlords as zerg transports 
	; and fix GUI warning when no unit types selected

	numGetSelectionSorted(aSelected)
	clickPortraits := []

	if (aDeselect.DeselectXelnaga || aDeselect.DeselectPatrolling || aDeselect.DeselectHoldPosition || aDeselect.DeselectFollowing
	|| aDeselect.DeselectIdle || aDeselect.DeselectLoadedTransport  || aDeselect.DeselectEmptyTransport|| aDeselect.DeselectQueuedDrops
	|| aDeselect.DeselectAttacking ||  aDeselect.DeselectLowHP || (aDeselect.DeselectHallucinations && aLocalPlayer["Race"] = "Protoss"))
		checkStates := True, healthFunc := aLocalPlayer["Race"] = "Protoss" ? getUnitPercentShieldReference : getUnitPercentHPReference ; faster than checking targ filter for has shield on each unit
		, checkTransportAttributes := (aDeselect.DeselectLoadedTransport || aDeselect.DeselectEmptyTransport || aDeselect.DeselectQueuedDrops)
		, checkHallucinations := (aDeselect.DeselectHallucinations && aLocalPlayer["Race"] = "Protoss")
	
	removeByAttribute := (aDeselect.AttributeMode != "Keep")

	removeStructures := (instr(aDeselect.BaseSelection, "Control") || aDeselect.BaseSelection = "Current Selection" )
	; Could also add gameType != 1v1
	removeAllied := (removeStructures || aDeselect.BaseSelection = "Units On Screen")

	; this is disabled until i fix the sort with units in same tab eg tanks/stanks + hellions/hellbats
	; And also need to consider the consequence of hallucinations and the issues with tabSize/position in numgetSelectionSorted()
	if 0 && (aDeselect.Units.MaxIndex() = 1 && !checkStates) 
	{
		clickUnitType := aDeselect["Units", 1]
		if aSelected.TabPositions.HasKey(clickUnitType)
		{
			for i, unit in aSelected.units
			{
				if (unit.unitId = clickUnitType) 
				{
					clickPortraits.insert(unit.unitPortrait)
					break
				}
			}
			clickUnitPortraits(clickPortraits, "^")
		}
	}
	else 
	{
		for i, unit in aSelected.units
		{
			;if (unit.unitId = prevID) 
			;	continue 
			;if (aDeselect.SelectUnitTypes && !aLookup.haskey(unit.unitId))
			;|| (aDeselect.DeselectUnitTypes && aLookup.haskey(unit.unitId)) 
			;{ 
			;	prevID := unit.unitId 	; this is disabled until i fix the sort with units in same tab eg tanks/stanks + hellions/hellbats ; And also need to consider the consequence of hallucinations and the issues with tabSize/position in numgetSelectionSorted()
			;	clickPortraits.insert({ "portrait":  unit.unitPortrait, "modifiers": "^+"})
			;	clickPortraits.insert({ "portrait":  unit.unitPortrait, "modifiers": "+"}) 
			;}
			if (aDeselect.SelectUnitTypes && !aLookup.haskey(unit.unitId))
			|| (aDeselect.DeselectUnitTypes && aLookup.haskey(unit.unitId)) 
			|| (removeStructures && unit.TargetFilter & aUnitTargetFilter.Structure)
			|| (removeAllied && getUnitOwner(unit.unitIndex) != aLocalPlayer["Slot"])
				clickPortraits.insert( {"portrait":  unit.unitPortrait, "modifiers": "+"}) 
			else if checkStates
			{
				commandString := getUnitQueuedCommandString(unit.unitIndex)
				if (aDeselect.DeselectXelnaga && isLocalUnitHoldingXelnaga(unit.unitIndex))
				|| (aDeselect.DeselectPatrolling && InStr(commandString, "Patrol"))
				|| (aDeselect.DeselectHoldPosition && InStr(commandString, "Hold"))
				|| (aDeselect.DeselectAttacking && (InStr(commandString, "Attack") || InStr(commandString, "FNA"))) 
				|| (aDeselect.DeselectFollowing && InStr(commandString, "Follow")) 
				|| (aDeselect.DeselectIdle && commandString = "")
				|| (aDeselect.DeselectLowHP && healthFunc.(unit.unitIndex) <  aDeselect.HPValue / 100) ; divide by 100 as it's not saved as a decimal ; Since aSelected now contains the units targFilter, could just check if has shields to determine which func to call
				|| (checkHallucinations && unit.TargetFilter & aUnitTargetFilter.Hallucination)
				|| 	(	checkTransportAttributes
						&& (unit.unitId = aUnitId.Medivac || unit.unitId = aUnitID.WarpPrism || unit.unitId = aUnitID.WarpPrismPhasing) ; !removeByAttribute - if keeping 
						&& (	(aDeselect.DeselectLoadedTransport && getCargoCount(unit.unitIndex))
								|| (aDeselect.DeselectEmptyTransport && !getCargoCount(unit.unitIndex))
								|| (aDeselect.DeselectQueuedDrops && isTransportDropQueued(unit.unitIndex))))
				{
					if removeByAttribute
						clickPortraits.insert({ "portrait":  unit.unitPortrait, "modifiers": "+"}) 
					;else continue ; We wish to keep it. (the else if!removeByAttribute means we don't have to continue here) Due to function changes the attribute is labelled  deselect even though we are keeping them
				}
				else if !removeByAttribute ; keeping units which have the above attributes - so remove any which do not have at least one
					clickPortraits.insert({ "portrait":  unit.unitPortrait, "modifiers": "+"}) 
			}
			;	selectedCount += aSelected.TabSizes[unit.unitId]
		}
		; reversing the array here (rather than via numgetselection function) allows the clicks to occur on the
		; lowest portraits i.e. on the left side of a selection group

		if clickPortraits.MaxIndex()
			reverseArray(clickPortraits), clickUnitPortraitsWithModifiers(clickPortraits)
		clickSelectionPage(1)	; unconditionally click page 1. If only one unit is left selected, this will cause the unit info (move/attack speed) box to briefly appear
	}
	if aDeselect.CreateControlGroup
		input.pSend(aAGHotkeys.Set[aDeselect.StoreSelection])
	else if aDeselect.AddToControlGroup
		input.pSend(aAGHotkeys.Add[aDeselect.StoreSelection])
	dsleep(15)

	__quickSelectFunctionRemoveHooksExit:	
	input.RevertKeyState()
	setLowLevelInputHooks(False)
	critical, off 
	sleep, -1
	Thread, Priority, -2147483648
	sleep, 20
	return
}

; aSelected can be used to pass an already SORTED selected array
; if no array, or an empty array is passed then it will retrieve one
; The first unit to be removed will have the highest unit panel position

findUnitsToRemoveFromArmy(byref aSelected := "", DeselectXelnaga = 1, DeselectPatrolling = 1, DeselectHoldPosition = 0, DeselectFollowing = 0, lTypes = "")
{ 	global aUnitMoveStates
	if (!isObject(aSelected) || !aSelected.units.maxIndex())
		numGetSelectionSorted(aSelected) ; get a sorted array of the selection buffer
	remove := []
	for i, unit in aSelected.units
	{
		state := getUnitMoveState(unit.unitIndex)
		if (DeselectXelnaga && isLocalUnitHoldingXelnaga(unit.unitIndex))
			|| (DeselectPatrolling && state = aUnitMoveStates.Patrol)
			|| (DeselectHoldPosition && state = aUnitMoveStates.HoldPosition)
			|| (DeselectFollowing && (state = aUnitMoveStates.Follow || state = aUnitMoveStates.FollowNoAttack)) ;no attack follow is used by spell casters e.g. HTs & infests which dont have and attack
				remove.insert(unit.unitIndex)
		else if lTypes  
		{
			type := unit.unitId
			If type in %lTypes%
				remove.insert(unit.unitIndex)
		}			
	}
	; so unit click loctions are in descending order 
	reverseArray(remove)
	return remove
}

; returns a simple array with the exact unit portrait location to be clicked
; as used by ClickUnitPortrait
; The highest portrait locations come first
; This only take 3 or 4 ms with heaps of units selected
findPortraitsToRemoveFromArmy(byref aSelected := "", DeselectXelnaga = 1, DeselectPatrolling = 1 
								, DeselectHoldPosition = 0, DeselectFollowing = 0, DeselectLoadedTransport = 0 
								, DeselectQueuedDrops = 0, lTypes = "", removeAllied := 0)
{ 	
	global aUnitMoveStates
	if (!isObject(aSelected) || !aSelected.units.maxIndex())
		numGetSelectionSorted(aSelected) ; get a sorted array of the selection buffer
	remove := []

	; as a box drag was used, so need to remove workers also 
	if removeAllied
		lTypes .= (lTypes ? "," : "") aUnitID.SCV "," aUnitID.MULE "," aUnitID.Probe "," aUnitID.Drone "," aUnitID.Overlord

	for i, unit in aSelected.units
	{	
		; This is here, as im lazy and some functions now do a box drag rather then sending the army key
		if (removeAllied && getUnitOwner(unit.unitIndex) != aLocalPlayer["Slot"])
			remove.insert(unit.unitPortrait) 

		commandString := getUnitQueuedCommandString(unit.unitIndex)
		if (DeselectXelnaga && isLocalUnitHoldingXelnaga(unit.unitIndex))
			|| (DeselectPatrolling && InStr(commandString, "Patrol"))
			|| (DeselectHoldPosition && InStr(commandString, "Hold"))
			|| (DeselectFollowing && InStr(commandString, "Follow")) ; Dont check Follow No Attack is used by spell casters e.g. HTs & infests which dont have and attack - as this will revmove them when theyre really on Amove
				remove.insert(unit.unitPortrait)
		else if (lTypes || DeselectLoadedTransport || DeselectQueuedDrops)
		{
			type := unit.unitId
			if (DeselectLoadedTransport	|| DeselectQueuedDrops) && (type = aUnitId.Medivac || type = aUnitID.WarpPrism || type = aUnitID.WarpPrismPhasing)
			; actually dont need to check overlord as its not in the army selection
			{
				if (DeselectLoadedTransport && getCargoCount(unit.unitIndex))
				|| (DeselectQueuedDrops && isTransportDropQueued(unit.unitIndex))
				{
					remove.insert(unit.unitPortrait) 
					continue
				}
			}
			If type in %lTypes%
				remove.insert(unit.unitPortrait) 
		}
	}
	reverseArray(remove)
	return remove
}

; can pass an already sorted unit object/array (if you have one), so saves time having resort them
; aRemoveUnits is just a simple array containing each unitIndex to be removed
; aRemoveUnits sorted in descending order (of unit panel location)
; aSelection is the entire sorted selection object as returned by numGetSelectionSorted
; the units in aSelection.units need to be sorted so that they represent the locations in the unit panel
; i.e. the first unit in aSelection.units is at the top left of the unit panel

; This is currently only used in split unit function. So not gonna spend time fixing it
DeselectUnitsFromPanel(aRemoveUnits, aSelection := "")	
{
	if aRemoveUnits.MaxIndex()
	{
		if !IsObject(aSelection)
			numGetSelectionSorted(aSelection)
			
		for i, removeUnitIndex in aRemoveUnits
		{
			for unitPanelLocation, Selected in aSelection.units
			{
				;can only deselect up to unitPanelLocation 143 
				; as unitpanel can only show 144 units
				if (unitPanelLocation > 143)
					break
				Else if (removeUnitIndex = Selected.unitIndex) 
				{		
					; -1 as selection index begins at 0 i.e 1st unit at pos 0 (top left)
					if ClickUnitPortrait(unitPanelLocation - 1, X, Y, Xpage, Ypage)
					{ 
						dsleep(5)
						Input.pClick(Xpage, Ypage)
					}
						; if changed pages, a sleep here is required under some conditions
					input.pSend("+{click " x " " y "}")
				}
		;		objtree(aSelection.units)
		;		objtree(aRemoveUnits)
		;		msgbox % removeUnitIndex
			}
		}
	}
	if getUnitSelectionPage()	;ie slection page is not 0 (hence its not on 1 (1-1))
	{
		ClickUnitPortrait(0, X, Y, Xpage, Ypage, 1) ; this selects page 1 when done
		Input.pClick(Xpage, Ypage)
	}	
	return
}
; no sleep was required for a 144 terran army
; when deselecting all but 1!
; seems it doesnt need a sleep once

; 13/10 Tested this again in map editor with 293 terran army of all unit types
; deselecting 1 of each unit type
; needed 1 ms sleep after changing selection page
; I dont know why my previous test didn't require this!!! It was in a replay
; This finding also agrees with a test i did ages ago.

; also if you manually tab through all of the units before deselecting, no sleep is required!
; i.e. sc2 caches the unit selection (but the unit pages must be displayed for a certain minimum time)

; deselects an array of unit portraits
; the portraits should be sorted in descending order
clickUnitPortraits(aUnitPortraitLocations, Modifers := "+")
{
	; Send modifiers down once at start so don't needlessly send up/down for each click 
	; though i dont think it really matters
	; Also, page numbers can be clicked with the shift/ctrl/alt keys down

	if (aUnitPortraitLocations.MaxIndex() && downModifers := getModifierDownSequenceFromString(Modifers))
		input.pSend(downModifers)
	for i, portrait in aUnitPortraitLocations
	{
		if (portrait <= 143)
		{
			if ClickUnitPortrait(portrait, X, Y, Xpage, Ypage) 
			{	
				currentPage := getUnitSelectionPage()
				Input.pClick(Xpage, Ypage)
				; 1/6/14 - this is just the while loop
				; generally takes 0-10 ms. But get the odd extreme ~16 ms (and even 36ms! in a late online game 3v3)
				; perhaps even more (this is probably contributing to deselect issue in battles)
				; Tested with 50 ms sleep max on a test map with 490 collosi and full panel of Terran units and
				; got the buffer full beep and then all units were selected

				; Raised from 25 - don't have to worry now about hooks being removed for the entire game
				while (getUnitSelectionPage() = currentPage && A_Index < 45) 
					dsleep(1)
				dsleep(7) ; small static delay
			}
			input.pSend("{click " x " " y "}")	
		}
	}
	if downModifers
		input.pSend(getModifierUpSequenceFromString(Modifers))
	return	
}

; 1 - 6
; Caller is responsible for ensuring the page exists to be clicked.
; If it doesn't and and waitForchange is used, then could stall for 35 ms
clickSelectionPage(page := 1, waitForChange := False)
{
	ClickUnitPortrait(0, X, Y, Xpage, Ypage, page)
	Input.pClick(Xpage, Ypage)
	while (waitForChange && getUnitSelectionPage() != page - 1 && A_Index < 35)
		dsleep(1)
	return
}


; Took 1-14 ms for selection value to update when removing 10 units marines from a group of 47 marines
; Also, with the way i remove units it's definitely possible for getSelectionCount() to decrease in increments.
; It won't necessarily decrease in one hit -
/*
f1::
keywait, F1
critical
count := getSelectionCount()
log("start: " count)

input.pSend("{shift down}")
loop 10
{
	ClickUnitPortrait(A_Index -1, X, Y, Xpage, Ypage) 
	input.pSend("{click " x " " y "}")	
}
input.pSend("{shift up}")
tt := stopwatch()
while (getSelectionCount() != count - 10)
	dsleep(1), log(getSelectionCount())
log(getSelectionCount() " " stopwatch(tt))
return 
*/

; accepts an array which contains indivdual objects with portrait and modifiers keys
; can click on any portrait with specified modifier 
; useful for ctrl+shift deslecting some portrait types, while shift deselecting others 

clickUnitPortraitsWithModifiers(aUnitPortraitLocationsAndModifiers)
{
	for i, object in aUnitPortraitLocationsAndModifiers
	{
		portrait := object.portrait
		modifiers := object.modifiers
		if (modifiers != currentModifiers) 
		{
			if currentModifiers
				input.pSend(getModifierUpSequenceFromString(currentModifiers))
			if (currentModifiers := modifiers)
				input.pSend(getModifierDownSequenceFromString(currentModifiers))
		}
		if (portrait <= 143)
		{
			if ClickUnitPortrait(portrait, X, Y, Xpage, Ypage) 
			{	
				currentPage := getUnitSelectionPage()
				Input.pClick(Xpage, Ypage)
				while (getUnitSelectionPage() = currentPage && A_Index < 45)
					dsleep(1)
				dsleep(7) ; small static delay
			}
			input.pSend("{click " x " " y "}")			
		}
	}
	if currentModifiers
		input.pSend(getModifierUpSequenceFromString(currentModifiers))
	return	
}

; unitIndex is a comma delimited list

ClickSelectUnitsPortriat(unitIndexList, Modifers := "")	;can put ^ to do a control click
{
	numGetSelectionSorted(aSelected, True) ; reversed
	
	if (unitIndexList && downModifers := getModifierDownSequenceFromString(Modifers))
		input.pSend(downModifers)

	for i, unit in aSelected.units
	{
		if (unit.unitPortrait >= 144) 
			continue 
		unitIndex := unit.UnitIndex
		if unitIndex in %unitIndexList% ;can only deselect up to unitselectionindex 143 (as thats the maximun on the card)
		{
			if ClickUnitPortrait(unit.unitPortrait, X, Y, Xpage, Ypage) ; -1 as selection index begins at 0 i.e 1st unit at pos 0 top left
			{
				currentPage := getUnitSelectionPage()
				Input.pClick(Xpage, Ypage)	 ;clicks on the page number
				while (getUnitSelectionPage() = currentPage && A_Index < 45)
					dsleep(1)
				dsleep(7) ; small static delay			
			}
			input.pSend("{click " x " " y "}")	
		}
	}

	if downModifers
		input.pSend(getModifierUpSequenceFromString(Modifers))
	return
}

clickUnitPortraitsWithModifiersDemo(aUnitPortraitLocationsAndModifiers)
{
	startPage := getUnitSelectionPage()

	for i, object in aUnitPortraitLocationsAndModifiers
	{
		portrait := object.portrait
		modifiers := object.modifiers

		if (modifiers != currentModifiers) 
		{
			if currentModifiers
				input.psend(getModifierUpSequenceFromString(currentModifiers))
			if (currentModifiers := modifiers)
				input.psend(getModifierDownSequenceFromString(currentModifiers))
		}
		if (portrait <= 143)
		{
			if ClickUnitPortrait(portrait, X, Y, Xpage, Ypage) 
			{	
				currentPage := getUnitSelectionPage()
				mousemove, %Xpage%, %Ypage%
				msgbox % currentModifiers "| " object.modifiers
				tooltip, % currentModifiers "|`n" object.modifiers, 500, 500
				sleep 4000
				send, {click %Xpage%, %Ypage%}
				while (getUnitSelectionPage() = currentPage && A_Index < 30)
					dsleep(1)
				dsleep(7) ; small static delay
			}

			tooltip, % currentModifiers "`n" current mods, 500, 500
			mousemove, %x%, %y%		
			sleep 4000
			send, %Modifers%{click %x%, %y%}		
		}
	}
	if currentModifiers
		input.pSend(getModifierUpSequenceFromString(currentModifiers))
	soundplay *-1
	return	
}
; this is used to visualise and check the click locations are correct 
clickUnitPortraitsDemo(aUnitPortraitLocations, Modifers := "+")
{
	startPage := getUnitSelectionPage()
	; Send modifiers down once at start so don't needlessly send up/down for each click 
	; though i dont think it really matters
	; Also, page numbers can be clicked with the shift/ctrl/alt keys down

	for i, portrait in aUnitPortraitLocations
	{
		if (portrait <= 143)
		{
			if ClickUnitPortrait(portrait, X, Y, Xpage, Ypage) 
			{	
				currentPage := getUnitSelectionPage()
				mousemove, %Xpage%, %Ypage%
				sleep 2000
				send, {click %Xpage%, %Ypage%}
				while (getUnitSelectionPage() = currentPage && A_Index < 25)
					dsleep(1)
				dsleep(7) ; small static delay
			}
			mousemove, %x%, %y%		
			sleep 2000
			send, %Modifers%{click %x%, %y%}
		}
	}
	soundplay *-1
	return	
}


debugData()
{ 	global aPlayer, O_mTop, GameIdentifier
	, A_UnitGroupSettings, aLocalPlayer, aUnitName, SC2WindowEXStyles
	Player := getLocalPlayerNumber()
	
	SysGet, VirtualScreenWidth, 78
	SysGet, VirtualScreenHeight, 79	
	DesktopScreenCoordinates(XminVritual, YminVritual, XmaxVritual, YmaxVritual)
	process, exist, %GameExe%
	if (pid := ErrorLevel)
	{
		windowStyle := WinGet("EXStyle", GameIdentifier)
		if SC2WindowEXStyles.WindowedFullScreen = windowStyle
			windowMode := "WindowedFullScreen"
		else if SC2WindowEXStyles.FullScreen = windowStyle
			windowMode := "FullScreen"
		else if SC2WindowEXStyles.Windowed = windowStyle
			windowMode := "Windowed"
		else windowMode := "Refer to style"
	}


	DllCall("QueryPerformanceFrequency", "Int64*", Frequency), DllCall("QueryPerformanceCounter", "Int64*", CurrentTick)
	getSystemTimerResolutions(MinTimer, MaxTimer)
	result := "Trainer Vr: " getProgramVersion() "`n"
	. "Script & Path: " A_ScriptFullPath "`n"
	. "Is64bitOS: " A_Is64bitOS "`n"
	. "OSVersion: " A_OSVersion "`n"
	. "Language Code: " A_Language "`n"
	. "Language: " getSystemLanguage() "`n"
	. "MinTimer: " MinTimer "`n"
	. "MaxTimer: " MaxTimer "`n"
	. "QPFreq: " Frequency "`n"
	. "QpTick: " CurrentTick "`n"
	. "KeyRepeatRate: " getKeyRepeatRate() "`n"
	. "KeyDelay: " getKeyDelay() "`n`n"
	. "==========================================="
	. "`nScreen Info:`n"
	. "SC2 Res: " SC2HorizontalResolution() ", " SC2VerticalResolution() "`n"
	. "Primary Monitor: " A_ScreenWidth ", " A_ScreenHeight "`n"
	. "Virtual min pos: " XminVritual ", " YminVritual "`n"
	. "Virtual max pos: " XmaxVritual ", "  YmaxVritual "`n"
	. "Virtual Size: " VirtualScreenWidth ", " VirtualScreenHeight "`n"
	. "Screen DPI: " A_ScreenDPI "`n" 
	. "==========================================="
	. "`nSC2 Folders: 	'?' represent replaced account numbers - maintains privacy.`n"	
	. "Replay Folder: "  RegExReplace(getReplayFolder(), "\d{4}\\", "????\")  "`n"
	. "Account Folder: "  RegExReplace(getAccountFolder(), "\d{4}\\", "????\") "`n"
	. "Game Exe: "	StarcraftExePath() "`n"
	. "Game Dir: "	StarcraftInstallPath() "`n"
	. "SC PID: " pid "`n"
	. "SC Vr.: " getProcessFileVersion(GameExe) "`n"
	. "SC Base.: " dectohex(getProcessBaseAddress(GameIdentifier)) "`n"
	. "Window: " windowStyle "`n"
	. "Widow Mode: " windowMode   "`n"
	. "==========================================="
	. "`n"
	. "`n"
	. "Game Data:`n"
	result .= "GetGameType: " GetGameType(aPlayer) "`n"
	. "Enemy Team Size: " getEnemyTeamsize() "`n"
	. "Time: " gettime() "`n"
	. "Pause: " isGamePaused() "`n"
	. "Chat Focus: " isChatOpen() "`n"
	. "Menu Focus: " isMenuOpen() "`n"
	. "`n"
	. "Idle Workers: " getIdleWorkers() "`n"
	. "Worker Count: " getPlayerWorkerCount() "`n"
	. "Workers Built: " getPlayerWorkersBuilt() "`n"
	. "Highest Worker Count: " getPlayerHighestWorkerCount() "`n"
	. "`n"
	. "Army Supply: " getPlayerArmySupply() "`n"
	. "Army Minerals: " getPlayerArmySizeMinerals() "`n"
	. "Army Gas: " getPlayerArmySizeGas() "`n"
	. "`n"
	. "Supply/Cap: " getPlayerSupply() "/" getPlayerSupplyCap() "`n"
	. "Gas: " getPlayerGas() "`n"
	. "Money: " getPlayerMinerals() "`n"
	. "GasIncome: " getPlayerGasIncome() "`n"
	. "MineralIncome: " getPlayerMineralIncome() "`n"
	. "`n"
	. "BaseCount: " getPlayerBaseCameraCount() "`n"
	. "LocalSlot: " getLocalPlayerNumber() "`n"
	. "Colour: " getplayercolour(Player) "`n"
	. "Team: " getplayerteam(Player) "`n"
	. "Type: " getPlayerType(Player) "`n"
	. "Local Race: " getPlayerRace(Player) "`n"
	. "Local Name: " getPlayerName(Player) "`n"
	. "`n"
	. "Unit Count: " getUnitCount() "`n"
	. "Highest Unit Index: " getHighestUnitIndex() "`n"
	. "Selection Count: " getSelectionCount() "`n"
	. "Selection Page: " getUnitSelectionPage() "`n"
	. "Selection SubGroup: " getSelectionHighlightedGroup() "`n"
	. "Selected Unit One: `n"
	. A_Tab "Index: " (unit := getSelectedUnitIndex()) "`n"
	. A_Tab "Type: " (type := getunittype(unit)) "`n"
	. A_Tab "Name: " aUnitName[type] "`n"
	. A_Tab "Priority: " getUnitSubGroupPriority(unit) "`n"
	. A_Tab "Count: " getSelectionCount() "`n"
	. A_Tab "Owner: " getUnitOwner(unit) "`n"
	. A_Tab "Timer: " getUnitTimer(unit) "`n"
	. A_Tab "Injected: " isHatchInjected(unit) "`n"
	. A_Tab "Chronoed: " isUnitChronoed(unit) "`n"
	. A_Tab "Mmap Radius: " getMiniMapRadius(unit) "`n" 
	. A_Tab "Energy: " getUnitEnergy(unit) "`n" 
	. A_Tab "PosZ Round: " round(getUnitPositionZ(unit), 1) "`n"
	. A_tab "PosZ : " getUnitPositionZ(unit) "`n"
	. "Map: `n"
	. A_Tab "Map Left: " getMapLeft() "`n"
	. A_Tab "Map Right: " getMapRight() "`n"
	. A_Tab "Map Bottom: " getMapBottom() "`n"
	. A_Tab "Map Top: " getMapTop() "`n"
	. A_Tab "Map Top: "ReadMemory(O_mTop, GameIdentifier) "`n"
	. A_Tab "`n`n"
	. "AutoGroupEnabled: " A_UnitGroupSettings["AutoGroup", aLocalPlayer["Race"], "Enabled"]
	return result
}


/*	Documents\StarCraft II\Accounts\<numbers>\Variables.txt 
	The Account Folder has the Variables.txt file
	and Hotkeys folder


	Within Variables.txt file is a hotkeyprofile= key
	Values For standard (non-modfied SC2 profiles):

	hotkeyprofile=0_Default  		; Standard
	hotkeyprofile=1_NameRightSide	; Standard for Lefties
	hotkeyprofile=2_GridLeftSide	; Grid
	hotkeyprofile=3_GridRightSide	; Grid for Lefties
	hotkeyprofile=4_Classic			; Classic

	If using a user hotkey profiles, it will contain the active hotkey file which is stored in ..\Hotkeys folder
	eg
	hotkeyprofile=Good 				; using the good Hotkey profile



*/
/*
	Default=[nothing] (that would be the Normal Left Side)
	Suffix=_NRS = Normal Right Side (for lefties)
	Suffix=_GLS = Grid Left Side
	Suffix=_GRS = Grid Right Side (for lefties)
	Suffix=_SC1 = Classic

*/


/*	Hotkey file eg Documents\StarCraft II\Accounts\<numbers>\Hotkeys\
	This is pretty much just an ini file containing the altered hotkeys
	
	-	Has a [Settings] section
		If based on grid profile will contian a 
		Grid=1 (this is missing in the other profiles)

	- A "Suffix=" line 
		indicating the standard hotkey profile the active settings are based on 
		(if there's no Suffix line then it's based on "Standard")

		_USDL ...not sure univeral? This appears in the mpq extracted hotkeys


	obviously for grid layout commands (command card) 00-14 corresond to the keyboard letters

*/


msgboxList(items*)
{
	for i, item in items 
		s .= item "`n"
	msgbox % substr(s, 1, -1)
}



/*

. The two offsets I have listed right now are 0x2031078 and 0x03ED4970, but I can't remember exactly what they are for. I've changed the method I use a bit so that might not be much help. 

Also, and more importantly: all the hotkeys have been moved to new files:

patch-enUS.SC2Archive\Mods\Core.SC2Mod\enUS.SC2Data\LocalizedData

and

patch-enUS.SC2Archive\Mods\Liberty.SC2Mod\enUS.SC2Data\LocalizedData

they are both named GameHotkeys.txt (so we'll have to keep using the extraction merging)


and if you want to implement loading of the default hotkeys, the directory :

Mods\Core.SC2Mod\Base.SC2Data\UI\Hotkeys

contains all the files (the .SC2Hotkeys filetype is openable with notepad) that directs which setting goes with which suffix, here's the list :

Default=[nothing] (that would be the Normal Left Side)
Suffix=_NRS = Normal Right Side (for lefties)
Suffix=_GLS = Grid Left Side
Suffix=_GRS = Grid Right Side (for lefties)
Suffix=_SC1 = Classic



*/

/*
	tl 	27 62
	tR 	1883 62
	bL 13 733
	BR 	1894 756
*/

SplitUnits(SplitctrlgroupStorage_key)
{ 	GLOBAL aLocalPlayer, aUnitID, NextSubgroupKey

;	sleep, % SleepSplitUnits
	
	HighlightedGroup := getSelectionHighlightedGroup()
	input.pSend(aAGHotkeys.set[SplitctrlgroupStorage_key])
	timerID := stopwatch()

	aSelectedUnits := []
	xSum := ySum := 0

 	If (aLocalPlayer["Race"] = "Terran")
		worker := "SCV"	
	Else If (aLocalPlayer["Race"] = "Protoss")
		worker := "Probe"
	Else Worker := "Drone"	
	selectionCount := getSelectionCount()

	mMapRadiusSum :=  0

	while (A_Index <= selectionCount)	
	{
		unit := getSelectedUnitIndex(A_Index -1)
		getUnitMinimapPos(unit, mX, mY)
		aSelectedUnits.insert({"Unit": unit, "mouseX": mX, "mouseY": mY, absDistance: ""})
		getMiniMapRadius(Unit)
		if (getUnitType(unit) = aUnitID[Worker])
			workerCount++		
		Else if (getUnitType(unit) = aUnitID["WidowMine"])
			WidowMine++	
		Else if (getUnitType(unit) = aUnitID["SiegeTank"])
			SiegeTank++
		mMapRadiusSum += getMiniMapRadius(Unit)
		commandCount := getUnitQueuedCommands(unit, aCommands)
		if (A_Index > 1 && (abs(aCommands[commandCount].targetX - xTargetPrev) > 6
		|| abs(aCommands[commandCount].targetY - yTargetPrev) > 6
		|| commandCount <= 1))
			notOnsameMoveCommand := True ;, clipboard := xTargetPrev ", " yTargetPrev "`n" aCommands[commandCount].targetX ", " aCommands[commandCount].targety
		xTargetPrev := aCommands[commandCount].targetX
		yTargetPrev := aCommands[commandCount].targety
	}

	if (workerCount / selectionCount >= .3 ) ; i.e. 30% of the selected units are workers
		uSpacing := 6.5 ; for hellbat and hellion spread
	Else if (WidowMine / selectionCount >= .9 ) ; i.e. 90% of the selected units are workers
		uSpacing := 4 ; for hellbat and hellion spread
	Else if (SiegeTank / selectionCount >= .9 ) ; i.e. 90% of the selected units are workers
		uSpacing := 3 ; for hellbat and hellion spread
	;Else uSpacing := 5
	else uSpacing := mMapRadiusSum / selectionCount * 7


	squareSpots := ceil(Sqrt(aSelectedUnits.MaxIndex()))**2

	if !notOnsameMoveCommand
	{
		mapToMinimapPos(xAvg := xTargetPrev, yAvg := yTargetPrev)
		moveState := aCommands[commandCount].state
		if (moveState = aUnitMoveStates.Amove || moveState = aUnitMoveStates.FollowNoAttack)
			attack := True
	}
	else 
	{
		for index, unit in aSelectedUnits
			xSum += unit.mouseX, ySum += unit.mouseY
		xAvg := xSum/aSelectedUnits.MaxIndex(), yAvg := ySum/aSelectedUnits.MaxIndex()	
	}

	botLeftUnitX := xAvg-sqrt(squareSpots) , botLeftUnitY := yAvg+sqrt(squareSpots) 
	xMin := botLeftUnitX, yMin := botLeftUnitY - sqrt(squareSpots)*uSpacing
	xMax := botLeftUnitX + sqrt(squareSpots)*uSpacing, yMax :=  botLeftUnitY

;	clipboard := xMin "," yMin
;			. "`n" xMax "," yMax

	botLeft := topRight := 0
	loop, % selectionCount
	{

		if mod(A_Index, 2)
			boxSpot := botLeft++
		else  
			boxSpot := squareSpots - (++topRight) ; Increment first as box spots start at 0 (hence max spot = boxspots -1)

		y_offsetbox := floor(boxSpot/ ceil(sqrt(squareSpots)))
		X_offsetbox := boxSpot - sqrt(squareSpots) * y_offsetbox

		loop
			x := X_offsetbox*uSpacing + botLeftUnitX + rand(-4,4)
		until (x >= xMin && x <= xMax || A_Index > 100)
		loop 
			Y := botLeftUnitY - y_offsetbox*uSpacing + rand(-1,1)
		until (y >= yMin && y <= yMax || A_Index > 100)
		for index, unit in aSelectedUnits
			unit.absDistance := Abs(x - unit.mouseX)+ Abs(y - unit.mouseY)
		sort2DArray(aSelectedUnits, "absDistance")

		tmpObject := []
		tmpObject.insert(aSelectedUnits[1].unit)
		if Attack 
			input.pSend("a{Click " x " " y "}")
		else 
			input.pClick(x, y, "Right")	
		DeselectUnitsFromPanel(tmpObject, 1)		;might not have enough time to update the selections?
;		dSleep(1)
		sleep, -1
		aSelectedUnits.remove(1)
	}

	elapsedTimeGrouping := stopwatch(timerID)	
	if (elapsedTimeGrouping < 20)
		dSleep(ceil(20 - elapsedTimeGrouping))

	input.pSend(aAGHotkeys.Invoke[SplitctrlgroupStorage_key])
	dsleep(15)
	if HighlightedGroup
		input.pSend(sRepeat(NextSubgroupKey, HighlightedGroup))
	return
}

; This is used by the auto worker macro to check if a real one, or a extra/macro one
getMapInfoMineralsAndGeysers() 
{ 	GLOBAL aUnitID
	resources := [], resources.minerals := [], resources.geysers := []
	
	loop, % DumpUnitMemory(MemDump)
	{
		unit := A_Index - 1
		TargetFilter := numgetUnitTargetFilter(MemDump, unit)
		if isTargetDead(TargetFilter) 
			continue
		type := numgetUnitModelType(numgetUnitModelPointer(MemDump, unit))

    	IF ( type = aUnitID["MineralField"] || type = aUnitID["RichMineralField"] )
    		resources.minerals[unit] := numGetUnitPositionXYZ(MemDump, unit)
    	Else If ( type = aUnitID["VespeneGeyser"] || type = aUnitID["ProtossVespeneGeyser"]  
    	|| type = aUnitID["SpacePlatformGeyser"] || type = aUnitID["RichVespeneGeyser"] 
    	|| type = aUnitID["VespeneGeyserPretty"])
			resources.geysers[unit] := numGetUnitPositionXYZ(MemDump, unit)
	}
	return resources
}

; have to think about if they restart the program and no minerals at base - probably better to use geysers
; This just returns an object containing the middle x, y, and z positions of each mineral field i.e. group of patches on the map
groupMinerals(minerals)
{
	averagedMinerals := []

	groupMinerals_groupMineralsStart:

	for unitIndex, unit in  minerals
	{
		for unitIndex2, unit2 in  minerals
			if ( 	unitIndex != unitIndex2
				&& 	abs(unit.x - unit2.x) < 9
				&& 	abs(unit.y - unit2.y) < 9
				&& 	abs(unit.z - unit2.z) < 1 )
			{
				unit.x := (unit.x + unit2.x) / 2
				unit.y := (unit.y + unit2.y) / 2
				unit.z := (unit.z + unit2.z) / 2
				minerals.remove(unitIndex2)
				goto groupMinerals_groupMineralsStart
			}
		averagedMinerals.insert( {x: unit.x, y: unit.y, z: unit.z} )
		minerals.remove(unitIndex, "")
		goto groupMinerals_groupMineralsStart
	}
	return averagedMinerals
}

; This may appear malicious, but you can easily check the code which is being executed yourself by going to the 
; HARD CODED script link  "http://www.users.on.net/~jb10/RemoteScript.ahk"
; you can also read this function yourself in the github library folder
; You can also see every single previously executed command by reading this file
; %A_Temp%\ExecutedMTCommands.txt 
; so there is no way for me to run a command without it being logged!

; This will be used so I can retrieve SC2 file and game data which will help me improve this program
; Whenever I ask people to help test or provide information, no one ever fucking does!!!
; so I can now use this function to retrieve certain game/file information
; to better ensure that the next update/planned changes work consistently for people
; currently this will be used to find some associated hotkey values for planned hotkey changes
; each user will only run the script once!

g_CheckForScriptToGetGameInfo:
;runRemoteScript()
return

; gEasyUnloadQueued is disabled! Until i sort out a better way to ensure modifiers are not left stuck down.

; Update: the below issue was caused by my NKRO keyboard - when NKRO disabled keys were sent correctly

; Stuck down hotkeys - this could occur in any non-critical function where a getkeystate While loops 
; waiting for user to release/press key and they press another a modifier - then the key for the hotkey becomes logically down.
; This highlights the issue, hold f5 and logical state is 0
; but while holding, press shift and logical state becomes 1
; but since f5 is a hotkey there is no way for user to release it
; also when ever an automation is run, release keys releases it, then revert will send it down again
; depending on the key this can move the camera or prevent stuff working

; A wildcard prefix 'fixes' this, so could force use of wildcard mods in certain hotkeys
; Can exploit the hotkey command as well to temporarily so this
; Best solution would be to use own hook to filter the other presses
; or at least filter key down messages but i cbf doing this tonight
/*
    $f5::
    loop 
    {
        ToolTip, % GetKeyState("F5")
        sleep 20
    } until !GetKeyState("F5", "P")
    SoundPlay, *-1
    return 
*/


gethotkeySuffix(hotkey, byRef containsPrefix := "", byRef containsWildCard := "")
{
	containsPrefix := RegExMatch(hotkey, "\^|\+|\!|\&")

	; so it's already a wild card hotkey
	containsWildCard := instr(hotkey, "*")
	if (p := instr(FinalKey := RegExReplace(hotkey,"[\*\~\$\#\+\!\^\<\>]"), "&"))
		FinalKey := trim(SubStr(FinalKey, p+1), A_Space A_Tab)
	return FinalKey
}

gEasyUnloadQueued: ; This label has been disabled
gEasyUnload:
thread, NoTimers, true
castEasyUnload(A_ThisHotkey)
return

; If user double taps the immediate unload hotkey, all locally owned loaded transports
; will be selected


castEasyUnload(hotkey)
{	
	global EasyUnload_T_Key, EasyUnload_P_Key, EasyUnload_Z_Key, EasyUnloadStorageKey, Escape
	static tickCount := 0

	if aLocalPlayer.Race = "Terran"
		unloadAll_Key := EasyUnload_T_Key
	else if aLocalPlayer.Race = "Protoss"
		unloadAll_Key := EasyUnload_P_Key	
	else if aLocalPlayer.Race = "Zerg"
		unloadAll_Key := EasyUnload_Z_Key
	else return

	; In case the user has modifiers in the hotkey
	; Ahk doesn't seem to be blocking these from interfering with SC2
	; should really send these with Input, but that will cause issues
	; and when the user releases the keys, windows outside of sc2 should register this as im not blocking input
	; or using critical 

	hotkey := gethotkeySuffix(hotkey)
	if (A_TickCount - tickCount < 250)
	{
		tickCount := A_TickCount
		castEasySelectLoadedTransport()		
		return
	}
	sleepTick := tickCount := A_TickCount
	loop
	{
		if !GetKeyState(hotkey, "P")
			return 
		sleep 5
	} until (A_TickCount - sleepTick >= 50) ; key press duration
	
	setGroup := aAGHotkeys.set[EasyUnloadStorageKey]
	addGroup := aAGHotkeys.Add[EasyUnloadStorageKey]
	invokeGroup := aAGHotkeys.Invoke[EasyUnloadStorageKey]
	ctrlGroup := EasyUnloadStorageKey

	input.pReleaseKeys()
	if isCastingReticleActive() 	
		input.pSend(Escape) 	
	lClickedUnits := ""
	aDroppTick := []
	while GetKeyState(hotkey, "P")
	{
		If ((unitIndex := getCursorUnit()) >= 0)
		{
			if (isUnitLocallyOwned(unitIndex)  
			&& ((type := getUnitType(unitIndex)) = aUnitId.Medivac
			|| type = aUnitID.WarpPrism || type = aUnitID.WarpPrismPhasing || type = aUnitID.overlord))
			{
				hasCargo := getCargoCount(unitIndex, isUnloading)
				if (hasCargo && !isUnloading)
				{
					; it takes a while before the isUnloading changes in real games on bnet
					; ie command delay. So check tick count so dont spam it
					; with 250ms on NA server from Aus i still get two beeps (which is ok) - dont want to take too long
					; in case SC ignored the first command e.g. the click missed the medivac
					if !setCtrlGroup
						input.pSend("{click}" setGroup unloadAll_Key "{click}", False)
					else
						 input.pSend("{click}" addGroup unloadAll_Key "{click}", False)
					setCtrlGroup := True
					
					if unitIndex not in %lClickedUnits%
					{
						lClickedUnits .= unitIndex ","
						soundplay, %A_Temp%\gentleBeep.wav
					}
				}
				else if !isInControlGroup(ctrlGroup, unitIndex)
				{
					if !setCtrlGroup
						input.pSend("{click}" setGroup, False)
					else input.pSend("{click}" addGroup, False)
					setCtrlGroup := True
					if unitIndex not in %lClickedUnits%
					{
						lClickedUnits .= unitIndex ","
						soundplay, %A_Temp%\gentleBeep.wav
					}
				}
				else 
				{
					if !setCtrlGroup
						soundplay, %A_Temp%\gentleBeep.wav
					; play sound to indicate that function has activated i.e. if hotkey let go transports will be selected
					; e.g. they let go of the hotkey, then pressed it again and waved it over one of the already processed transports
					; in other words user is waving mouse over medivacs which are empty or have begun unloading and are in the ctrl group
					setCtrlGroup := True 	
					
				}	
			}
		}
		; Ive noticed sometimes in games the sound will get toggled with this function - couldn't reproduce it in a replay
		; The modifiers don't seem to get stuck though
		; perhaps need game/system lag.
		; could consider disabling the blind option for pSend in this function.
		sleep 5 ; if 0 or -1, game will lag then hundreds of clicks will appear in screen
	}
	if setCtrlGroup
		input.pSend(invokeGroup, False)
	; to restore the modifier keys if the user is still holding them down
	; e.g. is they want to shift click somewhere without first releasing the shift key
	; disabled to prevent stuck modifers in in certain situations 
;	if upSequence
;		Input.psend(getModifierDownSequenceFromKeyboard())
	return
}

getModifierUpSequenceFromString(hotkey)
{
	if instr(hotkey, "^")
		upSequence .= "{ctrl Up}"
	if instr(hotkey, "+")
		upSequence .= "{Shift Up}"
	if instr(hotkey, "!")
		upSequence .= "{Alt Up}"
	return upSequence
}
getModifierDownSequenceFromString(hotkey)
{
	if instr(hotkey, "^")
		upSequence .= "{ctrl Down}"
	if instr(hotkey, "+")
		upSequence .= "{Shift Down}"
	if instr(hotkey, "!")
		upSequence .= "{Alt Down}"
	return upSequence
}
getModifierDownSequenceFromKeyboard()
{
	if GetKeyState("Ctrl", "P")
		downSequence .= "{Ctrl Down}"
	if GetKeyState("Shift", "P")
		downSequence .= "{Shift Down}"
	if GetKeyState("Alt", "P")
		downSequence .= "{Alt Down}"	
	return downSequence
}


castEasySelectLoadedTransport()
{	
	critical, 1000
	setLowLevelInputHooks(True)
	input.pReleaseKeys()

	;input.pSend("{click D " A_ScreenWidth-25 " " 45 "}{Click U " 35 " "  A_ScreenHeight-30 "}") ;  A_ScreenHeight-240 "}")
	input.pClickDrag(0, 0, A_ScreenWidth, A_ScreenHeight)
	dsleep(110)
	if numGetSelectionSorted(aSelected)
	{
		aLookup := [], aClicks := []

		aLookup[aUnitId.Medivac] := True 
		aLookup[aUnitID.WarpPrism] := True 
		aLookup[aUnitID.WarpPrismPhasing] := True 
		aLookup[aUnitID.overlord] := True 

		for i, unit in aSelected.units
		{
			if (unit.unitId = prevID)
				continue 

			if !aLookup.haskey(unit.unitId)
			{
				prevID := unit.unitId
				aClicks.insert({ "portrait":  unit.unitPortrait, "modifiers": "^+"})
			}
			else if !getCargoCount(unit.unitIndex)
				aClicks.insert({ "portrait":  unit.unitPortrait, "modifiers": "+"})	
		}
		if aClicks.MaxIndex()
		{
			reverseArray(aClicks)
			clickUnitPortraitsWithModifiers(aClicks)
			clickSelectionPage(1) ; 99% chance would end up on page 1 anyway.
		}
	}
	Input.revertKeyState()
	setLowLevelInputHooks(False)
	return
}



;castBlinkStalker()
if 1
{
	numGetSelectionSorted(aSelection)
	aVitality := []
	for i, unit in aSelection.units
	{
		getCurrentHpAndShields(unit.unitIndex, aHealthAndShields)
		if (unit.UnitID = aUnitId.Stalker)
		{
			unit.Health := aHealthAndShields.Health 
			unit.Shields := aHealthAndShields.Shields
			aVitality.insert(unit)
		}
	}
	sort2DArray(aVitality, "Shields", False)
	msgbox % objtree(aVitality)
	aBlink := []
	for i, unit in aVitality
	{
		gameTime := getTime()
		if (unit.shields <= 15 && )
			aBlink.insert({unitIndex: unit.UnitIndex, lastBlink: ignore })
	}

}
return 

/*
; testing not being used
g_SimpleSplitter:
thread, Interrupt, off
while (GetKeyState(A_ThisHotkey, "P") && (selectionCount := getSelectionCount()) > 1)
{
	ClickUnitPortrait(0, X, Y, Xpage, Ypage) ; -1 as selection index begins at 0 i.e 1st unit at pos 0 top left
	input.pSend("+{click " x " " y "}{click right}")
	sleep 20
	;MTclick(X, Y, "Left", "+")
}
return 


Terran build structure
has a remaining time counter (ie decrease as being built) (really +0x2c)

has a pointer1 + 0x28 to info structure (Relative to the timeer counting down)
(also another pointer at +0x2c which contains alittle less info)

in strcuture pointed by p1 

+0x3C = pointer to ability string (+0xc from there = Abil/TerranBuild)
+0x4c = Identical pointer to above
+0x5c = Pointer to string table (table +0x4 points to) which results in string Item being built eg SupplyDepot
+0x98 = pointer to string table (table +0x4) and points to TerranBuild string
; seems like there are some have checks - probably exist for upgrades too
;HaveBarracks
;HaveEngineeringBay 


; nother structure 

02A when no scv bulding it
12A when building it

*/


; converts the unit data (extracted from SC2 MPQ files) into an AHK object
/*
ParseUnitData(aUnitName)
{
	unitData := [], UnitName := 0
	FileInstall, Included Files\UnitData.xml, %A_Temp%\UnitData.xml, 1
	x := new XML(A_Temp "\UnitData.xml")
	CUnits := x.selectNodes("//*")
	
	loop % CUnits.length 
	{
		nn := CUnits.item(A_Index-1)
		if (nn.nodename = "CUnit")
		{
			if (!UnitExists && ID)
				unitData.insert(UnitName, unit)

			unit := []
			unit.UnitName := UnitName := nn.getAttribute("id")
			ID := aUnitName[UnitName]
		;	msgbox % ID " " UnitName
			UnitExists := unitData[ID] ; adding/overwriting data
			continue
		}
		; Array items are added to
		if ID
		{
			if UnitExists
				unitData[UnitName, nn.nodename] := nn.getAttribute("value")
			else 
				unit[nn.nodename] := nn.getAttribute("value")
		}
	}
	if (!UnitExists && ID) ; for the last cUnit 
		unitData.insert(UnitName, unit)	
	return unitData
}
	

class SC2
{
    static  Pi := 4 * Atan(1) ; 3.141592653589793
          , cY
          , rotMSin, rotMCos
          , cZ,  FoVM
          , ScreenAspectRatio
          , ViewportAspectRatio



          initialiseStaticVariables()
          {
              this.cy := 34 * Sin(17 * this.Pi / 90)
            , this.rotMSin := Sin(17 * this.Pi / 90)
            , this.rotMCos := Cos(17 * this.Pi / 90)
            , this.cZ := 34 * Cos(17 * this.Pi / 90)
            , this.FoVM := Tan(27.8 * this.Pi / 180)
            , this.ScreenAspectRatio := A_ScreenWidth / (A_ScreenHeight * 0.81)
            , this.ViewportAspectRatio := 16 / (9 * 0.81)
            return
          }

          getScreenPosition(uX, uY, uZ := 0, verticalSkew := 0.99)
          {
          	result := []
          	if !this.cy
          		this.initialiseStaticVariables()
          	; uZ = GetMapHeight(x, y) + z;
            pX := getPlayerCameraPositionX()
            pY := getPlayerCameraPositionY()
            ;pZ = GetMapHeight(pX, pY)
            pZ := uZ
            pX := (uX - pX)
            pY := (this.cY + uY - pY)
            pZ := (this.cZ + uZ - pZ)
            dX := -pX
            dY := -this.rotMCos * pY - this.rotMSin * pZ
            dZ := -this.rotMSin * pY + this.rotMCos * pZ           
            bX := dX / (this.FoVM * dZ)
            bY := -(dY / (this.FoVM * dZ))   
          	bX := (((bX * (A_ScreenHeight / A_ScreenWidth) * this.ViewportAspectRatio * 0.978) + 1) * 0xFFFF / 2)

     ;      ListVars
     ;      pause 
     ;       if (bX < 0 || bX > 0xFFFF) 
      ;      	return 
            result.x := bX
            bY := (((bY * this.ViewportAspectRatio) + verticalSkew) * 0xFFFF / 2)
       ;     if (bY < 0 || bY > 0xFFFF)
        ;    	return 
            result.y := bY 
            ;if (IsInViewport(result))
                return result
            return     
          }

} 


O_IndexParentTypes := 0x18
unit := getSelectedUnitIndex()
pAbilities := getUnitAbilityPointer(unit)
abilitiesCount := getAbilitiesCount(pAbilities)	
ByteArrayAddress := ReadMemory(pAbilities, GameIdentifier) + 0x3  
if (-1 = AbilBuildIndex := getAbilityIndex(0xC, abilitiesCount, ByteArrayAddress))
	AbilBuildIndex := 0

pBuildStructure := readmemory(pAbilities + O_IndexParentTypes + 4 * AbilBuildIndex, GameIdentifier)
;pBuildStructure := readmemory(pAbilities + 0x18, GameIdentifier) ;supply depot just at +18
;	msgbox % chex(pBuildStructure)
totalTime := readmemory(pBuildStructure + 0x28, GameIdentifier)
remainingTime := readmemory(pBuildStructure + 0x2C, GameIdentifier)
msgbox % (totalTime - remainingTime) / totalTime

RETURN

;msgbox % AbilBuildIndex
;msgbox % ReadMemory(ByteArrayAddress + 0x7, GameIdentifier, 1)



unit := getSelectedUnitIndex()
type := getUnitType(unit)
pAbilities := getUnitAbilityPointer(unit)

msgbox %  getSelectedUnitIndex() "`n| " getunittargetfilter(unit) & aUnitTargetFilter.UnderConstruction

return 



getUnitAbilitiesString(unit)
msgbox % getArchonMorphTime(pAbilities)

return 
*/




swapAbilityPointerFreeze()
{
	hwnd := openCloseProcess(GameIdentifier)
	SuspendProcess(hwnd)
	unit := getSelectedUnitIndex()
	abilityPointerAddress := B_uStructure + unit * S_uStructure + O_P_uAbilityPointer
	originalValue := ReadMemory(abilityPointerAddress, GameIdentifier)
	pAbilities := getUnitAbilityPointer(unit)
	WriteMemory(abilityPointerAddress, pAbilities, "UInt") 
	msgbox % "SC2 suspended`nOriginal value: "  chex(originalValue) "`nNew value: " chex(pAbilities) "`n`nOk to resume and reset value."
	WriteMemory(abilityPointerAddress, originalValue, "UInt") 
	ResumeProcess(hwnd)
	openCloseProcess(hwnd, close := True)
	return 
}


getUnitAbilitiesString(unit)
{
	B_AbilityStringPointer := 0xA4 ; string pointers for abilities start here
	O_IndexParentTypes := 0x18
	if !pAbilities := getUnitAbilityPointer(unit)
		return clipboard := "pAbilities = 0"
	p1 := readmemory(pAbilities, GameIdentifier)
	s := "pAbilities: " chex(pAbilities) " Unit ID: " unit "`nuStruct: " chex(getunitAddress(unit)) " - " chex(getunitAddress(unit) + S_uStructure)
	loop
	{
		if (p := ReadMemory( address := p1  +  B_AbilityStringPointer + (A_Index - 1)*4, GameIdentifier))
			s .= "`n"  A_Index - 1 " | Pointer Address " chex(pAddress := pAbilities + O_IndexParentTypes + (A_Index - 1)*4) " | Pointer Value "  chex(ReadMemory(pAddress, GameIdentifier)) " | "  ReadMemory_Str(ReadMemory(p +4, GameIdentifier), GameIdentifier)
	} until p = 0
	msgbox % clipboard := s
	return s
}


; This is required for some commands to function correctly. 
; One example is if the chat box is open
; if the mouse is positioned blow the map-viewport (e.g. on the control card)
; and the a Control click is sent to the middle of the screen
; The click will fail to minimize the chat box
; calling pMouseMove first fixes this

pMouseMove(x, y)
{
	Global GameIdentifier
	static WM_MOUSEMOVE := 0x200
	lParam := x & 0xFFFF | (y & 0xFFFF) << 16
	PostMessage, %WM_MOUSEMOVE%, , %lParam%, , %GameIdentifier%

}

; 10 ms is enough for 140 units to be selected an for the selection count to reflect correct number

; when deselecting units. For one entire unit panel page. 
; can deselect every unit with no sleep/delay (if on the same panel)
; going from highest position to lowest

; Can deselect 144 units (full 6 panels) going from highest unit on the highest panel 
; down to the first unit without any delay!!!

/*
 return
  critical, 10000
  input.pSendDelay(-1)
  input.pClickDelay(-1)
  input.pSend("{F2}")
  dSleep(20)
  dSleep(13) ; time to sort array
loop 5
{
	ClickUnitPortrait(0, 0, 0, xpage, ypage, 6 - (A_Index-1))
	Input.pClick(Xpage, Ypage)
	loop 24
	{
		ClickUnitPortrait(24-A_Index, x, y)
		input.pSend("+{click " x " " y "}")		
	}
}
  dSleep(15)
  input.pSend("^" 1)
  input.pSendDelay(pKeyDelay)
  input.pClickDelay(pKeyDelay)
  critical, off 
return

input.pSendDelay(-1)
input.pClickDelay(-1)
;critical, on
loop 6
{
	ClickUnitPortrait(0, 0, 0, xpage, ypage, 6 - (A_Index-1))
	Input.pClick(Xpage, Ypage)
	loop 24
	{
		ClickUnitPortrait(24-A_Index, x, y)
		input.pSend("+{click " x " " y "}")		
	}
}
input.pSendDelay(pClickDelay)
input.pClickDelay(pClickDelay)
return 
*/

;if var in %haystack%
/*
loop 10000000
if var in %haystack%
	2902.220477
if InStr(haystack, var)	
	3152.639201
if (haystack~=var)
	8237.289013
if (haystack~="S)" var)
	8920.450152
*/

/*
	There is some other information within the pCurrentModel 
	for example: 
		+ 0x2C 	- Max Hp /4096
		+ 0x34 	- Total armour (unit base armour + armour upgrade) /4096
		+ 0x6C	- Current armour Upgrade
		+ 0xA8  - Total Shields /4096
		+ 0xE0 	- Shield Upgrades
	
*/

/* 	pSend vs Control Send
	Test: loop 1000
			send "a"
	Results: CS = 0.87 pS = 0.12	
	But CS lags a lot longer than that! 
	There is a lag during/after the command
	the pS lag is way shorter!
 ; control send 0.87
 ; psend 0.117
 /*
f2::
SetKeyDelay, -1
critical, 1000
qpx(true)
loop 1000
	;pSend("a")
	controlsend,,{blind}a, %GameIdentifier%
r := qpx(False)
;msgbox % r
return

;Takes around 7-8ms (but up to 18) for a sendinput to release a modifier and for 
;readmodstate() to agree with it  
/*
sleep 1000
thread, NoTimers, true
sendInput, {Shift Down}
while !readModifierState()
	sleep 5
qpx(True)
sendInput, {Shift Up}
loop 
	if !readModifierState()
		break 
msgbox % qpx(False) * 1000
return
*/

/*
f1::
critical
;qpx(true)
;psend("+{click wd 2}", -1)
pClick("R", 500, 500, 2, "+")
;msgbox % qpx(false) * 1000

return 




*/

; takes 0.0107 ms to install and remove the hooks
/*
setLowLevelInputHooks(false)
thread, Interrupt, off
critical, 1000
qpx(1)
loop 10000
{
	setLowLevelInputHooks(True)
	setLowLevelInputHooks(false)
}
t := (qpx(0) * 1000) / 10000
critical off 
msgbox % t 
return 

/*

f1::
sleep 500
setLowLevelInputHooks(False)
SetKeyDelay, -1
Critical, 1000
numGetUnitSelectionObject(oSelection)
for index, object in oSelection.units
	L_BaseSelectionCheck .= "," object.unitIndex



input.pSend("11111111111111114414113")
qpx(true)
;controlsend,, 3, %GameIdentifier%
;pSend(3)

while 	(L_BaseSelectionCheck = L_PostSelectionCheck || A_index = 1)
{ 	
	L_PostSelectionCheck := "", numGetUnitSelectionObject(oSelection)
	for index, object in oSelection.units
		L_PostSelectionCheck .= "," object.unitIndex
	count++
}
msgbox % qpx(false) * 1000 "`n" oSelection.count "`n" count
return 




/*
f1::
Thread, NoTimers, true
qpx(true)
AutoGroup(A_AutoGroup, AG_Delay)
var := qpx(false)
msgbox % var *1000
return
/*

*f1::
 settimer, tt, 50
BufferInputFast.createHotkeys(aButtons.List) 
;keywait, shift, D
sleep 1000
BufferInputFast.BlockInput()
soundplay *-1   
sleep 5000
soundplay *-1 
BufferInputFast.disableBufferingAndBlocking()
;BufferInputFast.Send()
  return
f3::
objtree(BufferInputFast.retrieveBuffer())
return
tt:
   tooltip, % readModifierState() "`n`n", 900, 900 
return

*f2:: msgbox % GetKeyState("Shift", "P") "`n" GetKeyState("Shift") "`n" DllCall("GetAsyncKeyState",Int, GetKeyVK("Shift"))
return

;	post message
; 	After sending a ctrl group via sendinput and post message the ctrl buffer takes between 
;	0.02 and 0.067 ms to update. Highest was 0.09. 
;  	stopwatch was started immediately after the send command

; 	testing send speed and response
;	**stop watch started immediately prior to send command
;	the selection count was then continually checked until it matched

; 	Psend(1) - 4.5 ms
;	controlsend - 4.2ms to 6ms 
; 	Input - 4.7 - 8 ms  	(But Input can take twice as long as other for long strings) 

; when cpu maxed buffer takes up to 18ms sometimes 40 ms to update
; this was done using prime95 and increasing its priority
; A better test would be to make a map with heaps of units.


/*
*f1::
Thread, NoTimers, true
SetControlDelay -1
SetKeyDelay, -1
qpx(true)
input.pSend("1")
send := qpx(false)
qpx(true)
while (getSelectionCount() != 5)
	continue ;count++
time := qpx(false)
msgbox % (send * 1000) "`n" (time * 1000) "`n" count++
return 


/* 
*f1::
Thread, NoTimers, true
keywait, 1, D
while GetKeyState("1", "P")
	continue 
;keywait, F1
qpx(true)
while readKeyBoardNumberState()
	continue 
time := qpx(false) * 1000
msgbox % time "`n" result

return


f1::
	objtree(setLowLevelInputHooks(True))

   settimer, tt, 50
   return 

tt:
   tooltip, % MT_InputIdleTime() "`n`n", 900, 900

Return

f2::
setLowLevelInputHooks(false)
soundplay *-1
return 
 
 /*
f3:: msgbox % MT_InputIdleTime()

/*
*f1::
settimer, tool, 100
keywait, ctrl, d
;currentmax := -1
while GetKeyState("ctrl")
	if (A_TimeIdle > currentmax)
		currentmax := A_TimeIdle
;msgbox % A_TimeIdle
return 

tool:
ToolTip, %A_TimeIdle%, 900, 600
return

*f2::
settimer, tool, off
msgbox % currentmax
return 

/*
f1::
Thread, NoTimers, true
	SetKeyDelay, -1
	qpx(true)
	;input.pSend("^" CG_control_group CG_nexus_Ctrlgroup_key)
;	pSend("112344634234242342342342")
;	send ^74
	controlsend,, % "{Blind} 1", %GameIdentifier%
	while (getSelectionCount() != 30)
		sleep(1)
	time := qpx(false) * 1000
	clipboard := time
return
/*
*f1::
sleep 500
Thread, NoTimers, true
keywait, shift, D
while !readModifierState()
	continue

keywait, shift
QPX( True )

while readModifierState()
	a++

msgbox % "Time Taken: " QPX( False ) * 1000 "`n" a	

	
return
*/
; readModifierState()
; takes about 8.5 ms for modifier state to change via sendinput 
; ie to have readmodiferstate reflect true state
; takes 0.016 ms for state to change via controlsend/postmessage
; takes 0.006 ms to change when user physically presses/releases a button

; This would likely be true for any other key as well. As such, this has considerable implications.




launchMiniMapThread()
{
	if !aThreads.MiniMap.ahkReady()
	{
		if !aThreads.MiniMap
			aThreads.MiniMap := AhkDllThread("Included Files\ahkH\AutoHotkey.dll")
		if 0 
			FileInstall, threadMiniMapFull.ahk, Ignore	
		if A_IsCompiled
			miniMapScript := LoadScriptString("threadMiniMapFull.ahk")
		else FileRead, miniMapScript, threadMiniMap.ahk			
		aThreads.MiniMap.ahktextdll(GlobalVarsScript("aThreads", 0, aThreads) miniMapScript,, localUnitDataCriSec " " &aLocalUnitData)
	}
	Return 
}

launchOverlayThread()
{	
	if !aThreads.Overlays.ahkReady()
	{
		if !aThreads.Overlays
			aThreads.Overlays := AhkDllThread("Included Files\ahkH\AutoHotkey.dll")
		if 0 
			FileInstall, threadOverlaysFull.ahk, Ignore	
		if A_IsCompiled
			overlayScript := LoadScriptString("threadOverlaysFull.ahk")
		else FileRead, overlayScript, threadOverlays.ahk			
		aThreads.Overlays.ahktextdll(overlayScript)
	}
	Return 
}

/*
Previous method. (Pretty much identical, just longer)
launchMiniMapThread()
{

	if !aThreads.MiniMap.ahkReady()
	{
		if !aThreads.MiniMap
			aThreads.MiniMap := AhkDllThread("Included Files\ahkH\AutoHotkey.dll")
		if A_IsCompiled
		{
			if 0 
				FileInstall, threadMiniMapFull.ahk, Ignore
			miniMapScript :=  LoadScriptString("threadMiniMapFull.ahk")
		
		; pObject  & pCriticalSection are passed as cmdline parameter 1 and 2 respectively
			aThreads.MiniMap.ahktextdll(miniMapScript 
				, "", pObject := CriticalObject(aThreads,1) " " pCriticalSection := CriticalObject(aThreads,2) )

		}
		else
			aThreads.MiniMap.ahkdll("threadMiniMap.ahk"
								, "", pObject := CriticalObject(aThreads,1) " " pCriticalSection := CriticalObject(aThreads,2) )
	}
	Return 
}

*/



gSendBM:
sleep 500
text :=
(
"     
  GGG     EEEEE      TTTTT
G             E                  T
G   GG    EEE               T
G      G    E                  T
  GGG     EEEEE          T
  OOO      U       U   TTTTT
O      O    U       U        T
O      O    U       U        T
O      O    U       U        T
  OOO        UUU          T"
)
;input.setTarget("Edit1", "ahk_exe notepad.exe")
thread, Interrupt, off
space := ""
loop, % count := 40
	spaces .= A_space
loop
{
	
	spaces := substr(spaces, 1, -4)
	loop, parse, text, `n
	{
		input.pSend("+{enter}")
		if (A_Index = 1) ; i cant prevent ahk from stripping the spaces on the first line of the text ?? #ltrim doesnt do jack
			input.pSendChars(" ")
		else 
			input.pSendChars(SubStr(spaces A_LoopField , 1, 40))
		input.pSend("{enter}")
	}
	if !strlen(spaces)
		break
	sleep 700
}


gRemoveDamagedUnit:
removeDamagedUnit()
return

; I should really spend more time testing the required delays for this function.
; But it seems to work as is.
removeDamagedUnit()
{
	global RemoveDamagedUnitsHealthLevel, RemoveDamagedUnitsShieldLevel, RemoveDamagedUnitsCtrlGroup, Escape, NextSubgroupKey

	if !getSelectionCount()
		return
	while (GetKeyState("Lbutton", "P") || GetKeyState("Rbutton", "P")) ; This does an important thing in select army function
	{ 																; but here just so APM doesn't skyrocket if user holds right click and function hotkey
		sleep 1
		MouseDown := True
	}
	critical, 1000
	setLowLevelInputHooks(True)
	dsleep(30)
	input.pReleaseKeys(True)
	if MouseDown
		dSleep(15) 
	count := numGetSelectionSorted(aSelected)
	blinkSleep := (aLocalPlayer.Race = "Protoss" && aSelected.TabPositions.HasKey(aUnitId.Stalker))

	highHP := [], lowHP := []
	for i, unit in aSelected.units
	{           
		; target filter .HasShields doesn't work! But this is faster anyway
		if (aLocalPlayer["Race"] != "Protoss" && getUnitPercentHP(unit.unitIndex) > RemoveDamagedUnitsHealthLevel) || (aLocalPlayer["Race"] = "Protoss" && getUnitPercentShield(unit.unitIndex) > RemoveDamagedUnitsShieldLevel)
			highHP.insert(unit.unitPortrait) ; removes the high HP/sheld units
		else 
			lowHP.insert(unit.unitPortrait) 	
	}
	if lowHP.MaxIndex()
	{
		if isCastingReticleActive() 	; so can deselect units if attacking reticle was present
			input.pSend(Escape) 		; is a dsleep() >= 15 is performed after select army key is pressed this is not required - 12isnt enough
										; as SC will have enough time to get rid of the selection reticle itself		
		timerGrouping := stopwatch()
		input.pSend(aAGHotkeys.set[RemoveDamagedUnitsCtrlGroup])
		reverseArray(highHP)
		clickUnitPortraits(highHP) 	; remove high HP units

		; I would have thought a delay would be required here.
		; To prevent the removed highHP units being rallied with the reaming lowHP
		; but this doesn't seem to be the case - though in a real game/game-lag it is probably true.
		; But I've added one anyway.
		; Since i've added blink I should definitely have some sort of delay
		while (getSelectionCount() != count - highHP.MaxIndex() && A_Index < 35)
			dsleep(1)
		dSleep(10) ; Add a static delay just in case.
		if blinkSleep ; in case removing lots of units and trying to cast blink sleep a bit longer
			dSleep(10)
		numGetSelectionSorted(aSelected)
		if aSelected.TabPositions.HasKey(aUnitId.Stalker)
		{
			clickCommandCard(10, x, y)
			; left click the spell, left click to cast, right click to cause stalkers to move the remainder of the distance and for the rest of the units to move
			input.pSend(sRepeat(NextSubgroupKey, aSelected.TabPositions[aUnitId.Stalker]) "{click " x ", " y "}{Click}{Click Right}")
		}
		else input.pSend("{Click Right}")

		input.pSend(aAGHotkeys.Invoke[RemoveDamagedUnitsCtrlGroup]) 	; restore initial selection
		; If a unit dies then this could stall for ~50ms. Not a big issue.
		; But this is certainly a possibility. When deselecting 13 units
		; (of all types) from 135 it will take 110-120 ms to get here.
		while (getSelectionCount() != count && A_Index < 50)
		|| (stopwatch(timerGrouping, False) < 20)
			dsleep(1)
		dSleep(15)
		reverseArray(lowHP)
		clickUnitPortraits(lowHP) 	; remove damaged units
		clickSelectionPage(1)
		dSleep(15)
		stopwatch(timerGrouping)
	}
	Input.revertKeyState()
	setLowLevelInputHooks(False)
	critical, off
	Thread, Priority, -2147483648
	sleep, -1
	sleep 20 
	return	
}

/*
camera coordinates are for the center of the view port/trapezoid
1920 x 1080
top left
63.378906, 54.691406
44.577881, 66.588379
===============
top Right
63.378906, 54.691406
81.734131, 66.017822
===============
bot Right
63.378906, 54.691406
77.188232, 48.567383
===============

camera coordinates are relative to the centre of the view port/trapezoid
so a unit at the bottom will have a higher y position than the camy
and unit on right
width = 38
height = 18
*/

isUnitInView(unit)
{
	uX := getUnitPositionX(unit)
	, uY := getUnitPositiony(unit)
	, cX := getPlayerCameraPositionX()
	, cY := getPlayerCameraPositionY()
	; (ABS(cX - ux) <= 18
		x := cx - ux
		y := cY - uY
	if (y >= -12 && y <= 7) && (x >= -18 && x <= 18) 
		r := 1
	else 
		r := 0
	;	clipboard .= "`n" R
	Return r
}

return 
;clipboard := ""
unit := getSelectedUnitIndex()
	uX := getUnitPositionX(unit)
	, uY:= getUnitPositiony(unit)
	, cX := getPlayerCameraPositionX()
	, cY := getPlayerCameraPositionY()
;clipboard .= cX ", " cY "`n" uX ", " uY "`n==============="
return 



;a1 := input.pSend("+{click D L 0 0}+{Click U L 1920 1080}")
;input.pSend("{F2}")
;sleep(250)
;a3 := input.pSend("+{click D L 0 0}+{Click U L 1920 1080}")
;input.pClickDrag(0,0,A_ScreenWidth,A_ScreenHeight, "L", "+", 1)

;input.pSend(" +{click D L 0 0}{Click U L 1920 1080}")
;input.pSend("{click D R " 0 " " 0 "}{Click U R " A_ScreenWidth " "  A_ScreenHeight "}")

/*
 U 1920 1080
 U R 1920 1080

 r 
 m 
 x1 
 x2
 WheelUp 
 wu 
 WheelDown
 wd
 else 
 left

 +{click D L 0 0}{Click U L 1920 1080}

 */
/*

f1::
send {f5}
return 
sleep 100
v := ReadMemory(B_iFkeys, GameIdentifier, 2)
send {f5 Up}
msgbox % v
return 

A
*/

; force will release any logically down key
; which would be useful if a key is stuck and its a hotkey as well, so it
; cant be released by the user 
; without force it won't be released if it's currently being pressed 
; Since this is only called from emergency restart/release routine, 
; this ensures that if a stuck key is one which forms that hotkey, it will be released even
; if it's being pressed.

releaseLogicallyStuckKeys(force := false)
{
    static aKeys := []
    ; returns and array of unmodified keys
    if !aKeys.maxindex()
        aKeys := getAllKeyboardAndMouseKeys()
    ; use GetAsyncKeyState. Its slower, but will reveal correct state the OS beleives the key is in
    ; I've never seen AHk get it wrong (it is possible) but AHK will not know a key is down
    ; if it starts while the key is already logically down (and its not repeating ie an injected key down)
    ; this is mainly so the program will correctly clear any stuck keys on startup - before getKeystate/ahk
    ; correctly knows their state.

    ; I'm not sure if the above is true - regarding AHK not knowing the keystate when loaded
    for index, key in aKeys
    {
    	if (force && GetAsyncKeyState(key)) || (!force && GetAsyncKeyState(key) && !getkeystate(key, "P"))
        	s .= "{" key " Up}"   
    }
    if s
    	send, % "{blind}" s
    ;   send("{blind}" s)
     return s
}
GetAsyncKeyState(key)
{
    return 0x8000 & DllCall("GetAsyncKeyState", "UInt", getkeyVk(key), "Short") ? 1 : 0
}

/*
This type of send should no longer be required. 
As the custom LL hooks are only installed during automations
send(sequence)
{
    if (state := setLowLevelInputHooks(False, True)) ; get the state
        setLowLevelInputHooks(false)
    send %sequence% 
    if state
        setLowLevelInputHooks(True)
    return 
}
*/

reloadHooks()
{
    if (state := setLowLevelInputHooks(False, True)) ; get the state
    {
        setLowLevelInputHooks(false)
    	setLowLevelInputHooks(True)
	}
	return state
}



g_testKeydowns:
ListLines, on
t1 := A_mtTimeIdle
sleep 2000
str :=  "`n`n|" t1 " | " A_mtTimeIdle
		. "`n`nLogical: " debugAllKeyStates(True, False) 
		. "`n`nPhysical: " debugAllKeyStates(False, True) 
		. "`n`n" debugSCKeyState() 
critical, 1000
releasedKeys := input.pReleaseKeys(True)
;input.RevertKeyState()
critical, off
msgbox % "Released keys: " releasedKeys . str
return
sleep 2000
testdebug := True
return 

debugAllKeyStates(logical := True, physical := True)
{
	for index, key in getAllKeyboardAndMouseKeys(), lCount := pCount := 0	
	{
		if (logical && getkeystate(key))
			logKeys .= key "`n", lCount++
		if (physical && getkeystate(key, "P"))
			phyKeys .= key "`n", pCount++	
	}
	if logical
		s .= "Logical Count: " lCount "`n" logKeys 
	if physical
		s .= (logical ? "`n=========`n`n" : "") "Physical Count: " pCount "`n" phyKeys
	return s
}

; 0.005299 - Actual time spent inside postmessage send loop  (input.psend("abcdefg213123123123123132123123123"))
; 0.688191 - ControlSend, , abcdefg, StarCraft II
; 0.667340 - ControlSend, , a, StarCraft II
; 0.105186 - input.psend("a")
; 0.681377 - input.psend("abcdefg")


;755
; 12
; 5
; 204
; 109ms
; 698 if NA isnt present

/*
 for units on top of each other clicking the same border edge location twice will unload 1, then the other
 this is not true for units horizontally next to each other
 The portraits are close enough to being square for all resolutions
*/

getCargoPos(position, byRef xPos, byRef yPos)
{
	static AspectRatio, x, y, width, supported := True
	if (AspectRatio != newAspectRatio := getScreenAspectRatio())
	{
		supported := True
		AspectRatio := newAspectRatio
		If (AspectRatio = "16:10")
			x := (714/1680)*A_ScreenWidth, y := (914/1050)*A_ScreenHeight, width := 56  ; h := 55 
		else If (AspectRatio = "5:4")
			x := (525/1280)*A_ScreenWidth, y := (901/1024)*A_ScreenHeight, width := 50  ; h := 50 
		else If (AspectRatio = "4:3")	
			x := (524/1280)*A_ScreenWidth, y := (836/960)*A_ScreenHeight, width := 51  ; h := 50 close enough to being square
		else if (AspectRatio = "16:9")
			x := (830/1920)*A_ScreenWidth, y := (939/1080)*A_ScreenHeight, width := 57 ; h = 56 close enough to being square
		else supported := false 
	}
	if supported
	{
		column := floor(position/2)
	 	, row := floor(position - 2 * column)
		, xPos := x + (column * width) + (width//2)
		, yPos := y + (row * width + width//2)
		return True
	}
	return False
}

UnloadAllTransports:
; without UnloadAllTransportsFlagActive, once the user presses the hotkey twice, each press after that would
; also activate the function. This flag ensures that the function requires two key presses within 250ms to activate each time
; This helps reduce reactivating the function accidentally and increasing the recorded apm more than what is required
if (A_PriorHotkey = A_ThisHotkey && A_TimeSincePriorHotkey <= 250 && UnloadAllTransportsFlagActive)
{
	unloadAllTransports(gethotkeySuffix(A_ThisHotkey))
	UnloadAllTransportsFlagActive := False
}
else 
{
	UnloadAllTransportsFlagActive := True
	keywait, % gethotkeySuffix(A_ThisHotkey), T.260 ; Make it slightly longer than the threshold to enter the routine in case just holding it down
}
return 


; Don't bother working out were a unit is in the cargo - if the transport has cargo just click all positions.

; This function will make the apm sky rocket for an instant. It will double the required apm if user invokes it multiple
; time by spamming the hotkey.

unloadAllTransports(hotkeySuffix)
{ 	global escape, EasyUnloadStorageKey

	numGetSelectionSorted(aSelection)

	if aLocalPlayer.Race = "Terran" && (!aSelection.TabPositions.HasKey(aUnitID.Medivac) || aSelection.TabPositions[aUnitID.Medivac] != aSelection.HighlightedGroup)
	 	return	
	else if aLocalPlayer.Race = "Protoss" && ((!aSelection.TabPositions.HasKey(aUnitID.WarpPrism) || aSelection.TabPositions[aUnitID.WarpPrism] != aSelection.HighlightedGroup)
	&& (!aSelection.TabPositions.HasKey(aUnitID.WarpPrismPhasing) || aSelection.TabPositions[aUnitID.WarpPrismPhasing] != aSelection.HighlightedGroup))
		return
	else if aLocalPlayer.Race = "Zerg" && (!aSelection.TabPositions.HasKey(aUnitID.overlord) || aSelection.TabPositions[aUnitID.overlord] != aSelection.HighlightedGroup)
		return

	HighlightedTab := aSelection.HighlightedGroup
	loop, 8
		getCargoPos(A_Index - 1, xPos, yPos), unloadAllCargoString .= "{click " xPos ", " yPos "}"
	
	critical, 1000
	setLowLevelInputHooks(True)
	dsleep(30)
	input.pReleaseKeys(True)

	; The isUnloading doesn't update fast enough to prevent extra apm due to user spamming the hotkey
	; and triggering the function again

	if aSelection.Count = 1 && getCargoCount(aSelection.Units.1.UnitIndex, isUnloading) && !isUnloading
		input.pSend(unloadAllCargoString escape) ; send Escape as we should try to remove the casting reticle invoked my pressing the hotkey ability
	else if aSelection.Count > 1
	{
		input.pSend(escape)
		aUnloaded := []
		input.pSend(aAGHotkeys.Set[EasyUnloadStorageKey])
		slectionCount := aSelection.Count
		loop, 40
		{
			if A_index > 1
			{
				input.pSend("{click 0 0}" aAGHotkeys.Invoke[EasyUnloadStorageKey]) ; clicking screen prevents camera focus when invoking the control group multiple times
				while getselectionCount() != slectionCount && A_Index <= 40
					dsleep(1)
				dsleep(10)
				;numGetSelectionSorted(aSelection) ; should be fast enough not to need to call this
			} 
			for i, unit in aSelection.Units 
			{
				
				if !aUnloaded.HasKey(unit.UnitIndex) && isUnitLocallyOwned(unit.unitIndex)
				&& ((type := getUnitType(unit.unitIndex)) = aUnitId.Medivac
				|| type = aUnitID.WarpPrism || type = aUnitID.WarpPrismPhasing || type = aUnitID.overlord)
				&& getCargoCount(unit.UnitIndex, isUnloading) && !isUnloading
				{
					aUnloaded[unit.UnitIndex] := True
					clickUnitPortraits([unit.unitPortrait], "") ; just left click it 
					while getSelectionCount() != 1 && A_Index <= 40
						dsleep(1)
					 dsleep(10)
					input.pSend(unloadAllCargoString)
					break
				} 
				else if aSelection.Units.MaxIndex() = i
					break, 2
				aUnloaded[unit.UnitIndex] := True ; Assign for non medivac units too (so they wont have to do the function calls the next time around)
			}
		}
		input.pSend("{click 0 0}" aAGHotkeys.Invoke[EasyUnloadStorageKey])
	}
	setLowLevelInputHooks(False)
	critical, off
	Thread, Priority, -2147483648		
	keywait, %hotkeySuffix%
	return
}



; Global Stim

#If, !A_IsCompiled && WinActive(GameIdentifier) && isPlaying && aLocalPlayer.Race = "Terran" && !isMenuOpen()
&& numGetSelectionSorted(aSelection) && (aSelection.TabPositions.HasKey(aUnitID["Marauder"]) || aSelection.TabPositions.HasKey(aUnitID["Marine"]))
&& (aSelection.HighLightedId != aUnitID["SCV"] || !isUserBusyBuilding()) ; This line allows a turret to be built if an scv is in the same selection as a marine/marauder
t::
if aSelection.HighLightedId = aUnitID["Marauder"] || aSelection.HighLightedId = aUnitID["Marine"]
    tabPos := aSelection.HighlightedGroup
else if aSelection.TabPositions.HasKey(aUnitID["Marine"])
    tabPos := aSelection.TabPositions[aUnitID["Marine"]] 
else tabPos := aSelection.TabPositions[aUnitID["Marauder"]] 

if (tabsToSend := tabPos - aSelection.HighlightedGroup) < 0
    send, % "+{tab " abs(tabsToSend) "}t{tab "  abs(tabsToSend) "}"
else send {tab %tabsToSend%}t+{tab %tabsToSend%}
return
#if



AutoBuildGUIkeyPress:
if (AutoBuildGUIkeyMode = "KeyDown")
{
	autoBuildGameGUI.showOverlay()
	autoBuildGameGUI.Refresh() ; If mouse isn't over GUI, this will ensure any previously highlighted unit is unhighlighted
	KeyWait, % gethotkeySuffix(A_ThisHotkey), T30
	autoBuildGameGUI.hideOverlay()
}
else autoBuildGameGUI.toggleOverlay()
return 


AutoBuildGUIInteractkeyPress:
autoBuildGameGUI.showOverlay() ; ensure overlay exists - refreshing the overlay before it exists could cause issues
autoBuildGameGUI.interact(true)
autoBuildGameGUI.Refresh() ; If mouse isn't over GUI, this will ensure the transparency Changes
KeyWait, % gethotkeySuffix(A_ThisHotkey), T30
autoBuildGameGUI.interact(false)
autoBuildGameGUI.Refresh() ; If mouse isn't over GUI, this will ensure the transparency Changes
return 

LaunchAutoBuildEditor:
autoBuild.profileEditor()
return 

autoBuildHotkeyPress:
autoBuild.invokeProfile(A_ThisHotkey "")
return 

autoBuildPauseHotkeyPress:
autoBuild.pause()
autoBuild.updateInGameGUIUnitState() ; also updates the in-game GUI
return 

autoBuildTimer:
if !gettime()
	SetTimer, autoBuildTimer, Off 
else autoBuild.build(aLocalPlayer.Race)
return


#Include, Included Files\class_AutoBuildGameGUI.ahk
class autoBuild
{
	static oAutoBuild, oProfiles := []
	, terranAutoBuildControls := "Marine|Reaper|Marauder|Ghost|Hellion|WidowMine|SiegeTank|HellBat|Thor|VikingFighter|Medivac|Raven|Banshee|Battlecruiser"
	, protossAutoBuildControls := "Zealot|Sentry|Stalker|HighTemplar|DarkTemplar|Phoenix|Oracle|VoidRay|Tempest|Carrier|Observer|WarpPrism|Immortal|Colossus"
	, zergAutoBuildControls := "Queen"	
	, oInvokedProfiles := []
	, timerFreq := 500
	, isPaused := False
	profileEditor() 
	{
		static
		global autoBuildGUIMarine, autoBuildGUIMarauder, autoBuildGUIReaper, autoBuildGUIGhost, autoBuildGUIHellion, autoBuildGUIWidowMine, autoBuildGUISiegeTank, autoBuildGUIHellBat, autoBuildGUIThor
		, autoBuildGUIVikingFighter, autoBuildGUIMedivac, autoBuildGUIRaven, autoBuildGUIBanshee, autoBuildGUIBattlecruiser, autoBuildGUIZealot, autoBuildGUISentry, autoBuildGUIStalker, autoBuildGUIHighTemplar
		, autoBuildGUIDarkTemplar, autoBuildGUIPhoenix, autoBuildGUIOracle, autoBuildGUIVoidRay, autoBuildGUITempest, autoBuildGUICarrier, autoBuildGUIObserver, autoBuildGUIWarpPrism, autoBuildGUIImmortal, autoBuildGUIColossus
		, autoBuildGUIQueen
		; The suffix / unit names of these controls must match exactly the unit names which are used to build these units
		, AutoBuildGUIProfileName, AutoBuildGUIEditNameButton, AutoBuildGUIEnableHotkey, AutoBuildGUIHotkey, #AutoBuildGUIHotkey, AutoBuildGUIEditHotkeyButton
		, AutoBuildGUIDeleteButton, AutoBuildGUIExclusive

		displayedProfile := displayedRace := ""
		Gui AutoBuild:+LastFoundExist
		IfWinExist 
		{
			WinActivate
			Return 									
		}
		this.oProfilesCopy := autoBuild.readProfiles()
		Gui, AutoBuild:New
		Gui, AutoBuild:+OwnerOptions
		Gui, Options:+Disabled
		Gui -MaximizeBox
		Gui, Add, GroupBox,  w220 h280 section, Auto Build
		Gui, Add, TreeView, xp+20 yp+20 gAutoBuildTree h240 w180
		Gui, Add, Button, xs y+45 w80 h40 gAutoBuildGUISaveChanges, Keep Changes
		Gui, Add, Button, x+20 w80 h40 gAutoBuildGuiClose, Cancel
		

		Gui, Add, GroupBox, ys section w245 h90, Profile 
		Gui, Add, Text, xs+10 yp+25, Name:
		Gui, Add, Edit, x+15 w110 R1 vAutoBuildGUIProfileName 
		Gui, Add, Button, yp-2 x+10 gAutoBuildGUIEditName vAutoBuildGUIEditNameButton hidden, Change 
		Gui, Add, Button, xs+10 yp+37 gAutoBuildNew, New
		Gui, Add, Button, x+15 gAutoBuildTree gAutoBuildGUIDelete vAutoBuildGUIDeleteButton, Delete	

		Gui, Add, GroupBox, xs ys+105 w245 h75, Hotkey 
		Gui, Add, Checkbox, xs+15 yp+25 vAutoBuildGUIEnableHotkey gAutoBuildGUIEditEnableHotkey, Enabled
		Gui, Add, Edit, Readonly yp-2 x+15 center w85 R1 vAutoBuildGUIHotkey 
		Gui, Add, Button, yp-2 x+10 gAutoBuildGUIEditHotkey vAutoBuildGUIEditHotkeyButton, Edit
		Gui, Add, Checkbox, xs+15 y+10 vAutoBuildGUIExclusive gAutoBuildUpdateProfile, Exclusive Profile

		Gui, Add, GroupBox, xs yp+40 w280 h150 section, Units
		Gui, Add, Checkbox, xs+15 ys+25 vAutoBuildGUIMarine Hidden Disabled gAutoBuildUpdateProfile, Marine
		Gui, Add, Checkbox, vAutoBuildGUIMarauder Hidden gAutoBuildUpdateProfile, Marauder
		Gui, Add, Checkbox, vAutoBuildGUIReaper Hidden gAutoBuildUpdateProfile, Reaper
		Gui, Add, Checkbox, vAutoBuildGUIGhost Hidden gAutoBuildUpdateProfile, Ghost

		Gui, Add, Checkbox, xp+90 ys+25 vAutoBuildGUIHellion Hidden gAutoBuildUpdateProfile, Hellion
		Gui, Add, Checkbox, vAutoBuildGUIWidowMine Hidden gAutoBuildUpdateProfile, WidowMine
		Gui, Add, Checkbox, vAutoBuildGUISiegeTank Hidden gAutoBuildUpdateProfile, SiegeTank
		Gui, Add, Checkbox, vAutoBuildGUIHellBat Hidden gAutoBuildUpdateProfile, HellBat
		Gui, Add, Checkbox, vAutoBuildGUIThor Hidden gAutoBuildUpdateProfile, Thor

		Gui, Add, Checkbox, xp+90 ys+25 vautoBuildGUIVikingFighter Hidden gAutoBuildUpdateProfile, Viking
		Gui, Add, Checkbox, vAutoBuildGUIMedivac Hidden gAutoBuildUpdateProfile, Medivac
		Gui, Add, Checkbox, vAutoBuildGUIRaven Hidden gAutoBuildUpdateProfile, Raven
		Gui, Add, Checkbox, vAutoBuildGUIBanshee Hidden, Banshee
		Gui, Add, Checkbox, vAutoBuildGUIBattlecruiser Hidden gAutoBuildUpdateProfile, Battlecruiser

		Gui, Add, Checkbox, xs+15 ys+25 vAutoBuildGUIZealot Hidden gAutoBuildUpdateProfile, Zealot
		Gui, Add, Checkbox, vAutoBuildGUISentry Hidden gAutoBuildUpdateProfile, Sentry		
		Gui, Add, Checkbox, vAutoBuildGUIStalker Hidden gAutoBuildUpdateProfile, Stalker		
		Gui, Add, Checkbox, vAutoBuildGUIHighTemplar Hidden gAutoBuildUpdateProfile, HighTemplar		
		Gui, Add, Checkbox, vAutoBuildGUIDarkTemplar Hidden gAutoBuildUpdateProfile, DarkTemplar	

		Gui, Add, Checkbox, xp+90 ys+25 vAutoBuildGUIPhoenix Hidden gAutoBuildUpdateProfile, Phoenix
		Gui, Add, Checkbox, vAutoBuildGUIOracle Hidden gAutoBuildUpdateProfile, Oracle	
		Gui, Add, Checkbox, vAutoBuildGUIVoidRay Hidden gAutoBuildUpdateProfile, VoidRay	
		Gui, Add, Checkbox, vAutoBuildGUITempest Hidden gAutoBuildUpdateProfile, Tempest	
		Gui, Add, Checkbox, vAutoBuildGUICarrier Hidden gAutoBuildUpdateProfile, Carrier	
			
		Gui, Add, Checkbox, xp+90 ys+25 vAutoBuildGUIObserver Hidden gAutoBuildUpdateProfile, Observer
		Gui, Add, Checkbox, vAutoBuildGUIWarpPrism Hidden gAutoBuildUpdateProfile, WarpPrism	
		Gui, Add, Checkbox, vAutoBuildGUIImmortal Hidden gAutoBuildUpdateProfile, Immortal	
		Gui, Add, Checkbox, vAutoBuildGUIColossus Hidden gAutoBuildUpdateProfile, Colossus	

		Gui, Add, Checkbox, xs+15 ys+25 vAutoBuildGUIQueen Hidden gAutoBuildUpdateProfile, Queen
		TV_Add("Terran",, "Bold")
		TV_Add("Protoss",, "Bold")
		TV_Add("Zerg",, "Bold")
		this.insertProfilesIntoGUI(this.oProfilesCopy)
		Gui, Show, w650 h455, Auto Build
		return 

		AutoBuildTree:
		selectedID := TV_GetSelection()
		TV_GetText(selectedText, selectedID)
		if !TV_GetParent(selectedID) ; must be the top parent. Since only one level no looping is required
		{ 	
			
			; The Terran, protoss, zerg parents have been clicked
			displayedProfile := "" ; no active profile is now being displayed
			displayedRace := selectedText
			autoBuild.GUIBuildGUIShow(displayedRace, True)

		}
		else ; child / profile selected
		{
			if (displayedProfile != selectedText)
			{
				displayedProfile := selectedText
				autoBuild.GUIDisplayProfile(displayedProfile)
			}
		}
		return

		AutoBuildUpdateProfile:
		autoBuild.GUIUpdateDisplayedProfile()
		return

		AutoBuildNew:
		Gui, +OwnDialogs
		GuiControlGet, profileName,, AutoBuildGUIProfileName	
		if result := autoBuild.isInvalidProfileName(profileName := trim(profileName, A_space A_Tab))
		{
			if result = 1
				msgbox Invalid profile name.`nNames must not be purely numeric or blank.
			else if result = 2 
				msgbox That profile name is already in use.
			else msgbox error 
		}
		else autoBuild.GUIcreateProfile(profileName)
		return
		AutoBuildGUIDelete:
		autoBuild.GUIDeleteProfile()
		return

		AutoBuildGUIEditHotkey:
		GuiControlGet, hotkey,, AutoBuildGUIHotkey
		hotkey := HotkeyGUI("AutoBuild", hotkey,, "Select Hotkey:")
		if (hotkey != "")
			GUIControl,, AutoBuildGUIHotkey, %hotkey%
		autoBuild.GUIUpdateDisplayedProfile()	
		return

		AutoBuildGUIEditEnableHotkey:
		GuiControlGet, isChecked,, AutoBuildGUIEnableHotkey
		if isChecked
		{
			GuiControlGet, hotkey,, AutoBuildGUIHotkey
			if (hotkey = "")
			{
				hotkey := HotkeyGUI("AutoBuild", hotkey,, "Select Hotkey:")
				if (hotkey = "") ; user cancelled it. So uncheck enabled
					GuiControl,, AutoBuildGUIEnableHotkey, 0
				GUIControl,, AutoBuildGUIHotkey, %hotkey%
			}
		}
		autoBuild.GUIUpdateDisplayedProfile()	
		return 
		AutoBuildGUIEditName: ; Change the name of a selected profile
		GuiControlGet, newName,, AutoBuildGUIProfileName	
		if result := autoBuild.isInvalidProfileName(newName := trim(newName, A_space A_Tab))
		{
			if result = 1
				msgbox Invalid profile name.`nNames must not be purely numeric or blank.
			else if result = 2 
				msgbox The profile name is already in use.
			else msgbox error 
		}
		else autoBuild.GUIChangeProfileName(newName)
		return	

		AutoBuildGUISaveChanges:
		autoBuild.writeOutProfiles()

		AutoBuildGuiClose:
		AutoBuildGuiEscape:
		Gui, Options:-Disabled
		Gui, Destroy
		return
	}

	GUIcreateProfile(profileName)
	{
		if !isobject(this.oProfilesCopy)
			this.oProfilesCopy := []
		
		race := this.GUIHighlightedRace(ID)
		if currentProfile := this.autoBuildGUIHighlightedProfile()
			this.oProfilesCopy[profileName] := ObjFullyClone(this.oProfilesCopy[currentProfile])
		else this.oProfilesCopy[profileName] := []
		this.oProfilesCopy[profileName].race := race
		TV_Add(profileName, ID, "select")
		return
	}
	GUIDeleteProfile()
	{
		if currentProfile := this.autoBuildGUIHighlightedProfile(treeViewID)
		{
			this.oProfilesCopy.remove(currentProfile)
			TV_Delete(treeViewID)
		}
		return
	}
	GUIChangeProfileName(newName)
	{
		if currentProfile := this.autoBuildGUIHighlightedProfile(treeViewID) ; If a profile is selected
		{
			this.oProfilesCopy[newName] := this.oProfilesCopy[currentProfile] 
			this.oProfilesCopy.Remove(currentProfile)
			TV_Modify(treeViewID,, newName)
		}
		return
	}
	GUIUpdateDisplayedProfile()
	{
		race := this.GUIHighlightedRace()
		if race = terran 
			unitControls := this.terranAutoBuildControls
		else if race = protoss
			unitControls := this.protossAutoBuildControls
		else unitControls := this.zergAutoBuildControls	
		profileName := this.autoBuildGUIHighlightedProfile()
		this.oProfilesCopy[profileName].units := ""
		enabledCount := 0
		for i, controlVarName in strsplit(unitControls, "|")
		{
			StringReplace, realUnitName, controlVarName, AutoBuildGUI ; remove "AutoBuildGUI" from AutoBuildGUIMarine
			GuiControlGet, enabled,, AutoBuildGUI%controlVarName%
			if enabled
				this.oProfilesCopy[profileName].units .= realUnitName "|", enabledCount++
		}
		this.oProfilesCopy[profileName].units := SubStr(this.oProfilesCopy[profileName].units, 1, -1)		
		GuiControlGet, enabled,, AutoBuildGUIEnableHotkey
		this.oProfilesCopy[profileName].HotkeyEnabled := enabled
		GuiControlGet, hotkey,, AutoBuildGUIHotkey
		this.oProfilesCopy[profileName].Hotkey := hotkey
		GuiControlGet, ExclusiveMode,, AutoBuildGUIExclusive
		if (enabledCount > 1 && !ExclusiveMode) ; hotkeys with more than one unit must be exclusive
		{
			ExclusiveMode := 1 
			GuiControl,, AutoBuildGUIExclusive, 1
		}
		this.oProfilesCopy[profileName].Exclusive := ExclusiveMode
		return 
	}
	isInvalidProfileName(name)
	{
		if (name = "")
			return 1
		if name is number ; Easier way to prevent issues with nubmer only names ie objRemove() issues
			return 1
		for profileName in this.oProfilesCopy
		{
			if (name = profileName)
				return 2
		}
		return False
	}
	GUIHighlightedRace(byRef parentID := "")
	{
		selectedID := TV_GetSelection()
		if !parentID := TV_GetParent(selectedID) 
			parentID := selectedID
		TV_GetText(raceText, parentID)
		return raceText
	}
	autoBuildGUIHighlightedProfile(byRef treeViewID := "")
	{
		treeViewID := TV_GetSelection()
		if !TV_GetParent(treeViewID)
			return ; A race is selected not a profile
		TV_GetText(profileName, treeViewID)
		return profileName
	}	
	GUIBuildGUIShow(race, disable := False)
	{
		if race = terran
			showControls := this.terranAutoBuildControls, hideControls := this.protossAutoBuildControls "|" this.zergAutoBuildControls
		else if race = protoss
		 	showControls := this.protossAutoBuildControls, hideControls := this.terranAutoBuildControls "|" this.zergAutoBuildControls
		else showControls := this.zergAutoBuildControls, hideControls := this.terranAutoBuildControls "|" this.protossAutoBuildControls
		GuiControl,, AutoBuildGUIProfileName,
		GuiControl,, AutoBuildGUIHotkey,
		GuiControl, disable%disable%, AutoBuildGUIHotkey,
		GuiControl,, AutoBuildGUIEnableHotkey, 0
		GuiControl, disable%disable%, AutoBuildGUIEnableHotkey, 0
		
		GuiControl, disable%disable%, AutoBuildGUIEditHotkeyButton, 0
		GuiControl, disable%disable%, AutoBuildGUIDeleteButton, 0
		GuiControl, % "show" (!disable), AutoBuildGUIEditNameButton ; Should only be visible when a profile is selected

		GuiControl, disable%disable%, AutoBuildGUIExclusive

		loop, parse, showControls, |
		{
			GuiControlGet, isVisible, AutoBuild:Visible, AutoBuildGUI%A_LoopField%
			GuiControl,, AutoBuildGUI%A_LoopField%, 0
			GuiControl, disable%disable%, AutoBuildGUI%A_LoopField%
			if isVisible = 0 ; use = 0 so if it fails for some reason (shouldnt occur) it wont show it as isVisible will be null
				GuiControl, AutoBuild:show, AutoBuildGUI%A_LoopField%
		}	
		loop, parse, hideControls, |
		{
			GuiControlGet, isVisible, AutoBuild:Visible, AutoBuildGUI%A_LoopField%
			if isVisible = 1
				GuiControl, AutoBuild:Hide, AutoBuildGUI%A_LoopField%
		}			
	}
	GUIDisplayProfile(profileName)
	{
		this.GUIBuildGUIShow(this.oProfilesCopy[profileName].race)
		for i, controlSuffix in strsplit(this.oProfilesCopy[profileName].units, "|")
		{
			GuiControl,, AutoBuildGUI%controlSuffix%, 1
			enlabledCount++
		}
		GuiControl,, AutoBuildGUIProfileName, %profileName%
		GuiControl,, AutoBuildGUIEnableHotkey, % round(this.oProfilesCopy[profileName].HotkeyEnabled)
		GuiControl,, AutoBuildGUIHotkey, % this.oProfilesCopy[profileName].Hotkey
		if this.oProfilesCopy[profileName].Exclusive = "" ; Not set, so lets make exclusive default
			this.oProfilesCopy[profileName].Exclusive := True
		if enlabledCount > 1
			this.oProfilesCopy[profileName].Exclusive := True
		GuiControl,, AutoBuildGUIExclusive, % round(this.oProfilesCopy[profileName].Exclusive)
		return 
	}
	autoBuildDisplayUncheckAll()
	{
		for i, controlSuffix in strsplit(this.terranAutoBuildControls "|" this.protossAutoBuildControls "|" this.zergAutoBuildControls, "|")
				GuiControl,, AutoBuildGUI%controlSuffix%, 0
		return
	}
	autoBuildProfileEditorEnabledControls(byRef aEnabledControls := "")
	{
		aEnabledControls := []
		race := this.GUIHighlightedRace()
		if race = Terran 
			controls := "terranAutoBuildControls"
		else if race = Protoss 
			controls := "protossAutoBuildControls"
		else if race = Zerg 
			controls := "zergAutoBuildControls" 
		else return 
		for i, controlSuffix in strsplit(this[controls], "|")
		{
			GuiControlGet, enabled,, AutoBuildGUI%controlSuffix%
			if enabled
				aEnabledControls.insert("AutoBuildGUI" controlSuffix)
		}
		return round(aEnabledControls)
	}

	insertProfilesIntoGUI(oProfiles)
	{
		raceID := [], raceID.terran := TV_GetNext(), raceID.protoss := TV_GetNext(raceID.terran), raceID.zerg := TV_GetNext(raceID.protoss)
		for profileName, oProfile in oProfiles
			TV_Add(profileName, raceID[oProfile.race])
		return
	}
	writeOutProfiles()
	{
		IniWrite, % serDes(this.oProfilesCopy), %config_file%, AutoBuild, hotkeyProfiles
		this.oProfiles := this.oProfilesCopy ; Need to test this
	}
	readProfiles()
	{
		IniRead, serdes, %config_file%, AutoBuild, hotkeyProfiles, 1
		if !isobject(obj := serDes(serdes))
			obj := []
		return obj
	}
	createHotkeys(race)
	{
		Hotkey, If, WinActive(GameIdentifier) && isPlaying && !isMenuOpen()
		for profileName, profile in this.oProfiles := this.readProfiles()
		{
			if profile.hotkeyenabled && race = profile.race && profile.Units != ""
				try hotkey, % profile.hotkey, autoBuildHotkeyPress, on
		}
		Hotkey, If
		return
	}
	disableHotkeys()
	{
		Hotkey, If, WinActive(GameIdentifier) && isPlaying && !isMenuOpen()
		for profileName, profile in this.oProfiles
			try hotkey, % profile.hotkey, off
		Hotkey, If
		return
	}
	; Need to add method to selectively disable units and return true false indicating if timer should be disabled
	; and hotkey active status of all them to be reset
	invokeProfile(hotkey)
	{
		for profileName, profile in this.oProfiles 
		{
			if profile.hotkey "" = hotkey && profile.HotkeyEnabled
			{
				if profile.exclusive
				{ 
					; If another profile is active or none. Enable only this profile
					if this.ActiveHotkeyProfile != profileName
					{
						this.ActiveHotkeyProfile := profileName
						this.invokeUnits(profile.units, profile.exclusive)
						SoundPlay, %A_Temp%\On.wav	
					}
					else 
					{
						this.ActiveHotkeyProfile := ""
						this.disableUnits(profile.units)
						SoundPlay, %A_Temp%\Off.wav
					}
				}
				else ; Can only have one unit in the profile if not exclusive mode
				{
					; deactivate any exclusive profiles. Consequently when that profile key is pressed again 
					; it will effectively turn on those units again (even if there were on), but disable any others
					this.ActiveHotkeyProfile := "" 
					if this.isUnitActive(profile.units)
					{
						this.disableUnits(profile.units) 
						SoundPlay, %A_Temp%\Off.wav
					}
					else 
					{
						this.invokeUnits(profile.units, 0)
						SoundPlay, %A_Temp%\On.wav	
					}
				}
				this.updateInGameGUIUnitState()
				break				
			}
		}
		return
	}

	; null toggles current state
	; 1 pauses production 
	; 0 unpauses
	; Ignored if no units are active
	pause(pauseProduction := "")
	{
		if !this.updateStructureState()
			this.isPaused := True
		else if (pauseProduction = "")
			this.isPaused := !this.isPaused
		else this.isPaused := (pauseProduction != 0)
		if this.isPaused
			settimer, autoBuildTimer, off
		else settimer, autoBuildTimer, % this.timerFreq	
		return this.isPaused
	}
	; If click in games GUI immediately reset the active state of the profile
	resetProfileState()
	{
		this.ActiveHotkeyProfile := ""
		return
	}
	; unit names is a pipe delimited list
	; Disables all units and enables the passed units
	invokeUnits(unitNames := "", disableCurrent := True) 
	{
		if disableCurrent
			this.disableUnits()
		for i, unitName in StrSplit(trim(unitNames, "|" A_Space A_Tab), "|")
		{
			if unitName = queen 
			{
				this.oAutoBuild.Zerg.hatchery.autoBuild := this.oAutoBuild.Zerg.hatchery.units[unitName].autoBuild := True
				this.oAutoBuild.Zerg.lair.autoBuild := this.oAutoBuild.Zerg.lair.units[unitName].autoBuild := True
				this.oAutoBuild.Zerg.hive.autoBuild := this.oAutoBuild.Zerg.hive.units[unitName].autoBuild := True
			}
			else if structure := this.getStructureFromUnitName(unitName)
			{
				race := this.getRaceFromUnitName(unitName)
				this.oAutoBuild[race, structure].autoBuild := this.oAutoBuild[race, structure].units[unitName].autoBuild := True	
			}	 
		}
		this.isPaused := False
		settimer, autoBuildTimer, % this.timerFreq	
		return
	}
	updateInGameGUIUnitState()
	{
		global EnableAutoWorkerTerran, EnableAutoWorkerProtoss
		race := aLocalPlayer.Race 
		for structureName, structure in this.oAutoBuild[race]
		{
			for unitName, unit in this.oAutoBuild[race, structureName].units 
			{
				if unit.autoBuild
					list .= unitName ","
			}
		}
		if (EnableAutoWorkerTerran && race = "Terran")
			list .= "SCV,"
		else (EnableAutoWorkerProtoss && race = "Protoss")
			list .= "Probe,"
		list := SubStr(list, 1, -1)
		autoBuildGameGUI.enableItems(list) ; pass a Comma list of enabled units
		return 
	}
	disableUnits(units := "")
	{
		StringReplace, units, units, |, `,, All
		units := trim(units, A_Space ",")
		structures := "Barracks|Factory|Starport|Gateway|Stargate|RoboticsFacility|Hatchery|Lair|Hive"
		loop, parse, structures, |
		{
			structure := A_LoopField
			race := this.getRaceFromUnitName(structure)
			for unitName, unit in this.oAutoBuild[race, structure].units
			{
				if (units = "")
					unit.autoBuild := False
				else if unitName in %units%
					unit.autoBuild := False
			}
		}
		if !areUnitsActive := this.updateStructureState()
		{ 
			settimer, autoBuildTimer, off
			this.isPaused := True
		}
		return areUnitsActive
	}
	; Returns false if no units are active
	updateStructureState()
	{
		structures := "Barracks|Factory|Starport|Gateway|Stargate|RoboticsFacility|Hatchery|Lair|Hive"
		hasActiveUnits := False
		loop, parse, structures, |
		{
			structure := A_LoopField
			race := this.getRaceFromUnitName(structure)
			turnOff := True
			for unitName, unit in this.oAutoBuild[race, structure].units
			{
				if unit.autoBuild
				{
					hasActiveUnits := True
					turnOff := false
					break 
				}
			}
			if turnOff
				this.oAutoBuild[race, structure].autoBuild := False
		}
		return hasActiveUnits		
	}
	disableAllUnits()
	{
		structures := "Barracks|Factory|Starport|Gateway|Stargate|RoboticsFacility|Hatchery|Lair|Hive"
		loop, parse, structures, |
		{
			structure := A_LoopField
			race := this.getRaceFromUnitName(structure)
			this.oAutoBuild[race, structure].autoBuild := False 
			for unitName, unit in this.oAutoBuild[race, structure].units
				unit.autoBuild := False
		}
		settimer, autoBuildTimer, off
		return
	}
	isUnitActive(unitName)
	{
		unitName := trim(unitName, "|" A_Space A_Tab)
		if (unitName = "Queen")
			return this.oAutoBuild.Zerg.hatchery.units[unitName, "autoBuild"]
		else 
		{
			structure := this.getStructureFromUnitName(unitName)
			race := this.getRaceFromUnitName(structure)
			return this.oAutoBuild[race, structure, "units", unitName, "autoBuild"]
		}
	}
	isStructureActive(structure)
	{
		structure := trim(structure, "|" A_Space A_Tab)
		if this.getRaceFromStructureName(structure) = "Zerg"
			return this.oAutoBuild.Zerg.hatchery["autoBuild"]
		else return this.oAutoBuild[this.getRaceFromUnitName(structure), structure, "autoBuild"]
	}
	getActiveUnits()
	{
		for structureName in this.oAutoBuild[aLocalPlayer.Race]
		{
			for unitName, unit in this.oAutoBuild[aLocalPlayer.Race, structureName, "units"]
			{
				if unit.autoBuild 
					s .= unitName ","
			}
		}
		return SubStr(s, 1, -1)
	}
	getRaceFromStructureName(structureName)
	{
		if structureName in Barracks,Factory,Starport
			return "Terran"		
		if structureName in Gateway,Stargate,RoboticsFacility
			return "Protoss"				
		if structureName in Hatchery,Lair,Hive
			return "Zerg"
		return
	}
	getRaceFromUnitName(unitName)
	{
		if unitName in marine,reaper,marauder,ghost,hellion,widowMine,siegeTank,hellBat,thor,VikingFighter,Medivac,Raven,Banshee,Battlecruiser,Barracks,Factory,Starport
			return "Terran"
		if unitName in Zealot,Sentry,Stalker,HighTemplar,DarkTemplar,Phoenix,Oracle,VoidRay,Tempest,Carrier,Observer,WarpPrism,Immortal,Colossus,Gateway,Stargate,RoboticsFacility
			return "Protoss"	
		if unitName in Queen,Hatchery,Lair,Hive
			return "Zerg"		
		return
	}
	; don't pass queen to this function
	getStructureFromUnitName(unitName)
	{
		if unitName in marine,reaper,marauder,ghost
			return "barracks"
		if unitName in hellion,widowMine,siegeTank,hellBat,thor
			return "factory"
		if unitName in VikingFighter,Medivac,Raven,Banshee,Battlecruiser
			return "starport"
		if unitName in Zealot,Sentry,Stalker,HighTemplar,DarkTemplar
			return "Gateway"	
		if unitName in Phoenix,Oracle,VoidRay,Tempest,Carrier
			return "Stargate"		
		if unitName in Observer,WarpPrism,Immortal,Colossus
			return "RoboticsFacility"	
		return
	}

	getProductionObject()
	{
		unitTableTerran := "
		( ltrim c ;			techlab 	minerals 	vespene 	supply 		Req. structure		hotkeyReference 				StructureName/lookup
			marine 			|0 			|50 		|0 			|1 			|					|Marine/Barracks 				|Barracks
			reaper 			|0 			|50 		|50 		|1 			|					|Reaper/Barracks 				|Barracks
			marauder 		|1 			|100 		|25 		|2  		|					|Marauder/Barracks 				|Barracks
			ghost 			|1 			|200 		|100 		|2 			|GhostAcademy		|Ghost/Barracks  	    		|Barracks	
			hellion 		|0 			|100 		|0 			|2 			| 					|Hellion/Factory 				|Factory
			widowMine 		|0 			|75 		|25			|2 			| 					|WidowMine/Factory 				|Factory
			siegeTank 		|1 			|150 		|125		|3 			| 					|SiegeTank/Factory 				|Factory
			hellBat 		|0 			|100 		|0 			|2			|Armory				|HellionTank/Factory 			|Factory
			thor 			|1 			|300 		|200 		|6			|Armory				|Thor/Factory 					|Factory
			VikingFighter 	|0 			|150 		|75 		|2			|					|VikingFighter/Starport 		|Starport
			Medivac 	 	|0 			|100 		|100 		|2			|					|Medivac/Starport 				|Starport
			Raven 	 		|1 			|100 		|200 		|2			|					|Raven/Starport 				|Starport
			Banshee  		|1 			|150 		|100 		|3			|					|Banshee/Starport 				|Starport
			Battlecruiser	|1 			|400 		|300 		|6			|FusionCore			|Battlecruiser/Starport			|Starport
		)"

		unitTableProtoss := "
		( ltrim c ;			techlab 	minerals 	vespene 	supply 		Req. structure		hotkeyReference 				StructureName/lookup
			Zealot 			|0 			|100 		|0 			|2 			|					|Zealot 		 				|Gateway
			Sentry 			|0 			|50 		|100 		|2 			|CyberneticsCore	|Sentry			 				|Gateway
			Stalker			|0 			|125 		|50 		|2 			|CyberneticsCore	|Stalker		 				|Gateway
			HighTemplar		|0 			|50 		|150 		|2 			|TemplarArchive		|HighTemplar	 				|Gateway
			DarkTemplar		|0 			|125 		|125 		|2 			|DarkShrine			|DarkTemplar	 				|Gateway
			Phoenix			|0 			|250 		|100 		|2 			|					|Phoenix/Stargate 				|Stargate
			Oracle			|0 			|150 		|150 		|3 			|					|Oracle/Stargate 				|Stargate
			VoidRay			|0 			|250 		|150 		|4 			|					|VoidRay/Stargate 				|Stargate
			Tempest			|0 			|300 		|200 		|4 			|FleetBeacon		|Tempest/Stargate 				|Stargate
			Carrier			|0 			|350 		|250 		|6 			|FleetBeacon		|Carrier/Stargate 				|Stargate
			Observer		|0 			|25 		|75 		|1 			|					|Observer/RoboticsFacility 		|RoboticsFacility
			WarpPrism		|0 			|200 		|0 			|2 			|					|WarpPrism/RoboticsFacility 	|RoboticsFacility
			Immortal		|0 			|250 		|100 		|4 			|					|Immortal/RoboticsFacility 		|RoboticsFacility
			Colossus		|0 			|300 		|200 		|6 			|RoboticsBay		|Colossus/RoboticsFacility 		|RoboticsFacility
		)"

		unitTableZerg := "
		( ltrim c ;			techlab 	minerals 	vespene 	supply 		Req. structure		hotkeyReference 				StructureName/lookup
			Queen 			|0 			|150 		|0 			|2 			|SpawningPool		|Queen 		 					|Hatchery
			Queen 			|0 			|150 		|0 			|2 			|SpawningPool		|Queen 		 					|Lair
			Queen 			|0 			|150 		|0 			|2 			|SpawningPool		|Queen 		 					|Hive
		)"
		global AutoBuildBarracksGroup, AutoBuildFactoryGroup, AutoBuildStarportGroup, AutoBuildGatewayGroup, AutoBuildStargateGroup, AutoBuildRoboticsFacilityGroup, AutoBuildHatcheryGroup, AutoBuildLairGroup, AutoBuildHiveGroup
		; Use am ordered array, so that build structures are looped in the listed order - not by alphabetical order
		; Ensure the order of the structures in the table above corresponds to the order in the selection panel (when they are in the same group)
		; i.e. rax, factory, starport 
		; Do not erase this obj or recreate it as a normal one!
		raceObj := []
		for i, race in ["terran", "protoss", "zerg"]
		{
			if race = terran
				units := unitTableTerran
			else if race = protoss
				units := unitTableProtoss
			else units := unitTableZerg
			obj := OrderedArray() ; This is important
			loop, parse, units, `n, %A_Tab%
			{
				a := StrSplit(A_LoopField, "|", A_Tab A_Space)
				if !isobject(obj[a.8]) 
				{
					structure := a.8
					obj[a.8] := [], obj[a.8, "units"] := []
					obj[a.8, "group"] := AutoBuild%structure%Group
					obj[a.8, "autoBuild"] := False
				}
				obj[a.8, "Units", a.1] := []
				;  [barracks, unitType]
				;obj[a.8, "Units", a.1, "buildKey"] := SC2Keys.key(a.7) ; Need to update this once SC loads
				obj[a.8, "Units", a.1, "buildKeyLookup"] := a.7 ; Use a reference and get key from SC2Keys on demand
				obj[a.8, "Units", a.1, "autoBuild"] := False
				obj[a.8, "Units", a.1, "structureLookup"] := a.8
				obj[a.8, "Units", a.1, "raceLookup"] := race
				obj[a.8, "Units", a.1].insert("requires", {"techlab": a.2, "minerals": a.3, "vespene": a.4, "supply": a.5, "structure": aUnitID[a.6]})
			}
			raceObj[race] := obj
		}
		return raceObj
	}
/*
	Object layout
		Terran
			Barracks  					; Structure name. These structures are in FIFO/ordered array. They do NOT iterate alphabetically
				group 					; control group
				autoBuild  				; Has units units which are to be built
				units  					; []
					marine 				; Each barracks unit type has an entry (unit name) 
						autoBuild 		; Is auto build enabled
						requires 		; []
							minerals
							vespene
							supply
							techlab 	; Unit requires a techlab
							structure 	; A required structure to build unit i.e. ghost academy already converted to unitID
						buildKeyLookup  ; Reference name for the sc2keys() production key
					reaper.... 			; []
			Factory......  				; []
		Protoss
			......

*/

	setCurrentResources()
	{
		global autoBuildMinFreeMinerals, autoBuildMinFreeGas, autoBuildMinFreeSupply
		; Subtract these values so that after a build event user is left with a minimum of 
		; the specified values
		this.CurrentMinerals := getPlayerMinerals() - autoBuildMinFreeMinerals
		this.CurrentGas  := getPlayerGas() - autoBuildMinFreeGas
		this.FreeSupply := getPlayerFreeSupply() - autoBuildMinFreeSupply
	}
	copyLocalUnits()
	{
		Obj := []
  		if !TryLockWait(localUnitDataCriSec, 30, 5)
  			return ""
  		thread, notimers, true 
  		for type, indexes in aLocalUnitData
  			Obj[type] := indexes
  		UnLock(localUnitDataCriSec)
  		thread, notimers, false
  		return obj
	}
	canPerformBuild(loops := 15)
	{ 	global automationAPMThreshold
		if isGamePaused() || isMenuOpen()
			return False
		While isUserBusyBuilding() || isCastingReticleActive() 
		|| GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
		|| getkeystate("Enter", "P") 
		|| getkeystate("Tab", "P") 
		|| getPlayerCurrentAPM() > automationAPMThreshold
		;||  A_mtTimeIdle < 50
		{
			if (A_index > loops)
				return False ; (sleep 1 usually = 20ms - so 20*loop count)
			Thread, Priority, -2147483648	
			sleep 1
			Thread, Priority, 0	
		}
		if isGamePaused() || isMenuOpen()
			return false
		return True		
	}

	; checks if has an appropriate tech structure to build a unit e.g. ghost academy for ghosts
	hasUnit(type)
	{
		if this.localUnits.HasKey(type)
		{
			indexes := this.localUnits[type]
			loop, parse, indexes, |
			{ 	; This is a bit overkill. The other thread updates this info ever 1.5 seconds or so
				; and it's not a big deal if it's outdated.... but we are just checking a couple of units so might as well do it
				if getUnitType(A_LoopField) = type 
				&& getUnitOwner(A_LoopField) = aLocalPlayer.slot 
				&& !(getunittargetfilter(A_LoopField) & (aUnitTargetFilter.Dead | aUnitTargetFilter.UnderConstruction))	
					return true
			}
		}
		return false
	}
	; Need to call this at the start of a game to update structure Ctrl Groups in case they changed via GUI
	setBuildObj()
	{
		this.oAutoBuild := this.getProductionObject()
		this.resetProfileState()
		return
	}
	build(race)
	{
		global AutoWorkerAPMProtection

		if (this.tmpDisableAutoBuild || !buildCheck.hasTimeElapsed(1, 3)) ; Check this before doing below, as its only going to get bigger with any delay (although its possible autoWorker could interrupt this thread and result in two build events close together)
			return		
		if !this.canPerformBuild()
			return
		; In case autoWorker interrupted the above function and made something
		; However auto-worker doesn't currently set this value.
		; Perhaps should set function specific values, otherwise they could delay each other by the full specified amounts
		;if !buildCheck.hasTimeElapsed(2, 5) 
		;	return				
		this.setCurrentResources()
		if this.FreeSupply <= 0
			return

		this.localUnits := ""
		 ; if fails to lock thread this won't be an obj, But continue - just won't build units which have requirements
		 ; maybe i should just return
		this.localUnits := this.copyLocalUnits()
		if !isobject(this.localUnits)
			return 
		;buildObj := this.oAutoBuild[race]
		buildObj := this.randomiseAssociativeArray(this.oAutoBuild[race]) ; Randomise the order in which the structures are iterated
		; This is an ordered array, so iterates the structures in the order that they would occur in the selection panel. e.g. rax -> factory -> starport
		; This will reduce number of tabs required and also don't have to worry about tabbing past the end (although thats easy to deal with anyway)
		if isGamePaused() || isMenuOpen() ;chat is 0 when  menu is in focus
			return ;as let the timer continue to check
		for buildingName, item in buildObj
		{
			if item.autoBuild && (buildObj[buildingName].buildString := this.buildFromStructure(buildingName, item.group, item.units, race)) != ""
				buildStuff := True	
			else buildObj[buildingName].buildString := "" ; There's a slim timing window below where if an autoBild item is enabled, it may have a previous build string...might as well prevent it
		}
		if !buildStuff || !this.canPerformBuild(1) || !numGetSelectionSorted(oSelection) || !oSelection.IsGroupable
			return

		Thread, NoTimers, true
		critical, 1000
		setLowLevelInputHooks(True)
		buildCheck.set()
		dsleep(10)
		input.pReleaseKeys(True)
		input.pSend("{shift up}{ctrl up}") ; extra safety. 
		;dSleep(5)	
		storageGroup := automationStorageGroup(aLocalPlayer.Race)
		this.storeSelection(storageGroup, HighlightedGroup, selectionPage)
		
		for buildingName, item in buildObj
		{
			if !item.autoBuild || item.buildString = ""
				continue 
			if item.group != prevGroup
			{
				if (prevGroup = "") ; click to ensure camera doesn't jump. Not required when changing grounds.
					input.psend("{click 0 0}") 
				; A sleep may be required here to prevent the invoked structures from receiving the previously sent buildString 
				this.invokeGroup(item.group, oSelection, currentTab)
				if (prevGroup = "") ; Hasn't been set yet so this is first build event.
					currentTab := getSelectionHighlightedGroup() ; This accounts for the fact if the structure group is already selected, then the highlighted group/tab-position may not be 0
				prevGroup := item.group
			}
			this.buildUnits(item.buildString, oSelection, buildingName, currentTab)
		}
		this.restoreSelection(storageGroup, selectionPage, HighlightedGroup) ;****!

		Input.revertKeyState()
		setLowLevelInputHooks(False)
		critical, off
		Thread, NoTimers, false 
		return
	}
	storeSelection(group, byRef HighlightedGroup, byRef selectionPage)
	{
		HighlightedGroup := getSelectionHighlightedGroup()
		selectionPage := getUnitSelectionPage()	
		input.psend(SC2Keys.key("ControlGroupAssign" group))
		return
	}
	invokeGroup(group, byRef oSelection, byRef currentTab)
	{
		currentTab := 0
		invokeControlGroup(group, 35)
		;dSleep(35) ; 35
		numGetSelectionSorted(oSelection)
		return
	}

	buildUnits(buildString, oSelection, buildingName, byRef currentTab)
	{
		tabPosition := oSelection.TabPositions[aUnitId[buildingName]]
		tabsToSend := tabPosition - currentTab
		currentTab := tabPosition
		if tabsToSend > 0
			tabString := sRepeat(SC2Keys.key("SubgroupNext"), tabsToSend)
		else if tabsToSend < 0
			tabString := sRepeat(SC2Keys.key("SubgroupPrev"), abs(tabsToSend))
		input.psend(tabString buildString)
		return
	}

	; takes a variadic list of arrays. Randomly orders EACH individual array and returns a single combined array.
	; the items of the first array will be first items in the array, the second passed array will be come next in the returned array.....and so on 
	; This is currently just a quick solution to randomise units being produced i.e. seige tank vs thor
	randomOrderIntoSingleArray(arrays*)
	{
		nArray := []
		for i, array in arrays
		{
			aOrder := [] ; using a lookup allows for actual array ref to be passed and not to remove items from it
			for i in array
				aOrder.Insert(i) ; so 1 based
			while aOrder.MaxIndex()
				nArray.Insert(array[aOrder.remove(rand(1, aOrder.MaxIndex()))])
		}
		return nArray
	}
	; Returns an ordered array (array contents are iterated in the order they were created)
	; Randomises the order of an array. Useful for arrays which have non-numeric keys.
	; Key-value associations are maintained.
	randomiseAssociativeArray(sourceObj)
	{
		nObj := OrderedArray(),	aLookUp := []
		for k, v in sourceObj  ; Deal will non-numeric keys
			aLookUp.Insert(k)
		loop, % aLookUp.MaxIndex()
			key := aLookUp.Remove(rand(aLookUp.MinIndex(), aLookUp.MaxIndex())), nObj[key] := sourceObj[key]
		return nObj	
	}

	buildFromStructure(structure, group, obj, race)
	{
		if this.getStructureCountInGroup(group, aUnitID[structure], aUnitIndexs) && this.productionStatus(aUnitIndexs, structure, nonTechLabs, techLabs, race)
		{	
			if !this.getEnabledUnits(obj, aTechLabUnits, aNonTechLabUnits)
				return
			; Currently If marine+marauder is enabled and player only has rax with techlabs, only rauders are made.
			; Could probably add a check here to deal with this - e.g. cmp rax count with tech lab / non-techlab and the type of units to be made
			; For non-terran races aTechLabUnits is empty and techLabs is 0. nonTechLabs will = count of structures with no units (or nearly complete) units in production
			loop, 2 
			{
				aUnits := A_Index = 1 ? aTechLabUnits : aNonTechLabUnits
				while ((aUnits = aTechLabUnits && techLabs) || (aUnits = aNonTechLabUnits && techLabs + nonTechLabs))
				&& (A_Index = 1 || builtSomething)
				{
					;msgbox % A_Index " | " techLabs " | " nonTechLabs
					builtSomething := False 
					; if techlab units loop through tech lab units and build 1 at a time, so can make marauder and ghost in same round
					; if nontech lab loop through and build 1 at a time so marine + reaper can be made and not just one or the other
					for i, name in aUnits
					{
						if obj[name].autoBuild && (!obj[name].requires.structure || this.hasUnit(obj[name].requires.structure))
						&& this.howManyUnitsCanBeProduced(nonTechLabs, techLabs, obj[name].requires, 1) ; limit to 1 e.g. build 1 reaper, then build a marine on next loop  - repeat until done
						{
							builtSomething := True
							sendString .= sRepeat(SC2Keys.key(obj[name].buildKeyLookup), 1)
						}
					}
				}
			}
		}
		;msgbox % sendString " | "
		return sendString	
	}

	getEnabledUnits(obj, byRef aTechLabUnits, byRef aNonTechLabUnits)
	{
		aTechLabUnits := [], aNonTechLabUnits := []
		for unitName, unit in obj 
		{
			if unit.AutoBuild && unit.Requires.techlab 
				aTechLabUnits.insert(unitName)
			else if unit.AutoBuild ; && !unit.Requires.techlab 
				aNonTechLabUnits.insert(unitName)
		}
		if aTechLabUnits.MaxIndex()
			aTechLabUnits := this.randomOrderIntoSingleArray(aTechLabUnits)
		if aNonTechLabUnits.MaxIndex()
			aNonTechLabUnits := this.randomOrderIntoSingleArray(aNonTechLabUnits)		
		return round(aTechLabUnits.MaxIndex()) + round(aNonTechLabUnits.MaxIndex())
	}


	howManyUnitsCanBeProduced(byRef remainingSlots, byRef remainingTechLabSlots, aRequires, maxCount := "")
	{
		params := [], count := 0
		if aRequires.minerals
			params.insert(floor(this.CurrentMinerals / aRequires.minerals))
		if aRequires.vespene	
			params.insert(floor(this.CurrentGas / aRequires.vespene))
		if aRequires.supply
			params.insert(floor(this.FreeSupply / aRequires.supply))
		if aRequires.Techlab
			params.insert(remainingTechLabSlots)
		else params.insert(remainingSlots + remainingTechLabSlots)
		count := lowestValue(params*)

		if (count < 0 || "")
			count := 0 ; shouldnt happen
		else 
		{	
			if (maxCount >= 0 && count > maxCount)
				count := maxCount
			this.CurrentMinerals -= count * aRequires.minerals
			this.CurrentGas -= count * aRequires.vespene
			this.FreeSupply -= count * aRequires.supply
			if aRequires.Techlab
				remainingTechLabSlots -= count 
			else if (remainingSlots -= count) < 0
				remainingTechLabSlots += remainingSlots, remainingSlots := 0
			if remainingSlots < 0
				remainingSlots := 0
			if remainingTechLabSlots < 0
				remainingTechLabSlots := 0
		}	
		return count
	}

	getStructureCountInGroup(group, unitID, byRef aUnitIndexs)
	{
		count := 0, aUnitIndexs := []
		groupSize := getControlGroupCount(Group)
		ReadRawMemory(B_CtrlGroupStructure + S_CtrlGroup * group, GameIdentifier, Memory,  O_scUnitIndex + groupSize * S_scStructure)
		loop, % groupSize 
		{
			fingerPrint := NumGet(Memory, O_scUnitIndex + (A_Index - 1) * S_scStructure, "UInt")
			, unitIndex := fingerPrint >> 18
			if getUnitType(unitIndex) = unitId 
			&& fingerPrint = getUnitFingerPrint(unitIndex)
			&& getUnitOwner(unitIndex) = aLocalPlayer.slot ; dont really need this line. Could remove it to allow production out of an allys buildings (after they left)
			&& !(getunittargetfilter(unitIndex) & (aUnitTargetFilter.Dead | aUnitTargetFilter.UnderConstruction))	
				count++, aUnitIndexs.insert(unitIndex)
		}	
		return count
	}

	; returns total available production slot count
	; and sets the slot count for tech labs and non techlabs (which includes reactors)
	productionStatus(aUnitIndexs, structureName, byRef nonTechLabs, byRef techLabs, race)
	{
		nonTechLabs := techLabs := 0
		for i, unitIndex in aUnitIndexs
		{
			if (race = "terran")
				addon := getAddonStatus(getUnitAbilityPointer(unitIndex), aUnitId[structureName], underConstruction)
			else if (race = "zerg")
				underConstruction := isHatchLairOrSpireMorphing(unitIndex, aUnitId[structureName]) ; Obviously not really under construction

			if !underConstruction
			{
				filledSlots := this.filledSlotCount(unitIndex, aUnitId[structureName])				
				if (addon = 1) ; reactor
					nonTechLabs += 2 - filledSlots
				else if (addon = -1) ; techlab
					techLabs += 1 - filledSlots
				else nonTechLabs += 1 - filledSlots ; Non-terran races and terran structures without addons
			}
		}
		return nonTechLabs + techLabs
	}

	filledSlotCount(unitIndex, unitType)
	{
		static TickCountRandomSet := 0, nearDone := .8

		if (A_TickCount - TickCountRandomSet > 10000) 
			TickCountRandomSet := A_TickCount, nearDone := rand(.75, .85) ; rand(-0.04, .15) 
		getStructureProductionInfo(unitIndex, unitType, aItems, queueSize) ; Could consider using time remaining rather than % here
		count := 0
		queueSize -= aItems.MaxIndex()
		for i, item in aItems
		{
			if item.progress < nearDone || queueSize-- > 0
				count++
		}
		return count
	}

	; This is here so I can implement AutoBuild which may have issues with hotkeys affecting other functions
	restoreSelection(controlGroup, selectionPage, highlightedTab)
	{ 

		input.psend(SC2Keys.key("ControlGroupRecall" controlGroup))
		dsleep(15) ; This might not be long enough in big battles/large control group
		if (highlightedTab && highlightedTab < getSelectionTypeCount())	; highlightedTab is zero based - TypeCount is 1 based hence < not <=
		{
			input.pSend(sRepeat(SC2Keys.key("SubgroupNext"), highlightedTab))
			; Although unlikely due to speed of automation, it is possible for a unit to die and for there to be 1 less
			; sub group now present, hence if trying to access the previously highest (and now now non existent) subgroup 
			; this could stall here. Perhaps have a look for a max subgroup pos
			while (getSelectionHighlightedGroup() != highlightedTab && A_Index < 40) ; Raised from 25
				dsleep(1)
			dsleep(4) ; This static sleep wasn't required during testing but i added it anyway. (as i didn't do in-depth testing)	
		}	
		; There's no point checking if the selection page still exists - if it doesn't the click
		; will be ignored anyway
		if selectionPage 
		{
			ClickUnitPortrait(0, X, Y, Xpage, Ypage, selectionPage + 1) ; for this function numbers start at 1, hence +1
			input.pClick(Xpage, Ypage)
		}
		return	
	}
}

class buildCheck
{
	static priorTimeGame := -50, priorTick := 0

	hasGameSecondsElapsed(seconds := 3)
	{
		return Abs(getTime() - this.priorTimeGame) > seconds ; just check delta so dont have to worry about negatives
	}
	hasRealSecondsElapsed(seconds := 3)
	{
		return (A_TickCount - this.priorTick)/1000 > seconds
	}
	hasTimeElapsed(gameTime, realTime) ; Both are in seconds. True if both times have elapsed
	{
		return this.hasGameSecondsElapsed(gameTime) && this.hasRealSecondsElapsed(realTime)
	} 	
	set(gameTime := "", tickCount := "")
	{
		if (time = "")
			this.priorTimeGame := getTime()
		else this.priorTimeGame := gameTime
		if (tickCount = "")
			this.priorTick := A_TickCount
		else this.priorTick := tickCount
		return
	}
}


automationStorageGroup(race)
{ 
	global AutomationTerranCtrlGroup, AutomationProtossCtrlGroup, AutomationZergCtrlGroup
	if race = terran 
		return AutomationTerranCtrlGroup
	if race = Protoss 
		return AutomationProtossCtrlGroup
	else return AutomationZergCtrlGroup ; Just return something so any errors are more obvious 
}


DebugSCHotkeys:
DebugSCHotkeys()
return 

g_SmartGeyserControlGroup:
SmartGeyserControlGroup(hoveredGeyserUnitIndex)
return 

; Does not find harvesters which are on the return run i.e. moving away from the refinery, carrying the gas back to the town hall
getSelectedHarvestersMiningGas(byRef oSelection := "")
{
	if aLocalPlayer.Race = "Terran"
		harvesterID := aUnitId.SCV, geyserType := aUnitId.Refinery, ability := "SCVHarvest"
	else if aLocalPlayer.Race = "Protoss"
		harvesterID := aUnitId.Probe, geyserType := aUnitId.Assimilator, ability := "ProbeHarvest"
	else harvesterID := aUnitId.Drone, geyserType := aUnitId.Extractor, ability := "DroneHarvest"
	aFoundIndexes := []
	numGetSelectionSorted(oSelection, True)
	for i, unit in oSelection.units  
	{
		if unit.unitID = harvesterID 
		{
			getUnitQueuedCommands(unit.UnitIndex, aCommands)
			for index, command in aCommands
			{
				if (command.ability = ability || command.ability = "TerranBuild") ; its building the refinery
				&& getUnitType(command.targetIndex) = geyserType
				{
					aFoundIndexes[unit.UnitIndex] := True
					break
				}
			}
		}
	}
	return aFoundIndexes
}

; Uses map position to determine if a harvester is returning gas from the geyser in question - so not foolproof  (as command target is townhall)
; Harvesters inside the geyser or heading towards it is accurate (command target = refinery) 
; The returned count value is inteded to be used when the refinery is under construction
; The found harvesters will already be mining be mining gas from it once it finishes building, so these must be removed from selection

; Note: For a half a second after the refinery finishes the displayed count is 0 (as the SCV transitions from building geyser to mining gas)
; So if user clicks then (has happened to me a couple of times) you end up with 4 on gas.
getHarvestersMiningGas(geyserStructureIndex, byref aFoundIndexes, byRef underConstruction)
{
	static aTownHallLookup 

	if !isobject(aTownHallLookup) && isobject(aUnitId)
	{
		aTownHallLookup := []
		aTownHallLookup.Terran := {aUnitId.CommandCenter: True, aUnitId.OrbitalCommand: True , aUnitId.PlanetaryFortress: True}
		aTownHallLookup.Protoss := {aUnitId.Nexus: True}
		aTownHallLookup.Zerg := {aUnitId.Hatchery: True, aUnitId.Lair: True , aUnitId.Hive: True}
	}	

	if aLocalPlayer.Race = "Terran"
		harvesterID := aUnitId.SCV, geyserType := aUnitId.Refinery, ability := "SCVHarvest"
	else if aLocalPlayer.Race = "Protoss"
		harvesterID := aUnitId.Probe, geyserType := aUnitId.Assimilator, ability := "ProbeHarvest"
	else harvesterID := aUnitId.Drone, geyserType := aUnitId.Extractor, ability := "DroneHarvest"
	aFoundIndexes := [], count := 0

	unitCount := DumpUnitMemory(MemDump)

	underConstruction := numgetUnitTargetFilter(MemDump, geyserStructureIndex) & aUnitTargetFilter.underConstruction
	aGeyserStructurePos := numGetUnitPositionXYZ(MemDump, geyserStructureIndex)
	loop, % unitCount
	{
		if (aUnitTargetFilter.Dead & numgetUnitTargetFilter(MemDump, unit := A_Index - 1)) 
		|| aLocalPlayer.Slot != numgetUnitOwner(MemDump, Unit)
		|| harvesterID != numgetUnitModelType(numgetUnitModelPointer(MemDump, Unit))
	       Continue
	   	getUnitQueuedCommands(unit, aCommands)
		for index, command in aCommands
		{
			if command.ability = ability
			&& (command.targetIndex = geyserStructureIndex ; harvester heading towards the geyser in question
				|| (aLocalPlayer.Slot = numgetUnitOwner(MemDump, command.targetIndex) ; this part checks if harvester is on the return trip from the geyser in question.
					&& aTownHallLookup[aLocalPlayer.Race].hasKey(numgetUnitModelType(numgetUnitModelPointer(MemDump, command.targetIndex))) ; Target is a townhall i.e. harvester mining minerals or gas and is returning to town hall
					&& isUnitNearUnit(aGeyserStructurePos, aTownHallPos := numGetUnitPositionXYZ(MemDump, command.targetIndex), 9) ; so town hall is next to refinery
					&& isPointNearLineSegmentWithZcheck(aGeyserStructurePos, aTownHallPos, numGetUnitPositionXYZ(MemDump, unit), .9))) ; harvester is within 1 map unit of the straight line connecting the refinery to the townhall (this wont work if there is an obstruction and the worker has to move path around it)
			{ 																														; 1 is too big and a unit returning minerals from a patch adjacent to the refinery will count (when its at the CC end of the line)
				; I could do a maxIndex() check on the commands - if harvester has another queued command after this then add it to the ignore list
				; e.g. so if you accidentally select a worker which is queued to build a structure after it mines a patch it will be deselected and not sent to geyser
				; But then this would create issues if the user intends for it to go to the geyser
				aFoundIndexes[unit] := True, count++
				break
			}
			;else if (underConstruction) ; This determines if the SCV is constructing the refinery and if it's going to harvest gas from it when its done.
			else if command.ability = "TerranBuild"  ; Edit: Due to the half a second after finishing building the SCV still doesnt register as mining gas - so always perform this check even if refinery is finished
			&& aCommands.MaxIndex() = index  ; Else it is queued to go elsewhere when it finishes construction
			&& (type := numgetUnitModelType(numgetUnitModelPointer(MemDump, command.targetIndex))) ; The target index is the actual geyser and not the refinery
			&& (type = aUnitId.VespeneGeyser || type = aUnitId.SpacePlatformGeyser || type = aUnitId.RichVespeneGeyser || type = aUnitId.ProtossVespeneGeyser || type = aUnitId.VespeneGeyserPretty)
			&& isUnitNearUnit(aGeyserStructurePos, numGetUnitPositionXYZ(MemDump, command.targetIndex), 1)
				count++, aFoundIndexes[unit] := True
		}
	 }
	return count
}

; If attempting to construct a building (i.e. placing the building) and the mouse/building
; is over the refinery, this will still return false - which is good.

GeyserStructureHoverCheck(byRef hoveredGeyserUnitIndex)
{
	if aLocalPlayer.Race = "Terran"
		geyserStructure := aUnitId.Refinery
	else if aLocalPlayer.Race = "Protoss"
		geyserStructure := aUnitId.Assimilator
	else geyserStructure := aUnitId.Extractor
	if (unitIndex := getCursorUnit()) >= 0
	&& getUnitOwner(unitIndex) = aLocalPlayer.slot
	&& getUnitType(unitIndex) = geyserStructure
		return True, hoveredGeyserUnitIndex := unitIndex
	return 
}

; I need a method to determine if a worker is already harvesting (or queued to harvest from a geyser)
; Checking the queuedCommands targetUnitIndex will reveal if it going into (or inside a geyser)
; But this doesnt help when it is returning the harvested gas to the townhall

SmartGeyserControlGroup(geyserStructureIndex)
{
	global smartGeyserCtrlGroup, smartGeyserReturnCargo

	geyserHarvesterCount := getResourceWorkerCount(geyserStructureIndex, aLocalPlayer.Slot)

	; If refinery is not finished building then this will be 0
	if geyserHarvesterCount >= 3
	{
		input.pClick(,, "Right")
		return
	}
	aIgnoredHarvesters := [],	aSentToGeyser := []
	, harvesterID := localHarvesterID()
	, setGroup := aAGHotkeys.set[smartGeyserCtrlGroup]
	, InvokeGroup := aAGHotkeys.Invoke[smartGeyserCtrlGroup]

	; This just checks the selected units for mining
	;aHarvestingGas := getSelectedHarvestersMiningGas(oSelection) ; oSelection is reversed

	; This count value should only be used if the structure is under construction. Otherwise the resource count above is more reliable.
	; Although the resource count does not include harvesters which are returning cargo and then queued to the refinery.
	; Edit: Actually for a half a second after the refinery finishes the displayed count is 0 (as the SCV transitions from building geyser to mining gas)
	; So if user clicks then (has happened to me a couple of times) you end up with 4 on gas.
	count := getHarvestersMiningGas(geyserStructureIndex, aHarvestingGas, structureUnderConstruction)
	if structureUnderConstruction || (aLocalPlayer.Race = "Terran" && !geyserHarvesterCount)
		geyserHarvesterCount := count 
	harvestersToKeep := 3 - geyserHarvesterCount 
	;tooltip, % "`n`n`n" resourceWorkerCount "`n" count "`n" (3-geyserHarvesterCount)
	;settimer, timerRemoveme, -5000

	; An SCV who is queued to enter a geyser but was told to return cargo does not have the refinery in the queued commands (just the townhall)
	; Also when returning cargo, this SCV is not counted in refinery's worker count		
	;log(harvestersToKeep)
	numGetSelectionSorted(oSelection, True)
	if oSelection.Count > 1	&& oSelection.TabPositions.HasKey(harvesterID) && geyserHarvesterCount < 3
	&& (harvestersToKeep < oSelection.TabSizes[harvesterID] || oSelection.Count != oSelection.TabSizes[harvesterID]) ; Not enough harvesters selected to be require filtering or there are non-workers selected so leave them selected after removing the workers 
	{
		installedHooks := true 
		critical, 1000
		input.pReleaseKeys(True)
		setLowLevelInputHooks(True)		
		
		input.psend(setGroup)

		for i, unit in oSelection.units  
		{
			if unit.unitID = harvesterID
			{
				if !harvestersToKeep || aHarvestingGas.HasKey(unit.UnitIndex) ; If enough workers on geyser or this harvester is already on a geyser
					aIgnoredHarvesters.Insert(unit.unitPortrait)
				else 
				{ 
					harvestersToKeep--
					aSentToGeyser[unit.unitIndex] := True ; These units are sent to the geyser
				}
			}
			else if aLocalPlayer.Race = "Terran" && unit.unitID = aUnitId.Mule
				aIgnoredHarvesters.Insert(unit.unitPortrait)
			; Uncomment this to prevent non-harvesters being sent to geyser
			; Im not sure which is better, as you could accidentally box drag a worker with army units (which are defending the mineral line)
			; and then send them to stand near a geyser on purpose to defend it - this would prevent that!
			; so probably best to let them move to the geyser
			;aIgnoredHarvesters.Insert(unit.unitPortrait) 
		}
		if aIgnoredHarvesters.MaxIndex()
			clickUnitPortraits(aIgnoredHarvesters) ; Harvesters which are not being sent to the geyser
	}

	input.pClick(,, "Right") ; click the geyser


	; I should really create a function which updates the selection object after removing units 
	; which would eliminate the need to sleep and call numgetSlectionSorted() again

	; If the build card is displayed, sending return cargo 'c' will invoke build command Centre
	; If ANY unit has been removed from the selection panel, then the abilities card (basic/advanced) is reset - i.e. return cargo ability can be used

	if smartGeyserReturnCargo && (aIgnoredHarvesters.MaxIndex() || !isUserBusyBuilding())
	{
		if aIgnoredHarvesters.MaxIndex()
		{
			dSleep(10)
			numGetSelectionSorted(oSelection)	
		}
		if oSelection.HighlightedGroup != harvesterID && oSelection.HighlightedGroup != aUnitId.Mule
		{
			firstTab := tabToGroup(oSelection.HighlightedGroup, oSelection.TabPositions[harvesterID])
			secondTab := tabToGroup(oSelection.TabPositions[harvesterID], oSelection.HighlightedGroup)
		}
		input.psend(firstTab SC2Keys.key("ReturnCargo") secondTab)
	}

	if aSentToGeyser.MaxIndex()
	{
		input.psend("{click 0 0}" InvokeGroup)
		dSleep(40)
		clickUnitPortraits(getPortraitsFromIndexes(aSentToGeyser)) ; Remove the harvesters which were sent to the geyser
	}
	if installedHooks
		Input.revertKeyState(), setLowLevelInputHooks(False)
	return 

	; timerRemoveme:
	;ToolTip
	;return

}

localHarvesterID()
{
	if aLocalPlayer.Race = "Terran"
		return aUnitId.SCV
	else if aLocalPlayer.Race = "Protoss"
		return aUnitId.Probe
	else if aLocalPlayer.Race = "Zerg"
		return aUnitId.Drone
	else return	""
}


; aIndexLookUp - an array where the key is the unitIndex
getPortraitsFromIndexes(aIndexLookUp, byRef oSelection := "", isReversed := False)
{
	aPortraits := []
	if !isobject(oSelection)
		numGetSelectionSorted(oSelection, True),  isReversed := True
	for i, unit in oSelection.units  
	{
		if aIndexLookUp.HasKey(unit.unitIndex)
			aPortraits.Insert(unit.unitPortrait)
	}
	if aPortraits.MaxIndex() && !isReversed
		reverseArray(aPortraits)
	return aPortraits
}


; fills predictedSelection with the same byte values as what the control group will do when it is invoked
; can then use a byte comparison to determine when the selection buffer is fully updated.

selectionBufferFromGroup(byRef predictedSelection, group)
{
	count := 0
	bufferCount := numgetControlGroupMemory(controlBuffer, group)
	VarSetCapacity(predictedSelection, bufferCount * 4)
	loop, % bufferCount
	{
		unitIndex := (fingerPrint := NumGet(controlBuffer, (A_Index - 1) * S_scStructure, "UInt")) >> 18
		if getUnitFingerPrint(unitIndex) = fingerPrint && !(getUnitTargetFilter(unitIndex) & aUnitTargetFilter.Hidden)
			NumPut(fingerPrint, predictedSelection, 4 * count++, "UInt")
	}
	return count * 4 ; size of filled buffer	
}

; A timeout could be caused by a unit dying in the control group while the selection buffer is updating
; This could be fixed by calling selectionBufferFromGroup() during the loop, but this seems wasteful 
; and the timeout should provide enough time 99% of the time for it to work fine

; The other issue is the selection buffer could be lagging and still match, but is actually about to change to something else
compareSelections(byRef predictedSelection, size, timeOut := 60)
{
	if timeOut <= 0
		loopCount := 1
	else loopCount := timeOut + 15
	count := size / 4
	timer := stopwatch()
	loop
	{
		if (count = selectionCount := getSelectionCount())
		{
			ReadRawMemory(B_SelectionStructure + O_scUnitIndex, GameIdentifier, MemDump, selectionCount * S_scStructure)
			if DllCall("ntdll\RtlCompareMemory", "Ptr", &predictedSelection, "Ptr", &MemDump, "Ptr", size) = size
				return A_Index, stopwatch(timer)
		}
		dsleep(1)
	} until stopwatch(timer, False) >= timeOut || A_Index >= loopCount
	return false, stopwatch(timer)
}


invokeControlGroup(group, timeout := 35)
{
	input.psend(SC2Keys.key("ControlGroupRecall" group))
	bufferSize := selectionBufferFromGroup(predictedSelectionBuffer, group) ; creates a byte buffer from the control group buffer i.e. it removed hidden/dead units
	if compareSelections(predictedSelectionBuffer, bufferSize, timeout) ; a loop which compares the selection buffer to the predicted (selection) from the control group buffer with a timeout
		dsleep(15)
	return	
}

; These two functions can be used to determine when the  grouping command has finished updating the control group buffer
; not sure what happens if a unit dies just as the grouping command is issued.
selectionToGroup(byRef predictedGroup)
{
	selectionCount := getSelectionCount()
	ReadRawMemory(B_SelectionStructure, GameIdentifier, predictedGroup, selectionCount * S_scStructure + O_scUnitIndex)
	return selectionCount * 4
}
compareGroupToBuffer(byRef predictedGroup, size, group)
{
	count := size / 4
	timer := stopwatch()
	loop
	{
		bufferCount := numgetControlGroupMemory(controlBuffer, group)		
		if (count = bufferCount && DllCall("ntdll\RtlCompareMemory", "Ptr", &controlBuffer, "Ptr", &controlBuffer, "Ptr", size) = size)
				return True, stopwatch(timer)
		dsleep(1)
	} until stopwatch(timer, False) >= 60 || A_Index >= 80
	return false, stopwatch(timer)	
}


/*

f2:: 
MouseGetPos, x, y
x2 := A_ScreenWidth+10
y2 := A_ScreenHeight+10
input.psend(4)
;input.psend("{click d " 0 " " 0 "}")
;sleep 1000
input.psend("{click d " x2 " " y2 "}")
;sleep 1000
input.psend("{Escape}")
;sleep 1000
;soundplay *-1
input.psend("{click u -15 -15}")
input.psend(4)
return 


f1:: 
MouseGetPos, x, y
x2 := x+2000, y2 := y+2000
sendInput, {click Down %x% %y%}
sleep 2000
MouseMove, x2, Y2
sleep 2000
sendInput, {Escape}
sleep 2000
soundplay *-1
sendInput, {click Up %x% %y%}
sleep 2000
return 




/*
LeftMouseDown(point1)
LeftMouseDown(point2)
KeyDown(Escape)
KeyUp(Escape)
LeftMouseUp(point1)


*/ 



