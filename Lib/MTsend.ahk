MTsend(keys)
{
	GLOBAL GameIdentifier, input_method

;	send % "{Blind}" VKSend(keys)
	if (input_method = "PostMessage")
		; Cant send ^5 this way (doesnt work in SC and AHK sends the control keys default method)
		; so have to manually convert to {shift down}5{shift up}
		controlsend,, % "{Blind}" VKSend(keys), %GameIdentifier%
	else
		send {Blind}%keys%
	return
}
