send(string)
{
	StringLower, string, string
	if BufferInputFast.isInputBlockedOrBuffered()
		send, % "{blind}" VKSend(string)
	else send, % string
	return
}