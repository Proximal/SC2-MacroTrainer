getPrimaryMonitorCentre(byRef x, byRef y)
{
	SysGet, primaryMonitorID, MonitorPrimary
	SysGet, pos, Monitor, %primaryMonitorID%
	x := (posRight - posLeft)//2,	y := (posBottom - posTop)//2 
	if (x = "" || y = "") ; Should never occur, but this will always be inside the prim. monitor
		x := A_ScreenWidth//2, y := A_ScreenHeight//2
	return
}