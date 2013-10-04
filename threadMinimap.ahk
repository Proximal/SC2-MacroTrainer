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

;Cmdline passed script parameters 
pObject := "1", pObject := %pObject%	
pCriticalSection := "2", pCriticalSection := %pCriticalSection%
aThreads := CriticalObject(pObject, pCriticalSection)

tSpeak("hello", 100)



if !A_IsCompiled
{
	debug := True
	debug_name := "Kalamity"	
}

l_GameType := "1v1,2v2,3v3,4v4,FFA"
l_Races := "Terran,Protoss,Zerg"
GLOBAL GameWindowTitle := "StarCraft II"
GLOBAL GameIdentifier := "ahk_exe SC2.exe"
GLOBAL config_file := "MT_Config.ini"
GameExe := "SC2.exe"

#include %A_ScriptDir%\Included Files\Gdip.ahk
#Include <SC2_MemoryAndGeneralFunctions> ;In the library folder
pToken := Gdip_Startup()
Global aUnitID, aUnitName, aUnitSubGroupAlias, aUnitTargetFilter, aHexColours, MatrixColour
	, aUnitModel,  aPlayer, aLocalPlayer, minimap
	, a_pBrushes := [], a_pPens := []

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

settimer, timer_exit, 15000, -100 ; Just as a backup if the thread gets orphaned
l_Changeling := aUnitID["ChangelingZealot"] "," aUnitID["ChangelingMarineShield"] ","  aUnitID["ChangelingMarine"] 
				. ","  aUnitID["ChangelingZerglingWings"] "," aUnitID["ChangelingZergling"]
gameChange()
return

updateUserSettings()
{	
	Global hasReadConfig
	readConfigFile()
	hasReadConfig := True
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

 		if DrawUnitDestinations
 			drawUnitDestinations(G, A_MiniMapUnits)
		for index, unit in A_MiniMapUnits
			drawUnitRectangle(G, unit.X, unit.Y, unit.Radius + minimap.AddToRadius, unit.Radius + minimap.AddToRadius)	;draw rectangles first
		for index, unit in A_MiniMapUnits
			FillUnitRectangle(G, unit.X, unit.Y,  unit.Radius, unit.Radius, unit.Colour)

	}
	If (DrawSpawningRaces) && (getTime() - round(TimeReadRacesSet) <= 14) ;round used to change undefined var to 0 for resume so dont display races
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
	if DrawPlayerCameras
		drawPlayerCameras(G)

/* Test
	testObject := []
	unit := getselectedunitIndex()
	getUnitMoveCommands(unit, aQueuedMovements)
	testObject.insert({ "QueuedCommands": aQueuedMovements
					, "x": getUnitPositionX(unit)
					, "y": getUnitPositionY(unit) })
	drawUnitDestinations(G, testObject)
*/

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
           	  Colour := "UnitHighlightHallucinationsColour"
           else if type in %allActiveActiveUnitHighlightLists%
           {
           		; Overall, checking if the type is actually in the highlight list, 
           		; and then checking each  individual list 
           		; should be faster than needlessly checking every list

	           if type in %ActiveUnitHighlightList1%
	              Colour := "UnitHighlightList1Colour"
	           Else If type in %ActiveUnitHighlightList2%
	              Colour := "UnitHighlightList2Colour"                 
	           Else If type in %ActiveUnitHighlightList3%
	              Colour := "UnitHighlightList3Colour"                    
	           Else If type in %ActiveUnitHighlightList4%
	              Colour := "UnitHighlightList4Colour"                    
	           Else If type in %ActiveUnitHighlightList5%
	              Colour := "UnitHighlightList5Colour"   
	           Else If type in %ActiveUnitHighlightList6%
	              Colour := "UnitHighlightList6Colour"   
	           Else If type in %ActiveUnitHighlightList7%
	              Colour := "UnitHighlightList7Colour"
	       }
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

; Theres some problem here fix another day
; somtimes target x is empty 

/*
	public enum TargetFlags : uint
	{
		OverrideUnitPositon = 0x1,
		Unknown02 = 0x2,
		Unknown04 = 0x4,
		TargetIsPoint = 0x8,
		TargetIsUnit = 0x10,
		UseUnitPosition = 0x20
	}
*/

drawUnitDestinations(pGraphics, byRef A_MiniMapUnits)
{
	static a_pPen := [], hasRun

	if !hasRun
		a_pPen := createPens(1)

	for indexOuter, unit in A_MiniMapUnits
	{
		for indexQueued, movement in unit.QueuedCommands
		{
			if (movement.moveState = aUnitMoveStates.Amove)
				colour := "Red"
			else if (movement.moveState	= aUnitMoveStates.Patrol)
				colour := "Blue"
			else if (movement.moveState	= aUnitMoveStates.Move
				|| movement.moveState = aUnitMoveStates.Follow 
				|| movement.moveState = aUnitMoveStates.FollowNoAttack)
				colour := "Green"
			else colour := "Green"
		;	if !movement.targetX
		;		break
			if (indexQueued = unit.QueuedCommands.MinIndex())
				x := unit.x, y := unit.y 	
		;		convertCoOrdindatesToMiniMapPos(x,  y)	already coverted x, y due to minimap data
			Else 
				x := xTarget, y := yTarget

			convertCoOrdindatesToMiniMapPos(xTarget := movement.targetX, yTarget := movement.targetY)	
			Gdip_DrawLine(pGraphics, a_pPen[colour], x, y, xTarget, yTarget)
		
		
	;	objtree(unit.QueuedCommands)
	;	msgbox % x ", " y 
	;		. "`n"  xTarget ", " yTarget
	;		. "`n" unit.unit ", " aUnitName[getUnitType(unit.unit)]
	;		. "`n" getUnitPositionX(unit.unit) ", " getUnitPositionY(unit.unit)
		}
	}
	return
}


drawUnitDestinationsFromCompleteData(pGraphics, byRef aEnemyUnitData)
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
				|| movement.moveState = aUnitMoveStates.Follow 
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
	for colour, hexValue in aHexColours
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
		a_pPen := createPens(1)

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

			 Gdip_DrawLines(pGraphics, a_pPen[aPlayer[slotNumber, "colour"]],  x1 "," y1 "|" x2 "," y2 
							. "|" x3 "," y3 "|" x4 "," y4 "|" x1 "," y1 )
		}
	}
	return 
}







