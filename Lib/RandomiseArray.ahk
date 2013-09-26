RandomiseArray(byref a)
{
    aIndicies := []
    for i, in a 
         aIndicies.insert(i)
    for index, in a
    {
        Random, i, 1, aIndicies.MaxIndex()
        storage := a[aIndicies[i]]
        , a[aIndicies[i]] := a[index]
        , a[index] := storage   
    }
    return
}

/*
RandomiseArrayOld(byref a_Array)
{
	while (a_index <= a_Array.MaxIndex())
	{
		Random, i, a_Array.MinIndex(), a_Array.MaxIndex()
		storage := a_Array[a_index]
		a_Array[a_index] := a_Array[i]
		a_Array[i] := storage	
	}
	return
}
*/