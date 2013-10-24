; returns elapsed time in ms 
; Can keep track of multiple events in the same or different threads 
stopwatch(itemId := 0, removeUsedItem := True)
{
	static F := DllCall("QueryPerformanceFrequency", "Int64P", F) * F , aTicks := [], runID := 0

	if (itemId = 0) ; so if user accidentally passes an empty ID variable function returns -1
	{
		DllCall("QueryPerformanceCounter", "Int64P", S), aTicks[++runID] := S
		return runID
	}
	else 
	{
		if aTicks.hasKey(itemId)
		{
			DllCall("QueryPerformanceCounter", "Int64P", End)
			return (End - aTicks[itemId]) / F * 1000, removeUsedItem ? aTicks.remove(itemId, "") : ""
		}
		else return -1
	}
}

