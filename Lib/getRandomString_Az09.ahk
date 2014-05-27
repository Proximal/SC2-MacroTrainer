getRandomString_Az09(minLength, maxLength)
{
    loop, % rand(minLength, maxLength)
    {
        if rand(0, 4)
            s .= Chr(rand(0, 1) ? rand(65, 90) : rand(97, 122))  ; A-Z : a-z
        else 
            s .= Chr(rand(48, 57))   ; 0-9
    }
    return s
}