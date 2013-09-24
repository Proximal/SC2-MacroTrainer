; Index values should be numeric
; Will reverse the order of objects within another object
; Note: Their original index values will be lost
;       If the index values in the original were sparsely populated,
;       then these gaps will be lost.
;       the returned objected will have indexs from 1 to the number of items in the original object
;
; Note: If the object being passed resides within another object,
; byRef wont affect it - so need to use the returned object e.g. aObject := reverseArray(aObject)
reverseArray(Byref a)
{
    aIndices := []
    for index, in a
        aIndices.insert(index)
    aStorage := []
    loop % aIndices.maxIndex() 
       aStorage.insert(a[aIndices[aIndices.maxIndex() - A_index + 1]]) 
    a := aStorage
    return aStorage
}

/*
; A slower way to achieve same result
; This is ~7.5X slower
reverseArraySort(Byref a)
{
    for index, in a
        lIndex .= index ","
    StringTrimRight, lIndex, lIndex, 1 
    sort, lIndex, D`, N R 
    aStorage := []
    loop, parse, lIndex, `,
        aStorage.insert(a[A_LoopField]) 
    a := aStorage
    return aStorage
}
*/

