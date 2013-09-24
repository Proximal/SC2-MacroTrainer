#singleinstance force 
critical
a := [], a.b := []
loop 10
    a.b.insert({"key":  A_index, "key2": 222})
reverseArray(a.b)
objtree(a)
return






Sort2DArrayOld(Byref TDArray, KeyName, Order := 1) 
{
    aStorage := []
    For index2, obj2 in TDArray          ;TDArray : a two dimensional TDArray
    {                                    ;KeyName : the key name to be sorted
        For index, obj in TDArray        ;Order: 1:Ascending 0:Descending
        {
            if (lastIndex = index)
                break
            if (A_Index != 1) &&  (Order ? (TDArray[prevIndex][KeyName] > TDArray[index][KeyName]) : (TDArray[prevIndex][KeyName] < TDArray[index][KeyName])) 
            {       
                ; making this a single line expression saves ~20 ms on a 1000 index array
                aStorage := TDArray[index]
                , TDArray[index] := TDArray[prevIndex]
                , TDArray[prevIndex] := aStorage            
            }         
            prevIndex := index
        }     
        lastIndex := prevIndex
    }
}



; Index values should be numeric
; Will reverse the order of objects within another object
reverse2DArray(Byref a)
{
    aStorage := []
    for index, in a
        lIndex .= index ","
    StringTrimRight, lIndex, lIndex, 1 
    aStorage := []
    sort, lIndex, D`, N R 
    msgbox % lIndex

}

sort2DArraySimpleNew(byRef a, key, Ascending := True)
{
    for index, obj in a
        out .= obj[key] "-" index "|" ; "-" allows for sort to work with just the value
    ; out will look like:   value-index|value-index|
    StringTrimRight, out, out, 1 ; remove trailing | 
    Sort, out, % "D| N"  (!Ascending ? " R" : " ") ; sort by Numeric value
    aStorage := []
    loop, parse, out, |
    {
        StringSplit, split, A_LoopField, -
        ; split1 = value, split2 = index
        aStorage.insert(a[split2])
    }
    a := aStorage
    return
}