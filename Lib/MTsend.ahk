MTsend(keys)
{
	; so sends even if key is only 0 ie number 0
	if (keys != "")
		Input.psend(keys)
	return
}
