; Secondary monitors will register so long as the display cable is plugged in even with no power.
; Unplugging the monitor cable, removing the power cable, then plugging back in the display cable
; - windows will detect this and see it as present.
; Explanation: 
; http://www.extron.com/company/article.aspx?id=uedid
; EDID information is typically exchanged when the video source starts up. 
; The DDC specifications define a +5V supply connection for the source to provide power 
; to a display's EDID circuitry so that communication can be enabled, even if the display is powered off!

debugMonitorBoundingCoordinates()
{
    SysGet, primaryMonitorID, MonitorPrimary
    SysGet, MonitorCount, MonitorCount
    loop, % MonitorCount
    {
        SysGet, pos, Monitor, %A_Index%
        line := "(" posLeft ", " posTop ") -> (" posRight ", " posBottom ")"
        if (A_Index = primaryMonitorID)
            primaryString := "Primary: " line
        else otherString .= "Secondary: " line "`n"
    }   
    return primaryString (otherString != "" ? Rtrim("`n" otherString, "`n") : "")
}