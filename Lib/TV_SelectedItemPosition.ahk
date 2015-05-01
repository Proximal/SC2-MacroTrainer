; Returns the selected childs position. One based. 0 if has no children
; e.g.
; parent
; 	child 1 --> 1
; 	child 2 --> 2

TV_SelectedItemPosition(selectedID, parentID)
{
	if !currentID := TV_GetChild(parentID) ; get the ID of the top alert in this gamemode list
		return 0 ; so doesn't return A_Index = 1 in loop if it has no parent
	selectedIndex := 0 
	loop 
	{
		if (currentID = selectedID)
		{
			selectedIndex := A_Index 
			break
		}			
	} until 0 = currentID := TV_GetNext(currentID)	 ; end of list 
	return selectedIndex
}