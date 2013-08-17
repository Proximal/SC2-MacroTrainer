checkAllKeyStates()
{
	static aKeys := []

	; returns and array of unmodified keys
	if !aKeys.maxindex()
		aKeys := getAllKeyboardAndMouseKeys()

	for index, key in aKeys
	{
		if (getkeystate(key) ) ;|| getkeystate(key))
			return key
	}
	return
}