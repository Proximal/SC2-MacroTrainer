; length includes inserted spaces
; 1 in 6 chance of a space (spaces can not occur at start or end)
; Non spaces:
; 4:1 letter:digit
; 2:1 lower-case

getRandomString_Az09(minLength, maxLength, insertSpace := True)
{
    loop, % l := rand(minLength, maxLength)
    {
    	if (A_Index > 1 && A_Index != l && insertSpace && !rand(0, 5))
    		s .= A_Space
        else if rand(0, 4)
            s .= Chr(rand(0, 2) ? rand(97, 122) : rand(65, 90) )  ; a-z : A-Z 
        else 
            s .= rand(0, 9)   ; 0-9
    }
    return s
}