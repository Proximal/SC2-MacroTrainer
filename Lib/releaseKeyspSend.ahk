; this releases all keys vis pSend
; it can be used with the block hook, as it allows the users real key ups to pass 
; through. hence, can't get a stuck key outside of windows

releaseKeyspSend()
{
	static aKeys := []
	; returns and array of unmodified keys
	if !aKeys.maxindex()
		aKeys := getAllKeyboardAndMouseKeys()
	for index, key in aKeys
	{
		if (getkeystate(key) ) ;|| getkeystate(key))
		{
			if isKeyMouseButton(key)
				upSequence .= "{ click " key " up}"
			else upSequence .= "{ " key " up}"
		}	
	}	
	input.pSend(upSequence)
	return 
}