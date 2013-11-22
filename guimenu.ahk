
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
	aQuickSelectCopy[Race, "IndexGUI"] := round(aQuickSelectCopy[Race, "IndexGUI"] + 1)
	aQuickSelectCopy[Race, "MaxIndexGUI"] := round(aQuickSelectCopy[Race, "MaxIndexGUI"] + 1)
	GUIControl, , GroupBox%race%QuickSelect, % " Quick Select Navigation " aQuickSelectCopy[Race].IndexGUI " of " aQuickSelectCopy[Race, "MaxIndexGUI"]
	GUIControl, , GroupBoxItem%race%QuickSelect, % " Quick Select Item " aQuickSelectCopy[Race].IndexGUI
	
	blankQuickSelectGUI(race)
}
else if instr(A_GuiControl, "Delete")
{

	aQuickSelectCopy[Race].remove(aQuickSelectCopy[Race, "IndexGUI"])

	if (aQuickSelectCopy[Race, "MaxIndexGUI"] = 1)
	{
		blankQuickSelectGUI(race)
		return
	}
	if (aQuickSelectCopy[Race, "IndexGUI"] > 1)
		aQuickSelectCopy[Race, "IndexGUI"] := round(aQuickSelectCopy[Race, "IndexGUI"] - 1)
	aQuickSelectCopy[Race, "MaxIndexGUI"] := round(aQuickSelectCopy[Race, "MaxIndexGUI"] - 1)
	GUIControl, , GroupBox%race%QuickSelect, % " Quick Select Navigation " aQuickSelectCopy[Race].IndexGUI " of " aQuickSelectCopy[Race, "MaxIndexGUI"]
	GUIControl, , GroupBoxItem%race%QuickSelect, % " Quick Select Item " aQuickSelectCopy[Race].IndexGUI
	showQuickSelectItem(race, aQuickSelectCopy)
}
else if instr(A_GuiControl, "Next")
{
	if (aQuickSelectCopy[Race, "MaxIndexGUI"] = 1)
		return 
	saveCurrentQuickSelect(race, aQuickSelectCopy)
	if (aQuickSelectCopy[Race, "IndexGUI"] = aQuickSelectCopy[Race, "MaxIndexGUI"])
		aQuickSelectCopy[Race, "IndexGUI"] := 1
	else 
		aQuickSelectCopy[Race, "IndexGUI"] := round(aQuickSelectCopy[Race, "IndexGUI"] + 1)
	GUIControl, , GroupBox%race%QuickSelect, % " Quick Select Navigation " aQuickSelectCopy[Race].IndexGUI " of " aQuickSelectCopy[Race, "MaxIndexGUI"]
	GUIControl, , GroupBoxItem%race%QuickSelect, % " Quick Select Item " aQuickSelectCopy[Race].IndexGUI
	showQuickSelectItem(race, aQuickSelectCopy)		
}
else if instr(A_GuiControl, "Previous")
{

	if (aQuickSelectCopy[Race, "MaxIndexGUI"] = 1)
		return 
	saveCurrentQuickSelect(race, aQuickSelectCopy)
	if (aQuickSelectCopy[Race, "IndexGUI"] = 1)
		aQuickSelectCopy[Race, "IndexGUI"] := aQuickSelectCopy[Race, "MaxIndexGUI"]
	else 
		aQuickSelectCopy[Race, "IndexGUI"] := round(aQuickSelectCopy[Race, "IndexGUI"] - 1)
	GUIControl, , GroupBox%race%QuickSelect, % " Quick Select Navigation " aQuickSelectCopy[Race].IndexGUI " of " aQuickSelectCopy[Race, "MaxIndexGUI"]	
	GUIControl, , GroupBoxItem%race%QuickSelect, % " Quick Select Item " aQuickSelectCopy[Race].IndexGUI
	showQuickSelectItem(race, aQuickSelectCopy)
}

state := aQuickSelectCopy[Race, "MaxIndexGUI"] > 1 ? True : False
GUIControl, Enable%state%, Next%race%QuickSelect
GUIControl,  Enable%state%, Previous%race%QuickSelect

return 

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
	arrayPosition := aQuickSelectCopy[Race, "IndexGUI"]
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

	arrayPosition := aQuickSelectCopy[Race, "IndexGUI"]
	
	aQuickSelectCopy[Race, arrayPosition] := []
	aQuickSelectCopy[Race, arrayPosition, "enabled"] := enabled
	aQuickSelectCopy[Race, arrayPosition, "hotkey"] := hotkey
	aQuickSelectCopy[Race, arrayPosition, "units"] := []
	
	includesTransport := False
	StringReplace, units, units, `,, `n, All ; in case user writes a comma
	StringReplace, units, units, %A_Space%, `n, All 
	while InStr(units, "`n`n")
		StringReplace, units, units, `n`n, `n, All 
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