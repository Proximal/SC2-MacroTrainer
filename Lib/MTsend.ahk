MTsend(keys, Blind := True)
{
	GLOBAL GameIdentifier, input_method
	if keys
	{ 
		if Blind
			controlsend,, % "{Blind}" VKSend(keys), %GameIdentifier%
		else
			controlsend,, % Blind VKSend(keys), %GameIdentifier%
	}
	return
}
