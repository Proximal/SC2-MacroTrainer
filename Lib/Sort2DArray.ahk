; Note: This can only be used if you want to order the array
; by one key, and you dont care about how any of the other key values
; are ordered (when there are multiple sorted keys with the same value)
; eg sort could result in something like this:

; sortedKey:     1     associatedKey:   0
; sortedKey:     2     associatedKey:   2*   Higher
; sortedKey:     2     associatedKey:   1*   Lower
; sortedKey:     2     associatedKey:   3
; sortedKey:     3     associatedKey:   12

; (the associated keys will still be paired with their associated sorted key)   

sort2DArray(byRef a, key, Ascending := True)
{
    for index, obj in a
        out .= obj[key] "-" index "|" ; "-" allows for sort to work with just the value
    ; out will look like:   value-index|value-index|

    v := a[a.minIndex(), key]
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
; the sort command only takes a fraction of the function time, the rest is spent
; iterating and copying the data

; Test:
; Object: 
/*
    loop 10000
         a.insert({ "key": rand(1,10), "another": "b"})
*/
; Old Bubble Search
; Bubble took 54,032 ms
; New sort took 26.7 ms (2,023x Faster!)

