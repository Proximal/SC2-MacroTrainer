sortArray(byRef a, Ascending := True)
{
    for index, value in a
        out .= value "-" index "|" ; "-" allows for sort to work with just the value
    ; out will look like:   value-index|value-index|
    v := a[a.minIndex()]
    if v is number 
        type := " N "
    StringTrimRight, out, out, 1 ; remove trailing | 
    Sort, out, % "D| " type  (!Ascending ? " R" : " ")
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
