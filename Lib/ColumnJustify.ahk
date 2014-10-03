ColumnJustify(lines, lcr = "l", del = "`t", extraPadding := 4)
{
  Loop, Parse, lines, `n, `r
    Loop, Parse, A_LoopField, %del%
    {
      If ((t := StrLen(A_LoopField) + extraPadding) > c%A_Index% )
        c%A_Index% :=  t
      If (t > max)
        max := t
    }
  loop, % max
 	 blank .= A_Space
  If (lcr = "l") ;left-justify
    Loop, Parse, lines, `n, `r
      Loop, Parse, A_LoopField, %del%
        out .= (A_Index = 1 ? "`n" : " ") SubStr(A_LoopField blank, 1, c%A_Index%)
  Else If (lcr = "r") ;right-justify
    Loop, Parse, lines, `n, `r
      Loop, Parse, A_LoopField, %del%
        out .= (A_Index = 1 ? "`n" : " ") SubStr(blank A_LoopField, -c%A_Index%+1)
  Else If (lcr = "c") ;center-justify
    Loop, Parse, lines, `n, `r
      Loop, Parse, A_LoopField, %del%
        out .= (A_Index = 1 ? "`n" : " ") SubStr(blank A_LoopField blank
          , (Ceil((max * 2 + StrLen(A_LoopField))/2) - Ceil(c%A_Index%/2) + 1)
          , c%A_Index%)
  return SubStr(out, 2)
}