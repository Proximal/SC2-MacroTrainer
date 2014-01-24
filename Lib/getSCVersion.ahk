; macro trainer fails to launch SC for some people. That function also reads the registry values like this one.
; so it might be due to corrupted user registries, hence this might return a blank 
; value for some people - so ensure check it finds it before using the returned value for anything

getSCVersion()
{
	if !path := StarcraftInstallPath() ; includes final \
		return 
	loop, % path "Versions\Base*", 2 	;eg Base28667  I assume non-english installs will still have english folder names
	{
		version := A_LoopFileName
		StringReplace, version, version, Base
		if (version > highestVersion)
			highestVersion := version	 
	}
	return highestVersion
}
