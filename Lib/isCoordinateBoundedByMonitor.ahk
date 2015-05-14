; Cons of using this method:
;   1.  Function will return false if overlay spans across two monitors and is positioned
;       within 30 pixels of the right or bottom edge

; The previous method which used the virtual screen size did not have this issue.
; However, it was possible that an overlay could be permanently hidden for users after a release.
; This could only occur if the default positions were not on the primary monitor and the user's system
; was a multi monitor setup arranged so the screens were not aligned (or same resolution).
; This is because some areas of the virtual screen may not be displayed/visible. 

isCoordinateBoundedByMonitor(x, y)
{
    ; This loop only takes ~0.007 ms
    SysGet, MonitorCount, MonitorCount
    loop, % MonitorCount
    {
        SysGet, pos, Monitor, %A_Index%
        if (posLeft != "" && posTop != "" && posRight != "" && posBottom != "")
        && (x >= posLeft && x <= posRight - 30) ; GUIs are drawn to the right, so ensure at least 30 pixels are visible
        && (y >= posTop && y <= posBottom - 30) 
           return True 
    }
    return False
}


; Remember the overlays is drawn from left to right, top to bottom
; Also, its still possible for the overlay to be a pixel or two before the right edge of the
; screen and still not be visible! or lead to a drawing/updateLayeredWindow fail.
; Added a -30 check to max Pos so should always be able to see/click it to move
; providing the draw doesn't fail
