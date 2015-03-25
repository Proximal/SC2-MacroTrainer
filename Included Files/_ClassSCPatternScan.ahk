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
	B_uHighestIndex(byRef sizeUnitStructure := "") ;S_uStructure
	{
		sizeUnitStructure := ""
		if (address := this.mem.modulePatternScan("",  0x55, 0x8B, 0xEC, 0xA1, "?", "?", "?", "?", 0x57, 0x8B, 0xF9, 0x85, 0xC0, 0x74, 0x5B)) > 0
			return  this.mem.Read(address + 4), sizeUnitStructure := this.mem.Read(address + 0x19)
	}
	B_uStructure(byRef sizeUnitStructure := "")
	{
		sizeUnitStructure := ""
		if (address := this.mem.modulePatternScan("",  0x73, 0x33, 0x69, 0xC0, "?", "?", "?", "?", 0x05, "?", "?", "?", "?", 0x33, 0xC9, 0x3B, 0x10, 0x0F, 0x95, 0xC1)) > 0
			return this.mem.Read(address + 9), sizeUnitStructure := this.mem.Read(address + 4)
	}
	B_SelectionStructure()
	{
		if (address := this.mem.modulePatternScan("",  0x66, 0x83, 0x3D, "?", "?", "?", "?", 0x00, 0x74, 0x15, 0x0F, 0xB7, 0x05)) > 0
			return this.mem.Read(address + 3)
	}	
	B_CtrlGroupStructure(byRef S_CtrlGroup := "")
	{
		if (address := this.mem.modulePatternScan("",  0x53, 0xB9, "?", "?", "?", "?", 0xE8, "?", "?", "?", "?", 0xEB, "?", 0x0F, 0xB6, 0xC3, 0x8B, 0xC8, 0x69, 0xC0, "?", "?", "?", "?")) > 0
			return this.mem.Read(address + 2), S_CtrlGroup := this.mem.Read(address + 20)
	}
	S_CtrlGroup()
	{
		if (address := this.mem.modulePatternScan("",  0x69, 0xF6, "?", "?", "?", "?", 0x03, 0xF0, 0x0F, 0xB7, 0x06)) > 0
			return this.mem.Read(address + 2)
	}
	B_TeamColours()
	{
		if (address := this.mem.modulePatternScan("", 0xA2, "?", "?", "?", "?", 0x8B, 0x45, 0xF4, 0x89, 0x0D, "?", "?", "?", "?")) > 0
			return this.mem.Read(address + 10)
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
	B_IsGamePaused()
	{
		if (address := this.mem.modulePatternScan("", 0x8B, 0x75, 0x08, 0xA2, "?", "?", "?", "?", 0x8B, 0x8F, "?", "?", "?", "?", 0x56)) > 0
			return this.mem.Read(address + 4)				
	}	
	B_FramesPerSecond()
	{
		if (address := this.mem.modulePatternScan("", 0xA3, "?", "?", "?", "?", 0x0F, 0x84, "?", "?", "?", "?", 0x03, 0xC6, 0xD1, 0xE8, 0x8B, 0xC8)) > 0
			return this.mem.Read(address + 1)				
	}	
	; B_Gamespeed is wrong!
	B_Gamespeed()
	{
		if (address := this.mem.modulePatternScan("", 0x51, 0x8B, 0xCF, 0xFF, 0xD2, 0x8B, 0x0D, "?", "?", "?", "?", 0x8B, 0x01)) > 0
		{	
			address := this.mem.Read(address + 7)	
			base := this.mem.Read(address)	

			; This next pattern is for the function which actually changes the game speed. It's passed a couple of parameters game speed as well
			; as the base address (the value base above) - it then adds an offset to the base and writes the game speed
			; This is a shitty signature, as there was another identical function (but had a different offset value) so no way to tell them apart.
			; This signature takes a couple of lines from the next listed function (and all the 'return 3'/CCs between them), so could easily break!!!!!
			if (address := this.mem.modulePatternScan("", 0x55, 0x8B, 0xEC, 0x8B, 0x45, 0x08, 0x89, 0x81, "?", "?", "?", "?", 0x5D, 0xC2, 0x04, 0x00, 0x8B, 0x81, "?", "?", "?", "?", 0xC3, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0x55, 0x8B, 0xEC)) > 0
			{
				offset := this.mem.Read(address + 8)
				return 	base + offset
			}			
		}			
	}	
	B_InputStructure()
	{
		if (address := this.mem.modulePatternScan("", 0x33, 0xC9, 0x89, 0x48, 0x18, 0x8B, 0x15, "?", "?", "?", "?")) > 0
			return this.mem.Read(address + 7)
	}
	B_HorizontalResolution()
	{
		if (address := this.mem.modulePatternScan("", 0xA1, "?", "?", "?", "?", 0x89, 0x01, 0x8B, 0x0D, "?", "?", "?", "?", 0x89, 0x0A)) > 0 ; Second group of ?s isVertical res
			return this.mem.Read(address + 1)
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
		setformat, IntegerFast, H ;This isn't called from autoExec so don't bother changing it back
		obj := OrderedArray()
		methods :=	"B_Timer|B_Timer|P_SelectionPage|B_LocalPlayerSlot|P_IdleWorker|P_ChatFocus|P_MenuFocus|B_SelectionStructure|B_TeamColours|B_MapStruct|B_camLeft|P_IsBuildCardDisplayed"
				. 	"|B_CameraDragScroll|B_CameraMovingViaMouseAtScreenEdge|B_IsGamePaused|B_FramesPerSecond|B_InputStructure|B_HorizontalResolution|B_localArmyUnitCount"
		loop, parse, methods, |
			obj[A_LoopField] := this[A_LoopField]()
		obj["B_pStructure Copy"] := this.B_pStructureNuke(structureSize), obj["S_pStructure Copy"] := structureSize
		obj["B_pStructure"] := this.B_pStructure(structureSize), obj["S_pStructure"] := structureSize
		obj["B_uHighestIndex"] := this.B_uHighestIndex(structureSize), obj["S_uStructure Copy"] := structureSize
		obj["B_uStructure"] := this.B_uStructure(structureSize), obj["S_uStructure"] := structureSize
		obj["B_CtrlGroupStructure"] := this.B_CtrlGroupStructure(structureSize), obj["S_CtrlGroup"] := structureSize
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
			if this.mem.baseaddress >= currentValue := %currentlyUsedVarName%
				currentValue := currentValue
			else currentValue -= this.mem.baseaddress
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
