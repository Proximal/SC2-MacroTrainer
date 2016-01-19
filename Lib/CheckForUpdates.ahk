; Added support for multiple URLS i.e. backups
; aUpdateURLS stores the listed update URLS urls hosted on the same host which the version was successfully retried from will
; occur first 
; Returns values
; 	-1 = Error couldnt complete 
;	0 = No update exists
;	1 = Update Exists
; aVersionURLS - array of urls points to current version config file
CheckForUpdates(aVersionURLS, installed_version, byRef latestVersion, byRef aUpdateURLS := "", byRef announcements := "")
{
	aResultURLS := [], aBackupURLS := [], aUpdateURLS := []
	for URL_Index, versionURL in aVersionURLS
	{
		URLDownloadToFile, %versionURL%, %A_Temp%\version_checker_temp_file.ini
		if ErrorLevel 
		{
			FileDelete %A_Temp%\version_checker_temp_file.ini
			continue			
		}

		IniRead, latestVersion, %A_Temp%\version_checker_temp_file.ini, info, currentVersion, %installed_version%
		IniRead, updateURLList, %A_Temp%\version_checker_temp_file.ini, info, updateURLList, %A_Space%
		IniRead, announcements, %A_Temp%\version_checker_temp_file.ini, info, announcements, %A_Space%
		FileDelete %A_Temp%\version_checker_temp_file.ini
		updateURLList := Trim(updateURLList, " `t,")
		if !updateURLList
			return 0			
		aupdateURLList := StrSplit(updateURLList, ",")
		if !aupdateURLList.MaxIndex()
			return 0
		; A small subset of users can not access my main host
		; This compares the download URLS with the working host that the version file came from
		; It will insert URLS from this working host at the start of the returned URL array
		crackedVersionURL := CrackUrl(versionURL)
		for i, updateURL in aupdateURLList ; List or URLS holding the update
		{
			crackedUpdateURL := CrackUrl(updateURL)
			if crackedVersionURL.hostName = crackedUpdateURL.hostName
				aResultURLS.Insert(updateURL)
			else aBackupURLS.Insert(updateURL)
		}
		if aResultURLS.MaxIndex() ; Insert these first!
			aUpdateURLS.Insert(1, aResultURLS*)
		if aBackupURLS.MaxIndex()
			aUpdateURLS.Insert(round(aUpdateURLS.MaxIndex()) + 1, aBackupURLS*)
		
		Return (latestVersion > installed_version && aUpdateURLS.MaxIndex()) ; update exist
	}
	return -1 ; Failed to download/read the aVersionURLS
}


/*
Reads an ini file with the following keys

[info]
currentVersion=2.95
; Keep zipURL this key for backward compatibility  - at least for now
zipURL=http://www.xyz.com/file.zip  	
updateURLList=http://www.host1.com/file.zip,http://www.host2.com/file.zip
announcements=This is an announcement!

*/


/*
CheckForUpdates(url, installed_version, byRef latestVersion, byRef announcements := "")
{
	URLDownloadToFile, %url%, %A_Temp%\version_checker_temp_file.ini
	if !ErrorLevel 
	{	
		IniRead, latestVersion, %A_Temp%\version_checker_temp_file.ini, info, currentVersion, %installed_version%
		IniRead, zipURL, %A_Temp%\version_checker_temp_file.ini, info, zipURL, 0
		IniRead, announcements, %A_Temp%\version_checker_temp_file.ini, info, announcements, %A_Space%
		FileDelete %A_Temp%\version_checker_temp_file.ini
		If (latestVersion > installed_version && zipURL)
			Return zipURL ; update exist
	}
	latestVersion := installed_version ; in case there was an error
	FileDelete %A_Temp%\version_checker_temp_file.ini
	Return 0 ; no update or error
}
*/

