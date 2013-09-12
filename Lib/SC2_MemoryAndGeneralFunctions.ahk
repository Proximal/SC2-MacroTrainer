/*

  O_pTimeSupplyCapped := 0x840
  O_pAPM := 0x5A0


*/


LoadMemoryAddresses(SC2EXE)
{	global
	mA := []
	;	[Memory Addresses]
	B_LocalCharacterNameID := SC2EXE + 0x04F65144  ; stored as string Name#123
	B_LocalPlayerSlot := SC2EXE + 0x011265D8 ; note 1byte and has a second copy just after +1byte eg LS =16d=10h, hex 1010 (2bytes) & LS =01d = hex 0101
	B_pStructure := SC2EXE + 0x035E7BC0 ;			 
	S_pStructure := 0xDC0 ;0xCE0
		O_pXcam := 0x8
		O_pCamDistance := 0xA
		O_pYcam := 0xC	
		O_pTeam := 0x1C
		O_pType := 0x1D ;
		O_pStatus := 0x1E
		O_pName := 0x60 ;+8
		O_pRacePointer := 0x158
		O_pColour := 0x160 ;+8 
		O_pAccountID := 0x1C0

		O_pAPM := 0x598
		O_pEPM := 0x5D8

		O_pWorkerCount := 0x788 ;+1c
		O_pWorkersBuilt := 0x798 ; number of workers made (includes the 6 at the start of the game)
		O_pBaseCount := 0x7F8 ; +18
		O_pSupplyCap := 0x848 ;+18		
		O_pSupply := 0x860 ;+ 12		
		O_pMinerals := 0x8A0 ;+18
		O_pGas := 0x8A8

		O_pArmySupply := 0x880
		O_pMineralIncome := 0x920 ;+20
		O_pGasIncome := 0x928
		O_pArmyMineralSize := 0xC08 ;0xB68 ;+A0
		O_pArmyGasSize := 0xC30 ;A8 

	P_IdleWorker := SC2EXE + 0x031073C0		
		O1_IdleWorker := 0x370
		O2_IdleWorker := 0x244
	B_Timer := SC2EXE + 0x3534F44 ;0x3534F40 ;0x24C9EE0 	(Function: GameGetMissionTime)			
	B_rStructure := SC2EXE + 0x02F6C850	
		S_rStructure := 0x10

	P_ChatFocus := SC2EXE + 0x031073C0 		;Just when chat box is in focus
		O1_ChatFocus := 0x3AC 
		O2_ChatFocus := 0x174

	P_MenuFocus := SC2EXE + 0x04FE4E5C 		;this is all menus and includes chat box when in focus ; old 0x3F04C04
		O1_MenuFocus := 0x17C

	B_uCount := SC2EXE + 0x2F6C438 				; This is the units alive (and includes missiles) ;0x02CF5588			
	B_uHighestIndex := SC2EXE + 0x3665100 ; 0x25F92C0		;this is actually the highest currently alive unit (includes missiles while alive)
	B_uStructure := SC2EXE + 0x3665140			
	S_uStructure := 0x1C0
		O_uModelPointer := 0x8
		O_uTargetFilter := 0x14
		O_uBuildStatus := 0x18		; buildstatus is really part of the 8 bit targ filter!
		O_XelNagaActive := 0x34
		; something added in here in vr 2.10

		O_uOwner := 0x41  ; this and the rest below +4
		O_uX := 0x4C
		O_uY := 0x50
		O_uZ := 0x54
		O_uDestinationX := 0x80
		O_uDestinationY := 0x84
		O_P_uCmdQueuePointer := 0xD4 ;+4
		O_P_uAbilityPointer := 0xDC

									; there are other offsets which can be used for chrono/inject state
		O_uChronoState := 0xE6				; pre 210 chrono and inject offsets were the same
		O_uInjectState := 0xE7 ; +5 Weird this was 5 not 4 (and its values changed) chrono state just +4

		O_uHpDamage := 0x114
		O_uEnergy := 0x11c 
		O_uTimer := 0x16C ;+4
		
	;CommandQueue 	; separate structure
		O_cqMoveState := 0x40	

	
	; Unit Model Structure	
	O_mUnitID := 0x6	
	O_mSubgroupPriority := 0x3A8 ;0x398
	O_mMiniMapSize := 0x3AC ;0x39C
	
	; selection and ctrl groups
	B_SelectionStructure := SC2EXE + 0x031CAB90 ;0x0215FB50 

	; Note: This is actually the second control group in the group structure. 
	; The structure begins with ctrl group 0, then goes to 1, But i used ctrl group 1 as base for simplicity 
	; when getting info for group 1, the negative offset will work fine 

	B_CtrlGroupOneStructure := SC2EXE + 0x031CFDB8 
	S_CtrlGroup := 0x1B60
	S_scStructure := 0x4	; Unit Selection & Ctrl Group Structures
		O_scTypeCount := 0x2
		O_scTypeHighlighted := 0x4
		O_scUnitIndex := 0x8

;	P_PlayerColours := SC2EXE + 0x03D28A84 ; 0 when enemies red  1 when player colours
;		O1_PlayerColours := 0x4
;		O2_PlayerColours := 0x17c

	B_TeamColours := SC2EXE + 0x03108504 ; 2 when team colours is on 
	; another one at + 0x4FA7800

	P_SelectionPage := SC2EXE + 0x031073C0 ; theres one other 3 lvl pointer but for a split second (ever second or so) it points to 
		O1_SelectionPage := 0x338			; the wrong address! You need to increase CE timer resolution to see this happening! Check it!
		O2_SelectionPage := 0x15C			;this is for the currently selected unit portrait page ie 1-6 in game (really starts at 0-5)
		O3_SelectionPage := 0x14C 			;might actually be a 2 or 1 byte value....but works fine as 4

	DeadFilterFlag := 0x0000000200000000	
	BuriedFilterFlag :=	0x0000000010000000

	B_MapStruct := SC2EXE + 0x3534EDC ; 0X024C9E7C 
		O_mLeft := B_MapStruct + 0xDC	                                   
		O_mBottom := B_MapStruct + 0xE0	                                   
		O_mRight := B_MapStruct + 0xE4	    ; MapRight 157.999756 (akilon wastes) after dividing 4096                     
		O_mTop := B_MapStruct + 0xE8	   	; MapTop: 622591 (akilon wastes) before dividing 4096  

	uMovementFlags := {Idle: -1  ; ** Note this isn't actually a read in game type/value its just what my funtion will return if it is idle
	, Amove: 0 		;these arent really flags !! cant '&' them!
	, Patrol: 1
	, HoldPosition: 2
	, Move: 256
	, Follow: 512
	, FollowNoAttack: 515} ; This is used by unit spell casters such as infestors and High temps which dont have a real attack 
	; note I have Converted these hex numbers from their true decimal conversion 
	

 															; If used as 4byte value, will return 256 	there seems to be 2 of these memory addresses
	P_IsUserPerformingAction := SC2EXE + 0x031073C0			; This is a 1byte value and return 1  when user is casting or in is rallying a hatch via gather/rally or is in middle of issuing Amove/patrol command but
		O1_IsUserPerformingAction := 0x230 					; if youre searching for a 4byte value in CE offset will be at 0x254 (but really if using it as 1 byte it is 0x255) - but im lazy and use it as a 4byte with my pointer command
															; also 1 when placing a structure (after structure is selected) or trying to land rax to make a addon Also gives 1 when trying to burrow spore/spine
															; When searching for 4 byte value this offset will be 0x254 
															; this address is really really useful!
															; it is even 0 with a burrowed swarm host selected (unless user click 'y' for rally which is even better)

/* 	Not Currently Used
	P_IsUserBuildingWithWorker := SC2EXE + 0x0209C3C8  	 	; this is like the one but will give 1 even when all structure are greyed out (eg lair tech having advanced mutations up)
		01_IsUserBuildingWithWorker := 0x364 				; works for workers of all races
		02_IsUserBuildingWithWorker := 0x17C           		; even during constructing SVC will give 0 - give 1 when selection card is up :)
		03_IsUserBuildingWithWorker := 0x3A8   				; also displays 1 when the toss hallucination card is displayed
		04_IsUserBuildingWithWorker := 0x168 				; BUT will also give 1 when a hatch is selected!!!

*/
	P_IsBuildCardDisplayed := SC2EXE + 0x0311ADB4		; this displays 1 or 0 with units selected - displays 7 when targeting reticle displayed/or placing a building (same thing)
		01_IsBuildCardDisplayed := 0x7C 				; **but when either build card is displayed it displays 6 (even when all advanced structures are greyed out)!!!!
		02_IsBuildCardDisplayed := 0x74 				; also displays 6 when the toss hallucination card is displayed
		03_IsBuildCardDisplayed := 0x398 				; could use this in place of the current 'is user performing action offset'
 														; Note: There is another address which has the same info, but when placing a building it will swap between 6 & 7 (not stay at 7)!


 	; There are two chat buffers - One blanks after you press return (to send chat)
 	; while the other one keeps the text even after the chat is sent/closed
 	; this is the latter
 															
 	P_ChatInput := SC2EXE + 0x04FE4E5C
 		O1_ChatInput := 0x35C 
 		O2_ChatInput := 0x78
 		O3_ChatInput := 0x274
 		O4_ChatInput := 0x14

/*
Around this modifier area are other values which contain the logical states
SC2.exe+1FDF7C6 is a 2byte value which contains the state of the numbers 0-9
SC2.exe+1FDF7D0 contains the state F-keys as well as keys like tab, backspace, Ins, left, right etc
SC2.exe+1FDF7C8 (8 bytes) contains the state of most keys eg a-z etc

*/

											; there are two of these the later 1 is actually the one that affects the game
											; Also the 1st one, if u hold down a modifier then go out of the game (small window mode)
											; it will remain 1 even when back in and shift isn't down as moving a unit wont be shift-commanded! so dont use that one
										  	;shift = 1, ctrl = 2, alt = 4 (and add them together)

															; 
	B_CameraDragScroll := SC2EXE + 0x304A478  				; 1 byte Returns 1 when user is moving camera via DragScroll i.e. mmouse button the main map But not when on the minimap (or if mbutton is held down on the unit panel)

	
	B_InputStructure := SC2EXE + 0x304A788
		B_iMouseButtons := B_InputStructure + 0x0 	; 1 Byte 	MouseButton state 1 for Lbutton,  2 for middle mouse, 4 for rbutton
		B_iSpace := B_iMouseButtons + 0x8 			; 1 Bytes
		B_iNums := B_iSpace + 0x2  					; 2 Bytes
		B_iChars := B_iNums + 0x2 					; 4 Bytes 
		B_iTilda := B_iChars + 0x4 					; 1 Byte  (could be 2 bytes)
		B_iNonAlphNumChars := B_iTilda + 0x2 		; 2 Bytes - keys: [];',./ Esc Entr \
		B_iNonCharKeys := B_iNonAlphNumChars + 0x2 	; 2 Bytes - keys: BS Up Down Left Right Ins Del Hom etc scrl lock pause caps + tab
		B_iFkeys := B_iNonCharKeys + 0x2 			; 2 bytes		
		B_iModifiers := B_iFkeys + 0x6 				; 1 Byte



	B_CameraMovingViaMouseAtScreenEdge := SC2EXE + 0x031073C0 		; Really a 1 byte value value indicates which direction screen will scroll due to mouse at edge of screen
		01_CameraMovingViaMouseAtScreenEdge	:= 0x2C0					; 1 = Diagonal Left/Top 		4 = Left Edge
		02_CameraMovingViaMouseAtScreenEdge	:= 0x20C				; 2 = Top 						5 = Right Edge			
		03_CameraMovingViaMouseAtScreenEdge	:= 0x4B4				; 3 = Diagonal Right/Top 	  	6 = Diagonal Left/ Bot	
																	; 7 = Bottom Edge 			 	8 = Diagonal Right/Bot 
																	; Note need to do a pointer scan with max offset > 1200d!

	B_IsGamePaused := SC2EXE + 0x31F15A5 						


	B_FramesPerSecond := SC2EXE + 0x04FA80EC
	B_Gamespeed  := SC2EXE + 0x04EEB184

	; example: D:\My Computer\My Documents\StarCraft II\Accounts\56064144\6-S2-1-79722\Replays\
	; this works for En, Fr, and Kr languages 
	B_ReplayFolder :=  SC2EXE + 0x04F669C0

	; Horizontal resolution ; 4 bytes
	; vertical resolution ; The next 4 bytes immediately after the Horizontal resolution cheat and search for 8 bytes 4638564681600 (1920 1080)

	B_HorizontalResolution := SC2EXE + 0x4FE4910
	B_VerticalResolution := B_HorizontalResolution + 0x4

/*
	; There is value reached via a pointer which will change the rendered resolution (even in widowed mode)
	P_HorizontalResolutionReal := SC2EXE + 0x01106654
		01_HorizontalResolutionReal := 0x90 
	P_VerticalResolutionReal := SC2EXE + 0x01106654
		01_VerticalResolutionReal := 0x94

*/

 ; The below offsets are not Currently used but are current for 2.0.8

/*

 	P_IsUserCasting := SC2EXE +	0x0209C3C8					; this is probably something to do with the control card
		O1_IsUserCasting := 0x364 							; 1 indicates user is casting a spell e.g. fungal, snipe, or is trying to place a structure
		O2_IsUserCasting := 0x19C 							; auto casting e.g. swarm host displays 1 always 
		O3_IsUserCasting := 0x228
		O4_IsUserCasting := 0x168

	P_IsCursorReticleBurrowedInfestor:= SC2EXE + 0x021857EC			; 1 byte	;seems to return 1 when cursors is reticle but not for inject larva on queen
		O1_IsCursorReticleBurrowedInfestor := 0x1C 					; also retursn 1 for burrowed swarm hosts though - auto cast? (and fungal - but reticle present for fungal)
		O2_IsCursorReticleBurrowedInfestor := 0x14 					; 0 when placing a building

	P_IsUserBuildingWithDrone := SC2EXE + 0x0209C3C8		; gives 1 when drone has basic mutation or advance mutaion/ open
		01_IsUserBuildingWithDrone := 0x364 				; Note: If still on hatch tech and all advanced building 'greyed out' will give 0!!!!!
		02_IsUserBuildingWithDrone := 0x17C 				; also gives 1 when actually attempting to place building
		03_IsUserBuildingWithDrone := 0x228
		04_IsUserBuildingWithDrone := 0x168
*/

	return	



/* Not Currently used
	B_CameraBounds := SC2EXE + 0x209A094
		O_x0Bound := 0x0
		O_XmBound := 0x8
		O_Y0Bound := 0x04
		O_YmBound := 0x0C
	
	B_CurrentBaseCam := 0x017AB3C8	;not current
		P1_CurrentBaseCam := 0x25C		;not current
*/	
}





getMapLeft()
{	global
	return ReadMemory(O_mLeft, GameIdentifier) / 4096
}
getMapBottom()
{	global
	return ReadMemory(O_mBottom, GameIdentifier) / 4096
}
getMapRight()
{	global
	return ReadMemory(O_mRight, GameIdentifier) / 4096
}
getMapTop()
{	global
	return ReadMemory(O_mTop, GameIdentifier) / 4096
}

isInControlGroup(group, unit) 
{	; group# = 1, 2,3-0  
	global  
	loop, % getControlGroupCount(Group)
		if (unit = getCtrlGroupedUnitIndex(Group,  A_Index - 1))
			Return 1	;the unit is in this control group
	Return 0			
}	;	ctrl_unit_number := ReadMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (group - 1) + O_scUnitIndex +(A_Index - 1) * S_scStructure, GameIdentifier, 2)/4

getCtrlGroupedUnitIndex(group, i=0)
{	global
	Return ReadMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (group - 1) + O_scUnitIndex + i * S_scStructure, GameIdentifier) >> 18
}


getControlGroupCount(Group)
{	global
	Return	ReadMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (Group - 1), GameIdentifier, 2)
}	

getTime()
{	global 
	Return Round(ReadMemory(B_Timer, GameIdentifier)/4096, 1)
}

getGameTickCount()
{	global 
	Return ReadMemory(B_Timer, GameIdentifier)
}

ReadRawUnit(unit, ByRef Memory)	; dumps the raw memory for one unit
{	GLOBAL
	ReadRawMemory(B_uStructure + unit * S_uStructure, GameIdentifier, Memory, S_uStructure)
	return
}


getSelectedUnitIndex(i=0) ;IF Blank just return the first selected unit (at position 0)
{	global
	Return ReadMemory(B_SelectionStructure + O_scUnitIndex + i * S_scStructure, GameIdentifier) >> 18	;how the game does it
	; returns the same thing ; Return ReadMemory(B_SelectionStructure + O_scUnitIndex + i * S_scStructure, GameIdentifier, 2) /4
}

getSelectionTypeCount()	; begins at 1
{	global
	Return	ReadMemory(B_SelectionStructure + O_scTypeCount, GameIdentifier, 2)
}
getSelectionHighlightedGroup()	; begins at 0 
{	global
	Return ReadMemory(B_SelectionStructure + O_scTypeHighlighted, GameIdentifier, 2)
}

getSelectionCount()
{ 	global 
	Return ReadMemory(B_SelectionStructure, GameIdentifier, 2)
}
getIdleWorkers()
{	global 	
	return pointer(GameIdentifier, P_IdleWorker, O1_IdleWorker, O2_IdleWorker)
}
getPlayerSupply(player="")
{ global
	If (player = "")
		player := a_LocalPlayer["Slot"]
	Return round(ReadMemory(((B_pStructure + O_pSupply) + (player-1)*S_pStructure), GameIdentifier)  / 4096)		
	; Round Returns 0 when memory returns Fail
}
getPlayerSupplyCap(player="")
{ 	Local SupplyCap 
	If (player = "")
		player := a_LocalPlayer["Slot"]
		SupplyCap := round(ReadMemory(((B_pStructure + O_pSupplyCap) + (player-1)*S_pStructure), GameIdentifier)  / 4096)
		if (SupplyCap > 200)	; as this will actually report the amount of supply built i.e. can be more than 200
			return 200
		else return SupplyCap 
}
getPlayerSupplyCapTotal(player="")
{ 	GLOBAL 
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return round(ReadMemory(((B_pStructure + O_pSupplyCap) + (player-1)*S_pStructure), GameIdentifier)  / 4096)
}
getPlayerWorkerCount(player="")
{ global
	If (player = "")
		player := a_LocalPlayer["Slot"]
	Return ReadMemory(((B_pStructure + O_pWorkerCount) + (player-1)*S_pStructure), GameIdentifier)
}

;  Number of workers made (includes the 6 at the start of the game)
; eg have 12 workers, but 2 get killed, and then you make one more
; this value will be 13.

getPlayerWorkersBuilt(player="")
{ global
	If (player = "")
		player := a_LocalPlayer["Slot"]
	Return ReadMemory(((B_pStructure + O_pWorkersBuilt) + (player-1)*S_pStructure), GameIdentifier)
}
getPlayerWorkersLost(player="")
{ 	global a_LocalPlayer
	If (player = "")
		player := a_LocalPlayer["Slot"]
	return getPlayerWorkersBuilt() - getPlayerWorkerCount()
}
getUnitType(Unit) ;starts @ 0 i.e. first unit at 0
{ global 

	LOCAL pUnitModel := ReadMemory(B_uStructure + (Unit * S_uStructure) + O_uModelPointer, GameIdentifier) ; note - this isnt really the correct pointer still have to << 5 
	if !aUnitModel[pUnitModel]
    	getUnitModelInfo(pUnitModel)
  	return aUnitModel[pUnitModel].Type
;	Return ReadMemory(((ReadMemory(B_uStructure + (Unit * S_uStructure) 
;				+ O_uModelPointer, GameIdentifier)) << 5) + O_mUnitID, GameIdentifier, 2) ; note the pointer is 4byte, but the unit type is 2byte/word
}
getUnitName(unit)
{	global 
	Return substr(ReadMemory_Str(ReadMemory(ReadMemory(((ReadMemory(B_uStructure + (Unit * S_uStructure) 
			+ O_uModelPointer, GameIdentifier)) << 5) + 0x6C, GameIdentifier), GameIdentifier) + 0x29, ,GameIdentifier), 6)
	;	pNameDataAddress := ReadMemory(unit_type + 0x6C, "StarCraft II")
	;	NameDataAddress  := ReadMemory(pNameDataAddress, "StarCraft II") + 0x29 ; ie its a pointer 
	;	Name := ReadMemory_Str(NameDataAddress, , "StarCraft II")
	;	NameLength := ReadMemory(NameDataAddress, "StarCraft II") 		
}

getUnitOwner(Unit) ;starts @ 0 i.e. first unit at 0 - 2.0.4 starts at 1?
{ 	global
	Return	ReadMemory((B_uStructure + (Unit * S_uStructure)) + O_uOwner, GameIdentifier, 1) ; note the 1 to read 1 byte
}

getUnitTargetFilter(Unit) ;starts @ 0 i.e. first unit at 0
{	local Memory, result 		;ReadRawMemory/numget is only ~11% faster

	ReadRawMemory(B_uStructure + Unit * S_uStructure + O_uTargetFilter, GameIdentifier, Memory, 8)
	loop 8 
		result += numget(Memory, A_index-1 , "Uchar") << 8*(A_Index-1)
	return result
;	Return	ReadMemoryOld((B_uStructure + (Unit * S_uStructure)) + O_uTargetFilter, GameIdentifier, 8) ;This is required for the reading of the 8 bit target filter - cant work out how to do this properly with numget without looping a char
}

getMiniMapRadius(Unit)
{	
	LOCAL pUnitModel := ReadMemory(B_uStructure + (Unit * S_uStructure) + O_uModelPointer, GameIdentifier) ; note - this isnt really the correct pointer still have to << 5 
	if !aUnitModel[pUnitModel]
    	getUnitModelInfo(pUnitModel)
  	return aUnitModel[pUnitModel].MiniMapRadius	
	;Return ReadMemory(((ReadMemory(B_uStructure + (unit * S_uStructure) + O_uModelPointer, GameIdentifier) << 5) & 0xFFFFFFFF) + O_mMiniMapSize, GameIdentifier) /4096
}


getUnitCount()
{	global
	return ReadMemory(B_uCount, GameIdentifier)
}

getHighestUnitIndex() 	; this is the highest alive units index - note its out by 1 - ie it starts at 1
{	global				; if 1 unit is alive it will return 1 (NOT 0)
	Return ReadMemory(B_uHighestIndex, GameIdentifier)	
}
getPlayerName(i) ; start at 0
{	global
	Return ReadMemory_Str((B_pStructure + O_pName) + (i-1) * S_pStructure, , GameIdentifier) 
}
getPlayerRace(i) ; start at 0
{	global
	local Race
	; Race := ReadMemory_Str((B_rStructure + (i-1) * S_rStructure), ,GameIdentifier) ;old easy way
	Race := ReadMemory_Str(ReadMemory(ReadMemory(B_pStructure + O_pRacePointer + (i-1)*S_pStructure, GameIdentifier) + 4, GameIdentifier), , GameIdentifier) 
	If (Race == "Terr")
		Race := "Terran"
	Else if (Race == "Prot")
		Race := "Protoss"
	Else If (Race == "Zerg")
		Race := "Zerg"	
	Else If (Race == "Neut")
		Race := "Neutral"
	Else 
		Race := "Race Error" ; so if it ever gets read out in speech, easily know its just from here and not some other error
	Return Race
}

getPlayerType(i)
{	global
	static oPlayerType := {	  0: "None"
							, 1: "User" 	; I believe all human players in a game have this type regardless if ally or on enemy team
							, 2: "Computer"
							, 3: "Neutral"
							, 4: "Hostile"
							, 5: "Referee"
							, 6: "Spectator" }

	Return oPlayerType[ ReadMemory((B_pStructure + O_pType) + (i-1) * S_pStructure, GameIdentifier, 1) ]
}

getPlayerTeam(player="") ;team begins at 0
{	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory((B_pStructure + O_pTeam) + (player-1) * S_pStructure, GameIdentifier, 1)
}
getPlayerColour(i)
{	local A_Player_Colour, Colour_List
	A_Player_Colour := []
	Colour_List := "White|Red|Blue|Teal|Purple|Yellow|Orange|Green|Light Pink|Violet|Light Grey|Dark Green|Brown|Light Green|Dark Grey|Pink"
	Loop, Parse, Colour_List, |
		A_Player_Colour[a_index - 1] := A_LoopField
	Return A_Player_Colour[ReadMemory((B_pStructure + O_pColour) + (i-1) * S_pStructure, GameIdentifier)]
}
getLocalPlayerNumber() ;starts @ 1
{	global
	Return ReadMemory(B_LocalPlayerSlot, GameIdentifier, 1) ;Local player slot is 1 Byte!!
}
getBaseCameraCount(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory((B_pStructure + O_pBaseCount) + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerMineralIncome(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pMineralIncome + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerGasIncome(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pGasIncome + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerArmySupply(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pArmySupply + (player-1) * S_pStructure, GameIdentifier) / 4096
}
getPlayerArmySizeMinerals(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pArmyMineralSize + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerArmySizeGas(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pArmyGasSize + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerMinerals(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pMinerals + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerGas(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pGas + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerCameraPositionX(Player="")
{	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pXcam, GameIdentifier) / 4096
}
getPlayerCameraPositionY(Player="")
{	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pYcam, GameIdentifier) / 4096
}
getPlayerCurrentAPM(Player="")
{	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pAPM, GameIdentifier)
}

isUnderConstruction(building) ; starts @ 0 and only for BUILDINGS!
{ 	global  ; 0 means its completed
;	Return ReadMemory(B_uStructure + (building * S_uStructure) + O_uBuildStatus, GameIdentifier) ;- worked fine
	return getUnitTargetFilterFast(building) & a_UnitTargetFilter.UnderConstruction
}

isUnitAStructure(unit)
{	GLOBAL 
	return getUnitTargetFilterFast(unit) & a_UnitTargetFilter.Structure
}

getUnitEnergy(unit)
{	global
	Return Floor(ReadMemory(B_uStructure + (unit * S_uStructure) + O_uEnergy, GameIdentifier) / 4096)
}

; Damage which has been delt to the unit
; need to substract max hp in unit to find actual health value/percentage
getUnitHpDamage(unit)
{	global
	Return Floor(ReadMemory(B_uStructure + (unit * S_uStructure) + O_uHpDamage, GameIdentifier) / 4096)
}

getUnitPositionX(unit)
{	global
	Return ReadMemory(B_uStructure + (unit * S_uStructure) + O_uX, GameIdentifier) /4096
}
getUnitPositionY(unit)
{	global
	Return ReadMemory(B_uStructure + (unit * S_uStructure) + O_uY, GameIdentifier) /4096
}


getUnitPositionZ(unit)
{	global
	Return ReadMemory(B_uStructure + (unit * S_uStructure) + O_uZ, GameIdentifier) /4096
}


getUnitMoveState(unit)
{	local CmdQueue, BaseCmdQueStruct
	if (CmdQueue := ReadMemory(B_uStructure + unit * S_uStructure + O_P_uCmdQueuePointer, GameIdentifier)) ; points if currently has a command - 0 otherwise
	{
		BaseCmdQueStruct := ReadMemory(CmdQueue, GameIdentifier) & -2
		return ReadMemory(BaseCmdQueStruct + O_cqMoveState, GameIdentifier, 2) ;current state
	}
	else return -1 ;cant return 0 as that ould indicate A-move
}

isUnitPatrolling(unit)
{	global
	return uMovementFlags.Patrol & getUnitMoveState(unit)
}


arePlayerColoursEnabled()
{	global
	return !ReadMemory(B_TeamColours, GameIdentifier) ; inverse as this is true when player colours are off
	;Return pointer(GameIdentifier, P_PlayerColours, O1_PlayerColours, O2_PlayerColours) ; this true when they are on
}

isGamePaused()
{	global
	Return ReadMemory(B_IsGamePaused, GameIdentifier)
}


isMenuOpen()
{ 	global
	Return  pointer(GameIdentifier, P_MenuFocus, O1_MenuFocus)
}

isChatOpen()
{ 	global
	Return  pointer(GameIdentifier, P_ChatFocus, O1_ChatFocus, O2_ChatFocus)
}


getUnitTimer(unit)
{	global 
	return ReadMemory(B_uStructure + unit * S_uStructure + O_uTimer, GameIdentifier)
}

isUnitHoldingXelnaga(unit)
{	global

	return ReadMemory(B_uStructure + unit * S_uStructure + O_XelNagaActive, GameIdentifier)
	;if (256 = ReadMemory(B_uStructure + unit * S_uStructure + O_XelNagaActive, GameIdentifier))
	;	return 1
	;else return 0
}

; example: D:\My Computer\My Documents\StarCraft II\Accounts\56064144\6-S2-1-79722\Replays\
getReplayFolder()
{	GLOBAL
	Return ReadMemory_Str(B_ReplayFolder, , GameIdentifier) 
}

getChatText()
{ 	Global
	Local ChatAddress := pointer(GameIdentifier, P_ChatInput, O1_ChatInput, O2_ChatInput
									, O3_ChatInput, O4_ChatInput)

	return ReadMemory_Str(ChatAddress,, GameIdentifier)	
}


; I noticed with this function, it will return 0 when there is less than half a second of cool down left - close enough

getWarpGateCooldown(WarpGate) ; unitIndex
{	global B_uStructure, S_uStructure, O_P_uAbilityPointer, GameIdentifier
	u_AbilityPointer := B_uStructure + WarpGate * S_uStructure + O_P_uAbilityPointer
	ablilty := ReadMemory(u_AbilityPointer, GameIdentifier) & 0xFFFFFFFC
	p1 := ReadMemory(ablilty + 0x28, GameIdentifier)	
	if !(p2 := ReadMemory(p1 + 0x1C, GameIdentifier)) ; 0 if it has never warped in a unit
		return 0
	p3 := ReadMemory(p2 + 0xC, GameIdentifier)
	cooldown := ReadMemory(p3 + 0x6, GameIdentifier, 2)
	if (cooldown >= 0) 		; as found in map editor some warpgates gave -1....but this could just be due to it being in the mapeditor (and was never a gateway...but doubtful)
		return cooldown
	else return 0
}
getUnitAbilityPointer(unit) ;returns a pointer which still needs to be read. The pointer will be different for every unit, but for units of same type when read point to same address
{	global
	return ReadMemory(B_uStructure + unit * S_uStructure + O_P_uAbilityPointer, GameIdentifier) & 0xFFFFFFFC
}

isUnitChronoed(unit)
{	global	; 1 byte = 18h chrono for protoss structures 10h normal state This is pre patch 2.10
			; pre 210 i used the same offset to check injects and chrono state
			; now this has changed
			; post 210 seems its 0 when idle and 128 when chronoed 
			; dont think i have to do the if = 128 check now, but leave it just in case - havent checked 
			; every building for a default value
	
	if (128 = ReadMemory(B_uStructure + unit * S_uStructure + O_uChronoState, GameIdentifier, 1))	
		return 1
	else return 0
}
; pre patch 2.10
; 16 dec / 0x10 when not injected
; 48 dec / 0x30 when injected
; hatch/lair/hive unit structure + 0xE2 = inject state 
isHatchInjected(Hatch)
{	global	; 1 byte = 18h chrono for protoss structures, 48h when injected for zerg -  10h normal state
			; this changed in 2.10 - 0 idle 4 for inject (probably dont need the if = 4 check)
	if (4 = ReadMemory(B_uStructure + Hatch * S_uStructure + O_uInjectState, GameIdentifier, 1))	
		return 1
	else return 0
}
isWorkerInProductionOld(unit) ; units can only be t or P, no Z
{										;state = 1 in prod, 0 not, -1 if doing something else eg flying
	local state
	local type := getUnitType(unit)
	if (type = A_unitID["CommandCenterFlying"] || type = A_unitID["OrbitalCommandFlying"])
		state := -1
	else if ( type = A_unitID["Nexus"]) 	; this stuffs up
	{
		local p2 := ReadMemory(getUnitAbilityPointer(unit) + 0x24, GameIdentifier)
		state := ReadMemory(p2 + 0x88, GameIdentifier, 1)
		if (state = 0x43)	;probe Or mothership	
			state := 1
		else 	; idle 0x3
			state := 0
	}
	Else if (type = A_unitID["CommandCenter"])
	{
		 state := ReadMemory(getUnitAbilityPointer(unit) + 0x9, GameIdentifier, 1)
		if (state = 0x12)	;scv in produ
			state := 1
		else if (state = 32 || state = 64)	;0x0A = flying 32 ->PF | 64 -> orbital
			state := -1										; yeah i realise this flying wont e
		else ; state = 0x76 idle
			state := 0
	}
	Else if  (type =  A_unitID["PlanetaryFortress"])
	{
		local p1 := ReadMemory(getUnitAbilityPointer(unit) + 0x5C, GameIdentifier)
		state := ReadMemory(p1 + 0x28, GameIdentifier, 1) ; This is acutally the queue size
	}
	else if (type =  A_unitID["OrbitalCommand"])
	{
		state := ReadMemory(getUnitAbilityPointer(unit) + 0x9, GameIdentifier, 1)
		if (state = 0x11)	;scv
			state := 1
		else state := 0 ; 99h  	;else if (state = 0)	;flying
	}
	return state
}

 ; returns state which is really the queue size
isWorkerInProduction(unit) ; units can only be t or P, no Z
{										;state = 1 in prod, 0 not, -1 if doing something else eg flying
	GLOBAL A_unitID
	type := getUnitType(unit)
	if (type = A_unitID["CommandCenterFlying"] || type = A_unitID["OrbitalCommandFlying"])
		state := 0
	Else if (type = A_unitID["CommandCenter"] && isCommandCenterMorphing(unit))
		state := 1
	else if (type = A_unitID["PlanetaryFortress"]) 
		getBuildStatsPF(unit, state) ;state = queue size 1 means 1 worker is in production
	else 
		getBuildStats(unit, state)
	return state

}

; state =	0x0A = flying | 32 ->PF | 64 -> orbital
; state = 	0x76 idle
isCommandCenterMorphing(unit)
{
	local state
	state := ReadMemory(getUnitAbilityPointer(unit) + 0x9, GameIdentifier, 1)
	if (state = 32 )	;	->PF
		return A_unitID["PlanetaryFortress"]
	else if (state = 64)	; 	-> Orbital
		return A_unitID["OrbitalCommand"]
	return 0
}


isHatchOrLairMorphing(unit)
{
			/*
			hatchery
			getUnitAbilityPointer(unit) + 0x8
			111 / 0x6f idle (same if making drones etc - doesnt effect it)
			103 / 0x67 when researching e.g. burrow, pneumatic carapace, ventral sacs
			9 / 0x9 when going to lair
			lair
			119  / 0x77 idle
			103 / 0x67 when researching e.g. burrow, pneumatic carapace, ventral sacs
			9 / 0x9 when going to lair
			17 /0x11 when going to hive
			*/
	local state, Type
	type := getUnitType(unit)
	state := ReadMemory(getUnitAbilityPointer(unit) + 0x8, GameIdentifier, 1)
	if (state = 9 && type = A_unitID["Hatchery"])	;	->PF
		return A_unitID["Lair"]
	else if (state = 17 && type = A_unitID["Lair"])	; 	-> Orbital
		return A_unitID["Hive"]
	return 0
}


IsUserMovingCamera()
{
	if (IsCameraDragScrollActivated() || IsCameraDirectionalKeyScrollActivated() || IsCameraMovingViaMouseAtScreenEdge())
		return 1
	else return 0
}

; 4 = left, 8 = Up, 16 = Right, 32 = Down  ; can be used with bitmasks
; these are added together if multiple keys are down e.g.  if Left, Up and Right are all active result = 28
IsCameraDirectionalKeyScrollActivated()  
{
	GLOBAL
	Return ReadMemory(B_iNonCharKeys, GameIdentifier, 1)
}

 	;1 byte - MouseButton state 1 for Lbutton,  2 for middle mouse, 4 for rbutton - again these can add togther eg lbutton + mbutton = 4
IsMouseButtonActive()
{	GLOBAL
	Return ReadMemory(B_iMouseButtons, GameIdentifier, 1)
}

; Really a 1 byte value
; 1 = Diagonal Left/Top 		4 = Left Edge
; 2 = Top 						5 = Right Edge			
; 3 = Diagonal Right/Top 	  	6 = Diagonal Left/ Bot	
; 7 = Bottom Edge 			 	8 = Diagonal Right/Bot
 

IsCameraMovingViaMouseAtScreenEdge()
{	GLOBAL
	return pointer(GameIdentifier, B_CameraMovingViaMouseAtScreenEdge, 01_CameraMovingViaMouseAtScreenEdge, 02_CameraMovingViaMouseAtScreenEdge, 03_CameraMovingViaMouseAtScreenEdge)
}

IsKeyDownSC2Input(CheckMouseButtons := False)
{	GLOBAL
	if (CheckMouseButtons && IsMouseButtonActive())
	|| ReadMemory(B_iSpace, GameIdentifier, 1)	
	|| ReadMemory(B_iNums, GameIdentifier, 2)	
	|| ReadMemory(B_iChars, GameIdentifier, 4)
	|| ReadMemory(B_iTilda, GameIdentifier, 1)
	|| ReadMemory(B_iNonAlphNumChars, GameIdentifier, 2)
	|| ReadMemory(B_iNonCharKeys, GameIdentifier, 2)
	|| ReadMemory(B_iFkeys, GameIdentifier, 2)
	|| ReadMemory(B_iModifiers, GameIdentifier, 1)
		return 1
	return 0
}

; 1 byte Returns 1 when user is moving camera via DragScroll i.e. Mmouse button the main map

IsCameraDragScrollActivated() 
{	GLOBAL
	Return ReadMemory(B_CameraDragScroll, GameIdentifier, 1)
}

	; there are two of these the later 1 is actually the one that affects the game
	; Also the 1st one, if u hold down a modifier then go out of the game (small window mode)
	; it will remain 1 even when back in and shift isn't down as moving a unit wont be shift-commanded! so dont use that one
  	;shift = 1, ctrl = 2, alt = 4 (and add them together)

	; these will return the same as if you check logical state of the key
	; there are two of these the later 1 is actually the one that affects the game
	; shift = 1, ctrl = 2, alt = 4 (and add them together)
	; left and right modifers give same values
	; if you modify these values will actually affect in game
readModifierState()
{	GLOBAL 
	return ReadMemory(B_iModifiers, GameIdentifier, 1)
}

readKeyBoardNumberState()
{	GLOBAL 
	return ReadMemory(B_iNums, GameIdentifier, 2)
}

getSCModState(KeyName)
{
	state := readModifierState()
	if instr(KeyName, "Shift")
		return state & 1 
	else if instr(KeyName, "Ctrl") || instr(KeyName, "Control") 
		return state & 2
	else if instr(KeyName, "Alt")
		return state & 4
	else return 0
}
; this will only have a temporary affect
; as sc2 continually poles the modifier states
; use exact value if you want to write a number
WriteModifiers(shift := 0, ctrl := 0, alt := 0, ExactValue := 0){
	LOCAL value 
	if shift
		value += 1
	if ctrl 
		value += 2 
	if alt 
		value += 4
	if ExactValue
		value := ExactValue
	Return WriteMemory(B_iModifiers, GameIdentifier, value,"Char")
}

; can check if producing by checking queue size via buildstats()
isGatewayProducingOrConvertingToWarpGate(Gateway)
{ 
;	gateway 
;	ability pointer + 0x8 
;	0x2F Idle
;	0x0F building unit
;	0x21 when converting to warpgate
;	0x40 when converting back to gateway from warpgate
; 	note there is a byte at +0x4 which indicates the previous state of the gateway/warpgate while morphing

	GLOBAL GameIdentifier
	state := readmemory(getUnitAbilityPointer(Gateway) + 0x8, GameIdentifier, 1)
	if (state = 0x0F || state = 0x21)
		return 1
	else return 0
}
isGatewayConvertingToWarpGate(Gateway)
{ 
	GLOBAL GameIdentifier
	state := readmemory(getUnitAbilityPointer(Gateway) + 0x8, GameIdentifier, 1)
	if (state = 0x21)
		return 1
	else return 0
}


SetPlayerMinerals(amount=99999)
{ 	global
	player := 1
	Return WriteMemory(B_pStructure + O_pMinerals + (player-1) * S_pStructure, GameIdentifier, amount,"ushort")   	 
}
SetPlayerGas(amount=99999)
{ 	global
	player := 1	
	Return WriteMemory(B_pStructure + O_pGas + (player-1) * S_pStructure, GameIdentifier, amount,"ushort")   
}


getBuildStatsPF(unit, byref QueueSize := "",  QueuePosition := 0) ; dirty hack until i can be bothered fixing this function
{	GLOBAL GameIdentifier
	STATIC O_pQueueArray := 0x34, O_IndexParentTypes := 0x18, O_unitsQueued := 0x28
	CAbilQueue := ReadMemory(getUnitAbilityPointer(unit) + 0x5C, GameIdentifier)

	localQueSize := ReadMemory(CAbilQueue + O_unitsQueued, GameIdentifier, 1) ; This is acutally the queue size

	if IsByRef(QueueSize)
		QueueSize := localQueSize
	queuedArray := readmemory(CAbilQueue + O_pQueueArray, GameIdentifier)
	B_QueueInfo := readmemory(queuedArray + 4 * QueuePosition, GameIdentifier)

	if localQueSize
		return getPercentageUnitCompleted(B_QueueInfo)
	else return 0
}


getBuildStats(building, byref QueueSize := "")
{
	pAbilities := getUnitAbilityPointer(building)
	AbilitiesCount := getAbilitiesCount(pAbilities)
	CAbilQueueIndex := getCAbilQueueIndex(pAbilities, AbilitiesCount)
	B_QueueInfo := getPointerToQueueInfo(pAbilities, CAbilQueueIndex, localQueSize)
	if IsByRef(QueueSize)
		QueueSize := localQueSize
	if localQueSize
		return getPercentageUnitCompleted(B_QueueInfo)
	else return 0
}


getPercentageUnitCompleted(B_QueueInfo)
{	GLOBAL GameIdentifier
	STATIC O_TotalTime := 0x68, O_TimeRemaining := 0x6C

	TotalTime := ReadMemory(B_QueueInfo + O_TotalTime, GameIdentifier)
	RemainingTime := ReadMemory(B_QueueInfo + O_TimeRemaining, GameIdentifier)

	return round( (TotalTime - RemainingTime) / TotalTime, 2) ;return .47 (ie 47%)
}

; this doesnt correspond to the unit in production for all structures!
getPointerToQueueInfo(pAbilities, CAbilQueueIndex, byref QueueSize := "", QueuePosition := 0)
{	GLOBAL GameIdentifier
	STATIC O_pQueueArray := 0x34, O_IndexParentTypes := 0x18, O_unitsQueued := 0x28

	CAbilQueue := readmemory(pAbilities + O_IndexParentTypes + 4 * CAbilQueueIndex, GameIdentifier)


	if IsByRef(QueueSize) 
		QueueSize := readmemory(CAbilQueue + O_unitsQueued, GameIdentifier)

	queuedArray := readmemory(CAbilQueue + O_pQueueArray, GameIdentifier)
	return B_QueueInfo := readmemory(queuedArray + 4 * QueuePosition, GameIdentifier)
}

getAbilitiesCount(pAbilities)
{	GLOBAL GameIdentifier
	return ReadMemory(pAbilities + 0x16, GameIdentifier, 1)
}

getCAbilQueueIndex(pAbilities, AbilitiesCount)
{	GLOBAL GameIdentifier
	STATIC CAbilQueue := 0x19
	ByteArrayAddress := ReadMemory(pAbilities, GameIdentifier) + 0x3 
	ReadRawMemory(ByteArrayAddress, GameIdentifier, MemDump, AbilitiesCount)
	loop % AbilitiesCount
		if (CAbilQueue = numget(MemDump, A_Index-1, "Char"))
			return A_Index-1
	 return -1 ;error
}

; this is just used for testing
getbilListIndex(pAbilities, AbilitiesCount)
{	GLOBAL GameIdentifier
	STATIC CAbilQueue := 0x19
	abilties := []
	ByteArrayAddress := ReadMemory(pAbilities, GameIdentifier) + 0x3 
	ReadRawMemory(ByteArrayAddress, GameIdentifier, MemDump, AbilitiesCount)
	loop % AbilitiesCount
		abilties.insert(CAbilQueue := dectohex(numget(MemDump, A_Index-1, "Char")))
	 return abilties
}

; These values are stored right next to each other, so to quickly find the correct ones again search for an 8byte value
SC2HorizontalResolution()
{	GLOBAL
	return  ReadMemory(B_HorizontalResolution, GameIdentifier)
}
SC2VerticalResolution()
{	GLOBAL
	return  ReadMemory(B_VerticalResolution, GameIdentifier)
}


; This is the character name and ID which is different for each region (obviously the name can be the same)
; Stored format = CharacterName#123 where 123 is the character ID

getCharacerInfo(byref returnName := "", byref returnID := "")
{	GLOBAL B_LocalCharacterNameID, GameIdentifier
	CharacterString := ReadMemory_Str(B_LocalCharacterNameID, , GameIdentifier) 
	StringSplit, OutputArray, CharacterString, #
	returnName := OutputArray1
	returnID := OutputArray2
	return OutputArray0 ; contains the number of substrings
}


; this is a buffer which is only written to when issuing ctrl/shift grouping actions
; therefore the units it refers to may change as units die
; and their unit indexs are reused!!!!!  So must use this CAREFULLY and only in certain situations!!!! 
; have to check if unit is alive  and control group buffer isn't updated

; unit dies and is replaced with own local unit
; when a unit dies and is replaced by a local unit of same type it obviously wont respond or the 'ctrl grouped' command group
; so dont have to worry about that scenario

; BUT still need to worry about the fact that the wrong units will be READ as alive
; so if you know what unit should be in this control group, then just check unit type matches, is local unit and is alive
; and this should work for most scenarios (or at least the chances of it causing a problem are quite low)

numGetControlGroupObject(Byref oControlGroup, Group)
{	GLOBAL B_CtrlGroupOneStructure, S_CtrlGroup, GameIdentifier, S_scStructure, O_scUnitIndex
	oControlGroup := []
	GroupSize := getControlGroupCount(Group)

	ReadRawMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (group - 1), GameIdentifier, MemDump, GroupSize * S_scStructure + O_scUnitIndex)
;	oControlGroup["Count"]	:= numget(MemDump, 0, "Short")
;	oControlGroup["Types"]	:= numget(MemDump, O_scTypeCount, "Short") ;this will get whats actually in the memory
	oControlGroup["Count"]	:= oControlGroup["Types"] := 0
	oControlGroup.units := []
	loop % numget(MemDump, 0, "Short")
	{
		unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
		if (!isUnitDead(unit) && isUnitLocallyOwned(unit))
		{

			oControlGroup.units.insert({ "UnitIndex": unit
										, "Type": Type := getUnitType(unit)
										, "Energy": getUnitEnergy(unit)
										, "x": getUnitPositionX(unit)
										, "y": getUnitPositionY(unit)
										, "z": getUnitPositionZ(unit)}) ;note the object is unitS not unit!!!
			oControlGroup["Count"]++
			if Type not in %typeList%
			{
				typeList .= "," Type 
				oControlGroup["Types"]++
			}

		}
	}
	return oControlGroup["Count"]
}


; On a side note, I discovered that there is a value 2-byte which represents of units in each subgroup
; for both the current selection and control groups
; the following subgroup count will be at +0x8



numGetUnitSelectionObject(ByRef aSelection, mode = 0)
{	GLOBAL O_scTypeCount, O_scTypeHighlighted, S_scStructure, O_scUnitIndex, GameIdentifier, B_SelectionStructure
	aSelection := []
	selectionCount := getSelectionCount()
	ReadRawMemory(B_SelectionStructure, GameIdentifier, MemDump, selectionCount * S_scStructure + O_scUnitIndex)
	; aSelection.insert({"SelectedTypes:"})
	aSelection["Count"]	:= numget(MemDump, 0, "Short")
	aSelection["Types"]	:= numget(MemDump, O_scTypeCount, "Short")
	aSelection["HighlightedGroup"]	:= numget(MemDump, O_scTypeHighlighted, "Short")

	aSelection.units := []
	if (mode = "Sort")		
	{
		loop % aSelection["Count"]
		{
			unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
			aSelection.units.insert({ "Type": getUnitType(unit), "UnitIndex": unit, "Priority": getSubGroupPriority(unit)})	;NOTE this object will be accessed differently than the one below
		}
		Sort2DArray(aSelection.units, "UnitIndex", 1) ; sort in ascending order
		Sort2DArray(aSelection.units, "Priority", 0)	; sort in descending order
	}
	else if (mode = "UnSortedWithPriority")		
		loop % aSelection["Count"]
		{
			unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
			aSelection.units.insert({ "Type": getUnitType(unit), "UnitIndex": unit, "Priority": getSubGroupPriority(unit)})
		}	
	else
		loop % aSelection["Count"]
		{
			unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
			, owner := getUnitOwner(unit), Type := getUnitType(unit), aSelection.units.insert({"UnitIndex": unit, "Type": Type, "Owner": Owner})
		}
	return aSelection["Count"]
}


numgetUnitTargetFilter(ByRef Memory, unit)
{
	local result 		;ahk has a problem with Uint64
	loop 8 
		result += numget(Memory, Unit * S_uStructure + O_uTargetFilter + A_index-1 , "Uchar") << 8*(A_Index-1)
	return result
  ; return numget(Memory, Unit * S_uStructure + O_uTargetFilter, "UDouble") ;not double!
}

getUnitTargetFilterFast(unit)	;only marginally faster ~12%
{	local Memory, result
	ReadRawMemory(B_uStructure + Unit * S_uStructure + O_uTargetFilter, GameIdentifier, Memory, 8)
	loop 8 
		result += numget(Memory, A_index-1 , "Uchar") << 8*(A_Index-1)
	return result
}

numgetUnitOwner(ByRef Memory, Unit)
{ global 
  return numget(Memory, Unit * S_uStructure + O_uOwner, "Char")  
}

numgetUnitModelPointer(ByRef Memory, Unit)
{ global 
  return numget(Memory, Unit * S_uStructure + O_uModelPointer, "Int")  
}




 getGroupedQueensWhichCanInject(ByRef aControlGroup,  CheckMoveState := 0)
 {	GLOBAL A_unitID, O_scTypeCount, O_scTypeHighlighted, S_CtrlGroup, O_scUnitIndex, GameIdentifier, B_CtrlGroupOneStructure
 	, S_uStructure, GameIdentifier, MI_Queen_Group, S_scStructure, uMovementFlags
	aControlGroup := []
	group := MI_Queen_Group
	groupCount := getControlGroupCount(Group)

	ReadRawMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (Group - 1), GameIdentifier, MemDump, groupCount * S_CtrlGroup + O_scUnitIndex)

	aControlGroup["UnitCount"]	:= numget(MemDump, 0, "Short")
	aControlGroup["Types"]	:= numget(MemDump, O_scTypeCount, "Short")
;	aControlGroup["HighlightedGroup"]	:= numget(MemDump, O_scTypeHighlighted, "Short")
	aControlGroup.Queens := []

	loop % groupCount
	{
		unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
		if isUnitDead(unit) ; as this is being reead from control group buffer so dead units can still be included!
			continue 
		type := getUnitType(unit)
		if (isUnitLocallyOwned(Unit) && A_unitID["Queen"] = type && ((energy := getUnitEnergy(unit)) >= 25)) 
		&& (!CheckMoveState 
			||  (CheckMoveState &&  (MoveState := getUnitMoveState(unit)) != uMovementFlags.Amove && MoveState != uMovementFlags.Move && MoveState != uMovementFlags.Patrol)  )  ; I do this because my blocking of keys isnt 100% and if the user is pressing H e.g. hold posistion army or make hydras 
			aControlGroup.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aControlGroup.Queens[aControlGroup.Queens.MaxIndex(), "Type"] := Type 		; and so can accidentally put queen on hold position thereby stopping injects!!!
	} 																																					; so queen is not moving/patrolling/a-moving ; also if user right clicks queen to catsh, that would put her on a never ending follow command
	aControlGroup["QueenCount"] := 	aControlGroup.Queens.maxIndex() ? aControlGroup.Queens.maxIndex() : 0 ; as "SelectedUnitCount" will contain total selected queens + other units in group
	return 	aControlGroup.Queens.maxindex()
 }

	; CheckMoveState for forced injects
 getSelectedQueensWhichCanInject(ByRef aSelection, CheckMoveState := 0)
 {	GLOBAL A_unitID, O_scTypeCount, O_scTypeHighlighted, S_scStructure, O_scUnitIndex, GameIdentifier, B_SelectionStructure
 	, S_uStructure, GameIdentifier, uMovementFlags 
	aSelection := []
	selectionCount := getSelectionCount()
	ReadRawMemory(B_SelectionStructure, GameIdentifier, MemDump, selectionCount * S_scStructure + O_scUnitIndex)
	aSelection["SelectedUnitCount"]	:= numget(MemDump, 0, "Short")
	aSelection["Types"]	:= numget(MemDump, O_scTypeCount, "Short")
	aSelection["HighlightedGroup"]	:= numget(MemDump, O_scTypeHighlighted, "Short")
	aSelection.Queens := []

	loop % selectionCount
	{
		unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
		type := getUnitType(unit)
		if (isUnitLocallyOwned(Unit) && A_unitID["Queen"] = type && ((energy := getUnitEnergy(unit)) >= 25)) 
		&& (!CheckMoveState 
			||  (CheckMoveState &&  (MoveState := getUnitMoveState(unit)) != uMovementFlags.Amove && MoveState != uMovementFlags.Move && MoveState != uMovementFlags.Patrol)  )  ; I do this because my blocking of keys isnt 100% and if the user is pressing H e.g. hold posistion army or make hydras
			aSelection.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aSelection.Queens[aSelection.Queens.MaxIndex(), "Type"] := Type 					; and so can accidentally put queen on hold position thereby stopping injects!!!
	} 																																			; also if user right clicks queen to catsh, that would put her on a never ending follow command
	aSelection["Count"] :=  aSelection.Queens.maxIndex() ? aSelection.Queens.maxIndex() : 0 ; as "SelectedUnitCount" will contain total selected queens + other units in group
	return 	aSelection.Queens.maxindex()
 }

isQueenNearHatch(Queen, Hatch, MaxXYdistance) ; takes objects which must have keys of x, y and z
{
	x_dist := Abs(Queen.X - Hatch.X)
	y_dist := Abs(Queen.Y- Hatch.Y)																									
																								; there is a substantial difference in height even on 'flat ground' - using a max value of 1 should give decent results
	Return Result := (x_dist > MaxXYdistance) || (y_dist > MaxXYdistance) || (Abs(Queen.Z - Hatch.Z) > 1) ? 0 : 1 ; 0 Not near
}

isUnitNearUnit(Queen, Hatch, MaxXYdistance) ; takes objects which must have keys of x, y and z
{
	x_dist := Abs(Queen.X - Hatch.X)
	y_dist := Abs(Queen.Y- Hatch.Y)																											
												; there is a substantial difference in height even on 'flat ground' - using a max value of 1 should give decent results
	Return Result := (x_dist > MaxXYdistance) || (y_dist > MaxXYdistance) || (Abs(Queen.Z - Hatch.Z) > 1) ? 0 : 1 ; 0 Not near
}

 objectGetUnitXYZAndEnergy(unit) ;this will dump just a unit
 {	Local UnitDump
	ReadRawMemory(B_uStructure + unit * S_uStructure, GameIdentifier, UnitDump, S_uStructure)
	Local x := numget(UnitDump, O_uX, "int")/4096, y := numget(UnitDump, O_uY, "int")/4096, Local z := numget(UnitDump, O_uZ, "int")/4096
	Local Energy := numget(UnitDump, O_uEnergy, "int")/4096
	return { "unit": unit, "X": x, "Y": y, "Z": z, "Energy": energy}
 }

 numGetUnitPositionXFromMemDump(ByRef MemDump, Unit)
 {	global
 	return numget(MemDump, Unit * S_uStructure + O_uX, "int")/4096
 }
 numGetUnitPositionYFromMemDump(ByRef MemDump, Unit)
 {	global
 	return numget(MemDump, Unit * S_uStructure + O_uY, "int")/4096
 }
 numGetUnitPositionZFromMemDump(ByRef MemDump, Unit)
 {	global
 	return numget(MemDump, Unit * S_uStructure + O_uZ, "int")/4096
 }
 numGetIsHatchInjectedFromMemDump(ByRef MemDump, Unit)
 {	global ; 1 byte = 18h chrono for protoss structures, 48h when injected for zerg -  10h normal state
 	return (4 = numget(MemDump, Unit * S_uStructure + O_uInjectState, "UChar")) ? 1 : 0
 }

numGetUnitPositionXYZFromMemDump(ByRef MemDump, Unit)
{	
	position := []
	, position.x := numGetUnitPositionXFromMemDump(MemDump, Unit)
	, position.y := numGetUnitPositionYFromMemDump(MemDump, Unit)
	, position.z := numGetUnitPositionZFromMemDump(MemDump, Unit)
	return position
}

SortUnitsByAge(unitlist="", units*)
{
	List := []		
	if unitlist		
	{				
		units := []	
		loop, parse, unitlist, |
			units[A_index] := A_LoopField
	}	
	for index, unit in units
		List[A_Index] := {Unit:unit,Age:getUnitTimer(unit)}
	Sort2DArray(List, "Age", 0) ; 0 = descending
	For index, obj in List
		SortedList .= List[index].Unit "|"
	return RTrim(SortedList, "|")
}


getBaseCamIndex() ; begins at 0
{	global 	
	return pointer(GameIdentifier, B_CurrentBaseCam, P1_CurrentBaseCam)
}

SortBasesByBaseCam(BaseList, CurrentHatchCam)
{
	BaseList := SortUnitsByAge(BaseList)	;getBaseCameraCount()
	loop, parse, BaseList, |
		if (A_loopfield <> CurrentHatchCam)
			if CurrentIndex
				list .= A_LoopField "|"
			else
				LoList .= A_LoopField "|"
		else 
		{
			CurrentIndex := A_index
			list .= A_LoopField "|"
		}

	if LoList
		list := list LoList 
	return RTrim(list, "|")
}
