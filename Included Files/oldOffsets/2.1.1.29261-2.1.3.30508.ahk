    ; This is for versions 2.1.1.29261 to 2.1.3.30508
        ;   [Memory Addresses]
        B_LocalCharacterNameID := base + 0x04F15C14 ; stored as string Name#123
        B_LocalPlayerSlot := base + 0x112E5F0 ; note 1byte and has a second 'copy' (ReplayWatchedPlayer) just after +1byte eg LS =16d=10h, hex 1010 (2bytes) & LS =01d = hex 0101
        B_ReplayWatchedPlayer := B_LocalPlayerSlot + 0x1
        ;B_pStructure := base + 0x35F55A8  ; start at Player1            
        B_pStructure := base + 0x35F4798             
        S_pStructure := 0xE10
             O_pStatus := 0x0
             O_pXcam := 0x8
             O_pYcam := 0xC 
             O_pCamDistance := 0x10 ; 0xA - Dont know if this is correct - E
             O_pCamAngle := 0x14
             O_pCamRotation := 0x18

             O_pTeam := 0x1C
             O_pType := 0x1D ;
             O_pVictoryStatus := 0x1E
             O_pName := 0x60 ;+8
             
             O_pRacePointer := 0x158
             O_pColour := 0x1B0
             O_pAccountID := 0x1C0 ; ????

             O_pAPM := 0x5E8    ; 0x598     
             O_pEPM := 0x5D8    ; ?????

             O_pWorkerCount := 0x7D8 ; **Care dont confuse this with HighestWorkerCount
             O_pTotalUnitsBuilt := 0x658 ; eg numbers of units made (includes 6 starting scvs) 
             O_pWorkersBuilt := 0x7E8 ; number of workers made (includes the 6 at the start of the game)
             O_pHighestWorkerCount := 0x800 ; the current highest worker account achieved
             O_pBaseCount := 0x848 
             O_pSupplyCap := 0x898      
             O_pSupply := 0x8B0 ;+ 12       
             O_pMinerals := 0x8F0 ;+18
             O_pGas := 0x8F8

             O_pArmySupply := 0x8D0  
             O_pMineralIncome := 0x970
             O_pGasIncome := 0x978
             O_pArmyMineralSize := 0xC58    ; there are two (identical?) values for minerals/gas 
             O_pArmyGasSize := 0xC80        ; ** care dont use max army gas/mineral size! 

         P_IdleWorker := base + 0x03114D30      
             O1_IdleWorker := 0x358
             O2_IdleWorker := 0x244     ; tends to always end with this offset if finding via pointer scan

         B_Timer := base + 0x35428DC ; 0x353C41C            

         B_rStructure := base + 0x02F6C850  ; ?? Havent updated as dont use this
             S_rStructure := 0x10

         P_ChatFocus := base + 0x03114D30 ;Just when chat box is in focus ; value = True if open
             O1_ChatFocus := 0x394 
             O2_ChatFocus := 0x174      ; tends to end with this offset

         P_MenuFocus := base + 0x04FFA324   ;this is all menus and includes chat box when in focus ; old 0x3F04C04
             O1_MenuFocus := 0x17C          ; tends to end with this offse

        P_SocialMenu := base + 0x0409B098 ; ???? Havent updated as dont use it

         B_uCount := base + 0x3672FA8 ; or 0x2F75568    ; This is the units alive (and includes missiles)           
                                                        ; There are two of these values and they only differ the instant a unit dies esp with missle fire (ive used the higher value) - perhaps one updates slightly quicker - dont think i use this offset anymore
                                    
         B_uHighestIndex := base + 0x3672FC0            ; this is actually the highest currently alive unit (includes missiles while alive) and starts at 1 NOT 0! i.e. 1 unit alive = 1
         B_uStructure := base + 0x3673000           
         S_uStructure := 0x1C0
             O_uModelPointer := 0x8
             O_uTargetFilter := 0x14
             O_uBuildStatus := 0x18     ; buildstatus is really part of the 8 bit targ filter!
             O_uOwner := 0x27 ; There are 3 owner offsets (0x27, 0x40, 0x41) for changelings owner3 changes to the player it is mimicking
             O_XelNagaActive := 0x34    ; xel - dont use as doesnt work all the time
            ; something added in here in vr 2.10          
             O_uX := 0x4C
             O_uY := 0x50
             O_uZ := 0x54
             O_uDestinationX := 0x80
             O_uDestinationY := 0x84
             O_P_uCmdQueuePointer := 0xD4 ;+4
             O_P_uAbilityPointer := 0xDC

                                        ; there are other offsets which can be used for chrono/inject state
             O_uChronoState := 0xE6             ; pre 210 chrono and inject offsets were the same
             O_uInjectState := 0xE7 ; +5 Weird this was 5 not 4 (and its values changed) chrono state just +4
             O_uBuffPointer := 0xEC

             O_uHpDamage := 0x114
             O_uShieldDamage := 0x118
             O_uEnergy := 0x11c 
             O_uTimer := 0x16C ;+4
            
        ;CommandQueue   ; separate structure
             O_cqState := 0x40  

        
        ; Unit Model Structure  
         O_mUnitID := 0x6   
         O_mSubgroupPriority := 0x3A8 ;0x398
         O_mMiniMapSize := 0x3AC ;0x39C
        
        ; selection and ctrl groups
         B_SelectionStructure := base + 0x31D8508

         B_CtrlGroupOneStructure := base + 0x31DD730
         S_CtrlGroup := 0x1B60
         S_scStructure := 0x4   ; Unit Selection & Ctrl Group Structures
             O_scTypeCount := 0x2
             O_scTypeHighlighted := 0x4
             O_scUnitIndex := 0x8

        B_localArmyUnitCount := base + 0x03114D30
            O1_localArmyUnitCount := 0x354
            O2_localArmyUnitCount := 0x248

         B_TeamColours := base + 0x3115E7C ; 2 when team colours is on, else 0
        ; another one at + 0x4FBCB98

         P_SelectionPage := base + 0x03114D30   ; ***theres one other 3 lvl pointer but for a split second (every second or so) it points to 
             O1_SelectionPage := 0x320          ; the wrong address! You need to increase CE timer resolution to see this happening! Check it!
             O2_SelectionPage := 0x15C          ;this is for the currently selected unit portrait page ie 1-6 in game (really starts at 0-5)
             O3_SelectionPage := 0x14C          ;might actually be a 2 or 1 byte value....but works fine as 4

        DeadFilterFlag := 0x0000000200000000    
        BuriedFilterFlag := 0x0000000010000000

         B_MapStruct := base + 0x3542874        ;0x353C3B4 ;0x3534EDC ; 0X024C9E7C 
             O_mLeft := B_MapStruct + 0xDC                                     
             O_mBottom := B_MapStruct + 0xE0                                       
             O_mRight := B_MapStruct + 0xE4     ; MapRight 157.999756 (akilon wastes) after dividing 4096   (647167 before)                  
             O_mTop := B_MapStruct + 0xE8       ; MapTop: 622591 (akilon wastes) before dividing 4096  

        B_camLeft := base + 0x31165D8
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
            
        B_UnitCursor := base + 0x03114D30 
            O1_UnitCursor := 0x2C0                      
            O2_UnitCursor := 0x21C                  

                                                                ; If used as 4byte value, will return 256   there are 2 of these memory addresses
         P_IsUserPerformingAction := base + 0x03114D30          ; This is a 1byte value and return 1  when user is casting or in is rallying a hatch via gather/rally or is in middle of issuing Amove/patrol command but
             O1_IsUserPerformingAction := 0x230                     ; if youre searching for a 4byte value in CE offset will be at 0x254 (but really if using it as 1 byte it is 0x255) - but im lazy and use it as a 4byte with my pointer command

         P_IsBuildCardDisplayed := base + 0x0312872C        ; this displays 1 (swarm host) or 0 with units selected - displays 7 when targeting reticle displayed/or placing a building (same thing)
             01_IsBuildCardDisplayed := 0x7C                ; **but when either build card is displayed it displays 6 (even when all advanced structures are greyed out)!!!!
             02_IsBuildCardDisplayed := 0x74                ; also displays 6 when the toss hallucination card is displayed
             03_IsBuildCardDisplayed := 0x398               ; could use this in place of the current 'is user performing action offset'
                                                            ; Note: There is another address which has the same info, but when placing a building it will swap between 6 & 7 (not stay at 7)!
                                                               
         P_ChatInput := base + 0x0310EDEC       ; ?????? not updated/used currently
             O1_ChatInput := 0x16C 
             O2_ChatInput := 0xC
             O3_ChatInput := 0x278
             O4_ChatInput := 0x0
                                                            
         B_CameraDragScroll := base + 0x3057DB0             ; 1 byte Returns 1 when user is moving camera via DragScroll i.e. mmouse button the main map But not when on the minimap (or if mbutton is held down on the unit panel)

        
         B_InputStructure := base + 0x30580C0       
             B_iMouseButtons := B_InputStructure + 0x0      ; 1 Byte    MouseButton state 1 for Lbutton,  2 for middle mouse, 4 for rbutton
             B_iSpace := B_iMouseButtons + 0x8              ; 1 Bytes
             B_iNums := B_iSpace + 0x2                      ; 2 Bytes
             B_iChars := B_iNums + 0x2                      ; 4 Bytes 
             B_iTilda := B_iChars + 0x4                     ; 1 Byte  (could be 2 bytes)
             B_iNonAlphNumChars := B_iTilda + 0x2           ; 2 Bytes - keys: [];',./ Esc Entr \
             B_iNonCharKeys := B_iNonAlphNumChars + 0x2     ; 2 Bytes - keys: BS Up Down Left Right Ins Del Hom etc scrl lock pause caps + tab
             B_iFkeys := B_iNonCharKeys + 0x2               ; 2 bytes       
             B_iModifiers := B_iFkeys + 0x6                 ; 1 Byte



         B_CameraMovingViaMouseAtScreenEdge := base + 0x03114D30        ; Really a 1 byte value value indicates which direction screen will scroll due to mouse at edge of screen
             01_CameraMovingViaMouseAtScreenEdge := 0x2C0               ; 1 = Diagonal Left/Top         4 = Left Edge
             02_CameraMovingViaMouseAtScreenEdge := 0x20C               ; 2 = Top                       5 = Right Edge          
             03_CameraMovingViaMouseAtScreenEdge := 0x5A4               ; 3 = Diagonal Right/Top        6 = Diagonal Left/ Bot  
                                                                        ; 7 = Bottom Edge               8 = Diagonal Right/Bot 
                                                                        ; Note need to do a pointer scan with max offset > 1200d!
         B_IsGamePaused := base + 0x31FEF1D                         

         B_FramesPerSecond := base + 0x04FBD484
         B_Gamespeed  := base + 0x4EFE5E8

         B_ReplayFolder :=  base + 0x4F7B228 ;0x04F701F8

         B_HorizontalResolution := base + 0x4FF9DD8
         B_VerticalResolution := B_HorizontalResolution + 0x4
