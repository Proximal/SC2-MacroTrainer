; Uses a basic bubble search
; Original Author https://sites.google.com/site/ahkref/custom-functions/sort2darray
; Though had to alter it as it didn't update the objects other associated values

sort2DArray(Byref TDArray, KeyName, Order := 1) 
{
    aStorage := []
    For index2, obj2 in TDArray 		 ;TDArray : a two dimensional TDArray
	{           						 ;KeyName : the key name to be sorted
        For index, obj in TDArray  		 ;Order: 1:Ascending 0:Descending
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

; My old Method for bubble used pointers
/*              
               address := &TDArray[index]              
               , PrevAddress := &TDArray[prevIndex]
               , TDArray[index] := Object(PrevAddress)               
               , TDArray[prevIndex] := Object(address)  
    This was maringally slower (&address disables binary caching?)
    for an object which contained 10000 simple 2 element objects
    this was only 1ms slower 62524 ms vs 66318 ms
    clearing the storage object just once (at start) saves another 3s
*/
