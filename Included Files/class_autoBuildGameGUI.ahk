/*
hover on each icon 
click each icon 
feedback on which Icon was clicked
set a new line of icons
allow icons to be moved up or down
*/
; Remember this will catch MSGs from any AHK GUI in this main script
mainThreadMessageHandler(wParam, lParam, msg, hwnd)
{
	static aLastClicks := []
	if autoBuildGameGUI.hwnd = hwnd
	{
		if (msg = 0x200 && !autoBuildGameGUI.isTracking)    ; WM_MOUSEMOVE
			autoBuildGameGUI.setMouseLeaveTracking()
		else if msg = 0x203
			msg := 0x201 ; convert double clicks into a left button down event 
		else if msg = 0x020D ; WM_XBUTTONDBLCLK
			msg := 0x020B

		; Separate if
		if msg = 0x200 
			autoBuildGameGUI.hoverCheck(lParam & 0xFFFF, lParam >> 16) ; This reduces
		else if msg = 0x2A3 ; WM_MOUSELEAVE (not 100% reliable
			autoBuildGameGUI.MouseLeft()
		else if (msg = 0x201 && autoBuildGameGUI.drag)
			PostMessage, 0xA1, 2 ;WM_NCLBUTTONDOWN
		else if (msg = 0x204 || msg = 0x206) ; Right clicks
		{
			autoBuildGameGUI.pauseButtonPress()
			autoBuildGameGUI.refresh(lParam & 0xFFFF, lParam >> 16) ; So that it redraws the changed unit state, as the above method dosn't do this.
		}
		else if (msg = 0x207 || msg = 0x209) ; Middle mouse
			autoBuildGameGUI.offButtonPress()
		else if msg = 0x020B ; WM_XBUTTONDOWN
		{    
			; cant use mouse wheel with the window style unless want to let SC lose focus, so need to make do :(
			; If users have hotkeys bound to these buttons, then this wont work          
			quotaChange := 0x0001 & (wParam >> 16) ? (-1, key := "XButton1") : (1, key := "XButton2") ; which xbutton
			; not a great idea to sit in a loop while processing a msg, but it seems to work fine.
			while GetKeyState(key, "P")
			{
				if autoBuildGameGUI.refresh(lParam & 0xFFFF, lParam >> 16, msg, quotaChange) = 1
					break
				if A_Index = 1
				{
					KeyWait, %key%, U T.250
					if !ErrorLevel
						break
				}
				else sleep 50
			}
		}
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
	}	
	createOverlay()
	{
		global autoBuildOverlayX, autoBuildOverlayY, AutoBuildEnableInteractGUIHotkey, AutoBuildGUIkeyMode 
		this.endGameDestroy()
		Gui, autoBuildGUI: -Caption Hwndhwnd +E0x8080000 +LastFound +ToolWindow +AlwaysOnTop -DPIScale
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
		OnMessage(0x204, "mainThreadMessageHandler") ; WM_RBUTTONDOWN
		OnMessage(0x206, "mainThreadMessageHandler") ; WM_RBUTTONDBLCLK
		OnMessage(0x207, "mainThreadMessageHandler") ; WM_MBUTTONDOWN
		OnMessage(0x209, "mainThreadMessageHandler") ; WM_MBUTTONDBLCLK
		OnMessage(0x020B, "mainThreadMessageHandler") ; WM_XBUTTONDOWN
		OnMessage(0x020D, "mainThreadMessageHandler") ; WM_XBUTTONDBLCLK                
		; OnMessage(0x20A, "mainThreadMessageHandler") ; WM_MOUSEHWHEEL - wont work with WM_noactivate

		this.fillLocalRace()
		this.Refresh()
	}
	checkOverlayPosition()
	{
		global autoBuildOverlayX, autoBuildOverlayY
		if !isCoordinateBoundedByMonitor(autoBuildOverlayX, autoBuildOverlayY)
		{
			getPrimaryMonitorCentre(Xcentre, Ycentre)
			autoBuildOverlayX := Xcentre, autoBuildOverlayY := Ycentre
			Gui, autoBuildGUI: +LastFoundExist
			IfWinExist
				Try winmove,,, Xcentre, Ycentre				
		}
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
		; Do not create it if it doesn't exist. This is called from Shell msg indirectly
		return
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
		if enabled ; need to remove E0x8000000 (WS_EX_NOACTIVATE) to make it move while being dragged E0x8000000 prevents window activation when it is clicked, so restore it when dragging ends.
		{
			this.drag := True ; Keep track of drag via a variable so don't have to call getGUIStatus() indirectly on every wm_mousemove event
			this.interact(True)
			Gui, autoBuildGUI: -E0x8000000
		}
		else 
		{
			this.drag := False
			if AutoBuildEnableInteractGUIHotkey
				this.interact(False)
			Gui, autoBuildGUI: +E0x8000000 +LastFound
			WinGetPos, x, y
			if (x != "" && y != "") ; These made blank if not found
			{
				IniWrite, % autoBuildOverlayX := x, %config_file%, Overlays, autoBuildOverlayX
				IniWrite, % autoBuildOverlayY := y, %config_file%, Overlays, autoBuildOverlayY
			}
			; When the entire background is disabled (minimap/overlays-->Background)
			; Dragging the overlay can result a unit (at edge of grid) remaining highlighted when the mouse leaves
			; Probably due to loss of tracking state. This fixes it
			this.isTracking := False						
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
		NumPut(0x00000002, v, 4, "UInt") 	; dwFlags (TME_LEAVE)
		NumPut(this.hwnd, v, 8, "UInt") 	; HWND
		NumPut(0, v, 12, "UInt") 			; dwHoverTime (ignored)	
		return this.isTracking := DllCall("TrackMouseEvent", "Ptr", &v) ; Non-zero on success
	}
	removeMouseLeaveTracking()
	{
		VarSetCapacity(v, 16, 0)
		NumPut(16, v, 0, "UInt") 			; cbSize
		NumPut(0x80000000 | 0x00000002, v, 4, "UInt") 	; dwFlags  TME_CANCEL | TME_LEAVE
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
		global AutoBuildGUIAutoWorkerToggle
		if AutoBuildGUIAutoWorkerToggle
		{ 
			this.addItems("SCV")
			this.pushItemRight(3)
		}
		else this.pushItemRight(4, Gdip_GetImageWidth(a_pBitmap[aUnitID["SCV"]]) * .75) ; So the pause Icon is on the far right
		this.addItems("OffButton")
		this.addItems("pauseButton")
		this.pushDownLine()
		this.addItems("marine", "marauder", "reaper", "ghost")
		this.pushDownLine()
		;this.addItems("hellion", "siegetank", "thor", "hellbat", "widowMine")
		this.addItems("hellion", "widowMine", "siegetank", "cyclone", "hellbat", "thor")
		this.pushDownLine()
		this.addItems("vikingfighter", "medivac", "liberator", "raven", "banshee", "battlecruiser")
	}
	fillProtoss()
	{
		global AutoBuildGUIAutoWorkerToggle
		if AutoBuildGUIAutoWorkerToggle
		{ 
			this.addItems("Probe")
			this.pushItemRight(3)
		}
		else this.pushItemRight(4, Gdip_GetImageWidth(a_pBitmap[aUnitID["Probe"]]) * .75)
		this.addItems("OffButton")
		this.addItems("pauseButton")
		this.pushDownLine()
		this.addItems("zealot", "sentry", "stalker", "adept", "hightemplar", "darktemplar")
		this.pushDownLine()
		this.addItems("observer", "warpPrism", "immortal", "colossus", "disruptor")
		this.pushDownLine()
		this.addItems("phoenix", "oracle", "voidray", "tempest", "carrier")
	}	
	fillZerg()
	{
		this.addItems("Queen")
		this.pushItemRight()
		this.addItems("pauseButton")		
	}
	pushDownLine(count := 1, offset := 0)
	{
		this.lineStats.y += count * (round(this.items[this.items.minIndex(), "Height"]) + offset) ; Use minIndex so dont have to worry about pause icon sise
		this.lineStats.x := 0
	}
	pushItemRight(count := 1, offset := 0)
	{
		this.lineStats.x += count * (round(this.items[this.items.minIndex(), "Width"]) + offset)
	}
	addItems(names*)
	{
		global EnableAutoWorkerTerran, EnableAutoWorkerProtoss

		for i, name in names 
		{
			if (name = "pauseButton")
				pBitmap := a_pBitmap["GreenPause"], isUnit := False
			else if (name = "OffButton")
				pBitmap := a_pBitmap["redClose72"], isUnit := False 
			else 
				pBitmap := a_pBitmap[aUnitId[name]], isUnit := True
			
			if (name = "SCV")
				enabled := EnableAutoWorkerTerran
			else if (name = "Probe")
				enabled := EnableAutoWorkerProtoss
			else enabled := autoBuild.isUnitActive(name)

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
					, 	isUnit: isUnit
					,	enabled: enabled
					, 	x: x 
					, 	y: y}
			this.lineStats.x += width + 0
			this.Items.Insert(item)
		}
	}
	; This is called from the other autoBuild class
	; in response to a profile hotkey press
	enableItems(enabledList, disableOthers := True)
	{
		for i, item in this.Items
		{
			name := item.name 
			if name in %enabledList%
				item.enabled := True 
			else if disableOthers
				item.enabled := False 
		} 
		this.getGUIStatus()
		if this.GUIExists
			this.refresh()
		; Refresh overlay if drawn
	}
	disableItems(disableList)
	{
		for i, item in this.Items
		{
			name := item.name 
			if name in %disableList%
				item.enabled := False 
		} 
		this.getGUIStatus()
		if this.GUIExists
			this.refresh()
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
	findBorderEdges(byRef xleft, byRef ytop, byRef xright, byRef ybot)
	{
		xleft := xright := this.Items.1.x, ytop := ybot := this.Items.1.y 
		for i, item in this.Items
		{
			if item.x + item.width > xright 
				xright := item.x + item.width
			if item.y + item.height > ybot 
				ybot := item.y + item.width
			if item.x < xleft
				xleft := item.x
			if item.y < ytop
				ytop := item.y				
		}
		return
	}
	drawTick(G, item)
	{ 
		static grayScaleMatrix := "0.299|0.299|0.299|0|0|0.587|0.587|0.587|0|0|0.114|0.114|0.114|0|0|0|0|0|1|0|0|0|0|0|1"
		checkScale := (item.name != "SCV" && item.name != "Probe") ; worker production can never be 'paused' Only on/off
		, x := item.x, y := item.y, w := item.width, h := item.height
		, Gdip_DrawImage(G, a_pBitmap["greenTick"]
			, x += w - width := .25 * (sourceWidth := Gdip_GetImageWidth(a_pBitmap["greenTick"]))
			, y += h - height := .25 * (sourceHeight := Gdip_GetImageHeight(a_pBitmap["greenTick"])) 	
			, width, height, 0, 0, sourceWidth, sourceHeight, (checkScale && autoBuild.isPaused) ? grayScaleMatrix : "")
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
		 	this.findBorderEdges(x1,y1, x2, y2)
		 	Gdip_FillRoundedRectangle(G, a_pBrushes.transBackground, x1, y1, x2, y2, 2)
		}
		for i, item in this.Items
		{
			if (highlightedIndex = i)
			{
				Gdip_FillRoundedRectangle(G, a_pBrushes.transBlueHighlight, item.x, item.y, item.width, item.height, 2)
				item.Hovered := True
			}
			else item.Hovered := False
			if item.isUnit ; If not pause / off icon draw ticks
			{
				Gdip_DrawImage(G, item.pBitmap, item.x, item.y, item.Width, item.Height, 0, 0, item.SourceWidth, item.SourceHeight)
				if autoBuild.AutoBuildQuota[item.name] >= 0
				{
					if (count := autoBuild.AutoBuildQuota[item.name]) >= 100
						width := 28
					else if count >= 10
						width := 20
					else width := 12
					Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, item.x, item.y, width, 16, 2)
					Gdip_TextToGraphics(G, autoBuild.AutoBuildQuota[item.name], "Top cFFFF0000 r4 BOLD s14 x" item.x  "y" item.y + 18, "Arial")
				}
				if item.enabled 
					this.drawTick(G, item)	
			}
			else Gdip_DrawImage(G, item.pBitmap, item.x, item.y, item.Width, item.Height, 0, 0, item.SourceWidth, item.SourceHeight, autoBuild.isPaused && item.Name = "pauseButton" ? redmatrix : "")
		}
	}
	; We don't want to redraw the overlay on every WM_MouseMove msg
	; As this greatly increases CPU usage and makes clicking the overlay less responsive
	; Check if the mouse if on a non-highlighted icon
	; This greatly increases the reliability of the mouse hover when it leaves the screen
	; Though may still have issues on slow systems
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
	isWorkerProductionEnabled()
	{
		global EnableAutoWorkerTerran, EnableAutoWorkerProtoss
		return (aLocalPlayer.Race = "Terran" && EnableAutoWorkerTerran) || (aLocalPlayer.Race = "Protoss" && EnableAutoWorkerProtoss)
	}
	offButtonPress()
	{
		global AutoBuildGUIAutoWorkerOffButton, EnableAutoWorkerTerran, EnableAutoWorkerProtoss
		if AutoBuildGUIAutoWorkerOffButton
		{
			EnableAutoWorkerTerran := EnableAutoWorkerProtoss := False ; better not to use timer for label as the autoBuild function below checks the state below
			SetTimer, g_autoWorkerProductionCheck, off                 ; And could result in the tick being removed after the other ticks
		}
		autoBuild.disableUnits()
		autoBuild.updateInGameGUIUnitState() ; Easier just to have autoBuild check its internal state and then have it update this overlay		
		return
	}
	pauseButtonPress()
	{
		global AutoBuildGUIAutoWorkerPause
		; Toggle auto-build. If any units are active this returns false (i.e. they were previously paused)
		; so don't turn off the worker function e.g. worker was on, but the other units were
		if autoBuild.pause() && AutoBuildGUIAutoWorkerPause && this.isWorkerProductionEnabled() 
			settimer, g_AutoBuildGUIToggleAutoWorkerState, -50
		return 		
	}

	refresh(x := "", y := "", msg := "", quotaChange := 0)
	{
		global autoBuildInactiveOpacity
		this.setCanvas(hbm, hdc, G)
		if (x != "" && y != "")
			itemIndex := this.collisionCheck(x, y)
		if (itemIndex && msg = 0x201)
		{
			if this.items[itemIndex, "name"] = "pauseButton" 
				this.pauseButtonPress()
			else if this.items[itemIndex, "name"] = "OffButton"
				this.offButtonPress()	
			else if this.items[itemIndex, "name"] = "SCV" || this.items[itemIndex, "name"] = "Probe"
				settimer, g_AutoBuildGUIToggleAutoWorkerState, -50 ; Use a negative timer give time for this onMessage Event to finish
			else 
			{
				if this.items[itemIndex, "enabled"] := !this.items[itemIndex, "enabled"]
					autoBuild.invokeUnits(this.items[itemIndex, "name"], False)
				else autoBuild.disableUnits(this.items[itemIndex, "name"])
			}
			autoBuild.resetProfileState() ; Disable any active hotkey profiles
		}
		if (itemIndex && msg = 0x020B) ; WM_XBUTTONDOWN
			result := autoBuild.modifyAutoBuildQuota(this.items[itemIndex, "name"], quotaChange)
		this.drawItems(G, itemIndex) 
		UpdateLayeredWindow(this.hwnd, hdc,,,,, this.CanInteract ? 255 : autoBuildInactiveOpacity)
		this.cleanup(hbm, hdc, G)
		return result	
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
