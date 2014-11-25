/*
hover on each icon 
click each icon 
feedback on which Icon was clicked
set a new line of icons
allow icons to be moved up or down
*/
; Remember this will catch (0x201, 0x203, 0x200, 0x2A3) msgbs from an AHK GUI in this main script
mainThreadMessageHandler(wParam, lParam, msg, hwnd)
{
	if autoBuildGameGUI.hwnd = hwnd
	{
		if (msg = 0x200 && !autoBuildGameGUI.isTracking)    ; WM_MOUSEMOVE
			autoBuildGameGUI.setMouseLeaveTracking()
		else if msg = 0x203
			msg := 0x201 ; convert double clicks into a left button down event 

		; Separate if
		if msg = 0x200 
			autoBuildGameGUI.hoverCheck(lParam & 0xFFFF, lParam >> 16) ; This reduces
		else if msg = 0x2A3 ; WM_MOUSELEAVE (not 100% reliable
			autoBuildGameGUI.MouseLeft()
		else if (msg = 0x201 && autoBuildGameGUI.drag)
			PostMessage, 0xA1, 2 ;WM_NCLBUTTONDOWN	
		else autoBuildGameGUI.refresh(lParam & 0xFFFF, lParam >> 16, msg)
		return 1
	}
	else if msg = 0x200
		OptionsGUITooltips()
	return 


}
 
; This was initially a class which returned a draw object.
; Now it's just going to be a class which is directly called

class autoBuildGameGUI
{
	static overlayTitle := getRandomString_Az09(10, 20)
	, wWindow := 400, hWindow := 400 ; since object cant do wWindow := hWindow := 400 

	showOverlay()
	{
		this.getGUIStatus()
		if this.GUIExists && this.GUIHidden
			Gui, autoBuildGUI: Show, NA				
		else if !this.GUIExists
			this.createOverlay()
	}
	hideOverlay()
	{
		this.getGUIStatus()
		if this.GUIExists && !this.GUIHidden
		{
			Gui, autoBuildGUI: Cancel
			return True ; Action was performed
		}
	}	
	toggleOverlay()
	{
		this.getGUIStatus()
		if this.GUIExists && this.GUIHidden
			Gui, autoBuildGUI: Show, NA	
		else if this.GUIExists ; hide it as its visible
			Gui, autoBuildGUI: Cancel
		else this.createOverlay() ; doesnt exist
		;Gui, autoBuildGUI: +lastfound 
		;tooltip % WinExist()
	}	
	createOverlay()
	{
		global autoBuildOverlayX, autoBuildOverlayY, AutoBuildEnableInteractGUIHotkey, AutoBuildGUIkeyMode 
		this.endGameDestroy()
		Gui, autoBuildGUI: -Caption Hwndhwnd +E0x8080000 +LastFound +ToolWindow +AlwaysOnTop
		if (AutoBuildEnableInteractGUIHotkey && AutoBuildGUIkeyMode = "Toggle")
			this.interact(False)
		else this.interact(True)
		;Gui, %overlay%: -Caption Hwndhwnd -E0x20  +E0x80000 +LastFound +ToolWindow +AlwaysOnTop
		; need to remove E0x8000000 to make it move while being dragged
		Gui, autoBuildGUI: Show, NA X%autoBuildOverlayX% Y%autoBuildOverlayY% W400 H400, % this.OverlayTitle
		this.hwnd := hwnd
		this.Items := []
		this.lineStats["y"] := 0, this.lineStats["x"] := 0
		this.line := 0
		this.isTracking := False
		OnMessage(0x201, "mainThreadMessageHandler") ; WM_LBUTTONDOWN
		OnMessage(0x203, "mainThreadMessageHandler") ; WM_LBUTTONDBLCLK required to catch second left click if they occur quickly
		OnMessage(0x200, "mainThreadMessageHandler") ; WM_MOUSEMOVE need to make clickable to work i.e. -E0x20
		OnMessage(0x2A3, "mainThreadMessageHandler") ; WM_MOUSELEAVE
		this.fillLocalRace()
		this.Refresh()
	}
	interact(enable)
	{
		;Gui, % "autoBuildGUI: " (enable ? "-" : "+") "E0x20"
		if enable
		{
			Gui, autoBuildGUI: -E0x20
			this.CanInteract := True
		}
		else 
		{
			Gui, autoBuildGUI: +E0x20
			this.CanInteract := False
		}
	}
	starcraftLostFocus()
	{
		this.getGUIStatus()
		if this.GUIVisibleOnFocusLoss := (this.GUIExists && !this.GUIHidden) 
			Gui, autoBuildGUI: Cancel
		return this.GUIVisibleOnFocusLoss
	}
	starcraftGainedFocus()
	{
		global AutoBuildEnableGUIHotkey 
		; Need to check if GUI hotkey is still enabled. Else if user disables the hotkey in the options menu
		; while in game and tabs back in, wont be able to turn it off (unless I add a GUI Button in the overlay)
		if this.GUIVisibleOnFocusLoss && AutoBuildEnableGUIHotkey
			this.unHideOverlay()
	}
	unHideOverlay()
	{
		this.getGUIStatus()
		if this.GUIExists && this.GUIHidden
		{	
			Gui, autoBuildGUI: Show, NA
			return True
		}
	}	
	; Destroy the GUI and all items
	endGameDestroyOverlay()
	{
		Try Gui, autoBuildGUI: Destroy
		this.hwnd := ""
		this.Items := []
		this.lineStats["y"] := 0, this.lineStats["x"] := 0
		this.GUIVisibleOnFocusLoss := 0
	}
	getGUIStatus()
	{
		Gui, autoBuildGUI: +LastFoundExist
		IfWinExist
		{
			this.GUIExists := True
			WinGet, style, style
			this.GUIHidden := !(0x10000000 & style)
			WinGet, ExStyle, ExStyle
			this.WS_EX_TRANSPARENT := (0x20 & ExStyle) ; if set is cant interact
		 }
		 else 
		 {
		 	this.GUIExists := False
		 	this.hwnd := ""
		 }	
	}	

	setDrag(enabled := False)
	{
		global autoBuildOverlayX, autoBuildOverlayY, AutoBuildEnableInteractGUIHotkey
		this.getGUIStatus()
		if !this.GUIExists
			return
		if enabled ; need to remove E0x8000000 to make it move while being dragged E0x8000000 prevents window activation when it is clicked, so restore it when dragging ends.
		{
			this.drag := True ; Keep track of drag via a variable so don't have to call getGUIStatus() indirectly on every wm_mousemove event
			Gui, autoBuildGUI: -E0x8000000 -E0x20
		}
		else 
		{
			this.drag := False
			if AutoBuildEnableInteractGUIHotkey
				Gui, autoBuildGUI: +E0x8000000 +E0x20 +LastFound
			else Gui, autoBuildGUI: +E0x8000000 +LastFound
			WinGetPos, x, y
			if (x != "" && y != "") ; These made blank if not found
			{
				IniWrite, % autoBuildOverlayX := x, %config_file%, Overlays, autoBuildOverlayX
				IniWrite, % autoBuildOverlayY := y, %config_file%, Overlays, autoBuildOverlayY
			}						
		}
	}

	; Posts a WM_MOUSELEAVE when mouse leaves and removes the tracker.
	; Since this msg is posted immediately if mouse is outside of GUI
	; Need to wait until mouse in inGUI before calling it. And recall it on entering.
	; Used to remove the highlight from the last hovered item when the mouse leaves the GUI
	setMouseLeaveTracking()
	{
		VarSetCapacity(v, 16, 0)
		NumPut(16, v, 0, "UInt") 			; cbSize
		NumPut(0x00000003, v, 4, "UInt") 	; dwFlags (TME_LEAVE)
		NumPut(this.hwnd, v, 8, "UInt") 	; HWND
		NumPut(0, v, 12, "UInt") 			; dwHoverTime (ignored)	
		return this.isTracking := DllCall("TrackMouseEvent", "Ptr", &v) ; Non-zero on success
	}
	removeMouseLeaveTracking()
	{
		VarSetCapacity(v, 16, 0)
		NumPut(16, v, 0, "UInt") 			; cbSize
		NumPut(0x80000000 | 0x00000003, v, 4, "UInt") 	; dwFlags  TME_CANCEL | TME_LEAVE
		NumPut(this.hwnd, v, 8, "UInt") 	; HWND
		NumPut(0, v, 12, "UInt") 			; dwHoverTime (ignored)	
		DllCall("TrackMouseEvent", "Ptr", &v) ; Non-zero on success	
	}
	MouseLeft()
	{
		this.isTracking := False
		this.getGUIStatus()
		if this.GUIExists && !this.GUIHidden  ; DO NOT DRAW IF HIDDEN IT WILL LOCK THE GUI!!!
			this.refresh() ; redraw to remove background/hover highlight
		return		
	}
	fillLocalRace()
	{
		if aLocalPlayer.Race = "Terran"
			this.fillTerran()
		else if aLocalPlayer.Race = "Protoss"
			this.fillProtoss()
		else if aLocalPlayer.Race = "Zerg"
			this.fillZerg()
	}
	fillTerran()
	{
		this.addItems("SCV")
		this.pushItemRight(3)
		this.addItems("pauseButton")
		this.pushDownLine()
		this.addItems("marine", "marauder", "reaper", "ghost")
		this.pushDownLine()
		this.addItems("hellion", "siegetank", "thor", "hellbat", "widowMine")
		this.pushDownLine()
		this.addItems("vikingfighter", "medivac", "banshee", "raven", "battlecruiser")
	}
	fillProtoss()
	{
		this.addItems("Probe")
		this.pushItemRight(3)
		this.addItems("pauseButton")
		this.pushDownLine()
		this.addItems("zealot", "sentry", "stalker")
		this.pushDownLine()
		this.addItems("hightemplar", "darktemplar")
		this.pushDownLine()
		this.addItems("phoenix", "oracle", "voidray", "tempest", "carrier")
	}	
	fillZerg()
	{
		this.addItems("Queen")
		this.pushItemRight(3)
		this.addItems("pauseButton")		
	}
	pushDownLine(count := 1, offset := 0)
	{
		this.lineStats.y += count * (this.items[this.items.minIndex(), "Height"] + offset) ; Use minIndex so dont have to worry about pause icon sise
		this.lineStats.x := 0
	}
	pushItemRight(count := 1, offset := 0)
	{
		this.lineStats.x += count * (this.items[this.items.minIndex(), "Width"] + offset)
	}

	addItems(names*)
	{
		for i, name in names 
		{
			if (name = "pauseButton")
				pBitmap := a_pBitmap["GreenPause"]
			else 
				pBitmap := a_pBitmap[aUnitId[name]]
			width := Gdip_GetImageWidth(pBitmap)
			height := Gdip_GetImageHeight(pBitmap)
			y := this.lineStats.y
			x := this.lineStats.x
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap) 
			SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			item := {	name: name
					, 	pBitmap: pBitmap
					, 	width: width *= 0.75
					, 	height: Height *= 0.75
					, 	SourceWidth: SourceWidth
					, 	SourceHeight: SourceHeight
					,	enabled: autoBuild.isUnitActive(name)
					, 	x: x 
					, 	y: y}
			this.lineStats.x += width + 0
			this.Items.Insert(item)
		}
	}
	; This is called from the other autoBuild class
	; in response to a profile hotkey press
	setItemState(enabledList)
	{
		for i, item in this.Items
		{
			name := item.name 
			if name in %enabledList%
				item.enabled := True 
			else item.enabled := False 
		} 
		this.getGUIStatus()
		if this.GUIExists
			this.refresh()
		; Refresh overlay if drawn
	}
	setCanvas(byRef hbm, byRef hdc, byRef G)
	{
		hbm := CreateDIBSection(this.wWindow, this.hWindow), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
		, G := Gdip_GraphicsFromHDC(hdc), Gdip_SetInterpolationMode(G, 2), Gdip_SetSmoothingMode(G, 4)	
	}
	cleanup(byRef hbm, byRef hdc, byRef G)
	{
		Gdip_DeleteGraphics(G),	SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc) 			
	}
	findBorderEdges(byRef x, byRef y)
	{
		x := this.Items.1.x, y := this.Items.1.y 
		for i, item in this.Items
		{
			if item.x > x 
				x := item.x
			if item.y > y 
				y := item.y	
		}
		x += this.Items.1.width, y += this.Items.1.height
		return
	}
	drawTick(G, item)
	{
		grayScaleMatrix := "0.299|0.299|0.299|0|0|0.587|0.587|0.587|0|0|0.114|0.114|0.114|0|0|0|0|0|1|0|0|0|0|0|1"
		x := item.x, y := item.y, w := item.width, h := item.height
		Gdip_DrawImage(G, a_pBitmap["greenTick"]
			, x += w - width := .25 * (sourceWidth := Gdip_GetImageWidth(a_pBitmap["greenTick"]))
			, y += h - height := .25 * (sourceHeight := Gdip_GetImageHeight(a_pBitmap["greenTick"])) 	
			, width, height, 0, 0, sourceWidth, sourceHeight, autoBuild.isPaused ? grayScaleMatrix : "")
	}
	drawPause(G, item)
	{
		
		x := item.x, y := item.y, w := item.width, h := item.height
		Gdip_DrawImage(G, this.pBitmap
			, x += w - width := .25 * (sourceWidth := Gdip_GetImageWidth(this.pBitmap))
			, y += h - height := .25 * (sourceHeight := Gdip_GetImageHeight(this.pBitmap)) 	
			, width, height, 0, 0, sourceWidth, sourceHeight)
	}
	drawItems(g, highlightedIndex := "")
	{
		global a_pBrushes, BackgroundMacroAutoBuildOverlay
		static redmatrix := "15|0|0|0|0|0|0|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|1"

		if BackgroundMacroAutoBuildOverlay ; Draw the background 
		{
		 	this.findBorderEdges(x2, y2)
		 	Gdip_FillRoundedRectangle(G, a_pBrushes.transBackground, this.items.1.x, this.items.1.y, x2, y2, 2)
		}
		for i, item in this.Items
		{
			if (highlightedIndex = i)
			{
				Gdip_FillRoundedRectangle(G, a_pBrushes.transBlueHighlight, item.x, item.y, item.width, item.height, 2)
				item.Hovered := True
			}
			else item.Hovered := False
			if item.name = "pauseButton"
				Gdip_DrawImage(G, item.pBitmap, item.x, item.y, item.Width, item.Height, 0, 0, item.SourceWidth, item.SourceHeight, autoBuild.isPaused ? redmatrix : "")
			else 
			{
				Gdip_DrawImage(G, item.pBitmap, item.x, item.y, item.Width, item.Height, 0, 0, item.SourceWidth, item.SourceHeight)
				if item.enabled 
					this.drawTick(G, item)	
			}		
		}
	}
	; We don't want to redraw the overlay on every WM_MouseMove msg
	; As this greatly increases CPU usage and makes clicking the overlay less responsive
	; Check if the mouse if on a non-highlighted icon
	; This greatly increases the reliability of the mouse hover when it leaves the screen
	; Though be still have issues on slow systems
	hoverCheck(x, y)
	{
		for i, item in this.Items
		{
			if item.hovered
				count++
		}
		if index := this.collisionCheck(x, y)
		{
			if !this.Items[index].Hovered
				this.refresh(x, y)
		}
		else if count ; get rid of hover when in a dead spot on the gui (no icon - just background)
			this.refresh(x, y)
	}

	refresh(x := "", y := "", msg := "")
	{
		global autoBuildInactiveOpacity
		this.setCanvas(hbm, hdc, G)
		if (x != "" && y != "")
			itemIndex := this.collisionCheck(x, y)
		if (itemIndex && msg = 0x201)
		{
			if this.items[itemIndex, "name"] = "pauseButton"
				autoBuild.pause()
			else 
			{
				if this.items[itemIndex, "enabled"] := !this.items[itemIndex, "enabled"]
					autoBuild.invokeUnits(this.items[itemIndex, "name"], False)
				else autoBuild.disableUnits(this.items[itemIndex, "name"])
			}
			autoBuild.resetProfileState()
		}
		this.drawItems(G, itemIndex)
		UpdateLayeredWindow(this.hwnd, hdc,,,,, this.CanInteract ? 255 : autoBuildInactiveOpacity)
		this.cleanup(hbm, hdc, G)	
	}

	collisionCheck(x, y)
	{
		for i, item in this.items 
		{ 
			if item.x <= x && x <= item.x + item.width && item.y <= y && y <= item.y + item.height 
				return i
		}
		return
	}

}
