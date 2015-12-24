		B_LocalCharacterNameID := base + 0x4FBADF4 ; stored as string Name#123 There are a couple of these, but only one works after SC restart or out of game


		; bytes have swapped in patch 3? 
		;aSCOffsets["LocalPlayerSlot"] := [base + 0x018F5980, 0x18, 0x278, 0x258, 0x3DD] ; patch 3.3 ; note 1byte and has a second 'copy' (ReplayWatchedPlayer) just after +1byte eg LS =16d=10h, hex 1010 (2bytes) & LS =01d = hex 0101
	 
			 Offsets_Player_Status := 0x0
			 Offsets_Player_CameraPositionX := 0x8 ; same address but obfuscated 
			 Offsets_Player_CameraPositionY := 0xC	;
			 Offsets_Player_CameraDistance := 0x10 
			 Offsets_Player_CameraAngle := 0x14
			 Offsets_Player_CameraRotation := 0x18

			 Offsets_Player_Team := 0x1C 
			 Offsets_Player_Type := 0x1D 
			 O_pVictoryStatus := 0x1E
			 O_pName := 0x64 
			 
			 Offsets_Player_RacePointer := 0x5C ; same as old patch - but there was one at 0x160 - not there anymore
			 Offsets_Player_Colour := 0xD8   ; patch 3.3
			 O_pAccountID := 0x218 ;  0x1C0 

			 Offsets_Player_APMCurrent := 0x4F8	; Instantaneous (I only use this one out of the 4)
			 Offsets_Player_APMAverage := 0x500
			 Offsets_Player_EPMCurrent := 0x538 ; Instantaneous
			 Offsets_Player_EPMAverage := 0x540 	

			 Offsets_Player_TotalUnitsBuilt := 0x568 	; Units built, doesn't include structures. Increments on unit completion.					
			 											; There are a couple of other similar values, one is probably highest current unit count achieved.
			 Offsets_Player_CurrentTotalUnits := 0x5B0 ;  current number of units (includes 6 starting scvs/units) doesn't include structures.  Increments on unit completion.
			 Offsets_Player_WorkerCountAll := 0x5C8 ; This includes workers currently in production!
			 Offsets_Player_WorkerCount := 0x6E8 ; **Care dont confuse this with HighestWorkerCount (or worker count + production above)
			 Offsets_Player_WorkersBuilt := 0x6F8 ; number of workers made (includes the 6 at the start of the game) increases on worker completion
			 Offsets_Player_CompletedTownHalls := 0x758 ; Completed townHall count 
			 Offsets_Player_HighestWorkerCount := 0x710 ;???? the current highest worker account achieved (increases on worker completion - providing its more workers than previous highest value)
			 

			 Offsets_Player_SupplyCap := 0x7A8 
			 Offsets_Player_Supply := 0x7C0		
			 Offsets_Player_Minerals := 0x800
			 Offsets_Player_Gas := 0x808 

			 Offsets_Player_ArmySupply := 0x7E0 	 
			 Offsets_Player_MineralIncome := 0x880  
			 Offsets_Player_GasIncome := 0x888
			 Offsets_Player_ArmyMineralCost := 0xB68 ; there are two (identical?) values for minerals/gas 
			 Offsets_Player_ArmyGasCost := 0xB90 ; ** care dont use max army gas/mineral value! 

		; Be very careful of pointers which are invalid for a split second!
		Offsets_IdleWorkerCountPointer := [base + 0x0181C360, 0x8, 0x48, 0x134]

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
		 ; **** In lotv there was only 1 real valid pointer - the other ones (which appeared valid) sometimes failed during a match!
		 Offsets_ChatFocusPointer := [base + 0x024E0CF4, 0x1DC, 0xE8] ;Just when chat box is in focus ; value = True if open. There will be 2 of these.
	

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

		 Offsets_UnitHighestAliveIndex := base + 0x1F268C0 ;0x1F24840 		; This is actually the highest currently alive unit (includes missiles while alive) and starts at 1 NOT 0! i.e. 1 unit alive at index 0 = 1, 1 alive at index 7 = 8 

		; B_uStructure := base + 0x36AA840 ; Offsets_UnitHighestAliveIndex+0x40    			
		 Offsets_Unit_StructSize := 0x1E8 ; patch 3.3 = 488d
			 Offsets_Unit_ModelPointer := 0x8 ; p3.3
			 Offsets_Unit_TargetFilter := 0x14 ; p3.3
			 Offsets_Unit_Owner := 0x2E ; p3.3 ; There are 3 owner offsets (0x27, 0x40, 0x41) for changelings owner3 changes to the player it is mimicking
			; O_XelNagaActive := 0x34 	; xel - dont use as doesnt work all the time
			 Offsets_Unit_PositionX := 0x50
			 Offsets_Unit_PositionY := 0x54
			 Offsets_Unit_PositionZ := 0x58
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
		; In LotV, there is a pointer at unitModel + 8, that points to a structure containing
		; all the unit information - the info/value offsets didnt change from hots 3.0 -> lotv
		; in hots, this information was just in the base unit model structure 
		; ** ****
		; UnitModel_ID is in both structures i.e. unit model and the [unitModel + 8] structure,
		; But its not identical for all units. 
		; For OverlordTransport and TransportoverlordCocoon the unit id at [[unitModel + 8] +6] is wrong
		; but the priority is correct. The correct minimarpRadius is in the base structure
		; The get unit names still seem to work too (using the base unit model struct)	
		Offsets_UnitModel_ID := 0x6 
		Offsets_UnitModel_BasePtr := 0x8 
		Offsets_UnitModel_SubgroupPriority := 0x3CC 
		Offsets_UnitModel_MinimapRadius := 0x3D0 

		Offsets_Selection_Base := base + 0x1EEBC08 ;0x1EE9BB8 
		; The structure begins with ctrl group 0
		Offsets_Group_ControlGroup0 := base + 0x1EEF2C8 ;0x1EED278
		Offsets_Group_ControlGroupSize := 0x1B60
	; Unit Selection & Ctrl Group Structures use same offsets
			Offsets_Group_TypeCount := 0x2
			Offsets_Group_HighlightedGroup := 0x4
			Offsets_Group_UnitOffset := 0x8

		; gives the select army unit count (i.e. same as in the select army icon) - unit count not supply
		; dont confuse with similar value which includes army unit counts in production - or if in map editor unit count/index.
		; Shares a common base with Offsets_IsUserPerformingAction, SelectionPtr, IdleWorkerPtr, ChatFocusPtr, B_UnitCursor, Offsets_CameraMovingViaMouseAtScreenEdge (never realised it was so many derp)

		Offsets_localArmyUnitCountPointer := [base + 0x0181C360, 0x8, 0x138] ; ended with these two offsets last two patches 3.0.5


		Offsets_TeamColoursEnabled := base + 0x1B7C144 ; 2 when team colours is on, else 0 (There are two valid addresses for this)
		 

		Offsets_SelectionPage := [base + 0x0181D110, 0x8, 0xD8, 0xC8]  	; Tends to end with these offsets. ***theres one other 3 lvl pointer but for a split second (every few second or so) it points to 
			 				; the wrong address! You need to increase CE timer resolution to see this happening! Or better yet use the 'continually perform the pointer scan until stopped' option.
			 				;this is for the currently selected unit portrait page ie 1-6 in game (really starts at 0-5)
							;might actually be a 2 or 1 byte value....but works fine as 4

		Offsets_Map_NamePointer := [base + 0x01F17E08, 0x2A0] ; The string offset tends to end with this value

		/* Not updated dont use.
		; at B_MapStruct -0x5C is a pointer which list map file name, map name, description and other stuff
		 B_MapStruct := base + 0x357A06C		;0x353C3B4 ;0x3534EDC ; 0X024C9E7C 
			 O_mLeft := B_MapStruct + 0xDC	                                   
			 O_mBottom := B_MapStruct + 0xE0	                                   
			 O_mRight := B_MapStruct + 0xE4	    ; MapRight 157.999756 (akilon wastes) after dividing 4096   (647167 before)                  
			 O_mTop := B_MapStruct + 0xE8	   	; MapTop: 622591 (akilon wastes) before dividing 4096  
		*/ 
		
		Offsets_Camera_BorderLeft 	:= 	base + 0x1B7C84C        
		Offsets_Camera_BorderBottom := 	Offsets_Camera_BorderLeft + 0x4
		Offsets_Camera_BorderRight 	:= 	Offsets_Camera_BorderLeft + 0x8
		Offsets_Camera_BorderTop 	:= 	Offsets_Camera_BorderLeft + 0xC

		 aUnitMoveStates := { Idle: -1  ; ** Note this isn't actually a read in game type/value its just what my function will return if it is idle
							, Amove: 0 		
							, Patrol: 1
							, HoldPosition: 2
							, Move: 256
							, Follow: 512
							, FollowNoAttack: 515} ; (ScanMove) This is used by unit spell casters such as infestors and High temps which dont have a real attack 
			
			

	 	; This base can be the same as B_UnitCursor				; If used as 4byte value, will return 256 	there are 2 of these memory addresses
		 Offsets_IsUserPerformingAction := [base + 0x024E0CF4, 0x9C]	; This is a 1byte value and return 1  when user is casting or in is rallying a hatch via gather/rally or is in middle of issuing Amove/patrol command but
												 				; if youre searching for a 4byte value in CE offset will be at 0x254 (but really if using it as 1 byte it is 0x255) - but im lazy and use it as a 4byte with my pointer command
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
		 Offsets_IsBuildCardDisplayed := [base + 0x0181C2F4, 0x8, 0xF4, 0x28C]	
		 	; this displays 1 (swarm host) or 0 with units selected - displays 7 when targeting reticle displayed/or placing a building (same thing)
			; **but when either build card is displayed it displays 6 (even when all advanced structures are greyed out)!!!!
			; also displays 6 when the toss hallucination card is displayed
			; could use this in place of the current 'is user performing action offset'
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

															
		 B_CameraDragScroll := base + 0x188A314   			; 1 byte Returns 1 when user is moving camera via DragScroll i.e. mmouse button the main map But not when on the minimap (or if mbutton is held down on the unit panel)

		
		 Offsets_InputStructure := base + 0x188A624  		
			 B_iMouseButtons := Offsets_InputStructure + 0x0 		; 1 Byte 	MouseButton state 1 for Lbutton,  2 for middle mouse, 4 for rbutton, 8 xbutton1, 16 xbutton2
			 B_iSpace := B_iMouseButtons + 0x8 				; 1 Bytes
			 B_iNums := B_iSpace + 0x2  					; 2 Bytes
			 B_iChars := B_iNums + 0x2 						; 4 Bytes 
			 B_iTilda := B_iChars + 0x4 					; 1 Byte  (could be 2 bytes)
			 B_iNonAlphNumChars := B_iTilda + 0x2 			; 2 Bytes - keys: [];',./ Esc Entr \
			 B_iNonCharKeys := B_iNonAlphNumChars + 0x2 	; 2 Bytes - keys: BS Up Down Left Right Ins Del Hom etc scrl lock pause caps + tab
			 B_iFkeys := B_iNonCharKeys + 0x2 				; 2 bytes		
			 B_iModifiers := B_iFkeys + 0x6 				; 1 Byte



		 Offsets_CameraMovingViaMouseAtScreenEdge := [base + 0x01836324, 0x0, 0x2E4, 0x8, 0x688]  		; Really a 1 byte value value indicates which direction screen will scroll due to mouse at edge of screen
			 				; 1 = Diagonal Left/Top 		4 = Left Edge
			 				; 2 = Top 						5 = Right Edge			
			 				; 3 = Diagonal Right/Top 	  	6 = Diagonal Left/ Bot	
							; 7 = Bottom Edge 			 	8 = Diagonal Right/Bot 
							; Note need to do a pointer scan with max offset > 1200d! Tends to have the same offsets
		Offsets_IsGamePaused := base + 0x55E3460 						

		B_FramesPerSecond := base + 0x5008BC4
		Offsets_GameSpeed  := base + 0x55E3440

		; example: D:\My Computer\My Documents\StarCraft II\Accounts\56025555\6-S2-1-34555\Replays\
		; this works for En, Fr, and Kr languages 
		B_ReplayFolder := base + 0x24CAE18 ; p3.0.3

		; Horizontal resolution ; 4 bytes
		; vertical resolution ; The next 4 bytes immediately after the Horizontal resolution 
		; cheat and search for 8 bytes 4638564681600 (1920 1080)
		; There will be 3 green static addresses (+many non-statics) One of them will change depending on resolution
		; Can resize in window mode and it will change too

		 Offsets_HorizontalResolution := base + 0x2375244
		 Offsets_VerticalResolution := Offsets_HorizontalResolution + 0x4

		; 4 byte ints listed in memory: 808 28 1066 290  (at 1920x1080)
		; Be extremely careful with this on. CE 'scan until stopped' wasnt able to filter out a bad pointer
		; after 1 minute of scanning. It took 2 goes before it removed it!
		; There was another one that failed after ~5 min in my scanner
		; The pointer below was didn't fail even after 1 hour
		Offsets_MinimapPosition := [base + 0x023765B4, 0x30, 0x0, 0x178, 0xC]

	}