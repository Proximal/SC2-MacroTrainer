#singleinstance force 
SetStoreCapslockMode, off
*f1::
MouseGetPos, x, y
sendinput a
sleep 500 
KeyHistory
return 

*f2::
send ABC
return 


send(string)
{
	if getkeystate("Shift", "P")
		StringUpper, string, string
	else
		StringLower, string, string
;	if BufferInputFast.isInputBlockedOrBuffered()
;		send, % "{blind}" VKSend(string)
;	else send, % string
	msgbox % string 
	return
}