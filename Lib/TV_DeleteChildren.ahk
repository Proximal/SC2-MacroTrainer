TV_DeleteChildren(parentID)
{
	if !itemID := TV_GetChild(parentID)
		return 
	loop 
		nextItemID := TV_GetNext(itemID), TV_Delete(itemID)
	 until !nextItemID, itemID := nextItemID ; Have to call TV_getNext before deleting item!
	return
}