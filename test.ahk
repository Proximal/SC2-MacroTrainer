FileAppend, %clipboard%, clip 
loop, read, clip, 
{
	if (A_LoopReadLine != "")
		var .= "`n" A_LoopReadLine
}
clipboard := var 
FileDelete, clip
msgbox 

