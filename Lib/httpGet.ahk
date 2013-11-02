httpGet(url) 
{
	Random, somerandom, 1, 9999
	URLDownloadToFile, %url%, % filename := A_Temp "\ahk_http_get_" somerandom "_" a_now ".tmp"
	if (!ErrorLevel)	
		FileRead, result, %filename%
	else result := ""
	FileDelete %filename%
	return result
}