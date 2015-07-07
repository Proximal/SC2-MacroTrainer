B_LocalCharacterNameID := base + 0x4FB4DF4 ; stored as string Name#123 There are a couple of these, but only one works after SC restart or out of game
		B_LocalPlayerSlot := base + 0x115E6A8 ; note 1byte and has a second 'copy' (ReplayWatchedPlayer) just after +1byte eg LS =16d=10h, hex 1010 (2bytes) & LS =01d = hex 0101
		B_ReplayWatchedPlayer := B_LocalPlayerSlot + 0x1
		 
		B_pStructure := base + 0x3625F90 ; 			 
		S_pStructure := 0xE18
			 O_pStatus := 0x0
			 O_pXcam := 0x8
			 O_pYcam := 0xC	
			 O_pCamDistance := 0x10 ; 0xA - Dont know if this is correct - E
			 O_pCamAngle := 0x14
			 O_pCamRotation := 0x18

			 ; 8 bytes were inserted here
			 O_pTeam := 0x1C 
			 O_pType := 0x1D ;same
			 O_pVictoryStatus := 0x1E
			 O_pName := 0x64 
			 
			 O_pRacePointer := 0x160
			 O_pColour := 0x1B8
			 O_pAccountID := 0x218 ; This moved by quite a bit (more than the others) 0x1C0 

			 O_pAPM := 0x5F0 	; Instantaneous
			 O_pAPMAverage := 0x5F8
			 O_pEPM := 0x630 	; Instantaneous
			 O_pEPMAverage := 0x638 	

			 O_pWorkerCount := 0x7E0 ; **Care dont confuse this with HighestWorkerCount
			 O_pTotalUnitsBuilt := 0x660 ; eg numbers of units made (includes 6 starting scvs) 
			 O_pWorkersBuilt := 0x7F0 ; number of workers made (includes the 6 at the start of the game)
			 O_pHighestWorkerCount := 0x808 ; the current highest worker account achieved
			 O_pBaseCount := 0x850 

			 O_pSupplyCap := 0x8A0		
			 O_pSupply := 0x8B8 		
			 O_pMinerals := 0x8F8 
			 O_pGas := 0x900

			 O_pArmySupply := 0x8D8	 
			 O_pMineralIncome := 0x978
			 O_pGasIncome := 0x980
			 O_pArmyMineralSize := 0xC60 	; there are two (identical?) values for minerals/gas 
			 O_pArmyGasSize := 0xC88 		; ** care dont use max army gas/mineral size! 

		 P_IdleWorker := base + 0x3145920		
			 O1_IdleWorker := 0x358
			 O2_IdleWorker := 0x244 	; tends to always end with this offset if finding via pointer scan

		; 	This can be found via three methods, pattern scan:
		;	C1 EA 0A B9 00 01 00 00 01 0D ?? ?? ?? ?? F6 D2 A3 ?? ?? ?? ?? F6 C2 01 74 06 01 0D ?? ?? ?? ?? 83 3D ?? ?? ?? ?? 00 56 BE FF FF FF 7F
		; 	Timer Address = readMemory(patternAddress + 0x1C)
		; 	It can also be found as there are two (identical?) 4-byte timers next to each other.
		; 	So do the usual search between times to find the timer value, then search for an 8 byte representation of 
		;   two timers which have the same value.  GameGetMissionTime() refers to the second (+0x4) of these two timers.
		;	And via IDA (Function: GameGetMissionTime) (-0x800000 from IDA address)

		 B_Timer := base + 0x35740D0		

		 B_rStructure := base + 0x02F6C850	; Havent updated as dont use this
			 S_rStructure := 0x10

		 ; Also be sure to check the pointer in a real game. Ones which appear valid via mapeditor maps may not work.
		 ; must be 0 when chat box not open yet another menu window is
		 P_ChatFocus := base + 0x3145920 ;Just when chat box is in focus ; value = True if open. There will be 2 of these.
			 O1_ChatFocus := 0x394 
			 O2_ChatFocus := 0x174 		; tends to end with this offset

		 P_MenuFocus := base + 0x503FA6C 	;this is all menus and includes chat box when in focus 
			 O1_MenuFocus := 0x17C 			; tends to end with this offse

		P_SocialMenu := base + 0x0409B098 ; ???? Havent updated as dont use it

		 B_uCount := base + 0x36A47E8 	; This is the units alive (and includes missiles) - near B_uHighestIndex (-0x18)		
		 								; There are two of these values and they only differ the instant a unit dies esp with missle fire (ive used the higher value) - perhaps one updates slightly quicker - dont think i use this offset anymore other than as a value in debugData()
		 								; Theres another one which excludes structures

		 B_uHighestIndex := base + 0x36A4800  			; This is actually the highest currently alive unit (includes missiles while alive) and starts at 1 NOT 0! i.e. 1 unit alive = 1
		 B_uStructure := base + 0x36A4840 ; B_uHighestIndex+0x40    			
		 S_uStructure := 0x1C0
			 O_uModelPointer := 0x8
			 O_uTargetFilter := 0x14
			 O_uBuildStatus := 0x18		; buildstatus is really part of the 8 bit targ filter!
			 O_uOwner := 0x27 ; There are 3 owner offsets (0x27, 0x40, 0x41) for changelings owner3 changes to the player it is mimicking
			 O_XelNagaActive := 0x34 	; xel - dont use as doesnt work all the time
			; something added in here in vr 2.10		  
			 O_uX := 0x4C
			 O_uY := 0x50
			 O_uZ := 0x54
			 O_uDestinationX := 0x80
			 O_uDestinationY := 0x84
			 O_P_uCmdQueuePointer := 0xD4 ;+4
			 O_P_uAbilityPointer := 0xDC

			 O_uPoweredState := 0xE0 									
			 O_uChronoState := 0xE6	; there are other offsets which can be used for chrono/inject state ; pre 210 chrono and inject offsets were the same 
			 O_uInjectState := 0xE7 ; +5 Weird this was 5 not 4 (and its values changed) chrono state just +4
			 O_uBuffPointer := 0xEC


			 O_uHpDamage := 0x114
			 O_uShieldDamage := 0x118
			 O_uEnergy := 0x11c 
			 O_uTimer := 0x16C ;+4
			
		;CommandQueue 	; separate structure
			 O_cqState := 0x40	
		
		; Unit Model Structure	
		 O_mUnitID := 0x6	
		 O_mSubgroupPriority := 0x3A8 ;0x398
		 O_mMiniMapSize := 0x3AC ;0x39C
		
		; selection and ctrl groups
		 B_SelectionStructure := base + 0x3209810 

		; The structure begins with ctrl group 0

		 B_CtrlGroupStructure := base + 0x320CED8
		 S_CtrlGroup := 0x1B60
		 S_scStructure := 0x4	; Unit Selection & Ctrl Group Structures
			 O_scTypeCount := 0x2
			 O_scTypeHighlighted := 0x4
			 O_scUnitIndex := 0x8

		; gives the select army unit count (i.e. same as in the select army icon) - unit count not supply
		; dont confuse with similar value which includes army unit counts in production - or if in map editor unit count/index.
		; Shares a common base with P_IsUserPerformingAction, SelectionPtr, IdleWorkerPtr, ChatFocusPtr, B_UnitCursor, B_CameraMovingViaMouseAtScreenEdge (never realised it was so many derp)

		B_localArmyUnitCount := base + 0x3145920
			O1_localArmyUnitCount := 0x354
			O2_localArmyUnitCount := 0x248

		 B_TeamColours := base + 0x3147184 ; 2 when team colours is on, else 0
		; another one at + 0x4FEDA58

		 P_SelectionPage := base + 0x3145920  	; Tends to end with these offsets. ***theres one other 3 lvl pointer but for a split second (every few second or so) it points to 
			 O1_SelectionPage := 0x320			; the wrong address! You need to increase CE timer resolution to see this happening! Or better yet use the 'continually perform the pointer scan until stopped' option.
			 O2_SelectionPage := 0x15C			;this is for the currently selected unit portrait page ie 1-6 in game (really starts at 0-5)
			 O3_SelectionPage := 0x14C 			;might actually be a 2 or 1 byte value....but works fine as 4

		DeadFilterFlag := 0x0000000200000000	
		BuriedFilterFlag := 0x0000000010000000

		 B_MapInfo := base + 0x3574010
			O_FileInfoPointer := 0 

		; at B_MapStruct -0x5C is a pointer which list map file name, map name, description and other stuff
		 B_MapStruct := base + 0x357406C		;0x353C3B4 ;0x3534EDC ; 0X024C9E7C 
			 O_mLeft := B_MapStruct + 0xDC	                                   
			 O_mBottom := B_MapStruct + 0xE0	                                   
			 O_mRight := B_MapStruct + 0xE4	    ; MapRight 157.999756 (akilon wastes) after dividing 4096   (647167 before)                  
			 O_mTop := B_MapStruct + 0xE8	   	; MapTop: 622591 (akilon wastes) before dividing 4096  

		B_camLeft := base + 0x31478E0
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
			
		B_UnitCursor :=	base + 0x3145920  
			O1_UnitCursor := 0x2C0	 					
			O2_UnitCursor := 0x21C 					

	 	; This base can be the same as B_UnitCursor				; If used as 4byte value, will return 256 	there are 2 of these memory addresses
		 P_IsUserPerformingAction := base + 0x3145920 			; This is a 1byte value and return 1  when user is casting or in is rallying a hatch via gather/rally or is in middle of issuing Amove/patrol command but
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
		 P_IsBuildCardDisplayed := base + 0x3159A34 		; this displays 1 (swarm host) or 0 with units selected - displays 7 when targeting reticle displayed/or placing a building (same thing)
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

															
		 B_CameraDragScroll := base + 0x30887A8   			; 1 byte Returns 1 when user is moving camera via DragScroll i.e. mmouse button the main map But not when on the minimap (or if mbutton is held down on the unit panel)

		
		 B_InputStructure := base + 0x3088AB8  		
			 B_iMouseButtons := B_InputStructure + 0x0 		; 1 Byte 	MouseButton state 1 for Lbutton,  2 for middle mouse, 4 for rbutton, 8 xbutton1, 16 xbutton2
			 B_iSpace := B_iMouseButtons + 0x8 				; 1 Bytes
			 B_iNums := B_iSpace + 0x2  					; 2 Bytes
			 B_iChars := B_iNums + 0x2 						; 4 Bytes 
			 B_iTilda := B_iChars + 0x4 					; 1 Byte  (could be 2 bytes)
			 B_iNonAlphNumChars := B_iTilda + 0x2 			; 2 Bytes - keys: [];',./ Esc Entr \
			 B_iNonCharKeys := B_iNonAlphNumChars + 0x2 	; 2 Bytes - keys: BS Up Down Left Right Ins Del Hom etc scrl lock pause caps + tab
			 B_iFkeys := B_iNonCharKeys + 0x2 				; 2 bytes		
			 B_iModifiers := B_iFkeys + 0x6 				; 1 Byte



		 B_CameraMovingViaMouseAtScreenEdge := base + 0x3145920  		; Really a 1 byte value value indicates which direction screen will scroll due to mouse at edge of screen
			 01_CameraMovingViaMouseAtScreenEdge := 0x2C0				; 1 = Diagonal Left/Top 		4 = Left Edge
			 02_CameraMovingViaMouseAtScreenEdge := 0x20C				; 2 = Top 						5 = Right Edge			
			 03_CameraMovingViaMouseAtScreenEdge := 0x5A4				; 3 = Diagonal Right/Top 	  	6 = Diagonal Left/ Bot	
																		; 7 = Bottom Edge 			 	8 = Diagonal Right/Bot 
																		; Note need to do a pointer scan with max offset > 1200d! Tends to have the same offsets
		 B_IsGamePaused := base + 0x4EFFE8C 						

		 B_FramesPerSecond := base + 0x5002BC4
		 B_Gamespeed  := base + 0x4F2F6A8

		; example: D:\My Computer\My Documents\StarCraft II\Accounts\56025555\6-S2-1-34555\Replays\
		; this works for En, Fr, and Kr languages 
		 B_ReplayFolder :=  base + 0x4FB6668

		; Horizontal resolution ; 4 bytes
		; vertical resolution ; The next 4 bytes immediately after the Horizontal resolution 
		; cheat and search for 8 bytes 4638564681600 (1920 1080)
		; There will be 3 green static addresses (+many non-statics) One of them will change depending on resolution
		; Can resize in window mode and it will change too

		 B_HorizontalResolution := base + 0x503F520
		 B_VerticalResolution := B_HorizontalResolution + 0x4


		P_MinimapPosition := base + 0x03159A34
		O_MinimapPosition := [0x4, 0xE0, 0xD4, 0x25C]