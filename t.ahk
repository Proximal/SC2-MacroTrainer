#singleinstance force 
critical
a := [], a.b := []
loop 10
    a.b.insert({"key1":  A_index, "key2":  rand(1, 20), "key3":  rand(1, 20)})

;a.b := reverseArray(a.b) 
reverseArray(a.b) 
objtree(a.b)

for i, o in a.b 
    s .= o.key1 "`n"
msgbox % s
return 

; 2133.818577
; 2114.423743
; 

/*
For 2 keys, sort by the minor one first

For any number of keys in the same sort order just 
sort in from minor to major keys

*/

multi2DSort(byRef a, ascending := True, keys*)
{
    reverseArray(keys)
    for i, key in keys 
    {
        sort2DArray(a, key, ascending)
    }
}

multiOrder2DSort(byRef a, aKeyOrder)
{
    aReversed := []
    for key, order in aKeyOrder
        aReversed.insert(1, {(key): order})
    for i, object in aReversed
    {
        for key, order in object 
            sort2DArray(a, key, order)
    }
    return 
}


reverseArray(Byref a)
{
    aIndices := []
    for index, in a
        aIndices.insert(index)
    aStorage := []
    loop % aIndices.maxIndex() 
       aStorage.insert(a[aIndices[aIndices.maxIndex() - A_index + 1]]) 
    a := aStorage
    return aStorage ; for objects within objects
}

reverseArray2(Byref a)
{
    aStorage := []
    for index, v in a
        aStorage.insert(1, V)
    objtree(aStorage) 
    a := aStorage
    return aStorage
}
