#installkeybdhook
setbatchlines, -1
#SingleInstance force
#NoEnv
#singleinstance force
SetBatchLines, -1
#UseHook On
#InstallKeybdHook
#KeyHistory 400
#Persistent



f2:: 
send 1+a+b+2
KeyHistory
return 

; 1 2 3 4 5 6 7 8 9 10
; a c 1 ! x a 9 8 + a

; pos = 3
; 
f1::
newString := ""


Sequence = abc+1+{click left 12 15 2}+a ; +a broken
sLen := StrLen(Sequence)
cIndex := 1
aSend := []

while pos := RegExMatch(Sequence, "\^|\+|\!|\#",, cIndex)
{
   newString .= SubStr(Sequence, cIndex, pos - cIndex)
   cIndex := pos
   modDown := modUp := ""
   loop 
   {
      char := SubStr(Sequence, cIndex, 1)
      cIndex++
      if (char = "+")
         Modifier := "Shift"
      else if (char = "^")
         Modifier := "Ctrl"
      else if (char = "#")
         Modifier := "LWin"   ; no common win key           
      else if (char = "!")
         Modifier := "Alt"
      else 
      {
         newString .= modDown
         if (char = "{")
         {
            newIndex := instr(Sequence, "}", False, C_Index, 1) + 1
            newString .= substr(Sequence, cIndex-1, newIndex-cIndex +1)
            cIndex := newIndex
         }
         else 
            newString .= char 
         newString .= modUp
         break
      }
      modDown .= "{" modifier " down}"
      modUp .= "{" modifier " up}"
   } until (char = "") ; substr returned empty string as have gone too far error
}
newString .= substr(sequence, cIndex+1)
while pos := RegExMatch(newString, "i){\s*click(?:.*})", thisClick, 1)
{
   textSend := substr(newString, 1, pos - 1)
   aSend.Insert(textSend)
   ;thisClick := RegExReplace(thisClick, "i){|}|(?:click)", "")
   msgbox % newString := RegExReplace(newString, "i).*{\s*click[^}]*}", "",,1)

    numPos := 1, numbers := []
    while numPos := RegExMatch(string, "\b(\d+)\b", number, numPos + StrLen(number))
         numbers.insert(number)
    if (!numbers.maxindex() || numbers.maxindex() = 1)
    {
        MouseGetPos, x, y 
        clickCount := numbers.maxindex() ? numbers.1 : 1
    }
    else if (numbers.maxindex() = 2 || numbers.maxindex() = 3)
        x := numbers.1, y := numbers.2, clickCount := numbers.maxindex() = 3 ? numbers.3 : 1
    else continue ; error
    ; replace MM, as this could cause a middle click   
    RegExMatch(thisClick, "i)\b(left|right|l|r|m|middle|x1|x2|wu|wd|WheelDown|WheelUp|WheelLeft|wl|WheelRight|wr)\b", button)
    ; if it doesn't find it button is blank which controlClick will assume is left
    RegExMatch(thisClick, "i)\b(down|d|up|u)\b", event)
    ; if blank still need to send it
   aSend.Insert({    mode: "click" 
            , x: x
            , y: y
            , button: button
            , event: event
            , count: clickCount
            , mouseMove: instr(key, "MM") })
}

if newString
   asend.insert(newString)
if 0
for i, v in aSend
{
   if isObject(v) ; click
   {
      controlClick, % "x" v.x " y" v.y , WinTitle, WinText, % v.button, % v.count, % "pos " (instr(v.event, "d") ? "d" : (instr(v.event, "u") ? "u" :""))
      if v.mouseMove
      {
         lParam := v.x & 0xFFFF | (v.y & 0xFFFF) << 16
         WParamUp := 0
         PostMessage, %WM_MOUSEMOVE%, %WParamUp%, %lParam%, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
      }
   }
   else 
      ControlSend,, %v%, WinTitle, WinText, ExcludeTitle, ExcludeText
}


objtree(asend)
;msgbox % clipboard := newString
return 


;ControlClick [, Control-or-Pos, WinTitle, WinText, WhichButton, ClickCount, Options, ExcludeTitle, ExcludeText]





pSend2(Sequence := "", blind := True)
   {
      caseMode := A_StringCaseSense
      StringCaseSense, Off 

      if !blind
      {
         for index, key in this.modifiers
         {
            if GetKeyState(key)  ; check the logical state (as AHK will block the physical for some)
               Sequence := "{" key " Up}" Sequence "{" key " Down}" 
         }        
      }
      aSend := []
      C_Index := 1
      Currentmodifiers := []
      length := strlen(Sequence) 
      while (C_Index <= length)
      {
         char := SubStr(Sequence, C_Index, 1)
         if char in +,^,!,#
         {     
            if (char = "+")
               Modifier := "Shift"
            else if (char = "^")
               Modifier := "Ctrl"
            else if (char = "#")
               Modifier := "LWin"   ; no common win key           
            else 
               Modifier := "Alt"

            CurrentmodifierString .= char
            Currentmodifiers.insert( {"wParam": GetKeyVK(Modifier) ; used to release modifiers
                        , "sc": GetKeySC(Modifier)
                        , "message": char = "!" ? WM_SYSKEYUP : WM_KEYUP})       

            aSend.insert({   "message": char = "!" ? WM_SYSKEYDOWN : WM_KEYDOWN
                        , "sc": GetKeySC(Modifier)
                        , "wParam": GetKeyVK(Modifier)})
            C_Index++
            continue
            
         }
         if (char = "{")                        ; send {}} will fail with this test. It could be fixed with another if statement
         {                                   ; but cant use that key anyway, as a ] is really shift+] 
            if (Position := instr(Sequence, "}", False, C_Index, 1)) ; lets find the closing bracket) n
            {
               key := trim(substr(Sequence, C_Index+1, Position -  C_Index - 1))
               C_Index := Position ;PositionOfClosingBracket            
               
               key := RegExReplace(key, "\s{2,}|\t", " ") ; ensures tabs replaced with a space - and there is only one space between params
               if instr(key, "click")
               {
                  StringReplace, key, key, click ; remove the word click
                     StringSplit, clickOutput, key, %A_space%, %A_Space%%A_Tab%`,
                   numbers := []
                   loop, % clickOutput0
                   {
                     command := clickOutput%A_index% 
                       if command is number
                           numbers.insert(command)    
                   }
                  
                   if (!numbers.maxindex() || numbers.maxindex() = 1)
                   {
                       MouseGetPos, x, y  ; will cause problems if send hex number to insertpClickObject the regex below fixes this
                       clickCount := numbers.maxindex() ? numbers.1 : 1
                   }
                   else if (numbers.maxindex() = 2 || numbers.maxindex() = 3)
                       x := numbers.1, y := numbers.2, clickCount := numbers.maxindex() = 3 ? numbers.3 : 1
                   else continue ; error
                   ; replace MM, as this could cause a middle click   
                   if (mousemove := instr(key, "MM"))
                     StringReplace, key, key, MM,, All                
                   
                   ; at this point key variable will look like this  D 1920 1080, U 1920 1080, U L 1920 1080 
                   ; I don't need to refine the actual button any more, as the else-if in the function
                   ; will still correctly identify the button
                   ; e.g.  Middle 1920 1080 will still click the middle button, even though there is a d in middle
                   ; This regex will remove any numbers/hex which are not part of a text word i.e. xbutton1 is fine
                   ; Otherwise if coordinates were in hex, and it contained the number D, it could be seen as a down event

                   key := RegExReplace(key, "i)(?:\b\d+\b)|(:?0x[a-f0-9]+)", "")
                   this.pClick(x, y, key, clickCount, CurrentmodifierString, mousemove, aSend) 
                  skip := True ; as already inserted a mouse click event
               }
                  ; This RegExMatch takes ~0.02ms (after its first cached)
               else if RegExMatch(key, "iS)(?<key>[^\s]+)\s*(?<event>\b(?:up|u|down|d)\b)?\s*(?<count>(?:0x[a-f0-9]+\b)|\d+\b)?", send)
               && getkeyVK(sendKey) ; if key is valid
               {
                  instr(sendKey, "alt") 
                  ? (downMessage := WM_SYSKEYDOWN, upMessage := WM_SYSKEYUP)
                  : (downMessage := WM_KEYDOWN, upMessage := WM_KEYUP)

                  if instr(sendEvent, "d") || instr(sendEvent, "u")
                  {
                     message := instr(sendEvent, "d") ? downMessage : upMessage
                     loop, % sendCount ? sendCount : 1
                     {                 
                        aSend.insert({   "message": message     
                                    , "sc": GetKeySC(sendKey)
                                    , "wParam": GetKeyVK(sendKey)})
                     }                          
                  }
                  else ; its a complete press down + up
                  {
                     loop, % sendCount ? sendCount*2 : 2
                     {
                        aSend.insert({   "message": mod(A_index, 2) ? downMessage : upMessage
                                    , "sc": GetKeySC(sendKey)
                                    , "wParam": GetKeyVK(sendKey)})
                     }
                  }
                  skip := True ; skip sending char, as key was sent here instead
               }
               else skip := True ; use of { without a valid click or key syntax
            }
            else skip := True ; something went wrong 
         }

         if skip
            skip := False
         else ; its a char without a specified click count or down/up event
         {
            loop, 2
               aSend.insert({   "message": A_Index = 1 ? WM_KEYDOWN : WM_KEYUP
                           , "sc": GetKeySC(char)
                           , "wParam": GetKeyVK(char)})
         }

         if Modifier
         {
            for index, modifier in Currentmodifiers
               aSend.insert({   "message": modifier.message
                           , "sc": modifier.sc
                           , "wParam": modifier.wParam})
            Modifier := False
            CurrentmodifierString := "", Currentmodifiers := []
         }
         C_Index++
      }
      static test 
      if !test
         stest := stopwatch()
      
      for index, message in aSend
      {
         if (WM_KEYDOWN = message.message || WM_SYSKEYDOWN = message.message)
         {
             ; repeat code | (scan code << 16)
            lparam := 1 | (message.sc << 16)
            postmessage, message.message, message.wParam, lparam, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
            if (this.pSendPressDuration != -1)
               this.sleep(this.pSendPressDuration)
         
         }
         else if (WM_KEYUP = message.message || WM_SYSKEYUP = message.message)
         {
             ; repeat code | (scan code << 16) | (previous state << 30) | (transition state << 31)
            lparam := 1 | (message.sc << 16) | (1 << 30) | (1 << 31)
            postmessage, message.message, message.wParam, lparam, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
            if (this.pCurrentSendDelay != -1)
               this.sleep(this.pCurrentSendDelay)     
         }
         else ; mouse event
         {
            ; If mouse move is included it actually moves the mouse for an instant!
            postmessage, message.message, message.wParam, message.lparam, % this.Control, % this.WinTitle, % this.WinText, % this.ExcludeTitle, % this.ExcludeText
            if (message.HasKey("delay") && message.delay != -1)
               this.sleep(message.delay)
         }
      }
      StringCaseSense, %caseMode%
      return aSend
   }











/*
STMS() { ; System Time in MS / STMS() returns milliseconds elapsed since 16010101000000 UT
Static GetSystemTimeAsFileTime, T1601                              ; By SKAN / 21-Apr-2014  
  If ! GetSystemTimeAsFileTime
       GetSystemTimeAsFileTime := DllCall( "GetProcAddress", UInt
                                , DllCall( "GetModuleHandle", Str,"Kernel32.dll" )
                                , A_IsUnicode ? "AStr" : "Str","GetSystemTimeAsFileTime" ) 
  DllCall( GetSystemTimeAsFileTime, Int64P,T1601  )
Return T1601 // 10000
}





/*
SetFormat, integer, h
msgbox % clipboard := getkeyvk("ins") "`n" getkeyvk("NumpadIns") ; both 0x2D

; 0x60   0x2d



loop 
   msgbox % GetKeyState("NumpadEnter") "`n" GetKeyState("Enter") ; numpad0 / insert - only one can be down due to numlock state
   ;msgbox % GetKeyState("vk60") "`n" GetKeyState("vk2d") ; numpad0 / insert - only one can be down due to numlock state
   ;msgbox % GetKeyState("insert") "`n" GetKeyState("NumpadIns") ; will always be the same regardless of which is pressed
/*




; 0C  04C   i  u  0.00  NumpadClear 



/*
f1::
if !isobject(aJokes) || !aJokes.maxIndex()
{
   if !jokes
      fileRead, jokes, *t jokes.txt 
   aJokes := []
   loop, parse, jokes, `n 
      aJokes.Insert(A_LoopField)
}
random, index, aJokes.MinIndex(), aJokes.MaxIndex()
string := aJokes.Remove(index)
loop, parse, string, |
{
   if (A_index != 1)
      keywait, Enter, D
   sendRaw %A_LoopField%
} 
return 














/*

f1::
s := ""
Loop
   {
      offsetmove := A_Index * 29 
      box1x := 460 + offsetmove
      mousemove, box1x, 365
      s .= "`n" A_Index ": " box1x
      sleep 500
      If A_Index = 12
         Break
      else
         Sleep, 1000
   }

msgbox % clipboard := s

/*


1: 489
2: 518
3: 547
4: 576
5: 605
6: 634
7: 663
8: 692
9: 721
10: 750
11: 779
12: 808

*/




/*

^+a::
list := "control,shift,a"
loop, parse, list, `,
{  
   s .= "`n" A_LoopField ":" 
   s .= "`n" GetKeyState(A_LoopField)
   s .= " | " GetKeyState(A_LoopField, "P")
}
msgbox % s
return 




; *a & b:: invalid hotkey
; Hotkeys likes *!F1:: Will still need the alt key down to fire
; so need to create a *F1:: hotkey from this

gethotkeySuffix(hotkey, containsPrefix := "", containsWildCard := "")
{
   containsPrefix := RegExMatch(hotkey, "\^|\+|\!|\&")

   ; so it's already a wild card hotkey
   containsWildCard := instr(hotkey, "*")
   if (p := instr(FinalKey := RegExReplace(hotkey,"[\*\~\$\#\+\!\^\<\>]"), "&"))
      FinalKey := trim(SubStr(FinalKey, p+1), A_Space A_Tab)
   return FinalKey
}




; strlen 400 and none of these chars are in the string
; if instr(s, "m")                     0.000118
; if instr(s, "m") || instr(s, "n")       0.000181
; if instr(s, "m") || instr(s, "n") 
;  || instr(s, "q") || instr(s, "a")      0.00318  
; if s contains m                      0.000103
; if s contains m,n                 0.000114
; if s contains m,n,q,a                0.000135





 