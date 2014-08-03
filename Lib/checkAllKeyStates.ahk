; check result != "" as the '0' key when returned will indicate false rather than true
checkAllKeyStates(logical := True, physical := True)
{
	static aKeys := []

	; returns and array of unmodified keys
	if !aKeys.maxindex()
		aKeys := getAllKeyboardAndMouseKeys()
	if logical
	{
		for index, key in aKeys
		{
			if getkeystate(key)
				return key
		}
	}
	if physical
	{
		for index, key in aKeys
		{
			if getkeystate(key, "P")
				return key
		}
	}	
	return ""
}