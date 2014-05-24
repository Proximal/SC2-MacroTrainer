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
OnExit, ShutdownProcedure ; disabled due to crashing main thread during terminate - called manually now

/* ;Cmdline passed script parameters - Old method - now use globalVarsScript
	pObject := "1", pObject := %pObject%	
	pCriticalSection := "2", pCriticalSection := %pCriticalSection%
	aThreads := CriticalObject(pObject, pCriticalSection)
*/ 

global aThreads

l_GameType := "1v1,2v2,3v3,4v4,FFA"
l_Races := "Terran,Protoss,Zerg"
GLOBAL GameWindowTitle := "StarCraft II"
GLOBAL GameIdentifier := "ahk_exe SC2.exe"
GLOBAL config_file := "MT_Config.ini"
GameExe := "SC2.exe"


#Include <Gdip> ;In the library folder
#Include <SC2_MemoryAndGeneralFunctions> ;In the library folder
; pToken := Gdip_Startup() ; DO NOT get a new token. Not needed and causes crash on exit when calling gdipShutdown()
Global aUnitID, aUnitName, aUnitSubGroupAlias, aUnitTargetFilter, aHexColours, MatrixColour
	, aUnitModel,  aPlayer, aLocalPlayer, minimap
	, a_pBrushes := [], a_pPens := [], a_pBitmap

SetupUnitIDArray(aUnitID, aUnitName)
getSubGroupAliasArray(aUnitSubGroupAlias)
setupTargetFilters(aUnitTargetFilter)
SetupColourArrays(aHexColours, MatrixColour)
; Note: The brushes are initialised within the readConfig function
; so they are updated when user changes custom colour highlights
a_pPens := initialisePenColours(aHexColours)

CreatepBitmaps(a_pBitmap, aUnitID)
aUnitInfo := []
readConfigFile(), hasReadConfig := True
; Just as a backup if the thread gets orphaned
; This is now disabled. I'm not sure if the thread can event get orphaned.....
; But more importantly, if this thread closes, then the main thread tries to exit - it will hang!
;settimer, timer_exit, 15000, -100 
aChangeling := { 	aUnitID["ChangelingZealot"]: True
				 ,	aUnitID["ChangelingMarineShield"]: True 
				 ,	aUnitID["ChangelingMarine"]: True 
				 ,	aUnitID["ChangelingZerglingWings"]: True 
				 ,	aUnitID["ChangelingZergling"]: True }				
gameChange()
return

; Need this, as somtimes call from main thread to gameChange() fails
; also, sometimes the call succeeds, but the timers remain on
; it's fucking retarded!

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
		game_status := "game", warpgate_status := "not researched", gateway_count := warpgate_warning_set := 0
		TimeReadRacesSet := 0
		; aStringTable and aUnitModel are super global declared in memory and general functions
		aUnitModel := [] 		
		aStringTable := []
		MiniMapWarning := [], a_BaseList := [], aGatewayWarnings := []
		if WinActive(GameIdentifier)
			ReDrawMiniMap := ReDrawIncome := ReDrawResources := ReDrawArmySize := ReDrawWorker := RedrawUnit := ReDrawIdleWorkers := ReDrawLocalPlayerColour := 1
		getPlayers(aPlayer, aLocalPlayer)
		GameType := GetGameType(aPlayer)
		If (aLocalPlayer["Race"] = "Terran")
			SupplyType := aUnitID["SupplyDepot"]
		Else If (aLocalPlayer["Race"] = "Protoss")
			SupplyType := aUnitID["Pylon"]			
		SetMiniMap(minimap)
		setupMiniMapUnitLists(aMiniMapUnits) ; aMiniMapUnits is super global
		EnemyBaseList := GetEBases()
		
		If (DrawMiniMap || DrawAlerts || DrawSpawningRaces || warpgate_warn_on
		|| alert_array[GameType, "Enabled"])
			SetTimer, MiniMap_Timer, %MiniMapRefresh%, -7
		if (warpgate_warn_on || supplyon || workeron || alert_array[GameType, "Enabled"]) 
			settimer, unit_bank_read, %UnitDetectionTimer_ms%, -6
		if workeron
			settimer, worker, 1000, -5
		if supplyon
			settimer, supply, 200, -5
		if ((ResumeWarnings || UserSavedAppliedSettings) && alert_array[GameType, "Enabled"])  
			doUnitDetection(0, 0, 0, "Resume")
		Else
			doUnitDetection(0, 0, 0, "Reset") ; clear the variables within the function	
		settimer, gClock, 1000, -4
	}
	else 
	{
		SetTimer, MiniMap_Timer, off
		SetTimer, unit_bank_read, off
		SetTimer, worker, off
		SetTimer, supply, off
		SetTimer, gClock, off
		DestroyOverlays()
	}
	return "testValue"
}


MiniMap_Timer:
	if WinActive(GameIdentifier) 
		DrawMiniMap()
	else if !ReDrawMiniMap
		DestroyOverlays()
Return

timer_Exit:
{
	process, exist, %GameExe%
	if !errorlevel 		;errorlevel = 0 if not exist
		ExitApp ; this will run the shutdown routine below
}
return

; This is now called from the main thread to avoid crashing
ShutdownProcedure:
	Closed := ReadMemory()
	Closed := ReadRawMemory()
	Closed := ReadMemory_Str()
	; if pToken
	; 	Gdip_Shutdown(pToken) ; DO NOT call this here - only one thread needs to call it. Called from main thread on exit 
	ExitApp
Return

DrawMiniMap()
{	global
	local UnitRead_i, unit, type, Owner, Radius, Filter, EndCount, colour, ResourceOverlay_i, unitcount
	, DrawX, DrawY, Width, height, i, hbm, hdc, obm, G,  pBitmap, PlayerColours, A_MiniMapUnits, hwnd1, unit, x, y
	static overlayCreated := 0

	if (ReDrawMiniMap and WinActive(GameIdentifier))
	{
		Try Gui, MiniMapOverlay: Destroy
		overlayCreated := False
		ReDrawMiniMap := 0
	}

	If (!overlayCreated)
	{
		; Set the width and height we want as our drawing area, to draw everything in. This will be the dimensions of our bitmap
		; Create a layered window ;E0x20 click thru (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption		
		Gui, MiniMapOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound +ToolWindow +AlwaysOnTop
		; Show the window
		Gui, MiniMapOverlay: Show, NA
		; Get a handle to this window we have created in order to update it later
	;	hwnd1 := WinExist()
	}
		; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
		hbm := CreateDIBSection(A_ScreenWidth/4, A_ScreenHeight) ;only draw on left side of the screen
		; Get a device context compatible with the screen
		hdc := CreateCompatibleDC()
		; Select the bitmap into the device context
		obm := SelectObject(hdc, hbm)
	; Get a pointer to the graphics of the bitmap, for use with drawing functions
	G := Gdip_GraphicsFromHDC(hdc) ;needs to be here
	DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)	
	if DrawMiniMap
	{
		;setDrawingQuality(G)
		Gdip_SetSmoothingMode(G, 4)

		A_MiniMapUnits := []

 		getEnemyUnitsMiniMap(A_MiniMapUnits)

 		if DrawUnitDestinations
 			drawUnitDestinations(G, A_MiniMapUnits)
		for index, unit in A_MiniMapUnits
			drawUnitRectangle(G, unit.X, unit.Y, unit.Radius + minimap.AddToRadius, unit.Radius + minimap.AddToRadius)	;draw rectangles first
		for index, unit in A_MiniMapUnits
			FillUnitRectangle(G, unit.X, unit.Y,  unit.Radius, unit.Radius, unit.Colour)

	}
	If (DrawSpawningRaces) && (getTime() - round(TimeReadRacesSet) <= 14) ;round used to change undefined var to 0 for resume so dont display races
	{	
		Gdip_SetInterpolationMode(G, 7)				;TimeReadRacesSet gets set to 0 at start of match
		loop, parse, EnemyBaseList, |
		{		
			type := getUnitType(A_LoopField)
			getUnitMiniMapMousePos(A_LoopField, BaseX, BaseY)
			if ( type = aUnitID["Nexus"]) 		
			{	pBitmap := a_pBitmap["Protoss","RacePretty"]
				Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)	
				Gdip_DrawImage(G, pBitmap, (BaseX - Width/5), (BaseY - Height/5), Width//2.5, Height//2.5, 0, 0, Width, Height)
			}
			Else if (type = aUnitID["CommandCenter"] || type =  aUnitID["PlanetaryFortress"] || type =  aUnitID["OrbitalCommand"])
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
		While (A_index <= MiniMapWarning.MaxIndex())
		{	
			; this will remove warnings when they time out or if the unit had died 
			; or been cancelled and replaced with another one 

			unit := MiniMapWarning[A_index, "Unit"]
			owner := getUnitOwner(MiniMapWarning[A_index,"Unit"])	

			If (Time - MiniMapWarning[A_index, "Time"] >= 20 ;display for 20 seconds
			|| getUnitTimer(unit) < MiniMapWarning[A_index, "UnitTimer"]
			|| owner != MiniMapWarning[A_index, "Owner"]
			|| getUnitType(unit) != MiniMapWarning[A_index, "Type"])
			{	
				MiniMapWarning.Remove(A_index, "")
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
			getUnitMiniMapMousePos(MiniMapWarning[A_index,"Unit"], X, Y)

			Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)	
		;	Gdip_DrawImage(G, pBitmap, (X - Width/2), (Y - Height/2), Width, Height, 0, 0, Width, Height)	
			Gdip_DrawImage(G, pBitmap, (X - Width/2), (Y - Height/2), Width, Height, 0, 0, Width, Height)	
		} 
	}
	if DrawPlayerCameras
		drawPlayerCameras(G)
	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc, 0, 0, A_ScreenWidth/4, A_ScreenHeight, overlayMinimapTransparency) ;only draw on left side of the screen
	SelectObject(hdc, obm) ; needed else eats ram ; Select the object back into the hdc
	DeleteObject(hbm)   ; needed else eats ram 	; Now the bitmap may be deleted
	DeleteDC(hdc) ; Also the device context related to the bitmap may be deleted

Return
}

getEnemyUnitsMiniMap(byref A_MiniMapUnits)
{  LOCAL Unitcount, UnitAddress, pUnitModel, Filter, MemDump, Radius, x, y, PlayerColours, MemDump, PlayerColours, Unitcount, owner, unitName
 	, Colour, Type
  A_MiniMapUnits := []
  PlayerColours := arePlayerColoursEnabled()
  QueuedCommands := ""
  Unitcount := DumpUnitMemory(MemDump)
  while (A_Index <= Unitcount)
  {
     UnitAddress := (A_Index - 1) * S_uStructure
     Filter := numget(MemDump, UnitAddress + O_uTargetFilter, "Int64")
     if (Filter & DeadFilterFlag)
        Continue

     pUnitModel := numget(MemDump, UnitAddress + O_uModelPointer, "Int")  
     Type := numgetUnitModelType(pUnitModel)

     owner := numget(MemDump, UnitAddress + O_uOwner, "Char")     
     if aMiniMapUnits.Exclude.HasKey(type)
           Continue

     if  (aPlayer[Owner, "Team"] <> aLocalPlayer["Team"] && Owner && type >= aUnitID["Colossus"] && !aChangeling.HasKey(type)) 
     || (aChangeling.HasKey(type) && aPlayer[Owner, "Team"] = aLocalPlayer["Team"] ) ; as a changeling owner becomes whoever it is mimicking - its team also becomes theirs
     {
          if (!Radius := aUnitInfo[Type, "Radius"])
              Radius := aUnitInfo[Type, "Radius"] := numgetUnitModelMiniMapRadius(pUnitModel)
          if (Radius < minimap.UnitMinimumRadius) ; probes and such
           	Radius := minimap.UnitMinimumRadius
          
	       x :=  numget(MemDump, UnitAddress + O_uX, "int")/4096
           y :=  numget(MemDump, UnitAddress + O_uY, "int")/4096

        ;  Radius += (minimap.AddToRadius/2)
          
     
           convertCoOrdindatesToMiniMapPos(x, y)
           if (HighlightInvisible && Filter & aUnitTargetFilter.Hallucination) ; have here so even if non-halluc unit type has custom colour highlight, it will be drawn using halluc colour
           	  Colour := "UnitHighlightHallucinationsColour"
          else if aMiniMapUnits.Highlight.HasKey(type)
          	Colour := aMiniMapUnits.Highlight[type]
           Else if (HighlightInvisible && Filter & aUnitTargetFilter.Cloaked) ; this will include burrowed units (so dont need to check their flags)
           	  Colour := "UnitHighlightInvisibleColour" 				; Have this at bot so if an invis unit has a custom highlight it will be drawn with that colour
           Else if PlayerColours
              Colour := aPlayer[Owner, "Colour"]
           Else Colour := "Red" 

           if (GameType != "1v1" && HostileColourAssist)
           {
	           unitName := aUnitName[type]
	           if unitName in CommandCenter,CommandCenterFlying,OrbitalCommand,PlanetaryFortress,Nexus,Hatchery,Lair,Hive
	          		Colour := aPlayer[Owner, "Colour"]
	       }
	       if DrawUnitDestinations
	       		getUnitQueuedCommands(A_Index - 1, QueuedCommands)
           A_MiniMapUnits.insert({"X": x, "Y": y
           						, "Colour": Colour
           						, "Radius": Radius*2
           						, unit: A_index -1
           						, "queuedCommands": QueuedCommands})  

     }
  }
  Return
}

drawUnitDestinations(pGraphics, byRef A_MiniMapUnits)
{
	static a_pPen := [], hasRun

	if !hasRun
	{
		a_pPen := createPens(1)
		hasRun := True
	}

	for indexOuter, unit in A_MiniMapUnits
	{
		for indexQueued, command in unit.QueuedCommands
		{
			if (command.ability = "attack")
				colour := "Red"
			else if (command.ability = "move")
			{
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
				convertCoOrdindatesToMiniMapPos(x := command.targetX, y := command.targetY)
				Width := Gdip_GetImageWidth(pBitmap := a_pBitmap["pingNuke"]), Height := Gdip_GetImageHeight(pBitmap)	
				Gdip_DrawImage(pGraphics, pBitmap, (X - Width/2), (Y - Height/2), Width, Height, 0, 0, Width, Height)
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
			convertCoOrdindatesToMiniMapPos(targetX := command.targetX, targetY := command.targetY)	
			Gdip_DrawLine(pGraphics, a_pPen[colour], x, y, targetX, targetY)
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

temporarilyHideMinimap()
{
	Global DrawMiniMap, DrawPlayerCameras, DrawAlerts, DrawSpawningRaces
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
		Thread, Priority, -2147483648
		sleep, 2500
		if ReDrawMiniMap
			DrawMiniMap := True
		if ReDrawPlayerCams 
			DrawPlayerCameras := true
		if ReDrawAlerts
			DrawAlerts := True
		if ReDrawSpawningRaces
			DrawSpawningRaces := True
		gosub, MiniMap_Timer
	}
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
	static a_pPen := [], maxAngle := 1.195313, hasRun
	if !hasRun
	{
		a_pPen := createPens(1)
		hasRun := True
	}
	Region := Gdip_GetClipRegion(pGraphics)
	Gdip_SetClipRect(pGraphics, minimap.ScreenLeft, minimap.ScreenTop, minimap.Width, minimap.Height, 0)

	For slotNumber in aPlayer
	{
		If (aLocalPlayer.Team != aPlayer[slotNumber].Team && isPlayerActive(slotNumber))
		{
			angle := getPlayerCameraAngle(slotNumber)
			xCenter := getPlayerCameraPositionX(slotNumber)
			yCenter := getPlayerCameraPositionY(slotNumber)
			convertCoOrdindatesToMiniMapPos(xCenter, yCenter)

			x1 := xCenter - (18/1920*A_ScreenWidth/minimap.MapPlayableWidth * minimap.Width) * (angle/maxAngle)**2
			y1 := yCenter - (11/1080*A_ScreenHeight/minimap.MapPlayableHeight * minimap.Height) * angle/maxAngle
			
			x2 := x1 + (36/1920*A_ScreenWidth/minimap.MapPlayableWidth * minimap.Width) * (angle/maxAngle)**2
			y2 := y1 

			x3 := (x2 - (x2 - x1)/2) + (xOffset := 14/1920*A_ScreenWidth/minimap.MapPlayableWidth * minimap.Width * (angle/maxAngle)**3)
			y3 := y2 + ((18/1080*A_ScreenHeight /minimap.MapPlayableHeight * minimap.Height) * angle/maxAngle)

			x4 := x1 + ((x2 - x1)/2) - xOffset
			y4 := y3 

			Gdip_DrawLines(pGraphics, a_pPen[aPlayer[slotNumber, "colour"]],  x1 "," y1 "|" x2 "," y2 
							. "|" x3 "," y3 "|" x4 "," y4 "|" x1 "," y1 )
		}
	}
	Gdip_DeleteRegion(Region)
	return 
}

unit_bank_read:
SupplyInProductionCount := gateway_count := warpgate_count := 0
Time := getTime()
a_BaseListTmp := []
UnitBankCount := DumpUnitMemory(UBMemDump)
while (A_Index <= UnitBankCount)
{ 
	u_iteration := A_Index -1
	If ((Filter := numgetUnitTargetFilter(UBMemDump, u_iteration)) & DeadFilterFlag
		|| !(unit_owner := numgetUnitOwner(UBMemDump, u_iteration))
		|| (aLocalPlayer["Team"] = aPlayer[unit_owner, "Team"] && unit_owner != aLocalPlayer["Slot"]))
		Continue
	; so these units are alive, and either local or enemy units (and not neutral player 0)
	unit_type := numgetUnitModelType(numgetUnitModelPointer(UBMemDump, u_iteration))
	if (unit_owner = aLocalPlayer["Slot"])
	{
		IF (unit_type = supplytype AND Filter & aUnitTargetFilter.UnderConstruction)
				SupplyInProductionCount ++		
		if ( warpgate_warn_on AND (unit_type = aUnitID["Gateway"] OR unit_type = aUnitID["WarpGate"]) 
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
						{	isinlist := 1
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
			Else if (unit_type = aUnitID["WarpGate"] && warpgate_status <> "researched") ; as unit_type must = warpgate_id
			{
				warpgate_status := "researched"
			;	settimer warpgate_warn, 1000
			}
		}
		if (unit_type = aUnitID["Nexus"] || unit_type = aUnitID["CommandCenter"] 
		|| unit_type =  aUnitID["PlanetaryFortress"] || unit_type =  aUnitID["OrbitalCommand"])
		&&  !(Filter & aUnitTargetFilter.UnderConstruction)
			a_BaseListTmp.insert(u_iteration)
	}
	else if (alert_array[GameType, "Enabled"]) ; these units are enemies
		doUnitDetection(u_iteration, unit_type, unit_owner)
}
if warpgate_warn_on
	gosub warpgate_warn
SupplyInProduction := SupplyInProductionCount
a_BaseList := a_BaseListTmp 
return


;--------------------
;	WarpGate Warning
;--------------------

;	I think the problem here is if a user converts a warpate while the timer isnt running and then another warpgate finishes
;	it will rewarn the user even though it hasn't really waited the correct amount of time
;  also remeber that it only updates gateway/warpgate count after doing a unit bank read /iteration

; note: wargate warning only drawn for a set amount of time as the 'time' is only read in once in the unit bank section - so if user has a long follow up delay, that wont be accompanied by a minimap alert

warpgate_warn:
	if  (warpgate_status != "researched")
		return
	if gateway_count  ; this prvents the minmap warning showing converted gateways until they naturally time out in the drawing section
		for index, object in aGatewayWarnings
			if ( getUnitType(object.unit) != aUnitID["Gateway"] || isUnitDead(object.unit) || !isUnitLocallyOwned(object.unit) ) ;doing this in case unit dies or becomes other players gateway as this list onyl gets cleared when gateway count = 0
			{
				for minimapIndex, minimapObject in MiniMapWarning
					if (minimapObject.unit = object.unit)
					{
						MiniMapWarning.remove(minimapIndex, "") 
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
			for minimapIndex, minimapObject in MiniMapWarning
				if (minimapObject.unit = object.unit)
					minimapObject.remove(minimapIndex, "")        ;lets clear the list of old gateway warnings. This gets rid of the x as soon as the gateway becomes a warpgate
		aGatewayWarnings := []

	}
	else if ( warpgate_warn_count <= sec_warpgate && time > warpgateGiveWarningAt) 
	{
		warpgate_warn_count ++
		warpgateGiveWarningAt := getTime() + delay_warpgate_warn_followup

		for index, object in aGatewayWarnings
		{
			object.time := time ; so this will display an x even with long  follow up delay
			MiniMapWarning.insert(object)
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
worker:	
	If (aLocalPlayer["Race"] = "Terran" || aLocalPlayer["Race"] = "Protoss")
		WorkerInProductionWarning(a_BaseList, workerProductionTPIdle, 1 + sec_workerprod, additional_delay_worker_production, 120)
	else
	{
		if ( OldWorker_i <> NewWorker_i := getPlayerWorkerCount())
		{	;A worker has been produced or killed
			reset_worker_time := time, Worker_i = 0
			workerproduction_time_if := workerproduction_time
		}
		else
		{ 
			if  (time - reset_worker_time) > workerproduction_time_if AND (Worker_i <= sec_workerprod) ; sec_workerprod sets how many times to play warning.
			{
				If ( aLocalPlayer["Race"] = "Terran"  )
					tSpeak(w_workerprod_T)
				Else If ( aLocalPlayer["Race"] = "Protoss" )
					tSpeak(w_workerprod_P)
				Else If ( aLocalPlayer["Race"] = "Zerg" )
					tSpeak(w_workerprod_Z)
				Else 
					tSpeak("Build Worker")
				workerproduction_time_if := additional_delay_worker_production ; will give the second warning after 12 ingame seconds
				reset_worker_time := time		; This allows for the additional warnings to be delayed relative to the 1st warning
				Worker_i ++
			}
		}
		 OldWorker_i := NewWorker_i
	}
	return

WorkerInProductionWarning(a_BaseList, maxIdleTime, maxWarnings, folloupWarningDelay, MaxWorkerCount)	;add secondary delay and max workers
{	global aLocalPlayer, w_workerprod_T, w_workerprod_P, w_workerprod_Z
	static lastWorkerInProduction, warningCount, lastwarning

	if (getPlayerWorkerCount() >= MaxWorkerCount)	;stop warnings enough workers
		return

	time := getTime()
	for index, Base in a_BaseList
	{

		if (state := isWorkerInProduction(Base))
		{
			warningCount := 0
			lastWorkerInProduction := time
			return
		}
		else if (state < 0)
			morphingBases++
		else lazyBases++	;hence will only warn if there are no workers in production
							; and at least 1 building is capable of making workers i.e not flying/moring
	}
	if !lazyBases && morphingBases
		lastWorkerInProduction := time	;this prevents you getting a warning immeditely after the base finishes morphing

	if lazybases && (time - lastWorkerInProduction >= maxIdleTime) && ( warningCount < maxWarnings)
	{
		if (warningCount && time - lastwarning < folloupWarningDelay)
			return
		lastwarning := time
		warningCount++
		If ( aLocalPlayer["Race"] = "Terran" )
			tSpeak(w_workerprod_T)
		Else If ( aLocalPlayer["Race"] = "Protoss" )
			tSpeak(w_workerprod_P)
		Else If ( aLocalPlayer["Race"] = "Zerg" )
			tSpeak(w_workerprod_Z)
		Else 
			tSpeak("Build Worker")	;dont update the idle time so it gets bigger
	}
	return 
}




