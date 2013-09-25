#singleinstance force 

a := []

a.b := [] 

loop 10 
 
   ; a.insert(A_Index)
    a.b.insert(A_Index)
test(a.b)

test(byRef a)
{
    for i in a 
        a[i] := 10
    return
}    
objtree(a)








return
a := []
loop 20
    a.insert({"Letter": chr(96 + A_Index), "AssociatedValue": A_index})
for i, o in a, s := "Letter" A_Tab "AssociatedValue`n`n"
    s .= o.Letter A_Tab o.AssociatedValue "`n"
msgbox % s "`n`nStarting values`n`nclick ok to randomise array"

RandomiseArray(a)
for i, o in a, s := "" 
    s .= o.Letter A_Tab o.AssociatedValue "`n"
msgbox % s "`n`nclick ok to sort by letter (descending)"

sort2DArray(a, "Letter", 0) ; Descending 
for i, o in a, s := "" 
    s .= o.Letter A_Tab o.AssociatedValue "`n"
msgbox % clipboard := s "`n`nclick ok to reverse order"

reverseArray(a)
for i, o in a, s := ""
    s .= o.Letter A_Tab o.AssociatedValue "`n"
msgbox % clipboard := s 

a := []
key := 97 
loop 20
{
    random, major, 97, 101
    random, minor, 1, 2
    random, SubMinor, 1, 2
    a.insert({"major": chr(major), "minor": minor, "SubMinor": SubMinor})
}
for i, o in a, s := "Unsorted`n`n" "Major" A_Tab A_Tab A_Tab "Minor" A_Tab A_Tab A_Tab "SubMinor`n`n"
    s .= o.major A_Tab A_Tab A_Tab o.minor A_Tab A_Tab A_Tab o.SubMinor "`n"
msgbox % clipboard := s "`n`nBubble sort can be used to correctly rank items by any number of properties"
        . "`nclick ok to order by major, then minor, then SubMinor"
; Call bubble sort using the lowest priority key first
bubbleSort2DArray(a, "SubMinor", 0)
bubbleSort2DArray(a, "minor", 1)
bubbleSort2DArray(a, "major", 1)

s := "Major" A_Tab A_Tab A_Tab "Minor" A_Tab A_Tab A_Tab "SubMinor"
 . "`nAscending" A_Tab A_Tab "Ascending" A_Tab A_Tab "Descending`n`n" 

for i, o in a
    s .= o.major A_Tab A_Tab A_Tab o.minor A_Tab A_Tab A_Tab o.SubMinor "`n"
msgbox % clipboard := s 
