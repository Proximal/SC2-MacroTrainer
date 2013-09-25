; A modified bubble search
; This is slow, but very useful.
; If called in the correct sequence, you can completely order 
; a 2 dimensional array by as many keys as you want (and in any order)!

; to achieve this, simply call the function multiple times
; beginning with the lowest priority key, and ending with the highest priority key

sort2DArray(Byref a, key, Order := 1) 
{
    aStorage := []
    unsorted := True 
    While unsorted 		                        ; a two dimensional a
	{           					            ;key : the key name to be sorted
        unsorted := False                       ;Order: 1:Ascending 0:Descending
        For index, in a  		 
		{
            if (lastIndex = index)          ; This speeds it up (almost halves the time)
                break                  
            if (A_Index > 1) &&  (Order 
                                    ? (a[prevIndex, key] > a[index, key]) 
                                    : (a[prevIndex, key] < a[index, key])) 
			{       
                ; making this a single line expression saves ~20 ms on a 1000 index array
                aStorage := a[index]
                , a[index] := a[prevIndex]
                , a[prevIndex] := aStorage
                , unsorted := True			
            }         
            prevIndex := index
        }  
        lastIndex := prevIndex ; previous maxIndex reached (i.e. position of the last moved highest/lowest number)
        ; on each pass through the current highest number will be moved to 1 spot before 'lastIndex'
        ; i.e. towards the right
        ; As we know these values at the end are already the highest
        ; we can break, and don't have to worry about comparing them again
    }
}

; My old Method for bubble used pointers
/*              
               address := &a[index]              
               , PrevAddress := &a[prevIndex]
               , a[index] := Object(PrevAddress)               
               , a[prevIndex] := Object(address)  
    This was maringally slower (&address disables binary caching?)
    for an object which contained 10000 simple 2 element objects
    this was only 1ms slower 62524 ms vs 66318 ms
    clearing the storage object just once (at start) saves another 3s
*/
