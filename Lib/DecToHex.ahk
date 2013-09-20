DecToHex(Value)
{
   oldfrmt := A_FormatInteger
   hex := Value
   SetFormat, IntegerFast, hex
   hex += 0
   hex .= ""
   SetFormat, IntegerFast, %oldfrmt%
   return hex
}
