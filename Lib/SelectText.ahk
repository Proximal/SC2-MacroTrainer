; selects text in a text box, given absolute character positions
;   if start is -1, the current selection is deselected
;   if end is omitted or -1, the end of the text is used
;       (omit both to select all)

SelectText( ControlID, start=0, end=-1 )
{
    ; EM_SETSEL = 0x00B1
    SendMessage, 0xB1, start, end,, ahk_id %ControlID%
    return (ErrorLevel != "FAIL")
}