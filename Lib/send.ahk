send(string)
{
	if getkeystate("Shift", "P")   		; convert the case so will reduce the number of shift ups/downs AHK will send
		StringUpper, string, string
	else
		StringLower, string, string
;	if BufferInputFast.isInputBlockedOrBuffered()
;		send, % "{blind}" VKSend(string)
;	else send, % string
;	send % VKSend(string)
	send %string%
	return
}