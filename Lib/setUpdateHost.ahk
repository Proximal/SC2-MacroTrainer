setUpdateHost()
{
	global 
	if (updateFromHost = "Main")
		url.aCurrentVersionInfo := [url.aCurrentVersionInfoMain]
	else if (updateFromHost = "Alternate1")
		url.aCurrentVersionInfo := [url.aCurrentVersionInfoAlternate1] 
	; else always default to fallback
	else url.aCurrentVersionInfo := [url.aCurrentVersionInfoMain, url.aCurrentVersionInfoAlternate1]	
}