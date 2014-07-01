AutoChronoGui:
if instr(A_GuiControl, "New")
{
	if !retrieveItemsFromListView("AutoChronoListView").MaxIndex()
	{
		msgbox, % 64 + 8192 + 262144, New Item, The current structure field is empty.`n`nPlease add some structures before creating a new item.
		return
	}
	saveCurrentAutoChronoItem(aAutoChronoCopy)
	if blankIndex := autoChronoFindPosiitionWithNoUnits(aAutoChronoCopy) 
	{
		aAutoChronoCopy["IndexGUI"] := blankIndex
		showAutoChronoItem(aAutoChronoCopy)
	}
	else 
	{
		aAutoChronoCopy["IndexGUI"] := aAutoChronoCopy["MaxIndexGUI"] := round(aAutoChronoCopy["MaxIndexGUI"] + 1)	
		blankAutoChronoGUI()
	}
}
else if instr(A_GuiControl, "Delete")
{

	aAutoChronoCopy["Items"].remove(aAutoChronoCopy["IndexGUI"])

	if (aAutoChronoCopy["MaxIndexGUI"] = 1)
	{
		blankAutoChronoGUI()
		return
	}
	if (aAutoChronoCopy["IndexGUI"] > 1)
		aAutoChronoCopy["IndexGUI"] := round(aAutoChronoCopy["IndexGUI"] - 1)
	aAutoChronoCopy["MaxIndexGUI"] := round(aAutoChronoCopy["MaxIndexGUI"] - 1)
	showAutoChronoItem(aAutoChronoCopy)
}
else if instr(A_GuiControl, "Next")
{
	if (aAutoChronoCopy["MaxIndexGUI"] = 1)
		return 
	saveCurrentAutoChronoItem(aAutoChronoCopy)
	if (aAutoChronoCopy["IndexGUI"] >= aAutoChronoCopy["MaxIndexGUI"])
		aAutoChronoCopy["IndexGUI"] := 1
	else 
		aAutoChronoCopy["IndexGUI"] := round(aAutoChronoCopy["IndexGUI"] + 1)
	showAutoChronoItem(aAutoChronoCopy)	
}
else if instr(A_GuiControl, "Previous")
{
	if (aAutoChronoCopy["MaxIndexGUI"] = 1)
		return 
	saveCurrentAutoChronoItem(aAutoChronoCopy)
	if (aAutoChronoCopy["IndexGUI"] <= 1)
		aAutoChronoCopy["IndexGUI"] := aAutoChronoCopy["MaxIndexGUI"]
	else 
		aAutoChronoCopy["IndexGUI"] := round(aAutoChronoCopy["IndexGUI"] - 1)
	showAutoChronoItem(aAutoChronoCopy)	
}
; so doesnt get set to 0
if (aAutoChronoCopy["IndexGUI"] <= 0)
	aAutoChronoCopy["IndexGUI"] := 1
if (aAutoChronoCopy["MaxIndexGUI"] <= 0)
	aAutoChronoCopy["MaxIndexGUI"] := 1	
GUIControl, , GroupBoxAutoChrono, % "Chrono Navigation " aAutoChronoCopy["IndexGUI"] " of " aAutoChronoCopy["MaxIndexGUI"]	
GUIControl, , GroupBoxItemAutoChrono, % "Chrono Item " aAutoChronoCopy["IndexGUI"]
state := (aAutoChronoCopy["MaxIndexGUI"] > 1)
GUIControl, Enable%state%, NextAutoChrono
GUIControl,  Enable%state%, PreviousAutoChrono
return 


MoveUpUnitAutoChrono:
for row, unitName in retrieveSelectedItemsFromListView("AutoChronoListView") ; MultiSelect disabled so should only be 1 item
{
	if (row > 1)
	{
		removeItemFromListView(unitName)
		LV_Insert(row -1, "Select Focus", unitName)
	}
}
GuiControl, Focus, AutoChronoListView ; so that the selected item background is blue (as user pressed the up/down button)
LV_ModifyCol(1, "AutoHdr") ; resize column if user altered it
return
; When moving down easiest to start with the bottom row then work up
MoveDownUnitAutoChrono:
aSelectedRows := retrieveSelectedItemsFromListView("AutoChronoListView") 
while aSelectedRows.MaxIndex()
{
	if (aSelectedRows.MaxIndex() < LV_GetCount())
	{
		removeItemFromListView(aSelectedRows[aSelectedRows.MaxIndex()])
		LV_Insert(aSelectedRows.MaxIndex() + 1, "Select Focus", aSelectedRows[aSelectedRows.MaxIndex()])
	}
	aSelectedRows.remove(aSelectedRows.MaxIndex())
}
GuiControl, Focus, AutoChronoListView ; so that the selected item background is blue (as user pressed the up/down button)
LV_ModifyCol(1, "AutoHdr") ; resize column if user altered it
return


AddUnitAutoChrono:
Gui, ListView, AutoChronoListView
if newItems := GUISelectionList("Select Structure(s):"
			, "Select structure(s):"
			, "WarpGate|Gateway|Forge|Stargate|RoboticsFacility|Nexus|CyberneticsCore|TwilightCouncil|TemplarArchive|RoboticsBay|FleetBeacon"
			, "|", "|")
{
	firstAddedItem := ""
	loop, parse, newItems, |
	{
		if !isItemInListView(A_LoopField)
			addItemToListview(A_LoopField), (firstAddedItem = "" ? firstAddedItem := A_LoopField : "")
	}
	if firstAddedItem
	{
		LV_Modify(0, "-Select") ; Deselect all otherwise if item was already selected it will be selected along with the first added new item
		LV_Modify(isItemInListView(firstAddedItem), "Select Focus")
		GuiControl, Focus, AutoChronoListView
	}
}
LV_ModifyCol(1, "AutoHdr") ; resize column if user altered it
return

RemoveUnitAutoChrono:
Gui, ListView, AutoChronoListView
for i, item in aSelectedRows := retrieveSelectedItemsFromListView()
	removeItemFromListView(item)
if aSelectedRows.MinIndex() && LV_GetCount()
{
	LV_Modify(aSelectedRows.MinIndex() <= LV_GetCount() ? aSelectedRows.MinIndex() : LV_GetCount(), "Select Focus" )
	GuiControl, Focus, AutoChronoListView ; so that the selected item background is blue (as user pressed the up/down button)
}
LV_ModifyCol(1, "AutoHdr") ; resize column if user altered it
return

iniReadAutoChrono(byRef aAutoChronoCopy, byRef aAutoChrono)
{

	aAutoChronoCopy := [], aAutoChrono := []

	arrayPosition := 0
	; ive just added the forge and stargate here as, the warpages already here
	;[Chrono Boost Gateway/Warpgate]
	section := "Auto Chrono Items"
	loop 
	{
		arrayPosition++
		; itemNumber := arrayPosition
		; Use A_Index, as if no unit exists, then will decrement arrayPosition
		; causing an infinite loop as it reads the same ini key
		itemNumber := A_Index
		IniRead, enabled, %config_file%, %section%, %itemNumber%_enabled, error

		if (enabled = "error")
			break 

		IniRead, hotkey, %config_file%, %section%, %itemNumber%_hotkey, %A_Space%
		IniRead, units, %config_file%, %section%, %itemNumber%_units, %A_Space%

	    aAutoChronoCopy["Items", arrayPosition] := []
	    aAutoChronoCopy["Items", arrayPosition, "enabled"] := enabled
	    aAutoChronoCopy["Items", arrayPosition, "hotkey"] := hotkey
	    aAutoChronoCopy["Items", arrayPosition, "units"] := []

	    unitExists := false
	    ; sort, units, D`, U ; Do not use sort to remove duplicates - as it will also sort them.

	    userPriority := 1
	    loop, parse, units, `,
	    {
	    	unitName := A_LoopField

	    	if aUnitID.HasKey(unitName) && !aAutoChronoCopy["Items", arrayPosition, "units"].HasKey(aUnitID[unitName])
	    	{
	    		; don't use insert as using integer keys so it will move them around
	    		aAutoChronoCopy["Items", arrayPosition, "units", aUnitID[unitName]] := userPriority++
	    		unitExists := True
	    	}
	    }
	    if !unitExists
	    	aAutoChronoCopy["Items"].remove(arrayPosition--) ;post-decrement 
	}
	aAutoChronoCopy["MaxIndexGui"] := Round(aAutoChronoCopy["Items"].MaxIndex())
	
	aAutoChrono := aAutoChronoCopy
	return 
}

iniWriteAndUpdateAutoChrono(byRef aAutoChronoCopy, byRef aAutoChrono)
{
	
	section := "Auto Chrono Items"
	IniDelete, %config_file%, %section% ;clear the list
	for i, object in aAutoChronoCopy["Items"]
	{
		; Use the loop index in case something went wrong and there is a gap in the index of the object 1-->2-->4 
		; as iniread function will stop at first non-existent item
		itemNumber := A_Index 
		for key, value in object
		{
			if (key = "units")
			{
				value := "" , aDuplicateCheck := [] ; can't use sort to remove duplicates as their order is important. (there shouldn't be any anyway)
				aOrder := []
				for unitId, userOrder in object["units"]
				{
					if aUnitName.HasKey(unitId) && !aDuplicateCheck.HasKey(unitId)
						aOrder[userOrder] := aUnitName[unitId], aDuplicateCheck[unitId] := True
				}
				; Have to use another array to rank via user order - otherwise for loop would iterate in order of unitType/ID number
				for userOrder, unitName in aOrder
					value .= unitName ","
				value := Trim(value, " `t`,") ; remove the last comma
			}
			IniWrite, %value%, %config_file%, %section%, %itemNumber%_%key%
		}
	}
	aAutoChrono := aAutoChronoCopy
	return
}


saveCurrentAutoChronoItem(byRef aAutoChronoCopy)
{
	GuiControlGet, enabled,, AutoChronoEnabled
	GuiControlGet, hotkey,, AutoChrono_Key

	arrayPosition := aAutoChronoCopy["IndexGUI"]

	aAutoChronoCopy["Items", arrayPosition] := []
	aAutoChronoCopy["Items", arrayPosition, "enabled"] := enabled
	aAutoChronoCopy["Items", arrayPosition, "hotkey"] := hotkey
	aAutoChronoCopy["Items", arrayPosition, "units"] := []
	userPriority := 1
	for i, unitName in retrieveItemsFromListView("AutoChronoListView")
	{
		if aUnitID.haskey(unitName) && !aAutoChronoCopy["Items", arrayPosition, "units"].HasKey(aUnitID[unitName])
			aAutoChronoCopy["Items", arrayPosition, "units", aUnitID[unitName]] := userPriority++
	}
	; lets just save it anyway so that if the click previous to go back and they havent filled in the units part, 
	; they wont lose what they just entered
;	if !aAutoChronoCopy[Race, arrayPosition, "units"].maxIndex()
;	{
;		GUIControl, , quickSelect%Race%UnitsArmy,
;		aAutoChronoCopy[Race].remove(arrayPosition)
;		return 1 ; No real units were in the text field
;	}
	return 
}

autoChronoFindPosiitionWithNoUnits(byRef aAutoChronoCopy)
{
	loop, 1000
	{
		if !IsObject(aAutoChronoCopy["Items", A_Index])
			break
		if !aAutoChronoCopy["Items", A_Index, "units"].MaxIndex()
			return A_Index
	}
	return 0
}

showAutoChronoItem(byRef aAutoChronoCopy)
{
	arrayPosition := aAutoChronoCopy["IndexGUI"]
	removeAllItemsFromListView("AutoChronoListView")
	for typeID, userOrder in aAutoChronoCopy["Items", arrayPosition, "units"]
	{
		if aUnitName.haskey(typeID)
			LV_Insert(userOrder, "", aUnitName[typeID])
	}
	GUIControl,, AutoChronoEnabled, % round(aAutoChronoCopy["Items", arrayPosition, "enabled"])
	GUIControl,, AutoChrono_Key, % aAutoChronoCopy["Items", arrayPosition, "hotkey"]
	return
}
blankAutoChronoGUI()
{
	GUIControl,, AutoChronoEnabled, 0
	GUIControl,, AutoChrono_Key,
	removeAllItemsFromListView("AutoChronoListView")
	return
}