/*
	Rather than messing around with a lot of shared variables/objects/critical sections
	and locks,
	this thread is just going to going to read/update all of the users variables
	itself, as well as gamedata
	This has to be run using AHK.dll (mini doesnt have gui functions)
*/

#persistent
#NoEnv  ; think this is default with AHK_H
#NoTrayIcon
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1
ListLines, Off
OnExit, ShutdownProcedure 

/* ;Cmdline passed script parameters - Old method - now use globalVarsScript
	pObject := "1", pObject := %pObject%	
	pCriticalSection := "2", pCriticalSection := %pCriticalSection%
	aThreads := CriticalObject(pObject, pCriticalSection)
*/ 
scriptWinTitle := changeScriptMainWinTitle()
global aThreads

l_GameType := "1v1,2v2,3v3,4v4,FFA"
l_Races := "Terran,Protoss,Zerg"
GLOBAL GameWindowTitle := "StarCraft II"
GLOBAL GameIdentifier := "ahk_exe SC2.exe"
GLOBAL config_file := "MT_Config.ini"
GameExe := "SC2.exe"

#Include <Gdip> 
#Include <SC2_MemoryAndGeneralFunctions> 
; pToken := Gdip_Startup() ; DO NOT get a new token. Not needed and causes crash on exit when calling gdipShutdown()
Global aUnitID, aUnitName, aUnitSubGroupAlias, aUnitTargetFilter, aHexColours
	, aUnitModel,  aPlayer, aLocalPlayer, minimap
	, a_pBrushes := [], a_pPens := [], a_pBitmap

SetupUnitIDArray(aUnitID, aUnitName)
getSubGroupAliasArray(aUnitSubGroupAlias)
setupTargetFilters(aUnitTargetFilter)
SetupColourArrays(aHexColours, MatrixColour)
; Note: The brushes are initialised within the readConfig function
; so they are updated when user changes custom colour highlights
a_pPens := initialisePenColours(aHexColours)

CreatepBitmaps(a_pBitmap, aUnitID, MatrixColour)
global aUnitInfo := []
readConfigFile(), hasReadConfig := True
; This changeling check is no longer required as reading the first unit owner now (not the third)
;aChangeling := { 	aUnitID["ChangelingZealot"]: True
;				 ,	aUnitID["ChangelingMarineShield"]: True 
;				 ,	aUnitID["ChangelingMarine"]: True 
;				 ,	aUnitID["ChangelingZerglingWings"]: True 
;				 ,	aUnitID["ChangelingZergling"]: True }				
gameChange()
return

; Need this, as sometimes call from main thread to gameChange() fails
; also, sometimes the call succeeds, but the timers remain on
; it's fucking retarded! - Update: Probably due to using an old version of AHK_H. 
; Also some of the routines use a the time variable set here
gClock:
if (!time := getTime())
	gameChange()
return 

toggleMinimap()
{
	Global
	if (DrawMiniMap := !DrawMiniMap)
	{
		IniRead, DrawPlayerCameras, %config_file%, MiniMap, DrawPlayerCameras, 0
		SetTimer, MiniMap_Timer, %MiniMapRefresh%, -7
	}
	else 
		DrawPlayerCameras := False
	drawMinimap()
	return 
}

updateUserSettings()
{	
	Global hasReadConfig
	readConfigFile()
	hasReadConfig := True
	; don't need to call GameChange if settings are changed during a match
	; as the main thread will do that.
}

gameChange(UserSavedAppliedSettings := False)
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
		isWarpGateTechComplete := gateway_count := warpgate_warning_set := 0
		TimeReadRacesSet := 0
		; aStringTable and aUnitModel are super global declared in memory and general functions
		aUnitModel := [] 		
		aStringTable := []
		aMiniMapWarning := [], a_BaseList := [], aGatewayWarnings := []
		if WinActive(GameIdentifier)
			ReDrawMiniMap := ReDrawIncome := ReDrawResources := ReDrawArmySize := ReDrawWorker := RedrawUnit := ReDrawIdleWorkers := ReDrawLocalPlayerColour := 1
		getPlayers(aPlayer, aLocalPlayer)
		GameType := GetGameType(aPlayer)	; used by unit detection (and used inside it)	
		SetMiniMap(minimap)
		setupMiniMapUnitLists(aMiniMapUnits) ; aMiniMapUnits is super global
		EnemyBaseList := GetEBases()
		
		; Lets just always run this routine. It's easier than toggling timer on/off when user changes settings
		; via hotkey. And although it does create a DIB, it still wouldn't use any CPU while running 
		; and not drawing.
		;If (DrawMiniMap || DrawAlerts || DrawSpawningRaces || DrawPlayerCameras || warpgate_warn_on
		;|| alert_array[GameType, "Enabled"])
		SetTimer, MiniMap_Timer, %MiniMapRefresh%, -7

		; Resume warning is written inside the doUnitDetection when called via Save
		if ((ResumeWarnings || UserSavedAppliedSettings) && alert_array[GameType, "Enabled"])  
			doUnitDetection(0, 0, 0, "Resume")
		Else
			doUnitDetection(0, 0, 0, "Reset") ; clear the variables within the function			
		if (warpgate_warn_on && aLocalPlayer["Race"] = "Protoss") || supplyon || alert_array[GameType, "Enabled"]
		|| ( (aLocalPlayer["Race"] = "Terran" && WarningsWorkerTerranEnable) || (aLocalPlayer["Race"] = "Protoss" && WarningsWorkerProtossEnable) || (aLocalPlayer["Race"] = "Zerg" && WarningsWorkerProtossEnable))
		|| geyserOversaturationCheck	
			settimer, unit_bank_read, 1500, -6   ; unitdetecion performed every second run. ; 2500 worked well %UnitDetectionTimer_ms% ; previous was 4000
		else settimer, unit_bank_read, off
		if (aLocalPlayer["Race"] = "Terran" && WarningsWorkerTerranEnable) || (aLocalPlayer["Race"] = "Protoss" && WarningsWorkerProtossEnable) 
			settimer, workerTerranProtossCheck, 1000, -5
		else settimer, workerTerranProtossCheck, off
		;settimer, worker, % workeron ? 1000 : "off", -5
		settimer, supply, % supplyon ? 200 : "off", -5
		settimer, gClock, 1000, -4
		settimer, geyserOversaturationCheck, % WarningsGeyserOverSaturationEnable ? 250 : "Off"

	}
	else 
	{
		SetTimer, MiniMap_Timer, off
		SetTimer, unit_bank_read, off
		SetTimer, workerTerranProtossCheck, off
		SetTimer, geyserOversaturationCheck, off
		SetTimer, supply, off
		SetTimer, gClock, off
		DestroyOverlays()
	}
	return
}

; If user presses spawning race hotkey, then nothing will happen if 
; they don't also have one of the settings enabled which activates this timer

MiniMap_Timer:
	if WinActive(GameIdentifier)
		DrawMiniMap()
	else if !ReDrawMiniMap
		DestroyOverlays()
	sleep, 10 
	; sleep incase have v. fast refresh rates or slow computer (so CPU usage doesn't increase too much)
	; This is a non-issue for me
Return

ShutdownProcedure:
	Closed := ReadMemory()
	Closed := ReadRawMemory()
	Closed := ReadMemory_Str()
	deletepBitMaps(a_pBitmap)
	deletePens(a_pPens)
	deleteBrushArray(a_pBrushes)

	; if pToken
	; 	Gdip_Shutdown(pToken) ; DO NOT call this here - only one thread needs to call it. Called from main thread on exit 
	ExitApp
Return

DrawMiniMap()
{	global
	local UnitRead_i, unit, type, Owner, Radius, Filter, EndCount, colour, ResourceOverlay_i, unitcount
	, DrawX, DrawY, Width, height, i, hbm, hdc, obm, G,  Region, pBitmap, PlayerColours, aUnitsToDraw, hwnd1, unit, x, y
	static overlayCreated := 0, overlayTitle := ""

	if (ReDrawMiniMap and WinActive(GameIdentifier))
	{
		Try Gui, MiniMapOverlay: Destroy
		overlayCreated := False
		ReDrawMiniMap := 0
	}

	If (!overlayCreated)
	{
		if (overlayTitle = "")
			overlayTitle := getRandomString_Az09(10, 20)		
		; Set the width and height we want as our drawing area, to draw everything in. This will be the dimensions of our bitmap
		; Create a layered window ;E0x20 click thru (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption		
		Gui, MiniMapOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound +ToolWindow +AlwaysOnTop
		Gui, MiniMapOverlay: Show, NA, %overlayTitle%
	}
	; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
	;only draw on left side of the screen - DIB size influences speed considerably
	; but im too lazy to convert (drawing pos) the code so that DIB with fully screen height isn't required.
	; Update: DIB size does not influence draw speed. But it does slow down the call to GraphicsClear
	; but since creating a new dib every time, this call isn't required!
	hbm := CreateDIBSection(A_ScreenWidth/4, A_ScreenHeight) 
	, hdc := CreateCompatibleDC()
	, obm := SelectObject(hdc, hbm)
	, G := Gdip_GraphicsFromHDC(hdc) ;needs to be here
	;DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)	;DO NOT USE. Slow and not required
	, Region := Gdip_GetClipRegion(G)
	, Gdip_SetClipRect(G, minimap.ScreenLeft, minimap.ScreenTop, minimap.Width, minimap.Height, 0)

	if DrawMiniMap
	{
	;	pBrushWhite := Gdip_BrushCreateSolid(0xffffffff)
	;	Gdip_FillRectangle(G, pBrushWhite, minimap.BorderLeft, minimap.BorderTop , minimap.BorderWidth , minimap.BorderHeight)
	;	Gdip_DeleteBrush(pBrushWhite)
		
 		getEnemyUnitsMiniMap(aUnitsToDraw)
 		if DrawUnitDestinations
 			Gdip_SetSmoothingMode(G, 4), drawUnitDestinations(G, aUnitsToDraw, aSpecialAlerts)
 		; Don't anti alias. As that will blur where the rectangle meets the fill colour	
 		Gdip_SetSmoothingMode(G, 3)
		for index, unit in aUnitsToDraw.Normal
			drawUnitRectangle(G, unit.X, unit.Y, unit.Radius)	;draw rectangles first
		for index, unit in aUnitsToDraw.Custom
			drawUnitRectangle(G, unit.X, unit.Y, unit.Radius)
		for index, unit in aUnitsToDraw.Normal
			FillUnitRectangle(G, unit.X, unit.Y, unit.Radius, unit.Colour)	
		; Fill the custom highlighted units last, so that their colours won't be drawn over.			
		for index, unit in aUnitsToDraw.Custom
			FillUnitRectangle(G, unit.X, unit.Y, unit.Radius, unit.Colour)
		if DrawUnitDestinations
		{
			For i, alert in aSpecialAlerts
				Gdip_DrawImage(G, alert.pBitmap, alert.x, alert.y, alert.Width, alert.Height, 0, 0, alert.Width, alert.Height)
		}
	}
	Gdip_SetInterpolationMode(G, 2)	
	If (DrawSpawningRaces && getTime() - round(TimeReadRacesSet) <= 14) ;round used to change undefined var to 0 for resume so dont display races
	{	
		;TimeReadRacesSet gets set to 0 at start of match
		loop, parse, EnemyBaseList, |
		{		
			type := getUnitType(A_LoopField)
			getUnitMinimapPos(A_LoopField, BaseX, BaseY)
			if ( type = aUnitID["Nexus"]) 		
			{	pBitmap := a_pBitmap["Protoss","RacePretty"]
				Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)	
				Gdip_DrawImage(G, pBitmap, (BaseX - Width/5), (BaseY - Height/5), Width//2.5, Height//2.5, 0, 0, Width, Height)
			}
			Else if (type = aUnitID["CommandCenter"] || type = aUnitID["PlanetaryFortress"] || type =  aUnitID["OrbitalCommand"])
			{
				pBitmap := a_pBitmap["Terran","RacePretty"]
				Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)
				Gdip_DrawImage(G, pBitmap, (BaseX - Width/10), (BaseY - Height/10), Width//5, Height//5, 0, 0, Width, Height)
			}
			Else if (type = aUnitID["Hatchery"] || type =  aUnitID["Lair"] || type =  aUnitID["Hive"])
			{	pBitmap := a_pBitmap["Zerg","RacePretty"]
				Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)
				Gdip_DrawImage(G, pBitmap, (BaseX - Width/6), (BaseY - Height/6), Width//3, Height//3, 0, 0, Width, Height)
			}
		}
	}
	if DrawAlerts
	{
		While (A_index <= aMiniMapWarning.MaxIndex())
		{	
			; this will remove warnings when they time out or if the unit had died 
			; or been cancelled and replaced with another one 

			unit := aMiniMapWarning[A_index, "Unit"]
			owner := getUnitOwner(aMiniMapWarning[A_index,"Unit"])	

			If (Time - aMiniMapWarning[A_index, "Time"] >= 20 ;display for 20 seconds
			|| getUnitTimer(unit) < aMiniMapWarning[A_index, "UnitTimer"]
			|| owner != aMiniMapWarning[A_index, "Owner"]
			|| getUnitType(unit) != aMiniMapWarning[A_index, "Type"])
			{	
				aMiniMapWarning.Remove(A_index, "")
				continue
			}
			
			If (aPlayer[owner, "Team"] <> aLocalPlayer["Team"])
			{
				If (arePlayerColoursEnabled() AND aPlayer[Owner, "Colour"] = "Green")
					pBitmap := a_pBitmap["PurpleX16"] 
				Else pBitmap := a_pBitmap["GreenX16"]
			}
			Else 
				pBitmap := a_pBitmap["RedX16"]
			getUnitMinimapPos(aMiniMapWarning[A_index,"Unit"], X, Y)

			Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)	
		;	Gdip_DrawImage(G, pBitmap, (X - Width/2), (Y - Height/2), Width, Height, 0, 0, Width, Height)	
			Gdip_DrawImage(G, pBitmap, (X - Width/2), (Y - Height/2), Width, Height, 0, 0, Width, Height)	
		} 
	}
	if DrawPlayerCameras
		Gdip_SetSmoothingMode(G, 4), drawPlayerCameras(G) ; Can't really see a diference between HighQuality and AntiAlias
	Gdip_DeleteRegion(Region)
	, Gdip_DeleteGraphics(G)
	, UpdateLayeredWindow(hwnd1, hdc, 0, 0, A_ScreenWidth/4, A_ScreenHeight, overlayMinimapTransparency) ;only draw on left side of the screen
	, SelectObject(hdc, obm) ; needed else eats ram ; Select the object back into the hdc
	, DeleteObject(hbm)   ; needed else eats ram 	; Now the bitmap may be deleted
	, DeleteDC(hdc) ; Also the device context related to the bitmap may be deleted
Return
}

getEnemyUnitsMiniMap(byref aUnitsToDraw)
{  LOCAL UnitAddress, pUnitModel, Filter, MemDump, Radius, x, y, PlayerColours, MemDump, PlayerColours, owner, unitName
 	, Colour, Type, QueuedCommands
  
  aUnitsToDraw := [], aUnitsToDraw.Normal := [], aUnitsToDraw.Custom := []
  PlayerColours := arePlayerColoursEnabled()
  loop, % DumpUnitMemory(MemDump)
  {
     Filter := numget(MemDump, (UnitAddress := (A_Index - 1) * S_uStructure) + O_uTargetFilter, "Int64")
     ; Hidden e.g. marines in medivac/bunker etc. 
     ; Otherwise these unit colours get drawn over the top - medivac highlight colour is hidden.
     if (Filter & DeadFilterFlag || Filter & aUnitTargetFilter.Hidden || aMiniMapUnits.Exclude.HasKey(Type := numgetUnitModelType(pUnitModel := numget(MemDump, UnitAddress + O_uModelPointer, "Int"))))
     	Continue

     ;if  (aPlayer[Owner, "Team"] <> aLocalPlayer["Team"] && Owner && type >= aUnitID["Colossus"] && !aChangeling.HasKey(type)) 
     ;|| (aChangeling.HasKey(type) && aPlayer[Owner, "Team"] = aLocalPlayer["Team"] ) ; as a changeling owner becomes whoever it is mimicking - its team also becomes theirs
     
     if (aPlayer[owner := numget(MemDump, UnitAddress + O_uOwner, "Char"), "Team"] != aLocalPlayer["Team"] && Owner && type >= aUnitID["Colossus"])  ; This changeling check is no longer required as reading the first unit owner now (not the third)
     {
          if (!Radius := aUnitInfo[Type, "Radius"])
              Radius := aUnitInfo[Type, "Radius"] := numgetUnitModelMiniMapRadius(pUnitModel)

         if (Radius < minimap.UnitMinimumRadius) ; probes and such
           	Radius := minimap.UnitMinimumRadius

	       x := numget(MemDump, UnitAddress + O_uX, "int")/4096
           , y := numget(MemDump, UnitAddress + O_uY, "int")/4096
           , customFlag := True
	      , mapToMinimapPos(x, y) ; don't round them. As fraction might be important when subtracting scaled width in draw/fill rectangle

           if (HighlightInvisible && Filter & aUnitTargetFilter.Hallucination) ; have here so even if non-halluc unit type has custom colour highlight, it will be drawn using halluc colour
           	  Colour := "UnitHighlightHallucinationsColour"
           else if aMiniMapUnits.Highlight.HasKey(type)
          	Colour := aMiniMapUnits.Highlight[type]
           Else if (HighlightInvisible && Filter & aUnitTargetFilter.Cloaked) ; this will include burrowed units (so dont need to check their flags)
           	  Colour := "UnitHighlightInvisibleColour" 				; Have this at bot so if an invis unit has a custom highlight it will be drawn with that colour
           Else if PlayerColours
              Colour := aPlayer[Owner, "Colour"], customFlag := False
           Else Colour := "Red", customFlag := False

           if (HostileColourAssist && GameType != "1v1")
           {
	           unitName := aUnitName[type]
	           if unitName in CommandCenter,CommandCenterFlying,OrbitalCommand,PlanetaryFortress,Nexus,Hatchery,Lair,Hive
	          		Colour := aPlayer[Owner, "Colour"], customFlag := True
	       }
	       	if DrawUnitDestinations
	       		getUnitQueuedCommands(A_Index - 1, QueuedCommands)
          	if customFlag
           		aUnitsToDraw.Custom.insert({"X": x, "Y": y, "Colour": Colour, "Radius": Radius, unit: A_index -1, "queuedCommands": QueuedCommands})  
           	else
           		aUnitsToDraw.Normal.insert({"X": x, "Y": y, "Colour": Colour, "Radius": Radius, unit: A_index -1, "queuedCommands": QueuedCommands})  
     }
  }
  Return
}

drawUnitDestinations(pGraphics, byRef aUnitsToDraw, byRef aSpecialAlerts)
{	
	aSpecialAlerts := [] ; so nukes are not obstructed by unit being drawn over the top
	loop, 2 ; Using a 2x loop should be faster than an another for loop on top
	{
		for indexOuter, unit in (A_Index = 1 ? aUnitsToDraw.Normal : aUnitsToDraw.Custom)
		{
			for indexQueued, command in unit.QueuedCommands
			{
				if (command.ability = "attack")
					colour := "Red"
				else if (command.ability = "move")
				{
					; Not only the current patrol waypoint/destination will be drawn. That is, patrol move can shift queue multiple patrol waypoints/paths
					; But only the current one or first one (if there are other preceding move commands) will be drawn.
					; Obviously any preceding non-patrol move commands will also be drawn if these exist. 
					; If another command is queued after a multi waypoint patrol, then SC will remove the extra patrol points and add
					; the move command. This function will draw all of these correctly. 
					if (command.State = aUnitMoveStates.Patrol) 
						colour := "Blue"
					else colour := "Green"

				}
				else if (command.ability = "MedivacTransport"
				|| command.ability = "WarpPrismTransport"
				|| command.ability = "OverlordTransport")
				{
					colour := "Orange"
				}
				; as destinations are drawn first, the picture gets drawn over by unit boxes
				else if (command.ability = "TacNukeStrike")
				{	
					mapToMinimapPos(x := command.targetX, y := command.targetY)
					Width := Gdip_GetImageWidth(pBitmap := a_pBitmap["pingNuke"]), Height := Gdip_GetImageHeight(pBitmap)	
					;Gdip_DrawImage(pGraphics, pBitmap, (X - Width/2), (Y - Height/2), Width, Height, 0, 0, Width, Height)
					aSpecialAlerts.Insert( {pBitmap: pBitmap, Width: Width, Height: Height, x: X - Width/2, y : Y - Height/2})
					colour := "Yellow"
					; better to actually just let it draw a yellow line so if not shift queued, can see units move path
					;continue 
				}
				else colour := "Green"

				; some commands will have x,y,z targets of 0 (causing them to be drawn off the map)
				if !command.targetX
					break
				if (indexQueued = unit.QueuedCommands.MinIndex())
					x := unit.x, y := unit.y 	
				Else 
					x := targetX, y := targetY
				mapToMinimapPos(targetX := command.targetX, targetY := command.targetY)	
				Gdip_DrawLine(pGraphics, a_pPens[colour], x, y, targetX, targetY)
			}
		}
	}
	return
}

createPens(penSize)
{
	a_pPens := []
	for colour, hexValue in aHexColours
		a_pPens[Colour] := Gdip_CreatePen(0xcFF hexValue, penSize)
	return a_pPens
}
; If hotkey/function called twice (the second call occurs before the timer runs) the second call
; won't do anything i.e. it wont extend the time that these remain hidden
temporarilyHideMinimap()
{
	Global DrawMiniMap, DrawPlayerCameras, DrawAlerts, DrawSpawningRaces
	static ReDrawMiniMap, ReDrawPlayerCams, ReDrawAlerts, ReDrawSpawningRaces

	if (DrawMiniMap || DrawPlayerCameras || DrawAlerts || DrawSpawningRaces)
	{
		if DrawPlayerCameras
			DrawPlayerCameras := False, ReDrawPlayerCams := True
		if DrawAlerts
			DrawAlerts := False, ReDrawAlerts := True
		if DrawSpawningRaces
			DrawSpawningRaces := False, ReDrawSpawningRaces := True
		if DrawMiniMap
			DrawMiniMap := False, ReDrawMiniMap := True
		gosub, MiniMap_Timer ; so minimap disappears instantly 
		SetTimer, __temporarilyHideMinimapResume, -2500
	}
	return
	__temporarilyHideMinimapResume:
	if ReDrawMiniMap
		DrawMiniMap := True, ReDrawMiniMap := False
	if ReDrawPlayerCams 
		DrawPlayerCameras := true, ReDrawPlayerCams := False
	if ReDrawAlerts
		DrawAlerts := True, ReDrawAlerts := False
	if ReDrawSpawningRaces
		DrawSpawningRaces := True, ReDrawSpawningRaces := False
	gosub, MiniMap_Timer
	return
}

/*
	x,y co-ordinates
	1--------------------2
	\                   /
     \     centre      /
      \               /
       4-------------3

	Im bad at math so I just made this using trial and error
	it scales close enough for map sizes and zoom angles.
	(if bored might add roll/yaw or whatever it's called)
*/

drawPlayerCameras(pGraphics)
{
	static maxAngle := 1.195313
	For slotNumber in aPlayer
	{
		If (aLocalPlayer.Team != aPlayer[slotNumber].Team 
		&& isPlayerActive(slotNumber) 
		&& aPlayer[slotNumber].Type != "Computer") ; As AI don't move the camera
		{
			angle := getPlayerCameraAngle(slotNumber)
			xCenter := getPlayerCameraPositionX(slotNumber)
			yCenter := getPlayerCameraPositionY(slotNumber)
			mapToMinimapPos(xCenter, yCenter)

			x1 := xCenter - (19/1920*A_ScreenWidth/minimap.MapPlayableWidth * minimap.Width) * (angle/maxAngle)**2
			y1 := yCenter - (13/1080*A_ScreenHeight/minimap.MapPlayableHeight * minimap.Height) * angle/maxAngle
			
			x2 := x1 + (36/1920*A_ScreenWidth/minimap.MapPlayableWidth * minimap.Width) * (angle/maxAngle)**2
			y2 := y1 

			x3 := (x2 - (x2 - x1)/2) + (xOffset := 14/1920*A_ScreenWidth/minimap.MapPlayableWidth * minimap.Width * (angle/maxAngle)**3)
			y3 := y2 + ((18/1080*A_ScreenHeight /minimap.MapPlayableHeight * minimap.Height) * angle/maxAngle)

			x4 := x1 + ((x2 - x1)/2) - xOffset
			y4 := y3 

			Gdip_DrawLines(pGraphics, a_pPens[aPlayer[slotNumber, "colour"]],  x1 "," y1 "|" x2 "," y2 "|" x3 "," y3 "|" x4 "," y4 "|" x1 "," y1 )
		}
	}
	return 
}

/*
	2V2 each player near 200/200 time of routine
	8.659650
	3.111926 ; Skip unit detection
	8.881199 ; Unit Detection
	3.523995
*/

unit_bank_read:
;thread, NoTimers, true
;timerID := stopwatch()

; Unit detection function is relatively slow, so only do it on every second routine call
; this allows this routine to be called faster to keep the other info up-to-date more quickly
unit_bank_readCallCount++
doUnitDetectionOnThisRun := Mod(unit_bank_readCallCount, 2) * (alert_array[GameType, "Enabled"] = 1)
; If nothing is on or if only unitdetection is on but it is to be skipped on this pass, just return
if !(warpgate_warn_on && aLocalPlayer["Race"] = "Protoss") && !WarningsGeyserOverSaturationEnable && !supplyon && !workeron && !doUnitDetectionOnThisRun
&& !(WarningsWorkerZergEnable && aLocalPlayer["Race"] = "Zerg")
	return

SupplyInProductionCount := gateway_count := warpgate_count := ZergWorkerInProductionCount := 0
If (aLocalPlayer["Race"] = "Terran")
	SupplyType := aUnitID["SupplyDepot"], geyserStructure := aUnitID["Refinery"]
Else If (aLocalPlayer["Race"] = "Protoss")
	SupplyType := aUnitID["Pylon"], geyserStructure := aUnitID["Assimilator"]
else If (aLocalPlayer["Race"] = "Zerg")
	SupplyType := aUnitID["Egg"], geyserStructure := aUnitID["Extractor"]	
Time := getTime()
a_BaseListTmp := [], aGeyserStructuresTmp := []
loop, % DumpUnitMemory(UBMemDump)
{ 
	u_iteration := A_Index -1
	If ((Filter := numgetUnitTargetFilter(UBMemDump, u_iteration)) & DeadFilterFlag
		|| !(unit_owner := numgetUnitOwner(UBMemDump, u_iteration))
		|| (aLocalPlayer["Team"] = aPlayer[unit_owner, "Team"] && unit_owner != aLocalPlayer["Slot"]))
		Continue
	; so these units are alive, and either local or enemy units (and not neutral player 0)
	unit_type := numgetUnitModelType(numgetUnitModelPointer(UBMemDump, u_iteration))
	if  (unit_type < aUnitID["Colossus"]) ; First 'real' unit
		continue	

	if (unit_owner = aLocalPlayer["Slot"])
	{
		If (unit_type = supplytype) 
		{
			if (unit_type = aUnitID["Egg"]) ; Eggs already constructed
			{
				aProduction := getZergProductionFromEgg(u_iteration)
				if (aProduction.Type = aUnitID["Overlord"])
					SupplyInProductionCount++
				else if (aProduction.Type = aUnitID["Drone"])	
					ZergWorkerInProductionCount++
			}
			; So If unit is pylon/supply deopt and owner is protoss OR terran AND the supply depot is actively being constructed by an SCV
			else if (Filter & aUnitTargetFilter.UnderConstruction && (aLocalPlayer["Race"] != "Terran" || isBuildInProgressConstructionActive(numgetUnitAbilityPointer(UBMemDump, u_iteration), unit_type)))
				SupplyInProductionCount++	
		}
		else if ( warpgate_warn_on AND (unit_type = aUnitID["Gateway"] OR unit_type = aUnitID["WarpGate"]) 
		AND !(Filter & aUnitTargetFilter.UnderConstruction))
		{
			if ( unit_type = aUnitID["Gateway"]) 
			{
				gateway_count ++	
				if warpgate_warning_set
				{
					isinlist := 0
					For index in aGatewayWarnings
					{
						if aGatewayWarnings[index,"Unit"] = u_iteration
						{	
							isinlist := 1
							Break
						}		
					}
					if !isinlist
						aGatewayWarnings.insert({ "Unit": u_iteration 
												, "Time": Time
												, "UnitTimer": getUnitTimer(u_iteration)
												, "Type": unit_type
												, "Owner":  unit_owner})
				} 
			}
			Else if (unit_type = aUnitID["WarpGate"] && !isWarpGateTechComplete) ; as unit_type must = warpgate_id
			{
				isWarpGateTechComplete := True
			;	settimer warpgate_warn, 1000
			}
		}
		else if !(Filter & aUnitTargetFilter.UnderConstruction)
		{
			if (unit_type = aUnitID["Nexus"] || unit_type = aUnitID["CommandCenter"] 
			|| unit_type =  aUnitID["PlanetaryFortress"] || unit_type =  aUnitID["OrbitalCommand"])
				a_BaseListTmp.insert(u_iteration)
			else if (unit_type = geyserStructure)
				aGeyserStructuresTmp.insert(u_iteration)
		}
	}
	else if doUnitDetectionOnThisRun ; these units are enemies
		doUnitDetection(u_iteration, unit_type, unit_owner)
}
if warpgate_warn_on
	gosub warpgate_warn
SupplyInProduction := SupplyInProductionCount
ZergWorkerInProduction := ZergWorkerInProductionCount
a_BaseList := a_BaseListTmp,  aGeyserStructures := aGeyserStructuresTmp
if (WarningsWorkerZergEnable && aLocalPlayer["Race"] = "Zerg")
	gosub workerZergCheck
;log(stopwatch(timerID))
return


;--------------------
;	WarpGate Warning
;--------------------

;	I think the problem here is if a user converts a warpate while the timer isnt running and then another warpgate finishes
;	it will rewarn the user even though it hasn't really waited the correct amount of time
;  also remeber that it only updates gateway/warpgate count after doing a unit bank read /iteration

; note: wargate warning only drawn for a set amount of time as the 'time' is only read in once in the unit bank section - so if user has a long follow up delay, that wont be accompanied by a minimap alert

warpgate_warn:
	if  (!isWarpGateTechComplete)
		return
	if gateway_count  ; this remove warning x on the minmap once they start converting to warpgates - so don't have to wait for the alert 'x' to naturally time out in the minimap section
		for index, object in aGatewayWarnings
			if (getUnitType(object.unit) != aUnitID["Gateway"] || isUnitDead(object.unit) || !isUnitLocallyOwned(object.unit) ) ;doing this in case unit dies or becomes other players gateway as this list onyl gets cleared when gateway count = 0
			|| isGatewayConvertingToWarpGate(object.unit)
			{
				for minimapIndex, minimapObject in aMiniMapWarning
					if (minimapObject.unit = object.unit)
					{
						aMiniMapWarning.remove(minimapIndex, "") 
						break
					}
				aGatewayWarnings.remove(index, "") ; "" so deleting doesnt stuff up for loop		
			}

	if (gateway_count AND !warpgate_warning_set)
	{
		warpgateGiveWarningAt := getTime() + delay_warpgate_warn
		warpgate_warning_set := 1
	}
	else if ( !gateway_count  )
	{
		warpgate_warn_count := 0
		warpgate_warning_set := 0

		for index, object in aGatewayWarnings
			for minimapIndex, minimapObject in aMiniMapWarning
				if (minimapObject.unit = object.unit)
					minimapObject.remove(minimapIndex, "")        ;lets clear the list of old gateway warnings. This gets rid of the x as soon as the gateway becomes a warpgate
		aGatewayWarnings := []

	}
	else if ( warpgate_warn_count <= sec_warpgate && time > warpgateGiveWarningAt) 
	{
		warpgate_warn_count ++
		warpgateGiveWarningAt := getTime() + delay_warpgate_warn_followup
		time := getTime()
		for index, object in aGatewayWarnings
		{
			object.time := time ; so this will display an x even with long  follow up delay
			aMiniMapWarning.insert(object)
		}

		if aGatewayWarnings.maxindex()
			tSpeak(w_warpgate)	
	}

return

;--------------------------------------------
;    suply -------------
;--------------------------------------------

supply:
	sup:= getPlayerSupply(), SupCap := getPlayerSupplyCap() ; Returns 0 when memory returns Fail
	if  ( !sup or sup < minimum_supply )  		;this prevents the onetime speaking before a value has been read for sup - Note 0 instead of fail due to math procedures above
		return 
	Else If ( sup < supplylower )
		trigger := sub_lowerdelta
	Else If ( sup >= supplylower AND sup < supplymid )	
		trigger := sub_middelta
	Else If ( sup >= supplymid AND sup < supplyupper )	
		trigger := sub_upperdelta
	Else if ( sup >= supplyupper )
		trigger := above_upperdelta
	if ( ( sup + trigger ) >= supcap AND supcap < 200 And !SupplyInProduction)	
	{
									; <= sec_supply, as this includes the 1st primary warning
		if (Supply_i <= sec_supply )  ; sec_supply sets how many times alert will be played it should be counted.
		{
			tSpeak(w_supply)	;this is the supply warning
			settimer, supply, % additional_delay_supply *1000
		}
		Else	; this ensures follow up warnings are not delayed by waiting for additional seconds before running timmer
			settimer, supply, 200
		Supply_i ++	
	}
	else
	{
		Supply_i = 0 	; reset alert count
		settimer, supply, 200
	}
return


;--------------------------------------------
;    worker production -------------
;--------------------------------------------
; This is performed after every unit bank read ~1500ms
workerZergCheck:
time := getTime()
workerCount := getPlayerWorkerCount()

if (ZergWorkerInProduction || workerCount < WarningsWorkerZergMinWorkerCount || workerCount > WarningsWorkerZergMaxWorkerCount)	
{
	ZergLastWokerMadeTime := time, zergWorkerWarningCount = 0
	ZergWarningTimeForNoWorkers := WarningsWorkerZergTimeWithoutProduction
}
else if (time - ZergLastWokerMadeTime > ZergWarningTimeForNoWorkers && zergWorkerWarningCount <= WarningsWorkerZergFollowUpCount) 
{ 
	ZergWarningTimeForNoWorkers := WarningsWorkerZergFollowUpDelay ; will give the second warning after 12 ingame seconds
	ZergLastWokerMadeTime := time		; This allows for the additional warnings to be delayed relative to the 1st warning
	zergWorkerWarningCount++
	tSpeak(WarningsWorkerZergSpokenWarning)
}
return

workerTerranProtossCheck:
if aLocalPlayer["Race"] = "Terran"
{
		workerWarningMaxIdleTime := WarningsWorkerTerranTimeWithoutProduction
		, workerWarningMaxWarnings := WarningsWorkerTerranFollowUpCount
		, workerWarningFollowUpDelay := WarningsWorkerTerranFollowUpDelay
		, workerWarningMaxWorkerCount := WarningsWorkerTerranMaxWorkerCount
		, workerWarningMinWorkerCount := WarningsWorkerTerranMinWorkerCount
		, workerWarningSpokenWarning := WarningsWorkerTerranSpokenWarning
}
else 
{
		workerWarningMaxIdleTime := WarningsWorkerProtossTimeWithoutProduction
		, workerWarningMaxWarnings := WarningsWorkerProtossFollowUpCount
		, workerWarningFollowUpDelay := WarningsWorkerProtossFollowUpDelay
		, workerWarningMaxWorkerCount := WarningsWorkerProtossMaxWorkerCount
		, workerWarningMinWorkerCount := WarningsWorkerProtossMinWorkerCount
		, workerWarningSpokenWarning := WarningsWorkerProtossSpokenWarning	
}
WorkerInProductionWarning(a_BaseList, workerWarningMaxIdleTime, 1 + workerWarningMaxWarnings, workerWarningFollowUpDelay, workerWarningMaxWorkerCount, workerWarningMinWorkerCount, workerWarningSpokenWarning)
return


WorkerInProductionWarning(a_BaseList, maxIdleTime, maxWarnings, folloupWarningDelay, MaxWorkerCount, MinWorkerCount, warning)	;add secondary delay and max workers
{
	static lastWorkerInProduction, warningCount, lastwarning
	
	time := getTime()
	workerCount := getPlayerWorkerCount()
	if (workerCount < MinWorkerCount || workerCount > MaxWorkerCount)	;stop warnings enough workers
	{
		lastWorkerInProduction := time	
		return
	}
	
	for index, Base in a_BaseList
	{
		; -2 cc/orbital flying
		; -1 CC moring
		; 0 No worker
		; +Int workers
		if (state := isWorkerInProduction(Base)) > 0
		{
			; If just one Base has a worker in production return.
			warningCount := 0
			lastWorkerInProduction := time
			return
		}
		else if (state < 0) ; morphing or flying
			morphingFlyingBases++
		else lazyBases++	
	}
	; hence will only warn if there are no workers in production
	; and at least 1 building is capable of making workers i.e not flying/morphing	
	; also this prevents you getting a warning immediately after the base finishes morphing
	if !lazyBases && morphingFlyingBases
		lastWorkerInProduction := time	
	else if lazybases && (time - lastWorkerInProduction >= maxIdleTime) && ( warningCount < maxWarnings)
	{
		if (warningCount && time - lastwarning < folloupWarningDelay)
			return
		lastwarning := time
		warningCount++
		tSpeak(warning)
	}
	return 
}

geyserOversaturationCheck:
geyserOversaturationWarning(aGeyserStructures, WarningsGeyserOverSaturationMaxWorkers, WarningsGeyserOverSaturationMaxTime, WarningsGeyserOverSaturationFollowUpCount, WarningsGeyserOverSaturationFollowUpDelay, WarningsGeyserOverSaturationSpokenWarning)
return 

geyserOversaturationWarning(aGeyserStructures, maxWorkers, maxTime, maxWarnings, folloupWarningDelay, warning)
{
	global aMiniMapWarning
	static aWarnings := []
	time := getTime()
	If (aLocalPlayer["Race"] = "Terran")
		geyserStructure := aUnitID["Refinery"]
	Else If (aLocalPlayer["Race"] = "Protoss")
		geyserStructure := aUnitID["Assimilator"]
	else If (aLocalPlayer["Race"] = "Zerg")
		geyserStructure := aUnitID["Extractor"]
	; Remove old warnings from previous game or if geyser no longer exists
	for unit in aWarnings
	{
		if !aGeyserStructures
			aWarnings.Remove(unit, "")		
	}
	for i, unit in aGeyserStructures
	{
		if getUnitType(unit) = geyserStructure && !(getUnitTargetFilter(unit) & (aUnitTargetFilter.UnderConstruction | aUnitTargetFilter.Dead))
		{
			if getResourceWorkerCount(unit, aLocalPlayer["Slot"]) >= maxWorkers
			{
				if !aWarnings.HasKey(unit)
					aWarnings[unit, "start"] := time
				else 
				{
					if (!aWarnings[unit].HasKey("startFollowUp") && time - aWarnings[unit, "start"] >= maxTime)
					|| (aWarnings[unit].HasKey("startFollowUp") && time >= aWarnings[unit, "startFollowUp"] + folloupWarningDelay && aWarnings[unit, "startFollowUpCount"] <= maxWarnings)
					{
						aWarnings[unit, "startFollowUp"] := Time
						, aWarnings[unit, "startFollowUpCount"] := round(aWarnings[unit, "startFollowUpCount"]) + 1
						, aMiniMapWarning.insert({ "Unit": unit
												, "Time":  time
												, "UnitTimer": getUnitTimer(unit)
												, "Type": geyserStructure
												, "Owner":  aLocalPlayer["Slot"]})
						, announceWarning := True
					}
				}
			}
			else if aWarnings.HasKey(unit)
				aWarnings.Remove(unit, "")
		}
	}
	; Remove any old warnings i.e. worker count lowered so they instantly disappear from the screen
	for minimapIndex, object in aMiniMapWarning
	{
		if object.Type = geyserStructure && object.Owner = aLocalPlayer["Slot"] && !aWarnings.HasKey(object.Unit) ; check if still geyser and unitIndex hasn't been reused for another warning type
			aMiniMapWarning.remove(minimapIndex, "") 
	}
	if announceWarning
		tSpeak(warning)
	return
}


/*
		for index, object in aGatewayWarnings
			if ( getUnitType(object.unit) != aUnitID["Gateway"] || isUnitDead(object.unit) || !isUnitLocallyOwned(object.unit) ) ;doing this in case unit dies or becomes other players gateway as this list onyl gets cleared when gateway count = 0
			{
				for minimapIndex, minimapObject in aMiniMapWarning
					if (minimapObject.unit = object.unit)
					{
						aMiniMapWarning.remove(minimapIndex, "") 
						break
					}
				aGatewayWarnings.remove(index, "") ; "" so deleting doesnt stuff up for loop		
			}