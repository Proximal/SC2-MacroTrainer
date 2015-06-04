paintPictureControl(Handle, Colour, RoundCorner := 0, ControlW := "", ControlH := "")
{ 
	; GuiControlGet will only work for the current GUI thread. Could add a another variable for
	; this if required
	If (ControlW = "" OR ControlH = "")
	{
		GuiControlGet, Control, Pos, %Handle%
		; Assume Controls are DPISCale enabled and account for this. (all of my controls are).
		; Otherwise at higher DPIs the pictures end up non-scaled, consequently theyre smaller than the surrounding controls
		ControlW *= A_ScreenDPI/96, ControlH *= A_ScreenDPI/96 
	}

	pBitmap  := Gdip_CreateBitmap(ControlW, ControlH)
	G := Gdip_GraphicsFromImage(pBitmap)
	pBrushBackground  := Gdip_BrushCreateSolid("0xFFF0F0F0") 	;cover the edges of the pic
	Gdip_FillRectangle(G, pBrushBackground, 0, 0, ControlW, ControlH)
	pBrush  := Gdip_BrushCreateSolid(Colour)
	if RoundCorner
	{
		Gdip_SetSmoothingMode(G, 4)
		Gdip_FillRoundedRectangle(G, pBrush, 0, 0, ControlW, ControlH, RoundCorner)
	}
	Else 
	{
		Gdip_FillRectangle(G, pBrush, 0, 0, ControlW, ControlH)
		pPen := Gdip_CreatePen(0xFF000000, 1)
		Gdip_DrawRectangle(G, pPen, 0, 0, ControlW-1, ControlH-1) 
		Gdip_DeletePen(pPen)	
	}	
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(Handle, HBitmap)	
	Gdip_DeleteBrush(pBrush), Gdip_DeleteBrush(pBrushBackground), Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
	Return
}