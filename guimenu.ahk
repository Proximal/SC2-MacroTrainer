
; Still need to save the currently displayed item (incase user hasnt clicked a button
; which goes here to save)

g_QuickSelectGui:
if instr(A_GuiControl, "Terran")
	race := "Terran"
else if instr(A_GuiControl, "Protoss")
	race := "Protoss"
else 
	race := zerg 

if instr(A_GuiControl, "New")
{
	GuiControlGet, units, , quickSelect%Race%UnitsArmy ; comma delimited list
	if !trim(units, " `t`,")
	{
		msgbox, % 64 + 8192 + 262144, New Item, The current unit field is empty.`n`nPlease add some units before creating a new item.
		return
	}
	if saveCurrentQuickSelect(race, aQuickSelectCopy)
		return 
	aQuickSelectCopy[race "IndexGUI"]  := aQuickSelectCopy[race "MaxIndexGUI"] := round(aQuickSelectCopy[race "MaxIndexGUI"] + 1)	
	blankQuickSelectGUI(race)
}
else if instr(A_GuiControl, "Delete")
{

	aQuickSelectCopy[Race].remove(aQuickSelectCopy[race "IndexGUI"])

	if (aQuickSelectCopy[race "MaxIndexGUI"] = 1)
	{
		blankQuickSelectGUI(race)
		return
	}
	if (aQuickSelectCopy[race "IndexGUI"] > 1)
		aQuickSelectCopy[race "IndexGUI"] := round(aQuickSelectCopy[race "IndexGUI"] - 1)
	aQuickSelectCopy[race "MaxIndexGUI"] := round(aQuickSelectCopy[race "MaxIndexGUI"] - 1)
	showQuickSelectItem(race, aQuickSelectCopy)
}
else if instr(A_GuiControl, "Next")
{
	if (aQuickSelectCopy[race "MaxIndexGUI"] = 1)
		return 
	saveCurrentQuickSelect(race, aQuickSelectCopy)
	if (aQuickSelectCopy[race "IndexGUI"] = aQuickSelectCopy[race "MaxIndexGUI"])
		aQuickSelectCopy[race "IndexGUI"] := 1
	else 
		aQuickSelectCopy[race "IndexGUI"] := round(aQuickSelectCopy[race "IndexGUI"] + 1)
	showQuickSelectItem(race, aQuickSelectCopy)		
}
else if instr(A_GuiControl, "Previous")
{

	if (aQuickSelectCopy[race "MaxIndexGUI"] = 1)
		return 
	saveCurrentQuickSelect(race, aQuickSelectCopy)
	if (aQuickSelectCopy[race "IndexGUI"] = 1)
		aQuickSelectCopy[race "IndexGUI"] := aQuickSelectCopy[race "MaxIndexGUI"]
	else 
		aQuickSelectCopy[race "IndexGUI"] := round(aQuickSelectCopy[race "IndexGUI"] - 1)
	showQuickSelectItem(race, aQuickSelectCopy)
}

GUIControl, , GroupBox%race%QuickSelect, % " Quick Select Navigation " aQuickSelectCopy[Race "IndexGUI"] " of " aQuickSelectCopy[race "MaxIndexGUI"]	
GUIControl, , GroupBoxItem%race%QuickSelect, % " Quick Select Item " aQuickSelectCopy[Race "IndexGUI"]
state := aQuickSelectCopy[race "MaxIndexGUI"] > 1 ? True : False
GUIControl, Enable%state%, Next%race%QuickSelect
GUIControl,  Enable%state%, Previous%race%QuickSelect

return 

checkQuickSelectHotkey(race, byRef aQuickSelectCopy)
{
	arrayPosition := aQuickSelectCopy[race "IndexGUI"]
	GuiControlGet, hotkey, , quickSelect%Race%_Key
	if !hotkey
	{
		msgbox, % 64 + 8192 + 262144, New Item, You forgot to assign a hotkey.`n`nPlease set the hotkey before proceeding.
		return True
	}
}

; need to save the current displayed items as they might not be saved yet
; e.g. terran item 3 of 3 is displayed but might not be saved

saveCurrentDisplayedItemsQuickSelect(byRef aQuickSelectCopy)
{
	saveCurrentQuickSelect("Terran", aQuickSelectCopy)
	saveCurrentQuickSelect("Protoss", aQuickSelectCopy)
	saveCurrentQuickSelect("Zerg", aQuickSelectCopy)
}

iniWriteAndUpdateQuickSelect(byRef aQuickSelectCopy, byRef aQuickSelect)
{
	
	; save the currently displayed items for each race (as they might not be saved already)
	lRaces := "Terran,Protoss,Zerg"

	loop, parse, lRaces, `, 
	{
		race := A_LoopField
		section := "quick select " race
		IniDelete, %config_file%, %section% ;clear the list
		for itemNumber, object in aQuickSelectCopy[race]
		{
			for key, value in object
			{
				if (key = "units")
				{
					value := ""
					for i, unitId in  object["units"]
						value .= aUnitName[unitId] ","
					while InStr(value, ",,")
						StringReplace, value, value, `,`,, `,, All	; remove double commands if the name lookup failed and resulted in empty then comma
					value := Trim(value, " `t`,") ; remove the last comma
					sort, value, D`, U ;remove duplicates 
				}
				IniWrite, %value%, %config_file%, %section%, %itemNumber%_%key%
			}
		}
	}
	aQuickSelect := aQuickSelectCopy
	return
}

iniReadQuickSelect(byRef aQuickSelectCopy, byRef aQuickSelect)
{
	lRaces := "Terran,Protoss,Zerg"
	
	aQuickSelectCopy := [], aQuickSelect := []

	loop, parse, lRaces, `, 
	{
		arrayPosition := 0
		race := A_LoopField
		section := "quick select " race
		loop 
		{
			arrayPosition++
			itemNumber := arrayPosition
			IniRead, enabled, %config_file%, %section%, %itemNumber%_enabled, error

			if (enabled = "error")
				break 

			IniRead, hotkey, %config_file%, %section%, %itemNumber%_hotkey, %A_Space%
			IniRead, units, %config_file%, %section%, %itemNumber%_units, %A_Space%
			IniRead, storeSelection, %config_file%, %section%, %itemNumber%_storeSelection, off 
			IniRead, DeselectXelnaga, %config_file%, %section%, %itemNumber%_DeselectXelnaga, 0 
			IniRead, DeselectPatrolling, %config_file%, %section%, %itemNumber%_DeselectPatrolling, 0 
			IniRead, DeselectLoadedTransport, %config_file%, %section%, %itemNumber%_DeselectLoadedTransport, 0 
			IniRead, DeselectQueuedDrops, %config_file%, %section%, %itemNumber%_DeselectQueuedDrops, 0 
			IniRead, DeselectHoldPosition, %config_file%, %section%, %itemNumber%_DeselectHoldPosition, 0 
			IniRead, DeselectFollowing, %config_file%, %section%, %itemNumber%_DeselectFollowing, 0 
			IniRead, DeselectFollowing, %config_file%, %section%, %itemNumber%_DeselectFollowing, 0 

		    aQuickSelectCopy[Race, arrayPosition] := []
		    aQuickSelectCopy[Race, arrayPosition, "enabled"] := enabled
		    aQuickSelectCopy[Race, arrayPosition, "hotkey"] := hotkey
		    aQuickSelectCopy[Race, arrayPosition, "units"] := []

		    unitExists := false
		    sort, units, D`, U ;remove duplicates 
		    loop, parse, units, `,
		    {
		    	unitName := A_LoopField

		    	if aUnitID.HasKey(unitName) 
		    	{
		    		aQuickSelectCopy[Race, arrayPosition, "units"].insert(aUnitID[unitName])
		    		unitExists := True
		    	}
		    }

		    aQuickSelectCopy[Race, arrayPosition, "storeSelection"] := storeSelection
		    aQuickSelectCopy[Race, arrayPosition, "DeselectXelnaga"] := DeselectXelnaga
		    aQuickSelectCopy[Race, arrayPosition, "DeselectPatrolling"] := DeselectPatrolling
		    aQuickSelectCopy[Race, arrayPosition, "DeselectLoadedTransport"] := DeselectLoadedTransport
		    aQuickSelectCopy[Race, arrayPosition, "DeselectQueuedDrops"] := DeselectQueuedDrops
		    aQuickSelectCopy[Race, arrayPosition, "DeselectHoldPosition"] := DeselectHoldPosition
		    aQuickSelectCopy[Race, arrayPosition, "DeselectFollowing"] := DeselectFollowing
		    if !unitExists
		    	aQuickSelectCopy[Race].remove(arrayPosition)
		}
		aQuickSelectCopy[race "MaxIndexGui"] := Round(aQuickSelectCopy[race].MaxIndex())
	}	
	aQuickSelect := aQuickSelectCopy
	return 
}



blankQuickSelectGUI(race)
{
	GUIControl, , quickSelect%Race%Enable, 0
	GUIControl, , quickSelect%Race%_Key,
	GUIControl, , quickSelect%Race%UnitsArmy,
	GUIControl, , quickSelect%Race%UnitsArmy,

	GuiControl, ChooseString, QuickSelect%Race%StoreSelection, Off

	GUIControl, , quickSelect%Race%DeselectXelnaga, 0
	GUIControl, , quickSelect%Race%DeselectPatrolling, 0
	GUIControl, , quickSelect%Race%DeselectLoadedTransport, 0
	GUIControl, , quickSelect%Race%DeselectQueuedDrops, 0
	GUIControl, , quickSelect%Race%DeselectHoldPosition, 0
	GUIControl, , quickSelect%Race%DeselectFollowing, 0
}

showQuickSelectItem(Race, byRef aQuickSelectCopy)
{
	arrayPosition := aQuickSelectCopy[race "IndexGUI"]
	for index, unitName in aQuickSelectCopy[Race, arrayPosition, "units"]
	{
		if aUnitName.haskey(unitName)
			units .= aUnitName[unitName] (index != aQuickSelectCopy[Race, arrayPosition, "units"].MaxIndex() ? "`n" : "")
	}

	GUIControl, , quickSelect%Race%enabled, % round(aQuickSelectCopy[Race, arrayPosition, "enabled"])
	GUIControl, , quickSelect%Race%_Key, % aQuickSelectCopy[Race, arrayPosition, "hotkey"]
	GUIControl, , quickSelect%Race%UnitsArmy, %units%
	GuiControl, ChooseString, QuickSelect%Race%StoreSelection, % aQuickSelectCopy[Race, arrayPosition, "storeSelection"] 
																	? aQuickSelectCopy[Race, arrayPosition, "storeSelection"] 
																	: "Off"
	GUIControl, , quickSelect%Race%DeselectXelnaga, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectXelnaga"])
	GUIControl, , quickSelect%Race%DeselectPatrolling, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectPatrolling"])
	GUIControl, , quickSelect%Race%DeselectLoadedTransport, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectLoadedTransport"])
	GUIControl, , quickSelect%Race%DeselectQueuedDrops, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectQueuedDrops"])
	GUIControl, , quickSelect%Race%DeselectHoldPosition, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectHoldPosition"])
	GUIControl, , quickSelect%Race%DeselectFollowing, % round(aQuickSelectCopy[Race, arrayPosition, "DeselectFollowing"])
	
	return
}

saveCurrentQuickSelect(Race, byRef aQuickSelectCopy)
{
	GuiControlGet, enabled, , quickSelect%Race%enabled
	GuiControlGet, hotkey, , quickSelect%Race%_Key
	GuiControlGet, units, , quickSelect%Race%UnitsArmy ; comma delimited list
	GuiControlGet, storeSelection, , QuickSelect%Race%StoreSelection  ; 0-9 or Off
	GuiControlGet, DeselectXelnaga, , quickSelect%Race%DeselectXelnaga
	GuiControlGet, DeselectPatrolling, , quickSelect%Race%DeselectPatrolling
	GuiControlGet, DeselectLoadedTransport, , quickSelect%Race%DeselectLoadedTransport
	GuiControlGet, DeselectQueuedDrops, , quickSelect%Race%DeselectQueuedDrops
	GuiControlGet, DeselectHoldPosition, , quickSelect%Race%DeselectHoldPosition
	GuiControlGet, DeselectFollowing, , quickSelect%Race%DeselectFollowing

	arrayPosition := aQuickSelectCopy[race "IndexGUI"]
	
	aQuickSelectCopy[Race, arrayPosition] := []
	aQuickSelectCopy[Race, arrayPosition, "enabled"] := enabled
	aQuickSelectCopy[Race, arrayPosition, "hotkey"] := hotkey
	aQuickSelectCopy[Race, arrayPosition, "units"] := []
	
	includesTransport := False
	StringReplace, units, units, `,, `n, All ; in case user writes a comma
	StringReplace, units, units, %A_Space%, `n, All 
	StringReplace, units, units, `r,, All
	while InStr(units, "`n`n")
		StringReplace, units, units, `n`n, `n, All 
	sort, units, D`n U ;remove duplicates 
	loop, parse, units, `n
	{
		if aUnitID.haskey(unit := trim(A_LoopField," `t`n`,"))
		{
			aQuickSelectCopy[Race, arrayPosition, "units"].insert(aUnitID[unit])	
			if %unit% in Medivac,WarpPrism,WarpPrismPhasing
				includesTransport := True
		}
	}
	if !aQuickSelectCopy[Race, arrayPosition, "units"].maxIndex()
	{
		GUIControl, , quickSelect%Race%UnitsArmy,
		aQuickSelectCopy[Race].remove(arrayPosition)
		return 1 ; No real units were in the text field
	}
	if !includesTransport
		DeselectLoadedTransport := DeselectQueuedDrops := False

	aQuickSelectCopy[Race, arrayPosition, "storeSelection"] := storeSelection
	aQuickSelectCopy[Race, arrayPosition, "DeselectXelnaga"] := DeselectXelnaga
	aQuickSelectCopy[Race, arrayPosition, "DeselectPatrolling"] := DeselectPatrolling
	aQuickSelectCopy[Race, arrayPosition, "DeselectLoadedTransport"] := DeselectLoadedTransport
	aQuickSelectCopy[Race, arrayPosition, "DeselectQueuedDrops"] := DeselectQueuedDrops
	aQuickSelectCopy[Race, arrayPosition, "DeselectHoldPosition"] := DeselectHoldPosition
	aQuickSelectCopy[Race, arrayPosition, "DeselectFollowing"] := DeselectFollowing

	return 
;	GUIControl, Disable, HighlightInvisible
}