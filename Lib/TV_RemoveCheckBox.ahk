TV_RemoveCheckBox(treeViewHandle, nodeHandle)
{
	static tvi := struct("
						(
						  UINT      mask;
						  Ptr hItem;
						  UINT      state;
						  UINT      stateMask;
						  LPTSTR    pszText;
						  int       cchTextMax;
						  int       iImage;
						  int       iSelectedImage;
						  int       cChildren;
						  LPARAM    lParam;
						)"
						, {state: 0, mask: 0x8, stateMask: 0xF000}) ; mask = TVIF_STATE, stateMask = TVIS_STATEIMAGEMASK
	tvi.hItem := nodeHandle 
	sendmessage, 4415, 0, tvi[],, AHK_ID %treeViewHandle% ; msg TVM_SETITEM = 4415  
	return 
}