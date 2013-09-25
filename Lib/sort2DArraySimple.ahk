; Note: This can only be used if you want to order the array
; by one key, and you dont care about that any of the other key values
; are unordered
; eg sort could result in something like this:
; key1: 1     key2: 0
; key1: 2     key2: 2*   Higher
; key1: 2     key2: 1*   Lower
; key1: 3     key2: 5

; (the other key values will still be correctly associated with the ordered keys)  

sort2DArraySimple(byRef a, key, Ascending := True)
{
    for index, obj in a
        out .= obj[key] "-" index "|" ; "-" allows for sort to work with just the value
    ; out will look like:   value-index|value-index|
    StringTrimRight, out, out, 1 ; remove trailing | 
    value := a[1, key]
    if value is number 
        type := " N "
    Sort, out, % "D| " type  (!Ascending ? " R" : " ") ; sort by Numeric value
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

; the sort command only takes a fraction of the function time, the rest is spent
; iterating and copying the data

; Test:
; Object: 
/*
    loop 10000
         a.insert({ "key": rand(1,10), "another": "b"})
*/
; Old Bubble Search
; Bubble took 53,083 ms
; New sort took 26.8 ms (~2,000x Faster!)