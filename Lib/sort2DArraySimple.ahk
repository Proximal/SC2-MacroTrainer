; Sort will probably only work for numeric keys, as the index value
; would likely influence the string sort

; Note: This can only be used if you want to order the array
; by one key, and you dont care about how any of the other key values
; may be unordered
; eg sort could result in something like this
; 1     0
; 2     2   Higher
; 2     1   Lower
; 3     5

; the other keys will still be in the correct positions relative to the sorted key   

sort2DArraySimple(byRef a, key, Ascending := True)
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
; the sort command only takes a fraction of the function time, the rest is spent
; iterating and copying the data

; Test:
; Object: 
/*
    loop 10000
         a.insert({ "key": rand(1,10), "another": "b"})
*/
; Old Bubble Search
; Bubble took 59,0832 ms
; New sort took 267.7 ms (2,207x Faster!)