IENavigate(wb, url, timeout := 6000)
{
	try WB.Navigate(url) ; com errors can be nasty
	catch 
		return True
	finish := A_TickCount + round(timeout)
	while wb.busy || wb.ReadyState != 4
	{
		if (A_TickCount >= finish)
			return true		
   		Sleep 50
   	}
   	return False
}