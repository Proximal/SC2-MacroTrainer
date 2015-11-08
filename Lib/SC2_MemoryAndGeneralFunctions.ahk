;lets make all of the offsets super global (cant be fucked putting them in
; a global memory address array)
Global B_LocalCharacterNameID
, aSCOffsets
, OffsetsSC2Base 
, B_pStructure
, S_pStructure
, Offsets_Player_Status
, O_pXcam
, O_pCamDistance
, O_pCamAngle
, O_pCamRotation
, O_pYcam
, Offsets_Player_Team
, Offsets_Player_Type
, O_pVictoryStatus 
, O_pName
, Offsets_Player_RacePointer
, Offsets_Player_Colour
, O_pAccountID
, O_pAPM
, O_pEPM
, Offsets_Player_WorkerCount
, Offsets_Player_WorkersBuilt
, Offsets_Player_HighestWorkerCount
, Offsets_Player_CompletedTownHalls
, Offsets_Player_SupplyCap
, Offsets_Player_Supply
, Offsets_Player_Minerals
, Offsets_Player_Gas
, Offsets_Player_ArmySupply
, O_pMineralIncome
, O_pGasIncome
, Offsets_Player_ArmyMineralCost
, Offsets_Player_ArmyGasCost

, Offsets_IdleWorkerCountPointer
, B_Timer
, B_rStructure
, S_rStructure
, Offsets_ChatFocusPointer
, P_SocialMenu
, Offsets_UnitAliveCount
, Offsets_UnitHighestAliveIndex
, B_uStructure
, Offsets_Unit_StructSize
, Offsets_Unit_ModelPointer
, Offsets_Unit_TargetFilter
;, O_XelNagaActive
,  Offsets_Unit_Owner
, O_uX
, O_uY
, O_uZ
, O_uDestinationX
, O_uDestinationY
, Offsets_Unit_CommandQueuePointer
, Offsets_Unit_AbilityPointer
, Offsets_Unit_PoweredState
, Offsets_Unit_ChronoState
, Offsets_Unit_InjectState
, Offsets_Unit_BuffPointer
, Offsets_Unit_HPDamage
, Offsets_Unit_ShieldDamage
, Offsets_Unit_Energy
, Offsets_Unit_TimeAlive

, Offsets_QueuedCommand_StringPointer
, Offsets_QueuedCommand_TargetFingerPrint
, Offsets_QueuedCommand_TargetX
, Offsets_QueuedCommand_TargetY
, Offsets_QueuedCommand_TargetZ
, Offsets_QueuedCommand_TargetFlags
, Offsets_QueuedCommand_State
, Offsets_QueuedCommand_TimeRemaining
, Offsets_QueuedCommand_TimeRequired

, Offsets_UnitAbilities_ParentByteArrayIndex
, Offsets_UnitAbilities_AbilityPointerIndex
, Offsets_UnitAbilities_AbilityStringPointerIndex

, Offsets_CAbilQueue_QueuedCount
, Offsets_CAbilQueue_QueuedUnitsPointer

, Offsets_QueuedUnit_StringPointer
, Offsets_QueuedUnit_BuildTimeTotal
, Offsets_QueuedUnit_BuildTimeRemaining

, Offsets_UnitModel_ID
, Offsets_UnitModel_SubgroupPriority
, Offsets_UnitModel_MinimapRadius

, Offsets_Selection_Base
, Offsets_Group_ControlGroup0
, Offsets_Group_ControlGroupSize
, Offsets_Group_TypeCount
, Offsets_Group_HighlightedGroup
, Offsets_Group_UnitOffset

, Offsets_localArmyUnitCountPointer
, Offsets_TeamColoursEnabled
, P_SelectionPage
, O1_SelectionPage
, O2_SelectionPage
, O3_SelectionPage

, B_MapInfo
, O_FileInfoPointer
, B_MapStruct
, O_mLeft
, O_mBottom
, O_mRight
, O_mTop
, B_camLeft
, B_camBottom
, B_camRight
, B_camTop
, aUnitMoveStates
, B_UnitCursor
, O1_UnitCursor
, O2_UnitCursor

, P_IsUserPerformingAction
, O1_IsUserPerformingAction
, P_IsBuildCardDisplayed
, 01_IsBuildCardDisplayed
, 02_IsBuildCardDisplayed
, 03_IsBuildCardDisplayed
, P_ChatInput
, O1_ChatInput
, O2_ChatInput
, O3_ChatInput
, O4_ChatInput
, B_CameraDragScroll
, B_InputStructure
, B_iMouseButtons
, B_iSpace
, B_iNums
, B_iChars
, B_iTilda
, B_iNonAlphNumChars
, B_iNonCharKeys
, B_iFkeys
, B_iModifiers

, B_CameraMovingViaMouseAtScreenEdge
, 01_CameraMovingViaMouseAtScreenEdge
, 02_CameraMovingViaMouseAtScreenEdge
, 03_CameraMovingViaMouseAtScreenEdge
, B_IsGamePaused
, B_FramesPerSecond
, Offsets_GameSpeed
, B_ReplayFolder
, B_HorizontalResolution
, B_VerticalResolution
, P_MinimapPosition
, O_MinimapPosition

global aUnitModel := []
, aStringTable := []
, aMiniMapUnits := []

/*
  O_pTimeSupplyCapped := 0x840
  O_pActionsPerformed := 0x5A0 ; accumulative user commands
*/

class classAddressCachePlayerUnit
{
    __new(func)
    {
        this.__FuncUniqueName1234 := Func(func)
        return this
    }
    ; Store it in the base obj, so that __get doesn't get called again i.e. faster
    ; recreate obj on game start
    __get(key)
    {
        if this.HasKey(key)
            return this[key]
        return this[key] := this.__FuncUniqueName1234.(key)
    }  
}

loadMemoryAddresses(base, version := "")
{
	OffsetsSC2Base := base
	aSCOffsets := []
	aSCOffsets["playerAddress"] := new classAddressCachePlayerUnit("playerAddress")
	aSCOffsets["unitAddress"] := new classAddressCachePlayerUnit("getUnitAddress")

	if 0
	{
		v := v
	}	
	else ; load most recent in case patch didn't change offsets.
	{
		; These versions have matching offsets
		; !version in case the findVersion function stuffs up and returns 0/blank, thereby just assume match with latest offsets
		; Also worker threads do not pass the client verison
		if (version = "2.1.11.36281") 
			versionMatch := "2.1.11.36281"		
		else if (version = "2.1.12.36657" || !version) 
			versionMatch := "2.1.12.36657"		
		;else if version in 2.1.9.34644
		;	 versionMatch := version
		else versionMatch := false
		;	[Memory Addresses]
		B_LocalCharacterNameID := base + 0x4FBADF4 ; stored as string Name#123 There are a couple of these, but only one works after SC restart or out of game


		; bytes have swapped in patch 3? 
		;aSCOffsets["LocalPlayerSlot"] := [base + 0x018F5980, 0x18, 0x278, 0x258, 0x3DD] ; patch 3.3 ; note 1byte and has a second 'copy' (ReplayWatchedPlayer) just after +1byte eg LS =16d=10h, hex 1010 (2bytes) & LS =01d = hex 0101
	 
		B_pStructure := base + 0x362BF90 ; 			 
		S_pStructure := 0xE18
			 Offsets_Player_Status := 0x0
			 O_pXcam := 0x8 ; same address but obfuscated 
			 O_pYcam := 0xC	;
			 O_pCamDistance := 0x10 
			 O_pCamAngle := 0x14
			 O_pCamRotation := 0x18

			 Offsets_Player_Team := 0x1C ; patch 3.3
			 Offsets_Player_Type := 0x1D ;patch 3.3
			 O_pVictoryStatus := 0x1E
			 O_pName := 0x64 
			 
			 Offsets_Player_RacePointer := 0x5C ; same as old patch - but there was one at 0x160 - not there anymore
			 Offsets_Player_Colour := 0xD8   ; patch 3.3
			 O_pAccountID := 0x218 ;  0x1C0 

			 O_pAPM := 0x5F0 	; Instantaneous
			 O_pAPMAverage := 0x5F8
			 O_pEPM := 0x630 	; Instantaneous
			 O_pEPMAverage := 0x638 	
;568
			 Offsets_Player_WorkerCountAll := 0x5C8 ; p3.3 ; This includes workers currently in production!
			 Offsets_Player_WorkerCount := 0x6E8 ; p3.3 ; **Care dont confuse this with HighestWorkerCount (or worker count + production above)
			 Offsets_Player_CurrentTotalUnits := 0x5B0 ; p3.3 ;  current number of units (includes 6 starting scvs/units) doesn't include structures.  Increments on unit completion.
			 Offsets_Player_TotalUnitsBuilt := 0x568 	; p3.3 	Units built, doesn't include structures. Increments on unit completion.					
			 							; There are a couple of other similar values, one is probably highest current unit count achieved.
			 Offsets_Player_WorkersBuilt := 0x710 ; p3.3 ; number of workers made (includes the 6 at the start of the game) increases on worker completion
			 Offsets_Player_HighestWorkerCount := 0x868 ; p3.3 ; the current highest worker account achieved (increases on worker completion - providing its more workers than previous highest value)
			 Offsets_Player_CompletedTownHalls := 0x758 ; p3.3 ; Completed townHall count 

			 Offsets_Player_SupplyCap := 0x7A8 ; p3.3	
			 Offsets_Player_Supply := 0x7C0 ; p3.3 		
			 Offsets_Player_Minerals := 0x800 ; p3.3 
			 Offsets_Player_Gas := 0x808 ; p3.3 

			 Offsets_Player_ArmySupply := 0x7E0 ; p3.3	 
			 O_pMineralIncome := 0x978
			 O_pGasIncome := 0x980
			 Offsets_Player_ArmyMineralCost := 0xB68 ;p3.3 	; there are two (identical?) values for minerals/gas 
			 Offsets_Player_ArmyGasCost := 0xB90 ; p3.3 		; ** care dont use max army gas/mineral value! 

		 Offsets_IdleWorkerCountPointer := [base + 0x0181A28C, 0x8, 0x134]

		; 	This can be found via three methods, pattern scan:
		;	C1 EA 0A B9 00 01 00 00 01 0D ?? ?? ?? ?? F6 D2 A3 ?? ?? ?? ?? F6 C2 01 74 06 01 0D ?? ?? ?? ?? 83 3D ?? ?? ?? ?? 00 56 BE FF FF FF 7F
		; 	Timer Address = readMemory(patternAddress + 0x1C)
		; 	It can also be found as there are two (identical?) 4-byte timers next to each other.
		; 	So do the usual search between times to find the timer value, then search for an 8 byte representation of 
		;   two timers which have the same value.  GameGetMissionTime() refers to the second (+0x4) of these two timers.
		;	And via IDA (Function: GameGetMissionTime) (-0x800000 from IDA address)

		 B_Timer := base + 0x357A0D0		

		 B_rStructure := base + 0x02F6C850	; Havent updated as dont use this
			 S_rStructure := 0x10

		 ; Also be sure to check the pointer in a real game. Ones which appear valid via mapeditor maps may not work.
		 ; ***must be 0 when chat box not open yet another menu window is e.g. menu / options!!!!!!!!
		 ; note (its possible for it to be 1 while menu open - leave the chat box in focus and left click the menu button (on the right))
		 ; tends to end with the same offset after patches
		 Offsets_ChatFocusPointer := [base + 0x0181A234, 0x108, 0xE8] ;Just when chat box is in focus ; value = True if open. There will be 2 of these.
	

		 ; Removed this - using a similar (possibly the same value), but it represents menu depth
		 ; I.e. Chat in focus + menu open = 2, chat in focus  = 1. Chat not in focus + men open = 1
		 ; It may have always been this way, and i never realised
		 ; P_MenuFocus := base + 0x5045A6C 	;this is all menus and includes chat box when in focus (value 1)
		; 	 O1_MenuFocus := 0x17C 			; tends to end with this offset 

		P_SocialMenu := base + 0x0409B098 ; ???? Havent updated as dont use it

		Offsets_UnitAliveCount := base + 0x1821CC0 ;p3.3	; No longer near Offsets_UnitHighestAliveIndex
		 								; This is the units alive (and includes missiles) - near Offsets_UnitHighestAliveIndex (-0x18)		
		 								; There are two of these values and they only differ the instant a unit dies esp with missle fire (ive used the higher value) - perhaps one updates slightly quicker - dont think i use this offset anymore other than as a value in debugData()
		 								; Theres another one which excludes structures

		 Offsets_UnitHighestAliveIndex := base + 0x1F24840  ;p3.3		; This is actually the highest currently alive unit (includes missiles while alive) and starts at 1 NOT 0! i.e. 1 unit alive at index 0 = 1, 1 alive at index 7 = 8 
		; B_uStructure := base + 0x36AA840 ; Offsets_UnitHighestAliveIndex+0x40    			
		 Offsets_Unit_StructSize := 0x1E8 ; patch 3.3 = 488d
			 Offsets_Unit_ModelPointer := 0x8 ; p3.3
			 Offsets_Unit_TargetFilter := 0x14 ; p3.3
			 Offsets_Unit_Owner := 0x2E ; p3.3 ; There are 3 owner offsets (0x27, 0x40, 0x41) for changelings owner3 changes to the player it is mimicking
			; O_XelNagaActive := 0x34 	; xel - dont use as doesnt work all the time
			 O_uX := 0x4C
			 O_uY := 0x50
			 O_uZ := 0x54
			 O_uDestinationX := 0x80
			 O_uDestinationY := 0x84
			 Offsets_Unit_CommandQueuePointer := 0xE0 ; p3.3;0xD4
			 Offsets_Unit_AbilityPointer := 0xE8 ; p3.3 ;0xDC

			 Offsets_Unit_PoweredState := 0xF0 ; !!!Note there is also one at +4 - but this changes when chronoed!									
			 Offsets_Unit_ChronoState := 0x1A1	; there are other offsets which can be used for chrono/inject state ; pre 210 chrono and inject offsets were the same 
			 Offsets_Unit_InjectState := 0xF7 
			 Offsets_Unit_BuffPointer := 0x100 ; I think this is correct


			 Offsets_Unit_HPDamage := 0x138
			 Offsets_Unit_ShieldDamage := 0x13C
			 Offsets_Unit_Energy := 0x140 
			 Offsets_Unit_TimeAlive := 0x1A4 
			
		;CommandQueue 	
		Offsets_QueuedCommand_StringPointer := 0x20
		Offsets_QueuedCommand_TargetFingerPrint := 0x28
		Offsets_QueuedCommand_TargetX := 0x30
		Offsets_QueuedCommand_TargetY := 0x34
		Offsets_QueuedCommand_TargetZ := 0x38
		Offsets_QueuedCommand_TargetFlags := 0x40
		Offsets_QueuedCommand_State := 0x4C
		Offsets_QueuedCommand_TimeRemaining := 0xB4
		Offsets_QueuedCommand_TimeRequired := 0xCC

		; Unit ability structure
		Offsets_UnitAbilities_ParentByteArrayIndex := 0x4 
		Offsets_UnitAbilities_AbilityPointerIndex := 0x18	 ; An array of pointers begins here - Pointers to each of the units abilities start here
		Offsets_UnitAbilities_AbilityStringPointerIndex :=  0xA4 ; and array of string pointers begins here - these match to the Offsets_UnitAbilities_AbilityPointerIndex i.e. string index 0 is the name of ability pointer index 0
		
		Offsets_CAbilQueue_QueuedCount := 0x38 
		Offsets_CAbilQueue_QueuedUnitsPointer := 0x44 

		; Queued unit
		Offsets_QueuedUnit_BuildTimeTotal := 0x80 
		Offsets_QueuedUnit_BuildTimeRemaining := 0x84 		
		Offsets_QueuedUnit_StringPointer := 0xF4 
		; I dont use these
		Offsets_QueuedUnit_SpecificID := 0x68
		Offsets_QueuedUnit_Supply := 0x68
		Offsets_QueuedUnit_Minerals := 0x8C
		Offsets_QueuedUnit_Gas := 0x90

		; Unit Model Structure	
		Offsets_UnitModel_ID := 0x6 
		Offsets_UnitModel_SubgroupPriority := 0x3CC 
		Offsets_UnitModel_MinimapRadius := 0x3D0 
		
		
		Offsets_Selection_Base := base + 0x1EE9BB8 
		; The structure begins with ctrl group 0
		Offsets_Group_ControlGroup0 := base + 0x1EED278
		Offsets_Group_ControlGroupSize := 0x1B60
	; Unit Selection & Ctrl Group Structures use same offsets
			Offsets_Group_TypeCount := 0x2
			Offsets_Group_HighlightedGroup := 0x4
			Offsets_Group_UnitOffset := 0x8

		; gives the select army unit count (i.e. same as in the select army icon) - unit count not supply
		; dont confuse with similar value which includes army unit counts in production - or if in map editor unit count/index.
		; Shares a common base with P_IsUserPerformingAction, SelectionPtr, IdleWorkerPtr, ChatFocusPtr, B_UnitCursor, B_CameraMovingViaMouseAtScreenEdge (never realised it was so many derp)

		Offsets_localArmyUnitCountPointer := [base + 0x0181A358, 0x8, 0x138]


		 Offsets_TeamColoursEnabled := base + 0x1B7A174 ; 2 when team colours is on, else 0 (There are two valid addresses for this)
		 

		 P_SelectionPage := base + 0x314B920  	; Tends to end with these offsets. ***theres one other 3 lvl pointer but for a split second (every few second or so) it points to 
			 O1_SelectionPage := 0x320			; the wrong address! You need to increase CE timer resolution to see this happening! Or better yet use the 'continually perform the pointer scan until stopped' option.
			 O2_SelectionPage := 0x15C			;this is for the currently selected unit portrait page ie 1-6 in game (really starts at 0-5)
			 O3_SelectionPage := 0x14C 			;might actually be a 2 or 1 byte value....but works fine as 4


		BuriedFilterFlag := 0x0000000010000000

		 B_MapInfo := base + 0x357A010
			O_FileInfoPointer := 0 

		; at B_MapStruct -0x5C is a pointer which list map file name, map name, description and other stuff
		 B_MapStruct := base + 0x357A06C		;0x353C3B4 ;0x3534EDC ; 0X024C9E7C 
			 O_mLeft := B_MapStruct + 0xDC	                                   
			 O_mBottom := B_MapStruct + 0xE0	                                   
			 O_mRight := B_MapStruct + 0xE4	    ; MapRight 157.999756 (akilon wastes) after dividing 4096   (647167 before)                  
			 O_mTop := B_MapStruct + 0xE8	   	; MapTop: 622591 (akilon wastes) before dividing 4096  

		B_camLeft := base + 0x314D8E0
		B_camBottom := B_camLeft + 0x4
		B_camRight := B_camBottom + 0x4
		B_camTop := B_camRight + 0x4

		 aUnitMoveStates := { Idle: -1  ; ** Note this isn't actually a read in game type/value its just what my function will return if it is idle
							, Amove: 0 		
							, Patrol: 1
							, HoldPosition: 2
							, Move: 256
							, Follow: 512
							, FollowNoAttack: 515} ; This is used by unit spell casters such as infestors and High temps which dont have a real attack 
			
		B_UnitCursor :=	base + 0x314B920  
			O1_UnitCursor := 0x2C0	 					
			O2_UnitCursor := 0x21C 					

	 	; This base can be the same as B_UnitCursor				; If used as 4byte value, will return 256 	there are 2 of these memory addresses
		 P_IsUserPerformingAction := base + 0x314B920 			; This is a 1byte value and return 1  when user is casting or in is rallying a hatch via gather/rally or is in middle of issuing Amove/patrol command but
			 O1_IsUserPerformingAction := 0x230 				; if youre searching for a 4byte value in CE offset will be at 0x254 (but really if using it as 1 byte it is 0x255) - but im lazy and use it as a 4byte with my pointer command
																; also 1 when placing a structure (after structure is selected) or trying to land rax to make a addon Also gives 1 when trying to burrow spore/spine
																; When searching for 4 byte value this offset will be 0x254 
																; this address is really really useful!
																; it is even 0 with a burrowed swarm host selected (unless user click 'y' for rally which is even better)

	/* 	Not Currently Used
		P_IsUserBuildingWithWorker := base + 0x0209C3C8  	 	; this is like the one but will give 1 even when all structure are greyed out (eg lair tech having advanced mutations up)
			01_IsUserBuildingWithWorker := 0x364 				; works for workers of all races
			02_IsUserBuildingWithWorker := 0x17C           		; even during constructing SVC will give 0 - give 1 when selection card is up :)
			03_IsUserBuildingWithWorker := 0x3A8   				; also displays 1 when the toss hallucination card is displayed
			04_IsUserBuildingWithWorker := 0x168 				; BUT will also give 1 when a hatch is selected!!!

	*/
		; This tends to have the same offsets (though there are a few to choose from)
		 P_IsBuildCardDisplayed := base + 0x315FA34 		; this displays 1 (swarm host) or 0 with units selected - displays 7 when targeting reticle displayed/or placing a building (same thing)
			 01_IsBuildCardDisplayed := 0x7C 				; **but when either build card is displayed it displays 6 (even when all advanced structures are greyed out)!!!!
			 02_IsBuildCardDisplayed := 0x74 				; also displays 6 when the toss hallucination card is displayed
			 03_IsBuildCardDisplayed := 0x398 				; could use this in place of the current 'is user performing action offset'
	 														; Note: There is another address which has the same info, but when placing a building it will swap between 6 & 7 (not stay at 7)!


	 	; There are two chat buffers - One blanks after you press return (to send chat)
	 	; while the other one keeps the text even after the chat is sent/closed
	 	; this is the latter

	 	; note there are two of these so make sure pick the right one as there addresses 
	 	; can go from high to low so the one at the top of CE scan might not be the same one
	 	; that was at the top last time!
	 															
	 	 P_ChatInput := base + 0x0310EDEC 		; ?????? not updated/used currently
	 		 O1_ChatInput := 0x16C 
	 		 O2_ChatInput := 0xC
	 		 O3_ChatInput := 0x278
	 		 O4_ChatInput := 0x0

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

															
		 B_CameraDragScroll := base + 0x308E7A8   			; 1 byte Returns 1 when user is moving camera via DragScroll i.e. mmouse button the main map But not when on the minimap (or if mbutton is held down on the unit panel)

		
		 B_InputStructure := base + 0x308EAB8  		
			 B_iMouseButtons := B_InputStructure + 0x0 		; 1 Byte 	MouseButton state 1 for Lbutton,  2 for middle mouse, 4 for rbutton, 8 xbutton1, 16 xbutton2
			 B_iSpace := B_iMouseButtons + 0x8 				; 1 Bytes
			 B_iNums := B_iSpace + 0x2  					; 2 Bytes
			 B_iChars := B_iNums + 0x2 						; 4 Bytes 
			 B_iTilda := B_iChars + 0x4 					; 1 Byte  (could be 2 bytes)
			 B_iNonAlphNumChars := B_iTilda + 0x2 			; 2 Bytes - keys: [];',./ Esc Entr \
			 B_iNonCharKeys := B_iNonAlphNumChars + 0x2 	; 2 Bytes - keys: BS Up Down Left Right Ins Del Hom etc scrl lock pause caps + tab
			 B_iFkeys := B_iNonCharKeys + 0x2 				; 2 bytes		
			 B_iModifiers := B_iFkeys + 0x6 				; 1 Byte



		 B_CameraMovingViaMouseAtScreenEdge := base + 0x314B920  		; Really a 1 byte value value indicates which direction screen will scroll due to mouse at edge of screen
			 01_CameraMovingViaMouseAtScreenEdge := 0x2C0				; 1 = Diagonal Left/Top 		4 = Left Edge
			 02_CameraMovingViaMouseAtScreenEdge := 0x20C				; 2 = Top 						5 = Right Edge			
			 03_CameraMovingViaMouseAtScreenEdge := 0x5A4				; 3 = Diagonal Right/Top 	  	6 = Diagonal Left/ Bot	
																		; 7 = Bottom Edge 			 	8 = Diagonal Right/Bot 
																		; Note need to do a pointer scan with max offset > 1200d! Tends to have the same offsets
		B_IsGamePaused := base + 0x1AB3F7C 						

		B_FramesPerSecond := base + 0x5008BC4
		Offsets_GameSpeed  := base + 0x55E1330

		; example: D:\My Computer\My Documents\StarCraft II\Accounts\56025555\6-S2-1-34555\Replays\
		; this works for En, Fr, and Kr languages 
		B_ReplayFolder := base + 0x24C8D98 ; p3.0.3

		; Horizontal resolution ; 4 bytes
		; vertical resolution ; The next 4 bytes immediately after the Horizontal resolution 
		; cheat and search for 8 bytes 4638564681600 (1920 1080)
		; There will be 3 green static addresses (+many non-statics) One of them will change depending on resolution
		; Can resize in window mode and it will change too

		 B_HorizontalResolution := base + 0x5045520
		 B_VerticalResolution := B_HorizontalResolution + 0x4

		; 4 byte ints listed in memory: 808 28 1066 290  (at 1920x1080)
		P_MinimapPosition := base + 0x315FA34
		O_MinimapPosition := [0x4, 0xE0, 0xD4, 0x25C]

	}
	return versionMatch
}	

playerAddress(player := 1)
{
	if aSCOffsets["playerAddress"].HasKey(player) ; need to check has, key as this func is called internally when it doesnt --> loop
		return aSCOffsets["playerAddress", player]
	eax := player
	edx := ReadMemory(OffsetsSC2Base+0x1889130, GameIdentifier)
	edx ^= ReadMemory(OffsetsSC2Base+0x1F17828, GameIdentifier)
	edx ^=  0x0246D359 ;   xor edx,SC2.AllowCachingSupported+AB3119 ** ; Just a value not really an address
	ecx := ReadMemory(edx, GameIdentifier)
	eax := ecx + eax * 4 
	eax := ReadMemory(EAX, GameIdentifier)
	eax ^= ReadMemory(OffsetsSC2Base+0x188C68C, GameIdentifier)
	return aSCOffsets["playerAddress", player] := eax ^= 0x772BBADC 
}

/*
; Backtracked what wrote to mins to find this function
; You need to go up a couple of function calls
; EAX = player number
SC2.AssertAndCrash+375D1D - 75 12                 - jne SC2.AssertAndCrash+375D31 
SC2.AssertAndCrash+375D1F - 8B 15 3091B502        - mov edx,[SC2.exe+1889130]
SC2.AssertAndCrash+375D25 - 33 15 28781E03        - xor edx,[SC2.exe+1F17828]

SC2.AssertAndCrash+375D2B - 81 F2 59D34602        - xor edx,SC2.AllowCachingSupported+AB3119
; *** the above line changed to the below line on reload
; Its really just xoring a value, but CE fills in the address that coincidentally matches it
; 0x0246D359
SC2.AssertAndCrash+375D2B - 81 F2 59D34602        - xor edx,SC2.exe+227D359
SC2.AssertAndCrash+375D31 - 8B 0A                 - mov ecx,[edx]
SC2.AssertAndCrash+375D33 - 8D 04 81              - lea eax,[ecx+eax*4]
SC2.AssertAndCrash+375D36 - 8B 00                 - mov eax,[eax]
SC2.AssertAndCrash+375D38 - 33 05 8CC6B502        - xor eax,[SC2.exe+188C68C]
SC2.AssertAndCrash+375D3E - 35 DCBA2B77           - xor eax,ntdll.dll+15BADC
; The xor operand just happens to match that dll address!  Really just 0x772BBADC
; returns address (EAX)
SC2.AssertAndCrash+375D43 - C3                    - ret 
*/

getunitAddress(unitIndex)
{
	if aSCOffsets["unitAddress"].HasKey(unitIndex)
		return aSCOffsets["unitAddress", unitIndex]	
	edx := eax := unitIndex
	, eax &= 0xF 
	, eax *= Offsets_Unit_StructSize
	, edx >>= 0x4 
	, esi := ReadMemory(edx*4+OffsetsSC2Base+0x1F24848, GameIdentifier)
	, esi ^= ReadMemory(OffsetsSC2Base+0x188BFEC, GameIdentifier)
	, esi ^= 0x46E134B8
	return aSCOffsets["unitAddress", unitIndex]	:= esi += eax
}


; The actual mapleft() functions will not return the true values from the map editor
; eg left is 2 when it should be 0
; 19/6/15
; There are some other map values near this mapsture (integer) and floats
; the integer value is simply the below memory address values /4096 - however they seem to be rounded
; e.g. 745471/4096=181.999 vs 182
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
getMapPlayableLeft()
{
	return getCameraBoundsLeft() - 7
}
getMapPlayableRight()
{
	return getCameraBoundsRight() + 7
}
getMapPlayableBottom()
{
	return getCameraBoundsBottom() - 4
}
getMapPlayableTop() 
{
	return getCameraBoundsTop() + 4
}
getCameraBoundsLeft()
{
	return ReadMemory(B_camLeft, GameIdentifier) / 4096
}
getCameraBoundsBottom()
{
	return ReadMemory(B_camBottom, GameIdentifier) / 4096
}
getCameraBoundsRight()
{
	return ReadMemory(B_camRight, GameIdentifier) / 4096
}
getCameraBoundsTop()
{
	return ReadMemory(B_camTop, GameIdentifier) / 4096
}

; 11/12/14
; Identifying a specific unit is now possible i.e. can tell if a unit at a specific unit index
; is the same one which was previously there. 
; It's sad that I didn't realise this long ago, it would have simplified so many things.

; 
; Unit Base + 0 ushort times the unit Index has been reused (increases on death)
; Unit Base + 2 ushort is index number (divide by 4 or >> 2 if reading this as a ushort)
; When read as a dword this forms the individual ID value which permanently identifies this specific unit. This value is used throughout the game, particularity in selection/control group structures.
; Unit Base + 0 (dword) >> 18 this value to get the index number.

; Compare this dword directly with the non bit shifted values in the control group to 
; see if it is the same unit i.e. the unit which was originally control grouped
; and not a new one which currently exists at the same unit index

; Note Im going to refer to this value as fingerPrint - it is really the units
; individual ID, but i already have aUnitID, unitID and unit.ID etc littered everywhere. (which all refer to unit type)

getUnitFingerPrint(unitIndex)
{
	return readmemory(aSCOffsets["unitAddress", unitIndex], GameIdentifier)
}

FingerPrintToIndex(fingerPrint)
{
	return fingerPrint >> 18
}

IsInControlGroup(group, unitIndex)
{
	count := getControlGroupCount(Group)
	ReadRawMemory(Offsets_Group_ControlGroup0 + Offsets_Group_ControlGroupSize * group, GameIdentifier, Memory,  Offsets_Group_UnitOffset + count * 4)
	loop, % count 
	{
		if NumGet(Memory, Offsets_Group_UnitOffset + (A_Index - 1) * 4, "UInt") >> 18 = unitIndex
			return getUnitFingerPrint(unitIndex) = NumGet(Memory, Offsets_Group_UnitOffset + (A_Index - 1) * 4, "UInt")
	}
	Return 0	
}

controlGroupFingerPrints(Group)
{
	obj := []
	count := getControlGroupCount(Group)
	ReadRawMemory(Offsets_Group_ControlGroup0 + Offsets_Group_ControlGroupSize * group, GameIdentifier, Memory,  Offsets_Group_UnitOffset + count * 4)	
	loop, % count 
		obj.insert(NumGet(Memory, Offsets_Group_UnitOffset + (A_Index - 1) * 4, "UInt"))
	return obj
}

getControlGroupPortraitCount(group)
{
	count := 0
	loop, % bufferCount := numgetControlGroupMemory(controlBuffer, group)
	{
		unitIndex := (fingerPrint := NumGet(controlBuffer, (A_Index - 1) * 4, "UInt")) >> 18
		if getUnitFingerPrint(unitIndex) = fingerPrint && !(getUnitTargetFilter(unitIndex) & aUnitTargetFilter.Hidden)
			count++
	}
	return count
}

; Could dump the entire group (Offsets_Group_ControlGroupSize). But that seems wasteful 
; *** care should be taken with this. The base address of the dumped memory
; is the selection part of the control group - It does not contain the type or count
; so don't use those offsets when using numget() to retrieve indexes****
numgetControlGroupMemory(BYREF MemDump, group)
{
	if count := getControlGroupCount(Group)
		ReadRawMemory(Offsets_Group_ControlGroup0 + Offsets_Group_ControlGroupSize * group + Offsets_Group_UnitOffset, GameIdentifier, MemDump, count * 4)
	return count
}

getControlGroupCount(Group)
{	global
	Return	ReadMemory(Offsets_Group_ControlGroup0 + Offsets_Group_ControlGroupSize * Group, GameIdentifier, 2)
}	

getTime()
{	 
	Return Round(getGameTickCount()/4096, 1)
}

getTimeFull()
{	global 
	Return getGameTickCount()/4096
}

getGameTickCount()
{	 
	r := readMemory(OffsetsSC2Base + 0x188BC70, GameIdentifier)
	, r ^= readMemory(OffsetsSC2Base + 0x1F15DF4, GameIdentifier)
	, r ^= 0x6EAF10A5
	Return readMemory(r + 0x50, GameIdentifier)
}

ReadRawUnit(unit, ByRef Memory)	; dumps the raw memory for one unit
{	GLOBAL
	ReadRawMemory(B_uStructure + unit * Offsets_Unit_StructSize, GameIdentifier, Memory, Offsets_Unit_StructSize)
	return
}

; Always check selection count before using this to iterate the selection buffer
; due to the way SC updates the buffer / list of indexes. e.g. if the highest selected index is killed then the selection list does not change
; but the count does. If another unit which isnt the highest index dies, then the entire selection list is rewritten

getSelectedUnitIndex(i=0) ;IF Blank just return the first selected unit (at position 0)
{	global
	Return ReadMemory(Offsets_Selection_Base + Offsets_Group_UnitOffset + i * 4, GameIdentifier) >> 18	;how the game does it
	; returns the same thing ; Return ReadMemory(Offsets_Selection_Base + Offsets_Group_UnitOffset + i * 4, GameIdentifier, 2) /4
}
getSelectedUnitFingerPrint(i=0) ;IF Blank just return the first selected unit (at position 0)
{	global
	Return ReadMemory(Offsets_Selection_Base + Offsets_Group_UnitOffset + i * 4, GameIdentifier) 
	; returns the same thing ; Return ReadMemory(Offsets_Selection_Base + Offsets_Group_UnitOffset + i * 4, GameIdentifier, 2) /4
}
; begins at 1
; Tab/subgroup count
getSelectionTypeCount()	
{	global
	Return	ReadMemory(Offsets_Selection_Base + Offsets_Group_TypeCount, GameIdentifier, 2)
}
getSelectionHighlightedGroup()	; begins at 0 
{	global
	Return ReadMemory(Offsets_Selection_Base + Offsets_Group_HighlightedGroup, GameIdentifier, 2)
}
getSelectionCount()
{ 	global 
	Return ReadMemory(Offsets_Selection_Base, GameIdentifier, 2)
}
getIdleWorkers()
{	global 	
	return pointer(GameIdentifier, Offsets_IdleWorkerCountPointer*)
}
getPlayerSupply(player="")
{ 	global
	If (player = "")
		player := aLocalPlayer["Slot"]
	Return round(ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_Supply, GameIdentifier)  / 4096)		
	; Round Returns 0 when memory returns Fail
}
getPlayerSupplyCap(player := "")
{ 	
	if (SupplyCap := getPlayerSupplyCapTotal(player)) > 200	; as this will actually report the amount of supply built i.e. can be more than 200
		return 200
	else return SupplyCap 
}
getPlayerSupplyCapTotal(player="")
{ 	GLOBAL 
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return round(ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_SupplyCap, GameIdentifier)  / 4096)
}
getPlayerWorkerCount(player="")
{ 	global
	If (player = "")
		player := aLocalPlayer["Slot"]
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_WorkerCount, GameIdentifier)
}

;  Number of workers made (includes the 6 at the start of the game)
; eg have 12 workers, but 2 get killed, and then you make one more
; this value will be 13.

getPlayerWorkersBuilt(player="")
{ global
	If (player = "")
		player := aLocalPlayer["Slot"]
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_WorkersBuilt, GameIdentifier)
}
; Probably not accurate for drones morphing into structures
getPlayerWorkersLost(player="")
{ 	global aLocalPlayer
	If (player = "")
		player := aLocalPlayer["Slot"]
	return getPlayerWorkersBuilt() - getPlayerWorkerCount()
}
getPlayerHighestWorkerCount(player="")
{ global
	If (player = "")
		player := aLocalPlayer["Slot"]
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_HighestWorkerCount, GameIdentifier)
}
getUnitType(Unit) ;starts @ 0 i.e. first unit at 0
{ global 

	LOCAL pUnitModel := getUnitModelPointer(unit)
	if !aUnitModel[pUnitModel]
    	getUnitModelInfo(pUnitModel)
  	return aUnitModel[pUnitModel].Type
}

getUnitName2(unit)
{	global 
	Return substr(ReadMemory_Str(ReadMemory(ReadMemory(((ReadMemory(aSCOffsets["unitAddress", Unit] + Offsets_Unit_ModelPointer, GameIdentifier)) << 5) + 0xC, GameIdentifier), GameIdentifier) + 0x29, GameIdentifier), 6)
	;	pNameDataAddress := ReadMemory(unit_type + 0x6C, "StarCraft II")
	;	NameDataAddress  := ReadMemory(pNameDataAddress, "StarCraft II") + 0x29 
	;	Name := ReadMemory_Str(NameDataAddress, , "StarCraft II")
	;	NameLength := ReadMemory(NameDataAddress, "StarCraft II") 		
}
getUnitName(unitIndex)
{
	return unitModelName(getUnitModelPointer(unitIndex))
}
getUnitNameAlternate(unitIndex)
{
	return unitModelNameAlternate(getUnitModelPointer(unitIndex))
}

unitModelName(modelAddress)
{
	pNameDataAddress := ReadMemory(modelAddress + 0xC, GameIdentifier) ; mp + pName_address
	, pNameDataAddress := ReadMemory(pNameDataAddress, GameIdentifier) 
	, NameDataAddress := ReadMemory(pNameDataAddress, GameIdentifier) 
	return substr(ReadMemory_Str(NameDataAddress + 0x20, GameIdentifier), 11) ; trim Unit/Name/ from Unit/Name/Marine 	
}
; Should test if difference between trimming unit/Name and replacing e.g. if some weird models dont have unit/Name

unitModelNameAlternate(modelAddress)
{
	p := ReadMemory(modelAddress + 0xA20, GameIdentifier)
	if (p + 0 = "")
		return 
	name := ReadMemory_Str(p + 0x14, GameIdentifier) ; unitName/Revive
	StringReplace, name, name, /Revive,, All ; Not all names have /Revive suffix - so don't use substr()/TrimRight
	return name
}

getUnitOwner(Unit) 
{ 	global
	Return	ReadMemory(aSCOffsets["unitAddress", Unit] +  Offsets_Unit_Owner, GameIdentifier, 1) ; note the 1 to read 1 byte
}


getMiniMapRadius(Unit)
{	
	LOCAL pUnitModel := getUnitModelPointer(unit)
	if !aUnitModel[pUnitModel]
    	getUnitModelInfo(pUnitModel)
  	return aUnitModel[pUnitModel].MiniMapRadius	
	;Return ReadMemory(((ReadMemory(B_uStructure + (unit * Offsets_Unit_StructSize) + Offsets_Unit_ModelPointer, GameIdentifier) << 5) & 0xFFFFFFFF) + Offsets_UnitModel_MinimapRadius, GameIdentifier) /4096
}

getUnitCount()
{	global
	return ReadMemory(Offsets_UnitAliveCount, GameIdentifier)
}

getHighestUnitIndex() 	; this is the highest alive units index - note it starts at 1
{	global				; if 1 unit is alive it will return 1 (NOT 0)
	Return ReadMemory(Offsets_UnitHighestAliveIndex, GameIdentifier)	
}
getPlayerName(player) ; start at 0
{	global
	return "Player"
	Return ReadMemory_Str(B_pStructure + O_pName + player*S_pStructure, GameIdentifier) 
}
getPlayerRace(player) ; start at 0
{	
	static aLoopUp := {"Terr": "Terran", "Prot": "Protoss", "Zerg": "Zerg", "Neut": "Neutral", "Host": "Hostile"}
	;  Race := ReadMemory_Str((B_rStructure + (player-1) * S_rStructure), ,GameIdentifier) ;old easy way. Select terran, search for Terr - change race search for Prot or Zerg
	
	race := ReadMemory_Str(ReadMemory(ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_RacePointer, GameIdentifier) + 4, GameIdentifier), GameIdentifier) 
	if aLoopUp.HasKey(race)
		return aLoopUp[race]
	return "Race Error" ; so if it ever gets read out in speech, easily know its just from here and not some other error
}

getPlayerType(player := "")
{	global
	static oPlayerType := {	  0: "None"
							, 1: "User" 	; I believe all human players in a game have this type regardless if ally or on enemy team
							, 2: "Computer"
							, 3: "Neutral"
							, 4: "Hostile"
							, 5: "Referee"
							, 6: "Spectator" }
	If (player = "")
		player := aLocalPlayer["Slot"]					
	Return oPlayerType[ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_Type, GameIdentifier, 1)]
}

getPlayerVictoryStatus(player)
{	global
	static oPlayerStatus := {	  0: "Playing"
								, 1: "Victorious" 	
								, 2: "Defeated"
								, 3: "Tied" }
	Return oPlayerStatus[ReadMemory(aSCOffsets["playerAddress", player] + O_pVictoryStatus, GameIdentifier, 1)]
}

/*
Nuke's Enum
oPlayerStatus := {	  0: "Unused"
								, 1: "Active" 	
								, 2: "Left"
								, 3: "Tied"
								, 5: "Win"
								, 7: "SeeBuildings" 
								, 9: "Active9" 
								, 17: "Active14" 
								, 24: "Left" 
								, 25: "Active25" }
 all of these values occured while player was still 'active'
;5 ;9 ;13 ;17 ;33 ;65 ;73 ;81 ;129 ;133 ;137 ;145 ;161 ;193 ;209

*/

isPlayerActive(player)
{
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_Status, GameIdentifier, 1) & 1
}

getPlayerTeam(player="") ;team begins at 0
{	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_Team , GameIdentifier, 1)
}
getPlayerColour(player)
{	static aPlayerColour
	if !isObject(aPlayerColour)
	{
		aPlayerColour := []
		Colour_List := "White|Red|Blue|Teal|Purple|Yellow|Orange|Green|Light Pink|Violet|Light Grey|Dark Green|Brown|Light Green|Dark Grey|Pink"
		Loop, Parse, Colour_List, |
			aPlayerColour[a_index - 1] := A_LoopField
	}
	Return aPlayerColour[ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_Colour, GameIdentifier)]
}
/* Patch 3.3
SC2.AssertAndCrash+164683 - A1 0CC16702           - mov eax,[SC2.exe+188C10C]
SC2.AssertAndCrash+164688 - 33 05 F0A99602        - xor eax,[SC2.exe+1B7A9F0]
SC2.AssertAndCrash+16468E - 35 1BF35324           - xor eax,2453F31B : [6FF78088]
SC2.AssertAndCrash+164693 - 88 48 0D              - mov [eax+0D],cl
*/
; Patch 3.3 bytes changed. 
; In lobby first byte = 10 second byte = 10
; In game first byte = player number, second byte = player number - 1.
; in replay when viewing 'everyone' perspective, both are 10h
; when viewing an ai, 1st byte = player number,  2nd byte = 10h
; when viewing a player, 1st byte = player number, 2nd byte = player number -1

; There is a second static 2 byte value, but it only has the correct value during a game
; 1st byte = slot 2 byte = slot
getLocalPlayerNumber(byref replayByte := "") ;starts @ 1 (because the first player in the player structure is always player 0 = neutral)
{	
	static address
	if !address  ; not sure if safe. Havent testesed what happens when regions change - can u even do that now?
	{
		eax := readMemory(OffsetsSC2Base + 0x188C10C, GameIdentifier)
		eax ^= readMemory(OffsetsSC2Base + 0x1B7A9F0, GameIdentifier)
		eax ^= 0x2453F31B
		address := eax += 0x0D 
	}
	word := ReadMemory(address, GameIdentifier, 2) ;Local player slot is 1 Byte and 1 byte for replay)
	Return word & 0xFF, replayByte := word >> 8 
}

getPlayerBaseCameraCount(player="")
{ 	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_CompletedTownHalls, GameIdentifier)
}
getPlayerMineralIncome(player="")
{ 	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + O_pMineralIncome, GameIdentifier)
}
getPlayerGasIncome(player="")
{ 	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + O_pGasIncome, GameIdentifier)
}
getPlayerArmySupply(player="")
{ 	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_ArmySupply, GameIdentifier) / 4096
}

; Note this won't always agree with the replay active forces size.
; For example with zerg the active forces counts a completed observer as 150 minerals (100 = overlord, 50 = observer morph)
; but this address only counts it as 50 i.e. the cost of the observer morph

getPlayerArmySizeMinerals(player="")
{ 	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_ArmyMineralCost, GameIdentifier)
}
getPlayerArmySizeGas(player="")
{ 	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_ArmyGasCost, GameIdentifier)
}
getPlayerMinerals(player := "")
{ 	
	;If (player = "")
	;	player := aLocalPlayer["Slot"]
	If (player = "")
		player := aLocalPlayer["Slot"]
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_Minerals, GameIdentifier)
}
getPlayerGas(player="")
{ 	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + Offsets_Player_Gas, GameIdentifier)
}
getPlayerCameraPositionX(Player="")
{	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + O_pXcam, GameIdentifier) / 4096
}
getPlayerCameraPositionY(Player="")
{	global
	If (player = "")
		player := aLocalPlayer["Slot"]
		Return ReadMemory(aSCOffsets["playerAddress", player] + O_pYcam, GameIdentifier) / 4096
}
getPlayerCameraDistance(Player="")
{	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + O_pCamDistance, GameIdentifier) / 4096
}
getPlayerCameraAngle(Player="")
{	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + O_pCamAngle, GameIdentifier) / 4096
}
getPlayerCameraRotation(Player="")
{	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + O_pCamRotation, GameIdentifier) / 4096
}


;	Note if in game without other players (get instant victory)
;	then this value will remain zero
;	I think it might get frozen after a real game finishes 
;	but user decides to remain in the game

getPlayerCurrentAPM(Player="")
{	global
	If (player = "")
		player := aLocalPlayer["Slot"]	
	Return ReadMemory(aSCOffsets["playerAddress", player] + O_pAPM, GameIdentifier)
}

isUnderConstruction(building) ; starts @ 0 and only for BUILDINGS!
{ 	global  ; 0 means its completed
;	Return ReadMemory(B_uStructure + (building * Offsets_Unit_StructSize) + O_uBuildStatus, GameIdentifier) ;- worked fine
	return getUnitTargetFilter(building) & aUnitTargetFilter.UnderConstruction
}


getUnitEnergy(unit)
{	global
	Return Floor(ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_Energy, GameIdentifier) / 4096)
}

getUnitEnergyRaw(unit)
{	global
	Return ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_Energy, GameIdentifier) / 4096
}

numgetUnitEnergy(ByRef unitDump, unit)
{	global
	Return Floor(numget(unitDump, unit * Offsets_Unit_StructSize + Offsets_Unit_Energy, "Uint") / 4096)
}

numgetUnitEnergyRaw(ByRef unitDump, unit)
{	global
	Return numget(unitDump, unit * Offsets_Unit_StructSize + Offsets_Unit_Energy, "Uint") / 4096
}
; Damage which has been delt to the unit
; need to substract max hp in unit to find actual health value/percentage
; Why am i Flooring these??? 11/2015
getUnitHpDamage(unit)
{	global
	Return Floor(ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_HPDamage, GameIdentifier) / 4096)
}

getUnitShieldDamage(unit)
{	global
	Return Floor(ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_ShieldDamage, GameIdentifier) / 4096)
}

getUnitPositionX(unit)
{	global
	Return ReadMemory(aSCOffsets["unitAddress", unit] + O_uX, GameIdentifier) /4096
}
getUnitPositionY(unit)
{	global
	Return ReadMemory(aSCOffsets["unitAddress", unit]  + O_uY, GameIdentifier) /4096
}

getUnitPositionZ(unit)
{	global
	Return ReadMemory(aSCOffsets["unitAddress", unit] + O_uZ, GameIdentifier) /4096
}


/*
	Move Structure
	+0x0 next Command ptr either (& -2) or (& 0xFFFFFFFE)
	+0x4 unit Structure Address
	+08 Some ptr - maybe ability


	When at the last command, the Command ptr & 0xFFFFFFFE
	will = the adress of the first command
	also, the last bit of the Command ptr (pre &) will be set to 1

;  Offsets_QueuedCommand_State := 0x40 = AbilityCommand
; Nukes offsets/Research
<Struct Name="QueuedCommand" Size="-1">
<Member Name="pNextCommand" Type="Unsigned" Size="4" Offset="0"/>
<!--
 A Struct very similar to Command starts here. It is a bit different though. 
-->
<Member Name="AbilityPointer" Type="Unsigned" Size="4" Offset="pNextCommand+0x18" AbsoluteOffset="0x18"/>
<Member Name="TargetUnitID" Type="Unsigned" Size="4" Offset="AbilityPointer+8" AbsoluteOffset="0x20"/>
<Member Name="TargetUnitModelPtr" Type="Unsigned" Size="4" Offset="TargetUnitID+4" AbsoluteOffset="0x24"/>
<Member Name="TargetX" Type="Fixed" Size="4" Offset="TargetUnitModelPtr+4" AbsoluteOffset="0x28"/>
<Member Name="TargetY" Type="Fixed" Size="4" Offset="TargetX+4" AbsoluteOffset="0x2C"/>
<Member Name="TargetZ" Type="Fixed" Size="4" Offset="TargetY+4" AbsoluteOffset="0x30"/>
<Member Name="Unknown" Type="Unsigned" Size="4" Offset="TargetZ+4" AbsoluteOffset="0x34"/>
<Member Name="TargetFlags" Type="Unsigned" Size="4" Offset="Unknown+4" AbsoluteOffset="0x38"/>
<Member Name="Flags" Type="Unsigned" Size="4" Offset="TargetFlags+4" AbsoluteOffset="0x3C"/> ; OrderFlags 
<Member Name="AbilityCommand" Type="Unsigned" Size="1" Offset="Flags+4" AbsoluteOffset="0x40"/>
<Member Name="Player" Type="Unsigned" Size="1" Offset="AbilityCommand+2" AbsoluteOffset="0x42"/>
</Struct>

*/
; Check if a medivac, prism or overlord has a drop queued up
; unload command movestate = 2
; target flag  = 15 for drop and for movement
; target flag = 7 for hold position but movestate is the same
isTransportDropQueued(transportIndex)
{
	getUnitQueuedCommands(transportIndex, aCommands)
	for i, command in aCommands
	{
		if (command.ability = "MedivacTransport"
		|| command.ability = "WarpPrismTransport"
		|| command.ability = "OverlordTransport")
			return i
	}
	return 0
}

; Queued command structure
	; Sc 2.0
	; + 0 pointer to next command
	; 0x20 targetUnitIndex 	
	; 0x28 targetX 	
	; 0x2C targetY 	
	; 0x30 targetZ 	
	; 0x18 pString 	
	; 0x38 targetFlag 	
	; 0x3C OrderFlags 	
	; 0x40 state 


/*	
	static aTargetFlags := { "overrideUnitPositon":  0x1
							, "unknown02": 0x2
							, "unknown04": 0x4
							, "targetIsPoint": 0x8
							, "targetIsUnit": 0x10
						, "useUnitPosition": 0x20 }
	*/	


	; patch 3.3
	; + 0 pointer to next command
	; +4 = Unit address
	; +0x20 = Ability string pointer
	; +0x28 Target unit finger print 
	; +0x30 - Target X - Pretty Sure
	; +0x34 - Target y - Pretty Sure
	; +0x38 - Target z - Pretty Sure
	; +0x40 - Target Flag ? - think this is correct
	; +0x44 - OrderFlags ?? Havent checked this
	; +0x4C - Ability state  / command ability (2 bytes)
	; +0x4E - Player (1 byte)

	; Havent looked for differences between these for various units/commands
	; 0xB0 - TimeRemaining A 
	; 0xB4 - TimeRemaining B (slightly higher than A). Im using this atm.
	; 0xC4 - timeRemaining A
	; 0xCC - Total Time Required 
	; 0xD0 - timeRemaining B
	

	; Target Flag  Done with a probe
	; 00011111 1F move to point
	; 00011111 1F Attack move to Point
	; 00010000  targetIsPoint = 0x10 
	; 00100000  targetIsUnit = 0x20 
	; 01101101 6D attack structure with probe
	; 01101111 6F move to structure 

; Patrol move can shift queue multiple patrol waypoints/paths but only the current one or first one (if there are other preceding move commands) will be returned.
; If a another command (move/attack etc) is queued after a multi waypoint patrol, then SC will remove the extra patrol points and add
; the move command. This function will return all of these correctly. 


getUnitQueuedCommands(unit, byRef aQueuedMovements)
{
	static targetIsPointOrUnit := 0x10 | 0x20 ; point 0x10, unit 0x20

	aQueuedMovements := []
	if (CmdQueue := ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_CommandQueuePointer, GameIdentifier)) ; points if currently has a command - 0 otherwise
	{
		pNextCmd := ReadMemory(CmdQueue, GameIdentifier) ; If & -2 this is really the first command ie  = BaseCmdQueStruct
		loop 
		{
			ReadRawMemory(pNextCmd & -2, GameIdentifier, cmdDump, 0xF4 + 4)
			, targetFlag := numget(cmdDump, Offsets_QueuedCommand_TargetFlags, "UInt")

			;OrderFlags := numget(cmdDump, 0x3C, "UInt") ; OrderFlags 
			if !aStringTable.hasKey(pString := numget(cmdDump, Offsets_QueuedCommand_StringPointer, "UInt")) 
				aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
			aQueuedMovements.insert({ "targetX": numget(cmdDump, Offsets_QueuedCommand_TargetX, "UInt") / 4096  
									, "targetY": numget(cmdDump, Offsets_QueuedCommand_TargetY, "UInt") / 4096  
									, "targetZ": numget(cmdDump, Offsets_QueuedCommand_TargetZ, "UInt") / 4096 
									, "ability": aStringTable[pString] 
									, "targetFlag" : targetFlag
									;, "OrderFlags": OrderFlags
									;, "flagString": CommandFlagsToString(OrderFlags)
									, "targetIndex": numget(cmdDump, Offsets_QueuedCommand_TargetFingerPrint, "UInt") >> 18 
									, "state": numget(cmdDump, Offsets_QueuedCommand_State, "UShort") 
									;  These times are raw - need to '/ 65536 (2^16)' to get time in seconds
									, "timeRemaining": numget(cmdDump, Offsets_QueuedCommand_TimeRemaining, "UInt") 
									, "timeRequired": numget(cmdDump, Offsets_QueuedCommand_TimeRequired, "UInt") })

			if (A_Index > 20 || !(targetFlag & targetIsPointOrUnit || targetFlag = 0xF)) ; something went wrong or target isnt a point/unit and the targ flag isnt 0xF either 
			{ 	; target flag is usually 0xF for the morphing types (and units on hold position). In patch 2.x its was 7dec
				aQueuedMovements := []
				return 0
			}
		} Until (1 & pNextCmd := numget(cmdDump, 0, "UInt"))	; loop until the last/first bit of pNextCmd is set to 1
		return aQueuedMovements.MaxIndex() 	; interestingly after -2 & pNextCmd (the last one) it should = the first address
	}
	else return 0
}

CommandFlagsToString(commandFlags)
{
	static aFlags := {	Alternate: 0x1
					, 	Queued: 0x2 ;added to end of queue.
					, 	Preempt: 0x4 ;inserted at the start of queue.
					, 	SmartClick: 0x8
					, 	SmartRally: 0x10
					, 	Subgroup: 0x20
					, 	SetAutoCast: 0x40
					, 	SetAutoCastOn: 0x80
					, 	Required: 0x100
					, 	Unknown200: 0x200 ;v these two are checked if target is neither unit nor point.
					, 	Unknown400: 0x400 ;^ other one.
					, 	Minimap: 0x400000 } ;this may be wrong.

	for command, value in aFlags
	{
		if (value & commandFlags)
			s .= command ","
	}
	return SubStr(s, 1, -1)
}

/*
	QueenBuild = make creepTumour (or on way to making it) - state = 0
	Transfusion  - state = 0

*/

getUnitQueuedCommandString(aQueuedCommandsOrUnitIndex)
{
	if !isObject(aQueuedCommandsOrUnitIndex)
	{
		unitIndex := aQueuedCommandsOrUnitIndex	 ; safer to do this
		aQueuedCommandsOrUnitIndex := [] 			; as AHK has a weird thing where variables in functions can alter themselves strangely
		getUnitQueuedCommands(unitIndex, aQueuedCommandsOrUnitIndex) 
	}
	for i, command in aQueuedCommandsOrUnitIndex
	{
		if (command.ability = "move")
		{
			if (command.state = aUnitMoveStates.Patrol)
				s .= "Patrol,"
			else if (command.state = aUnitMoveStates.Move)
				s .= "Move,"
			else if (command.state = aUnitMoveStates.Follow)
				s .= "Follow,"
			else if (command.state = aUnitMoveStates.HoldPosition)
				s .= "Hold,"
			else if (movement.state	= aUnitMoveStates.FollowNoAttack)
				s .= "FNA," ; ScanMove
		}
		else if (command.ability = "attack")
			s .= "Attack,"
		else s .= command.ability ","
	}
	; just sort to remove duplicates
	if s
		Sort, s, D`, U
	return s
}

arePlayerColoursEnabled()
{	global
	return !ReadMemory(Offsets_TeamColoursEnabled, GameIdentifier) ; inverse as this is true when player colours are off
	;Return pointer(GameIdentifier, P_PlayerColours, O1_PlayerColours, O2_PlayerColours) ; this true when they are on
}

; give the army unit count (i.e. same as in the select army icon) - unit count not supply
getArmyUnitCount()
{
	return Round(pointer(GameIdentifier, Offsets_localArmyUnitCountPointer*))
}

isGamePaused()
{	global
	Return ReadMemory(B_IsGamePaused, GameIdentifier)
}

; Note: This is always true if the user is holding the drag camera button (middle mouse by default)

; In sc 2.xxx - this value was 1 for chat and all menus 
; Cant seem to find this exact value again
; In SC 3.xxx this value represents the menu/window depth
; e.g. have chat in focus the value is one.
; While the chat is in focus if you then open a menu (left click the menu button)
; will increment this value to 2.
; This may in fact be the same offset, but i never previously released you could 
; get the menu open when the chat was in focus.
isMenuOpen()
{ 	
	ecx := readMemory(OffsetsSC2Base + 0x1889A90, GameIdentifier)
	, ecx ^= readMemory(OffsetsSC2Base + 0x2370A24, GameIdentifier)
	, ecx ^= 0x8EE43918
	, ecx += 0x428
	return readMemory(ecx + 0x1C, GameIdentifier)
	;Return  pointer(GameIdentifier, P_MenuFocus, O1_MenuFocus)
}

isChatOpen()
{ 	global
	Return  pointer(GameIdentifier, Offsets_ChatFocusPointer*)
}

; True when previous chat box or the social menu has text focus.
; invalid outside of game

isSocialMenuFocused()
{	 
	Return  pointer(GameIdentifier, P_SocialMenu, 0x3DC, 0x3C4, 0x3A8, 0xA4)
}

; Time Alive in seconds
; 10/12/14 I just discovered that this is not accurate for protoss structures. 
; Chrono boost will cause this to increase faster, so care should be used.
; contaminate may delay it - havent checked.
getUnitTimer(unit)
{	global 
	return ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_TimeAlive, GameIdentifier)/4096
}

/*
01DFD4C0 - 8B 07  - mov eax,[edi]
01DFD4C2 - 89 55 08  - mov [ebp+08],edx
01DFD4C5 - 89 44 8E 28  - mov [esi+ecx*4+28],eax <<
01DFD4C9 - 8D 7E 28  - lea edi,[esi+28]
01DFD4CC - C7 45 10 10000000 - mov [ebp+10],00000010

EAX=00080001
EBX=00000000
ECX=00000001
EDX=00080001
ESI=05D88800 = p1 := ReadMemory(getUnitAbilityPointer(Xelnaga) + 0x18, GameIdentifier)
EDI=08C1B94C
ESP=08C1B4B4
EBP=08C1B4E4
EIP=01DFD4C9

*/
; 
; There can be multiple units on the xelnaga, 1 spot for each of the 16 players
; If one player has multiple units holding the xelnaga, only the unit with the highest
; unit index will be listed in their player slot on the tower

; returns a ',' delimited list of unit indexes of units which are capturing the tower
; these units can be owned by any player
getUnitsHoldingXelnaga(Xelnaga)
{
	p1 := ReadMemory(getUnitAbilityPointer(Xelnaga) + 0x18, GameIdentifier) ; TowerCapture ability
	if ReadMemory(p1 + 0xC, GameIdentifier) = 0x3A3 ; 0x3A3 when towerCaptured / 0xA3 when not captured
	{
		loop, 16
		{
			if (unit := ReadMemory(p1 + (A_Index - 1) * 4 + 0x38 , GameIdentifier))
				units .= unit >> 18 ","
		}
		return RTrim(units, ",")
	}
	return -1
}

;********
; Note: You can also check the units queued commands - This will have a xelnaga ability
; if its holding the xelnaga
;********

; if a local unit is on the tower, then its Index will be returned
; if multiple units are on the tower, the one with the highest index will be
; returned
getLocalUnitHoldingXelnaga(Xelnaga)
{
	;p1 := ReadMemory(findAbilityTypePointer(getUnitAbilityPointer(Xelnaga), aUnitID["XelNagaTower"], "TowerCapture"), GameIdentifier)	
	p1 := ReadMemory(getUnitAbilityPointer(Xelnaga) + 0x18, GameIdentifier) ; TowerCapture ability
	; 0x3A3 when towerCaptured / 0xA3 when not captured
	; though don't really need to check this, as if local unit isn't on
	; the tower, then unit/address = 0
	if ReadMemory(p1 + 0xC, GameIdentifier) = 0x3A3 && (unit := ReadMemory(p1 + aLocalPlayer["slot"] * 4 + 0x38 , GameIdentifier))
		return unit >> 18 
	return -1
}

; call this function at the start of every match
findXelnagas(byRef aXelnagas)
{
	aXelnagas := []
	loop, % getHighestUnitIndex()
	{
		if (aUnitID.XelNagaTower = getUnitType(A_Index - 1))
			aXelnagas.insert(A_Index - 1)
	}
	if aXelnagas.MaxIndex()
		return aXelnagas.MaxIndex()
	else return 0
}

; aXelnagas is a global array read at the start of each game

isLocalUnitHoldingXelnaga(unitIndex)
{	
	static tickCount := 0, unitsOnTower
	; Prevent lots of unnecessary memory reads
	; Though its not like it really matters
	; for a user invoked function
	if (A_TickCount - tickCount > 5)
	{
		tickCount := A_TickCount
		unitsOnTower := ""
		for i, xelnagaIndex in aXelnagas
		{
			if ((unitOnTower := getLocalUnitHoldingXelnaga(xelnagaIndex)) > 0)
				unitsOnTower .= unitOnTower ","	
		}	
	}
	if unitIndex in %unitsOnTower%
		return 1
	return 0
}

;  	for some reason this offset can be reversed for some units 
; 	perhaps if they kill a unit which is already on the tower?
; 	but it happens quite often
;	return ReadMemory(B_uStructure + unit * Offsets_Unit_StructSize + O_XelNagaActive, GameIdentifier)
	;if (256 = ReadMemory(B_uStructure + unit * Offsets_Unit_StructSize + O_XelNagaActive, GameIdentifier))
	;	return 1
	;else return 0


; example: D:\My Computer\My Documents\StarCraft II\Accounts\56044444\6-S2-1-72222\Replays\
getReplayFolder()
{	GLOBAL
	Return ReadMemory_Str(B_ReplayFolder, GameIdentifier) 
}

; Includes the final backslash
; D:\My Computer\My Documents\StarCraft II\Replays\  --- > D:\My Computer\My Documents\StarCraft II\    (In map editor game)
; D:\My Computer\My Documents\StarCraft II\Accounts\56088844\6-S2-1-49888\Replays\ --> D:\My Computer\My Documents\StarCraft II\Accounts\56088844\
getAccountFolder()
{ 	
	replayFolder := getReplayFolder()
	if RegExMatch(replayFolder, ".*\\Accounts\\[0-9]*\\", folder) 
		return InStr(FileExist(folder), "D") ? folder : ""
	else return RegExMatch(replayFolder, ".*\\StarCraft II\\", folder) && InStr(FileExist(folder), "D") ? folder : "" ; MapEditor - Root SC folder
}


getChatText()
{ 	Global
	Local ChatAddress := pointer(GameIdentifier, P_ChatInput, O1_ChatInput, O2_ChatInput
									, O3_ChatInput, O4_ChatInput)

	return ReadMemory_Str(ChatAddress, GameIdentifier)	
}

getFPS()
{
	return ReadMemory(B_FramesPerSecond, GameIdentifier)
}

getGameSpeed()
{
	static aGameSpeed := { 	0: "Slower"
						,	1: "Slow"
						,	2: "Normal"
						,	3: "Fast"
						,	4: "Faster" }
	return aGameSpeed[ReadMemory(Offsets_GameSpeed, GameIdentifier)]
}


; I noticed with this function, it will return 0 when there is less than half a second of cool down left - close enough
; should really be finding the pointer by looking up the ability index ID in the byte array.
; but im lazy and this works
; ht = 45s * 65536 =  2949120
; 44s * 65536 = 2883584

getWarpGateCooldown(unit, type) ; unitIndex
{	
	p := findAbilityTypePointer(getUnitAbilityPointer(unit), type, "WarpGateTrain")
	p := readmemory(p, GameIdentifier)
	if !p := readmemory(p + 0x2C, GameIdentifier)
		return 0
	pStruct := readmemory(p + 0, GameIdentifier) ; there was another apparently identical pointer at +0x4
	timeRemaining := readMemory(pStruct + 0xC, GameIdentifier)
	;totalTime := readMemory(pStruct + 0x10) ; This value remains after cool down complete
	if (timeRemaining >= 0 && !(timeRemaining >> 31 & 1))
		return timeRemaining / 65536
	return 0

	; as found in map editor some warpgates gave -1....but this could just be due to it being in the mapeditor (and was never a gateway...but doubtful)
	; or i could have just stuffed something up when testing no harm in being safe.
	; Edit 1/7/14
	; Sometimes this value is 0xFFFFF800 or 0xfffff000 on a warpagte when NOT on cooldown
	; This was in a custom game against no AI (instant victory) and I gave myself extra resources
	; I don't know if there are other non-cooldown values
	; When against an AI (no extra resources) this value was always 0
	; But for safety sake add a basic check
	; so check if the 32 bit is not set (it will never be set when on cooldown - too high)
	; A better method would be to look for a byte in the WarpGateTrain indicating its on cooldown.
	; but im tired.
}
/*
; Dont use not updated
getMedivacBoostCooldown(unit)
{
	; This is a bit weird. 
	; In mapeditor if never boosted p1 = 0, but in a real game
	; p1 is valid and p2 = 0
	if (!(p1 := ReadMemory(getUnitAbilityPointer(unit) + 0x28, GameIdentifier))
		|| !(p2 := readmemory(p1+0x1c, GameIdentifier)) )
		return 0	
	p3 := readmemory(p2+0xc, GameIdentifier)
	return ReadMemory(p3+0x4, GameIdentifier)
}
*/

getUnitAbilityPointer(unit) ;returns a pointer which still needs to be read. The pointer will be different for every unit, but for units of same type when read point to same address
{	global
	return ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_AbilityPointer, GameIdentifier) & 0xFFFFFFFC
}

getUnitAbilitiesString(unit, msgbox := True)
{
	if !pAbilities := getUnitAbilityPointer(unit)
		return clipboard := "pAbilities = 0"
	p1 := readmemory(pAbilities, GameIdentifier)
	s := "pAbilities: " chex(pAbilities) " Unit ID: " unit "`nuStruct: " chex(getunitAddress(unit)) " - " chex(getunitAddress(unit) + Offsets_Unit_StructSize)
	loop
	{
		if (p := ReadMemory( address := p1  +  Offsets_UnitAbilities_AbilityStringPointerIndex + (A_Index - 1)*4, GameIdentifier))
		{
			s .= "`n"  A_Index - 1 " | Pointer Address " chex(pAddress := pAbilities + Offsets_UnitAbilities_AbilityPointerIndex + (A_Index - 1)*4) "  (+0x" chex(pAddress - pAbilities) ") | Pointer Value "  chex(ReadMemory(pAddress, GameIdentifier)) " | "  ReadMemory_Str(ReadMemory(p + 4, GameIdentifier), GameIdentifier)
			count++
		}
	} until p = 0
	s .= "`nLoop Count: " count A_TAB "Read Count: " getAbilitiesCount(pAbilities)
	if msgbox
		msgbox % clipboard := s
	return s
}

numgetUnitAbilityPointer(byRef unitDump, unit)
{
	return numget(unitDump, unit * Offsets_Unit_StructSize + Offsets_Unit_AbilityPointer, "UInt") & 0xFFFFFFFC
}
;
;;; 6144 when stimmed 4096 when not
;isUnitStimed(unit)
;{
;	structure := readmemory(getUnitAbilityPointer(unit) + 0x20, GameIdentifier)
;	return (readmemory(structure + 0x38, GameIdentifier) = 6144) ? 1 : 0
;}

isUnitChronoed(unit)
{	global	; 1 byte = 18h chrono for protoss structures 10h normal state This is pre patch 2.10
			; pre 210 i used the same offset to check injects and chrono state
			; now this has changed
			; post 210 seems its 0 when idle and 128 when chronoed 
			; dont think i have to do the if = 128 check now, but leave it just in case - havent checked 
			; every building for a default value
	
	return 24 = ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_ChronoState, GameIdentifier, 1)	
}

numgetIsUnitChronoed(byref unitDump, unit)
{	global	
	return 24 = numget(unitDump, unit * Offsets_Unit_StructSize + Offsets_Unit_ChronoState, "UChar")	
}

numgetIsUnitPowered(byref unitDump, unit)
{	global	
	return 0 = numget(unitDump, unit * Offsets_Unit_StructSize + Offsets_Unit_PoweredState, "UInt")	
}
; Returns True for structures which do not require power e.g. nexus, pylons, rocks
isUnitPowered(unit)
{
	return 0 = ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_PoweredState, GameIdentifier)	
}

; This whole area (inject/chrono/powered) is some type of bit field. Note there are a few this which can indicate chrono/power/inject
; some may just be parts of points

; pre patch 2.10
; 16 dec / 0x10 when not injected
; 48 dec / 0x30 when injected
; hatch/lair/hive unit structure + 0xE2 = inject state 
isHatchInjected(unit)
{	global	; 1 byte = 18h chrono for protoss structures, 48h when injected for zerg -  10h normal state
			; this changed in 2.10 - 0 idle 4 for inject 
	return 2 = ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_InjectState, GameIdentifier, 1)
}
; The byte at Offsets_Unit_PoweredState + 7 changes to 1 when unpowered
; Offsets_Unit_PoweredState - really a byte or bit field flag address (SC is testing the bytes at this address against multiple values). So there may be other things which change it too!
; Offsets_Unit_PoweredState = 0 when powered 




; returns state which is really the queue size
; units can only be t or P town halls, no Z
; -2 cc/orbital flying
; -1 CC moring
; 0 No worker
; +Int workers/MSC
isWorkerInProduction(unit, type := "") 
{										
	if (type = "")
		type := getUnitType(unit)
	if (type = aUnitID["CommandCenterFlying"] || type = aUnitID["OrbitalCommandFlying"])
		state := -2
	Else if (type = aUnitID["CommandCenter"] && isCommandCenterMorphing(unit))
		state := -1
	Else getStructureProductionInfo(unit, type, aItems, state) ; state = queue size 1 means 1 worker is in production. Also counts MSC

	return state
}

; state =	0x0A = flying | 32 ->PF | 64 -> orbital
; state = 	0x76 idle
isCommandCenterMorphing(unit)
{
	state := ReadMemory(getUnitAbilityPointer(unit) + 0x9, GameIdentifier, 1)
	if (state = 32 )	;	->PF
		return aUnitID["PlanetaryFortress"]
	else if (state = 64)	; 	-> Orbital
		return aUnitID["OrbitalCommand"]
	return 0
}


isHatchLairOrSpireMorphing(unit, type := 0)
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
	local state
	if !type
		type := getUnitType(unit)
	state := ReadMemory(getUnitAbilityPointer(unit) + 0x8, GameIdentifier, 1)
	if (state = 9 && type = aUnitID["Hatchery"])	;	->PF
		return aUnitID["Lair"]
	else if (state = 17 && type = aUnitID["Lair"])	; 	-> Orbital
		return aUnitID["Hive"]
	else if (state = 4 && type = aUnitID["Spire"])
		return aUnitID["GreaterSpire"]
	return 0
}


isMotherShipCoreMorphing(unit)
{
	state := ReadMemory(getUnitAbilityPointer(unit) + 0x8, GameIdentifier, 1)
	return state = 8 
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

debugSCKeyState()
{
	return "B_iSpace: " ReadMemory(B_iSpace, GameIdentifier, 1)	
		 . "`nB_iNums: " ReadMemory(B_iNums, GameIdentifier, 2)	
		 . "`n" "B_iChars: " ReadMemory(B_iChars, GameIdentifier, 4)	
		 . "`n" "B_iTilda: " ReadMemory(B_iTilda, GameIdentifier, 1)	
		 . "`n" "B_iNonAlphNumChars: " ReadMemory(B_iNonAlphNumChars, GameIdentifier, 2)
		 . "`n" "B_iNonCharKeys: " ReadMemory(B_iNonCharKeys, GameIdentifier, 2)
		 . "`n" "B_iFkeys: " ReadMemory(B_iFkeys, GameIdentifier, 2)
		 . "`n" "B_iFkeys: " ReadMemory(B_iFkeys, GameIdentifier, 2)
		 . "`n" "B_iModifiers: " ReadMemory(B_iModifiers, GameIdentifier, 1)

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


; can check if producing by checking queue size via buildstats()
; *** note it's safer to check production info
; As if unit becomes contaminated, then this will return 0!!!!
; Probably the same for isGatewayConvertingToWarpGate() - havent checked.
; a warp gate which is already converting and then contaminated will still convert.
; I think perhaps this value gets bitwise-| with a contaminate value. CBF checking atm.
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

SetPlayerMinerals(amount := 99999, player := "")
{ 	global
	If (player = "")
		player := getLocalPlayerNumber()
	Return WriteMemory(aSCOffsets["playerAddress", player]  + Offsets_Player_Minerals, GameIdentifier, amount, "UInt")   	 
}
SetPlayerGas(amount := 99999, player := "")
{ 	global
	If (player = "")
		player := getLocalPlayerNumber()
	Return WriteMemory(aSCOffsets["playerAddress", player] + Offsets_Player_Gas, GameIdentifier, amount, "UInt")   
}

cHex(dec, useClipboard := True)
{
	return useClipboard ? clipboard := substr(dectohex(dec), 3) : substr(dectohex(dec), 3)
}



; this will return 1 or 2 units in production for use in unit panel
; hence this accounts for if a reactor is present
; it doesn't return the full list of units queued, just the one/two which are currently being produced
; byref totalQueueSize will return the total number of units queued up
getStructureProductionInfo(unit, type, byRef aInfo, byRef totalQueueSize := "", percent := True)
{
	STATIC aOffsets := []

	aInfo := [], totalQueueSize := 0
	if (!pAbilities := getUnitAbilityPointer(unit))
		return 0
	if !aOffsets.HasKey(type)
	{
		if (type = aUnitID.PlanetaryFortress)
			aOffsets[type] := 0x5C ;que5PassiveCancelToSelection - getCAbilQueueIndex will point to que5CancelToSelection which is for CC/orbital
		else 
		{
			CAbilQueueIndex := getCAbilQueueIndex(pAbilities, getAbilitiesCount(pAbilities)) ; CAbilQueueIndex
			if (CAbilQueueIndex != -1)
				aOffsets[type] := Offsets_UnitAbilities_AbilityPointerIndex + 4 * CAbilQueueIndex
			else 
				aOffsets[type] := -1
		}
	}
	if (aOffsets[type] = -1)
		return 0 ; refinery,reactor, depot, spine, extractor etc

	CAbilQueue := readmemory(pAbilities + aOffsets[type], GameIdentifier)
	, totalQueueSize := readmemory(CAbilQueue + Offsets_CAbilQueue_QueuedCount, GameIdentifier) ; this is the total real queue size e.g. max 5 on non-reactor, max 8 on reactored 
	, queuedArray := readmemory(CAbilQueue + Offsets_CAbilQueue_QueuedUnitsPointer, GameIdentifier)
	while (A_Index <= totalQueueSize && B_QueuedUnitInfo := readmemory(queuedArray + 4 * (A_index-1), GameIdentifier) )   ; A_index-1 = queue position ;progress = 0 not being built, but is in queue
	{
		if !aStringTable.hasKey(pString := readMemory(B_QueuedUnitInfo + Offsets_QueuedUnit_StringPointer, GameIdentifier))
			aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
		item := aStringTable[pString]
		; progress 0 if hasn't started so don't add it to the list
		if progress := percent ? getPercentageUnitCompleted(B_QueuedUnitInfo) : getTimeUntilUnitCompleted(B_QueuedUnitInfo)  ; 0.0 will be seen as false but doesnt really matter
			aInfo.insert({ "Item": item, "progress": progress})
		else break ; unit with highest complete percent is ALWAYS first in this queuedArray
	} 
	return round(aInfo.maxIndex())
}

; Not updated use getStructureProductionInfo() instead 
getZergProductionStringFromEgg(eggUnitIndex)
{
	p := readmemory(getUnitAbilityPointer(eggUnitIndex) + 0x1C, GameIdentifier)
	p := readmemory(p + 0x34, GameIdentifier) 		; cAbilQueueUse
	p := readmemory(p, GameIdentifier) 				; LarvaTrain  - this pointer structure will also have the production time/total
	p := readmemory(p + 0xf4, GameIdentifier) ; Offsets_QueuedUnit_StringPointer ??
	if !aStringTable.haskey(pString := readmemory(p, GameIdentifier) ) ; pString
		return aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
	return aStringTable[pString]
}

; Not updated use getStructureProductionInfo() instead 
getZergProductionFromEgg(eggUnitIndex)
{
	item := []
	, p := readmemory(getUnitAbilityPointer(eggUnitIndex) + 0x1C, GameIdentifier)
	, p := readmemory(p + 0x34, GameIdentifier) 		; cAbilQueueUse
	, p := readmemory(p, GameIdentifier) 				; LarvaTrain  - this pointer structure will also have the production time/total
	, totalTime := readmemory(p + 0x80, GameIdentifier) 	 ; pre p3.0 0x68
	, timeRemaining := readmemory(p + 0x84, GameIdentifier)  ; pre p3.0 0x6C
		
	p := readmemory(p + 0xf4, GameIdentifier) ; Offsets_QueuedUnit_StringPointer??
	if !aStringTable.haskey(pString := readmemory(p, GameIdentifier) ) ; pString
		aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
	item.Progress := round((totalTime - timeRemaining)/totalTime, 2) 
	, item.Type := aUnitID[(item.Item := aStringTable[pString])] 
	, item.Count := item.Type = aUnitID.Zergling ? 2 : 1
	return item
}

/*
	Queued Unit info (B_QueuedUnitInfo)
	+0x1c = pString Action e.g. barracks train
	+0xB0 = string Ability e.g. abil/BarracksTrain
	+0xC0 = string Ability e.g. abil/BarracksTrain
	+0xDO = pString Current item in production
	+0x108 = pString to unit ID e.g. barracks
*/


; byteArrayDump can be used to pass an already dumped byte array, saving reading it again
getAbilityIndex(abilityID, abilitiesCount, ByteArrayAddress := "", byRef byteArrayDump := "")
{
	if !byteArrayDump
		ReadRawMemory(ByteArrayAddress, GameIdentifier, byteArrayDump, abilitiesCount)
	loop % abilitiesCount
	{
		if (abilityID = numget(byteArrayDump, A_Index-1, "Char"))
			return A_Index - 1
	}
	return -1 ; as above can return 0
}

; the specific ability pointer for units of the same type doesn't change relative to the unit's specific pAbilties.
; This uses a slow string read to find the pointer offset the first time, then any subsequent calls for the same unit type are
; returned immediately from the static array

findAbilityTypePointer(pAbilities, unitType, abilityString)
{
	static aUnitAbilitiesOffsets := []

	if aUnitAbilitiesOffsets[unitType].hasKey(abilityString)
		return pAbilities + aUnitAbilitiesOffsets[unitType, abilityString]
	p1 := readmemory(pAbilities, GameIdentifier)
	loop
	{
		if (!p := ReadMemory(p1 + Offsets_UnitAbilities_AbilityStringPointerIndex + (A_Index - 1)*4, GameIdentifier))
			return 0
		if (abilityString = string := ReadMemory_Str(ReadMemory(p + 0x4, GameIdentifier), GameIdentifier))
			return pAbilities + (aUnitAbilitiesOffsets[unitType, abilityString] := Offsets_UnitAbilities_AbilityPointerIndex + (A_Index - 1)*4)	
	} until (A_Index > 100)
	return  0 ; something went wrong
}



/*	cAbilityRallyStruct
	Rally Stucture Size := 0x1C (0x20 If you include the rally count)
	+0x0 = rally count - (max 4)
	Following Repeats for each rally (data only gets changed when a new rally point >= current one is made)
	; eg 4 rally points, then set to rally on self structure, then none are changed 
	; rally count = 0 when self rallied
		+0x04 = unit Finger print (>> 18 to get unit index)
				**** This will be 0 If you don't currently have map vision of it e.g. a hatch which is under construction and doesnt yet provide vision to the rallied mineral patch
		+0x08 = Unit Model pointer
		+0xc = x1 
		+0x10 = y1
		+0x14 = z1
		+0x18 = something which changes depending on what is rallied to
		+0x1C = something which changes depending on what is rallied to
	
	Weirdly a lifted CC (or spawning floating CC in the map editor) still has the
	rally ability present (its rally count is zero though) even though it lacks this 
	ability in map/unit editor data

	For zerg town halls the above rally structure is used by normal units
	The hatchery mineral/gas rally structure begins at 
	cAbilityRallyStruct +0x74 - immediately at the end of the above rally structure
	i.e. 4 * 1C (4 * rally points) + 4 bytes for the rally count.

*/

; zergTownHallResourceRally - When true returns the rally structure for resources i.e. drones, instead of other units
getStructureRallyPoints(unitIndex, byRef aRallyPoints := "", zergTownHallResourceRally := False)
{
	static cAbilRally := 0x1a

	aRallyPoints := []
	, pAbilities := getUnitAbilityPointer(unitIndex)
	, abilitiesCount := getAbilitiesCount(pAbilities)	
	, ByteArrayAddress := ReadMemory(pAbilities, GameIdentifier) + Offsets_UnitAbilities_ParentByteArrayIndex  ; gets the address of a byte array which contains the ID list of the units abilities
	, cAbilRallyIndex := getAbilityIndex(cAbilRally, abilitiesCount, ByteArrayAddress) ;find the position/index of the rally ability in the ID list
	
	if (cAbilRallyIndex >= 0)
	{
		pCAbillityStruct := readmemory(pAbilities + Offsets_UnitAbilities_AbilityPointerIndex + 4 * cAbilRallyIndex, GameIdentifier)
		, bRallyStruct := readmemory(pCAbillityStruct + 0x44, GameIdentifier)
	
		ReadRawMemory(bRallyStruct + (zergTownHallResourceRally ? 0x74 : 0), GameIdentifier, rallyDump, 0x4 + 0x1C * 4) ; max rally count. Dump entire area - save a mem read
		if rallyCount := NumGet(rallyDump, 0, "Int")
		{	
			;ReadRawMemory(bRallyStruct, GameIdentifier, rallyDump, 0x14 + 0x1C * rallyCount)
			while (A_Index <= rallyCount)
			{
				aRallyPoints.insert({ "fingerPrint": fingerPrint := numget(rallyDump, (A_Index-1) * 0x1C + 0x04, "UInt")
									, "unitIndex": fingerPrint >> 18
									, "unitModelPointer": numget(rallyDump, (A_Index-1) * 0x1C + 0x08, "UInt")
									, "x": numget(rallyDump, (A_Index-1) * 0x1C + 0xC, "Int") / 4096
							  		, "y": numget(rallyDump, (A_Index-1) * 0x1C + 0x10, "Int") / 4096 })	
									; I think there is a z and targetFlag too
			}
		}
		return rallyCount ; self rallied = 0
	}
	return -1 ; not rallyable
}

getPercentageUnitCompleted(B_QueuedUnitInfo)
{	
	TotalTime := ReadMemory(B_QueuedUnitInfo + Offsets_QueuedUnit_BuildTimeTotal, GameIdentifier)
	RemainingTime := ReadMemory(B_QueuedUnitInfo + Offsets_QueuedUnit_BuildTimeRemaining, GameIdentifier)
	return round( (TotalTime - RemainingTime) / TotalTime, 2) ;return .47 (ie 47%)
}

; Production struct sc 2.0x
; TypeID = 0x44 (specific to the building type)
; StructureUnitIndex 0x5E (needs to be shifted)
; supply = 0x64
; TotalTime = 0x68
; RemainingTime  0x6C
; Minerals =  0x74
; Gas = 0x78

; Production struct sc 3.0.3x
; TypeID = 0x68 (specific to the building type)
; StructureUnitIndex 0x74 (needs to be shifted)
; supply = 0x7C
; TotalTime = 0x80
; RemainingTime  0x84
; Minerals =  0x8C
; Gas = 0x90



; returns seconds round to 2 decimal points
; returns 0/false if hasnt started
getTimeUntilUnitCompleted(B_QueuedUnitInfo)
{
	TotalTime := ReadMemory(B_QueuedUnitInfo + Offsets_QueuedUnit_BuildTimeTotal, GameIdentifier)
	RemainingTime := ReadMemory(B_QueuedUnitInfo + Offsets_QueuedUnit_BuildTimeRemaining, GameIdentifier)
	if (TotalTime = RemainingTime) ; hasn't started so don't add it to any lists
		return 0
	return round(RemainingTime / 65536, 2) ;return 6.47 
}


getAbilitiesCount(pAbilities)
{	GLOBAL GameIdentifier
	return ReadMemory(pAbilities + 0x17, GameIdentifier, 1) ; pre 3.03 0x16
}

getCAbilQueueIndex(pAbilities, AbilitiesCount)
{	GLOBAL GameIdentifier
	STATIC CAbilQueue := 0x19
	ByteArrayAddress := ReadMemory(pAbilities, GameIdentifier) + Offsets_UnitAbilities_ParentByteArrayIndex ; sc 2.x 0x3 
	ReadRawMemory(ByteArrayAddress, GameIdentifier, MemDump, AbilitiesCount)
	loop % AbilitiesCount
		if (CAbilQueue = numget(MemDump, A_Index-1, "UChar"))
			return A_Index-1
	 return -1 ;error
}

; this is just used for testing
getAbilListIndex(pAbilities, AbilitiesCount)
{	GLOBAL GameIdentifier
	STATIC CAbilQueue := 0x19
	abilties := []
	ByteArrayAddress := ReadMemory(pAbilities, GameIdentifier) + Offsets_UnitAbilities_ParentByteArrayIndex 
	ReadRawMemory(ByteArrayAddress, GameIdentifier, MemDump, AbilitiesCount)
	loop % AbilitiesCount
		abilties.insert(CAbilQueue := dectohex(numget(MemDump, A_Index-1, "UChar")))
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
	CharacterString := ReadMemory_Str(B_LocalCharacterNameID, GameIdentifier) 
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
; For complete safety, should read the units timer and compare against it's last value.

; note ctrl group base address really starts with ctrl group 0 - but the negative offset from ctrl group 1 works fine
numGetControlGroupObject(Byref oControlGroup, Group)
{	GLOBAL Offsets_Group_ControlGroup0, Offsets_Group_ControlGroupSize, GameIdentifier, 4, Offsets_Group_UnitOffset
	oControlGroup := []
	GroupSize := getControlGroupCount(Group)

	ReadRawMemory(Offsets_Group_ControlGroup0 + Offsets_Group_ControlGroupSize * group, GameIdentifier, MemDump, GroupSize * 4 + Offsets_Group_UnitOffset)
;	oControlGroup["Count"]	:= numget(MemDump, 0, "Short")
;	oControlGroup["Types"]	:= numget(MemDump, Offsets_Group_TypeCount, "Short") ;this will get whats actually in the memory
	oControlGroup["Count"]	:= oControlGroup["Types"] := 0
	oControlGroup.units := []
	loop % numget(MemDump, 0, "Short")
	{
		fingerPrint := numget(MemDump,(A_Index-1) * 4 + Offsets_Group_UnitOffset , "Int")
		unit := fingerPrint >> 18

		;if (!isUnitDead(unit) && isUnitLocallyOwned(unit))
		if getUnitFingerPrint(unit) = fingerPrint && isUnitLocallyOwned(unit) && !(getunittargetfilter(Unit) & aUnitTargetFilter.hidden)
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

; Function When reversed:
; the first unit (in aSelection.units) is the last unit in the selection panel (i.e. furtherest from the start)
; the last unit (aSelection.units) is the very first unit (top left) of the selection panel
; otherwise they appear in the same order as they do in the unit panel

; Sorting Rules: (in order of priority)
; 	higher priority come first
; 		lower unitID/SubgroupAlias comes first
;			(hallucinated units come immediately before non-hallucinated counterparts)
; 				lower unit Index comes first

; Units with different unitID/SubgroupAliases are tabable 

; hallucinated units come before their real counterparts. They can also be tabbed between
; hallucinated units are also selected with the select army hotkey (unless theyre probes)
; so easy/dirty fix is to give them a new subgroup alias slightly lower than their non-hallucinated brothers

; hallucinated units can be tabbed, but ^+ clicking them removes the real ones too, so don't try to click the real ones if the hallucinated ones have already been clicked
; Burrowed zerg units can be tabbed between and ^+ only removes the the clicked type (i.e. burrowed or normal, not both)

; A subgroup alias is really just a unitID/type i.e. the unit belongs in the tank group

; This method does not call bubbleSort2DArray. bubbleSort2DArray uses a bubble method of sorting
; Which is very slow, and becomes much much slower as the array size grows
; Not only that, but calling  bubbleSort2DArray three times is required to get the units in the 
; correct order. Hence this takes a very long time!
;
; This new method exploits AHKs internal sorting method for objects, so no manual sorting is required!
; If aSelection is to be reversed, then reverseArray() is called.
; reverseArray() is very basic and fast.

; Test Case: 238 units were selected in SC2
; numGetSelectionBubbleSort i.e. bubble sort took 86.56 ms
; numGetSelectionSorted took just 4.75 ms ~18X faster!
; 8/09/14 Added another loop to account for hallucinations properly
; the function now takes 5.53 ms - The previous version of the function took 5.34 ms. This was with 235 protoss units of all types and sc was running the background.


; Important Notes: ******************
; If hallucinations are present as well as real units of same type
; The tabsize[unitType] will = the real units size
; There will be no mention of the tab size for the hallucinations
; and tabPositions[unitType] will = the real unit types tab position 
; So be very careful when using this data in functions

numGetSelectionSorted(ByRef aSelection, ReverseOrder := False)
{
	global aLocalPlayer
	aSelection := []
	, selectionCount := getSelectionCount()
	, ReadRawMemory(Offsets_Selection_Base, GameIdentifier, MemDump, selectionCount * 4 + Offsets_Group_UnitOffset)
	, aSelection.Count := numget(MemDump, 0, "Short")
	, aSelection.Types := numget(MemDump, Offsets_Group_TypeCount, "Short")
	, aSelection.HighlightedGroup := numget(MemDump, Offsets_Group_HighlightedGroup, "Short")
	, aStorage := []
	loop % aSelection.Count
	{
		; Use a negative priority so AHKs normal object enumerates them in the correct 
		; unit panel order (backwards to how they would normally be enumerated)
		priority := -1 * getUnitSubGroupPriority(unitIndex := numget(MemDump,(A_Index-1) * 4 + Offsets_Group_UnitOffset , "Int") >> 18)
		, subGroupAlias := aUnitSubGroupAlias.hasKey(unitId := getUnitType(unitIndex)) ? aUnitSubGroupAlias[unitId] : unitId 
		, sIndices .= "," unitIndex
		, hallucinationOrder := !((filter := getUnitTargetFilter(unitIndex)) & aUnitTargetFilter.Hallucination) ; hallucinations come first so they get key 0 real units get key 1
		if aLocalPlayer["Slot"] != getUnitOwner(unitIndex)
			nonLocalUnitSelected := True
		else if !visibleUnit && !(filter & aUnitTargetFilter.Hidden)	; e.g. worker entering refinery does not change selection panel - but marines into a bunker or medivac does
			visibleUnit := True											; so I don't think i need to remove the hidden units from selection (as marines wont be in the selection buffer) but the workers will be

		if !isObject(aStorage[priority, subGroupAlias])
		  	aStorage[priority, subGroupAlias] := [], aStorage[priority, subGroupAlias, 0] := [], aStorage[priority, subGroupAlias, 1] := []
		; Note when looking in objtree() the order on the right is correct - the order in the tall left treeview panel is not
		aStorage[priority, subGroupAlias, hallucinationOrder].insert({"unitIndex": unitIndex, "unitId": unitId, "Filter": filter})
		
		; when aStorage is enumerated, units will be accessed in the same order
		; as they appear in the unit panel ie top left to bottom right 	
	}

	aSelection.IsGroupable := (aSelection.Count && !nonLocalUnitSelected && visibleUnit)
	; This will convert the data into a simple indexed object
	; The index value will be 1 more than the unit portrait location
	, aSelection.IndicesString := substr(sIndices, 2) ; trim first "," 
	, aSelection.units := []
	, aSelection.TabPositions := []
	, aSelection.TabSizes := []
	, TabPosition := unitPortrait := 0
	for priority, object in aStorage
	{
		for subGroupAlias, object in object 
		{
			for hallucinationOrder, object2 in object 
			{
				; Above we are explicitly creating a 0 and 1 object for the hallucination check/order.
				; So now we have to check if this has any keys - otherwise will get a blank key in the TabPositions and TabSizes fields
				; doing the check here will be slightly faster than doing the check above on every single unit (as here it's only doing it practically for each unit type)
				;hallucinated := !hallucinationOrder
				if object2.MaxIndex()
				{
					; I put the next couple of lines here so they don't get needlessly looped
					; inside the next for loop
					if (TabPosition = aSelection.HighlightedGroup)
						aSelection.HighlightedId :=  object2[1].unitId
					; Tab positions are stored with the unitId as key
					; so can just look up the tab location of unit type directly with no looping
					; cant use .insert(key, tabposition) as that adjusts higher keys (adds 1 to them)!
					aSelection.TabPositions[object2[1].unitId] := TabPosition
					, tabSize := 0
					for index, unit in object2 ; (unit is an object)
					{
						aSelection.units.insert({ "priority": -1*priority ; convert back to positive
												, "subGroupAlias": subGroupAlias
												, "unitIndex": unit.unitIndex
												, "unitId": unit.unitId
												, "TargetFilter": unit.Filter
												, "tabPosition": TabPosition
												, "unitPortrait": unitPortrait++}) ; will be 1 less than A_index when iterated
												; Note unitPortrait++ increments after assigning value to unitPortrait
						, tabSize++ ; how many units are in each tab - this is misleading when hallucinations are present! (this will equal the real units) as they are in there own tab
					}
					aSelection.TabSizes[object2[1].unitId] := tabSize								
					, TabPosition++	
				}
			}
		}
	}
	if ReverseOrder
	{
		aSelection.units := reverseArray(aSelection.units) ; Have to := as byRef wont work while inside another object
  		aSelection.IsReversed := True
  	}

  	return aSelection["Count"]	
}

updateSelectionRemove(aSelection, aRemovedPortraits)
{
	aRemovedIndexes := []
	for i, portrait in aRemovedPortraits
	{
		for index, unit in aSelection.units 
		{
			if unit.portrait = portrait
			{
				aSelection.units.remove(index)
				aSelection.TabSizes[unit.unitId]--
				break
			}
		}
	}
	aSelection.TabPositions := []

	if aSelection.TabSizes[aSelection.HighlightedId] <= 0
	{
		highlihgtedTab := 0 ; reset to first tab
	}

	for i, unit in aSelection.units 
	{
		stuff := stuff
	}

}

; SubgroupNext
; SubgroupPrev
tabToGroup(byRef currentGroup, TargetGroup)
{
	count := TargetGroup - currentGroup
	currentGroup := TargetGroup
	if count > 0
		return sRepeat(SC2Keys.key("SubgroupNext"), count)
	else if count < 0
		return sRepeat(SC2Keys.key("SubgroupPrev"), -1 * count)
	else return
}



; r := sRepeat("as", 3)
; r = "asasas"
; 0 returns empty string (same for negative numbers)
sRepeat(string, multiplier)
{
	loop, % multiplier 
		r .= string
	return r
}

/*
numGetSelectionSortedTest(ReverseOrder := False)
{
	global aLocalPlayer
	static dllFunction := "d:\My Computer\My Documents\Visual Studio 2010\Projects\fddgf\Debug\fddgf.dll"
	selectionCount := getSelectionCount()
	ReadRawMemory(Offsets_Selection_Base, GameIdentifier, MemDump, selectionCount * 4 + Offsets_Group_UnitOffset)
	if !func
		func := DllCall("GetProcAddress", Ptr, DllCall("LoadLibrary", Str, dllFunction, "Ptr"), AStr, "sortSelection", "Ptr")
	
	loop % selectionCount
	{
		priority := getUnitSubGroupPriority(unitIndex := numget(MemDump,(A_Index-1) * 4 + Offsets_Group_UnitOffset , "Int") >> 18)
		subGroupAlias := aUnitSubGroupAlias.hasKey(unitId := getUnitType(unitIndex)) ? aUnitSubGroupAlias[unitId] : unitId 
		hallucinationOrder := (getUnitTargetFilter(unitIndex) & aUnitTargetFilter.Hallucination) ; hallucinations come first so they get key 0 real units get key 1
		testString .= (A_Index != 1 ? "|" : "") priority "," subGroupAlias "," 	hallucinationOrder "," unitIndex				
		; when aStorage is enumerated, units will be accessed in the same order
		; as they appear in the unit panel ie top left to bottom right 	

	}
	id := stopwatch()
	DllCall(func, "astr", testString, "Cdecl Int")
	msgbox % stopwatch(id)
	return testString
}
*/


/*
This was just a test to compare the speed of using a machine code function vs the current numgetselectionSorted()
If it was significantly faster, I would re-write the c++ function so it was nicer to look at - an array of an array syntax or something.
However, as I suspected the actual MCode function is blazingly fast - ~0.004 ms, but all the additional numput/numget calls
result in it being slower than the current AHK function. For 235 units it was ~7.6 ms.
If I could have the function write these values directly back into the object, then it would be worth it. But wouldnt be easy.
Perhaps it would be possible to pass everything as a single delimited string to the function and then have
it return a delimited string of unit indexes in order, or better yet write it directly to a passed variable pointer. This would eliminate all numputs/numgets
numGetSelectionSortedMachineCodeTest(ByRef aSelection, byRef aStorage)
{
	global aLocalPlayer
	static mCodeF 
	if !mCodeF
		mCodeF := MCode("1,x86:558BEC83EC0C8B450C5633F6488945F474768B450853578BD6C1E2028D0CB504000000014D0C8D3C888D1C90897DFC8B3F895DF88B1B3BDF7F4675288B7C90048B5C88043BFB7C38751A8B7C900C8B4C880C3BF97F2A750C8B4C90108B550C3B0C907C1C8B55FC8B4DF86A045F8B1A8B318919893283C10483C2044F75EF33F6463B75F472915F5B33C0405EC9C3")
	aSelection := []
	, selectionCount := getSelectionCount()
	, ReadRawMemory(Offsets_Selection_Base, GameIdentifier, MemDump, selectionCount * 4 + Offsets_Group_UnitOffset)
	, aSelection.Count := numget(MemDump, 0, "Short")
	, aSelection.Types := numget(MemDump, Offsets_Group_TypeCount, "Short")
	, aSelection.HighlightedGroup := numget(MemDump, Offsets_Group_HighlightedGroup, "Short")
	, aStorage := []
	, aSelection.units := []
	VarSetCapacity(buffer, aSelection.Count * 16, 0)
	loop % aSelection.Count
	{
		priority := getUnitSubGroupPriority(unitIndex := numget(MemDump,(A_Index-1) * 4 + Offsets_Group_UnitOffset , "Int") >> 18)
		subGroupAlias := aUnitSubGroupAlias.hasKey(unitId := getUnitType(unitIndex)) ? aUnitSubGroupAlias[unitId] : unitId 
		sIndices .= "," unitIndex
		hallucination := ((filter := getUnitTargetFilter(unitIndex)) & aUnitTargetFilter.Hallucination) ; hallucinations come first so they get key 0 real units get key 1
		if aLocalPlayer["Slot"] != getUnitOwner(unitIndex)
			nonLocalUnitSelected := True										

		NumPut(priority, buffer,  (A_Index-1)*16, "Int")
		, NumPut(subGroupAlias, buffer,  (A_Index-1)*16 +4, "Int")
		, NumPut(hallucination, buffer,  (A_Index-1)*16 +8, "Int")
		, NumPut(unitIndex, buffer,  (A_Index-1)*16 +12, "Int")
	}
	DllCall(mCodeF, "Ptr", &buffer, "int", aSelection.Count, "cdecl int")
	loop, % aSelection.Count
		aStorage[A_Index] := NumGet(buffer, (A_Index-1)*16+12, "Int") ; retrieve the UnitIndex values
	return
}

int sort(int* buffer, unsigned int count)
{
	int size = 4;
	int swap; 
	for (int i = 0; i < count-1; i++)
	{
		int priorityA = i*size + 0;
		int unitIDA = i*size + 1;
		int hallucinationA = i*size + 2;
		int unitIndexA = i*size + 3;

		int priorityB = priorityA + size;
		int unitIDB = unitIDA + size;
		int hallucinationB = hallucinationA + size; 
		int unitIndexB = unitIndexA + size; 

		if (buffer[priorityA] > buffer[priorityB])
			continue;
		else if (buffer[priorityA] == buffer[priorityB])
		{
			if (buffer[unitIDA] < buffer[unitIDB])
				continue;
			else if (buffer[unitIDA] == buffer[unitIDB])
			{
				if (buffer[hallucinationA] > buffer[hallucinationB])
					continue;
				else if (buffer[hallucinationA] == buffer[hallucinationB])
				{
					if (buffer[unitIndexA] < buffer[unitIndexB])
						continue;
				}
			}
		}
		for (int j = 0; j < size; j++)
		{
			swap = buffer[priorityA+j];
			buffer[priorityA+j] = buffer[priorityB+j];
			buffer[priorityB+j] = swap;
		}
		i = 0;
	}
	return 1;
}

*/

isInSelection(unitIndex)
{
	selectionCount := getSelectionCount()
	ReadRawMemory(Offsets_Selection_Base, GameIdentifier, MemDump, selectionCount * 4 + Offsets_Group_UnitOffset)
	loop % selectionCount
	{
		if (unitIndex = numget(MemDump, (A_Index-1) * 4 + Offsets_Group_UnitOffset, "Int") >> 18)
			return 1
	}
	return 0
}

numGetUnitSelectionObject(ByRef aSelection)
{	GLOBAL Offsets_Group_TypeCount, Offsets_Group_HighlightedGroup, 4, Offsets_Group_UnitOffset, GameIdentifier, Offsets_Selection_Base
	aSelection := []
	, selectionCount := getSelectionCount()
	, ReadRawMemory(Offsets_Selection_Base, GameIdentifier, MemDump, selectionCount * 4 + Offsets_Group_UnitOffset)
	, aSelection["Count"] := numget(MemDump, 0, "Short")
	, aSelection["Types"] := numget(MemDump, Offsets_Group_TypeCount, "Short")
	, aSelection["HighlightedGroup"] := numget(MemDump, Offsets_Group_HighlightedGroup, "Short")
	, aSelection.units := []
	loop % aSelection["Count"]
		owner := getUnitOwner(unit := numget(MemDump,(A_Index-1) * 4 + Offsets_Group_UnitOffset , "Int") >> 18), Type := getUnitType(unit), aSelection.units.insert({"UnitIndex": unit, "Type": Type, "Owner": Owner})
	return aSelection["Count"]
}
; 0-5 indicates which unit page is currently selected (in game its 1-6)
; 0 is displayed when no unit is selected as well as 1 unit (i.e. when the page tabs are not visible)
getUnitSelectionPage()	
{	global 	
	return pointer(GameIdentifier, P_SelectionPage, O1_SelectionPage, O2_SelectionPage, O3_SelectionPage)
}
; Starts at 0 - like the SC selection page value
; Like SC max of 5 (0-5)
; Remember when only 1 or no unit is selected in SC no selection pages are visible.
; And this will return 0 just like getUnitSelectionPage()
getMaxPageValue(count := "")
{
	if (count = "")
		count := getSelectionCount()
	if (count <= 0)
		return 0
	return (i := Ceil(count / 24)) > 5 ? 5 : i - 1
}

numgetUnitTargetFilter(ByRef Memory, unit)
{
	return numget(Memory, Unit * Offsets_Unit_StructSize + Offsets_Unit_TargetFilter, "Int64")
}

getUnitTargetFilter(Unit) ;starts @ 0 i.e. first unit at 0
{
	return ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_TargetFilter, GameIdentifier, 8)
}

numgetUnitOwner(ByRef Memory, Unit)
{ global 
  return numget(Memory, Unit * Offsets_Unit_StructSize +  Offsets_Unit_Owner, "Char")  
}

numgetUnitModelPointer(ByRef Memory, Unit)
{  
  return (numget(Memory, Unit * Offsets_Unit_StructSize + Offsets_Unit_ModelPointer, "UInt")  << 5) & 0xFFFFFFFF
}

getUnitModelPointer(unit)
{  
  return (ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_ModelPointer, GameIdentifier) << 5) & 0xFFFFFFFF
}
getUnitModelPointerRaw(unit)
{  
  return ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_ModelPointer, GameIdentifier)
}
 getGroupedQueensWhichCanInject(ByRef aControlGroup,  CheckMoveState := 0)
 {	GLOBAL aUnitID, Offsets_Group_TypeCount, Offsets_Group_HighlightedGroup, Offsets_Group_ControlGroupSize, Offsets_Group_UnitOffset, GameIdentifier, Offsets_Group_ControlGroup0
 	, Offsets_Unit_StructSize, GameIdentifier, MI_Queen_Group, 4, aUnitMoveStates
	aControlGroup := []
	group := MI_Queen_Group
	groupCount := getControlGroupCount(Group)

	ReadRawMemory(Offsets_Group_ControlGroup0 + Offsets_Group_ControlGroupSize * Group, GameIdentifier, MemDump, groupCount * Offsets_Group_ControlGroupSize + Offsets_Group_UnitOffset)

	aControlGroup["UnitCount"]	:= numget(MemDump, 0, "Short")
	aControlGroup["Types"]	:= numget(MemDump, Offsets_Group_TypeCount, "Short")
;	aControlGroup["HighlightedGroup"]	:= numget(MemDump, Offsets_Group_HighlightedGroup, "Short")
	aControlGroup.Queens := []
	aControlGroup.AllQueens := []

	loop % groupCount
	{
		fingerPrint := numget(MemDump,(A_Index-1) * 4 + Offsets_Group_UnitOffset , "Int")
		unit := fingerPrint >> 18
		;if (isUnitDead(unit) || !isUnitLocallyOwned(Unit)) ; as this is being read from control group buffer so dead units can still be included!
		if getUnitFingerPrint(unit) != fingerPrint || !isUnitLocallyOwned(Unit) || getunittargetfilter(Unit) & aUnitTargetFilter.hidden ; the hight check in isnearhatch() would have prevented any issue as queen is only hidden when inside overlord - not when burrowed
			continue 
		
		if (aUnitID["Queen"] = type := getUnitType(unit)) 
		{
			; this is used to keep track of if some queens shouldnt inject 
			aControlGroup.AllQueens.insert({ "unit": unit})

			; I do this because my blocking of keys isnt 100% and if the user is pressing H e.g. hold posistion army or make hydras 
			; and so can accidentally put queen on hold position thereby stopping injects!!!
			; so queen is not moving/patrolling/a-moving ; also if user right clicks queen to catsh, that would put her on a never ending follow command
			; QueenBuild = make creepTumour (or on way to making it) - state = 0
			if (energy := getUnitEnergy(unit) >= 25)
			{
				if CheckMoveState
				{
					commandString := getUnitQueuedCommandString(unit)
					if !(InStr(commandString, "SpawnLarva") || InStr(commandString, "Patrol") || InStr(commandString, "Move") || InStr(commandString, "Attack")
					|| InStr(commandString, "QueenBuild") || InStr(commandString, "Transfusion"))
						aControlGroup.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aControlGroup.Queens[aControlGroup.Queens.MaxIndex(), "Type"] := Type
				}
				else aControlGroup.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aControlGroup.Queens[aControlGroup.Queens.MaxIndex(), "Type"] := Type
			}
		}

	} 																																					
	aControlGroup["QueenCount"] := round(aControlGroup.Queens.maxIndex()) ; as "SelectedUnitCount" will contain total selected queens + other units in group
	return 	aControlGroup.Queens.maxindex()
 }

	; CheckMoveState for forced injects
 getSelectedQueensWhichCanInject(ByRef aSelection, CheckMoveState := 0)
 {	GLOBAL aUnitID, Offsets_Group_TypeCount, Offsets_Group_HighlightedGroup, 4, Offsets_Group_UnitOffset, GameIdentifier, Offsets_Selection_Base
 	, Offsets_Unit_StructSize, GameIdentifier, aUnitMoveStates 
	aSelection := []
	selectionCount := getSelectionCount()
	ReadRawMemory(Offsets_Selection_Base, GameIdentifier, MemDump, selectionCount * 4 + Offsets_Group_UnitOffset)
	aSelection["SelectedUnitCount"]	:= numget(MemDump, 0, "Short")
	aSelection["Types"]	:= numget(MemDump, Offsets_Group_TypeCount, "Short")
	aSelection["HighlightedGroup"]	:= numget(MemDump, Offsets_Group_HighlightedGroup, "Short")
	aSelection.Queens := []

	loop % selectionCount
	{
		unit := numget(MemDump,(A_Index-1) * 4 + Offsets_Group_UnitOffset , "Int") >> 18
		type := getUnitType(unit)
		if (isUnitLocallyOwned(Unit) && aUnitID["Queen"] = type && ((energy := getUnitEnergy(unit)) >= 25)) 
		{
			if CheckMoveState
			{
				commandString := getUnitQueuedCommandString(unit)
				if !(InStr(commandString, "Patrol") || InStr(commandString, "Move") || InStr(commandString, "Attack")
				|| InStr(commandString, "QueenBuild") || InStr(commandString, "Transfusion"))		
					aSelection.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aSelection.Queens[aSelection.Queens.MaxIndex(), "Type"] := Type
			}
			else 
				aSelection.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aSelection.Queens[aSelection.Queens.MaxIndex(), "Type"] := Type
		}
	} 																								; also if user right clicks queen to catsh, that would put her on a never ending follow command
	aSelection["Count"] := round(aSelection.Queens.maxIndex())		; as "SelectedUnitCount" will contain total selected queens + other units in group
	return 	aSelection.Queens.maxindex()
 }

isQueenNearHatch(Queen, Hatch, MaxXYdistance) ; takes objects which must have keys of x, y and z
{
	x_dist := Abs(Queen.X - Hatch.X)
	y_dist := Abs(Queen.Y- Hatch.Y)																									
																								; there is a substantial difference in height even on 'flat ground' - using a max value of 1 should give decent results
	Return (x_dist > MaxXYdistance) || (y_dist > MaxXYdistance) || (Abs(Queen.Z - Hatch.Z) > 1) ? 0 : 1 ; 0 Not near
}

/*
isUnitNearUnit(Queen, Hatch, MaxXYdistance) ; takes objects which must have keys of x, y and z
{
	x_dist := Abs(Queen.X - Hatch.X)
	y_dist := Abs(Queen.Y- Hatch.Y)																											
												; there is a substantial difference in height even on 'flat ground' - using a max value of 1 should give decent results
	Return (x_dist > MaxXYdistance) || (y_dist > MaxXYdistance) || (Abs(Queen.Z - Hatch.Z) > 1) ? 0 : 1 ; 0 Not near
}
*/

; there is a substantial difference in height even on 'flat ground' - using a max value of 1 should give decent results
isUnitNearUnit(a, b, MaxXYdistance) ; takes objects which must have keys of x, y and z
{												
	return Abs(a.X - b.X) <= MaxXYdistance && Abs(a.Y- b.Y)	<= MaxXYdistance && Abs(a.Z - b.Z) <= 1
}

; returns true if within specified distance
distanceCheck(x1, y1, z1, x2, y2, z2, xMax, yMax, zMax)
{
	return Abs(x1 - x2) <= xMax && Abs(y1 - y2) <= yMax && Abs(z1 - z2) <= zMax
}

; Returns True if point is within maxDistance of a line (as formed by linePointA and linePointB).
; Note: This assumes that the line is infinitely long - so the function can still return true even if the point is far away from 
; the 'ends' i.e. linePointA/linePointB but still falls on the line.
; call isPointAlongLineSegmentWithZcheck() if need ensure point lies between the start and end of a line i.e. a line segment
; note isPointAlongLineSegmentWithZcheck() can still return true if the point lies past the end of the line but still within the specified maxDistance
isPointNearLine(linePointA, linePointB, point, maxDistance)
{
	return distanceFromLine(linePointA, linePointB, point) <= maxDistance
}

distanceFromLine(linePointA, linePointB, point)
{
	return (Abs( (linePointB.x - linePointA.x) * (linePointA.y - point.y) - (linePointA.x - point.x) * (linePointB.y - linePointA.y) ) 
		/ Sqrt( (linePointB.x - linePointA.x)**2 + (linePointB.y - linePointA.y)**2))  
}

; returns true if a point lies along the line formed by linePointA and linePointB
; Note: This creates a bounding rectangle using the diagonal line formed from (linePointA.x, linePointA.y) (one corner) and (linePointB.x, linePointB.y) 
; (the opposing corner) with a maxDistance buffer.
; Note this can still return true if the point lies past the end of the line segment but still within the specified maxDistance
isPointNearLineSegmentWithZcheck(linePointA, linePointB, point, maxDistance)
{
	if abs(((linePointA.z + linePointB.z) / 2) - point.z) <= 1 ; Do a z check. the avg. of pointA.z and pointB.z is used
	&& ((point.x >= linePointA.x - maxDistance && point.x <= linePointB.x + maxDistance) || (point.x <= linePointA.x + maxDistance && point.x >= linePointB.x - maxDistance)) ; create a bounding rectangle
	&& ((point.y >= linePointA.y - maxDistance && point.y <= linePointB.y + maxDistance) || (point.y <= linePointA.y + maxDistance && point.y >= linePointB.y - maxDistance)) ; and check point.x and point.y is contained within it.
		return isPointNearLine(linePointA, linePointB, point, maxDistance)
	return false
}

 objectGetUnitXYZAndEnergy(unit) ;this will dump just a unit
 {	Local UnitDump
	ReadRawMemory(B_uStructure + unit * Offsets_Unit_StructSize, GameIdentifier, UnitDump, Offsets_Unit_StructSize)
	Local x := numget(UnitDump, O_uX, "int")/4096, y := numget(UnitDump, O_uY, "int")/4096, Local z := numget(UnitDump, O_uZ, "int")/4096
	Local Energy := numget(UnitDump, Offsets_Unit_Energy, "int")/4096
	return { "unit": unit, "X": x, "Y": y, "Z": z, "Energy": energy}
 }

 numGetUnitPositionX(ByRef MemDump, Unit)
 {	global
 	return numget(MemDump, Unit * Offsets_Unit_StructSize + O_uX, "int")/4096
 }
 numGetUnitPositionY(ByRef MemDump, Unit)
 {	global
 	return numget(MemDump, Unit * Offsets_Unit_StructSize + O_uY, "int")/4096
 }
 numGetUnitPositionZ(ByRef MemDump, Unit)
 {	global
 	return numget(MemDump, Unit * Offsets_Unit_StructSize + O_uZ, "int")/4096
 }
 numGetIsHatchInjectedFromMemDump(ByRef MemDump, Unit)
 {	global ; 1 byte = 18h chrono for protoss structures, 48h when injected for zerg -  10h normal state
 	return 2 = numget(MemDump, Unit * Offsets_Unit_StructSize + Offsets_Unit_InjectState, "UChar")
 }

numGetUnitPositionXYZ(ByRef MemDump, Unit)
{	
	position := []
	, position.x := numGetUnitPositionX(MemDump, Unit)
	, position.y := numGetUnitPositionY(MemDump, Unit)
	, position.z := numGetUnitPositionZ(MemDump, Unit)
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
	bubbleSort2DArray(List, "Age", 0) ; 0 = descending
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

commonUnitObject(baseType := True)
{
	if baseType
	{
		return {"Terran": {SupplyDepotLowered: "SupplyDepot", WidowMineBurrowed: "WidowMine", CommandCenterFlying: "CommandCenter", OrbitalCommandFlying: "OrbitalCommand"
											, BarracksFlying: "Barracks", FactoryFlying: "Factory", StarportFlying: "Starport", SiegeTankSieged: "SiegeTank",  ThorHighImpactPayload: "Thor", VikingAssault: "VikingFighter"}
								, "Zerg": {DroneBurrowed: "Drone", ZerglingBurrowed: "Zergling", HydraliskBurrowed: "Hydralisk", UltraliskBurrowed: "Ultralisk", RoachBurrowed: "Roach"
								, InfestorBurrowed: "Infestor", BanelingBurrowed: "Baneling", QueenBurrowed: "Queen", SporeCrawlerUprooted: "SporeCrawler", SpineCrawlerUprooted: "SpineCrawler"}} 
	}
	else 
	{
		return	{"Terran": {SupplyDepot: "SupplyDepotLowered", WidowMine: "WidowMineBurrowed", CommandCenter: "CommandCenterFlying", OrbitalCommand: "OrbitalCommandFlying"
										, Barracks: "BarracksFlying", Factory: "FactoryFlying", Starport: "StarportFlying", SiegeTank: "SiegeTankSieged",  Thor: "ThorHighImpactPayload", VikingFighter: "VikingAssault"}
							, "Zerg": {Drone: "DroneBurrowed", Zergling: "ZerglingBurrowed", Hydralisk: "HydraliskBurrowed", Ultralisk: "UltraliskBurrowed", Roach: "RoachBurrowed"										
							, Infestor: "InfestorBurrowed", Baneling: "BanelingBurrowed", Queen: "QueenBurrowed", SporeCrawler: "SporeCrawlerUprooted", SpineCrawler: "SpineCrawlerUprooted"}}
	}
}

; weirdly in the mapeditor the techlabs each have their own subgroup aliases
; yet they all appear in the same subgroup i.e. TechLab

; to work out the required number of tabs, i.e. how many tab presses to arrive at
; a unit group: 1 tab for every time the subGroup changes in the array

getSubGroupAliasArray(byRef object)
{
	if !isObject(object)
		object := []
	 object := {aUnitID.VikingFighter: aUnitID.VikingAssault                
       		 , aUnitID.BarracksTechLab: aUnitID.TechLab ; All tech labs come under techlab
       		 , aUnitID.FactoryTechLab: aUnitID.TechLab 
       		 , aUnitID.StarportTechLab: aUnitID.TechLab
       		 , aUnitID.BarracksReactor: aUnitID.Reactor
       		 , aUnitID.FactoryReactor: aUnitID.Reactor
       		 , aUnitID.StarportReactor: aUnitID.Reactor
       		 , aUnitID.WidowMineBurrowed: aUnitID.WidowMine 
       		 , aUnitID.SiegeTankSieged: aUnitID.SiegeTank 
       		 , aUnitID.HellBat: aUnitID.Hellion 
       		 , aUnitID.ChangelingZealot: aUnitID.Changeling 
       		 , aUnitID.ChangelingMarineShield: aUnitID.Changeling 
       		 , aUnitID.ChangelingMarine: aUnitID.Changeling 
       		 , aUnitID.ChangelingZerglingWings: aUnitID.Changeling 
       		 , aUnitID.ChangelingZergling: aUnitID.Changeling}
	return       		 
}

getUnitSubGroupPriority(unit)	
{
	if !aUnitModel[pUnitModel := getUnitModelPointer(unit)]
    	getUnitModelInfo(pUnitModel)
  	return aUnitModel[pUnitModel].RealSubGroupPriority	
}


setupMiniMapUnitLists(byRef aMiniMapUnits)
{	local list, unitlist, ListType
	aUnitHighlights := []
	aMiniMapUnits.Highlight := []
	aMiniMapUnits.Exclude := []
	list := "UnitHighlightList1,UnitHighlightList2,UnitHighlightList3,UnitHighlightList4,UnitHighlightList5,UnitHighlightList6,UnitHighlightList7,UnitHighlightExcludeList"
	Loop, Parse, list, `,
	{	
		StringReplace, unitlist, %A_LoopField%, %A_Space%, , All ; Remove Spaces also creates var unitlist	
		StringReplace, unitlist, unitlist, %A_Tab%, , All
		unitlist := Trim(unitlist, ", |")	; , or `, both work - remove spaces, tabs and commas
		listNumber := A_Index ; If adding more custom highlights to the above list, ensure UnitHighlightExcludeList is last in the list!
		
		if (A_LoopField = "UnitHighlightExcludeList")
		{
			loop, parse, unitlist, `,
				aMiniMapUnits.Exclude[aUnitID[A_LoopField]] := True
		}
		else 
		{
			loop, parse, unitlist, `,
				aMiniMapUnits.Highlight[aUnitID[A_LoopField]] := "UnitHighlightList" listNumber "Colour"
		}
	}
	Return
}


;--------------------
;	Mini Map Setup
;--------------------
; The actual mapleft() functions will not return the true values from the map editor
; eg left is 2 when it should be 0


updateMinimapPosition()
{
	global minimap
	SetMiniMap(minimap)
}

/*
MacroTrainer Map border edge alignment vs scale
All scales as recorded at 1920x1080
1v1 
	Coda le  fine (1.79)
	Echo le - fine (1.87) * interesting - in SC map UI the top 'margin' is drawn, but the bottom isn't!
	Expedition lost - fine (1.87)
	Vaani reasearch station - fine (1.43)
	Cactus valley - fine (1.68)
	Inferno pools - fine (1.46)
	Iron fortress le - fine (1.68)
2v2
	Crystal pools - out -1 (1.34)
	Desert refuge - fine (1.37)
	Katherine square - Out +2 (1.46)
	Omicron - Out +1 (1.76)
	Preservation le - fine (1.24)
	Seething jungle - fine (1.58)
	Wolfe Industries - fine (1.51)
	Old country - fine (1.37)
*/



; *** note about minimap size and input
; the left and right locations reported by minimapLocation()/memory do not match where you can click on the minimap.
; left+1 and right-1 are the bounds for the clickable margins!

; Takes ~ 0.21 ms

SetMiniMap(byref minimap)
{	
	; minimap is a super global (though here it is a local)
	minimap := []

	;DPIScale := A_ScreenDPI/96 ; disabled until i can personally test on win7,8, & 8.1 using a high DPI monitor
	; *** DPI issue fixed - this DPI scale associated code is redundant and should be removed (except for VSLeft etc - which is used by getUnitScreenMinimapPos)
	DPIScale := 1
	winGetPos, Xsc, Ysc, Wsc, Hsc, %GameIdentifier%
	XscRaw := Xsc, YscRaw := Ysc, HscRaw := Hsc
	Xsc *= DPIScale, Ysc *= DPIScale, Wsc *= DPIScale, Hsc *= DPIScale
	if GameWindowStyle() = "Windowed"
		systemWindowEdgeSize(leftFrame, topFrame) ; Frame sizes are already scaled for DPI aware programs.
	else leftFrame := topFrame:= 0
	; The coodinates of the entire SC minimap border
	; relative to the SC client area (doesn't include the SC window frame if present)
	minimapLocation(left, right, bottom, top)
	
	; x, y screen coordinates of the full minimap UI Border relative to the SC client area NOT window
	; i.e. relative to the top left display area of the SC window which isn't a part of the outer window border or window frame 
	minimap.CALeft := left ;+ 1
	minimap.CARight := right ;- 1
	minimap.CABottom := bottom
	minimap.CATop := top
	minimap.CAWidth := right - left
	minimap.CAHeight := bottom - top	
	; x, y screen coordinates of the full minimap UI Border relative to the virtual screen (desktop area) 
	; Need to DPI scale the SC minimap border coordinates and the SC window position from winGetPos
	minimap.VSLeft := left*DPIScale + Xsc + leftFrame ;+ 1
	minimap.VSRight := right*DPIScale + Xsc + leftFrame ;- 1 ; - 1 Account for difference in SC stored value
	minimap.VSTop  := top*DPIScale + Ysc + topFrame ; When windowed the top SC border consists of a caption and frame
	minimap.VSBottom := bottom*DPIScale + Ysc + topFrame 
	minimap.VSWidth := minimap.VSRight - minimap.VSLeft
	minimap.VSHeight := minimap.VSBottom - minimap.VSTop

	; Using this new method is much better when a map side is much larger than the actual visual (playable) size
	; i.e. map bounds > camera bounds. 
	; Only the camerabounds +/- margin are actually displayed on the minimap and are playable.
	; Press 'o' to see these bounds in the map editor
	; Refers to actual playable map positions
	minimap.MapLeft := getMapPlayableLeft(), minimap.MapRight := getMapPlayableRight()
	minimap.MapTop := getMapPlayableTop(), minimap.MapBottom := getMapPlayableBottom()
	minimap.MapPlayableWidth := minimap.MapRight - minimap.MapLeft
	minimap.MapPlayableHeight := minimap.MapTop - minimap.MapBottom	
	
	if (minimap.MapPlayableWidth >= minimap.MapPlayableHeight)
	{
		minimap.CAScale := minimap.CAWidth / minimap.MapPlayableWidth
		minimap.VSScale := round(minimap.CAScale * DPIScale, 2) ; Account for DPI
		minimap.CAScale := round(minimap.CAScale, 2)
		Xoffset := 0
		if minimap.MapPlayableWidth = minimap.MapPlayableHeight
			Yoffset := 0
		else Yoffset := ceil(abs((minimap.CAHeight - minimap.CAScale * minimap.MapPlayableHeight) / 2)) ; ceil is needed on seething jungle, otherwise get negative offset ;was round previously. 
	}
	else if (minimap.MapPlayableWidth < minimap.MapPlayableHeight)
	{
		minimap.CAScale := minimap.CAHeight / minimap.MapPlayableHeight
		minimap.VSScale := round(minimap.CAScale* DPIScale, 2) ; needs to be min. 2
		minimap.CAScale := round(minimap.CAScale, 2) ; needs to be min. 2
		Yoffset := 0, Xoffset := floor(Abs((minimap.CAWidth - minimap.CAScale * minimap.MapPlayableWidth) / 2)) 
	}
	;minimap.DrawingXoffset := Xoffset ; just for debugging
	;minimap.DrawingYoffset := Yoffset	
	minimap.mapName := getMapName()
	if minimap.mapName = "Omicron" 	|| minimap.mapName = "Backcountry" 		
		Yoffset += floor(1 * minimap.VSWidth/262)
	else if (minimap.mapName = "Katherine Square" || minimap.mapName = "Dust Bowl")
		Yoffset += floor(2 * minimap.VSWidth/262) 		; 262 = map width at 1920x1080, so offset values scale to other resolutions
	else if minimap.mapName = "Crystal Pools"			; seems fine with full screen resolutions, but not true windowed modes 
		Xoffset -= floor(1 * minimap.VSHeight/258)

	; Perhaps adding to inaccuracy my multiplying rounded values...
	minimap.CAPlayableWidth := minimap.CAWidth - 2*Xoffset 
	minimap.CAPlayableHeight := minimap.CAHeight - 2*Yoffset 

	minimap.VSPlayableWidth := minimap.VSWidth - 2*Xoffset * DPIScale
	minimap.VSPlayableHeight := minimap.VSHeight - 2*Yoffset * DPIScale			
	
	; Delta of the minimap UI border edge and the displayed/sized map
	; To be used with drawing the minimap
	; The minimap must be positioned at the top left of the FULL SC minimap as this is 0 based
	minimap.DrawingHorizontalOffset := Xoffset * DPIScale	
	minimap.DrawingVerticalOffset := Yoffset * DPIScale

	; playable minimap position relative to the SC client area (doesn't include the window frame/border)
	; Used for input calculations that are destined for the input class (postmessage)
	minimap.clientInputBottom := minimap.CABottom - Yoffset
	minimap.clientInputTop := minimap.CATop + Yoffset
	minimap.clientInputLeft := minimap.CALeft + Xoffset


	minimap.UnitMinimumRadius := 1 / minimap.VSScale
	minimap.UnitMaximumRadius := 10
	minimap.AddToRadius := 1 / minimap.VSScale	
	Return
}

getMapName()
{
	MapFileInfo := readmemory(B_MapInfo + O_FileInfoPointer, GameIdentifier)
	return ReadMemory_Str(MapFileInfo + 0x2A0, GameIdentifier)
}

; Use these functions to get co-ordinates for clicking
; Not for drawing on the minimap
getUnitMinimapPos(Unit, ByRef  x, ByRef y) ; Note redounded as mouse clicks dont round decimals e.g. 10.9 = 10
{
	mapToMinimapPos(x := getUnitPositionX(Unit), y := getUnitPositionY(Unit))
	, x := round(x), y := round(y)
}
; x, y should be rounded for mouse clicks and for drawing.
; Although the unit drawing function already floors, so it's not really necessary for that.
mapToMinimapPos(ByRef  X, ByRef  Y) 
{
	global minimap
	X -= minimap.MapLeft, Y -= minimap.MapBottom ; correct units position as mapleft/start of map can be >0
	, X := round(minimap.clientInputLeft + (X/minimap.MapPlayableWidth * minimap.CAPlayableWidth))
	, Y := round(minimap.clientInputBottom - (Y/minimap.MapPlayableHeight * minimap.CAPlayableHeight))		
	return	
}

; Use these two functions to draw items on the minimap
getUnitRelativeMinimapPos(Unit, ByRef  x, ByRef y) ; Note raounded as mouse clicks dont round decimals e.g. 10.9 = 10
{
	mapToRelativeMinimapPos(x := getUnitPositionX(Unit), y := getUnitPositionY(Unit))
	, x := round(x), y := round(y)
}

mapToRelativeMinimapPos(ByRef  X, ByRef  Y) 
{
	global minimap
	X -= minimap.MapLeft, Y -= minimap.MapBottom ; correct units position as mapleft/start of map can be >0
	, X := round(minimap["DrawingHorizontalOffset"] + (X/minimap.MapPlayableWidth * minimap.VSPlayableWidth))
	, Y := round(minimap["DrawingVerticalOffset"] + (1-(Y/minimap.MapPlayableHeight)) * minimap.VSPlayableHeight)		
	return	
}
; For AHK click commands. **Coordmode = screen
; Couldn't seem to get it to work with client or window
getUnitScreenMinimapPos(Unit, ByRef  x, ByRef y) ; Note redounded as mouse clicks dont round decimals e.g. 10.9 = 10
{
	mapToRelativeMinimapPos(x := getUnitPositionX(Unit), y := getUnitPositionY(Unit))
	, x := round(x)+minimap.VSLeft, y := round(y) + minimap.VSTop
}



initialiseBrushColours(aHexColours, byRef a_pBrushes)
{
	Global UnitHighlightHallucinationsColour, UnitHighlightInvisibleColour
		, UnitHighlightList1Colour, UnitHighlightList2Colour, UnitHighlightList3Colour
		, UnitHighlightList4Colour, UnitHighlightList5Colour, UnitHighlightList6Colour
		, UnitHighlightList7Colour
		, TransparentBackgroundColour

	; Userhighlight brushes colours can change

	deleteBrushArray(a_pBrushes)
	a_pBrushes := []
	for colour, hexValue in aHexColours
		a_pBrushes[colour] := Gdip_BrushCreateSolid(0xFF hexValue)
	; Used in the unit overlay	
	a_pBrushes["TransparentBlack"] := Gdip_BrushCreateSolid(0x78000000)
	a_pBrushes["transBackground"] := Gdip_BrushCreateSolid(TransparentBackgroundColour)
	a_pBrushes["transBlueHighlight"] := Gdip_BrushCreateSolid(0x480066FF)
	a_pBrushes["ScanChrono"] := Gdip_BrushCreateSolid(0xCCFF00B3)
	a_pBrushes["redStrikeOut"] := Gdip_BrushCreateSolid(0xFFB4141E)
	a_pBrushes["UnitHighlightHallucinationsColour"] := Gdip_BrushCreateSolid(UnitHighlightHallucinationsColour)
	a_pBrushes["UnitHighlightInvisibleColour"] := Gdip_BrushCreateSolid(UnitHighlightInvisibleColour)
	a_pBrushes["UnitHighlightList1Colour"] := Gdip_BrushCreateSolid(UnitHighlightList1Colour)
	a_pBrushes["UnitHighlightList2Colour"] := Gdip_BrushCreateSolid(UnitHighlightList2Colour)
	a_pBrushes["UnitHighlightList3Colour"] := Gdip_BrushCreateSolid(UnitHighlightList3Colour)
	a_pBrushes["UnitHighlightList4Colour"] := Gdip_BrushCreateSolid(UnitHighlightList4Colour)
	a_pBrushes["UnitHighlightList5Colour"] := Gdip_BrushCreateSolid(UnitHighlightList5Colour)
	a_pBrushes["UnitHighlightList6Colour"] := Gdip_BrushCreateSolid(UnitHighlightList6Colour)
	a_pBrushes["UnitHighlightList7Colour"] := Gdip_BrushCreateSolid(UnitHighlightList7Colour)

	return 
}

deleteBrushArray(byRef a_pBrushes)
{
	for colour, pBrush in a_pBrushes
		Gdip_DeleteBrush(pBrush)
	a_pBrushes := []
	return
}

; 11/02/14 
; Just realised i don't think i delete any pens
; but I think? they are all static static anyway so it doesnt really matter.
; There a couple of static pens in functions which won't be deleted - but a couple of dangling pointers
; doesn't mean anything, as they will of course be freed when the program exits.

initialisePenColours(aHexColours)
{
	a_pPens := []
	for colour, hexValue in aHexColours
		a_pPens[colour] := Gdip_CreatePen(0xFF hexValue, 1)
	a_pPens["redStrikeOut2"] := Gdip_CreatePen(0xFFB4141E, 2)
	a_pPens["redStrikeOut3"] := Gdip_CreatePen(0xFFB4141E, 3)
	return a_pPens
}

deletePens(byRef a_pPens)
{
	for i, pPen in a_pPens
		Gdip_DeletePen(pPen)
	a_pPens := []
	return 
}

; When calling Gdip_DrawRectangle or FillUnitRectangle do not pass decimal values as params.
; e.g. .5 x,y causes one pixel to be missed in border edge where they meet
; and width/height >= x.6 (decminal .6 not .5!) causes that side to be one pixel bigger
; Using //1 as it is 3X faster than floor()
; The x, y pos are are the centre of the rectangle, so need to halve and subtract to get top left corner
; The x and y position need to be -1 and the w and h need to be + 1
; so as to allow the rectangle to be filled correctly without overlap
; Note width is used to calculate x,y pos - so cant +1 w/h until after they are calculated!
; Not sure if I should use floor or round. 
; Note must use parenthesis and use //1 last so the operations occur in the same order for both draw and fill and any floating point impression occurs equally for both before the floor divide.
; other wise if for example width has a value like 1.999999999999998 (width//1+enlarge) will result in 2  one function and 3 in the other and the their will be gaps/
; Can see it on the commune map =



drawUnitRectangle(G, x, y, radius, colour := "black")
{ 	
	global minimap, static enlarge := 1
	; The w,h + enlarge in function call increase size so as to help hide inaccuracy
	width := height := radius * 2 * minimap.VSScale 
	, Gdip_DrawRectangle(G, a_pPens[colour], (x - 1 - width / 2)//1, (y - 1 - height /2)//1, (width + 1 + enlarge)//1, (height + 1+enlarge)//1)
}

FillUnitRectangle(G, x, y, radius, colour)
{ 	global minimap, static enlarge := 1
	; The w,h + enlarge in function call increase size so as to help hide inaccuracy
	width := height := radius * 2 * minimap.VSScale 
	, Gdip_FillRectangle(G, a_pBrushes[colour], (x - width / 2)//1, (y - height /2)//1, (width+enlarge)//1, (height+enlarge)//1)
}

/*
drawUnitRectangleTest(x, y, radius)
{ 	
	global minimap, static enlarge := 1
	; The w,h + enlarge in function call increase size so as to help hide inaccuracy
	msgbox % radius
	width := radius * 2 * minimap.scale 
	, height := radius * 2 * minimap.scale 
	x := (x - 1 - width / 2)//1
	y := (y - 1 - height /2)//1
	width := (width + 1)//1+enlarge
	height := (height + 1)//1+enlarge
	msgbox % clipboard := x ", " y "`n" width ", " height
}

FillUnitRectangleTest(x, y, radius)
{ 	global minimap, static enlarge := 1
	; The w,h + enlarge in function call increase size so as to help hide inaccuracy
	width := radius * 2 * minimap.scale 
	, height := radius * 2 * minimap.scale
	x:= (x - width / 2)//1
	y := (y - height /2)//1
	width := width//1+enlarge
	height := height//1+enlarge
	msgbox % clipboard := x ", " y "`n" width ", " height
}
*/

isUnitLocallyOwned(Unit) ; 1 its local player owned
{	global aLocalPlayer
	Return (aLocalPlayer["Slot"] = getUnitOwner(Unit))
}
isOwnerLocal(Owner) ; 1 its local player owned
{	global aLocalPlayer
	Return (aLocalPlayer["Slot"] = Owner)
}

GetEnemyRaces()
{	global aPlayer, aLocalPlayer
	For i, player in aPlayer
	{	
		If ( aLocalPlayer["Team"] <>  player["Team"] )
		{
			If (EnemyRaces <> "")
				EnemyRaces .= ", "
			EnemyRaces .= player["Race"]
		}
	}
	return EnemyRaces 
}

GetGameType(aPlayer)
{	
	For slot_number in aPlayer
	{	team := aPlayer[slot_number, "Team"]
		TeamsList .= Team "|"
		Player_i ++
	}
	Sort, TeamsList, D| N U
	TeamsList := SubStr(TeamsList, 1, -1)
	Loop, Parse, TeamsList, |
		Team_i := A_Index
	If (Team_i > 2)
		Return "FFA" 
	Else	 ;sets game_type to 1v1,2v2,3v3,4v4 ;this helps with empty player slots in custom games - round up to the next game type
		Return Ceil(Player_i/Team_i) "v" Ceil(Player_i/Team_i)
}

GetEnemyTeamSize()
{	global aPlayer, aLocalPlayer
	For slot_number in aPlayer
		If aLocalPlayer["Team"] <> aPlayer[slot_number, "Team"]
			EnemyTeam_i ++
	Return EnemyTeam_i
}

GetEBases()
{	global aPlayer, aLocalPlayer, aUnitID
	EnemyBase_i := GetEnemyTeamSize()
	Unitcount := DumpUnitMemory(MemDump)
	while (A_Index <= Unitcount)
	{
		unit := A_Index - 1
		TargetFilter := numgetUnitTargetFilter(MemDump, unit)
		if (TargetFilter & aUnitTargetFilter.Dead)
	    	Continue	
	    pUnitModel := numgetUnitModelPointer(MemDump, Unit)
	   	Type := numgetUnitModelType(pUnitModel)
	   	owner := numgetUnitOwner(MemDump, Unit) 
		IF (( type = aUnitID["Nexus"] ) OR ( type = aUnitID["CommandCenter"] ) OR ( type = aUnitID["Hatchery"] )) AND (aPlayer[Owner, "Team"] <> aLocalPlayer["Team"])
		{
			Found_i ++
			list .=  unit "|"
		}
	}
	Return SubStr(list, 1, -1)	; remove last "|"	
}

DumpUnitMemory(BYREF MemDump)
{   
	Offsets_Unit_UnitsPerBlock := 0xF + 1

	unitCount := getHighestUnitIndex()
	, VarSetCapacity(MemDump, unitCount * Offsets_Unit_StructSize)
	, unitBlockSize := Offsets_Unit_StructSize * Offsets_Unit_UnitsPerBlock
	
	loop, % loopCount := ceil(unitCount / Offsets_Unit_UnitsPerBlock)
	{
		if (A_Index = loopCount)
			unitBlockSize := Mod(unitCount, Offsets_Unit_UnitsPerBlock) * Offsets_Unit_StructSize
		
		UnitAtStartOfBlock := (A_Index-1) * Offsets_Unit_UnitsPerBlock
		, localBufferOffset := UnitAtStartOfBlock * Offsets_Unit_StructSize
		, ReadRawMemory(getUnitAddress(UnitAtStartOfBlock), GameIdentifier, MemDump, unitBlockSize, localBufferOffset)
	}
  	return unitCount
}
; 0 - 15
; 

class cUnitModelInfo
{
   __New(pUnitModel) 
   {  global GameIdentifier, Offsets_UnitModel_ID, Offsets_UnitModel_MinimapRadius, Offsets_UnitModel_SubgroupPriority
      ReadRawMemory(pUnitModel & 0xFFFFFFFF, GameIdentifier, uModelData, Offsets_UnitModel_MinimapRadius+4) ; Offsets_UnitModel_MinimapRadius - 0x39C + 4 (int) is the highest offset i get from the unitmodel
      this.Type := numget(uModelData, Offsets_UnitModel_ID, "Short") 
      this.MiniMapRadius := numget(uModelData, Offsets_UnitModel_MinimapRadius, "int")/4096
      this.RealSubGroupPriority := numget(uModelData, Offsets_UnitModel_SubgroupPriority, "Short")
   }
}

numgetUnitModelType(pUnitModel)
{  global aUnitModel
   if !aUnitModel[pUnitModel]
      getUnitModelInfo(pUnitModel)
   return aUnitModel[pUnitModel].Type
}
numgetUnitModelMiniMapRadius(pUnitModel)
{  global aUnitModel
   if !aUnitModel[pUnitModel]
      getUnitModelInfo(pUnitModel)
   return aUnitModel[pUnitModel].MiniMapRadius
}
numgetUnitModelPriority(pUnitModel)
{  global aUnitModel
   if !aUnitModel[pUnitModel]
      getUnitModelInfo(pUnitModel)
   return aUnitModel[pUnitModel].RealSubGroupPriority
}

getUnitModelInfo(pUnitModel)
{  global aUnitModel
   aUnitModel[pUnitModel] := new cUnitModelInfo(pUnitModel)
   return
}

isUnitDead(unit)
{ 	global 
	return	getUnitTargetFilter(unit) & aUnitTargetFilter.Dead
}


; 	provides two simple arrays
;	aUnitID takes the unit name e.g. "Stalker" and return the unit ID
; 	aUnitName takes the unit ID and Returns the unit name

SetupUnitIDArray(byref aUnitID, byref aUnitName)
{
	#include %A_ScriptDir%\Included Files\l_UnitTypes.AHK
	aUnitID := []
	aUnitName := []
	loop, parse, l_UnitTypes, `,
	{
		StringSplit, Item , A_LoopField, = 		; Format "Colossus = 38"
		name := trim(Item1, " `t `n"), UnitID := trim(Item2, " `t `n")
		aUnitID[name] := UnitID
		aUnitName[UnitID] := name
	}
	Return
}

setupTargetFilters(byref Array)
{
	#include %A_ScriptDir%\Included Files\aUnitTargetFilter.AHK
	Array := aUnitTargetFilter
	return
}

SetupColourArrays(ByRef HexColour, Byref MatrixColour)
{ 	
	If IsByRef(HexColour)
		HexColour := [] 
	If IsByRef(MatrixColour)	
		MatrixColour := []
	HexCoulourList := "White=FFFFFF|Red=B4141E|Blue=0042FF|Teal=1CA7EA|Purple=540081|Yellow=EBE129|Orange=FE8A0E|Green=168000|Light Pink=CCA6FC|Violet=1F01C9|Light Grey=525494|Dark Green=106246|Brown=4E2A04|Light Green=96FF91|Dark Grey=232323|Pink=E55BB0|Black=000000"
	loop, parse, HexCoulourList, |  
	{
		StringSplit, Item , A_LoopField, = ;Format "White = FFFFFF"
		If IsByRef(HexColour)
			HexColour[Item1] := Item2 ; White, FFFFFF - hextriplet R G B
		If IsByRef(MatrixColour)
		{
			colour := Item2
			colourRed := "0x" substr(colour, 1, 2) 
			colourGreen := "0x" substr(colour, 3, 2)
			colourBlue := "0x" substr(colour, 5, 2)	
			colourRed := Round(colourRed/0xFF,2)
			colourGreen := Round(colourGreen/0xFF,2)
			colourBlue := Round(colourBlue/0xFF,2)		
			Matrix =
		(
0		|0		|0		|0		|0
0		|0		|0		|0		|0
0		|0		|0		|0		|0
0		|0		|0		|1		|0
%colourRed%	|%colourGreen%	|%colourBlue%	|0		|1
		)
			MatrixColour[Item1] := Matrix
		}
	}
	Return
}

; These bitmaps take up a bit more than 1 MB of space (check mem usage before and after deleting)
CreatepBitmaps(byref a_pBitmap, aUnitID, MatrixColour := "")
{
	a_pBitmap := []
	l_Races := "Terran,Protoss,Zerg"
	loop, parse, l_Races, `,
	{
		loop, 2
		{
			Background := A_index - 1
			a_pBitmap[A_loopfield,"Mineral",Background] := Gdip_CreateBitmapFromFile(A_Temp "\Mineral_" Background A_loopfield ".png")
			a_pBitmap[A_loopfield,"Gas",Background] := Gdip_CreateBitmapFromFile(A_Temp "\Gas_" Background A_loopfield ".png")			
			a_pBitmap[A_loopfield,"Supply",Background] := Gdip_CreateBitmapFromFile(A_Temp "\Supply_" Background A_loopfield ".png")
		}
		a_pBitmap[A_loopfield,"Worker"] := Gdip_CreateBitmapFromFile(A_Temp "\Worker_0" A_loopfield ".png")
		a_pBitmap[A_loopfield,"Army"] := Gdip_CreateBitmapFromFile(A_Temp "\Army_" A_loopfield ".png")
		a_pBitmap[A_loopfield,"RacePretty"] := Gdip_CreateBitmapFromFile(A_Temp "\" A_loopfield "90.png")
		a_pBitmap[A_loopfield,"RaceFlat"]  := Gdip_CreateBitmapFromFile(A_Temp "\Race_" A_loopfield "Flat.png")

		Width := Gdip_GetImageWidth(a_pBitmap[A_loopfield,"RaceFlat"]), Height := Gdip_GetImageHeight(a_pBitmap[A_loopfield,"RaceFlat"])
		; Using a matrix in the overlays via drawImage() to change the colour is slower (adds a couple of ms for 6 race icons). So create a bitmap with the colour already changed.
		for colour, matrix in MatrixColour
		{
			a_pBitmap[A_loopfield, "RaceFlatColour", colour] := Gdip_CreateBitmap(Width, Height)
			G2 := Gdip_GraphicsFromImage(a_pBitmap[A_loopfield, "RaceFlatColour", colour])
			; These two shouldn't be required as not drawing shapes or altering size (but leave them just incase)
			Gdip_SetSmoothingMode(G2, 4)
			Gdip_SetInterpolationMode(G2, 7)	
			Gdip_DrawImage(G2, a_pBitmap[A_loopfield,"RaceFlat"], "", "", "", "", "", "", "", "", matrix)
			Gdip_DeleteGraphics(G2)
		}
	}
	Loop, %A_Temp%\UnitPanelMacroTrainer\*.png
	{
		StringReplace, FileTitle, A_LoopFileName, .%A_LoopFileExt% ;remove the .ext
		if aUnitID[FileTitle]	;have a 2 pics which arnt in the unit array - bunkerfortified & thorsiegemode
			a_pBitmap[aUnitID[FileTitle]] := Gdip_CreateBitmapFromFile(A_LoopFileFullPath)
		else  ; these are upgrades and accessed by SC2 item name string
			a_pBitmap[FileTitle] := Gdip_CreateBitmapFromFile(A_LoopFileFullPath)
	}

	a_pBitmap["GreenTick"] := Gdip_CreateBitmapFromFile(A_Temp "\MacroTrainerFiles\OverlaysMisc\greenTick.png")
	a_pBitmap["GreenPause"] := Gdip_CreateBitmapFromFile(A_Temp "\MacroTrainerFiles\OverlaysMisc\GreenPause.png")
	a_pBitmap["RedClose72"] := Gdip_CreateBitmapFromFile(A_Temp "\MacroTrainerFiles\OverlaysMisc\redClose72.png")
	a_pBitmap["PurpleX16"] := Gdip_CreateBitmapFromFile(A_Temp "\PurpleX16.png")
	a_pBitmap["GreenX16"] := Gdip_CreateBitmapFromFile(A_Temp "\GreenX16.png")
	a_pBitmap["RedX16"] := Gdip_CreateBitmapFromFile(A_Temp "\RedX16.png")
}

deletepBitMaps(byRef a_pBitmap)
{
	for i, v in a_pBitmap
	{
		if IsObject(v)
			deletepBitMaps(a_pBitmap[i]) ; passing reference to original object, so I could check if it was clearing every item
		else 
		{
			Gdip_DisposeImage(v)
		;	a_pBitmap[i] := Gdip_DisposeImage(v) ; Return value 0 indicates success - was used to check it was doing it for every item
		}
	}
	a_pBitmap := []
	return
}


; player0 = neutral 
; player1-14 = players/refs/specs/none/computer
; player15 = hostile
; There are really 16 player slots. 

;----------------------
;	player_team_sorter
;-----------------------
getPlayers(byref aPlayer, byref aLocalPlayer, byref aEnemyAndLocalPlayer := "")
{
	aPlayer := [], aLocalPlayer := [], aEnemyAndLocalPlayer := []
	; doing it this way allows for custom games with blank slots 
	; can get weird things if 16 (but filtering them for nonplayers)
	Loop, 16	
	{
		slot := A_Index - 1
		if getPlayerName(slot) = "" ;empty slot custom games?
		|| IsInList(getPlayerType(slot), "None", "Neutral", "Hostile", "Referee", "Spectator")
			Continue
		aPlayer.insert(slot, new c_Player(slot) )  ; insert at player index so can call using player slot number as the key (slot number = key) 
		If (slot = getLocalPlayerNumber())
			aLocalPlayer := new c_Player(slot)
	}
	for slotNumber, player in aPlayer
	{
		if player.Team != aLocalPlayer.Team 
			aEnemyAndLocalPlayer.insert(player)
	}
	; so local player is last in this object so when iterating for overlays local player shows up last
	; **********
	; but cant use the key as the slot number for this object!!!
	; *********
	aEnemyAndLocalPlayer.Insert(aLocalPlayer) 
	return	
}
; works for arrays too!
IsInList(Var, items*)
{
	for key, item in items
	{
		If (var = item)
			Return 1
	}
	return 0
}

class c_Player
{
	__New(i) 
	{	
		this.Slot := i
		this.Type := getPlayerType(i)
		this.Name := getPlayerName(i)
		this.Team := getPlayerTeam(i)
		this.Race := getPlayerRace(i)
		this.Colour := getPlayerColour(i)
	}
} 

Class c_EnemyUnit
{
	__New(unit) 
	{	
		this.Radius := getMiniMapRadius(Unit)
		this.Owner := getUnitOwner(Unit)
		this.Type := getUnitType(Unit)
		this.X := getUnitPositionX(unit)
		this.Y := getUnitPositionY(unit)
		this.TargetFilter := getUnitTargetFilter(Unit)	
	}
}

;ParseEnemyUnits(ByRef a_LocalUnits, ByRef a_EnemyUnits, ByRef aPlayer)
ParseEnemyUnits(ByRef a_EnemyUnits, ByRef aPlayer)
{ 
	LocalTeam := getPlayerTeam(), a_EnemyUnitsTmp := []
	While (A_Index <= getHighestUnitIndex())
	{
		unit := A_Index -1
		Filter := getUnitTargetFilter(unit)	
		If (Filter & aUnitTargetFilter.Dead) || (type = "Fail")
			Continue
		Owner := getUnitOwner(unit)
		if  (aPlayer[Owner, "Team"] <> LocalTeam AND Owner) 
			a_EnemyUnitsTmp[Unit] := new c_EnemyUnit(Unit)
	}
	a_EnemyUnits := a_EnemyUnitsTmp
}

; returns longest player name (string length) in enemy team and can include the local player for overlays
getLongestPlayerName(aPlayer, includeLocalPlayer := False)
{
	localTeam := getPlayerTeam(getLocalPlayerNumber())
	for slotNumber, Player in aPlayer
	{
		if ((player.team != localTeam || (slotNumber = aLocalPlayer["Slot"] && includeLocalPlayer )) 
		&& StrLen(player.name) > StrLen(LongestName))
			LongestName := player.name
	}
	return LongestName
}

getLongestPlayerNames(byRef LongestEnemyName, byRef LongestIncludeSelf)
{
	hbm := CreateDIBSection(600, 200) ; big enough for any name
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	for slotNumber, Player in aPlayer
	{
		if (player.team != localTeam)
		{
			data := gdip_TextToGraphics(G, player.name, "x0y0 Bold cFFFFFFFF r4 s17", "Arial") ;get string size
			StringSplit, size, data, | ;retrieve the length of the string
			if (size3 > longestSize)
				longestSize := size3, LongestEnemyName := player.name
		} 	
	}

	data := gdip_TextToGraphics(G, aLocalPlayer.Name, "x0y0 Bold cFFFFFFFF r4 s17", "Arial") ;get string size
	StringSplit, size, data, | ;retrieve the length of the string
	if (size3 > longestSize)
		LongestIncludeSelf := aLocalPlayer.Name
	else LongestIncludeSelf := LongestEnemyName

	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayMatchTransparency)
	SelectObject(hdc, obm)
	DeleteObject(hbm)
	DeleteDC(hdc)
	return
}

; Returns false if any redraw is false (i.e. one ore more are still being drawn)
; returns true if all redraws are set true (i.e. waiting to be redrawn)
areOverlaysWaitingToRedraw()
{
	global
	return (ReDrawIncome && ReDrawResources && ReDrawArmySize && ReDrawWorker 
			&& ReDrawIdleWorkers && RedrawUnit && ReDrawLocalPlayerColour
			&& RedrawMacroTownHall && RedrawLocalUpgrades)	
}

DestroyOverlays()
{	
	global
	; destroy minimap when alttabed out
	; and at end of game
	; These destroy commands shouldnt be needed as the functions
	; themselves will do it when called with -1
	Try Gui, APMOverlay: Destroy 
	Try Gui, MiniMapOverlay: Destroy 
	Try Gui, IncomeOverlay: Destroy
	Try Gui, ResourcesOverlay: Destroy
	Try Gui, ArmySizeOverlay: Destroy
	Try Gui, WorkerOverlay: Destroy			
	Try Gui, idleWorkersOverlay: Destroy			
	Try Gui, LocalPlayerColourOverlay: Destroy			
	Try Gui, UnitOverlay: Destroy	
	Try Gui, MacroTownHall: Destroy	
	Try Gui, LocalUpgradesOverlay: Destroy	
	
	; as these arent in the minimap thread, if that call it, it will jump out
	local lOverlayFunctions := "DrawAPMOverlay,DrawIncomeOverlay,DrawUnitOverlay,DrawResourcesOverlay,DrawLocalPlayerColourOverlay"
				. ",DrawArmySizeOverlay,DrawWorkerOverlay,DrawIdleWorkersOverlay,DrawMacroTownHallOverlay"
				. ",DrawLocalUpgradesOverlay"
	loop, parse, lOverlayFunctions, `,
	{
		; telling the function to destroy itself is more reliable that just using gui destroy
		; The try is here as there is a narrow timing window after the overlay starts but before it finishes reading the ini
		; file which could throw an AHK GUI window error due to invalid value x, y pos (they havent been read yet)
		; When called from the main thread via the shell hook message.
		; This timing window could be bigger on slow computers.
		; Actually I don't think it could be from here due to it being a creation/GUi, show error
		; It would be from the shell hook, but when its creating not destroying the GUI
		; Note this only occurred when I had manually set an overlay to draw as if it had not read the ini file.
		; The draw/enable overlay value would be null. 
		; Otherwise the timing window would be impossibly small
		if IsFunc(A_LoopField)
			try %A_LoopField%(-1)
	}
	ReDrawOverlays := ReDrawAPM := ReDrawIncome := ReDrawResources 
				:= ReDrawArmySize := ReDrawWorker := ReDrawIdleWorkers 
				:= RedrawUnit := ReDrawLocalPlayerColour 
				:= RedrawMacroTownHall := RedrawLocalUpgrades := True
	return True ; used by shell to check thread actually ran the function
}





/*
; I was playing around with this for a long time, and it did make some maps better.
; But simply using the camera bounds instead of map bounds fixes a lot of stuff
;/* 
; I believe the other key to this is the camera and map bounds
; and their relationship with each other, as well as flooring/rounding/ceiling correctly.
; Although it is clear that units are not positioned linearly in certain parts of a map.
; I had this near fucking perfect for ladder maps.
; But it didn't work correctly for smaller or square maps. Now its just gone to shit again.
mapToMinimapPos(ByRef x, ByRef y) 
{
	global minimap

	xStart := x//1, yStart := y//1 ; floor seems to work better
	; correct units position as mapleft/start of map doesn't have to be 0
	x -= minimap.MapLeft, Y -= minimap.MapBottom 
	; Find the units relative position in the playable map and convert this to position in SC minimap UI (* minimap.Width) 
	; (minimap.Width is the screen width of SC UI minimap)
	; Then add on the origin of the x/y SC minimap UI (ScreenLeft)
	x := minimap.ScreenLeft + (x/minimap.MapPlayableWidth * minimap.Width)
	y := minimap.Screenbottom - (y/minimap.MapPlayableHeight * minimap.Height)	
	; Try to push x and y back towards the centre
	; as when drawing away from centre, it tends to be out in that direction
	; And the further away from centre, the larger the error.
	; I feel a big part of a pixel perfect position lies here. 
	; This probably needs to be a bit more complex

	minimap.CamMapPlayableHeight := getCameraboundsTop()+4 - getCameraBoundsBottom()+4
	minimap.CamMapPlayableWidth := getCameraboundsRight()+7 - getCameraboundsLeft()+7

	minimap.UnitOffsetXScale := minimap.CamMapPlayableWidth / minimap.CamMapPlayableHeight
	minimap.UnitOffsetYScale := minimap.CamMapPlayableHeight / minimap.CamMapPlayableWidth

	xoffset := 0.5 - xStart/minimap.CamMapPlayableWidth
	yoffset := yStart/minimap.CamMapPlayableHeight - 0.5 ; Reversed as my y origin is from the bottom of the map
	; factor 2.25 for square maps
	; 1 for tall maps
	x += ceil(xoffset * minimap.Scale * minimap.UnitOffsetXScale) *2 
  	y += ceil(yoffset * minimap.Scale * minimap.UnitOffsetYScale) *2
	return	
}
*/

isUserPerformingAction()
{	
	if ( isUserBusyBuilding() || IsUserMovingCamera() || IsMouseButtonActive() 	; so it wont do anything if user is holding down a mousebutton! eg dragboxing
	||  isCastingReticleActive() ) ; this gives 256 when reticle/cast cursor is present
		return 1
	else return 0
}

isUserPerformingActionIgnoringCamera()
{	GLOBAL
	if ( isUserBusyBuilding() || IsMouseButtonActive() 	; so it wont do anything if user is holding down a mousebutton! eg dragboxing
	||  isCastingReticleActive() ) ; this gives 256 when reticle/cast cursor is present
		return 1
	else return 0
}

; this gives 256 when reticle/casting cursor is present (includes attacking)
isCastingReticleActive()
{	GLOBAL
	return pointer(GameIdentifier, P_IsUserPerformingAction, O1_IsUserPerformingAction)
}

; for the second old pointer
; This will return 1 if the basic or advanced building selection card is up (even if all structures greyed out)
; This will also return 1 when user is trying to place the structure
isUserBusyBuilding()	
{ 	GLOBAL
	; if 6, it means that either the basic or advanced build cards are displayed - even if all are greyed out (and hence a worker is selected) - give 1 for most other units, but gives 7 for targeting reticle
	if ( 6 = pointer(GameIdentifier, P_IsBuildCardDisplayed, 01_IsBuildCardDisplayed, 02_IsBuildCardDisplayed, 03_IsBuildCardDisplayed)) 
		return 1 ; as it seems 6 is only displayed when the worker build cards are up, so don't need to double check with below pointer
	;	return pointer(GameIdentifier, P_IsUserBuildingWithWorker, 01_IsUserBuildingWithWorker, 02_IsUserBuildingWithWorker, 03_IsUserBuildingWithWorker, 04_IsUserBuildingWithWorker)
	else return 0
}
	

/*


	GENERAL FUNCTIONS TO BE PUT IN A LIB

*/


ifTypeInList(type, byref list)
{
	if type in %list%
		return 1
	return 0
}

IniRead(File, Section, Key="", DefaultValue="")
{
	IniRead, Output, %File%, %Section%, %Key%, %DefaultValue%
	Return Output
}

createAlertArray()
{	
	local alert_array := [], temp_name, temp_DWB, temp_DWA, Temp_repeat, Temp_IDName, minimapAlert, gameType

	for i, gameType in ["1v1", "2v2", "3v3", "4v4"]
	{
		IniRead, BAS_on_%gameType%, %config_file%, Building & Unit Alert %gameType%, enable, 0	;alert system on/off
		alert_array["Enabled", gameType] := BAS_on_%gameType% ;this style name, so it matches variable name for update
		alert_array[gameType] := []
		loop	;loop thru the building list sequentially
		{
			IniRead, temp_name, %config_file%, Building & Unit Alert %gameType%, %A_Index%_name_warning, ERROrABnCRQFQFtvq
			if (  temp_name == "ERROrABnCRQFQFtvq" ) ; use a phrase that a user would never use
				break	
			IniRead, temp_DWB, %config_file%, Building & Unit Alert %gameType%, %A_Index%_Dont_Warn_Before_Time, 0 ;get around having blank keys in ini)=
			IniRead, temp_DWA, %config_file%, Building & Unit Alert %gameType%, %A_Index%_Dont_Warn_After_Time, 54000 ;15 hours - get around having blank keys in ini		
			IniRead, Temp_repeat, %config_file%, Building & Unit Alert %gameType%, %A_Index%_repeat_on_new, 0
			IniRead, minimapAlert, %config_file%, Building & Unit Alert %gameType%, %A_Index%_minimapAlert, 1
			IniRead, Temp_IDName, %config_file%, Building & Unit Alert %gameType%, %A_Index%_IDName
			alert_array[gameType].Insert({ "Name": temp_name, "DWB":  temp_DWB, "DWA": temp_DWA, "Repeat": Temp_repeat, "IDName": Temp_IDName, "minimapAlert": minimapAlert})
				; This lookup has the has the id for each unit type which has an alert. 
			; can do a simple alert_array[GameType, IDLookUp].HasKey(unitID) to check if the list has an alert for this unit type
			; then can do a for loop on just these alerts
			if !isObject(alert_array["IDLookUp", gameType, aUnitID[Temp_IDName]])
				alert_array["IDLookUp", gameType, aUnitID[Temp_IDName]] := []
			alert_array["IDLookUp", gameType, aUnitID[Temp_IDName]].insert(alert_array[gameType].MaxIndex())
		}
	}
	Return alert_array
}

convertObjectToList(Object, Delimiter="|")
{
	for index, item in Object
		if (A_index = 1)
			List .= item
		else
			List .= "|" item
	return List
}

;note if the object is part of a multidimensional array it still must first be initialised
;eg
;	obj := []
;	obj["Terran", "Units"] := []
;	ConvertListToObject(obj["Terran", "Units"], l_UnitNamesTerran)
ConvertListToObject(byref Object, List, Delimiter="|", ClearObject = 0)
{
	if (!IsObject(object) || ClearObject)
		object := []
	loop, parse, List, %delimiter%
		object.insert(A_LoopField)
	return
}

; This was used due to problems with thread.terminate() and SAPI/object
; Also can be used to exit the thread without causing the shutdown routine to be called
; twice. Only used in certain situations. e.g. directly closing a thread
exitApp()
{
	ExitApp
	return 
}


tSpeak(Message, SAPIVol := "", SAPIRate := "")
{	global speech_volume, aThreads

	if (SAPIVol = "")
		SAPIVol := speech_volume
	if SAPIVol ; If it's 0 don't bother calling the function
		aThreads.Speech.ahkPostFunction("speak", Message, SAPIVol, SAPIRate)
	return
}

; Returns the game time (seconds) when the structure was created
; For production units e.g. marines it returns the time at which it leaves
; the barracks

; Increases each time the unit dies (when the unit dies)
; Starts at 1. E.g. a town hall which spawns with the map has a value of 1
; morphing doesn't change this
getUnitIndexReusedCount(unitIndex)
{
	return readmemory(B_uStructure + Offsets_Unit_StructSize * unitIndex, GameIdentifier, 2) ; +0 Increases when the unit dies
}

numGetUnitIndexReusedCount(ByRef MemDump, Unit)
{	
	return numget(MemDump, Unit * Offsets_Unit_StructSize, "UShort")
}
numGetUnitFingerPrint(ByRef MemDump, Unit)
{	
	return numget(MemDump, Unit * Offsets_Unit_StructSize, "UInt")
}

; The unitTimer is updated slower than the gameTick/time. This can cause a time to be out
; by a fraction depending on when the function is called e.g. 0.0625 instead of 0. So round it.
; I think this could cause issues if the if the results are near x.5, so if comparing it to some other value check the deltas are within a small rang e.g. 1 

; 10/12/14 I just discovered that this is not accurate for protoss structures. 
; Chrono boost will cause getUnitTimer() to increase faster, and hence this will return a slightly lower value so care should be used.

getTimeAtUnitConstruction(unit)
{
	; round to help account for different update intervals of the two timers. Round to nearest Integer!!
	return (seconds := round(getTimeFull() - getUnitTimer(unit))) < 0 ? 0 : seconds ; getTime() is rounded to 1 decimal, so protect against small negative numbers. This shouldn't be required when calling getTimeFUll(), but doesn't hurt
}

; Do a obj.parentLookUp[gametype].HasKeys(unitID) before calling
; I.e. only call the function for structures which can produce the upgrade (alert) items
performUpgradeDetection(unitID, unitIndex, owner, fingerPrint)
{
	global aMiniMapWarning, aUpgradeAlerts, GameType, time
	static aWarned := []

	aSpecialUnits := {aUnitID.Hatchery: "UpgradeToLair"
					, aUnitID.Lair: "UpgradeToHive"
					, aUnitID.Spire: "UpgradeToGreaterSpire"
					, aUnitID.MothershipCore: "MorphToMothership"}

	if (time <= 10 && aWarned := [])
		return 
	if aUpgradeAlerts.alertLookUp[gameType].Haskey(aSpecialUnits[unitID]) && isHatchLairOrSpireMorphing(unitIndex, unitID)
	{
		aInfo := [], aInfo[1, "Item"] := aSpecialUnits[unitID]
		, aInfo[1, "Progress"] := getUnitMorphTime(unitIndex, unitID, False)
	}
	else if !getStructureProductionInfo(unitIndex, unitID, aInfo,, False)
		return
	if !aUpgradeAlerts.alertLookUp[gameType].Haskey(aInfo.1.Item)
	|| time > aUpgradeAlerts[GameType, key := aUpgradeAlerts.alertLookUp[gameType, aInfo.1.Item], "DWA"]
		return

;	if (time <= 10 && aWarned := []) ; No upgrade will start before this time. Easy way to reset for new game.
;	|| !getStructureProductionInfo(unitIndex, unitID, aInfo,, False) ; False return progress as time remaining (more accurate than rounded %)
;	|| !aUpgradeAlerts.alertLookUp[gameType].Haskey(aInfo.1.Item) ; No warning for this upgrade in this game mode
;	|| time > aUpgradeAlerts[GameType, key := aUpgradeAlerts.alertLookUp[gameType, aInfo.1.Item], "DWA"] ; Don't warn after this game time 
;		return 
	; Ignore warned upgrade which is still researching, unless its timeRemainging > the prior time remaining or its being researched by a new structure (it has restarted)
	; If (previously warned && ((!repeatable || <15 seconds since first started) || (upgrade has has progressed && same structure)) return + update progress
	; When repeatable - if an upgrade is cancelled and restarted within 15 in game seconds  from starting, it will not be rewarmed.

	if aWarned[owner].hasKey(aInfo.1.Item) 
	&& ( !aUpgradeAlerts[GameType, key, "Repeatable"]  ; Don't warn on restart 
	; && ( (!aUpgradeAlerts[GameType, key, "Repeatable"] || abs(aWarned[owner, aInfo.1.Item, "startTime"] - time) <= 15) ; Don't warn on restart 
	|| (aWarned[owner, aInfo.1.Item, "fingerPrints"].hasKey(fingerPrint) && aWarned[owner, aInfo.1.Item, fingerPrint, "timeRemaining"] >= aInfo.1.Progress))  ; ; ** Use >= in case protoss upgrade gets unpowered
		return "", aWarned[owner, aInfo.1.Item, fingerPrint, "timeRemaining"] := aInfo.1.Progress ; Update that new progress. helps ensure that cancelled upgrades will be re-warned if they start again

	;, aWarned[owner, aInfo.1.Item, "gameTime"] := time
	aWarned[owner, aInfo.1.Item, fingerPrint, "timeRemaining"] := aInfo.1.Progress 
	, aWarned[owner, aInfo.1.Item, "fingerPrints", fingerPrint] :=  True
	;, aWarned[owner, aInfo.1.Item, "startTime"] := time
	, alert := aUpgradeAlerts[GameType, key]	
	, previousDetectionWarning({"unitIndex": unitIndex, "FingerPrint": fingerPrint, "Type": unitID, "Owner": owner, "minimapAlert": alert.minimapAlert, "speech": alert.verbalWarning, "WarningType": "upgradeDetection"})
	if alert.minimapAlert								
		aMiniMapWarning.insert({ "unitIndex": unitIndex, "Time": Time, "FingerPrint": fingerPrint, "Type": unitID, "Owner": owner, "WarningType": "upgradeDetection"})
	tSpeak(alert.verbalWarning)
	return
}


; One of the first functions i ever wrote. Very messy. But it works and im lazy
; Should have made it so that it uses the unit type as a lookup rather than iterating the warning types.
; But then would have to modify quite a bit, as you can have multiple warning for the same unit type
; Also it's possible a unit won't be warned if an already warned unit dies and its unit index is reused
; for another unit which should be warned. Should compare timeAlive value

doUnitDetection(unit, type, owner, unitUsedCount, mode = "")
{	
	global config_file, alert_array, time, aMiniMapWarning, GameIdentifier, aUnitID, GameType
	static Alert_TimedOut := [], Alerted_Buildings := [], Alerted_Buildings_Base := []

	if !mode
	{
		;i should really compare the unit type, as theres a chance that the warned unit has died and was replaced with another unit which should be warned
		
		;loop, % alert_array[GameType, "list", "size"]
		for i, key in alert_array["IDLookUp", GameType, type]
		{ 				
			alert := alert_array[GameType, key]

			if  ( type = aUnitID[alert["IDName"]] ) ;So if its a shrine and the player is not on ur team. This should be required as the type loop above should mean they will always match
			{
				createdAtTime := getTimeAtUnitConstruction(unit) ; This will be 0 for starting units (townhall + workers)

				if ( createdAtTime < alert["DWB"]) ; Each time chrono is used on it createdAtTime will be slightly lower - but this isn't an issue as the unit would already have been warned 
				{	
					if !Alert_TimedOut[owner, key].HasKey(unit) || unitUsedCount != Alert_TimedOut[owner, key, unit]
						Alert_TimedOut[owner, key, unit] := unitUsedCount 
					continue ; may be an alert with a different DWB for this unit type later on in the array
				}
				else if (time > alert["DWA"]) ; refer to time, as createdAtTime is reduced with each chrono. (which could cause a trigger if the unit was made just after DWA)
					continue ; may be other warnings for this unit with different times
				Else if (Alert_TimedOut[owner, key].HasKey(unit) && unitUsedCount = Alert_TimedOut[owner, key, unit])
				|| (!alert["Repeat"] && Alerted_Buildings[owner].HasKey(key))
				|| (Alerted_Buildings_Base[owner, key].Haskey(unit) && unitUsedCount = Alerted_Buildings_Base[owner, key, unit])
					return 
				
				; using key in Alerted_Buildings_Base ensures that a warning will work for a hatch and later for lair when it finishes morphing
				; if just used the fingerprint this wouldnt work (unless checked unit type)
				fingerPrint := getUnitFingerPrint(unit)
				, previousDetectionWarning({ "unitIndex": unit, "FingerPrint": fingerPrint, "Type": type, "Owner": owner, "minimapAlert": alert["minimapAlert"], "speech": alert["Name"], "WarningType": "unitDetection"})
				if alert["minimapAlert"]
				 	aMiniMapWarning.insert({ "unitIndex": unit, "Time": Time, "FingerPrint": fingerPrint, "Type": type, "Owner": owner, "WarningType": "unitDetection"})
				
				tSpeak(speech := alert["Name"])
				if !alert["Repeat"]	; =0 these below setup a list like above, but contins the type - to prevent rewarning
					Alerted_Buildings[owner, key] := True
					;Alerted_Buildings.insert( {(owner): key})
			;	Alerted_Buildings_Base.insert( {(owner): unit}) ; prevents the same exact unit beings warned on next run thru
				Alerted_Buildings_Base[owner, key, unit] := unitUsedCount ; prevents the same exact unit beings warned on next run thru.
				return	
			} ;End of if unit is on list and player not on our team 
		} ; loop, % alert_array[GameType, "list", "size"]
	}
	else if (Mode = "Reset")
	{
		Alert_TimedOut := [], Alerted_Buildings := [], Alerted_Buildings_Base := []
		IniDelete, %config_file%, Resume Warnings
	}
	else If (Mode = "Save")
	{
		Iniwrite, % SerDes(Alert_TimedOut), %config_file%, Resume Warnings, Alert_TimedOut		
		Iniwrite, % SerDes(Alerted_Buildings), %config_file%, Resume Warnings, Alerted_Buildings		
		Iniwrite, % SerDes(Alerted_Buildings_Base), %config_file%, Resume Warnings, Alerted_Buildings_Base		
		Iniwrite, %A_NowUTC%, %config_file%, Resume Warnings, Resume ; Only resume if program restarted within 15 seconds
	}
	Else if (Mode = "Resume") ; Used when main thread saves options gui and emergency reload.
	{
		Alert_TimedOut := [], Alerted_Buildings := [], Alerted_Buildings_Base := []
		Iniread, string, %config_file%, Resume Warnings, Alert_TimedOut, %A_space%
		if (string != "")
		{
			Alert_TimedOut := SerDes(string)
			; 21/08/14 I noticed today this got stuck repeating units at start of match (hatch/cc)
			; Cant seem to make it do it again though. Got it to do it once or twice but not sure what the cause was
			; Added safety check in case SerDes() doesn't return an object
			; But I don't believe this is the cause.
			; I also had the main GUI load on startup and alt-tabed in/out at start of match
			if !IsObject(Alert_TimedOut)
				Alert_TimedOut := []
		}
		Iniread, string, %config_file%, Resume Warnings, Alerted_Buildings, %A_space%
		if (string != "")
		{
			Alerted_Buildings := SerDes(string)
			if !IsObject(Alerted_Buildings)
				Alerted_Buildings := []
		}
		Iniread, string, %config_file%, Resume Warnings, Alerted_Buildings_Base, %A_space%
		if (string != "")
		{
			Alerted_Buildings_Base := SerDes(string)
			if !IsObject(Alerted_Buildings_Base)
				Alerted_Buildings_Base := []
		}
		IniDelete, %config_file%, Resume Warnings
	}
	return
}



; Chrono fucks this method	i.e. getTimeAtUnitConstruction()	

/*
	getTimeAtUnitConstruction() the returned time will (permanently) decrease whenever a structure is chrono boosted
	therefore do: (time = getTimeAtUnitConstruction() result )
	if currentTime - savedTime < 1 
		same unit 
	else new unit

	If it is the exact same unit currentTime and savedTime will be the same (within a fraction of a second).

	If its the same unit which has been chronoed then the result (currentTime - savedTime) will be a negative number,
	as currentTime is lowered by each chrono boost

	if the old unit died and its index is reused, then the result (currentTime - savedTime) will be positive, as 
	currentTime will be greater than savedTime

*/

; keys 
; unitIndex, FingerPrint, speech, Type, Owner, minimapAlert, WarningType

; pass object to set prior alert. 
; pass null to invoke prior warning
; any other value will reset clear the previous alert
previousDetectionWarning(p := "")
{
	global aMiniMapWarning
	static pWarning

	if isObject(p)
		pWarning := p.clone()
	else if (p != "") ; call at start of game to allow 'There have been no alerts' to work
		pWarning := ""
	else If pWarning
	{
		if getUnitFingerPrint(pWarning.unitIndex) != pWarning.FingerPrint
			tSpeak(pWarning.speech " is dead.")
		else 
		{
			tSpeak(pWarning.speech)
			if pWarning.minimapAlert
			{
				aMiniMapWarning.insert({ "unitIndex": pWarning.unitIndex
								, "Time":  getTime()
								, "FingerPrint": pWarning.FingerPrint
								, "WarningType": pWarning.WarningType
								, "Type": pWarning.Type 
								, "Owner":  pWarning.Owner})
			}
		}
	}
	Else tSpeak("There have been no alerts")
	return 
}

; This is called by the minimap thread via the main thread, when the 
; user clicks 'save' in the alert list editor. It applies alert the changes for the current game.
; otherwise if they don't click the save button on the options GUI, then 
; the changes are not applied until the next game
updateAlertArray()
{
	global alert_array := createAlertArray()
}
updateUpgradeAlerts()
{
	global aUpgradeAlerts := iniReadUpgradeAlerts()
}
updateUnitFilterLists()
{
	global aUnitPanelUnits
	; [UnitPanelFilter]
	section := "UnitPanelFilter"
	aUnitPanelUnits := []	;;array just used to store the smaller lists for each race
	for index, race in ["Terran", "Protoss", "Zerg"] 
	{
		IniRead, list, %config_file%, %section%, %race%FilteredCompleted, %A_Space% ;Format FleetBeacon|TwilightCouncil|PhotonCannon	
		aUnitPanelUnits[race, "FilteredCompleted"] := [] ; make it an object
		ConvertListToObject(aUnitPanelUnits[race, "FilteredCompleted"], list)
		IniRead, list, %config_file%, %section%, %race%FilteredUnderConstruction, %A_Space% ;Format FleetBeacon|TwilightCouncil|PhotonCannon	
		aUnitPanelUnits[race, "FilteredUnderConstruction"] := [] ; make it an object
		ConvertListToObject(aUnitPanelUnits[race, "FilteredUnderConstruction"], list)
	}
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
	

	IniRead, InjectTimerAdvancedEnable, %config_file%, Manual Inject Timer, InjectTimerAdvancedEnable, 0
	IniRead, InjectTimerAdvancedTime, %config_file%, Manual Inject Timer, InjectTimerAdvancedTime, 43
	IniRead, InjectTimerAdvancedLarvaKey, %config_file%, Manual Inject Timer, InjectTimerAdvancedLarvaKey, e

	

	;[Inject Warning]
	IniRead, W_inject_ding_on, %config_file%, Inject Warning, ding_on, 1
	IniRead, W_inject_speech_on, %config_file%, Inject Warning, speech_on, 0
	IniRead, w_inject_spoken, %config_file%, Inject Warning, w_inject, Inject
	
	;[Forced Inject]
	section := "Forced Inject"
	IniRead, F_Inject_Enable, %config_file%, %section%, F_Inject_Enable, 0
	IniRead, FInjectHatchFrequency, %config_file%, %section%, FInjectHatchFrequency, 2500
	if (FInjectHatchFrequency < 500) ; prior to vr.3.142 users could set this to anything!
		FInjectHatchFrequency := 500
	IniRead, FInjectHatchMaxHatches, %config_file%, %section%, FInjectHatchMaxHatches, 10
	IniRead, FInjectAPMProtection, %config_file%, %section%, FInjectAPMProtection, 190
	IniRead, F_InjectOff_Key, %config_file%, %section%, F_InjectOff_Key, Lwin & F5
	IniRead, EnableToggleAutoInjectHotkey, %config_file%, %section%, EnableToggleAutoInjectHotkey, 1
	
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
	IniRead, CG_control_group, %config_file%, %section%, CG_control_group, 9
	IniRead, CG_nexuOffsets_Group_ControlGroupSize_key, %config_file%, %section%, CG_nexuOffsets_Group_ControlGroupSize_key, 4
	IniRead, chrono_key, %config_file%, %section%, chrono_key, c
	IniRead, CG_chrono_remainder, %config_file%, %section%, CG_chrono_remainder, 2
	IniRead, ChronoBoostSleep, %config_file%, %section%, ChronoBoostSleep, 50
	if IsFunc(FunctionName := "iniReadAutoChrono") ; function only in main thread
		%FunctionName%(aAutoChronoCopy, aAutoChrono)

	;[Advanced Auto Inject Settings]
	IniRead, auto_inject_sleep, %config_file%, Advanced Auto Inject Settings, auto_inject_sleep, 50
	IniRead, Inject_SleepVariance, %config_file%, Advanced Auto Inject Settings, Inject_SleepVariance, 0
	Inject_SleepVariance := 1 + (Inject_SleepVariance/100) ; so turn the variance 30% into 1.3 

	IniRead, CanQueenMultiInject, %config_file%, Advanced Auto Inject Settings, CanQueenMultiInject, 1
	IniRead, InjectConserveQueenEnergy, %config_file%, Advanced Auto Inject Settings, InjectConserveQueenEnergy, 0
	IniRead, Inject_RestoreSelection, %config_file%, Advanced Auto Inject Settings, Inject_RestoreSelection, 1
	IniRead, BackspaceRestoreCameraDelay, %config_file%, Advanced Auto Inject Settings, BackspaceRestoreCameraDelay, 30
	IniRead, InjectGroupingDelay, %config_file%, Advanced Auto Inject Settings, InjectGroupingDelay, 0

	IniRead, Inject_RestoreScreenLocation, %config_file%, Advanced Auto Inject Settings, Inject_RestoreScreenLocation, 1
	IniRead, Inject_SoundOnCompletion, %config_file%, Advanced Auto Inject Settings, Inject_SoundOnCompletion, 0
	IniRead, drag_origin, %config_file%, Advanced Auto Inject Settings, drag_origin, Left

	;[Read Opponents Spawn-Races]
	IniRead, race_reading, %config_file%, Read Opponents Spawn-Races, enable, 1
	IniRead, Auto_Read_Races, %config_file%, Read Opponents Spawn-Races, Auto_Read_Races, 1
	IniRead, read_races_key, %config_file%, Read Opponents Spawn-Races, read_key, LWin & F1
	;IniRead, race_speech, %config_file%, Read Opponents Spawn-Races, speech, 1
	;IniRead, race_clipboard, %config_file%, Read Opponents Spawn-Races, copy_to_clipboard, 0

	;[Worker Production Helper]
	for i, race in ["Terran", "Protoss", "Zerg"]
	{
		for key, value in {	"WarningsWorker|Enable": 1
						, 	"WarningsWorker|TimeWithoutProduction": 10
						,	"WarningsWorker|MinWorkerCount": 6
						, 	"WarningsWorker|MaxWorkerCount": 60
						, 	"WarningsWorker|FollowUpCount": 0
						, 	"WarningsWorker|FollowUpDelay": 25
						, 	"WarningsWorker|SpokenWarning": "Build Worker"}
		{
			StringReplace, key, key, |, %race%
			IniRead, %key%, %config_file%, Worker Production Helper, %key%, %value%
		}
	}

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

	;[WarningsGeyserOverSaturation]
	section := "WarningsGeyserOverSaturation"
	IniRead, WarningsGeyserOverSaturationEnable, %config_file%, %section%, WarningsGeyserOverSaturationEnable, 0
	IniRead, WarningsGeyserOverSaturationMaxWorkers, %config_file%, %section%, WarningsGeyserOverSaturationMaxWorkers, 4
	IniRead, WarningsGeyserOverSaturationMaxTime, %config_file%, %section%, WarningsGeyserOverSaturationMaxTime, 15
	IniRead, WarningsGeyserOverSaturationFollowUpCount, %config_file%, %section%, WarningsGeyserOverSaturationFollowUpCount, 0
	IniRead, WarningsGeyserOverSaturationFollowUpDelay, %config_file%, %section%, WarningsGeyserOverSaturationFollowUpDelay, 25
	IniRead, WarningsGeyserOverSaturationSpokenWarning, %config_file%, %section%, WarningsGeyserOverSaturationSpokenWarning, Geyser Saturation

	;[TownHallRally]
	section := "TownHallRally"
	IniRead, TownHallRallyEnableTerran, %config_file%, %section%, TownHallRallyEnableTerran, 0
	IniRead, TownHallRallyEnableProtoss, %config_file%, %section%, TownHallRallyEnableProtoss, 0
	IniRead, TownHallRallyEnableZerg, %config_file%, %section%, TownHallRallyEnableZerg, 0
	IniRead, TownHallRallySpokenWarning, %config_file%, %section%, TownHallRallySpokenWarning, Rally

	;[Additional Warning Count]-----set number of warnings to make
	IniRead, sec_supply, %config_file%, Additional Warning Count, supply, 1
	IniRead, sec_mineral, %config_file%, Additional Warning Count, minerals, 1
	IniRead, sec_gas, %config_file%, Additional Warning Count, gas, 0
	IniRead, sec_idle, %config_file%, Additional Warning Count, idle_workers, 0
	/*
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
			String := IniRead(config_file, section, "AG_" A_LoopField A_Index - 1, A_Space)
			StringReplace, String, String, |, `, %a_space%, All ;replace | with , space
			if Instr(String, A_Space A_Space)
				StringReplace, String, String, %A_Space%%A_Space%, %A_Space%, All
			list := ""
			loop, parse, String, `, ; string is a local var/copy in this command
			{
				if aUnitID.HasKey(string := Trim(A_LoopField, "`, `t")) ; get rid of spaces which cause haskey to fail
					list .= string ", "  ; leave a space for the gui
			}
			A_UnitGroupSettings[Race, A_Index - 1] := Trim(list, "`, `t")			
		}

	}
	IniRead, AGBufferDelay, %config_file%, %section%, AGBufferDelay, 50
	IniRead, AGKeyReleaseDelay, %config_file%, %section%, AGKeyReleaseDelay, 60
	IniRead, AGRestrictBufferDelay, %config_file%, %section%, AGRestrictBufferDelay, 90
	
	; hotkeys
	aAGHotkeys := []
	loop 10 
	{
		group := A_index -1
		IniRead, AGAddToGroup%group%, %config_file%, %section%, AGAddToGroup%group%, +%group%
		IniRead, AGSetGroup%group%, %config_file%, %section%, AGSetGroup%group%, ^%group%
		IniRead, AGInvokeGroup%group%, %config_file%, %section%, AGInvokeGroup%group%, %group%
		aAGHotkeys["add", group] := AGAddToGroup%group%
		aAGHotkeys["set", group] := AGSetGroup%group%
		aAGHotkeys["invoke", group] := AGInvokeGroup%group%
	}		
	*/

	if IsFunc(FunctionName := "iniReadAutoGrouping") ; function only in main thread
		aAutoGroup := %FunctionName%()	
	if IsFunc(FunctionName := "iniReadRestrictGrouping") ; function only in main thread
		aRestrictGroup := %FunctionName%()

	;[ Volume]
	section := "Volume"
	IniRead, speech_volume, %config_file%, %section%, speech, 100
	IniRead, programVolume, %config_file%, %section%, program, 100
	; theres an iniwrite volume in the exit routine

	;[Warnings]-----sets the audio warning
	IniRead, w_supply, %config_file%, Warnings, supply, "Supply"
	IniRead, w_mineral, %config_file%, Warnings, minerals, "Money"
	IniRead, w_gas, %config_file%, Warnings, gas, "Gas"
	IniRead, w_idle, %config_file%, Warnings, idle_workers, "Idle"

	;[Additional Warning Delay]
	IniRead, additional_delay_supply, %config_file%, Additional Warning Delay, supply, 10
	IniRead, additional_delay_minerals, %config_file%, Additional Warning Delay, minerals, 10
	IniRead, additional_delay_gas, %config_file%, Additional Warning Delay, gas, 10
	IniRead, additional_idle_workers, %config_file%, Additional Warning Delay, idle_workers, 10


	;[Misc Hotkey]
	IniRead, EnableWorkerCountSpeechHotkey, %config_file%, Misc Hotkey, EnableWorkerCountSpeechHotkey, 1
	IniRead, worker_count_local_key, %config_file%, Misc Hotkey, worker_count_key, F8
	IniRead, EnableEnemyWorkerCountSpeechHotkey, %config_file%, Misc Hotkey, EnableEnemyWorkerCountSpeechHotkey, 1
	IniRead, worker_count_enemy_key, %config_file%, Misc Hotkey, enemy_worker_count, Lwin & F8
	IniRead, EnableToggleMacroTrainerHotkey, %config_file%, Misc Hotkey, EnableToggleMacroTrainerHotkey, 1
	IniRead, warning_toggle_key, %config_file%, Misc Hotkey, pause_resume_warnings_key, Lwin & Pause
	IniRead, EnablePingMiniMapHotkey, %config_file%, Misc Hotkey, EnablePingMiniMapHotkey, 1
	IniRead, ping_key, %config_file%, Misc Hotkey, ping_map, Lwin & MButton

	;[Misc Settings]
	section := "Misc Settings"
	IniRead, input_method, %config_file%, %section%, input_method, Input
	IniRead, pSendDelay, %config_file%, %section%, pSendDelay, -1
	IniRead, pClickDelay, %config_file%, %section%, pClickDelay, -1
	IniRead, EventKeyDelay, %config_file%, %section%, EventKeyDelay, -1
	
	IniRead, LauncherMode, %config_file%, %section%, LauncherMode, Battle.net
	IniRead, auto_update, %config_file%, %section%, auto_check_updates, 1
	IniRead, launch_settings, %config_file%, %section%, launch_settings, 0
	IniRead, MaxWindowOnStart, %config_file%, %section%, MaxWindowOnStart, 1

	;IniRead, UnitDetectionTimer_ms, %config_file%, %section%, UnitDetectionTimer_ms, 3500
	

	IniRead, MTCustomIcon, %config_file%, %section%, MTCustomIcon, %A_Space% ; I.e. False
	IniRead, MTCustomProgramName, %config_file%, %section%, MTCustomProgramName, %A_Space% ; I.e. False
	MTCustomProgramName := Trim(MTCustomProgramName)

	;[Key Blocking]
	section := "Key Blocking"
	
	IniRead, LwinDisable, %config_file%, %section%, LwinDisable, 1
	IniRead, Key_EmergencyRestart, %config_file%, %section%, Key_EmergencyRestart, <#Space

/*
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
*/

	;[Misc Automation]
	section := "AutoWorkerProduction"	
	IniRead, EnableAutoWorkerTerranStart, %config_file%, %section%, EnableAutoWorkerTerranStart, 0 
	IniRead, EnableAutoWorkerProtossStart, %config_file%, %section%, EnableAutoWorkerProtossStart, 0 
	IniRead, EnableToggleAutoWorkerHotkey, %config_file%, %section%, EnableToggleAutoWorkerHotkey, 1
	IniRead, ToggleAutoWorkerState_Key, %config_file%, %section%, ToggleAutoWorkerState_Key, #F2
	IniRead, AutoWorkerQueueSupplyBlock, %config_file%, %section%, AutoWorkerQueueSupplyBlock, 1
	IniRead, AutoWorkerAlwaysGroup, %config_file%, %section%, AutoWorkerAlwaysGroup, 1
	IniRead, AutoWorkerWarnMaxWorkers, %config_file%, %section%, AutoWorkerWarnMaxWorkers, 0
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


	section := "AutoBuild"
	IniRead, AutoBuildBarracksGroup, %config_file%, %section%, AutoBuildBarracksGroup, 5
	IniRead, AutoBuildFactoryGroup, %config_file%, %section%, AutoBuildFactoryGroup, 5
	IniRead, AutoBuildStarportGroup, %config_file%, %section%, AutoBuildStarportGroup, 5
	IniRead, AutoBuildGatewayGroup, %config_file%, %section%, AutoBuildGatewayGroup, 6
	IniRead, AutoBuildStargateGroup, %config_file%, %section%, AutoBuildStargateGroup, 6
	IniRead, AutoBuildRoboticsFacilityGroup, %config_file%, %section%, AutoBuildRoboticsFacilityGroup, 6
	IniRead, AutoBuildHatcheryGroup, %config_file%, %section%, AutoBuildHatcheryGroup, 4
	IniRead, AutoBuildLairGroup, %config_file%, %section%, AutoBuildLairGroup, 4
	IniRead, AutoBuildHiveGroup, %config_file%, %section%, AutoBuildHiveGroup, 4
	IniRead, autoBuildMinFreeMinerals, %config_file%, %section%, autoBuildMinFreeMinerals, 100
	IniRead, autoBuildMinFreeGas, %config_file%, %section%, autoBuildMinFreeGas, 0
	IniRead, autoBuildMinFreeSupply, %config_file%, %section%, autoBuildMinFreeSupply, 0	
	IniRead, AutoBuildEnableGUIHotkey, %config_file%, %section%, AutoBuildEnableGUIHotkey, 4
	IniRead, AutoBuildEnableGUIHotkey, %config_file%, %section%, AutoBuildEnableGUIHotkey, 0
	IniRead, AutoBuildGUIkey, %config_file%, %section%, AutoBuildGUIkey, F9
	IniRead, AutoBuildEnableInteractGUIHotkey, %config_file%, %section%, AutoBuildEnableInteractGUIHotkey, 0
	IniRead, AutoBuildInteractGUIKey, %config_file%, %section%, AutoBuildInteractGUIKey, F11
	IniRead, AutoBuildGUIkeyMode, %config_file%, %section%, AutoBuildGUIkeyMode, Toggle
	IniRead, AutoBuildInactiveOpacity, %config_file%, %section%, AutoBuildInactiveOpacity, 255
	IniRead, AutoBuildGUIAutoWorkerToggle, %config_file%, %section%, AutoBuildGUIAutoWorkerToggle, 0
	IniRead, AutoBuildGUIAutoWorkerPause, %config_file%, %section%, AutoBuildGUIAutoWorkerPause, 0
	IniRead, AutoBuildGUIAutoWorkerOffButton, %config_file%, %section%, AutoBuildGUIAutoWorkerOffButton, 0
	IniRead, autoBuildEnablePauseAllHotkey, %config_file%, %section%, autoBuildEnablePauseAllHotkey, 0
	IniRead, AutoBuildPauseAllkey, %config_file%, %section%, AutoBuildPauseAllkey, F8
	iniReadAutoBuildQuota()

	section := "AutomationCommon"
	IniRead, automationAPMThreshold, %config_file%, %section%, automationAPMThreshold, 200
	IniRead, AutomationTerranCtrlGroup, %config_file%, %section%, AutomationTerranCtrlGroup, 9
	IniRead, AutomationProtossCtrlGroup, %config_file%, %section%, AutomationProtossCtrlGroup, 9
	IniRead, AutomationZergCtrlGroup, %config_file%, %section%, AutomationZergCtrlGroup, 9
	IniRead, AutomationTerranCameraGroup, %config_file%, %section%, AutomationTerranCameraGroup, 4
	IniRead, AutomationProtossCameraGroup, %config_file%, %section%, AutomationProtossCameraGroup, 4
	IniRead, AutomationZergCameraGroup, %config_file%, %section%, AutomationZergCameraGroup, 4

	;[Misc Automation]
	section := "Misc Automation"
	IniRead, SelectArmyEnable, %config_file%, %section%, SelectArmyEnable, 0	;enable disable
	IniRead, Sc2SelectArmy_Key, %config_file%, %section%, Sc2SelectArmy_Key, {F2}
	IniRead, castSelectArmy_key, %config_file%, %section%, castSelectArmy_key, F2
	IniRead, SleepSelectArmy, %config_file%, %section%, SleepSelectArmy, 15
	IniRead, ModifierBeepSelectArmy, %config_file%, %section%, ModifierBeepSelectArmy, 1
	IniRead, SelectArmyOnScreen, %config_file%, %section%, SelectArmyOnScreen, 0
	IniRead, SelectArmyDeselectXelnaga, %config_file%, %section%, SelectArmyDeselectXelnaga, 1
	IniRead, SelectArmyDeselectPatrolling, %config_file%, %section%, SelectArmyDeselectPatrolling, 1
	IniRead, SelectArmyDeselectHoldPosition, %config_file%, %section%, SelectArmyDeselectHoldPosition, 0
	IniRead, SelectArmyDeselectFollowing, %config_file%, %section%, SelectArmyDeselectFollowing, 0
	IniRead, SelectArmyDeselectLoadedTransport, %config_file%, %section%, SelectArmyDeselectLoadedTransport, 0
	IniRead, SelectArmyDeselectQueuedDrops, %config_file%, %section%, SelectArmyDeselectQueuedDrops, 0
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
	IniRead, RemoveDamagedUnitsEnable, %config_file%, %section%, RemoveDamagedUnitsEnable, 0
	IniRead, castRemoveDamagedUnits_key, %config_file%, %section%, castRemoveDamagedUnits_key, !F1
	IniRead, RemoveDamagedUnitsCtrlGroup, %config_file%, %section%, RemoveDamagedUnitsCtrlGroup, 9
	IniRead, RemoveDamagedUnitsHealthLevel, %config_file%, %section%, RemoveDamagedUnitsHealthLevel, 90
	RemoveDamagedUnitsHealthLevel := round(RemoveDamagedUnitsHealthLevel / 100, 3)
	IniRead, RemoveDamagedUnitsShieldLevel, %config_file%, %section%, RemoveDamagedUnitsShieldLevel, 15
	RemoveDamagedUnitsShieldLevel := round(RemoveDamagedUnitsShieldLevel / 100, 3)

	IniRead, SelectTransportsTerranEnable, %config_file%, %section%, SelectTransportsTerranEnable, 0
	IniRead, SelectTransportsProtossEnable, %config_file%, %section%, SelectTransportsProtossEnable, 0
	IniRead, SelectTransportsZergEnable, %config_file%, %section%, SelectTransportsZergEnable, 0
	IniRead, EasyUnloadAllTerranEnable, %config_file%, %section%, EasyUnloadAllTerranEnable, 0
	IniRead, EasyUnloadAllProtossEnable, %config_file%, %section%, EasyUnloadAllProtossEnable, 0
	IniRead, EasyUnloadAllZergEnable, %config_file%, %section%, EasyUnloadAllZergEnable, 0
	IniRead, SelectTransportsHotkey, %config_file%, %section%, SelectTransportsHotkey, F5
	IniRead, EasyUnloadQueuedHotkey, %config_file%, %section%, EasyUnloadQueuedHotkey, +F5
	IniRead, EasyUnload_T_Key, %config_file%, %section%, EasyUnload_T_Key, d
	IniRead, EasyUnload_P_Key, %config_file%, %section%, EasyUnload_P_Key, d
	IniRead, EasyUnload_Z_Key, %config_file%, %section%, EasyUnload_Z_Key, d
	IniRead, EasyUnloadStorageKey, %config_file%, %section%, EasyUnloadStorageKey, 9
	IniRead, smartGeyserEnable, %config_file%, %section%, smartGeyserEnable, 0
	IniRead, smartGeyserCtrlGroup, %config_file%, %section%, smartGeyserCtrlGroup, 9
	IniRead, smartGeyserReturnCargo, %config_file%, %section%, smartGeyserReturnCargo, 0
	
	IniRead, ConvertGatewaysEnable, %config_file%, %section%, ConvertGatewaysEnable, 0
	IniRead, ConvertGatewayCtrlGroup, %config_file%, %section%, ConvertGatewayCtrlGroup, 5
	IniRead, ConvertGatewayDelay, %config_file%, %section%, ConvertGatewayDelay, 5
	
	IniRead, SmartMassRecallEnable, %config_file%, %section%, SmartMassRecallEnable, 0
	IniRead, SmartPhotonOverchargeEnable, %config_file%, %section%, SmartPhotonOverchargeEnable, 0
	IniRead, GlobalStimEnable, %config_file%, %section%, GlobalStimEnable, 0

	if thisThreadTitle in main,minimap
	{
		;[Alert Location]
		IniRead, Playback_Alert_Key, %config_file%, Alert Location, Playback_Alert_Key, <#F7
		IniRead, EnableLastAlertPlayBackHotkey, %config_file%, Alert Location, EnableLastAlertPlayBackHotkey, 1

		alert_array := createAlertArray()
		
		section := "Upgrade Alerts"
		IniRead, UpgradeAlertsEnable1v1, %config_file%, %section%, UpgradeAlertsEnable1v1, 0
		IniRead, UpgradeAlertsEnable2v2, %config_file%, %section%, UpgradeAlertsEnable2v2, 0
		IniRead, UpgradeAlertsEnable3v3, %config_file%, %section%, UpgradeAlertsEnable3v3, 0
		IniRead, UpgradeAlertsEnable4v4, %config_file%, %section%, UpgradeAlertsEnable4v4, 0
		aUpgradeAlerts := iniReadUpgradeAlerts()
	}

	;[Overlays]
	section := "Overlays"
	; This function will get return  the x,y coordinates for the top left, and bottom right of the 
	; desktop screen (the area on both monitors)
	;DesktopScreenCoordinates(XminScreen, YminScreen, XmaxScreen, YmaxScreen)
	local Xcentre, Ycentre, list
	getPrimaryMonitorCentre(Xcentre, Ycentre)
	list := "APMOverlay,IncomeOverlay,ResourcesOverlay,ArmySizeOverlay,WorkerOverlay,IdleWorkersOverlay,UnitOverlay,LocalPlayerColourOverlay,MacroTownHallOverlay,LocalUpgradesOverlay,autoBuildOverlay"
	loop, parse, list, `,
	{
		if (A_LoopField != "autoBuildOverlay") ; This overlay has no scale
		{
			IniRead, Draw%A_LoopField%, %config_file%, %section%, Draw%A_LoopField%, 0
			IniRead, %A_LoopField%Scale, %config_file%, %section%, %A_LoopField%Scale, 1
			if (%A_LoopField%Scale < .5)	;so cant get -scales (or invisibly small)
				%A_LoopField%Scale := .5
		}
		IniRead, %A_LoopField%X, %config_file%, %section%, %A_LoopField%X, %Xcentre%
		IniRead, %A_LoopField%Y, %config_file%, %section%, %A_LoopField%Y, %Ycentre%	
		if (%A_LoopField%X != Xcentre || %A_LoopField%Y != Ycentre)
		&& !isCoordinateBoundedByMonitor(%A_LoopField%X, %A_LoopField%Y)
			%A_LoopField%X := Xcentre, %A_LoopField%Y := Ycentre
	}

	IniRead, EnableHideMiniMapHotkey, %config_file%, %section%, EnableHideMiniMapHotkey, 1
	IniRead, EnableToggleMiniMapHotkey, %config_file%, %section%, EnableToggleMiniMapHotkey, 1
	IniRead, EnableToggleIncomeOverlayHotkey, %config_file%, %section%, EnableToggleIncomeOverlayHotkey, 1
	IniRead, EnableToggleResourcesOverlayHotkey, %config_file%, %section%, EnableToggleResourcesOverlayHotkey, 1
	IniRead, EnableToggleArmySizeOverlayHotkey, %config_file%, %section%, EnableToggleArmySizeOverlayHotkey, 1
	IniRead, EnableToggleWorkerOverlayHotkey, %config_file%, %section%, EnableToggleWorkerOverlayHotkey, 1
	IniRead, EnableToggleUnitPanelOverlayHotkey, %config_file%, %section%, EnableToggleUnitPanelOverlayHotkey, 1
	IniRead, EnableCycleIdentifierHotkey, %config_file%, %section%, EnableCycleIdentifierHotkey, 1
	IniRead, EnableAdjustOverlaysHotkey, %config_file%, %section%, EnableAdjustOverlaysHotkey, 1
	IniRead, EnableMultiOverlayToggleHotkey, %config_file%, %section%, EnableMultiOverlayToggleHotkey, 0
	IniRead, MultiOverlayToggleKey, %config_file%, %section%, MultiOverlayToggleKey, <#O

;	IniRead, DrawWorkerOverlay, %config_file%, %section%, DrawWorkerOverlay, 1
;	IniRead, DrawIdleWorkersOverlay, %config_file%, %section%, DrawIdleWorkersOverlay, 1

	IniRead, ToggleAPMOverlayKey, %config_file%, %section%, ToggleAPMOverlayKey, <#A
	IniRead, ToggleUnitOverlayKey, %config_file%, %section%, ToggleUnitOverlayKey, <#U
; This has been removed
;	IniRead, ToggleIdleWorkersOverlayKey, %config_file%, %section%, ToggleIdleWorkersOverlayKey, <#L
	IniRead, ToggleMinimapOverlayKey, %config_file%, %section%, ToggleMinimapOverlayKey, <#H
	IniRead, ToggleIncomeOverlayKey, %config_file%, %section%, ToggleIncomeOverlayKey, <#I
	IniRead, ToggleResourcesOverlayKey, %config_file%, %section%, ToggleResourcesOverlayKey, <#R
	IniRead, ToggleArmySizeOverlayKey, %config_file%, %section%, ToggleArmySizeOverlayKey, <#A
	IniRead, ToggleWorkerOverlayKey, %config_file%, %section%, ToggleWorkerOverlayKey, <#W	
	IniRead, AdjustOverlayKey, %config_file%, %section%, AdjustOverlayKey, Home
	IniRead, ToggleIdentifierKey, %config_file%, %section%, ToggleIdentifierKey, <#Q
	;IniRead, CycleOverlayKey, %config_file%, %section%, CycleOverlayKey, <#Enter
	IniRead, OverlayIdent, %config_file%, %section%, OverlayIdent, 2
	IniRead, SplitUnitPanel, %config_file%, %section%, SplitUnitPanel, 1
	IniRead, unitPanelAlignNewUnits, %config_file%, %section%, unitPanelAlignNewUnits, 0
	IniRead, UnitPanelNewUnitGap, %config_file%, %section%, UnitPanelNewUnitGap, 0
	;IniRead, DrawUnitUpgrades, %config_file%, %section%, DrawUnitUpgrades, 1
	IniRead, UnitOverlayMode, %config_file%, %section%, UnitOverlayMode, Units + Upgrades
	IniRead, unitPanelDrawStructureProgress, %config_file%, %section%, unitPanelDrawStructureProgress, 1
	IniRead, unitPanelDrawUnitProgress, %config_file%, %section%, unitPanelDrawUnitProgress, 1
	IniRead, unitPanelDrawUpgradeProgress, %config_file%, %section%, unitPanelDrawUpgradeProgress, 1
	IniRead, unitPanelPlayerProgressColours, %config_file%, %section%, unitPanelPlayerProgressColours, 0
	IniRead, unitPanelDrawScanProgress, %config_file%, %section%, unitPanelDrawScanProgress, 0
	IniRead, unitPanelDrawLocalPlayer, %config_file%, %section%, unitPanelDrawLocalPlayer, 0
;	IniRead, OverlayBackgrounds, %config_file%, %section%, OverlayBackgrounds, 0
	OverlayBackgrounds := False ; should remove this from 
	IniRead, MiniMapRefresh, %config_file%, %section%, MiniMapRefresh, 300
	IniRead, OverlayRefresh, %config_file%, %section%, OverlayRefresh, 1000
	IniRead, UnitOverlayRefresh, %config_file%, %section%, UnitOverlayRefresh, 4500
	IniRead, APMOverlayMode, %config_file%, %section%, APMOverlayMode, 0
	IniRead, drawLocalPlayerResources, %config_file%, %section%, drawLocalPlayerResources, 0
	IniRead, drawLocalPlayerIncome, %config_file%, %section%, drawLocalPlayerIncome, 0
	IniRead, drawLocalPlayerArmy, %config_file%, %section%, drawLocalPlayerArmy, 0
	
	IniRead, overlayAPMTransparency, %config_file%, %section%, overlayAPMTransparency, 255
	IniRead, overlayIncomeTransparency, %config_file%, %section%, overlayIncomeTransparency, 255
	IniRead, overlayMatchTransparency, %config_file%, %section%, overlayMatchTransparency, 255
	IniRead, overlayResourceTransparency, %config_file%, %section%, overlayResourceTransparency, 255
	IniRead, overlayArmyTransparency, %config_file%, %section%, overlayArmyTransparency, 255
	IniRead, overlayHarvesterTransparency, %config_file%, %section%, overlayHarvesterTransparency, 255
	IniRead, overlayIdleWorkerTransparency, %config_file%, %section%, overlayIdleWorkerTransparency, 255
	IniRead, overlayLocalColourTransparency, %config_file%, %section%, overlayLocalColourTransparency, 255
	IniRead, overlayMinimapTransparency, %config_file%, %section%, overlayMinimapTransparency, 255
	IniRead, overlayMacroTownHallTransparency, %config_file%, %section%, overlayMacroTownHallTransparency, 255
	IniRead, overlayLocalUpgradesTransparency, %config_file%, %section%, overlayLocalUpgradesTransparency, 255
	IniRead, localUpgradesOverlayMode, %config_file%, %section%, localUpgradesOverlayMode, Time Remaining
	IniRead, localUpgradesItemsPerRow, %config_file%, %section%, localUpgradesItemsPerRow, 6
	IniRead, IdleWorkerOverlayThreshold, %config_file%, %section%, IdleWorkerOverlayThreshold, 1
	IniRead, multiOverlayToggleBitField, %config_file%, %section%, multiOverlayToggleBitField, 0
	
	IniRead, TransparentBackgroundColour, %config_file%, %section%, TransparentBackgroundColour, 0x78000000
	IniRead, BackgroundIncomeOverlay, %config_file%, %section%, BackgroundIncomeOverlay, 0
	IniRead, BackgroundResourcesOverlay, %config_file%, %section%, BackgroundResourcesOverlay, 0
	IniRead, BackgroundArmySizeOverlay, %config_file%, %section%, BackgroundArmySizeOverlay, 0
	IniRead, BackgroundAPMOverlay, %config_file%, %section%, BackgroundAPMOverlay, 0
	IniRead, BackgroundIdleWorkersOverlay, %config_file%, %section%, BackgroundIdleWorkersOverlay, 0
	IniRead, BackgroundWorkerOverlay, %config_file%, %section%, BackgroundWorkerOverlay, 0
	IniRead, BackgroundMacroTownHallOverlay, %config_file%, %section%, BackgroundMacroTownHallOverlay, 0
	IniRead, BackgroundMacroAutoBuildOverlay, %config_file%, %section%, BackgroundMacroAutoBuildOverlay, 1

	; [UnitPanelFilter]
	section := "UnitPanelFilter"
	aUnitPanelUnits := []	;;array just used to store the smaller lists for each race
	loop, parse, l_Races, `,
	{
		race := A_LoopField
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
	
	; In version 3.01 colour picker was changed to the standard windows form/API. 
	; Users will no longer be able to set the alpha channel as the API doesn't have this functionality.
	; The returned colour will be missing the alpha channel. This channel is added in the saving routine, but lets be
	; ultra safe and just bitwise-or it here to ensure the alpha channel is full.   	
					
	UnitHighlightList1Colour |= 0xFF000000, UnitHighlightList2Colour |= 0xFF000000
	UnitHighlightList3Colour |= 0xFF000000, UnitHighlightList4Colour |= 0xFF000000
	UnitHighlightList5Colour |= 0xFF000000, UnitHighlightList6Colour |= 0xFF000000
	UnitHighlightList7Colour |= 0xFF000000


	IniRead, HighlightInvisible, %config_file%, %section%, HighlightInvisible, 1
	IniRead, UnitHighlightInvisibleColour, %config_file%, %section%, UnitHighlightInvisibleColour, 0xFFB7FF00
	UnitHighlightInvisibleColour |= 0xFF000000

	IniRead, HighlightHallucinations, %config_file%, %section%, HighlightHallucinations, 1
	IniRead, UnitHighlightHallucinationsColour, %config_file%, %section%, UnitHighlightHallucinationsColour, 0xFF808080
	UnitHighlightHallucinationsColour |= 0xFF000000

	; This allows the colour picker to update and keep the users added custom colour palette
	; even when opening the GUI multiple times
	; This custom colour pallette 
	; Have to bitwise-& 0xFFFFFF due to http://msdn.microsoft.com/en-us/library/windows/desktop/dd183449(v=vs.85).aspx
	; When specifying an explicit RGB color, the COLORREF value has the following hexadecimal form:
    ; 0x00bbggrr - The high-order byte must be zero.
    ; Note: I've modified the function so this is no longer required - can pass ARGB values.
	if !isObject(aChooseColourCustomPalette)
	{
		aChooseColourCustomPalette := []
		loop 7
			aChooseColourCustomPalette.insert(UnitHighlightList%A_Index%Colour & 0xFFFFFF)
		aChooseColourCustomPalette.insert(UnitHighlightInvisibleColour & 0xFFFFFF)
		aChooseColourCustomPalette.insert(UnitHighlightHallucinationsColour & 0xFFFFFF)
		aChooseColourCustomPalette.insert(0) ; black
	}
	IniRead, UnitHighlightExcludeList, %config_file%, %section%, UnitHighlightExcludeList, CreepTumor, CreepTumorBurrowed
	IniRead, DrawMiniMap, %config_file%, %section%, DrawMiniMap, 1
	IniRead, TempHideMiniMapKey, %config_file%, %section%, TempHideMiniMapKey, !Space
	IniRead, DrawSpawningRaces, %config_file%, %section%, DrawSpawningRaces, 1
	IniRead, DrawAlerts, %config_file%, %section%, DrawAlerts, 1
	IniRead, DrawUnitDestinations, %config_file%, %section%, DrawUnitDestinations, 0
	IniRead, DrawPlayerCameras, %config_file%, %section%, DrawPlayerCameras, 0
	IniRead, HostileColourAssist, %config_file%, %section%, HostileColourAssist, 0
	
	;[Hidden Options]
	section := "Hidden Options"
	IniRead, AutoGroupTimer, %config_file%, %section%, AutoGroupTimer, 30 		; care with this setting this below 20 stops the minimap from drawing properly wasted hours finding this problem!!!!
	IniRead, AutoGroupTimerIdle, %config_file%, %section%, AutoGroupTimerIdle, 5	; have to carefully think about timer priorities and frequency
	
	; Resume Warnings
	; This is written in the unitDetection save function
	; The variable ResumeWarnings contains a A_NowUTC time value for when the warnings were saved
	Iniread, ResumeWarnings, %config_file%, Resume Warnings, Resume, 0
	if (ResumeWarnings && A_NowUTC - ResumeWarnings <= 20) ; Only resume if within 20 seconds
		ResumeWarnings := True 
	else ResumeWarnings := False

	; [Misc Info]
	section := "Misc Info"
	IniRead, MT_HasWarnedLanguage, %config_file%, %section%, MT_HasWarnedLanguage, 0
	; RestartMethod is written to in the emergency exit routine
	; it is used in a couple of checks. Only the main thread will see this value as true.
	IniRead, MT_Restart, %config_file%, %section%, RestartMethod, 0
	if MT_Restart
		IniWrite, 0, %config_file%, %section%, RestartMethod ; set the value back to 0	
	IniRead, MT_DWMwarned, %config_file%, %section%, MT_DWMwarned, 0
	
	if IsFunc(FunctionName := "iniReadQuickSelect") ; function not in minimapthread
		%FunctionName%(aQuickSelectCopy, aQuickSelect)

	; So custom colour highlights are updated
	initialiseBrushColours(aHexColours, a_pBrushes)

	return
}



stripModifiers(pressedKey)
{
    StringReplace, pressedKey, pressedKey, ^ 
	StringReplace, pressedKey, pressedKey, + ;	these are needed in case the hotkey/keyname in key list contains these modifiers
	StringReplace, pressedKey, pressedKey, ! 
	StringReplace, pressedKey, pressedKey, *
	StringReplace, pressedKey, pressedKey, ~
	return pressedKey
}

; This returns -1 when no unit is under the cursor

getCursorUnit()
{
	p1 := readMemory(B_UnitCursor, GameIdentifier)
	p2 := readMemory(p1 + O1_UnitCursor, GameIdentifier)
	if (index := readMemory(p2 + O2_UnitCursor, GameIdentifier))
		return index >> 18
	return -1
}

getCursorUnitType(byRef unitIndex := "")
{
	if (unitIndex := getCursorUnit()) >= 0
		return getUnitType(unitIndex)
	return 0
}

/*
	Transport Structure (includes bunker too)

	Base = readmemory(getUnitAbilityPointer(unit) + 0x24)
	+ 0x0C Current state, idle (3), load, unload(259)
			Clicking one unit portrait to unload doesn't change it, nor does clicking another portrait after it finishes unloading the previous unit
			clicking (and shift+clicking) two or more does (as does unload all)
	+ 0x20 	Memory Address of the unit in the unit structure
	+ 0x28 	Currently queued/loaded unit count eg 2 marines + hellbat = 3
			This includes units queued up to be loaded.
				E.g. click medivac and shift click onto 4 marines, value = 1 (even though is empty)
				the value remains current cargo + 1 until units begin loading
				select 4 marines and then click onto medivac, value = 4 (even though is empty)
	+ 0x3c 	Total units loaded (accumulative) 4bytes
	+ 0x40 	Total units unloaded
		(current loaded units = their deltas)
	+ 0x44 	UnloadTimer	Counts down to 0 (resets and occurs for each unit being unloaded)

	static aStates := {"loading": 67 ; 3 + 64d/0x40
					, "loading": 35  ; changes just before units begin loading
					, "unloading": 259 ;  3 + 256d	} 

*/

; Returns unit count inside a transport eg 2 marines + hellbat = 3
getCargoCount(unit, byRef isUnloading := "")
{
	transportStructure := readmemory(getUnitAbilityPointer(unit) + 0x24, GameIdentifier)
	totalLoaded := readmemory(transportStructure + 0x3C, GameIdentifier)
	totalUnloaded := readmemory(transportStructure + 0x40, GameIdentifier)
	isUnloading := readmemory(transportStructure + 0x0C, GameIdentifier) = 259 
	return totalLoaded - totalUnloaded
}

isTransportUnloading(unit)
{
	transportStructure := readmemory(getUnitAbilityPointer(unit) + 0x24, GameIdentifier)
	return readmemory(transportStructure + 0x0C, GameIdentifier) = 259 ? 1 : 0
}


/*
	There is some other information within the pCurrentModel 
	for example: 
		+ 0x2C 	- Max Hp /4096 (there are two of these next to each other))
		+ 0x34 	- Total armour (unit base armour + armour upgrade) /4096
		+ 0x6C	- Current armour Upgrade
		+ 0xA0  - Total Shields /4096 (there are two of these next to each other)
		+ 0xE0 	- Shield Upgrades
		+ 		- Max energy
	
*/

getUnitMaxHp(unit)
{   global B_uStructure, Offsets_Unit_StructSize, Offsets_Unit_ModelPointer
    mp := getUnitModelPointer(unit)
    addressArray := readMemory(mp + 0xC, GameIdentifier, 4)
    pCurrentModel := readMemory(addressArray + 0x4, GameIdentifier, 4) 		
    return round(readMemory(pCurrentModel + 0x2C, GameIdentifier) / 4096)
}

getUnitMaxShield(unit)
{   global B_uStructure, Offsets_Unit_StructSize, Offsets_Unit_ModelPointer
    mp := getUnitModelPointer(unit)
    addressArray := readMemory(mp + 0xC, GameIdentifier, 4)
    pCurrentModel := readMemory(addressArray + 0x4, GameIdentifier, 4) 		
    return round(readMemory(pCurrentModel + 0xA0, GameIdentifier) / 4096)
}

getUnitCurrentHp(unit)
{
	return getUnitMaxHp(unit) - getUnitHpDamage(unit)
}
; returns 1 if something goes wrong and reads 0
getUnitPercentHP(unit)
{
	return (!percent := ((maxHP := getUnitMaxHp(unit)) - getUnitHpDamage(unit)) / maxHP) ? 1 : percent
}

getUnitPercentShield(unit)
{
	return ((maxShield := getUnitMaxShield(unit)) - getUnitShieldDamage(unit)) / maxShield
}
; will be 0 for units which dont have shields
getUnitCurrentShields(unit)
{
	return getUnitMaxShield(unit) - getUnitShieldDamage(unit)
}

getCurrentHpAndShields(unit, byRef result)
{
	global B_uStructure, Offsets_Unit_StructSize, Offsets_Unit_ModelPointer
    result := []
    mp := getUnitModelPointer(unit)
    addressArray := readMemory(mp + 0xC, GameIdentifier, 4)
    pCurrentModel := readMemory(addressArray + 0x4, GameIdentifier, 4) 		
    result.health := round(readMemory(pCurrentModel + 0x2C, GameIdentifier) / 4096) - getUnitHpDamage(unit)
    result.shields :=  round(readMemory(pCurrentModel + 0xA0, GameIdentifier) / 4096) - getUnitShieldDamage(unit)
    result.unitIndex := unit 
    return
}


; This will get the morph time for most structures e.g. CC -> orbital/PF, hatch -> lair -> Hive, spire -> G.Spire
; CommandCentre->Orbital - time remaining
; [[[[Ability Struct + 0x34] + 0x10] + 0xD4] + 0x98]
; This way is simpler than using the units queued command pointer
; Not updated/used
getStructureMorphProgress(pAbilities, unitType)
{
;	pBuildInProgress := findAbilityTypePointer(pAbilities, unitType, "BuildInProgress")
	p := pointer(GameIdentifier, findAbilityTypePointer(pAbilities, unitType, "BuildInProgress"), 0x10, 0xD4)
	timeRemaining := ReadMemory(p + 0x98, GameIdentifier)
	totalTime := ReadMemory(p + 0xB4, GameIdentifier)
	return round((totalTime - timeRemaining)/totalTime, 2)
}
; similar to getStructureBuildProgress
; Note, this also works with corruptors -> gg.lords and overlord -> overseer, but not ling -> bane or HTs -> Archon
; but if also has queued command then need to find the morphing ability
; Not updated/used
getUnitMorphTimeOld(unit)
{
	p := ReadMemory(B_uStructure + unit * Offsets_Unit_StructSize + Offsets_Unit_CommandQueuePointer, GameIdentifier)
	timeRemaining := ReadMemory(p + 0x98, GameIdentifier)
	totalTime := ReadMemory(p + 0xB4, GameIdentifier)
	return round((totalTime - timeRemaining)/totalTime, 2)
}

; If percent False returns seconds remaining
; otherwise returns % complete
; Only use on OverlordCocoon, BroodLordCocoon, Spire, Hatchery, Lair, MothershipCore, CommandCenter
; Returns percent complete or time remaining (game seconds)
getUnitMorphTime(unit, unitType, percent := True)
{
	static hasRun := False, aMorphStrings

	if !hasRun 
	{
		hasRun := True 
		aMorphStrings := { 	aUnitID.OverlordCocoon: ["MorphToOverseer"]
						 ,	aUnitID.BroodLordCocoon: ["MorphToBroodLord"]
						 ,	aUnitID.Spire: ["UpgradeToGreaterSpire"]
						 ,  aUnitID.Hatchery: ["UpgradeToLair"]
						 ,	aUnitID.Lair: ["UpgradeToHive"]
						 ,  aUnitID.MothershipCore: ["MorphToMothership"]
						 ,	aUnitID.CommandCenter: ["UpgradeToOrbital", "UpgradeToPlanetaryFortress"]}
	}
	if !getUnitQueuedCommands(unit, aCommands)
		return 0
	for i, morphString in aMorphStrings[unitType]
	{
		for index, command in aCommands
		{
			if (morphString = command["ability"]) ;  timeRaw / 65536 or 2^16
				return round(percent ? (command["timeRequired"] - command["timeRemaining"]) / command["timeRequired"] : command["timeRemaining"] / 65536, 2) 
		}
	}
	return 0
}

; Time required Raw for baneling = 20s * 65536  = 1310720
; 19s * 65536 = 1245184
; Found 4 addresses for time remaining 3 were the same and slightly higher than the 4th
; There are two differnt timing addresses which both have pointers from the MorphZerglingToBaneling ability structure
; sc 2.x p := pointer(GameIdentifier, findAbilityTypePointer(pAbilities, aUnitID.BanelingCocoon, "MorphZerglingToBaneling"), 0x12c, 0x0)
; 	totalTime := ReadMemory(p + 0x80, GameIdentifier)
;	timeRemaining := ReadMemory(p + 0x6c, GameIdentifier)

getBanelingMorphTime(pAbilities)
{
	p := pointer(GameIdentifier, findAbilityTypePointer(pAbilities, aUnitID.BanelingCocoon, "MorphZerglingToBaneling"), 0x164, 0x0)
	totalTime := ReadMemory(p + 0x80, GameIdentifier)
	timeRemaining := ReadMemory(p + 0x84, GameIdentifier)
	return round((totalTime - timeRemaining)/totalTime, 2)
}
; Merge Time = 12s = 786432
; 11s = 720896
; patch 3.0 offsets +0x10
getArchonMorphTime(pAbilities)
{
	pMergeable := readmemory(findAbilityTypePointer(pAbilities, aUnitID.Archon, "Mergeable"), GameIdentifier)
	totalTime := ReadMemory(pMergeable + 0x38, GameIdentifier)
	timeRemaining := ReadMemory(pMergeable + 0x3C, GameIdentifier) ; >> 16 to get in game seconds remaining
	return round((totalTime - timeRemaining)/totalTime, 2)
}

; In FactoryAddOns +10 is unit address of the factory

; Returns:
;	1  Complete reactor
;	-1  Complete techlab
;	0  no addons or addon in construction 
;
;	There are bytes in the addons (eg BarracksAddOns) structure which indicate an addon is under construction 
;	but not which type it is - but when an addon is underconstruction its position in the unit panel doesn't change!
;  	I don't need this info anyway.

getAddonStatus(pAbilities, unitType, byRef underConstruction := "")
{
	STATIC hasRun := False, aAddonStrings := [], aOffsets := []
	if !hasRun 
	{
		hasRun := True
		aAddonStrings := { 	aUnitID.Barracks: "BarracksAddOns"
						 ,	aUnitID.Factory: "FactoryAddOns"
						 ,	aUnitID.Starport: "StarportAddOns"}
	}
	underConstruction := False
	if aAddonStrings.HasKey(unitType)
	{
		p := readmemory(findAbilityTypePointer(pAbilities, unitType, aAddonStrings[unitType]), GameIdentifier)
		
		if readmemory(p + 0xC, GameIdentifier, 1) = 0xA3 ; 0x23 Idle
			return 0, underConstruction := True

		if readmemory(p + 0x38, GameIdentifier) ; if offset +38 or +3C not 0 addon is present techlab or reactor 
		{
			if !aOffsets.HasKey(unitType) ; ie CAbilQueue offset = aOffsets[unitType] - should be the same for all 3 types of units
				aOffsets[unitType] := Offsets_UnitAbilities_AbilityPointerIndex + 4 * getCAbilQueueIndex(pAbilities, getAbilitiesCount(pAbilities)) 
			if readmemory(readmemory(pAbilities + aOffsets[unitType], GameIdentifier) + 0x58, GameIdentifier) ; if != 0 reactor present
				return 1 ; reactor Present
			return -1 ; techlab present
		}			
	}
	return 0 ; no complete addons
}


/*
while addon is being constructed, order of buildings doesnt change

BarracksAddOns
+C = 0x63 addon under construction (the pointers below are still 0)
+28 also + 2C a pointer
If pointer not 0 then has a (fully built) reactor or techlab 

*/ 

; total build time and Time Remaining are blank if unit exists as part of the map i.e. via the mapeditor 
; I added the nydusCanal here instead of having another separate function.
; This uses the same offsets as getArchonMorphTime() i.e. total time and time remaining, and in path 

; When selecting a fully built unit it returns 1, but if unit existed as part of map (eg map editor) then it returns 0 (i guess it never executed the build ability)
getBuildProgress(pAbilities, type)
{
	static O_TotalBuildTime := 0x38, O_BuildTimeRemaining := 0x3C

	if pBuild := findAbilityTypePointer(pAbilities, type, type != aUnitID["NydusCanal"] ? "BuildInProgress" : "BuildinProgressNydusCanal")
	{
		B_Build := ReadMemory(pBuild, GameIdentifier)
		totalTime := readmemory(B_Build + O_TotalBuildTime, GameIdentifier)
		remainingTime := readmemory(B_Build + O_BuildTimeRemaining, GameIdentifier) ; >> 16 to get in game seconds remaining (/16 to get fraction of seconds)
		return round((totalTime - remainingTime) / totalTime, 2) ; 0.73
	}
	else return 1 ; something went wrong so assume its complete 
}


/*
Haven't checked other races - but currently this is only being used to for the supply cap 
warning to check if a depot is actively being built.

BuildInProgress Terran 
	+ 0xC 	= 0x123 under construction 
			= 0x1A3 when incomplete but not actively being constructed by SCV
			= 0x0A3 fully built
	+ 0x6C 	= 1 under construction  ; (this increased from 0x5C in sc 2.x)
			= 0 when incomplete but not actively being constructed by SCV
			= 0 When complete
*/

isBuildInProgressConstructionActive(pAbilities, type)
{
	if pBuild := findAbilityTypePointer(pAbilities, type, "BuildInProgress")
		return ReadMemory(ReadMemory(pBuild, GameIdentifier) + 0x6C, GameIdentifier)
	return 1 ; assume true
}


/*
Finds the buffs applied to a unit. Percent complete.

If the byref variable buffNameOrObject is an object then any current buff is stored in it and the buff count is returned (0 if none)
The object will not be blanked - so do this if required.

Otherwise buffNameOrObject can be the buff string to search for. It will return the percent Complete if found else 0

There's a fair amount of info on buffs/behaviours on SC2Mapster
And this would shed some light on some of the info/structures

Some buff strings:
	ChronoBoost
	CloakingField
	MothershipCoreApplyPurifyAB  (Photon overcharge)

 This needs more investigation and won't work for all buffs e.g. larva perhaps only timer buffs?
*/
; Hasnt been updated for SC 3.x
getUnitBuff(unit, byRef buffNameOrObject)
{
	static aBuffStringOffsets := []

	; If no buffs applied pointer = 0 - so if buff finishes this will change back to 0
	if !buffArray := ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_BuffPointer, GameIdentifier)
		return 0
	; I spent almost 0 time investigating these structures - so there should probably be more pointer checking conditions
	; and counts

	; The value at buffArray is a pointer to itself (& -2)
	; A nexus will have an innate ability at buffArray + 0x04 - haven't checked other structures. Maybe train?
	; A zealot will not have this innate ability - the first 'real'/inducible  buff will be at buffArray + 4
	; This is like a list c++ list? if A comes before B and then A expires, B moves back to position A. Like the other SC2 lists
	buffCount := 0

	;msgbox % chex(buffArray)
	; loop 20 times max as safety. In case buffs expire during read and this memory area is now used
	; for something else.
	while (p := ReadMemory(buffArray + 0x04 + 4*(A_Index-1), GameIdentifier)) && (A_Index < 20) ; 
	{
		if !baseTimer := ReadMemory(p + 0x58, GameIdentifier)
			continue
		if !p := ReadMemory(baseTimer + 0x4, GameIdentifier) & -2
			continue
		if !p := ReadMemory(p + 0x4, GameIdentifier)
			continue
		; first pointer to string/buff name
		; This is empty for the first innate nexus buff (it may be located elsewhere in this struct)
		if !p := ReadMemory(p + 0xA8, GameIdentifier) 
			continue
		aBuffStringOffsets.HasKey(p)
			? buffString := aBuffStringOffsets[p]
			: aBuffStringOffsets[p] := buffString := ReadMemory_Str(ReadMemory(p + 0x4, GameIdentifier), GameIdentifier)

		if buffString
		{
			totalTime :=  ReadMemory(baseTimer, GameIdentifier)
			, remainingTime := ReadMemory(baseTimer+ 0x10, GameIdentifier)
			, percent := round((totalTime - remainingTime) / totalTime, 2)

			if IsObject(buffNameOrObject)
				buffNameOrObject.insert(buffString, percent), buffCount++
			else if (buffNameOrObject = buffString)
				return percent			
		}	
	}
	if IsObject(buffNameOrObject)
		return buffCount ; cant use max.Index() as strings are keys
	return 0 ; Specified buff not applied/found
}



; And this only works on refinery/assimilators/extractors and town halls.
; This is the values for the little display above geysers/town halls
; unit should be unitIndex for a refinery or town hall 
getDisplayedResourceWorker(unit, player := "")
{  
    if (!p := readMemory(aSCOffsets["unitAddress", unit]+ 0x130, GameIdentifier))
    || (!p := readMemory(p + 0x16C, GameIdentifier))
    || (!p := readMemory(p + 0x2CC, GameIdentifier))
    || (!p := readMemory(p + 0x10, GameIdentifier))
        return -1 
    return readMemory(p + 0x398, GameIdentifier)
}


; To find this, load a team game replay
; put local worker in and find match value. Then send an team mates worker into the refinery and search for unchanged value
; careful not to find the value displayed above the refinery!

; Returns the workers count for refiners, extractors, assimilators, and mineral patchs.
; If units are waiting to enter the refinery before it finishes construction, it will include them as well.
; It removes mules (this is address is 0 for non terran races).
getResourceWorkerCount(unit, player)
{  
  
    if !p := readMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_BuffPointer, GameIdentifier) ; i think buff pointer is 0x100 patch 3.0.3
        return -1
    p := readMemory(p+0x4, GameIdentifier)
    if !p := readMemory(p+0x6C, GameIdentifier) ; 0x78 pre sc 3.x
        return -1
    ; There is an array of slots here. Each slot has that owners worker count for this resource
    ; Allies with shared control can harvest from refinery too or anyone from a mineral patch
    ; So to get the true total amount of workers, you should loop all positions and sum them
    ; But we would only want local player       
   	workers := readmemory(p + player*0x4, GameIdentifier)
   	mules := readmemory(p + 0x40 + player*0x4, GameIdentifier)
    return workers - mules
}

/*
Not used/updated
; Returns amount of resource left in a refinery/extractor/assimilator/geyser/mineral patch 
getRemainingResourceCount(unit)
{
    if !p := readMemory( B_uStructure + unit * Offsets_Unit_StructSize + Offsets_Unit_BuffPointer, GameIdentifier)
        return -1
    p := readMemory(p + 0x4, GameIdentifier)
    return readMemory(p + 0x50, GameIdentifier)
}

*/

; This seems to work for hatches, lairs and hives even when building/researching
getTownHallLarvaCount(unit)
{
	if !buffArray := ReadMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_BuffPointer, GameIdentifier) ; 0x100
		return 0
	if !p := ReadMemory(buffArray + 0x8, GameIdentifier)
		return 0
	; This structure also contains the addresses of the larva
	; At +0x68 is a pointer to an array which stores the unit indexes for the spawned larva (indexes must be >> 18)
	; If the larva is morphed to an egg, then these may point to the egg, but will be replaced when a new larva spawns
	; so is not useful in finding unit production associated with a hatch
	; Note. Re-found this value using CE, not sure if same structure - offsets were similar
	return ReadMemory(p + 0x6C, GameIdentifier)
}

; PO lasts 20s, 60 x 65536 = 3932160
; 59s = 3866624


; Unit must be a nexus else function returns 'true' due to readMemory returning "Fail"
isPhotonOverChargeActive(unit)
{	
	; attackProtossBuilding structure + 0x64 - 1 Active 0 not.
	; Correctly returns 0 For nexus under construction as well (as they will have the same ability structure/addresses).
	; Check if = 1, in case something went wrong - but it shouldn't if calling for a nexus. 
	return 1 = ReadMemory(ReadMemory(findAbilityTypePointer(getUnitAbilityPointer(unit), aUnitID["Nexus"], "attackProtossBuilding"), GameIdentifier) + 0x64, GameIdentifier)
}

getPhotonOverChargeProgress(unit)
{
	p := readMemory(aSCOffsets["unitAddress", unit] + Offsets_Unit_BuffPointer, GameIdentifier)
	if !p := readMemory(p + 0x8, GameIdentifier) ; not active
		return 0 
	struct := readMemory(p + 0x6C, GameIdentifier)
	, totalTime :=  ReadMemory(struct, GameIdentifier)
	, remainingTime := ReadMemory(struct + 0x10, GameIdentifier)
	return round((totalTime - remainingTime) / totalTime, 2)
}


unitIndexFromAddress(address)
{
	return (address - B_uStructure) / Offsets_Unit_StructSize
}

getUnitTargetFilterString(unit)
{
	targetFilter := getUnitTargetFilter(unit)
	for k, v in aUnitTargetFilter
		v & targetFilter ? s .= (s ? "`n" : "") k
	return s
}

; This is used for finding certain offsets.
; Specifically where two uInts reside next to each other.
; It returns the 8 byte value (generated if you were to read them as an 8 byte value) 
; which you can search for in CE
; If the 8 byte value is >= 0x8000000000000000 the returned value will be incorrect as AHK doesn't support
; large uInt64s
twoUIntAsUint64(uInt1, uInt2 := "")
{
	if (uInt2 = "")
		uInt2 := uInt1
	VarSetCapacity(address, 8, 0)
	NumPut(uInt1, address, 0, "UInt")
	NumPut(uInt2, address, 4, "UInt")
	return numget(address, 0, "UInt64")
}
twoBoolsAsShort(bool1, bool2 := "")
{
	if (bool2 = "")
		bool2 := bool1
	VarSetCapacity(address, 2, 0)
	NumPut(bool1, address, 0, "Char")
	NumPut(bool2, address, 1, "Char")
	return numget(address, 0, "Short")
}
twoShortsAsInt(short1, short2 := "")
{
	if (short2 = "")
		short2 := short1
	VarSetCapacity(address, 4, 0)
	NumPut(short1, address, 0, "Short")
	NumPut(short2, address, 2, "Short")
	return numget(address, 0, "UInt")
}

debug(text, byRef newHeader := 0)
{
	FileAppend, % (newHeader != 0 ? newHeader : A_Min ":" A_Sec " - ") text "`n", *
	return
}

log(text, logFile := "log.txt")
{
	FileAppend, %text%`n, %logFile%
	return 
}

; Convert the specified number of seconds to h:m:s format.
; removes leading 0's and ':'
; seconds is not zero padded when 0 hours and 0 minutes
; 9 seconds = 9
; 61 second = 1:01
formatSeconds(seconds)  
{
	seconds := ceil(seconds) 
    time = 19990101  ; *Midnight* of an arbitrary date.
    time += %seconds%, seconds
    FormatTime, mss, %time%, m:ss
    return lTrim(seconds//3600 ":" mss, "0:") 
}

gameToRealSeconds(gameSeconds)
{
	static aFactor := { Slower: 1.66
					,	Slow: 1.25
					,	Normal: 1.00
					,	Fast: .8275
					,	Faster: .725 }
	return  gameSeconds * aFactor[getGameSpeed()]
}
; It would be much simpler to use the ' Gui MiniMapOverlay:+LastFoundExist' and  'IfWinNotExist'
; rather than tracking drawing states in a variable. But this seems to work fine and I cbf changing it.

modifyOverlay(overlay, byRef Redraw, byRef overlayCreated, byRef Drag, byRef DragPrevious, byRef x, byRef y, w, h, byRef hwnd1)
{
	If (Redraw = -1)
	{
		Try Gui, %overlay%: Destroy
		overlayCreated := False
		Redraw := 0
		Return 0
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, %overlay%: Destroy
		overlayCreated := False
		Redraw := 0
	}
	If (!overlayCreated)
	{
		; Create a layered window ;E0x20 click thru (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
		; Disable DPI scaling, as this can result in overlays not showing when the calling updatelayeredwindow() without W/h values as wingetPos returns values larger than those used in createDIBSection()
		Gui, %overlay%: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop -DPIScale
		Gui, %overlay%: Show, NA X%x% Y%y% W%w% H%h%, % aOverlayTitles[overlay]
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		overlayCreated := True
	}	
	If (Drag AND !DragPrevious)
	{	
		DragPrevious := 1
		Gui, %overlay%: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	
		DragPrevious := 0
		Gui, %overlay%: +E0x20 +LastFound
		WinGetPos, x, y		
		IniWrite, %x%, %config_file%, Overlays, %overlay%X
		Iniwrite, %y%, %config_file%, Overlays, %overlay%Y
	}
	return 1
}

; returns the Game path. Blank if file doesn't exist
; e.g.	C:\Games\StarCraft II\StarCraft II.exe
StarcraftExePath()
{
	if A_Is64bitOS
		RegRead, GamePath, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Blizzard Entertainment\StarCraft II Retail, GamePath
	else 
		RegRead, GamePath, HKEY_LOCAL_MACHINE, SOFTWARE\Blizzard Entertainment\StarCraft II Retail, GamePath
	; Im not sure if my SC install is corrupted now, after a reinstall or more likely due to the new battle.net launcher
	; The above registry key is no longer written. 
	if !FileExist(GamePath)
		GamePath := StarcraftInstallPath() "\" "StarCraft II.exe"
	return FileExist(GamePath) ? GamePath : ""
}

switcherExePath()
{
	return (installPath := StarcraftInstallPath()) && FileExist(switcherPath := RTrim(installPath, "\") "\Support\SC2Switcher.exe") ? switcherPath : ""		
}
; returns the Install path
; e.g.	C:\Games\StarCraft II
; if doesnt exist returns blank
StarcraftInstallPath()
{
	; This key may no longer be valid/set when installing SC....or my install is just corrupted, try using the windows uninstall path
	wowNode := A_Is64bitOS ? "Wow6432Node\" : ""
	RegRead, SC2InstallPath, HKEY_LOCAL_MACHINE, SOFTWARE\%wowNode%Blizzard Entertainment\StarCraft II Retail, InstallPath ; I think this has a final backslash (cant test now)
	if (SC2InstallPath = "" || !InStr(FileExist(SC2InstallPath), "D")) ; Try to read the Windows uninstall path e.g. C:\Games\StarCraft II\StarCraft II
		RegRead, SC2InstallPath, HKEY_LOCAL_MACHINE, SOFTWARE\%wowNode%Microsoft\Windows\CurrentVersion\Uninstall\StarCraft II, InstallLocation ; C:\Games\StarCraft II - no backslash
	if strlen(SC2InstallPath) > 3 ; i.e. not c:\  ...Not that anyone would ever install it in root
		SC2InstallPath := RTrim(SC2InstallPath, "\")
	return InStr(FileExist(SC2InstallPath), "D") ? SC2InstallPath : ""
}

; portrait numbers begin at 0 i.e. first page contains portraits 0-23
; clickTabPage is the real tab number ! its not off by 1! i.e. tab 1 = 1

; You can have a max of 6 pages 1-6. 
; This function will stuff up if unit portraits higher than 144 units are called. 
; So always check the units portrait location before calling

ClickUnitPortrait(SelectionIndex=0, byref X=0, byref Y=0, byref Xpage=0, byref Ypage=0, ClickPageTab = 0, setSize := False) 
{
	static Xu0, Yu0, Size, Xpage1, Ypage1, Ypage6, YpageDistance

	if setSize
	{
		AspectRatio := g_aGameWindow.AspectRatio
		, Wclient := g_aGameWindow.Width
		, Hclient := g_aGameWindow.Height

		if g_aGameWindow.style = "Windowed"
		{
			; mouse clients are relative to the games client area (so need to subtract borders)
			minLength := Hclient > Wclient ? Wclient : Hclient
			, Size := floor((48/957)*minLength) ; 49
			; Regardless of client width and height, the 6th column always occurs at the centre of the game window
			; i.e. it's a fixed position

			; subtracting borders/caption in the manner, as I didn't account for the fact that AHKs mousegetpos
			; returns coordinates which include these edges and therefore all the testing was done with calculations
			; that include these borders and then remove them at the end.
			, Xu0 := (Wclient//2) - 5*Size + .25*Size - g_aGameWindow.leftFrameWidth, Yu0 := (697/851)*Hclient + size/2 - g_aGameWindow.topFrameHeight
			, Xpage1 := Xu0 - .75*size, Ypage1 := Yu0 - size//7
			, Ypage6 := Ypage1 + 2.5*size
		}
		else If (AspectRatio = "16:10")
		{
			Xu0 := (578/1680)*Wclient, Yu0 := (888/1050)*Hclient	;X,Yu0 = the middle of unit portrait 0 ( the top left unit)
			Size := (56/1680)*Wclient										;the unit portrait is square 56x56
			Xpage1 := (528/1680)*Wclient, Ypage1 := (877/1050)*Hclient, Ypage6 := (1016/1050)*Hclient	;Xpage1 & Ypage6 are locations of the Portrait Page numbers 1-5 
		}	
		Else If (AspectRatio = "5:4")
		{	
			Xu0 := (400/1280)*Wclient, Yu0 := (876/1024)*Hclient
			Size := (51.57/1280)*Wclient
			Xpage1 := (352/1280)*Wclient, Ypage1 := (864/1024)*Hclient, Ypage6 := (992/1024)*Hclient
		}	
		Else If (AspectRatio = "4:3")
		{	
			Xu0 := (400/1280)*Wclient, Yu0 := (812/960)*Hclient
			Size := (51.14/1280)*Wclient
			Xpage1 := (350/1280)*Wclient, Ypage1 := (800/960)*Hclient, Ypage6 := (928/960)*Hclient
		}
		; If the screen resolution is > game, the game will still probably be running in this aspect ratio (as it will look the best)
		; It will just not take up the entire screen (assume positioned top left 0,0)
		Else ;if (AspectRatio = "16:9") 
		{
			Xu0 := (692/1920)*Wclient, Yu0 := (916/1080)*Hclient
			Size := (57/1920)*Wclient	;its square
			Xpage1 := (638/1920)*Wclient, Ypage1 := (901/1080)*Hclient, Ypage6 := (1044/1080)*Hclient
		}

		YpageDistance := (Ypage6 - Ypage1)/5		;because there are 6 pages - 6-1
	}

	if ClickPageTab	;use this to return the selection back to a specified page
	{
		PageIndex := ClickPageTab - 1
		Xpage := Xpage1, Ypage := Ypage1 + (PageIndex * YpageDistance)
		return 1
	}

	; You can have a max of 6 pages 1-6. 
	; This function will stuff up if unit portraits higher than 144 units are called. 
	; So always check the units portrait location before calling
	PageIndex := floor(SelectionIndex / 24)
	, SelectionIndex -= 24 * PageIndex
	, Offset_y := floor(SelectionIndex / 8) 
	, Offset_x := SelectionIndex -= 8 * Offset_y		
	, x := Xu0 + (Offset_x *Size), Y := Yu0 + (Offset_y *Size)

	; A delay may be required for selection page to update
	; could use an overide value - but not sure if the click would register
	if (PageIndex != getUnitSelectionPage())
	{
		Xpage := Xpage1, Ypage := Ypage1 + (PageIndex * YpageDistance)
		return 1 ; indicating that you must left click the index page first
	}
	return 0	
}


/*
Command card has 3 rows with 5 buttons each
Top left button is 0 
next button on right is 1
bottom right button is 14
This function returns the x, y co-ordinates for the specific command card button.
*/
clickCommandCard(position, byRef x, byRef y, setSize := False)
{
	static X0, y0, width, height

	if setSize
	{
		AspectRatio := g_aGameWindow.AspectRatio
		, Wclient := g_aGameWindow.Width
		, Hclient := g_aGameWindow.Height
		if g_aGameWindow.style = "Windowed"
		{
			; mouse clients are relative to the games client area (so need to subtract borders)
			Wclient -= g_aGameWindow.leftFrameWidth
			Hclient -= g_aGameWindow.topFrameHeight
			width := height := (53/878) * (Hclient > Wclient ? Wclient : Hclient)
			, finalX := Wclient-87,	finalY := Hclient-25
			, X0 := finalX - 4 * width, Y0 := finalY - 2 * width
		}
		else If (AspectRatio = "16:10")
		{
			X0 := (1314/1680)*Wclient, y0 := (893/1050)*Hclient		
			width := (65/1680)*Wclient, height := (66/1050)*Hclient										
		}	
		Else If (AspectRatio = "5:4")
		{	
			X0 := (944/1280)*Wclient, y0 := (880/1024)*Hclient
			width := (61/1280)*Wclient, height := (60/1024)*Hclient	
		}	
		Else If (AspectRatio = "4:3")
		{	
			X0 := (944/1280)*Wclient, y0 := (815/960)*Hclient
			width := (61/1280)*Wclient, height := (61/960)*Hclient	
		}
		; If the screen resolution is > game, the game will still probably be running in this aspect ratio (as it will look the best)
		; It will just not take up the entire screen (assume positioned top left 0,0)		
		Else ;if (AspectRatio = "16:9")
		{
			X0 := (1542/1920)*Wclient, y0 := (916/1080)*Hclient
			width := (68/1920)*Wclient, height := (69/1080)*Hclient	
		}
	}
	row := floor(position/5)
	, column := floor(position - 5 * row)
	, x := X0 + (column * width) + (width//2)
	, y := y0 + (row * height - height//2)
	return
}


/*
 for units on top of each other clicking the same border edge location twice will unload 1, then the other
 this is not true for units horizontally next to each other
 The portraits are close enough to being square for all resolutions
*/

getCargoPos(position, byRef xPos, byRef yPos, setSize := False)
{
	static x, y, width
	if setSize
	{
		AspectRatio := g_aGameWindow.AspectRatio
		, Wclient := g_aGameWindow.Width
		, Hclient := g_aGameWindow.Height

		if  g_aGameWindow.style = "Windowed"
		{
			minLength := Hclient > Wclient ? Wclient : Hclient
			, width := floor((48/957)*minLength)
			, x := round(Wclient*.455) - g_aGameWindow.leftFrameWidth
			, y := round(Hclient*.9) - g_aGameWindow.topFrameHeight
		}
		else If (AspectRatio = "16:10")
			x := (760/1680)*Wclient, y := (937/1050)*Hclient, width := 56  ; h := 55 
		else If (AspectRatio = "5:4")
			x := (575/1280)*Wclient, y := (926/1024)*Hclient, width := 50  ; h := 50 
		else If (AspectRatio = "4:3")	
			x := (575/1280)*Wclient, y := (861/960)*Hclient, width := 51  ; h := 50 close enough to being square
		else if (AspectRatio = "16:9")
			x := (887/1920)*Wclient, y := (967/1080)*Hclient, width := 57 ; h = 56 close enough to being square
	}
	column := floor(position/2)
 	, row := floor(position - 2 * column)
	, xPos := x + (column * width)
	, yPos := y + (row * width)
}




; Gives the co-ordinates for the ping icon/toolbar (so don't have to worry about differ user SC hotkeys)
getMiniMapPingIconPos(byref xPos, byref yPos)
{
	static AspectRatio, x, y, supported := True

	if (AspectRatio != newAspectRatio := getClientAspectRatio(Xclient, Yclient, Wclient, Hclient))
	{
		AspectRatio := newAspectRatio
		If (AspectRatio = "16:10")
			x := (319/1680)*A_ScreenWidth, y := (830/1050)*A_ScreenHeight										
		Else If (AspectRatio = "5:4")
			x := (292/1280)*A_ScreenWidth, y := (823/1024)*A_ScreenHeight
		Else If (AspectRatio = "4:3")	
			x := (291/1280)*A_ScreenWidth, y := (759/960)*A_ScreenHeight
		; If the screen resolution is > game, the game will still probably be running in this aspect ratio (as it will look the best)
		; It will just not take up the entire screen (assume positioned top left 0,0)
		Else ;if (AspectRatio = "16:9")
			x := (328/1920)*Wclient, y := (854/1080)*Hclient
		;else supported := false 
	}
	if supported
		return true, xPos := x, yPos := y
	else return false, xPos := yPos := "" 
}

getClientAspectRatio(byRef x := "", byRef y := "", byRef w := "", byRef h := "", byRef trueAspectRatio := "")
{ 	
	; winGetPos only takes ~ 0.047 ms
	WinGetPos, x, y, w, h, %GameIdentifier%
	if (w = "") ; client window doesn't exist
		w := A_ScreenWidth, h := A_ScreenHeight, x := y := 0
	;ROUND as this should group 1366x768 (1.7786458333) in with 16:9
	trueAspectRatio := AspectRatio := Round(w / h, 2)
	if ( AspectRatio = Round(1680/1050, 2)) 	; 1.6
		AspectRatio := "16:10"
	else if (AspectRatio = Round(1920/1080, 2)) ; 1.78s
		AspectRatio := "16:9"
	else if (AspectRatio = Round(1280/1024, 2)) ; 1.25
		AspectRatio := "5:4"
	else if (AspectRatio = Round(1600/1200, 2)) ; 1.33
		AspectRatio := "4:3"
	return AspectRatio, pX := x, pY := y, pW := w, pH := h
}

; Converts the olldbg plugin scanner output to a string compatible with my scanner
sigConverterOlly(sig, mask, storeInClip := True)
{
	sig := trim(sig, A_Space A_Tab "\") ; "sig starts with \"
	mask := trim(mask, A_Space A_Tab)
	StringReplace, sig, sig, x, 0x, All
	aSig := StrSplit(sig, "\")
	loop, parse, mask
		r .= (A_LoopField != "?" ? aSig[A_Index] : """?""") ", "
	return storeInClip ? clipboard := substr(r, 1, -2) : substr(r, 1, -2) 
}

; Sig must be in standard CE hex format i.e. without '0x' prefix and spaces to delimit bytes
; e.g. 89 4F 18 F7 D0 33 86 ?? ?? ?? ?? 8B C8 C1 E9 10 8B D0
SigConverterCE(sig := "", storeInClip := True)
{
	for i, v in strsplit(trim(sig, A_Space A_Tab), A_Space)
		r .= (RegExMatch(v, "i)^[0-9a-f]+") ? "0x" v : """?""") ", "
	return storeInClip ? clipboard := RTrim(r, ", ") : RTrim(r, ", ")
}



hasShields(unitId)
{
	static aUnitLookup 
	if !isobject(aUnitLookup)
	{
		aUnitLookup := []
		s := "Colossus|Mothership|Nexus|Pylon|Assimilator|Gateway|Forge|FleetBeacon|TwilightCouncil|PhotonCannon|Stargate|TemplarArchive|DarkShrine|RoboticsBay|RoboticsFacility|CyberneticsCore|Zealot|Stalker|HighTemplar|DarkTemplar|Sentry|Phoenix|Carrier|VoidRay|WarpPrism|Observer|Immortal|Probe|Interceptor|WarpGate|WarpPrismPhasing|Archon|MothershipCore|Oracle|Tempest"
		loop, parse, s, |
			aUnitLookup[aUnitID[A_LoopField]] := True
	}
	return aUnitLookup.HasKey(unitId)
}



; Pointer to a an array of town halls (completed and landed) in dynamic memory ["SC2.exe"+03FC53E4]+0
; an array of town hall unit indexes (just search for the town halls finger prints as an AOB) (note: The static arrays are actually the control group which you are storing them in)
; This will only contain town halls which are accessible via the backspace camera
; The town hall camera uses a static variable to cycle through them (zero based)
; Note: The camera will still jump to a town hall which is actively lifting. It is removed from the 
; structure when it completes the lift action.


; **** These addresses are not zeroed after a game
; and the values remain until a new townHall overwrites the old one
; Since unit Index reuse count (ie part which forms the finger print) is zeroed at the start of a game
; you cannot check if fingerprints match and if unit is still alive (unless you also do a unit type/player race check)
; as its possible for the finger print to match i.e. same unit Index and same index reuse count (eg 0)
; Only safe way is to use getPlayerBaseCameraCount()
; Wrong!!! cant use getPlayerBaseCameraCount() as it seems when lifted the structure doesn't completely realign
; so the lifted cc is still included - probably the same for dead ones. 
/*
getCameraTownHalls(byRef aTownHalls := "")
{
	aTownHalls := []
	if baseCount := getPlayerBaseCameraCount()
		ReadRawMemory(ReadMemory(*x***x*, GameIdentifier), GameIdentifier, buffer, 4 * baseCount) ; no one is every going to have more than 100
	loop, % baseCount
		fingerPrint := NumGet(buffer, (A_Index-1) * 4, "UInt"), aTownHalls[fingerPrint] :=  fingerPrint >> 18
	return round(baseCount)
}
*/


iniReadUpgradeAlerts()
{
	IniRead, objString, %config_file%, Upgrade Alerts, Alerts, %A_Space% ; Could replace this with a default obj string
	if !isobject(obj := serDes(objString))
		obj := []
	obj.Remove("parentLookUp"),	obj.Remove("alertLookUp") ; these shouldnt be in the obj anyway
	for i, gameType in ["1v1", "2v2", "3v3", "4v4"]
	{
		for key, alert in obj[gameType]
		{
			obj["parentLookUp", gameType, aUnitID[upgradeDefinitions.BuildingFromUpgrade(alert.upgradeGameTitle)]] := True
			, obj["alertLookUp", gameType, alert.upgradeGameTitle] := key
		}
	}	
	return obj	
}


class upgradeDefinitions
{
	static aUpgradeUserTitle := { Terran: { StarportTechLab: {ResearchBansheeCloak: "CloakingField", ResearchMedivacEnergyUpgrade: "CaduceusReactor", ResearchDurableMaterials: "DurableMaterials", ResearchRavenEnergyUpgrade: "CorvidReactor"}
									, FusionCore: {ResearchBattlecruiserEnergyUpgrade: "BehemothReactor", ResearchBattlecruiserSpecializations: "WeaponRefit"}
									, GhostAcademy: {ResearchPersonalCloaking: "PersonalCloaking"} ;, ResearchGhostEnergyUpgrade: ""
									, BarracksTechLab: {ResearchShieldWall: "CombatShield", Stimpack: "Stimpack", ResearchPunisherGrenades: "ConcussiveShells"}
									, FactoryTechLab: {ResearchDrillClaws: "DrillingClaws", ResearchHighCapacityBarrels: "InfernalPre-Igniter"} ;, ;ResearchTransformationServos: ""
									, Armory: { TerranVehicleAndShipPlatingLevel1: "VehicleAndShipPlatingLevel1", TerranVehicleAndShipPlatingLevel2: "VehicleAndShipPlatingLevel2", TerranVehicleAndShipPlatingLevel3: "VehicleAndShipPlatingLevel3", TerranVehicleAndShipWeaponsLevel1: "VehicleAndShipWeaponsLevel1", TerranVehicleAndShipWeaponsLevel2: "VehicleAndShipWeaponsLevel2", TerranVehicleAndShipWeaponsLevel3: "VehicleAndShipWeaponsLevel3"} ;, TerranVehicleWeaponsLevel1: "";, TerranVehicleWeaponsLevel2: "";, TerranVehicleWeaponsLevel3: "";, TerranShipWeaponsLevel1: "";, TerranShipWeaponsLevel2: "";, TerranShipWeaponsLevel3: ""
									, EngineeringBay: {TerranInfantryArmorLevel1: "InfantryArmorLevel1", TerranInfantryArmorLevel2: "InfantryArmorLevel2", TerranInfantryArmorLevel3: "InfantryArmorLevel3", TerranInfantryWeaponsLevel1: "InfantryWeaponsLevel1", TerranInfantryWeaponsLevel2: "InfantryWeaponsLevel2", TerranInfantryWeaponsLevel3: "InfantryWeaponsLevel3", ResearchNeosteelFrame: "NeosteelFrame", ResearchHiSecAutoTracking: "Hi-SecAutoTracking", UpgradeBuildingArmorLevel1: "StructureArmor"}}						
						, Protoss:	{ FleetBeacon: {PhoenixRangeUpgrade: "AnionPulse-Crystals", ResearchInterceptorLaunchSpeedUpgrade: "GravitonCatapult"}
									, Forge: {ProtossGroundWeaponsLevel1: "GroundWeaponsLevel1", ProtossGroundWeaponsLevel2: "GroundWeaponsLevel2", ProtossGroundWeaponsLevel3: "GroundWeaponsLevel3", ProtossGroundArmorLevel1: "GroundArmorLevel1", ProtossGroundArmorLevel2: "GroundArmorLevel2", ProtossGroundArmorLevel3: "GroundArmorLevel3", ProtossShieldsLevel1: "ShieldsLevel1", ProtossShieldsLevel2: "ShieldsLevel2", ProtossShieldsLevel3: "ShieldsLevel3"}
									, RoboticsBay: {ResearchExtendedThermalLance: "ExtendedThermalLance", ResearchGraviticBooster: "GraviticBoosters", ResearchGraviticDrive: "GraviticDrive"}
									, TemplarArchive: {ResearchPsiStorm: "PsionicStorm"}
									, MothershipCore: {MorphToMothership: "UpgradeToMothership"}
									, CyberneticsCore: {ResearchWarpGate: "WarpGate", ProtossAirWeaponsLevel1: "AirWeaponsLevel1", ProtossAirWeaponsLevel2: "AirWeaponsLevel2", ProtossAirWeaponsLevel3: "AirWeaponsLevel3", ProtossAirArmorLevel1: "AirArmorLevel1", ProtossAirArmorLevel2: "AirArmorLevel2", ProtossAirArmorLevel3: "AirArmorLevel3"}
									, TwilightCouncil: {ResearchCharge: "Charge", ResearchStalkerTeleport: "Blink"}}
						, Zerg:	{BanelingNest: {EvolveCentrificalHooks: "CentrifugalHooks"}
									, InfestationPit: {EvolveInfestorEnergyUpgrade: "PathogenGlands", ResearchNeuralParasite: "NeuralParasite", EvolveFlyingLocusts: "FlyingLocusts"} ;, ResearchLocustLifetimeIncrease: ""
									, UltraliskCavern: {EvolveChitinousPlating: "ChitinousPlating"}
									, RoachWarren: {EvolveGlialRegeneration: "GlialReconstitution", EvolveTunnelingClaws: "TunnelingClaws"}
									, Hatchery: {overlordspeed: "PneumatizedCarapace", ResearchBurrow: "Burrow", UpgradeToLair: "MutateLair"}
									, Lair: {overlordspeed: "PneumatizedCarapace", ResearchBurrow: "Burrow", EvolveVentralSacks: "VentralSacks", UpgradeToHive: "MutateHive"}									
									, Hive: {overlordspeed: "PneumatizedCarapace", ResearchBurrow: "Burrow", EvolveVentralSacks: "VentralSacks"}
									, HydraliskDen: {hydraliskspeed: "GroovedSpines", MuscularAugments: "MuscularAugments"}
									, SpawningPool: {zerglingmovementspeed: "MetabolicBoost", zerglingattackspeed: "AdrenalGlands"}
									, Spire: {zergflyerarmor1: "FlyerCarapaceLevel1", zergflyerarmor2: "FlyerCarapaceLevel2", zergflyerarmor3: "FlyerCarapaceLevel3", zergflyerattack1: "FlyerAttacksLevel1", zergflyerattack2: "FlyerAttacksLevel2", zergflyerattack3: "FlyerAttacksLevel3", UpgradeToGreaterSpire: "MutateGreaterSpire"}
									, GreaterSpire: {zergflyerarmor1: "FlyerCarapaceLevel1", zergflyerarmor2: "FlyerCarapaceLevel2", zergflyerarmor3: "FlyerCarapaceLevel3", zergflyerattack1: "FlyerAttacksLevel1", zergflyerattack2: "FlyerAttacksLevel2", zergflyerattack3: "FlyerAttacksLevel3"}
									, EvolutionChamber: {zerggroundarmor1: "GroundCarapaceLevel1", zerggroundarmor2: "GroundCarapaceLevel2", zerggroundarmor3: "GroundCarapaceLevel3", zergmeleeweapons1: "MeleeAttacksLevel1", zergmeleeweapons2: "MeleeAttacksLevel2", zergmeleeweapons3: "MeleeAttacksLevel3", zergmissileweapons1: "MissileAttacksLevel1", zergmissileweapons2: "MissileAttacksLevel2", zergmissileweapons3: "MissileAttacksLevel3" }}}
	static _ahack := upgradeDefinitions.initialiseVars()

	initialiseVars()
	{
		this._aUserTitles := []
		this._aGameTitles := []
		this._aUpgradeToStructure := []
		this._aUpgradesFromBuilding := []
		this._aStructuresFromRace := []
		for race, obj in this.aUpgradeUserTitle
		{
			this._aStructuresFromRace[race] := []
			for structure, upgrades in obj
			{
				this._aStructuresFromRace[race].insert(structure)
				this._aUpgradesFromBuilding[structure] := []
				for gameTitle, commonTitle in upgrades
				{
					this._aGameTitles[commonTitle] := gameTitle
					this._aUserTitles[gameTitle] := commonTitle
					this._aUpgradeToStructure[gameTitle] := structure
					this._aUpgradesFromBuilding[structure].insert(gameTitle)
				}
			}
		}
		return		
	}
	upgradeGameTitle(userTitle)
	{
		return this._aGameTitles[userTitle]
	}
	upgradeUserTitle(gameTitle)
	{
		return this._aUserTitles[gameTitle]
	}
	BuildingFromUpgrade(upgrade)
	{
		return this._aUpgradeToStructure[upgrade]
	}
	; returns an array of upgrades available from a structure	
	upgradesFromBuilding(structure)
	{
		return this._aUpgradesFromBuilding[structure]
	}
	; Returns an array of structures 
	structuresFromRace(race)
	{
		return this._aStructuresFromRace[race]
	}
}
; 4 byte ints listed in memory: 808 28 1066 290  (at 1920x1080)
; an 8 byte value 4578435137564 (first two ints)
; These are the coordinates of the minimap UI borders
; relative to the SC client area (doesn't include the SC window frame)

; ***Note: SC memory has left position as 28, but this isn't clickable in SC (it's part of the border overlay)
; so need to +1 to the returned value!!!!
; The right edge is stored as 290, but it is really 289 (-1)
; *** note about minimap size and input
; the left and right locations are reported by minimapLocation()/memory do not match where you can click on the minimap.
; left+1 and right-1 are the bounds for the clickable margins!

minimapLocation(byRef left, byRef right, byRef bottom, byRef top)
{
	static 	o_Top := 0x1C, o_left := 0x20, o_Bottom := 0x24, o_Right := 0x28
	p := pointer(GameIdentifier, P_MinimapPosition, O_MinimapPosition*)
	, left := ReadMemory(p + o_left, GameIdentifier)
	, right := ReadMemory(p + o_Right, GameIdentifier)
	, bottom := ReadMemory(p + o_Bottom, GameIdentifier)
	, top := ReadMemory(p + o_Top, GameIdentifier)
	return 
}

; There are two sets of coordiantes, one directly after the other. I have not observed any differences between the two.
; However, two users (German and Chinese) reported that the minimap isn't aligned correctly.
; I was previously using the minimap top value from the second set of values (the rest was from the first)
minimapLocationDebug()
{
	static 	o_Top := 0x1C, o_left := 0x20, o_Bottom := 0x24, o_Right := 0x28

	p := pointer(GameIdentifier, P_MinimapPosition, O_MinimapPosition*)
	, left := ReadMemory(p + o_left, GameIdentifier)
	, right := ReadMemory(p + o_Right, GameIdentifier)
	, bottom := ReadMemory(p + o_Bottom, GameIdentifier)
	, top := ReadMemory(p + o_Top, GameIdentifier)
	, left2 := ReadMemory(p + 0x10 + o_left, GameIdentifier)
	, right2 := ReadMemory(p + 0x10 + o_Right, GameIdentifier)
	, bottom2 := ReadMemory(p + 0x10 + o_Bottom, GameIdentifier)
	, top2 := ReadMemory(p  + 0x10 + o_Top, GameIdentifier) ; Can be different Forbidden sanctuary 

	return "Left: " left "`nRight: " right "`nBottom: " bottom "`nTop: " top "`n"
		.  "Left2: " left2 "`nRight2: " right2 "`nBottom2: " bottom2 "`nTop2: " top2 "`n"
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

GameWindowStyle()
{
	style := WinGet("EXStyle", GameIdentifier)
	if (style = 0x00040000)
		return "WindowedFullScreen"
	else if (style = 0x00040008) 
		return "FullScreen"
	else if (style = 0x00040100) 
		return "Windowed"
	else return style
}	


systemWindowEdgeSize(byRef leftAndRightBorder := "", byref topBorder := "", byRef BottomBorder  := "")
{
	; SM_CXSIZEFRAME, SM_CYSIZEFRAME: Thickness of the sizing border around the perimeter of a window 
	; that can be resized, in pixels. SM_CXSIZEFRAME is the width of the horizontal border, 
	; and SM_CYSIZEFRAME is the height of the vertical border. 
	; Synonymous with SM_CXFRAME and SM_CYFRAME.
	
	; SM_CYCAPTION: Height of a caption area, in pixels.

	SysGet, widthSizeFrame, 32 ; SM_CXSIZEFRAME
	SysGet, heightSizeFrame, 33 ; SM_CYSIZEFRAME
	SysGet, captionHeight, 4 ; SM_CYCAPTION

	leftAndRightBorder := widthSizeFrame
	, topBorder := heightSizeFrame + captionHeight
	, BottomBorder := heightSizeFrame
	return 
}


iniReadAutoBuildQuota()
{
	global aAutoBuildQuota
	IniRead, string, %config_file%, AutoBuild, Quota, %A_space%
	if !isobject(aAutoBuildQuota := SerDes(string))
	{
		aAutoBuildQuota := []
		for i, raceObj in autoBuild.getProducibleUnits()
		{
			for j, unitName in raceObj
				aAutoBuildQuota[unitName] := -1
		}			
	}
	return 
}

HiWord(number)
{
	if (number & 0x80000000)
		return (number >> 16)
	return (number >> 16) & 0xffff	
}	
; returns rotation count. Downward rotations are -negative numbers
mouseWheelRotations(wParam)
{
	return wParam > 0x7FFFFFFF ? HiWord(-(~wParam)-1)/120 :  HiWord(wParam)/120 ;get the higher order word & /120 = number of rotations
}





dumpUnitTypes(byRef outputString)
{
	outputString := ""
	mem := new _ClassMemory(GameIdentifier) 
	mp := getunitmodelpointer(0)
	byte1 := mem.read(mp, "Char")
	byte2 := mem.read(mp+1, "Char")
	byte3 := mem.read(mp+2, "Char")
	byte4 := mem.read(mp+3, "Char")
	
	excludeNamesContaining = 
	( join, Comments ltrim
	ACGluescreenDummy
	##id##
	DestructibleCityDebris
	CollapsibleTerranTower
	XelNaga_Caverns_
	ExtendingBridge
	DestructibleRock
	UnbuildablePlates
	CollapsibleRockTower
	DebrisRamp
	Shape
	Destructible
	)
	excludeNames = 
	( join, Comments ltrim
	Amount
	AttributeBonus[Armored]
	GlaiveWurmWeapon
	Level
	)
	modifyNames = 
	( join, Comments ltrim
	Changeling
	Overlord
	TechLab
	VespeneGeyser
	)	

	aIDLookup := [], aDuplicates := [], aNameLookup := [], foundCount := 0
	modelAddress := mem.baseaddress
	while (modelAddress := mem.processPatternScan(modelAddress + 0x4,, byte1, byte2, byte3, byte4)) > 0 ;  same value at +0x0 of every model structure
	{	

		name := unitModelNameAlternate(modelAddress)
		name2 := unitModelName(modelAddress)

		if (name = "Changeling" || name2 = "Changeling")
			name := "Changeling"
		else if RegExmatch(name, "[^\x20-\x7E]") ; space -> ~ i.e. non english characters / non-string
			name := name2

		if (name = "")
			continue
		if name in %excludeNames%
			continue
		if name contains %excludeNamesContaining%
			continue

		modelID := ReadMemory(modelAddress + Offsets_UnitModel_ID, GameIdentifier, 2)
		if (modelID + 0 = "" || modelID >= 1000) ; **** may need to change this for lotv?
			continue 

		if aNameLookup.HasKey(name) 
		{
			if (modelID = aNameLookup[name]) ; same modelID & name values i.e. duplicate
				continue 
			; else differnt IDs
			; for changelings and such, want 'aIDLookup[modelID] := name' below to store the ID but not log it as a duplicate here!
			if name not in %modifyNames%
			{
				aDuplicates[name] := modelID 
				duplicatesPresent := true
			}
		}
		else aNameLookup[name] := modelID

		aIDLookup[modelID] := name
		foundCount++
	}
	if !foundCount
		return 0	
	

	 aRename   := { "Changeling" : 		["Changeling", "ChangelingZealot", "ChangelingMarineShield", "ChangelingMarine", "ChangelingZerglingWings", "ChangelingZergling"]
    			,   "TechLab": 			["TechLab", "BarracksTechLab", "FactoryTechLab", "StarportTechLab"]
   				,   "VespeneGeyser": 	["VespeneGeyser", "ProtossVespeneGeyser", "VespeneGeyserPretty"]}
	; There are a few other geysers, but they have unique name i.e. SpacePlatformGeyser, RichVespeneGeyser
	overlordCount := 0
	for modelID, name in aIDLookup
	{
		if aRename.HasKey(name)
		{
			indexKey := aRename[name, "_count"] := round(aRename[name, "_count"]) + 1
			if aRename[name].HasKey(indexKey)	
				aIDLookup[modelID] := newName := aRename[name, indexKey]
			else renameError .= name " Error - new " name " ? modelID: " modelID 
		}
		else if (name = "Overlord") ; Second overlord has a higher unit ID and doesn't seem valid
		{
			if (++overlordCount = 2)
				aIDLookup.remove(modelID, ""), foundCount--
			else if (overlordCount > 2)
				renameError .= "OverlordCount Error - new Overlord ? modelID: " modelID
		}
	}
	if renameError
		renameError := "Rename Errors:`n" renameError

	for modelID, name in aIDLookup
		outputString .= name " = " modelID ",`n"


	outputString := Rtrim(outputString, ",`n")
	outputString .= "`n`nCount: " foundCount "`n`n"
	outputString .= renameError
	if duplicatesPresent
	{
		outputString .= "`n`n`nDuplicates present:`n"
		for name, in aDuplicates
			outputString .= name "`n"
	}

	outputString .= "Excluded Names Containing: " excludeNamesContaining
				. "`nExcluded Names Matching: " excludeNames

	return foundCount
}

; Use on test map. 
debugUnitTargetFlags()
{
	loop, % getHighestUnitIndex()
	{
		unit := A_index - 1 
		name := getUnitNameAlternate(unit)
		filters := getUnitTargetFilterString(unit)
		r .= "`n`n" unit " " name "`n============`n" filters
	}
	return ltrim(r, "`n")
}



SetupUnitIDTestArray(byref aUnitID, byref aUnitName)
{
	l_UnitTypes = 
( comments 
System_Snapshot_Dummy = 1,
Ball = 21,
StereoscopicOptionsUnit = 22,
Colossus = 23,
TechLab = 24,
Reactor = 25,
InfestorTerran = 27,
BanelingCocoon = 28,
Baneling = 29,
Mothership = 30,
PointDefenseDrone = 31,
Changeling = 32,
ChangelingZealot = 33,
ChangelingMarineShield = 34,
ChangelingMarine = 35,
ChangelingZerglingWings = 36,
ChangelingZergling = 37,
CommandCenter = 39,
SupplyDepot = 40,
Refinery = 41,
Barracks = 42,
EngineeringBay = 43,
MissileTurret = 44,
Bunker = 45,
SensorTower = 46,
GhostAcademy = 47,
Factory = 48,
Starport = 49,
Armory = 51,
FusionCore = 52,
AutoTurret = 53,
SiegeTankSieged = 54,
SiegeTank = 55,
VikingAssault = 56,
VikingFighter = 57,
CommandCenterFlying = 58,
BarracksTechLab = 59,
BarracksReactor = 60,
FactoryTechLab = 61,
FactoryReactor = 62,
StarportTechLab = 63,
StarportReactor = 64,
FactoryFlying = 65,
StarportFlying = 66,
SCV = 67,
BarracksFlying = 68,
SupplyDepotLowered = 69,
Marine = 70,
Reaper = 71,
Ghost = 72,
Marauder = 73,
Thor = 74,
Hellion = 75,
Medivac = 76,
Banshee = 77,
Raven = 78,
Battlecruiser = 79,
Nuke = 80,
Nexus = 81,
Pylon = 82,
Assimilator = 83,
Gateway = 84,
Forge = 85,
FleetBeacon = 86,
TwilightCouncil = 87,
PhotonCannon = 88,
Stargate = 89,
TemplarArchive = 90,
DarkShrine = 91,
RoboticsBay = 92,
RoboticsFacility = 93,
CyberneticsCore = 94,
Zealot = 95,
Stalker = 96,
HighTemplar = 97,
DarkTemplar = 98,
Sentry = 99,
Phoenix = 100,
Carrier = 101,
VoidRay = 102,
WarpPrism = 103,
Observer = 104,
Immortal = 105,
Probe = 106,
Interceptor = 107,
Hatchery = 108,
CreepTumor = 109,
Extractor = 110,
SpawningPool = 111,
EvolutionChamber = 112,
HydraliskDen = 113,
Spire = 114,
UltraliskCavern = 115,
InfestationPit = 116,
NydusNetwork = 117,
BanelingNest = 118,
RoachWarren = 119,
SpineCrawler = 120,
SporeCrawler = 121,
Lair = 122,
Hive = 123,
GreaterSpire = 124,
Egg = 125,
Drone = 126,
Zergling = 127,
Overlord = 128,
Hydralisk = 129,
Mutalisk = 130,
Ultralisk = 131,
Roach = 132,
Infestor = 133,
Corruptor = 134,
BroodLordCocoon = 135,
BroodLord = 136,
BanelingBurrowed = 137,
DroneBurrowed = 138,
HydraliskBurrowed = 139,
RoachBurrowed = 140,
ZerglingBurrowed = 141,
InfestorTerranBurrowed = 142,
RedstoneLavaCritterInjuredBurrowed = 144,
RedstoneLavaCritter = 145,
RedstoneLavaCritterInjured = 146,
QueenBurrowed = 147,
Queen = 148,
InfestorBurrowed = 149,
OverlordCocoon = 150,
Overseer = 151,
PlanetaryFortress = 152,
UltraliskBurrowed = 153,
OrbitalCommand = 154,
WarpGate = 155,
OrbitalCommandFlying = 156,
ForceField = 157,
WarpPrismPhasing = 158,
CreepTumorBurrowed = 159,
CreepTumorQueen = 160,
SpineCrawlerUprooted = 161,
SporeCrawlerUprooted = 162,
Archon = 163,
NydusCanal = 164,
BroodlingEscort = 165,
RichMineralField = 166,
XelNagaTower = 168,
InfestedTerransEgg = 172,
Larva = 173,
ReaperPlaceholder = 174,
NeedleSpinesWeapon = 237,
CorruptionWeapon = 238,
InfestedTerransWeapon = 239,
NeuralParasiteWeapon = 240,
HunterSeekerWeapon = 242,
MULE = 243,
ThorAAWeapon = 245,
PunisherGrenadesLMWeapon = 246,
VikingFighterWeapon = 247,
ATALaserBatteryLMWeapon = 248,
ATSLaserBatteryLMWeapon = 249,
LongboltMissileWeapon = 250,
D8ChargeWeapon = 251,
YamatoWeapon = 252,
IonCannonsWeapon = 253,
AcidSalivaWeapon = 254,
SpineCrawlerWeapon = 255,
SporeCrawlerWeapon = 256,
StalkerWeapon = 260,
EMP2Weapon = 261,
BacklashRocketsLMWeapon = 262,
PhotonCannonWeapon = 263,
ParasiteSporeWeapon = 264,
Broodling = 266,
BroodLordBWeapon = 267,
AutoTurretReleaseWeapon = 270,
LarvaReleaseMissile = 271,
AcidSpinesWeapon = 272,
FrenzyWeapon = 273,
ContaminateWeapon = 274,
BeaconRally = 286,
BeaconArmy = 287,
BeaconAttack = 288,
BeaconDefend = 289,
BeaconHarass = 290,
BeaconIdle = 291,
BeaconAuto = 292,
BeaconDetect = 293,
BeaconScout = 294,
BeaconClaim = 295,
BeaconExpand = 296,
BeaconCustom1 = 297,
BeaconCustom2 = 298,
BeaconCustom3 = 299,
BeaconCustom4 = 300,
Rocks2x2NonConjoined = 305,
FungalGrowthMissile = 306,
NeuralParasiteTentacleMissile = 307,
Beacon_Protoss = 308,
Beacon_ProtossSmall = 309,
Beacon_Terran = 310,
Beacon_TerranSmall = 311,
Beacon_Zerg = 312,
Beacon_ZergSmall = 313,
Lyote = 314,
CarrionBird = 315,
KarakMale = 316,
KarakFemale = 317,
UrsadakFemaleExotic = 318,
UrsadakMale = 319,
UrsadakFemale = 320,
UrsadakCalf = 321,
UrsadakMaleExotic = 322,
UtilityBot = 323,
CommentatorBot1 = 324,
CommentatorBot2 = 325,
CommentatorBot3 = 326,
CommentatorBot4 = 327,
Scantipede = 328,
Dog = 329,
Sheep = 330,
Cow = 331,
InfestedTerransEggPlacement = 332,
InfestorTerransWeapon = 333,
MineralField = 334,
VespeneGeyser = 335,
ProtossVespeneGeyser = 336,
RichVespeneGeyser = 337,
TrafficSignal = 354,
MengskStatueAlone = 372,
MengskStatue = 373,
WolfStatue = 374,
GlobeStatue = 375,
Weapon = 376,
BroodLordWeapon = 378,
BroodLordAWeapon = 379,
CreepBlocker1x1 = 380,
PathingBlocker1x1 = 381,
PathingBlocker2x2 = 382,
AutoTestAttackTargetGround = 383,
AutoTestAttackTargetAir = 384,
AutoTestAttacker = 385,
HelperEmitterSelectionArrow = 386,
MultiKillObject = 387,
Debris2x2NonConjoined = 467,
EnemyPathingBlocker1x1 = 468,
EnemyPathingBlocker2x2 = 469,
EnemyPathingBlocker4x4 = 470,
EnemyPathingBlocker8x8 = 471,
EnemyPathingBlocker16x16 = 472,
ScopeTest = 473,
MineralField750 = 476,
RichMineralField750 = 477,
HellionTank = 493,
MothershipCore = 497,
LocustMP = 501,
NydusCanalAttacker = 503,
NydusCanalCreeper = 504,
SwarmHostBurrowedMP = 505,
SwarmHostMP = 506,
Oracle = 507,
Tempest = 508,
WarHound = 509,
WidowMine = 510,
Viper = 511,
WidowMineBurrowed = 512,
LurkerMPEgg = 513,
LurkerMP = 514,
LurkerMPBurrowed = 515,
LurkerDenMP = 516,
DigesterCreepSprayTargetUnit = 582,
DigesterCreepSprayUnit = 583,
NydusCanalAttackerWeapon = 584,
ViperConsumeStructureWeapon = 585,
ResourceBlocker = 588,
TempestWeapon = 589,
YoinkMissile = 590,
YoinkVikingAirMissile = 594,
YoinkVikingGroundMissile = 596,
YoinkSiegeTankMissile = 598,
WarHoundWeapon = 600,
EyeStalkWeapon = 602,
WidowMineWeapon = 605,
WidowMineAirWeapon = 606,
MothershipCoreWeaponWeapon = 607,
TornadoMissileWeapon = 608,
TornadoMissileDummyWeapon = 609,
TalonsMissileWeapon = 610,
CreepTumorMissile = 611,
LocustMPEggAMissileWeapon = 612,
LocustMPEggBMissileWeapon = 613,
LocustMPWeapon = 614,
RepulsorCannonWeapon = 616,
Ice2x2NonConjoined = 624,
IceProtossCrates = 625,
ProtossCrates = 626,
TowerMine = 627,
PickupPalletGas = 628,
PickupPalletMinerals = 629,
PickupScrapSalvage1x1 = 630,
PickupScrapSalvage2x2 = 631,
PickupScrapSalvage3x3 = 632,
RoughTerrain = 633,
UnbuildableBricksSmallUnit = 634,
UnbuildableRocksSmallUnit = 637,
XelNagaHealingShrine = 638,
InvisibleTargetDummy = 639,
VespeneGeyserPretty = 640, ; my custom name 
ThornLizard = 643,
CleaningBot = 644,
ProtossSnakeSegmentDemo = 646,
PhysicsCapsule = 647,
PhysicsCube = 648,
PhysicsCylinder = 649,
PhysicsKnot = 650,
PhysicsL = 651,
PhysicsPrimitives = 652,
PhysicsSphere = 653,
PhysicsStar = 654,
CreepBlocker4x4 = 655,
TestZerg = 664,
PathingBlockerRadius1 = 665,
DesertPlanetSearchlight = 686,
DesertPlanetStreetlight = 687,
UnbuildableBricksUnit = 688,
UnbuildableRocksUnit = 689,
Artosilope = 691,
Anteplott = 692,
LabBot = 693,
Crabeetle = 694,
LabMineralField = 697,
LabMineralField750 = 698,
ThorAP = 714,
LocustMPFlying = 715,
ThorAALance = 718,
OracleWeapon = 719,
TempestWeaponGround = 720,
SeekerMissile = 722	
)
	aUnitID := []
	aUnitName := []
	loop, parse, l_UnitTypes, `,
	{
		StringSplit, Item , A_LoopField, = 		; Format "Colossus = 38"
		name := trim(Item1, " `t `n"), UnitID := trim(Item2, " `t `n")
		aUnitID[name] := UnitID
		aUnitName[UnitID] := name
	}
	Return
}