#Include <Class_LV_Colors>
class _ClassSCPatternScan
{ 	
	mem := new _ClassMemory(GameIdentifier) ; set when new is used

	B_Timer()
	{
		if (address := this.mem.modulePatternScan("", 0x01, 0x0D, "?", "?", "?", "?", 0xF6, 0xD2)) > 0
			return this.mem.Read(address + 2)	
	}
	P_SelectionPage()
	{
		if (address := this.mem.modulePatternScan("", 0x4B, 0x23, 0xC3, 0x5B, 0x74, 0x16, 0x38, 0x48, 0x27, 0x75, 0x11, 0xA1, "?", "?", "?", "?")) > 0
			return this.mem.Read(address + 12) 	
	}	
	B_LocalPlayerSlot()
	{
		if (address := this.mem.modulePatternScan("", 0xA0, "?", "?", "?", "?", 0x38, 0x41, 0x44, 0x74, 0x53)) > 0
			return this.mem.Read(address+1)
	}
	B_pStructureNuke(byRef structureSize := "")
	{
		structureSize := ""
		if (address := this.mem.modulePatternScan("", 0xF, 0xB6, 0xC1, 0x69, 0xC0, "?", "?", 0, 0, 0x5)) > 0
			return this.mem.Read(address+10), structureSize := this.mem.Read(address+5)
	}
	B_pStructure(byRef structureSize := "")
	{
		structureSize := ""
		if (address := this.mem.modulePatternScan("", 0x21, 0x88, "?", "?", "?", "?", 0x05, "?", "?", "?", "?", 0x3D, "?", "?", "?", "?", 0x72, 0xEE)) > 0
			return this.mem.Read(address+2), structureSize := this.mem.Read(address+7) 		
	}
	P_IdleWorker()
	{
		if (address := this.mem.modulePatternScan("", 0x84, 0xC0, 0x0F, 0x84, "?", "?", "?", "?", 0xA1, "?", "?", "?", "?", 0x53)) > 0
			return  this.mem.Read(address+9)
	}
	P_ChatFocus()
	{
		if (address := this.mem.modulePatternScan("", 0x83, 0x3D, "?", "?", "?", "?", "?", 0x74, 0x0F, 0x80, 0x3D, "?", "?", "?", "?", "?", 0x74, 0x06)) > 0
			return this.mem.Read(address+2)
	}
	P_MenuFocus()
	{
		if (address := this.mem.modulePatternScan("", 0xA1, "?", "?", "?", "?", 0x8B, 0x90, "?", "?", "?", "?", 0x8B, 0x88, "?", "?", "?", "?", 0x8B, 0x45, 0x08)) > 0
			return this.mem.Read(address+1)
	}
	Offsets_UnitHighestAliveIndex(byRef sizeUnitStructure := "") ;S_uStructure
	{
		sizeUnitStructure := ""
		if (address := this.mem.modulePatternScan("",  0x8B, 0x1D, "?", "?", "?", "?", 0x83, 0xC3, "?", 0xC1, 0xEB, 0x04, 0x03, 0xDB, 0x03, 0xDB, 0x8B, 0xC3)) > 0
			return  this.mem.Read(address + 2)
	}
	B_uStructure(byRef sizeUnitStructure := "")
	{
		sizeUnitStructure := ""
		if (address := this.mem.modulePatternScan("",  0x73, 0x33, 0x69, 0xC0, "?", "?", "?", "?", 0x05, "?", "?", "?", "?", 0x33, 0xC9, 0x3B, 0x10, 0x0F, 0x95, 0xC1)) > 0
			return this.mem.Read(address + 9), sizeUnitStructure := this.mem.Read(address + 4)
	}
	/* Local selection buffer
	SC2.AssertAndCrash+22AC1A - 0F84 C4020000         - je SC2.AssertAndCrash+22AEE4
	SC2.AssertAndCrash+22AC20 - 53                    - push ebx
	SC2.AssertAndCrash+22AC21 - 57                    - push edi
	SC2.AssertAndCrash+22AC22 - 68 08BC2803           - push SC2.exe+1EEBC08 - selection buffer
	SC2.AssertAndCrash+22AC27 - 8D 8D 34F0FFFF        - lea ecx,[ebp-00000FCC]
	SC2.AssertAndCrash+22AC2D - E8 AEE1FFFF           - call SC2.AssertAndCrash+228DE0
	SC2.AssertAndCrash+22AC32 - 33 C0                 - xor eax,eax
	*/
	Offsets_Selection_Base()
	{
		if (address := this.mem.modulePatternScan("",  0x53, 0x57, 0x68, "?", "?", "?", "?", 0x8D, "?", "?", "?", "?", "?", 0xE8, "?", "?", "?", "?", 0x33, 0xC0)) > 0
			return this.mem.Read(address + 3)
	}	
	/*
	SC2.AssertAndCrash+22C099 - E8 F2D8FFFF           - call SC2.AssertAndCrash+229990
	SC2.AssertAndCrash+22C09E - 68 08BC2803           - push SC2.exe+1EEBC08 ; selection 
	SC2.AssertAndCrash+22C0A3 - 53                    - push ebx
	SC2.AssertAndCrash+22C0A4 - B9 C8F22803           - mov ecx,SC2.exe+1EEF2C8  ; ctrl group 0
	SC2.AssertAndCrash+22C0A9 - E8 423C1A01           - call SC2.GetBattlenetAllocator+226690
	SC2.AssertAndCrash+22C0AE - 84 C0                 - test al,al
	SC2.AssertAndCrash+22C0B0 - 74 11                 - je SC2.AssertAndCrash+22C0C3
	*/
	Offsets_Group_ControlGroup0(byRef Offsets_Selection_Base := "")
	{
		if (address := this.mem.modulePatternScan("", 0xE8, "?", "?", "?", "?", 0x68, "?", "?", "?", "?", 0x53, 0xB9, "?", "?", "?", "?", 0xE8,  "?", "?", "?", "?", 0x84, 0xC0, 0x74, 0x11)) > 0
			return this.mem.Read(address + 12), Offsets_Selection_Base := this.mem.Read(address + 6)
	}
	/*	 This is about 10 lines below the above pattern
	SC2.AssertAndCrash+22C0DA - 0FB6 CB               - movzx ecx,bl
	SC2.AssertAndCrash+22C0DD - B8 01000000           - mov eax,00000001
	SC2.AssertAndCrash+22C0E2 - D3 E0                 - shl eax,cl
	SC2.AssertAndCrash+22C0E4 - 69 C9 601B0000        - imul ecx,ecx,00001B60  - size ctrl group
	SC2.AssertAndCrash+22C0EA - 8D 91 C8F22803        - lea edx,[ecx+SC2.exe+1EEF2C8] ctrl group base (array)
	SC2.AssertAndCrash+22C0F0 - 57                    - push edi
	SC2.AssertAndCrash+22C0F1 - F7 D0                 - not eax
	SC2.AssertAndCrash+22C0F3 - 21 05 04BC2803        - and [SC2.exe+1EEBC04],eax selection base -4
	*/
	
	Offsets_Group_ControlGroupSize(byRef OffsetsControlGroup0Base := "")
	{
		if (address := this.mem.modulePatternScan("",  0xD3, 0xE0, 0x69, 0xC9, "?", "?", "?", "?",  0x8D, 0x91, "?", "?", "?", "?", 0x57)) > 0
			return this.mem.Read(address + 4), OffsetsControlGroup0Base := this.mem.Read(address + 10)
	}
	/* Offsets_TeamColoursEnabled
	SC2.AssertAndCrash+157ECA - 8B 45 EC              - mov eax,[ebp-14]
	SC2.AssertAndCrash+157ECD - 0F95 C2               - setne dl
	SC2.AssertAndCrash+157ED0 - A3 44C1F102           - mov [SC2.exe+1B7C144],eax
	SC2.AssertAndCrash+157ED5 - 8B 45 F0              - mov eax,[ebp-10]
	SC2.AssertAndCrash+157ED8 - 88 55 E8              - mov [ebp-18],dl
	*/		
	Offsets_TeamColoursEnabled()
	{
		if (address := this.mem.modulePatternScan("", 0x8B, 0x45, 0xEC, 0x0F, 0x95, 0xC2, 0xA3, "?", "?", "?", "?", 0x8B, 0x45, 0xF0, 0x88, 0x55, 0xE8)) > 0
			return this.mem.Read(address + 7)
	}
	B_MapStruct()
	{
		if (address := this.mem.modulePatternScan("", 0xC1, 0xE0, 0x0C, 0xC1, 0xE2, 0x0C, 0x4E, 0x49, 0xA3, "?", "?", "?", "?")) > 0
			return this.mem.Read(address + 9) - 0xDC ; This is actually O_mLeft so need to -0xDC offset
	}
	B_camLeft()
	{
		if (address := this.mem.modulePatternScan("", 0x8B, 0x16, 0x89, 0x15, "?", "?", "?", "?", 0x8B, 0x46, 0x04, 0xA3)) > 0
			return this.mem.Read(address + 4)
	}
	P_IsUserPerformingAction(byRef B_UnitCursor := "")
	{
		if (address := this.mem.modulePatternScan("", 0x83, 0x3D, "?", "?", "?", "?", 0x00, 0x74, 0x0F, 0x80, 0x3D, "?", "?", "?", "?", 0x00, 0x74, 0x06)) > 0
			return this.mem.Read(address + 2), B_UnitCursor := this.mem.Read(address + 2) ; Change this ** theyre the same
	}
	P_IsBuildCardDisplayed()
	{
		if (address := this.mem.modulePatternScan("", 0x53, 0x8B, 0x1D, "?", "?", "?", "?", 0xEB, 0x09, 0x8D, 0x9B, "?", "?", "?", "?", 0x8B, 0x7D, 0xFC)) > 0
			return this.mem.Read(address + 3)
	}
	B_CameraDragScroll()
	{
		if (address := this.mem.modulePatternScan("", 0xA1, "?", "?", "?", "?", 0x83, 0xE8, 0x00, 0x0F, 0xBF, 0xD6)) > 0
			return this.mem.Read(address + 1)
	}
	B_CameraMovingViaMouseAtScreenEdge()
	{
		if (address := this.mem.modulePatternScan("", 0x0F, 0x84, "?", "?", "?", "?", 0xA1, "?", "?", "?", "?", 0x53, 0x56, 0x8B, 0xB0)) > 0
			return this.mem.Read(address + 7)
	}
/* pause. This pattern will almost certainly break on updates!!! - just testing it. Its purposely obfuscated.
There are numerous viable pause addresses, but the first one to change seems to be obfuscated
base
SC2.AssertAndCrash+3AF52 - E8 D9476600           - call SC2.AllowCachingSupported+1EB0
SC2.AssertAndCrash+3AF57 - 8B 0D E4C89401        - mov ecx,[SC2.exe+188C8E4]
SC2.AssertAndCrash+3AF5D - 33 0D 047F7505        - xor ecx,[SC2.exe+5697F04]
SC2.AssertAndCrash+3AF63 - 81 F1 DA034845        - xor ecx,454803DA
SC2.AssertAndCrash+3AF69 - 74 08                 - je SC2.AssertAndCrash+3AF73
SC2.AssertAndCrash+3AF6B - 8B 11                 - mov edx,[ecx]
SC2.AssertAndCrash+3AF6D - 8B 42 18              - mov eax,[edx+18]
----------------------
offset
SC2.GetBattlenetAllocator+46D52 - 33 C0                 - xor eax,eax
SC2.GetBattlenetAllocator+46D54 - 39 45 0C              - cmp [ebp+0C],eax
SC2.GetBattlenetAllocator+46D57 - F7 D1                 - not ecx
SC2.GetBattlenetAllocator+46D59 - 0F95 C0               - setne al
SC2.GetBattlenetAllocator+46D5C - 89 86 40630100        - mov [esi+00016340],eax  offset - esi = base 
SC2.GetBattlenetAllocator+46D62 - 89 4F 4C              - mov [edi+4C],ecx
SC2.GetBattlenetAllocator+46D65 - F7 D1                 - not ecx
SC2.GetBattlenetAllocator+46D67 - 33 8E 44630100        - xor ecx,[esi+00016344]


0x39, 0x45, 0x0C, 0xF7, 0xD1, 0x0F, 0x95, 0xC0, 0x89, 0x86, "?", "?", "?", "?", 0x89, 0x4F, 0x4C, 0xF7, 0xD1
*/	
	Offsets_IsGamePaused()
	{
		if (address := this.mem.modulePatternScan("", 0xE8, "?", "?", "?", "?", 0x8B, 0x0D, "?", "?", "?", "?", 0x33, 0x0D, "?", "?", "?", "?", 0x81, 0xF1, "?", "?", "?", "?", 0x74, "?", 0x8B, 0x11, 0x8B, 0x42, 0x18)) <= 0
			return 
		v1 := this.mem.Read(this.mem.Read(address + 7))
		v2 := this.mem.Read(this.mem.Read(address + 13))		
		v3 := this.mem.Read(address + 19)
		base := v1 ^ v2 ^ v3
		if (address := this.mem.modulePatternScan("", 0x33, 0xC0, 0x39, 0x45, 0x0C, 0xF7, 0xD1, 0x0F, 0x95, 0xC0, 0x89, 0x86, "?", "?", "?", "?", 0x89, 0x4F, 0x4C, 0xF7, 0xD1, 0x33, 0x8E)) <= 0
			return
		offset := this.mem.Read(address + 12)	
		return base + offset 			
	}	
	B_FramesPerSecond()
	{
		if (address := this.mem.modulePatternScan("", 0xA3, "?", "?", "?", "?", 0x0F, 0x84, "?", "?", "?", "?", 0x03, 0xC6, 0xD1, 0xE8, 0x8B, 0xC8)) > 0
			return this.mem.Read(address + 1)				
	}
	/*
	Base - again this is obfuscated and will most certainly break on update
	SC2.GetBattlenetAllocator+233C47 - FF D2                 - call edx
	SC2.GetBattlenetAllocator+233C49 - 8B 0D E4C86E02        - mov ecx,[SC2.exe+188C8E4]
	SC2.GetBattlenetAllocator+233C4F - 33 0D 047F4F06        - xor ecx,[SC2.exe+5697F04]
	SC2.GetBattlenetAllocator+233C55 - 6A 00                 - push 00
	SC2.GetBattlenetAllocator+233C57 - 81 F1 DA034845        - xor ecx,454803DA

	offset
	SC2.GetBattlenetAllocator+3C578 - 75 09                 - jne SC2.GetBattlenetAllocator+3C583
	SC2.GetBattlenetAllocator+3C57A - 8B 45 08              - mov eax,[ebp+08]
	SC2.GetBattlenetAllocator+3C57D - 89 86 20630100        - mov [esi+00016320],eax
	SC2.GetBattlenetAllocator+3C583 - 5E                    - pop esi
	SC2.GetBattlenetAllocator+3C584 - 5D                    - pop ebp
	SC2.GetBattlenetAllocator+3C585 - C2 0800               - ret 0008

	*/
	; Need to be in a game to work!	
	Offsets_GameSpeed()
	{
		if (address := this.mem.modulePatternScan("", 0xFF, 0xD2, 0x8B, 0x0D, "?", "?", "?", "?", 0x33, 0x0D, "?", "?", "?", "?", 0x6A, 0x00, 0x81, 0xF1)) <= 0
			return
		v1 := this.mem.Read(this.mem.Read(address + 4))
		v1 ^= this.mem.Read(this.mem.Read(address + 10))	
		v1 ^= this.mem.Read(address + 18)
		if (address := this.mem.modulePatternScan("", 0x75, 0x09, 0x8B, 0x45, 0x08, 0x89, 0x86, "?", "?", "?", "?", 0x5E, 0x5D, 0xC2, 0x08, 0x00)) <= 0
			return 
		return v1 + this.mem.Read(address + 7)
					
	}
	B_ReplayFolder()
	{
		; Finds string \Replays\ (with null terminator) and then walks back to find the start of the string
		; Not a great pattern, just use it then validate in CE
		; This relies on there being a 00 byte just before the string (not necessarily true)
		; This valid string/address occurs at lower memory addresses than the other non-valid copies (ones which change on client restart)
		; A custom map (from map editor from this folder) name could occur before this (could use regex to check for this)
		if (address := this.mem.modulePatternScan("", 0x5C, 0x52, 0x65, 0x70, 0x6C, 0x61, 0x79, 0x73, 0x5C, 0x00)) > 0
		{
			while A_Index < 200 
			{
				if this.mem.Read(--address, "UChar") = 0
					return address + 1
			}
		}
	}	
	B_InputStructure()
	{
		if (address := this.mem.modulePatternScan("", 0x33, 0xC9, 0x89, 0x48, 0x18, 0x8B, 0x15, "?", "?", "?", "?")) > 0
			return this.mem.Read(address + 7)
	}
/*
DB ? ? 89 0D ? ? ? ? 89 15 ? ? ? ? 85 C9
SC2.AssertAndCrash+62C3AB - DB 45 FC              - fild dword ptr [ebp-04]
SC2.AssertAndCrash+62C3AE - 89 0D 44527103        - mov [SC2.exe+2375244],ecx
SC2.AssertAndCrash+62C3B4 - 89 15 48527103        - mov [SC2.exe+2375248],edx
SC2.AssertAndCrash+62C3BA - 85 C9                 - test ecx,ecx
*/	

	B_HorizontalResolution()
	{
		if (address := this.mem.modulePatternScan("", 0xDB, "?", "?", 0x89, 0x0D, "?", "?", "?", "?", 0x89, 0x15, "?", "?", "?", "?", 0x85, 0xC9)) > 0 ; Second group of ?s isVertical res
			return this.mem.Read(address + 5)
	}
	B_localArmyUnitCount()
	{
		if (address := this.mem.modulePatternScan("", 0xA1, "?", "?", "?", "?", 0x89, 0x45, 0xEC, 0x8B, 0xD8, 0x8B, 0xCF)) > 0
			return this.mem.Read(address + 1)
	}
	
	listView()
	{
		Gui, SCPatternScan:New  ; destroy previous windows with same name
		Gui, Add, ListView, Grid -LV0x10 NoSortHdr hwndHLV +resize w450 r34, Name|Address|Offset|Loaded Offset
		LV_Colors.OnMessage()
		LV_Colors.Attach(HLV, True, True, False) ; Im not sure if you need to call detach(). The author of the class makes no mention of it.
		for i, params in this.scanAndCombine()
		{
			LV_Add("", params*)
			if params.3 = params.4 && params.3 != ""
				LV_Colors.Row(HLV, A_Index, 0x36FC87) 	; Green match
			else LV_Colors.Row(HLV, A_Index, 0xFF4444) 	; Red error 
		}
		loop, % LV_GetCount("Column")
			LV_ModifyCol(A_Index, "AutoHdr") ; resize contents+header
		LV_ModifyCol(1, "Text Sort")
		Gui, Add, Button, Default g__SCPatternScanClipboardDump, Dump To Clipboard
		Gui, Show,, Pattern Scan
		GuiControl, +Redraw, %HLV% ; This needs to be here for LV_Colours to work
		return 
		__SCPatternScanClipboardDump:
		clipboard := ColumnJustify(Table_FromListview())
		return 
		
		SCPatternScanGuiClose:
		SCPatternScanGuiEscape:
		Gui Destroy
		return 
	}
	; Returns an array of arrays
	; each individual array has 4 items. 
	; 		1  Name of offset
	;		2  Current memory address (includes SC Base address)
	;		3  Offset of address relative to SC base address
	; 		4  The value for this offset which is currently being used in macroTrainer

	scanAndCombine()
	{
		setformat, IntegerFast, H ;This isn't called from autoExec so don't bother changing it back. Easy way to ensure displayed as hex while using FastMode and not having to do conversions
		obj := OrderedArray()
		methods :=	"B_Timer|B_Timer|P_SelectionPage|B_LocalPlayerSlot|P_IdleWorker|P_ChatFocus|P_MenuFocus|Offsets_Selection_Base|Offsets_TeamColoursEnabled|B_MapStruct|B_camLeft|P_IsBuildCardDisplayed"
				. 	"|B_CameraDragScroll|B_CameraMovingViaMouseAtScreenEdge|Offsets_IsGamePaused|B_FramesPerSecond|Offsets_GameSpeed (must be in game)|B_ReplayFolder|B_InputStructure|B_HorizontalResolution|B_localArmyUnitCount"
		loop, parse, methods, |
			obj[A_LoopField] := this[StrSplit(A_LoopField, A_Space).1]()
		obj["B_pStructure Copy"] := this.B_pStructureNuke(structureSize), obj["S_pStructure Copy"] := structureSize
		obj["B_pStructure"] := this.B_pStructure(structureSize), obj["S_pStructure"] := structureSize
		obj["Offsets_UnitHighestAliveIndex"] := this.Offsets_UnitHighestAliveIndex()
		obj["B_uStructure"] := this.B_uStructure(structureSize), obj["S_uStructure"] := structureSize
		obj["Offsets_Group_ControlGroup0"] := this.Offsets_Group_ControlGroup0(offset), obj["Offsets_Selection_Base Copy"] := offset
		obj["Offsets_Group_ControlGroupSize"] := this.Offsets_Group_ControlGroupSize(offset), obj["Offsets_Group_ControlGroup0 Copy"] := offset
		obj["P_IsUserPerformingAction"] := this.P_IsUserPerformingAction(unitUnderCursor), obj["B_UnitCursor"] := unitUnderCursor		
		array := []
		for k, v in obj
		{
			if (v = "")
				actual := ""
			else if this.mem.baseaddress >= v ; size of a structure
				actual := v
			else actual := v - this.mem.baseaddress
			currentlyUsedVarName := StrSplit(k, A_Space).1 ; Some keys have spaces as they are backups, so not a valid variable name. The space separates the real name from the extra info
			if this.mem.baseaddress < currentValue := %currentlyUsedVarName%
				currentValue -= this.mem.baseaddress
			array.insert([k, v, actual, currentValue]) ;
		}
		return array
	}
	scanToText()
	{
		s .= "Name|Address|Offset|Loaded Offset"
		for i, array in this.scanAndCombine()
		{
			s .= "`n" 
			for i, v in array
				s .= (A_Index != 1 ? "|" : "") v
		}
		return ColumnJustify(s,, "|")
	}

}
