#persistent
#NoEnv  ; think this is default with AHK_H
#NoTrayIcon
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1 ; This is the default for AHK_H, but any other value eg 30 causes major issues!
ListLines, Off
OnExit, ShutdownProcedure 
scriptWinTitle := changeScriptMainWinTitle()

l_GameType := "1v1,2v2,3v3,4v4,FFA"
l_Races := "Terran,Protoss,Zerg"
GLOBAL GameWindowTitle := "StarCraft II"
GLOBAL GameIdentifier := "ahk_exe SC2.exe"
GLOBAL config_file := "MT_Config.ini"
GameExe := "SC2.exe"

#Include <Gdip> ;In the library folder
#Include <SC2_MemoryAndGeneralFunctions> 
Global aUnitID, aUnitName, aUnitSubGroupAlias, aUnitTargetFilter, aHexColours
	, aUnitModel,  aPlayer, aLocalPlayer, minimap
	, a_pBrushes := [], a_pPens := [], a_pBitmap

SetupUnitIDArray(aUnitID, aUnitName)
getSubGroupAliasArray(aUnitSubGroupAlias)
setupTargetFilters(aUnitTargetFilter)
SetupColourArrays(aHexColours, MatrixColour)

;pToken := Gdip_Startup()
a_pPens := initialisePenColours(aHexColours)


CreatepBitmaps(a_pBitmap, aUnitID, MatrixColour)
global aUnitInfo := []
readConfigFile(), hasReadConfig := True
global aOverlayTitles := []
for i, overlay in ["IncomeOverlay", "ResourcesOverlay", "ArmySizeOverlay", "WorkerOverlay", "IdleWorkersOverlay", "UnitOverlay", "LocalPlayerColourOverlay", "APMOverlay"] ; here cos it can get non overlay titles
	aOverlayTitles[overlay] := getRandomString_Az09(10, 20)

global MT_CurrentGame 
global aPlayer, aLocalPlayer
global aEnemyAndLocalPlayer
gameChange()
return

ShutdownProcedure:
	Closed := ReadMemory()
	Closed := ReadRawMemory()
	Closed := ReadMemory_Str()
	ExitApp
Return

; Need this, as sometimes call from main thread to gameChange() fails
; also, sometimes the call succeeds, but the timers remain on
; it's fucking retarded!
; Update: This was probably due to using a very old version of AHK_H
; But I don't really want to test this atm, so its being left as is.

gClock:
if (!time := getTime())
	gameChange()
return 

gosubAllOverlays:
gosub, overlayTimer
gosub, unitPanelOverlayTimer
return

; DIB size does not affect overlaying drawing speed
; however if the overlay isn't blank/recreated and graphicsClear is
; called, then this call takes ages (relatively speaking) esp. with big DIBs


overlayTimer: 	;DrawIncomeOverlay(ByRef Redraw, UserScale=1, PlayerIdent=0, Background=0,Drag=0)
If (WinActive(GameIdentifier) || Dragoverlay) ;really only needed to ressize/scale not drag - as the movement is donve via  a post message - needed as overlay becomes the active window during drag etc
{
	If DrawIncomeOverlay
		DrawIncomeOverlay(ReDrawIncome, IncomeOverlayScale, OverlayIdent, OverlayBackgrounds, Dragoverlay)
	If DrawAPMOverlay
		DrawAPMOverlay(ReDrawAPM, APMOverlayScale, OverlayIdent, modeAPM_EPM, Dragoverlay)
	If DrawResourcesOverlay
		DrawResourcesOverlay(ReDrawResources, ResourcesOverlayScale, OverlayIdent, OverlayBackgrounds, Dragoverlay)
	If DrawArmySizeOverlay
		DrawArmySizeOverlay(ReDrawArmySize, ArmySizeOverlayScale, OverlayIdent, OverlayBackgrounds, Dragoverlay)
	If DrawWorkerOverlay
		DrawWorkerOverlay(ReDrawWorker, WorkerOverlayScale, Dragoverlay) ;2 less parameters
	If DrawIdleWorkersOverlay
		DrawIdleWorkersOverlay(ReDrawIdleWorkers, IdleWorkersOverlayScale, dragOverlay)
	if (DrawLocalPlayerColourOverlay && (GameType != "1v1" && GameType != "FFA"))   ;easier just to redraw it each time as otherwise have to change internal for when dragging
		DrawLocalPlayerColour(ReDrawLocalPlayerColour, LocalPlayerColourOverlayScale, DragOverlay)	
}
; sometimes the overlay timer doesnt work, so this is a backup which ensure theyre destroyed
; I think it fails sometimes because its inside an overlay function or something
else if (!WinActive(GameIdentifier) && !Dragoverlay && !areOverlaysWaitingToRedraw())
	DestroyOverlays()
Return

unitPanelOverlayTimer:
If (WinActive(GameIdentifier) || Dragoverlay)
{
	If (DrawUnitOverlay || DrawUnitUpgrades)
	{
		; 854 unit count (2v2 all 4 players being drawn)
		; 10 ms for getEnemyUnitCount+FilterUnits 
		; 25-30 ms for draw
		getEnemyUnitCount(aEnemyUnits, aEnemyUnitConstruction, aEnemyCurrentUpgrades)
		FilterUnits(aEnemyUnits, aEnemyUnitConstruction, aUnitPanelUnits)
		DrawUnitOverlay(RedrawUnit, UnitOverlayScale, OverlayIdent, Dragoverlay)
	}
}
else if (!WinActive(GameIdentifier) && !Dragoverlay && !areOverlaysWaitingToRedraw())
	DestroyOverlays()
return 

  
updateUserSettings()
{	
	Global hasReadConfig
	readConfigFile()
	hasReadConfig := True
	; don't need to call GameChange if settings are changed during a match
	; as the main thread will do that.
}

gameChange()
{
	global
	if !hasReadConfig
		readConfigFile(), hasReadConfig := True
	if !hasLoadedMemoryAddresses
	{
		Process, wait, %GameExe%
		while (!(B_SC2Process := getProcessBaseAddress(GameIdentifier)) || B_SC2Process < 0)		;using just the window title could cause problems if a folder had the same name e.g. sc2 folder
			sleep 400
		hasLoadedMemoryAddresses := loadMemoryAddresses(B_SC2Process)
	}
	if (Time := getTime())
	{
		; aStringTable and aUnitModel are super global declared in memory and general functions
		aUnitModel := [], aStringTable := [], MT_CurrentGame := []
		if WinActive(GameIdentifier)
			ReDrawMiniMap := ReDrawIncome := ReDrawResources := ReDrawArmySize := ReDrawWorker := RedrawUnit := ReDrawIdleWorkers := ReDrawLocalPlayerColour := 1
		getPlayers(aPlayer, aLocalPlayer, aEnemyAndLocalPlayer)
		GameType := GetGameType(aPlayer)	
		getLongestPlayerNames(LongestEnemyName, LongestName) ; Enemy, Enemy or Self
		MT_CurrentGame.LongestEnemyName := LongestEnemyName, MT_CurrentGame.LongestName := LongestName
		SetTimer, overlayTimer, %OverlayRefresh%
		SetTimer, unitPanelOverlayTimer, %UnitOverlayRefresh%
		settimer, gClock, 1000, -4 ; doesn't seem necessary any more. Updated AHK_H seems to always call the function from the main thread
	}
	else 
	{
		SetTimer, overlayTimer, off
		SetTimer, unitPanelOverlayTimer, off
		SetTimer, gClock, off
		DestroyOverlays()
	}
	return
}

increaseOverlayTimer()
{
	global 

	SetTimer, overlayTimer, 50 ; increase freq so that increasing size occurs more rapidly
	SetTimer, unitPanelOverlayTimer, 50 
	SetTimer, overlayTimerSetOriginal, -60000
	return
	overlayTimerSetOriginal:
	SetTimer, overlayTimer, %OverlayRefresh%
	SetTimer, unitPanelOverlayTimer, %UnitOverlayRefresh%
	return
}

restoreOverlayTimer()
{
	global 
	SetTimer, overlayTimer, %OverlayRefresh%
	SetTimer, overlayTimer, %UnitOverlayRefresh%
	return	
}

overlayToggle(hotkey)
{
	global
	if (hotkey = CycleOverlayKey "")
	{
		; if more than one overlays on. Turn then all off. Then cycle
		; DrawIncomeOverlay, DrawResourcesOverlay, DrawArmySizeOverlay, DrawAPMOverlay, DrawUnitOverlay, All
		If ((ActiveOverlays := DrawIncomeOverlay + DrawResourcesOverlay + DrawArmySizeOverlay + DrawAPMOverlay + ((DrawUnitOverlay || DrawUnitUpgrades) ? 1 : 0)) > 1)
		{
			DrawResourcesOverlay := DrawArmySizeOverlay := DrawAPMOverlay := DrawIncomeOverlay := DrawUnitOverlay := DrawUnitUpgrades := 0
			DrawResourcesOverlay(-1), DrawArmySizeOverlay(-1), DrawAPMOverlay(-1), DrawIncomeOverlay(-1), DrawUnitOverlay(-1)
		}
		Else If (ActiveOverlays = 0)
			DrawIncomeOverlay := 1
		Else
		{
			If DrawIncomeOverlay
				DrawResourcesOverlay := !DrawIncomeOverlay := DrawUnitOverlay := 0, DrawIncomeOverlay(-1) 				
			Else If DrawResourcesOverlay
				DrawArmySizeOverlay := !DrawResourcesOverlay := DrawUnitOverlay := 0, DrawResourcesOverlay(-1)
			Else If DrawArmySizeOverlay
				DrawAPMOverlay := !DrawResourcesOverlay := DrawArmySizeOverlay :=  0, DrawArmySizeOverlay(-1)
			Else If DrawAPMOverlay
				DrawUnitUpgrades := DrawUnitOverlay := !DrawAPMOverlay :=  0, DrawAPMOverlay(-1)
			Else If (DrawUnitOverlay || DrawUnitUpgrades) 	; turn them all on
				DrawResourcesOverlay := DrawArmySizeOverlay := DrawAPMOverlay := DrawIncomeOverlay := 1 	
		}
		SetTimer, gosubAllOverlays, -5 
	}	
	Else If (hotkey = ToggleIncomeOverlayKey "")
	{
		If (!DrawIncomeOverlay := !DrawIncomeOverlay)
			DrawIncomeOverlay(-1)	
	}
	Else If (hotkey = ToggleResourcesOverlayKey "")
	{
		If (!DrawResourcesOverlay := !DrawResourcesOverlay)
			DrawResourcesOverlay(-1)
	}
	Else If (hotkey = ToggleArmySizeOverlayKey "")
	{
		If (!DrawArmySizeOverlay := !DrawArmySizeOverlay)
			DrawArmySizeOverlay(-1)	
	}
	Else If (hotkey = ToggleWorkerOverlayKey "")
	{
		If (!DrawWorkerOverlay := !DrawWorkerOverlay)
			DrawWorkerOverlay(-1)
	}	
	Else If (hotkey = ToggleIdleWorkersOverlayKey "")
	{
		If (!DrawIdleWorkersOverlay := !DrawIdleWorkersOverlay)
			DrawIdleWorkersOverlay(-1)
	}	
	Else If (hotkey = ToggleUnitOverlayKey "")
	{
		if (!DrawUnitOverlay && !DrawUnitUpgrades)	
			DrawUnitOverlay := True	
		else if (DrawUnitOverlay && !DrawUnitUpgrades)
			DrawUnitUpgrades := True
		else if (DrawUnitOverlay && DrawUnitUpgrades)
			DrawUnitOverlay := False, DrawUnitUpgrades := True		
		else if (!DrawUnitOverlay && DrawUnitUpgrades)
			DrawUnitUpgrades := False
		If (!DrawUnitOverlay && !DrawUnitUpgrades)
			DrawUnitOverlay(-1)
	}
	SetTimer, gosubAllOverlays, -5 ;this makes the change take effect immediately. 
	Return
}
toggleIdentifier()
{
	global 
	If OverlayIdent = 3
		OverlayIdent := 0
	Else OverlayIdent ++
	Iniwrite, %OverlayIdent%, %config_file%, Overlays, OverlayIdent
	; Since this is called via sendMessage, (so it can read the OverlayIdent on return)
	; lets use a timer to do the gosubs so main script isn't delayed.
	SetTimer, gosubAllOverlays, -5 
	return
}

HiWord(number)
{
	if (number & 0x80000000)
		return (number >> 16)
	return (number >> 16) & 0xffff	
}	
OverlayResize_WM_MOUSEWHEEL(wParam) 		;(wParam, lParam) 0x20A =mousewheel
{ 
	local WheelMove, ActiveTitle, newScale, Scale
	WheelMove := wParam > 0x7FFFFFFF ? HiWord(-(~wParam)-1)/120 :  HiWord(wParam)/120 ;get the higher order word & /120 = number of rotations
	WinGetActiveTitle, ActiveTitle 			;downward rotations are -negative numbers
	for overlayName, overlayTitle in aOverlayTitles
	{	
		if (ActiveTitle = overlayTitle)
		{
			newScale := %overlayName%Scale + WheelMove*.05
			if (newScale >= .5)
				%overlayName%Scale := newScale
			else newScale := %overlayName%Scale := .5	
			IniWrite, %newScale%, %config_file%, Overlays, %overlayName%Scale
			return
		}
	}
	return
} 

OverlayMove_LButtonDown()
{
    PostMessage, 0xA1, 2
}


/*
"FYI, Microsoft recommends to free the Graphics object (G) before working with the GDI device context 
handle (hdc). In other words, call Gdip_DeleteGraphics() before UpdateLayeredWindow() rather than after. "
http://www.autohotkey.com/board/topic/37927-help-with-gdi-clearing-image-after-updating/
http://support.microsoft.com/kb/311221
*/

; The performance/time measurements above each function were performed with
; no player IDs. When IDs (text/pic) are present it takes a bit longer
; Takes 0.76 ms
DrawIdleWorkersOverlay(ByRef Redraw, UserScale=1,Drag=0, expand=1)
{	global aLocalPlayer, GameIdentifier, config_file, IdleWorkersOverlayX, IdleWorkersOverlayY, a_pBitmap, overlayIdleWorkerTransparency
	static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0				

	DestX := DestY := 0
	idleCount := getIdleWorkers()
	If (Redraw = -1 || !idleCount)		;only draw overlay when idle workers present
	{
		Try Gui, idleWorkersOverlay: Destroy
		overlayCreated := False
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier) && idleCount)
	{
		Try Gui, idleWorkersOverlay: Destroy
		overlayCreated := False
		Redraw := 0
	}	
	If (!overlayCreated)
	{
		Gui, idleWorkersOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, idleWorkersOverlay: Show, NA X%idleWorkersOverlayX% Y%idleWorkersOverlayY% W400 H400, % aOverlayTitles["idleWorkersOverlay"]
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		overlayCreated := True	
	}
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, idleWorkersOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, idleWorkersOverlay: +E0x20 +LastFound
		WinGetPos,idleWorkersOverlayX,idleWorkersOverlayY		
		IniWrite, %idleWorkersOverlayX%, %config_file%, Overlays, idleWorkersOverlayX
		Iniwrite, %idleWorkersOverlayY%, %config_file%, Overlays, idleWorkersOverlayY
	}
	hbm := CreateDIBSection(400, 400)
	, hdc := CreateCompatibleDC()
	, obm := SelectObject(hdc, hbm)
	, G := Gdip_GraphicsFromHDC(hdc)
	, Gdip_SetInterpolationMode(G, 2)
	;DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)	

	pBitmap := a_pBitmap[aLocalPlayer["Race"],"Worker"]
	SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)

	expandOnIdle := 4
	if expand
	{
		increased := floor(idlecount / expandOnIdle)/8
		if (increased > .5)		; insreases size every 4 idle workers until 16 workers ie 4x
			increased := .5
		UserScale += increased
	}
	Options := " cFFFFFFFF r4 s" 18*UserScale
	Width *= UserScale *.5, Height *= UserScale *.5
	Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
	Gdip_TextToGraphics(G, idleCount, "x"(DestX+Width+2*UserScale) "y"(DestY+(Height//4)) Options, Font, TextWidthHeight, TextWidthHeight)
	Gdip_DeleteGraphics(G)	
	UpdateLayeredWindow(hwnd1, hdc,,,,, overlayIdleWorkerTransparency)
	SelectObject(hdc, obm) 
	DeleteObject(hbm)  
	DeleteDC(hdc) 
	Return
}

; Takes 4.4 ms    
DrawIncomeOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, Background=0,Drag=0)
{	global aLocalPlayer, aHexColours, aPlayer, GameIdentifier, IncomeOverlayX, IncomeOverlayY, config_file, a_pBitmap, overlayIncomeTransparency
	, drawLocalPlayerIncome
	static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0

	DestX := i := 0
	Options := " cFFFFFFFF r4 s" 17*UserScale					;these cant be static	
	If (Redraw = -1)
	{
		Try Gui, IncomeOverlay: Destroy
		overlayCreated := False
		Redraw := 0
		Return
	}		
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, IncomeOverlay: Destroy
		overlayCreated := False
		Redraw := 0
	}	
	If (!overlayCreated)
	{
		Gui, IncomeOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, IncomeOverlay: Show, NA X%IncomeOverlayX% Y%IncomeOverlayY% W400 H400, % aOverlayTitles["IncomeOverlay"]
	;	hwnd1 := WinExist()
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		overlayCreated := True
	}
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, IncomeOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, IncomeOverlay: +E0x20 +LastFound
		WinGetPos,IncomeOverlayX,IncomeOverlayY,w,h		
		IniWrite, %IncomeOverlayX%, %config_file%, Overlays, IncomeOverlayX
		Iniwrite, %IncomeOverlayY%, %config_file%, Overlays, IncomeOverlayY		
	}

	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	, hdc := CreateCompatibleDC()
	, obm := SelectObject(hdc, hbm)
	, G := Gdip_GraphicsFromHDC(hdc)
	, Gdip_SetInterpolationMode(G, 2)
	; DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0) ; This slows things down massively, slower with bigger dibs	
	For index, player in aEnemyAndLocalPlayer
	{
		if ((slot_number := player["Slot"]) != aLocalPlayer["Slot"] || drawLocalPlayerIncome)
		{				
			DestY := i ? i*Height : 0

			If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
			{	
				IF (PlayerIdentifier = 2)
					OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
				Else IF (PlayerIdentifier = 1)
					OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale	
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font)
				if !LongestNameSize
				{
					if drawLocalPlayerIncome
						longestName := MT_CurrentGame.LongestName
					else 
						longestName := MT_CurrentGame.LongestEnemyName
					LongestNameData :=	gdip_TextToGraphics(G, longestName, "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale, Font) ; text is invisible ;get string size	
					StringSplit, LongestNameSize, LongestNameData, | ;retrieve the length of the string
					LongestNameSize := LongestNameSize3
				}
				DestX := LongestNameSize+10*UserScale
			}
			Else If (PlayerIdentifier = 3)
			{		
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
				Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				DestX := Width+10*UserScale
			}
			Else 
			{
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
			}

			Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			Gdip_TextToGraphics(G, getPlayerMineralIncome(slot_number), "x"(DestX+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				

			pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Gas",Background]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			Gdip_TextToGraphics(G, getPlayerGasIncome(slot_number), "x"(DestX+(85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				

			pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Worker"]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (2*85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
			TextData := Gdip_TextToGraphics(G, getPlayerWorkerCount(slot_number), "x"(DestX+(2*85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				
			StringSplit, TextSize, TextData, | ;retrieve the length of the string
			if (WindowWidth < CurrentWidth := DestX+(2*85*UserScale)+Width+5*UserScale + TextSize3)
				WindowWidth := CurrentWidth
			i++ 
		}
	}
	WindowHeight := DestY+Height

	if !WindowWidth
		WindowWidth := 20	
	else if (WindowWidth > A_ScreenWidth)
		WindowWidth := A_ScreenWidth

	if !WindowHeight
		WindowHeight := 20		
	else if (WindowHeight > A_ScreenHeight)
		WindowHeight := A_ScreenHeight

	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayIncomeTransparency)
	SelectObject(hdc, obm) ; needed else eats ram ; Select the object back into the hdc
	DeleteObject(hbm)   ; needed else eats ram 	; Now the bitmap may be deleted
	DeleteDC(hdc) ; Also the device context related to the bitmap may be deleted
	Return
}

; Takes ~ 2 ms 
DrawAPMOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, modeAPM_EPM=0,Drag=0)
{	global aLocalPlayer, aHexColours, aPlayer, GameIdentifier, APMOverlayX, APMOverlayY, config_file, a_pBitmap, overlayAPMTransparency
	, APMOverlayMode
	static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0

	DestX := i := 0
	Options := " cFFFFFFFF Right r4 s" 20*UserScale					;these cant be static	
	If (Redraw = -1)
	{
		Try Gui, APMOverlay: Destroy
		overlayCreated := False
		Redraw := 0
		Return
	}		
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, APMOverlay: Destroy
		overlayCreated := False
		Redraw := 0
	}	
	If (!overlayCreated)
	{
		Gui, APMOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, APMOverlay: Show, NA X%APMOverlayX% Y%APMOverlayY% W400 H400, % aOverlayTitles["APMOverlay"]
	;	hwnd1 := WinExist()
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		overlayCreated := True
	}
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, APMOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, APMOverlay: +E0x20 +LastFound
		WinGetPos,APMOverlayX,APMOverlayY,w,h		
		IniWrite, %APMOverlayX%, %config_file%, Overlays, APMOverlayX
		Iniwrite, %APMOverlayY%, %config_file%, Overlays, APMOverlayY		
	}		
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	, hdc := CreateCompatibleDC()
	, obm := SelectObject(hdc, hbm)
	, G := Gdip_GraphicsFromHDC(hdc)
	, Gdip_SetInterpolationMode(G, 2)
	;DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)	
	DestX := 0
	For index, player in aEnemyAndLocalPlayer
	{
		slot_number := player["Slot"]
		; APMOverlayMode
		; -1 = enemies + self
		;  0 = enemies
		;  1 = self
		if ( (( slot_number = aLocalPlayer["Slot"] && APMOverlayMode) || (slot_number != aLocalPlayer["Slot"] && (!APMOverlayMode || APMOverlayMode = -1))) && isPlayerActive(slot_number))
		{				
			DestY := i ? i*Height : 0

			If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
			{	
				IF (PlayerIdentifier = 2)
					OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
				Else IF (PlayerIdentifier = 1)
					OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale	
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font)
				if !LongestNameSize
				{
					if (APMOverlayMode = -1) 
						longestName := MT_CurrentGame.LongestName
					else if (APMOverlayMode = 0) 
						longestName := MT_CurrentGame.LongestEnemyName
					else 
						longestName := aLocalPlayer["Name"]
					LongestNameData :=	gdip_TextToGraphics(G, longestName, "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale, Font) ; text is invisible ;get string size	
					StringSplit, LongestNameSize, LongestNameData, | ;retrieve the length of the string
					LongestNameSize := LongestNameSize3
				}
				DestX := LongestNameSize+10*UserScale

			}
			Else If (PlayerIdentifier = 3)
			{		
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
				Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
				DestX := Width+10*UserScale
				DestY += Height//4
			}
			TextData := Gdip_TextToGraphics(G, getPlayerCurrentAPM(slot_number), "x"DestX "y"DestY " W" 50*UserScale " "  Options, Font)
			; 24.500000|0.000000|25.140299|21.117188|2|1			
			StringSplit, TextSize, TextData, | ;retrieve the length of the string
			if (Height < TextSize4)
				Height := TextSize4
			if (WindowWidth < CurrentWidth := DestX+(40*UserScale) + TextSize3)
				WindowWidth := CurrentWidth
			Height += 5*userscale
			i++ 
		}
	}
	WindowHeight := DestY+Height

	if !WindowWidth
		WindowWidth := 20	
	else if (WindowWidth > A_ScreenWidth)
		WindowWidth := A_ScreenWidth

	if !WindowHeight
		WindowHeight := 20		
	else if (WindowHeight > A_ScreenHeight)
		WindowHeight := A_ScreenHeight

	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayAPMTransparency)
	SelectObject(hdc, obm) ; needed else eats ram ; Select the object back into the hdc
	DeleteObject(hbm)   ; needed else eats ram 	; Now the bitmap may be deleted
	DeleteDC(hdc) ; Also the device context related to the bitmap may be deleted
	Return
}

; Takes 4.45 ms
DrawResourcesOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, Background=0,Drag=0)
{	global aLocalPlayer, aHexColours, aPlayer, GameIdentifier, config_file, ResourcesOverlayX, ResourcesOverlayY, a_pBitmap, overlayResourceTransparency
			, drawLocalPlayerResources
	static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0		

	DestX := i := 0
	Options := " Right cFFFFFFFF r4 s" 17*UserScale 					;these cant be static	
	If (Redraw = -1)
	{
		Try Gui, ResourcesOverlay: Destroy
		overlayCreated := False
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, ResourcesOverlay: Destroy
		overlayCreated := False
		Redraw := 0
	}
	If (!overlayCreated)
	{
		Gui, ResourcesOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, ResourcesOverlay: Show, NA X%ResourcesOverlayX% Y%ResourcesOverlayY% W400 H400, % aOverlayTitles["ResourcesOverlay"]

	;	hwnd1 := WinExist()
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		overlayCreated := True
	}	
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, ResourcesOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, ResourcesOverlay: +E0x20 +LastFound
		WinGetPos,ResourcesOverlayX,ResourcesOverlayY		
		IniWrite, %ResourcesOverlayX%, %config_file%, Overlays, ResourcesOverlayX
		Iniwrite, %ResourcesOverlayY%, %config_file%, Overlays, ResourcesOverlayY		
	}

	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	, hdc := CreateCompatibleDC()
	, obm := SelectObject(hdc, hbm)
	, G := Gdip_GraphicsFromHDC(hdc)
	, Gdip_SetInterpolationMode(G, 2)
	;DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)		

	; Users have requested that their own local player appear in some overlays
	; to do this i now iterate the aEnemyAndLocalPlayer rather than the 
	; aPlayer. Hence this is why i needlessly lookup items like race using aPlayer[slot_number, "Race"] rather than player["Race"]
	For index, player in aEnemyAndLocalPlayer
	{	
		if ((slot_number := player["Slot"]) != aLocalPlayer["Slot"] || drawLocalPlayerResources)
		{	
			DestY := i ? i*Height : 0

			If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
			{	
				IF (PlayerIdentifier = 2)
					OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
				Else IF (PlayerIdentifier = 1)
					OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale		
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)		
				Width *= UserScale *.5, Height *= UserScale *.5
				gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font) ;get string size	
				if !LongestNameSize
				{
					if drawLocalPlayerResources
						longestName := MT_CurrentGame.LongestName
					else 
						longestName := MT_CurrentGame.LongestEnemyName
					LongestNameData :=	gdip_TextToGraphics(G, longestName, "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale	, Font) ; text is invisible ;get string size	
					StringSplit, LongestNameSize, LongestNameData, | ;retrieve the length of the string
					LongestNameSize := LongestNameSize3
				}
				DestX := LongestNameSize+10*UserScale
			}
			Else If (PlayerIdentifier = 3)
			{	pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
				Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
				;Gdip_DisposeImage(pBitmap)
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				DestX := Width+10*UserScale
			}
			Else
			{
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
			}

			Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			;Gdip_DisposeImage(pBitmap)
			Gdip_TextToGraphics(G, getPlayerMinerals(slot_number), "x"(DestX+Width+5*UserScale) "y"(DestY+(Height//4)) Options  " w" 45*UserScale , Font, TextWidthHeight, TextWidthHeight)				
			pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Gas",Background]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			;Gdip_DisposeImage(pBitmap)
			Gdip_TextToGraphics(G, getPlayerGas(slot_number), "x"(DestX+(80*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options  " w" 45*UserScale, Font, TextWidthHeight,TextWidthHeight)				

			pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Supply",Background]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (2*85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
			;Gdip_DisposeImage(pBitmap)
			TextData := Gdip_TextToGraphics(G, getPlayerSupply(slot_number)"/"getPlayerSupplyCap(slot_number), "x"(DestX+(2*83*UserScale)+Width+3*UserScale) "y"(DestY+(Height//4)) Options  " w" 70*UserScale, Font, TextWidthHeight, TextWidthHeight)				
			StringSplit, TextSize, TextData, |			
			if (WindowWidth < CurrentWidth := DestX+(2*85*UserScale)+Width+5*UserScale + TextSize3*2)
				WindowWidth := CurrentWidth	
			Height += 5*userscale	;needed to stop the edge of race pic overlap'n due to Supply pic -prot then zerg
			i++ 
		}
	}
	WindowHeight := DestY+Height

	if !WindowWidth
		WindowWidth := 20	
	else if (WindowWidth > A_ScreenWidth)
		WindowWidth := A_ScreenWidth

	if !WindowHeight
		WindowHeight := 20		
	else if (WindowHeight > A_ScreenHeight)
		WindowHeight := A_ScreenHeight

	Gdip_DeleteGraphics(G)
	, UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayResourceTransparency)
	, SelectObject(hdc, obm)
	, DeleteObject(hbm)
	, DeleteDC(hdc)
	Return
}

; Takes 7 ms for 2 (enemy) players
DrawArmySizeOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, Background=0,Drag=0)
{	global aLocalPlayer, aHexColours, aPlayer, GameIdentifier, config_file, ArmySizeOverlayX, ArmySizeOverlayY, a_pBitmap, overlayArmyTransparency
	, drawLocalPlayerArmy
	static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0	
		
	DestX := i := 0
	Options := " cFFFFFFFF r4 s" 17*UserScale					;these cant be static
	If (Redraw = -1)
	{
		Try Gui, ArmySizeOverlay: Destroy
		overlayCreated := False
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, ArmySizeOverlay: Destroy
		overlayCreated := False
		Redraw := 0
	}	
	If (!overlayCreated)
	{	; Create a layered window ;E0x20 click thru (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption		
		Gui, ArmySizeOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, ArmySizeOverlay: Show, NA X%ArmySizeOverlayX% Y%ArmySizeOverlayY% W400 H400, % aOverlayTitles["ArmySizeOverlay"]
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		overlayCreated := True
	}
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, ArmySizeOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, ArmySizeOverlay: +E0x20 +LastFound
		WinGetPos,ArmySizeOverlayX,ArmySizeOverlayY		
		IniWrite, %ArmySizeOverlayX%, %config_file%, Overlays, ArmySizeOverlayX
		Iniwrite, %ArmySizeOverlayY%, %config_file%, Overlays, ArmySizeOverlayY	
	}
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	, hdc := CreateCompatibleDC()
	, obm := SelectObject(hdc, hbm)
	, G := Gdip_GraphicsFromHDC(hdc)
	, Gdip_SetInterpolationMode(G, 2)
	;DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)
	For index, player in aEnemyAndLocalPlayer
	{	
		; DrawArmySizeOverlay -1 = enemies + self
		if ((slot_number := player["Slot"]) != aLocalPlayer["Slot"] || drawLocalPlayerArmy)
		{	
		;	DestY := i ? i*Height + 5*UserScale : 0
			DestY := i ? i*Height : 0

			If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
			{	
				IF (PlayerIdentifier = 2)
					OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
				Else IF (PlayerIdentifier = 1)
					OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale	
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font)		
				if !LongestNameSize
				{
					if (DrawArmySizeOverlay = -1) 
						longestName := MT_CurrentGame.LongestName
					else 
						longestName := MT_CurrentGame.LongestEnemyName

					LongestNameData :=	gdip_TextToGraphics(G, longestName, "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale	, Font) ; text is invisible ;get string size	
					StringSplit, LongestNameSize, LongestNameData, | ;retrieve the length of the string
					LongestNameSize := LongestNameSize3
				}
				DestX := LongestNameSize+10*UserScale
			}
			Else If (PlayerIdentifier = 3)
			{		
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
				Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
				;Gdip_DisposeImage(pBitmap)
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				DestX := Width+10*UserScale
			}
			Else
			{
				pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
			}
			Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			;Gdip_DisposeImage(pBitmap)
			Gdip_TextToGraphics(G, ArmyMinerals := getPlayerArmySizeMinerals(slot_number), "x"(DestX+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				
			pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Gas",Background]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			;Gdip_DisposeImage(pBitmap)
			Gdip_TextToGraphics(G, getPlayerArmySizeGas(slot_number), "x"(DestX+(85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				



			pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Army"]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (2*85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
			;Gdip_DisposeImage(pBitmap)
			TextData := Gdip_TextToGraphics(G, round(getPlayerArmySupply(slot_number)) "/" getPlayerSupply(slot_number), "x"(DestX+(2*85*UserScale)+Width+3*UserScale) "y"(DestY+(Height//4)) Options, Font)				
			StringSplit, TextSize, TextData, |
			if (WindowWidth < CurrentWidth := DestX+(2*85*UserScale)+Width+5*UserScale + TextSize3)
				WindowWidth := CurrentWidth				
			i++ 
		}
	}
	WindowHeight := DestY+Height

	;DesktopScreenCoordinates(Xmin, Ymin, Xmax, Ymax)
	; If the width is larger than the created Dib section the 
	; Update layered window will fail and nothing will get drawn (overlay permanently hidden)
	; window width should never be 0 for this overlay (unless 0 players in the game)
	; Note: I think there is a little more to it than this, as when adjusting the overlay it allows
	; you to make it massive and then disappears when the overlay gets destroyed/redrawn

	if !WindowWidth
		WindowWidth := 20	
	else if (WindowWidth > A_ScreenWidth)
		WindowWidth := A_ScreenWidth

	if !WindowHeight
		WindowHeight := 20		
	else if (WindowHeight > A_ScreenHeight)
		WindowHeight := A_ScreenHeight

	Gdip_DeleteGraphics(G)
	, UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayArmyTransparency)
	, SelectObject(hdc, obm) 
	, DeleteObject(hbm)  
	, DeleteDC(hdc) 
	Return
}
; Takes 0.6 ms
DrawWorkerOverlay(ByRef Redraw, UserScale=1,Drag=0)
{	global aLocalPlayer, GameIdentifier, config_file, WorkerOverlayX, WorkerOverlayY, a_pBitmap, overlayHarvesterTransparency
	static Font := "Arial", overlayCreated, hwnd1, DragPrevious := False				
	Options := " cFFFFFFFF r4 s" 18*UserScale

	DestX := DestY := 0
	If (Redraw = -1)
	{
		Try Gui, WorkerOverlay: Destroy
		overlayCreated := False
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, WorkerOverlay: Destroy
		overlayCreated := False
		Redraw := 0
	}	
	If (!overlayCreated)
	{
		Gui, WorkerOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, WorkerOverlay: Show, NA X%WorkerOverlayX% Y%WorkerOverlayY% W400 H400, % aOverlayTitles["WorkerOverlay"]
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		overlayCreated := True
	}
	If (Drag AND !DragPrevious)
	{	
		DragPrevious := True
		Gui, WorkerOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	
		DragPrevious := False
		Gui, WorkerOverlay: +E0x20 +LastFound
		WinGetPos,WorkerOverlayX,WorkerOverlayY		
		IniWrite, %WorkerOverlayX%, %config_file%, Overlays, WorkerOverlayX
		Iniwrite, %WorkerOverlayY%, %config_file%, Overlays, WorkerOverlayY
	}
	hbm := CreateDIBSection(400, 400)
	, hdc := CreateCompatibleDC()
	, obm := SelectObject(hdc, hbm)
	, G := Gdip_GraphicsFromHDC(hdc)
	, Gdip_SetInterpolationMode(G, 2)

	pBitmap := a_pBitmap[aLocalPlayer["Race"],"Worker"]
	SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
	Width *= UserScale *.5, Height *= UserScale *.5
	Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
	Gdip_TextToGraphics(G, getPlayerWorkerCount(aLocalPlayer["Slot"]), "x"(DestX+Width+2*UserScale) "y"(DestY+(Height//4)) Options, Font, TextWidthHeight, TextWidthHeight)
	Gdip_DeleteGraphics(G)	

	; Don't have to worry about size checks here, as not passing these params to updateLayeredWindow()
	UpdateLayeredWindow(hwnd1, hdc,,,,, overlayHarvesterTransparency)
	, SelectObject(hdc, obm) 
	, DeleteObject(hbm)  
	, DeleteDC(hdc) 
	Return
}

; Function takes 0.151217 ms
DrawLocalPlayerColour(ByRef Redraw, UserScale=1,Drag=0)
{	global aLocalPlayer, GameIdentifier, config_file, LocalPlayerColourOverlayX, LocalPlayerColourOverlayY, a_pBitmap, aHexColours, overlayLocalColourTransparency
	static overlayCreated, hwnd1, DragPrevious := 0,  PreviousPlayerColours := 0 			

	playerColours := arePlayerColoursEnabled()

	if (!playerColours && PreviousPlayerColours) ; this just toggles the colour circle when the player changes the Player COlour state. A bit messy with the stuff below but im lazy
	{
		Redraw := 1
		PreviousPlayerColours := 0
	}
	else if (playerColours && !PreviousPlayerColours)
	{
		Try Gui, LocalPlayerColourOverlay: Destroy
		overlayCreated := False
		PreviousPlayerColours := 1
		return
	}
	else if playerColours
		return

	If (Redraw = -1)
	{
		Try Gui, LocalPlayerColourOverlay: Destroy
		overlayCreated := False
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, LocalPlayerColourOverlay: Destroy
		overlayCreated := False
		Redraw := 0
	}	
	If (!overlayCreated)
	{
		Gui, LocalPlayerColourOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, LocalPlayerColourOverlay: Show, NA X%LocalPlayerColourOverlayX% Y%LocalPlayerColourOverlayY% W200 H200, % aOverlayTitles["LocalPlayerColourOverlay"]
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		overlayCreated := True
	}
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, LocalPlayerColourOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, LocalPlayerColourOverlay: +E0x20 +LastFound
		WinGetPos,LocalPlayerColourOverlayX,LocalPlayerColourOverlayY		
		IniWrite, %LocalPlayerColourOverlayX%, %config_file%, Overlays, LocalPlayerColourOverlayX
		Iniwrite, %LocalPlayerColourOverlayY%, %config_file%, Overlays, LocalPlayerColourOverlayY
	}

	hbm := CreateDIBSection(200, 200)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	;DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)	
	Gdip_SetSmoothingMode(G, 4) 
	colour := aLocalPlayer["Colour"]

	Radius := 12 * UserScale
	Gdip_FillEllipse(G, a_pBrushes[colour], 0, 0, Radius, Radius)

	Gdip_DeleteGraphics(G)	
	UpdateLayeredWindow(hwnd1, hdc,,,,, overlayLocalColourTransparency)
	SelectObject(hdc, obm) 
	DeleteObject(hbm)  
	DeleteDC(hdc) 
	Return
}



getEnemyUnitCount(byref aEnemyUnits, byref aEnemyUnitConstruction, byref aEnemyCurrentUpgrades)
{
	GLOBAL DeadFilterFlag, aPlayer, aLocalPlayer, aUnitTargetFilter, aUnitInfo, aMiscUnitPanelInfo
	aEnemyUnits := [], aEnemyUnitConstruction := [], aEnemyCurrentUpgrades := [], aMiscUnitPanelInfo := []
	 ; Mothership cant really morph - but might as well add it  inside the MSC section
	static aUnitMorphingNames := {"Egg": True, "BanelingCocoon": True, "BroodLordCocoon": True, "OverlordCocoon": True, "MothershipCore": True, "Mothership": True }
;	if !aEnemyUnitPriorities	;because having  GLOBAL aEnemyUnitPriorities := [] results in it getting cleared each function run
;		aEnemyUnitPriorities := []

	loop, % Unitcount := DumpUnitMemory(MemDump)
	{

	    TargetFilter := numgetUnitTargetFilter(MemDump, unit := A_Index - 1)
	    if (TargetFilter & DeadFilterFlag || TargetFilter & aUnitTargetFilter.Hallucination)
	       Continue
		owner := numgetUnitOwner(MemDump, Unit) 

	    if  (aPlayer[Owner, "Team"] <> aLocalPlayer["Team"] && Owner) ;|| (Owner) 
	    {
	    	pUnitModel := numgetUnitModelPointer(MemDump, Unit)
	    	Type := numgetUnitModelType(pUnitModel)

	    	if  (Type < aUnitID["Colossus"])
				continue	
			if (!Priority := aUnitInfo[Type, "Priority"]) ; faster than reading the priority each time - this is splitting hairs!!!
				aUnitInfo[Type, "Priority"] := Priority := numgetUnitModelPriority(pUnitModel)

			if (aUnitInfo[Type, "isStructure"] = "")
				aUnitInfo[Type, "isStructure"] := TargetFilter & aUnitTargetFilter.Structure

			if (TargetFilter & aUnitTargetFilter.UnderConstruction)
			{
				pAbilities := numgetUnitAbilityPointer(MemDump, unit)

				if (Type = aUnitID.Archon )
					progress := getArchonMorphTime(pAbilities)
				;if (TargetFilter & aUnitTargetFilter.Structure)	
				else			
					progress := getBuildProgress(pAbilities, Type)

				aEnemyUnitConstruction[Owner, Priority, Type] := {"progress": progress > aEnemyUnitConstruction[Owner, Priority, Type].Progress
																				? progress 
																				: aEnemyUnitConstruction[Owner, Priority, Type].Progress
																, "count": round(aEnemyUnitConstruction[Owner, Priority, Type].Count) + 1}
				aEnemyUnitConstruction[Owner, "TotalCount"] := round(aEnemyUnitConstruction[Owner, "TotalCount"]) + 1 ; Only used to calculate current zerg drone count. 
				; These will be buildings, but there could be a couple of units here e.g. archon - so if a zerg has a similar unit, then it will throw off the drone count
				
			}		; this is a cheat and very lazy way of incorporating a count into the array without stuffing the for loop and having another variable
			Else 
			{
				if (TargetFilter & aUnitTargetFilter.Structure)
				{
					chronoed := False
					if (aPlayer[owner, "Race"] = "Protoss")
					{
						if numgetIsUnitChronoed(MemDump, unit)
						{
							chronoed := True
							aMiscUnitPanelInfo["chrono", owner, Type] := round(aMiscUnitPanelInfo["chrono", owner, Type]) + 1 
						}
						if (type = aUnitID["Nexus"])
						{
							if (chronoBoosts := floor(numgetUnitEnergy(MemDump, unit)/25))
								aMiscUnitPanelInfo["chronoBoosts", owner] := round(aMiscUnitPanelInfo["chronoBoosts", owner]) + chronoBoosts 
						}
					}
					else if (aPlayer[owner, "Race"] = "Terran") && (Type = aUnitID["OrbitalCommand"] || Type = aUnitID["OrbitalCommandFlying"])
					{
						if (scanCount := floor(numgetUnitEnergy(MemDump, unit)/50))
							aMiscUnitPanelInfo["Scans", owner] := round(aMiscUnitPanelInfo["Scans", owner]) + scanCount 
					} 

					if (queueSize := getStructureProductionInfo(unit, type, aQueueInfo))
					{
						for i, aProduction in aQueueInfo
						{
							if (QueuedType := aUnitID[aProduction.Item])
							{
								; this could fail in first game when no unit has been made yet of this type (QueuedPriority will be blank)
								; But thats a good thing! as it will allow the prioritys to match when then filter trys to remove units (hence it allows the filter to work)
								QueuedPriority := aUnitInfo[QueuedType, "Priority"]  
								;aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType] := round(aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType]) + 1 ; ? aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType] + 1 : 1 	
							
							aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType] := {"progress": (aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType].progress > aProduction.progress ? aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType].progress : aProduction.progress)
																							, "count": round(aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType].count) + 1 }

							} ; this count for upgrades allows the number of nukes being produced to be displayed
							else if a_pBitmap.haskey(aProduction.Item) ; upgrade/research item
							{
								; list the highest progress if more than 1
								
								aEnemyCurrentUpgrades[Owner, aProduction.Item] := {"progress": (aEnemyCurrentUpgrades[Owner, aProduction.Item].progress > aProduction.progress ? aEnemyCurrentUpgrades[Owner, aProduction.Item].progress : aProduction.progress)
																					, "count": round(aEnemyCurrentUpgrades[Owner, aProduction.Item].count) + 1 }
								if chronoed
									aMiscUnitPanelInfo[owner, "ChronoUpgrade", aProduction.Item] := True
							}
						}
					}
					; priority - CC = PF = 3, Orbital = 4
					; this allows the orbital to show as a 'under construction' unit on the right
					if (Type = aUnitID["CommandCenter"] && MorphingType := isCommandCenterMorphing(unit))
					{	
						; if first game then aUnitInfo might not contain the priority
						; priority - CC = PF = 3, Orbital = 4
						if !Priority := aUnitInfo[MorphingType, "Priority"]
						{
							if (MorphingType = aUnitID.OrbitalCommand)
								Priority := aUnitInfo[Type, "Priority"] + 1
							else Priority := aUnitInfo[Type, "Priority"]
							aUnitInfo[MorphingType, "isStructure"] := True ; so a unit morphing into a type which isnt already in aUnitInfo wont get drawn as a unit rather than structure
						}
						progress := getUnitMorphTime(unit, type)
						;aEnemyUnitConstruction[Owner, Priority, MorphingType] := round(aEnemyUnitConstruction[Owner, Priority, MorphingType]) + 1 ; ? aEnemyUnitConstruction[Owner, Priority, MorphingType] + 1 : 1 
						aEnemyUnitConstruction[Owner, Priority, MorphingType] := {"progress": (aEnemyUnitConstruction[Owner, Priority, MorphingType].progress > aProduction.progress ? aEnemyUnitConstruction[Owner, Priority, MorphingType].progress : progress)
																					, "count": round(aEnemyUnitConstruction[Owner, Priority, MorphingType].count) + 1 }
					}
					; hatchery, lair, and hive have the same priority - 2, so just use the hatches priority as it had to already exist 
					else if (Type = aUnitID["Hatchery"] || aUnitID["Lair"] || aUnitID["Spire"]) && MorphingType := isHatchLairOrSpireMorphing(unit)
					{
						aUnitInfo[MorphingType, "isStructure"] := True
						progress := getUnitMorphTime(unit, type)
						
						aEnemyUnitConstruction[Owner, Priority, MorphingType] := {"progress": (aEnemyUnitConstruction[Owner, Priority, MorphingType].progress > progress ? aEnemyUnitConstruction[Owner, Priority, MorphingType].progress : progress)
																					, "count": round(aEnemyUnitConstruction[Owner, Priority, MorphingType].count) + 1 }

						; I think its better to still count the unit as a hatch as well as a morph type
						aEnemyUnits[Owner, Priority, Type] := round(aEnemyUnits[Owner, Priority, Type]) + 1 ; as its already a hatch/lair
					}

					else
						aEnemyUnits[Owner, Priority, Type] := round(aEnemyUnits[Owner, Priority, Type]) + 1 ; ? aEnemyUnits[Owner, Priority, Type] + 1 : 1 ;note +1 (++ will not work!!!)			
				}
				else ; Non-structure/unit
				{
					if aUnitMorphingNames.HasKey(aUnitName[type])
					{

						if (Type = aUnitId.Egg)
						{
							aProduction := getZergProductionFromEgg(unit)				
							QueuedPriority := aUnitInfo[aProduction.Type, "Priority"], progress :=  aProduction.progress, type := aProduction.Type	
							count := aProduction.Count
						}
						else if (Type = aUnitID.BanelingCocoon)
						{
							progress := getBanelingMorphTime(numgetUnitAbilityPointer(MemDump, unit))
							QueuedPriority := aUnitInfo[aUnitID.Baneling, "Priority"], Count := 1
						}
						else if (Type = aUnitID.BroodLordCocoon)
						{
							progress := getUnitMorphTime(unit, Type)
							QueuedPriority := aUnitInfo[Type := aUnitID.BroodLord, "Priority"], Count := 1
						}
						else if (Type = aUnitID.OverlordCocoon)
						{
							progress := getUnitMorphTime(unit, Type)
							QueuedPriority := aUnitInfo[Type := aUnitID.Overseer, "Priority"], Count := 1
						}
						else if (Type = aUnitId.MothershipCore || Type = aUnitId.Mothership)
						{
							if isMotherShipCoreMorphing(unit)
							{
								progress := getUnitMorphTime(unit, Type)
								QueuedPriority := aUnitInfo[Type, "Priority"], Count := 1, Type := aUnitID.Mothership
							}
							else 
							{
								aMiscUnitPanelInfo["MotherShipEnergy", owner] := getUnitEnergy(unit)
								; Since only can have 1 mothership[core] could have just used the 'count' to store the energy
								aEnemyUnits[Owner, Priority, Type] := round(aEnemyUnits[Owner, Priority, Type]) + 1 ; ? aEnemyUnits[Owner, Priority, Type] + 1 : 1
								continue
							}
						}							
						aEnemyUnitConstruction[Owner, QueuedPriority, Type] := {"progress": (aEnemyUnitConstruction[Owner, QueuedPriority, Type].progress > progress ? aEnemyUnitConstruction[Owner, QueuedPriority, Type].progress : progress)
																					, "count": round(aEnemyUnitConstruction[Owner, QueuedPriority, Type].count) + Count} 						
					}
					else
						aEnemyUnits[Owner, Priority, Type] := round(aEnemyUnits[Owner, Priority, Type]) + 1 ; ? aEnemyUnits[Owner, Priority, Type] + 1 : 1
				}
			}
	   	}
	}
	Return
}

; need to fix templar /dt count when morohing in an archon


/*
	object looks like this
	(owner)	|----3
	(Priority)	 |-----2
	(unit)			   |------247

*/

; an easier way to do this would just to create an array containg an object of each unit
; each unit object would then have type, owner, priorty property
; and it could then be sorted by each property in turn to get the order correct
; but tipple sorting an array would take 'considerable' time, at least relative to not sorthing it
; so i would rather do it without sorting the array


FilterUnits(byref aEnemyUnits, byref aEnemyUnitConstruction, byref aUnitPanelUnits)	;care have used aUnitID everywhere else!!
{	global aUnitInfo
	;	aEnemyUnits[Owner, Type]
	STATIC aRemovedUnits := {"Terran": ["BarracksTechLab","BarracksReactor","FactoryTechLab","FactoryReactor","StarportTechLab","StarportReactor"]
							, "Protoss": ["Interceptor"]
							, "Zerg": ["CreepTumorBurrowed","Broodling","Locust"]}

	STATIC aAddUnits 	:=	{"Terran": {SupplyDepotLowered: "SupplyDepot", WidowMineBurrowed: "WidowMine", CommandCenterFlying: "CommandCenter", OrbitalCommandFlying: "OrbitalCommand"
										, BarracksFlying: "Barracks", FactoryFlying: "Factory", StarportFlying: "Starport", SiegeTankSieged: "SiegeTank",  ThorHighImpactPayload: "Thor", VikingAssault: "VikingFighter"}
							, "Zerg": {DroneBurrowed: "Drone", ZerglingBurrowed: "Zergling", HydraliskBurrowed: "Hydralisk", UltraliskBurrowed: "Ultralisk", RoachBurrowed: "Roach"
							, InfestorBurrowed: "Infestor", BanelingBurrowed: "Baneling", QueenBurrowed: "Queen", SporeCrawlerUprooted: "SporeCrawler", SpineCrawlerUprooted: "SpineCrawler"}} 

	STATIC aAddConstruction := {"Terran": {BarracksTechLab: "TechLab", BarracksReactor: "Reactor", FactoryTechLab: "TechLab", FactoryReactor: "Reactor", StarportTechLab: "TechLab", StarportReactor: "Reactor"}}


	STATIC aUnitOrder := 	{"Terran": ["SCV", "OrbitalCommand", "PlanetaryFortress", "CommandCenter"]
							, "Protoss": ["Probe", "Nexus"]
							, "Zerg": ["Drone","Hive","Lair", "Hatchery"]}

	STATIC aAddMorphing := {"Zerg": {BanelingCocoon: "Baneling"}}
	
	; aUnitPanelUnits is an object which contains the custom filtered (removed) user selected units
	;	aUnitPanelUnits ----Race
	;						|------- FilteredCompleted
	;						|------- FilteredUnderConstruction
	;
		/*
		units.insert({"Unit": unitID, Priority: UnitPriority, built: count, constructing: conCount})
		this will look like
		index 	1
				|
				|----- Unit:
				|------Priority etc
				= etc
				|
				2
				|----- Unit:
		Then use sort to arrange correctly
			*/



									; note - could have just done - if name contains "Burrowed" check, substring = minus burrowed
									; overlord cocoon = morphing overseer (and it isnt under construction)
									;also need to account for morphing drones into buildings 
/*									; SupplyDepotDrop
	object looks like this
	(owner)		 3
	(Priority)	 |-----2
	(unit)			   |------247--->Count

*/
	; Since i've added progress and count to the unit panel, i've had to turn priorityObject[priority, unitId] into an object itself containing progress and count - rather than just equalling 
	; the count 

	for owner, priorityObject in aEnemyUnits
	{
	;	aDeleteKeys := []					;****have to 'save' the delete keys, as deleting them during a for loop will cause you to go +2 keys on next loop, not 1
		race := aPlayer[owner, "Race"]		;it doesn't matter if it attempts to delete the same key a second time (doesn't effect anything)

		; as drones morphing are still counted as 'alive' so have to remove them. Could possibly use some of the target filters e.g. hidden
		; But thats also true if they are loaded into an overlord. There might be a way to determine this, or use an additional target filter.

		; For zerg, these units are considered underConstruction and they do not consume a drone. They also have the structure flag
		; NydusCanal (head). Only one of these can be made at a time as well.
		; CreepTumorQueen (queen laid tumour)
		; CreepTumor = 124 (the 'constructing' one when spread from an active tumour)
		; morphing banes, overseers, broodlords, and completed (buried) tumours all give 0 as under construction 

		if (race = "Zerg" && priorityObject[aUnitInfo[aUnitID["Drone"], "Priority"], aUnitID["Drone"]] && aEnemyUnitConstruction[Owner, "TotalCount"])
		{
			priorityObject[aUnitInfo[aUnitID["Drone"], "Priority"], aUnitID["Drone"]] -= aEnemyUnitConstruction[Owner, "TotalCount"] 
																						- round(aEnemyUnitConstruction[owner, aUnitInfo[aUnitID["NydusCanal"], "Priority"], aUnitID["NydusCanal"], "Count"]) 
																						- round(aEnemyUnitConstruction[owner, aUnitInfo[aUnitID["CreepTumorQueen"], "Priority"], aUnitID["CreepTumorQueen"], "Count"])
																						- round(aEnemyUnitConstruction[owner, aUnitInfo[aUnitID["CreepTumor"], "Priority"], aUnitID["CreepTumor"], "Count"])
			if (priorityObject[aUnitInfo[aUnitID["Drone"], "Priority"], aUnitID["Drone"]] <= 0)
				priorityObject[aUnitInfo[aUnitID["Drone"], "Priority"]].remove(aUnitID["Drone"], "")
		}
		for index, removeUnit in aRemovedUnits[race]
		{
			removeUnit := aUnitID[removeUnit]
			priority := aUnitInfo[removeUnit, "Priority"]
			priorityObject[priority].remove(removeUnit, "")
		}

		for subUnit, mainUnit in aAddUnits[Race]
		{
			subunit := aUnitID[subUnit]
			subPriority := aUnitInfo[subunit, "Priority"]
			if (total := priorityObject[subPriority, subunit])			;** care as if unit has not been seen before, then this priority may be blank!!
			{														;** actually its the other unit priority which may be blank
				mainUnit := aUnitID[mainUnit]
				if !priority := aUnitInfo[mainUnit, "Priority"]
					priority := subPriority		;take a chance, hopefully they will have same priority

				; since its possible that the main unit hasn't been allocated a isStructure
				; use the isStructure from the subUnit which will be the same, and has already been assigned
				if (aUnitInfo[mainUnit, "isStructure"] = "")
					aUnitInfo[mainUnit, "isStructure"] := aUnitInfo[subUnit, "isStructure"]

				priorityObject[priority, mainUnit] := round(priorityObject[priority, mainUnit]) + total
				;if priorityObject[priority, mainUnit]
				;	priorityObject[priority, mainUnit] += total
				;else priorityObject[priority, mainUnit] := total
				priorityObject[subPriority].remove(subunit, "")
			;	aEnemyUnits[owner, priority, subunit] := ""
			;	aEnemyUnits[owner, priority].remove(subunit, "")
			}	
		}


		; this is just so banelings wont show up in
		for subUnit, mainUnit in aAddMorphing[Race]
		{
			subunit := aUnitID[subUnit]
			subPriority := aUnitInfo[subunit, "Priority"]
			if (total := priorityObject[subPriority, subunit])
			{
				; baneling priority = 16, morphing bane = 1
				mainUnit := aUnitID[mainUnit]
				if !priority := aUnitInfo[mainUnit, "Priority"]
					priority := 16		; just for baneling
				aEnemyUnitConstruction[owner, Priority, mainUnit] :=  round(aEnemyUnitConstruction[owner, Priority, mainUnit]) + total
				priorityObject[subPriority].remove(subunit, "") ; remove the baneling cocoon
			}
		}



		for index, removeUnit in aUnitPanelUnits[race, "FilteredCompleted"]
		{
			removeUnit := aUnitID[removeUnit]
			priority := aUnitInfo[removeUnit, "Priority"]
			priorityObject[priority].remove(removeUnit, "")
		}

		for index, unit in aUnitOrder[race]
		{
			if (count := priorityObject[aUnitInfo[aUnitID[unit], "Priority"], aUnitID[unit]])
			{
				index := 0 - aUnitOrder[race].maxindex() + A_index ; hence so the first unit in array eg SCV will be on the left - last unit will have priority 0
			 	priorityObject[index, aUnitID[unit]] := count 		;change priority to fake ones - so that Obital is on far left, followed by
			 	priority := aUnitInfo[aUnitID[unit], "Priority"]		; PF and then CC
			 	priorityObject[priority].remove(aUnitID[unit], "")	
			}
		}		


;		for index, unit in aDeleteKeys												; **********	remove(unit, "") Removes an integer key and returns its value, but does NOT affect other integer keys.
;			priorityObject[aEnemyUnitPriorities[unit]].remove(unit, "")				;				as the keys are integers, otherwise it will decrease the keys afterwards by 1 for each removed unit!!!!													
	}

	for owner, priorityObject in aEnemyUnitConstruction
	{
		race := aPlayer[owner, "Race"]	

		for subUnit, mainUnit in aAddConstruction[Race] ; As this point only Terrans will enter this loop. And its only for rectors/techLabs
		{
			subunit := aUnitID[subUnit]
			subPriority := aUnitInfo[subunit, "Priority"]
			if (total := priorityObject[subPriority, subunit, "Count"])
			{
				subProgress := priorityObject[subPriority, subunit, "progress"]
				mainUnit := aUnitID[mainUnit]
				if !priority := aUnitInfo[mainUnit, "Priority"]
					priority := subPriority		;take a chance, hopefully they will have same priority can cause issues

				; since its possible that the main unit hasn't been allocated a isStructure
				; use the isStructure from the subUnit which will be the same, and has already been assigned
				; Also, as it stands this is only required for terrans, and so all of these units are techlab/reactors
				; so they're structures 
				if (aUnitInfo[mainUnit, "isStructure"] = "")
					aUnitInfo[mainUnit, "isStructure"] := aUnitInfo[subUnit, "isStructure"]

				if priorityObject[priority, mainUnit, "Count"]
				{
					priorityObject[priority, mainUnit, "Count"] += total
					if (priorityObject[priority, mainUnit, "progress"] < subProgress)
						priorityObject[priority, mainUnit, "progress"] := subProgress
				}
				else 
				{
					priorityObject[priority, mainUnit, "Count"] := total
					priorityObject[priority, mainUnit, "progress"] := subProgress
				}
				priorityObject[subPriority].remove(subunit, "")
				aEnemyUnitConstruction[Owner, "TotalCount"] -= total 	;these counts still seem to be out, but works for zerg?
			}		
		}

		for index, removeUnit in aUnitPanelUnits[race, "FilteredUnderConstruction"]
		{
			removeUnit := aUnitID[removeUnit]
			priority := aUnitInfo[removeUnit, "Priority"]
			priorityObject[priority].remove(removeUnit, "")
		}
	
		for index, unit in aUnitOrder[race]		;this will ensure the change in priority matches the changes made above to make the order correct, so they can be added together.
			if (count := priorityObject[aUnitInfo[aUnitID[unit], "Priority"], aUnitID[unit]].count)
			{
				index := 0 - aUnitOrder[race].maxindex() + A_index ; hence so the first unit in array eg SCV will be on the left - last unit will have priority 0
			 	priorityObject[index, aUnitID[unit]] :=  priorityObject[aUnitInfo[aUnitID[unit], "Priority"], aUnitID[unit]] 			;change priority to fake ones - so that Obital is on far left, followed by
			 	priority := aUnitInfo[aUnitID[unit], "Priority"]		; PF and then CC
			 	priorityObject[priority].remove(aUnitID[unit], "")	
			}	
	}
	return
}

; Gdip_GetImageWidth() takes almost no time 0.0009 ms.
; using commas ',' to place expression into 1 line saves ~ 1.5ms (over 45ms draw 3v3 - 6 players being drawn)

DrawUnitOverlay(ByRef Redraw, UserScale = 1, PlayerIdentifier = 0, Drag = 0)
{
	GLOBAL aEnemyUnits, aEnemyUnitConstruction, a_pBitmap, aPlayer, aLocalPlayer, aHexColours, GameIdentifier, config_file, UnitOverlayX, UnitOverlayY 
		, aUnitInfo, SplitUnitPanel, aEnemyCurrentUpgrades, DrawUnitOverlay, DrawUnitUpgrades, aMiscUnitPanelInfo, aUnitID, overlayMatchTransparency
		, unitPanelDrawStructureProgress, unitPanelDrawUnitProgress, unitPanelDrawUpgradeProgress 
	static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0

	If (Redraw = -1)
	{
		Try Gui, UnitOverlay: Destroy
		overlayCreated := False
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, UnitOverlay: Destroy
		overlayCreated := False
		Redraw := 0
	}
	If (!overlayCreated)
	{
		Gui, UnitOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, UnitOverlay: Show, NA X%UnitOverlayX% Y%UnitOverlayY% W400 H400, % aOverlayTitles["UnitOverlay"]
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		overlayCreated := True
	}	
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, UnitOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, UnitOverlay: +E0x20 +LastFound
		WinGetPos,UnitOverlayX,UnitOverlayY		
		IniWrite, %UnitOverlayX%, %config_file%, Overlays, UnitOverlayX
		Iniwrite, %UnitOverlayY%, %config_file%, Overlays, UnitOverlayY		
	}
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	, hdc := CreateCompatibleDC()
	, obm := SelectObject(hdc, hbm)
	, G := Gdip_GraphicsFromHDC(hdc)

 ;	DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0) ; takes 2ms for a 1920x1080. Not required if deleting graphics

	;Gdip_GraphicsClear(G)
	;setDrawingQuality(G)

	; This seems to make the edge (mainly left and top) of the progress bars fuzzy (AntiAlias)
	; but it does gives the shaded count boxes a slightly neater (rounded) corner
	; This is toggled to mode 0 (default) when drawing the progress bars - best of both worlds!
	; Note: CC and nexus - there number counts seem to mess with the background shaded box colour 
	; this occurs on all Gdip_SetSmoothingMode values - certain picture background colour
	
	, Gdip_SetSmoothingMode(G, 4)
	, Gdip_SetInterpolationMode(G, 2)	; fast and draws (almost?) same quality as mode 7 HighQualityBicubic. Refer to benchmark picture for data


	Height := DestY := 0
	, rowMultiplier := (DrawUnitOverlay ? (SplitUnitPanel ? 2 : 1) : 0) + (DrawUnitUpgrades ? 1 : 0)
	
	for slot_number, priorityObject in aEnemyUnits ; slotnumber = owner and slotnumber is an object
	{
		DestXPlayerMax := 0
		Height += 7*userscale	;easy way to increase different players next line
		; destY is height of each players first panel row.
		, DestY := (rowMultiplier * Height + ((unitPanelDrawUnitProgress || unitPanelDrawStructureProgress ) ? 8 * UserScale : 0)) * (A_Index - 1)
		, destUnitSplitY :=  DestY + ((unitPanelDrawUnitProgress || unitPanelDrawStructureProgress ) ? 5 * UserScale : 0)
		
		If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
		{	
			IF (PlayerIdentifier = 2)
				OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
			Else IF (PlayerIdentifier = 1)
				OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale		
			gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY +12*UserScale)  OptionsName, Font) ;get string size	
		;	StringSplit, TextSize, TextData, | ;retrieve the length of the string		
			if !LongestNameSize
			{
				LongestNameData :=	gdip_TextToGraphics(G, MT_CurrentGame.LongestEnemyName
														, "x0" "y"(DestY)  " Bold c00FFFFFF r4 s" 17*UserScale	, Font) ; text is invisible ;get string size	
				StringSplit, LongestNameSize, LongestNameData, | ;retrieve the length of the string
				LongestNameSize := LongestNameSize3
			}
			DestX := LongestNameSize+5*UserScale

		}
		Else If (PlayerIdentifier = 3)
		{	
			pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
			, SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			, Width *= UserScale *.5, Height *= UserScale *.5	
			, Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY + Height/5, Width, Height, 0, 0, SourceWidth, SourceHeight)
			, DestX := Width+15*UserScale 
		}
		else DestX := 0

		; this moves the destionX to the right to account for the race-icon/name
		firstColumnX  := destUnitSplitX := DestX

		
		if DrawUnitOverlay
		{
			for priority, object in priorityObject
			{
				for unit, unitCount in object
				{
					if !(pBitmap := a_pBitmap[unit])
						continue ; as i dont have a picture for that unit - not a real unit?
					SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap) 
					, Width *= UserScale *.5, Height *= UserScale *.5	; all unit/buildings/updagres are 38x38 after being halved
				

					; Doing like this as it's a requested feature and im too lazy to change everything to make it simpler
					if (SplitUnitPanel && !aUnitInfo[unit, "isStructure"])
					{
						prevStructureX := DestX
						, prevStructureY := DestY
						, DestX := destUnitSplitX
						, DestY := destUnitSplitY + Height * 1.1	; 1.1 so the transparent backgrounds of the count and count underconstruction dont overlap
					}
					if (DestXPlayerMax < DestX)
						DestXPlayerMax := DestX		
					Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)

					; Draw the MSC energy in place of unit count - as can only have one MSC.
					if (unit = aUnitID.MothershipCore || unit = aUnitID.Mothership)
					{
						; For the motherShip - the energy is a little hard to read, due to the its background picture
						energy := aMiscUnitPanelInfo["MotherShipEnergy", slot_number]
						if (energy < 100)
						{
							Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .6*Width, DestY + .6*Height, Width/2.5, Height/2.5, 5)
							if (energy < 10)
								gdip_TextToGraphics(G, energy, "x"(DestX + .5*Width + .4*Width/2) "y"(DestY + .5*Height + .3*Height/2)  " Bold Italic cFFCD00FF r4 s" 11*UserScale, Font)	
							else 
								gdip_TextToGraphics(G, energy, "x"(DestX + .5*Width + .18*Width/2) "y"(DestY + .5*Height + .3*Height/2) " Bold Italic cFFCD00FF r4 s" 11*UserScale, Font)
						}
						else  ;(energy >= 100)
						{
							; Since MSC energy can be three digits (in the 100s), make the transparent back ground a bit wider - move the start pos back,
							; but ensure it still ends at the same pos as the other unit count transparent backgrounds.
							; use .45*width for text x pos, as since text (and italic) the text will way be slightly to the right
							Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .5*Width, DestY + .6*Height, (Width/2.5) +  .1*Width, Height/2.5, 5)
							, gdip_TextToGraphics(G, energy, "x"(DestX + .45*Width) "y"(DestY + .5*Height + .3*Height/2)  " Bold Italic cFFCD00FF r4 s" 11*UserScale, Font)
						}
					}
					else 
					{
						Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .6*Width, DestY + .6*Height, Width/2.5, Height/2.5, 5)
						if (unitCount >= 10)
							gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .18*Width/2) "y"(DestY + .5*Height + .3*Height/2)  " Bold cFFFFFFFF r4 s" 11*UserScale, Font)
						Else
							gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .35*Width/2) "y"(DestY + .5*Height + .3*Height/2)  " Bold cFFFFFFFF r4 s" 11*UserScale, Font)					
					}
					; Draws in top Left corner of picture scan count for orbitals or chrono count for protoss structures
					if ((chronos := aMiscUnitPanelInfo["chrono", slot_number, unit]))
					{
						if (chronos = 1)
							Gdip_FillEllipse(G, a_pBrushes["ScanChrono"], DestX + .2*Width/2, DestY + .15*Height/2, 5*UserScale, 5*UserScale)
						Else
						{
							Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX, DestY, Width/2.5, Height/2.5, 5)
							if (chronoCount >= 10)
								gdip_TextToGraphics(G, chronos, "x"(DestX + .1*Width/2) "y"(DestY + .10*Height/2)  " Bold Italic cFFFF00B3 r4 s" 11*UserScale, Font)
							else
								gdip_TextToGraphics(G, chronos, "x"(DestX + .2*Width/2) "y"(DestY + .10*Height/2) " Bold Italic cFFFF00B3 r4 s" 11*UserScale, Font)
						}
					}

					if 	( (unit = aUnitID.OrbitalCommand  && (chronoScanCount := aMiscUnitPanelInfo["Scans", slot_number]))
					|| (unit = aUnitID.Nexus && (chronoScanCount := aMiscUnitPanelInfo["chronoBoosts", slot_number])))
					{
						Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX, DestY + .6*Height, Width/2.5, Height/2.5, 5)
						if (chronoScanCount >= 10)
							gdip_TextToGraphics(G, chronoScanCount, "x"(DestX + .1*Width/2) "y"(DestY + .5*Height + .3*Height/2)  " Bold Italic cFF00FFFF r4 s" 11*UserScale, Font)
						else
							gdip_TextToGraphics(G, chronoScanCount, "x"(DestX + .2*Width/2) "y"(DestY + .5*Height + .3*Height/2) " Bold Italic cFF00FFFF r4 s" 11*UserScale, Font)
					}

					if (unitCount := aEnemyUnitConstruction[slot_number, priority, unit].count)	; so there are some of this unit being built lets draw the count on top of the completed units
					{
						progress := aEnemyUnitConstruction[slot_number, priority, unit].progress
					;	Gdip_FillRoundedRectangle(G, a_pBrush[TransparentBlack], DestX, DestY + .6*Height, Width/2.5, Height/2.5, 5)
						, Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .6*Width, DestY, Width/2.5, Height/2.5, 5)
						if (unitCount >= 10)
							gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .16*Width/2) "y"(DestY + .10*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
						Else
							gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .3*Width/2) "y"(DestY + .10*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
						
						if (unitPanelDrawStructureProgress && aUnitInfo[unit, "isStructure"]) || (unitPanelDrawUnitProgress && !aUnitInfo[unit, "isStructure"])
						{
							Gdip_SetSmoothingMode(G, 0)
							; floor helps keep a consistent height for the bar - as the y address may be a a float + the float the height can cause inconsistent results 
							; I.e. one bar might appear slightly taller 
							, Gdip_FillRectangle(G, a_pBrushes.TransparentBlack, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width - 10 * UserScale *.5, Height/16)
							, Gdip_FillRectangle(G, a_pBrushes.Green, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width*progress - progress * 10 * UserScale *.5, Height/16)
							, Gdip_SetSmoothingMode(G, 4)
						}
							aEnemyUnitConstruction[slot_number, priority].remove(unit, "")
					}
					if (SplitUnitPanel && !aUnitInfo[unit, "isStructure"])
					{
						destUnitSplitX += (Width+5*UserScale)
						, DestX := prevStructureX
						, DestY := prevStructureY
					}
					else DestX += (Width+5*UserScale)
				}
			}

			; This is fine for both split/non-split panels 
			; Add 1 image width to destination, as DestXPlayerMax was not incremented at the end of the last loop. 
			; (so it's currently placed at the start of the last drawn picture)
			DestX := DestXPlayerMax += (Width+5*UserScale) 

			destUnitSplitX := DestX += (Width+5*UserScale) ; constructing units / buildings in construction appear 1 'blank spot' further to the right

			; in case no units in construction

			; I think if the unit panel is split, all of these units should be structures
			; so I dont have to worry about checking structure or not
			; wrong! some units like morphing archons are considered underconstruction!
			for ConstructionPriority, priorityConstructionObject in aEnemyUnitConstruction[slot_number]
			{
				for unit, item in priorityConstructionObject		;	lets draw the buildings under construction (these are ones which werent already drawn above)
				{	

					if (unit != "TotalCount" && pBitmap := a_pBitmap[unit])				;	i.e. there are no already completed buildings of same type
					{
						SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
						, Width *= UserScale *.5, Height *= UserScale *.5	
						
						if (!aUnitInfo[unit, "isStructure"] && SplitUnitPanel)
						{
							prevStructureX := DestX
							, prevStructureY := DestY
							, DestX := destUnitSplitX
							, DestY := destUnitSplitY + Height * 1.1 ; 1.1 so the tranparent backgrounds of the count and count underconstruction dont overlap 
						} 
				
						Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
						Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .6*Width, DestY, Width/2.5, Height/2.5, 5)
						if (item.count >= 10)
							gdip_TextToGraphics(G, item.count, "x"(DestX + .5*Width + .16*Width/2) "y"(DestY + .10*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
						Else
							gdip_TextToGraphics(G, item.count, "x"(DestX + .5*Width + .3*Width/2) " y"(DestY + .10*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
						
						if (unitPanelDrawStructureProgress && aUnitInfo[unit, "isStructure"]) || (unitPanelDrawUnitProgress && !aUnitInfo[unit, "isStructure"])
						{
							Gdip_SetSmoothingMode(G, 0)
							;Gdip_FillRectangle(G, a_pBrushes.TransparentBlack, DestX + 5 * UserScale *.5, DestY+Height, Width - 10 * UserScale *.5, Height/15) ; DestY+Height
							, Gdip_FillRectangle(G, a_pBrushes.TransparentBlack, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width - 10 * UserScale *.5, Height/16)
							, Gdip_FillRectangle(G, a_pBrushes.Green, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width*item.progress - item.progress * 10 * UserScale *.5, Height/16)
							, Gdip_SetSmoothingMode(G, 4)
						}

						if (!aUnitInfo[unit, "isStructure"] && SplitUnitPanel)
						{
							destUnitSplitX += (Width+5*UserScale)
							, DestX := prevStructureX
							, DestY := prevStructureY
							
						}
						else DestX += (Width+5*UserScale)
					}
				}
			}
				; This is here to find the longest unit panel (as they will be different size for different players)
			if (DestX + Width > WindowWidth)
				WindowWidth := DestX
			else if (destUnitSplitX + Width > WindowWidth)
				WindowWidth := destUnitSplitX
		}
		if DrawUnitUpgrades
		{
			;destUpgradesY := DestY  + Height * 1.1 * (rowMultiplier - 1)

			offset := (SplitUnitPanel ? 2 : 1) * ((unitPanelDrawUnitProgress || unitPanelDrawStructureProgress) ? 5 : 0) * userscale
			, destUpgradesY := DestY  + Height * 1.1 * (rowMultiplier - 1) + offset
			, UpgradeX := firstColumnX

			for itemName, item in aEnemyCurrentUpgrades[slot_number]
			{
				if (pBitmap := a_pBitmap[itemName])
				{
					SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
					, Width *= UserScale *.5, Height *= UserScale *.5	
					, Gdip_DrawImage(G, pBitmap, UpgradeX, destUpgradesY, Width, Height, 0, 0, SourceWidth, SourceHeight)					

					if (item.count > 1) ; This is for nukes - think its the only upgrade which can have a count > 1
					{
						Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, UpgradeX + .6*Width, destUpgradesY, Width/2.5, Height/2.5, 5)
						, gdip_TextToGraphics(G, item.count, "x"(UpgradeX + .5*Width + .4*Width/2) "y"(destUpgradesY + .15*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
					}
;					Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX, destUpgradesY+5+Height, Width, Height/10, 3)
;					Gdip_FillRoundedRectangle(G, a_pBrushes.Green, DestX, destUpgradesY+5+Height, Width*progress, Height/10, progress < 3 ? progress : 3)
					; all the icons (even unit ones) have an invisible border around them. Hence deduct 10 pixels from the width and and 5 to destX
					; the progress bar doest start too far to the left of the icon, and doesn't finish too far to the right
					if unitPanelDrawUpgradeProgress
					{
						Gdip_SetSmoothingMode(G, 0)
						, Gdip_FillRectangle(G, a_pBrushes.TransparentBlack, UpgradeX + 5 * UserScale *.5, floor(destUpgradesY+Height), Width - 10 * UserScale *.5, Height/16)
						, Gdip_FillRectangle(G, a_pBrushes.Green, UpgradeX + 5 * UserScale *.5, floor(destUpgradesY+Height), Width*item.progress - item.progress * 10 * UserScale *.5, Height/16)
						, Gdip_SetSmoothingMode(G, 4)
					}

					if aMiscUnitPanelInfo[slot_number, "ChronoUpgrade", itemName] ; its chronoed
						Gdip_FillEllipse(G, a_pBrushes["ScanChrono"], UpgradeX + .2*Width/2, destUpgradesY + .2*Height/2, ceil(5*UserScale), ceil(5*UserScale)) ; ceil seems to make it rounder/crisper
					UpgradeX += (Width+5*UserScale)
				}
			}
			; This is here to find the longest unit panel (as they will be different size for different players)
			if (UpgradeX + Width > WindowWidth)
				WindowWidth := UpgradeX
		}
	}

	; 4*height easy way to ensure the last split unit panel or upgrade doesn't get cut off
	WindowHeight := DestY + 4*Height
	, WindowWidth += width *3 ; because x begins on the left side of where the icon is drawn hence need to add 1 extra icon width to maximum width - actually 1.x something due to the fact that the black count square is past the edge of the picture

	; If just showing upgrades and no names/race icons (though possible but unlikely when showing all),
	; window height width could be null as could destY and width. This would cause the updatelayered to fail
	; causing the last drawn upgrade to annoyingly flash on the screen

	;DesktopScreenCoordinates(Xmin, Ymin, Xmax, Ymax)
	; If the width is larger than the created Dib section the 
	; Update layered window will fail and nothing will get drawn (overlay permanently hidden)

	; Note: I think there is a little more to it than this, as when adjusting the overlay it allows
	; you to make it massive and then disappears when the overlay gets destroyed/redrawn

	if !WindowWidth 
		WindowWidth := DestX ? DestX : 20	; so names/pictures dont get cut off if just displaying upgrades height should; height will always have a value
	else if (WindowWidth > A_ScreenWidth)
		WindowWidth := A_ScreenWidth

	if !WindowHeight ; I think window height will always have a value (unless no players)
		WindowHeight := 20		
	else if (WindowHeight > A_ScreenHeight)
		WindowHeight := A_ScreenHeight

	Gdip_DeleteGraphics(G) ; .0005ms
	, UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayMatchTransparency)
	, SelectObject(hdc, obm) ; All Three of these only take a total of ~ 0.22 ms. So in the end its faster to recreate/delete these than to GDI clear the graphics
	, DeleteObject(hbm)
	, DeleteDC(hdc)
	Return
}

/* Performance impact of changing DIB size
	Since the DIB size limits the drawing size and it would be nice to allow
	a UI to be larger than the screen (in practice this would never be required)
	Also remember that you cant update the layered window with a size larger than the DIB size
	Test:
		thread, NoTimers, True
		getEnemyUnitCount(aEnemyUnits, aEnemyUnitConstruction, aEnemyCurrentUpgrades)
		FilterUnits(aEnemyUnits, aEnemyUnitConstruction, aUnitPanelUnits)
		s := stopwatch()
		loop 100
				DrawUnitOverlay(RedrawUnit, UnitOverlayScale, OverlayIdent, Dragoverlay)
		msgbox %  clipboard := stopwatch(s)
		return 

	when DIB size of screen
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
 	Results: 776, 779, 783, 771 ms

	when DIB 2*size of screen
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	Results: 1496, 1506, 1481 ms 

	Update: I believe this was due to calling gdi graphicsClear (which isn't required)
*/




		