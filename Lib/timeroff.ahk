timeroff(timers*)
{
	For index, timer in timers ; for current count, current value in timers/array
		try settimer, %timer%, off
	return
}

				