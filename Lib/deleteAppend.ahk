deleteAppend(file, string)
{
	if FileExist(file)
		FileDelete, %file%
	FileAppend, %string%, %file%
	return
}