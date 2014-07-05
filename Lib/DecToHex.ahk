DecToHex(Value)
{
   oldfrmt := A_FormatInteger
   hex := Value
   SetFormat, IntegerFast, Hex ; Capital H so hex letters are capitalised
   hex += 0
   hex .= ""
   SetFormat, IntegerFast, %oldfrmt%
   return hex
}
