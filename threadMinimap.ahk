/*
	Rather than messing around with a lot of shared variables/objects/critical sections
	and locks,
	this thread is just going to going to read/update all of the users variables
	itself, as well as gamedata
	This has to be run using AHK.dll (mini doesnt have gui functions)
*/



#persistent
#NoEnv  ; think this is default with AHK_H
;#NoTrayIcon

;SetBatchLines, -1
;ListLines(False) 
OnExit, ShutdownProcedure
if !A_IsCompiled
{
	debug := True
	debug_name := "Kalamity"	
}

l_GameType := "1v1,2v2,3v3,4v4,FFA"
l_Races := "Terran,Protoss,Zerg"
GLOBAL GameWindowTitle := "StarCraft II"
GLOBAL GameIdentifier := "ahk_exe SC2.exe"
GameExe := "SC2.exe"

#include %A_ScriptDir%\Included Files\Gdip.ahk
#Include <SC2_MemoryAndGeneralFunctions> ;In the library folder
pToken := Gdip_Startup()
Global aUnitID, aUnitName, aUnitSubGroupAlias, aUnitTargetFilter, HexColour, MatrixColour
	, aUnitModel,  aPlayer, aLocalPlayer, minimap


SetupUnitIDArray(aUnitID, aUnitName)
getSubGroupAliasArray(aUnitSubGroupAlias)
setupTargetFilters(aUnitTargetFilter)
SetupColourArrays(HexColour, MatrixColour)

CreatepBitmaps(a_pBitmap, aUnitID)
aUnitInfo := []
a_pBrush := []
readConfigFile()

settimer, timer_exit, 15000, -100 ; Just as a backup if the thread gets orphaned
l_Changeling := aUnitID["ChangelingZealot"] "," aUnitID["ChangelingMarineShield"] ","  aUnitID["ChangelingMarine"] 
				. ","  aUnitID["ChangelingZerglingWings"] "," aUnitID["ChangelingZergling"]
return




gameChange()
{
	global
	if !hasLoadedMemoryAddresses
	{
		Process, wait, %GameExe%
		while (!(B_SC2Process := getProcessBaseAddress(GameIdentifier)) || B_SC2Process < 0)		;using just the window title could cause problems if a folder had the same name e.g. sc2 folder
			sleep 400
		hasLoadedMemoryAddresses := loadMemoryAddresses(B_SC2Process)
	}
	if getTime()
	{
		game_status := "game", warpgate_status := "not researched", gateway_count := warpgate_warning_set := 0
		aUnitModel := []
		if WinActive(GameIdentifier)
			ReDrawMiniMap := ReDrawIncome := ReDrawResources := ReDrawArmySize := ReDrawWorker := RedrawUnit := ReDrawIdleWorkers := ReDrawLocalPlayerColour := 1
		getPlayers(aPlayer, aLocalPlayer)
		GameType := GetGameType(aPlayer)
		SetMiniMap(minimap)
		setupMiniMapUnitLists()
		SetTimer, MiniMap_Timer, %MiniMapRefresh%, -7
		EnemyBaseList := GetEBases()
	}
	else 
	{
		SetTimer, MiniMap_Timer, off
	}
	return
}


MiniMap_Timer:
	if WinActive(GameIdentifier)
		DrawMiniMap()
Return

timer_Exit:
{
	process, exist, %GameExe%
	if !errorlevel 		;errorlevel = 0 if not exist
		ExitApp ; this will run the shutdown routine below
}
return

ShutdownProcedure:
	Closed := ReadMemory()
	Closed := ReadRawMemory()
	Closed := ReadMemory_Str()
	Gdip_Shutdown(pToken)
	ExitApp
Return



DrawMiniMap()
{	global
	local UnitRead_i, unit, type, Owner, Radius, Filter, EndCount, colour, ResourceOverlay_i, unitcount
	, DrawX, DrawY, Width, height, i, hbm, hdc, obm, G,  pBitmap, PlayerColours, A_MiniMapUnits
	static Overlay_RunCount
	Overlay_RunCount ++
	if (ReDrawMiniMap and WinActive(GameIdentifier))
	{
		Try Gui, MiniMapOverlay: Destroy
		Overlay_RunCount := 1
		ReDrawMiniMap := 0
	}
	If (Overlay_RunCount = 1)
	{
		; Set the width and height we want as our drawing area, to draw everything in. This will be the dimensions of our bitmap
		; Create a layered window ;E0x20 click thru (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption		
		Gui, MiniMapOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
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
		setDrawingQuality(G)
		A_MiniMapUnits := []

 		getEnemyUnitsMiniMap(A_MiniMapUnits)

		for index, unit in A_MiniMapUnits
			drawUnitRectangle(G, unit.X, unit.Y, unit.Radius + minimap.AddToRadius, unit.Radius + minimap.AddToRadius)	;draw rectangles first
		for index, unit in A_MiniMapUnits
			FillUnitRectangle(G, unit.X, unit.Y,  unit.Radius, unit.Radius, unit.Colour)

	}
	If (DrawSpawningRaces) && (Time - round(TimeReadRacesSet) <= 14) ;round used to change undefined var to 0 for resume so dont display races
	{	Gdip_SetInterpolationMode(G, 7)				;TimeReadRacesSet gets set to 0 at start of match
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
			If (Time - MiniMapWarning[A_index,"Time"] >= 20) ;display for 20 seconds
			{	MiniMapWarning.Remove(A_index)
				continue
			}
			owner := getUnitOwner(MiniMapWarning[A_index,"Unit"])	
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
			Gdip_DrawImage(G, pBitmap, (X - Width/2), (Y - Height/2), Width, Height, 0, 0, Width, Height)	
		} 
	}

	drawPlayerCameras(G)

	testObject := []
	unit := getselectedunitIndex()
	getUnitMoveCommands(unit, aQueuedMovements)
	testObject.insert({ "QueuedCommands": aQueuedMovements
					, "x": getUnitPositionX(unit)
					, "y": getUnitPositionY(unit) })
	drawUnitDestinations(G, testObject)


	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc, 0, 0, A_ScreenWidth/4, A_ScreenHeight) ;only draw on left side of the screen
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
     If type in %ActiveUnitHighlightExcludeList% ; cant use or/expressions with type in
           Continue
     if  (aPlayer[Owner, "Team"] <> aLocalPlayer["Team"] && Owner && type >= aUnitID["Colossus"] && !ifTypeInList(type, l_Changeling)) 
     || (ifTypeInList(type, l_Changeling) && aPlayer[Owner, "Team"] = aLocalPlayer["Team"] ) ; as a changeling owner becomes whoever it is mimicking - its team also becomes theirs
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
           	  Colour := UnitHighlightHallucinationsColour
           else if type in %allActiveActiveUnitHighlightLists%
           {
           		; Overall, checking if the type is actually in the highlight list, 
           		; and then checking each  individual list 
           		; should be faster than needlessly checking every list

	           if type in %ActiveUnitHighlightList1%
	              Colour := UnitHighlightList1Colour
	           Else If type in %ActiveUnitHighlightList2%
	              Colour := UnitHighlightList2Colour                 
	           Else If type in %ActiveUnitHighlightList3%
	              Colour := UnitHighlightList3Colour                    
	           Else If type in %ActiveUnitHighlightList4%
	              Colour := UnitHighlightList4Colour                    
	           Else If type in %ActiveUnitHighlightList5%
	              Colour := UnitHighlightList5Colour   
	           Else If type in %ActiveUnitHighlightList6%
	              Colour := UnitHighlightList6Colour   
	           Else If type in %ActiveUnitHighlightList7%
	              Colour := UnitHighlightList7Colour
	       }
           Else if (HighlightInvisible && Filter & aUnitTargetFilter.Cloaked) ; this will include burrowed units (so dont need to check their flags)
           	  Colour := UnitHighlightInvisibleColour 				; Have this at bot so if an invis unit has a custom highlight it will be drawn with that colour
           Else if PlayerColours
              Colour := 0xcFF HexColour[aPlayer[Owner, "Colour"]]   ;FF=Transparency
           Else Colour := 0xcFF HexColour["Red"]  

           if (GameType != "1v1" && HostileColourAssist)
           {
	           unitName := aUnitName[type]
	           if unitName in CommandCenter,CommandCenterFlying,OrbitalCommand,PlanetaryFortress,Nexus,Hatchery,Lair,Hive
	          		Colour := 0xcFF HexColour[aPlayer[Owner, "Colour"]]
	       }

           A_MiniMapUnits.insert({"X": x, "Y": y, "Colour": Colour, "Radius": Radius*2})  

     }
  }
  Return
}

drawUnitDestinations(pGraphics, byRef aEnemyUnitData)
{
	static a_pPen := [], hasRun

	if !hasRun
		a_pPen := createPens(2)

	for indexOuter, aIndividualUnit in aEnemyUnitData
	{
		for index, movement in aIndividualUnit.QueuedCommands
		{
			if (movement.moveState = aUnitMoveStates.Amove)
				colour := "Red"
			else if (movement.moveState	= aUnitMoveStates.Patrol)
				colour := "Blue"
			else if (movement.moveState	= aUnitMoveStates.Move
				|| movement.moveState= aUnitMoveStates.Follow 
				|| movement.moveState = aUnitMoveStates.FollowNoAttack)
				colour := "Green"
			else continue

			if (index = aIndividualUnit.QueuedCommands.MinIndex())
			{
				x := aIndividualUnit.x, y := aIndividualUnit.y 	
				convertCoOrdindatesToMiniMapPos(x,  y)	
				
			}
			Else 
			{
				x := xTarget, y := yTarget
			}

			xTarget := movement.targetX, yTarget := movement.targetY

			convertCoOrdindatesToMiniMapPos(xTarget,  yTarget)	

			msgbox % x ", " y "`n" xTarget ", " yTarget
			Gdip_DrawLine(pGraphics, a_pPen[colour], x, y, xTarget, yTarget)

		}
	}
	objtree(aEnemyMovements)
	msgbox 
	return
}

createPens(penSize)
{
	a_pPens := []
	for colour, hexValue in HexColour
		a_pPens[Colour] := Gdip_CreatePen(0xcFF hexValue, penSize)
	return a_pPens
}



/*
	x,y co-ordinates
	1--------------------2
	\                   /
     \     centre      /
      \               /
       4-------------3

Still have to scale this for the map - so probably *minimap.scale
*/

drawPlayerCameras(pGraphics)
{
	static a_pPen := [], maxAngle := 1.195313, hasRun
	if !hasRun
		a_pPen := createPens(2)

	For slotNumber in aPlayer
	{
		If (aLocalPlayer.Team != aPlayer[slotNumber].Team || 1)
		{

			angle := getPlayerCameraAngle(slotNumber)
			xCenter := getPlayerCameraPositionX(slotNumber)
			yCenter := getPlayerCameraPositionY(slotNumber)
			convertCoOrdindatesToMiniMapPos(xCenter, yCenter)

			x1 := xCenter - (33/1920*A_ScreenWidth * (angle/maxAngle)**2 + (Abs(maxAngle-angle)*10/1920*A_ScreenWidth) )
			y1 := yCenter - (22/1080*A_ScreenHeight * (angle/maxAngle)**2 + (Abs(maxAngle-angle)*20/1080*A_ScreenHeight) )
			
			if (x1 < minimap.ScreenLeft)
				x1 := minimap.ScreenLeft
			if (y1 < minimap.ScreenTop)
				y1 := minimap.ScreenTop

			 x2 := x1 + (66/1920*A_ScreenWidth * (angle/maxAngle)**2 + (Abs(maxAngle-angle)*20/1920*A_ScreenWidth))
			 y2 := y1 

			if (x2 > minimap.ScreenRight)
				x2 := minimap.ScreenRight

			 x3 := x2 - ((x2 - x1)/2) + (25/1920*A_ScreenWidth * (angle/maxAngle)**2 - (Abs(maxAngle-angle)*10/1920*A_ScreenWidth))
			 y3 := y2 + (33/1080*A_ScreenHeight * (angle/maxAngle)**2 + (Abs(maxAngle-angle)*20/1080*A_ScreenHeight))
			
			if (y3 > minimap.ScreenBottom)
				y3 := minimap.ScreenBottom
			 x4 := x1 + ((x2 - x1)/2) - (25/1920*A_ScreenWidth * (angle/maxAngle)**2 - (Abs(maxAngle-angle)*10/1920*A_ScreenWidth))
			 y4 := y3 

			 Gdip_DrawLines(pGraphics, a_pPen[Colour],  x1 "," y1 "|" x2 "," y2 
							. "|" x3 "," y3 "|" x4 "," y4 "|" x1 "," y1 )
		}
	}
	return 
}







readConfigFile()
{
	Global 
	;[Version]
	IniRead, read_version, %config_file%, Version, version, 1 ; 1 if cant find value - IE early version
	;[Auto Inject]
	IniRead, auto_inject, %config_file%, Auto Inject, auto_inject_enable, 1
	IniRead, auto_inject_alert, %config_file%, Auto Inject, alert_enable, 1
	IniRead, auto_inject_time, %config_file%, Auto Inject, auto_inject_time, 41
	IniRead, cast_inject_key, %config_file%, Auto Inject, auto_inject_key, F5
	IniRead, Inject_control_group, %config_file%, Auto Inject, control_group, 9
	IniRead, Inject_spawn_larva, %config_file%, Auto Inject, spawn_larva, v
	IniRead, HotkeysZergBurrow, %config_file%, Auto Inject, HotkeysZergBurrow, r
	
	; [MiniMap Inject]
	section := "MiniMap Inject"
	IniRead, MI_Queen_Group, %config_file%, %section%, MI_Queen_Group, 7
	IniRead, MI_QueenDistance, %config_file%, %section%, MI_QueenDistance, 17

		
	;[Manual Inject Timer]
	IniRead, manual_inject_timer, %config_file%, Manual Inject Timer, manual_timer_enable, 0
	IniRead, manual_inject_time, %config_file%, Manual Inject Timer, manual_inject_time, 43
	IniRead, inject_start_key, %config_file%, Manual Inject Timer, start_stop_key, Lwin & RButton
	IniRead, inject_reset_key, %config_file%, Manual Inject Timer, reset_key, Lwin & LButton
	
	;[Inject Warning]
	IniRead, W_inject_ding_on, %config_file%, Inject Warning, ding_on, 1
	IniRead, W_inject_speech_on, %config_file%, Inject Warning, speech_on, 0
	IniRead, w_inject_spoken, %config_file%, Inject Warning, w_inject, Inject
	
	;[Forced Inject]
	section := "Forced Inject"
	IniRead, F_Inject_Enable, %config_file%, %section%, F_Inject_Enable, 0
	IniRead, FInjectHatchFrequency, %config_file%, %section%, FInjectHatchFrequency, 2500
	IniRead, FInjectHatchMaxHatches, %config_file%, %section%, FInjectHatchMaxHatches, 10
	IniRead, FInjectAPMProtection, %config_file%, %section%, FInjectAPMProtection, 190
	IniRead, F_InjectOff_Key, %config_file%, %section%, F_InjectOff_Key, Lwin & F5
	
	

	;[Idle AFK Game Pause]
	IniRead, idle_enable, %config_file%, Idle AFK Game Pause, enable, 0
	IniRead, idle_time, %config_file%, Idle AFK Game Pause, idle_time, 15
	IniRead, UserIdle_LoLimit, %config_file%, Idle AFK Game Pause, UserIdle_LoLimit, 3	;sc2 seconds
	IniRead, UserIdle_HiLimit, %config_file%, Idle AFK Game Pause, UserIdle_HiLimit, 10	
	IniRead, chat_text, %config_file%, Idle AFK Game Pause, chat_text, Sorry, please give me 2 minutes. Thanks :)


	;[Starcraft Settings & Keys]
	IniRead, name, %config_file%, Starcraft Settings & Keys, name, YourNameHere
	IniRead, pause_game, %config_file%, Starcraft Settings & Keys, pause_game, {Pause}
	IniRead, base_camera, %config_file%, Starcraft Settings & Keys, base_camera, {Backspace}
	IniRead, NextSubgroupKey, %config_file%, Starcraft Settings & Keys, NextSubgroupKey, {Tab}
	IniRead, escape, %config_file%, Starcraft Settings & Keys, escape, {escape}
	
	;[Backspace Inject Keys]
	section := "Backspace Inject Keys"
	IniRead, BI_create_camera_pos_x, %config_file%, %section%, create_camera_pos_x, +{F6}	
	IniRead, BI_camera_pos_x, %config_file%, %section%, camera_pos_x, {F6}	


	;[Forgotten Gateway/Warpgate Warning]
	section := "Forgotten Gateway/Warpgate Warning"
	IniRead, warpgate_warn_on, %config_file%, %section%, enable, 1
	IniRead, sec_warpgate, %config_file%, %section%, warning_count, 1
	IniRead, delay_warpgate_warn, %config_file%, %section%, initial_time_delay, 10
	IniRead, delay_warpgate_warn_followup, %config_file%, %section%, follow_up_time_delay, 15
	IniRead, w_warpgate, %config_file%, %section%, spoken_warning, "WarpGate"

	; ive just added the forge and stargate here as, the warpages already here
	;[Chrono Boost Gateway/Warpgate]
	section := "Chrono Boost Gateway/Warpgate"
	IniRead, CG_Enable, %config_file%, %section%, enable, 1
	IniRead, Cast_ChronoGate_Key, %config_file%, %section%, Cast_ChronoGate_Key, F5
	IniRead, CG_control_group, %config_file%, %section%, CG_control_group, 9
	IniRead, CG_nexus_Ctrlgroup_key, %config_file%, %section%, CG_nexus_Ctrlgroup_key, 4
	IniRead, chrono_key, %config_file%, %section%, chrono_key, c
	IniRead, CG_chrono_remainder, %config_file%, %section%, CG_chrono_remainder, 2
	IniRead, ChronoBoostSleep, %config_file%, %section%, ChronoBoostSleep, 50
	IniRead, ChronoBoostEnableForge, %config_file%, %section%, ChronoBoostEnableForge, 0
	IniRead, ChronoBoostEnableStargate, %config_file%, %section%, ChronoBoostEnableStargate, 0
	IniRead, ChronoBoostEnableNexus, %config_file%, %section%, ChronoBoostEnableNexus, 0
	IniRead, ChronoBoostEnableRoboticsFacility, %config_file%, %section%, ChronoBoostEnableRoboticsFacility, 0
	IniRead, Cast_ChronoForge_Key, %config_file%, %section%, Cast_ChronoForge_Key, ^F5
	IniRead, Cast_ChronoStargate_Key, %config_file%, %section%, Cast_ChronoStargate_Key, +F5
	IniRead, Cast_ChronoNexus_Key, %config_file%, %section%, Cast_ChronoNexus_Key, >!F5
	IniRead, Cast_ChronoRoboticsFacility_Key, %config_file%, %section%, Cast_ChronoRoboticsFacility_Key, >!F6

	
	;[Advanced Auto Inject Settings]
	IniRead, auto_inject_sleep, %config_file%, Advanced Auto Inject Settings, auto_inject_sleep, 50
	IniRead, Inject_SleepVariance, %config_file%, Advanced Auto Inject Settings, Inject_SleepVariance, 0
	Inject_SleepVariance := 1 + (Inject_SleepVariance/100) ; so turn the variance 30% into 1.3 

	IniRead, CanQueenMultiInject, %config_file%, Advanced Auto Inject Settings, CanQueenMultiInject, 1
	IniRead, Inject_RestoreSelection, %config_file%, Advanced Auto Inject Settings, Inject_RestoreSelection, 1
	IniRead, Inject_RestoreScreenLocation, %config_file%, Advanced Auto Inject Settings, Inject_RestoreScreenLocation, 1
	IniRead, drag_origin, %config_file%, Advanced Auto Inject Settings, drag_origin, Left

	;[Read Opponents Spawn-Races]
	IniRead, race_reading, %config_file%, Read Opponents Spawn-Races, enable, 1
	IniRead, Auto_Read_Races, %config_file%, Read Opponents Spawn-Races, Auto_Read_Races, 1
	IniRead, read_races_key, %config_file%, Read Opponents Spawn-Races, read_key, LWin & F1
	IniRead, race_speech, %config_file%, Read Opponents Spawn-Races, speech, 1
	IniRead, race_clipboard, %config_file%, Read Opponents Spawn-Races, copy_to_clipboard, 0

	;[Worker Production Helper]	
	IniRead, workeron, %config_file%, Worker Production Helper, warning_enable, 1
	IniRead, workerProductionTPIdle, %config_file%, Worker Production Helper, workerProductionTPIdle, 10
	IniRead, workerproduction_time, %config_file%, Worker Production Helper, production_time_lapse, 24
		workerproduction_time_if := workerproduction_time	;this allows to swap the 2nd warning time

	;[Minerals]
	IniRead, mineralon, %config_file%, Minerals, warning_enable, 1
	IniRead, mineraltrigger, %config_file%, Minerals, mineral_trigger, 1000

	;[Gas]
	IniRead, gas_on, %config_file%, Gas, warning_enable, 0
	IniRead, gas_trigger, %config_file%, Gas, gas_trigger, 600


	;[Idle Workers]
	IniRead, idleon, %config_file%, Idle Workers, warning_enable, 1
	IniRead, idletrigger, %config_file%, Idle Workers, idle_trigger, 5

	;[Supply]
	IniRead, supplyon, %config_file%, Supply, warning_enable, 1
	IniRead, minimum_supply, %config_file%, Supply, minimum_supply, 11
	IniRead, supplylower, %config_file%, Supply, supplylower, 40
	IniRead, supplymid, %config_file%, Supply, supplymid, 80
	IniRead, supplyupper, %config_file%, Supply, supplyupper, 120
	IniRead, sub_lowerdelta, %config_file%, Supply, sub_lowerdelta, 4
	IniRead, sub_middelta, %config_file%, Supply, sub_middelta, 5
	IniRead, sub_upperdelta, %config_file%, Supply, sub_upperdelta, 6
	IniRead, above_upperdelta, %config_file%, Supply, above_upperdelta, 8

	;[Additional Warning Count]-----set number of warnings to make
	IniRead, sec_supply, %config_file%, Additional Warning Count, supply, 1
	IniRead, sec_mineral, %config_file%, Additional Warning Count, minerals, 1
	IniRead, sec_gas, %config_file%, Additional Warning Count, gas, 0
	IniRead, sec_workerprod, %config_file%, Additional Warning Count, worker_production, 1
	IniRead, sec_idle, %config_file%, Additional Warning Count, idle_workers, 0
	
	;[Auto Control Group]
	Short_Race_List := "Terr|Prot|Zerg", section := "Auto Control Group", A_UnitGroupSettings := []
	Loop, Parse, l_Races, `, ;Terran ie full name
		while (10 > i := A_index - 1)	
			A_UnitGroupSettings["LimitGroup", A_LoopField, i, "Enabled"] := IniRead(config_file, section, A_LoopField "_LimitGroup_" i, 0)
	loop, parse, Short_Race_List, |
	{			
		If (A_LoopField = "Terr")
			Race := "Terran"
		Else if (A_LoopField = "Prot")
			Race := "Protoss"
		Else If (A_LoopField = "Zerg")
			Race := "Zerg"	

		A_UnitGroupSettings["AutoGroup", Race, "Enabled"] := IniRead(config_file, section, "AG_Enable_" A_LoopField , 0)
		loop, 10		;this reads the auto group and removes the final |/, 
		{				;and repalces all | with better looking ,
			String := RTrim(IniRead(config_file, section, "AG_" A_LoopField A_Index - 1 , A_Space), "`, |")
			StringReplace, String, String, |, `, %a_space%, All ;replace | with ,
			A_UnitGroupSettings[Race, A_Index - 1] := String			
		}
	}
	IniRead, AG_Delay, %config_file%, %section%, AG_Delay, 0

	
	;[ Volume]
	section := "Volume"
	IniRead, speech_volume, %config_file%, %section%, speech, 100
	IniRead, programVolume, %config_file%, %section%, program, 100

	;[Warnings]-----sets the audio warning
	IniRead, w_supply, %config_file%, Warnings, supply, "Supply"
	IniRead, w_mineral, %config_file%, Warnings, minerals, "Money"
	IniRead, w_gas, %config_file%, Warnings, gas, "Gas"
	IniRead, w_workerprod_T, %config_file%, Warnings, worker_production_T, "Build SCV"
	IniRead, w_workerprod_P, %config_file%, Warnings, worker_production_P, "Build Probe"
	IniRead, w_workerprod_Z, %config_file%, Warnings, worker_production_Z, "Build Drone"
	IniRead, w_idle, %config_file%, Warnings, idle_workers, "Idle"

	;[Additional Warning Delay]
	IniRead, additional_delay_supply, %config_file%, Additional Warning Delay, supply, 10
	IniRead, additional_delay_minerals, %config_file%, Additional Warning Delay, minerals, 10
	IniRead, additional_delay_gas, %config_file%, Additional Warning Delay, gas, 10
	IniRead, additional_delay_worker_production, %config_file%, Additional Warning Delay, worker_production, 25 ;sc2time
	IniRead, additional_idle_workers, %config_file%, Additional Warning Delay, idle_workers, 10


	;[Misc Hotkey]
	IniRead, worker_count_local_key, %config_file%, Misc Hotkey, worker_count_key, F8
	IniRead, worker_count_enemy_key, %config_file%, Misc Hotkey, enemy_worker_count, Lwin & F8
	IniRead, warning_toggle_key, %config_file%, Misc Hotkey, pause_resume_warnings_key, Lwin & Pause
	IniRead, ping_key, %config_file%, Misc Hotkey, ping_map, Lwin & MButton

	;[Misc Settings]
	section := "Misc Settings"
	IniRead, input_method, %config_file%, %section%, input_method, Input
	IniRead, EventKeyDelay, %config_file%, %section%, EventKeyDelay, -1
	IniRead, pKeyDelay, %config_file%, %section%, pKeyDelay, 3
	IniRead, auto_update, %config_file%, %section%, auto_check_updates, 1
	IniRead, launch_settings, %config_file%, %section%, launch_settings, 0
	IniRead, MaxWindowOnStart, %config_file%, %section%, MaxWindowOnStart, 1
	IniRead, HumanMouse, %config_file%, %section%, HumanMouse, 0
	IniRead, HumanMouseTimeLo, %config_file%, %section%, HumanMouseTimeLo, 70
	IniRead, HumanMouseTimeHi, %config_file%, %section%, HumanMouseTimeHi, 110

	IniRead, UnitDetectionTimer_ms, %config_file%, %section%, UnitDetectionTimer_ms, 3500

	IniRead, MTCustomIcon, %config_file%, %section%, MTCustomIcon, %A_Space% ; I.e. False
	IniRead, MTCustomProgramName, %config_file%, %section%, MTCustomProgramName, %A_Space% ; I.e. False
	MTCustomProgramName := Trim(MTCustomProgramName)

	

	;[Key Blocking]
	section := "Key Blocking"
	IniRead, BlockingStandard, %config_file%, %section%, BlockingStandard, 1
	IniRead, BlockingFunctional, %config_file%, %section%, BlockingFunctional, 1
	IniRead, BlockingNumpad, %config_file%, %section%, BlockingNumpad, 1
	IniRead, BlockingMouseKeys, %config_file%, %section%, BlockingMouseKeys, 1
	IniRead, BlockingMultimedia, %config_file%, %section%, BlockingMultimedia, 1
	IniRead, LwinDisable, %config_file%, %section%, LwinDisable, 1
	IniRead, Key_EmergencyRestart, %config_file%, %section%, Key_EmergencyRestart, <#Space

	aButtons := [] 	; Note I no longer retreive modifier keys in this list as these will always be blocked using ~*prefix
	aButtons.List := getKeyboardAndMouseButtonArray(BlockingStandard*1 + BlockingFunctional*2 + BlockingNumpad*4
																	 + BlockingMouseKeys*8 + BlockingMultimedia*16)	;gets an object contains keys
	;[Auto Mine]
	section := "Auto Mine"
	IniRead, auto_mine, %config_file%, %section%, enable, 0
	IniRead, Auto_Mine_Set_CtrlGroup, %config_file%, %section%, Auto_Mine_Set_CtrlGroup, 1
	IniRead, Auto_mineMakeWorker, %config_file%, %section%, Auto_mineMakeWorker, 1
	IniRead, AutoMineMethod, %config_file%, %section%, AutoMineMethod, Normal
	IniRead, WorkerSplitType, %config_file%, %section%, WorkerSplitType, 3x2
	IniRead, Auto_Mine_Sleep2, %config_file%, %section%, Auto_Mine_Sleep2, 100
	IniRead, AM_PixelColour, %config_file%, %section%, AM_PixelColour, 4286496753
	;this just stores the ARGB colours for the auto mine menu
	Gdip_FromARGB(AM_PixelColour, AM_MiniMap_PixelColourAlpha, AM_MiniMap_PixelColourRed, AM_MiniMap_PixelColourGreen, AM_MinsiMap_PixelColourBlue)
	IniRead, AM_MiniMap_PixelVariance, %config_file%, %section%, AM_MiniMap_PixelVariance, 0
	IniRead, Start_Mine_Time, %config_file%, %section%, Start_Mine_Time, 1
	IniRead, AM_KeyDelay, %config_file%, %section%, AM_KeyDelay, 2
	IniRead, Idle_Worker_Key, %config_file%, %section%, Idle_Worker_Key, {F1}
	IniRead, Gather_Minerals_key, %config_file%, %section%, Gather_Minerals_key, g


	;[Misc Automation]
	section := "AutoWorkerProduction"	
	IniRead, EnableAutoWorkerTerranStart, %config_file%, %section%, EnableAutoWorkerTerranStart, 0 
	IniRead, EnableAutoWorkerProtossStart, %config_file%, %section%, EnableAutoWorkerProtossStart, 0 
	IniRead, ToggleAutoWorkerState_Key, %config_file%, %section%, ToggleAutoWorkerState_Key, #F2
	IniRead, AutoWorkerQueueSupplyBlock, %config_file%, %section%, AutoWorkerQueueSupplyBlock, 1
	IniRead, AutoWorkerAPMProtection, %config_file%, %section%, AutoWorkerAPMProtection, 160
	IniRead, AutoWorkerStorage_T_Key, %config_file%, %section%, AutoWorkerStorage_T_Key, 3
	IniRead, AutoWorkerStorage_P_Key, %config_file%, %section%, AutoWorkerStorage_P_Key, 3
	IniRead, Base_Control_Group_T_Key, %config_file%, %section%, Base_Control_Group_T_Key, 4
	IniRead, Base_Control_Group_P_Key, %config_file%, %section%, Base_Control_Group_P_Key, 4
	IniRead, AutoWorkerMakeWorker_T_Key, %config_file%, %section%, AutoWorkerMakeWorker_T_Key, s
	IniRead, AutoWorkerMakeWorker_P_Key, %config_file%, %section%, AutoWorkerMakeWorker_P_Key, e

	IniRead, AutoWorkerMaxWorkerTerran, %config_file%, %section%, AutoWorkerMaxWorkerTerran, 80
	IniRead, AutoWorkerMaxWorkerPerBaseTerran, %config_file%, %section%, AutoWorkerMaxWorkerPerBaseTerran, 30
	IniRead, AutoWorkerMaxWorkerProtoss, %config_file%, %section%, AutoWorkerMaxWorkerProtoss, 80
	IniRead, AutoWorkerMaxWorkerPerBaseProtoss, %config_file%, %section%, AutoWorkerMaxWorkerPerBaseProtoss, 30

	
	;[Misc Automation]
	section := "Misc Automation"
	IniRead, SelectArmyEnable, %config_file%, %section%, SelectArmyEnable, 0	;enable disable
	IniRead, Sc2SelectArmy_Key, %config_file%, %section%, Sc2SelectArmy_Key, {F2}
	IniRead, castSelectArmy_key, %config_file%, %section%, castSelectArmy_key, F2
	IniRead, SleepSelectArmy, %config_file%, %section%, SleepSelectArmy, 15
	IniRead, ModifierBeepSelectArmy, %config_file%, %section%, ModifierBeepSelectArmy, 1
	IniRead, SelectArmyDeselectXelnaga, %config_file%, %section%, SelectArmyDeselectXelnaga, 1
	IniRead, SelectArmyDeselectPatrolling, %config_file%, %section%, SelectArmyDeselectPatrolling, 1
	IniRead, SelectArmyDeselectHoldPosition, %config_file%, %section%, SelectArmyDeselectHoldPosition, 0
	IniRead, SelectArmyDeselectFollowing, %config_file%, %section%, SelectArmyDeselectFollowing, 0
	IniRead, SelectArmyControlGroupEnable, %config_file%, %section%, SelectArmyControlGroupEnable, 0
	IniRead, Sc2SelectArmyCtrlGroup, %config_file%, %section%, Sc2SelectArmyCtrlGroup, 1	
	IniRead, SplitUnitsEnable, %config_file%, %section%, SplitUnitsEnable, 0
	IniRead, castSplitUnit_key, %config_file%, %section%, castSplitUnit_key, F4
	IniRead, SplitctrlgroupStorage_key, %config_file%, %section%, SplitctrlgroupStorage_key, 9
	IniRead, SleepSplitUnits, %config_file%, %section%, SleepSplitUnits, 20
	IniRead, l_DeselectArmy, %config_file%, %section%, l_DeselectArmy, %A_Space%
	IniRead, DeselectSleepTime, %config_file%, %section%, DeselectSleepTime, 0
	IniRead, RemoveUnitEnable, %config_file%, %section%, RemoveUnitEnable, 0
	IniRead, castRemoveUnit_key, %config_file%, %section%, castRemoveUnit_key, +Esc

	;[Alert Location]
	IniRead, Playback_Alert_Key, %config_file%, Alert Location, Playback_Alert_Key, <#F7

	alert_array := [],	alert_array := createAlertArray()
	
	;[Overlays]
	section := "Overlays"
	; This function will get return  the x,y coordinates for the top left, and bottom right of the 
	; desktop screen (the area on both monitors)
	DesktopScreenCoordinates(XminScreen, YminScreen, XmaxScreen, YmaxScreen)
	list := "IncomeOverlay,ResourcesOverlay,ArmySizeOverlay,WorkerOverlay,IdleWorkersOverlay,UnitOverlay,LocalPlayerColourOverlay"
	loop, parse, list, `,
	{
		IniRead, Draw%A_LoopField%, %config_file%, %section%, Draw%A_LoopField%, 0
		IniRead, %A_LoopField%Scale, %config_file%, %section%, %A_LoopField%Scale, 1
		if (%A_LoopField%Scale < .5)	;so cant get -scales (or invisibly small)
			%A_LoopField%Scale := .5
		IniRead, %A_LoopField%X, %config_file%, %section%, %A_LoopField%X, % A_ScreenWidth/2
		if (%A_LoopField%X = "" || %A_LoopField%X < XminScreen || %A_LoopField%X > XmaxScreen) ; guard against blank key
			%A_LoopField%X := A_ScreenWidth/2
		IniRead, %A_LoopField%Y, %config_file%, %section%, %A_LoopField%Y, % A_ScreenHeight/2	
		if (%A_LoopField%Y = "" || %A_LoopField%Y < YminScreen || %A_LoopField%Y > YmaxScreen)
			%A_LoopField%Y := A_ScreenHeight/2
	}


;	IniRead, DrawWorkerOverlay, %config_file%, %section%, DrawWorkerOverlay, 1
;	IniRead, DrawIdleWorkersOverlay, %config_file%, %section%, DrawIdleWorkersOverlay, 1

	IniRead, ToggleUnitOverlayKey, %config_file%, %section%, ToggleUnitOverlayKey, <#U
	IniRead, ToggleIdleWorkersOverlayKey, %config_file%, %section%, ToggleIdleWorkersOverlayKey, <#L
	IniRead, ToggleMinimapOverlayKey, %config_file%, %section%, ToggleMinimapOverlayKey, <#H
	IniRead, ToggleIncomeOverlayKey, %config_file%, %section%, ToggleIncomeOverlayKey, <#I
	IniRead, ToggleResourcesOverlayKey, %config_file%, %section%, ToggleResourcesOverlayKey, <#R
	IniRead, ToggleArmySizeOverlayKey, %config_file%, %section%, ToggleArmySizeOverlayKey, <#A
	IniRead, ToggleWorkerOverlayKey, %config_file%, %section%, ToggleWorkerOverlayKey, <#W	
	IniRead, AdjustOverlayKey, %config_file%, %section%, AdjustOverlayKey, Home
	IniRead, ToggleIdentifierKey, %config_file%, %section%, ToggleIdentifierKey, <#q
	IniRead, CycleOverlayKey, %config_file%, %section%, CycleOverlayKey, <#Enter
	IniRead, OverlayIdent, %config_file%, %section%, OverlayIdent, 2
	IniRead, OverlayBackgrounds, %config_file%, %section%, OverlayBackgrounds, 0
	IniRead, MiniMapRefresh, %config_file%, %section%, MiniMapRefresh, 300
	IniRead, OverlayRefresh, %config_file%, %section%, OverlayRefresh, 1000
	IniRead, UnitOverlayRefresh, %config_file%, %section%, UnitOverlayRefresh, 4500


	; [UnitPanelFilter]
	section := "UnitPanelFilter"
	aUnitPanelUnits := []	;;array just used to store the smaller lists for each race
	loop, parse, l_Races, `,
	{
		race := A_LoopField,
		IniRead, list, %config_file%, %section%, %race%FilteredCompleted, %A_Space% ;Format FleetBeacon|TwilightCouncil|PhotonCannon	
		aUnitPanelUnits[race, "FilteredCompleted"] := [] ; make it an object
		ConvertListToObject(aUnitPanelUnits[race, "FilteredCompleted"], list)
		IniRead, list, %config_file%, %section%, %race%FilteredUnderConstruction, %A_Space% ;Format FleetBeacon|TwilightCouncil|PhotonCannon	
		aUnitPanelUnits[race, "FilteredUnderConstruction"] := [] ; make it an object
		ConvertListToObject(aUnitPanelUnits[race, "FilteredUnderConstruction"], list)
		list := ""
	}

	;[MiniMap]
	section := "MiniMap" 	
	IniRead, UnitHighlightList1, %config_file%, %section%, UnitHighlightList1, SporeCrawler, SporeCrawlerUprooted, MissileTurret, PhotonCannon, Observer	;the list
	IniRead, UnitHighlightList2, %config_file%, %section%, UnitHighlightList2, DarkTemplar, Changeling, ChangelingZealot, ChangelingMarineShield, ChangelingMarine, ChangelingZerglingWings, ChangelingZergling
	IniRead, UnitHighlightList3, %config_file%, %section%, UnitHighlightList3, %A_Space%
	IniRead, UnitHighlightList4, %config_file%, %section%, UnitHighlightList4, %A_Space%
	IniRead, UnitHighlightList5, %config_file%, %section%, UnitHighlightList5, %A_Space%
	IniRead, UnitHighlightList6, %config_file%, %section%, UnitHighlightList6, %A_Space%
	IniRead, UnitHighlightList7, %config_file%, %section%, UnitHighlightList7, %A_Space%

	IniRead, UnitHighlightList1Colour, %config_file%, %section%, UnitHighlightList1Colour, 0xFFFFFFFF  ;the colour
	IniRead, UnitHighlightList2Colour, %config_file%, %section%, UnitHighlightList2Colour, 0xFFFF00FF 
	IniRead, UnitHighlightList3Colour, %config_file%, %section%, UnitHighlightList3Colour, 0xFF09C7CA 
	IniRead, UnitHighlightList4Colour, %config_file%, %section%, UnitHighlightList4Colour, 0xFFFFFF00
	IniRead, UnitHighlightList5Colour, %config_file%, %section%, UnitHighlightList5Colour, 0xFF00FFFF
	IniRead, UnitHighlightList6Colour, %config_file%, %section%, UnitHighlightList6Colour, 0xFFFFC663
	IniRead, UnitHighlightList7Colour, %config_file%, %section%, UnitHighlightList7Colour, 0xFF21FBFF

	IniRead, HighlightInvisible, %config_file%, %section%, HighlightInvisible, 1
	IniRead, UnitHighlightInvisibleColour, %config_file%, %section%, UnitHighlightInvisibleColour, 0xFFB7FF00

	IniRead, HighlightHallucinations, %config_file%, %section%, HighlightHallucinations, 1
	IniRead, UnitHighlightHallucinationsColour, %config_file%, %section%, UnitHighlightHallucinationsColour, 0xFF808080

	IniRead, UnitHighlightExcludeList, %config_file%, %section%, UnitHighlightExcludeList, CreepTumor, CreepTumorBurrowed
	IniRead, DrawMiniMap, %config_file%, %section%, DrawMiniMap, 1
	IniRead, TempHideMiniMapKey, %config_file%, %section%, TempHideMiniMapKey, !Space
	IniRead, DrawSpawningRaces, %config_file%, %section%, DrawSpawningRaces, 1
	IniRead, DrawAlerts, %config_file%, %section%, DrawAlerts, 1
	IniRead, HostileColourAssist, %config_file%, %section%, HostileColourAssist, 0
	
	;[Hidden Options]
	section := "Hidden Options"
	IniRead, AutoGroupTimer, %config_file%, %section%, AutoGroupTimer, 30 		; care with this setting this below 20 stops the minimap from drawing properly wasted hours finding this problem!!!!
	IniRead, AutoGroupTimerIdle, %config_file%, %section%, AutoGroupTimerIdle, 5	; have to carefully think about timer priorities and frequency
	
	; Resume Warnings
	Iniread, ResumeWarnings, %config_file%, Resume Warnings, Resume, 0

	return
}