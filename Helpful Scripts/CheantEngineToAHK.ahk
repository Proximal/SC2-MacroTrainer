#SingleInstance force
SetBatchLines, -1  

ExampleInput =
(
SC2.AssertAndCrash+378306 - 8B 15 C8B0C202        - mov edx,[SC2.exe+188B0C8]
SC2.AssertAndCrash+37830C - 33 15 B8982B03        - xor edx,[SC2.exe+1F198B8]
SC2.AssertAndCrash+378312 - 81 F2 F8ED2C41        - xor edx,412CEDF8
SC2.AssertAndCrash+378318 - 8B 0A                 - mov ecx,[edx]
SC2.AssertAndCrash+37831A - 8D 0C 81              - lea ecx,[ecx+eax*4]
SC2.AssertAndCrash+37831D - 0FB7 01               - movzx eax,word ptr [ecx]
SC2.AssertAndCrash+378320 - 0FB7 49 02            - movzx ecx,word ptr [ecx+02]
SC2.AssertAndCrash+378320 - 0FB7 49 02            - movzx ecx,word ptr [ecx+02]
)

ExampleInput =
(
SC2.AssertAndCrash+4E81E4 - 8B 53 54              - mov edx,[ebx+54]
SC2.AssertAndCrash+4E81E7 - 56                    - push esi
SC2.AssertAndCrash+4E81E8 - 8B 73 50              - mov esi,[ebx+50]
SC2.AssertAndCrash+4E81EB - 57                    - push edi
SC2.AssertAndCrash+4E81EC - 8B FE                 - mov edi,esi
SC2.AssertAndCrash+4E81EE - 8B C6                 - mov eax,esi
SC2.AssertAndCrash+4E81F0 - F7 D0                 - not eax
SC2.AssertAndCrash+4E81F2 - C1 EF 0C              - shr edi,0C
SC2.AssertAndCrash+4E81F5 - 2B C7                 - sub eax,edi
SC2.AssertAndCrash+4E81F7 - 25 FF0F0000           - and eax,00000FFF
SC2.AssertAndCrash+4E81FC - 2B 14 85 E8369801     - sub edx,[eax*4+SC2.exe+19436E8]
SC2.AssertAndCrash+4E8203 - 8B C2                 - mov eax,edx
SC2.AssertAndCrash+4E8205 - C1 E8 0C              - shr eax,0C
SC2.AssertAndCrash+4E8208 - 8B FA                 - mov edi,edx
SC2.AssertAndCrash+4E820A - F7 D7                 - not edi
SC2.AssertAndCrash+4E820C - 03 C7                 - add eax,edi
SC2.AssertAndCrash+4E820E - 25 FF0F0000           - and eax,00000FFF
SC2.AssertAndCrash+4E8213 - 8B 04 85 E8369801     - mov eax,[eax*4+SC2.exe+19436E8]
SC2.AssertAndCrash+4E821A - 03 C6                 - add eax,esi
SC2.AssertAndCrash+4E821C - 8B F0                 - mov esi,eax
SC2.AssertAndCrash+4E821E - 33 F2                 - xor esi,edx
SC2.AssertAndCrash+4E8220 - 81 E6 55555555        - and esi,55555555
SC2.AssertAndCrash+4E8226 - 33 F0                 - xor esi,eax
SC2.AssertAndCrash+4E8228 - 33 C2                 - xor eax,edx
SC2.AssertAndCrash+4E822A - 25 55555555           - and eax,55555555
SC2.AssertAndCrash+4E822F - 33 C2                 - xor eax,edx

)

gui, add, text, xm ym, Cheat Engine Code:
gui, add, edit, xm w600 h300 vInputCE, %ExampleInput%
gui, add, button, % "xp+" ((600//2)-60//2) " y+10 w60 h40 gConvert", Convert
gui, add, checkbox, x+50 yp vInsertCommas, Insert Commas?
gui, add, text, xm y+0, Output:
gui, add, edit, xm w600 h300 vOutputAHK, This script is only meant to facilitate the conversion of ASM to AHK.`nThe output must be checked and corrected.`nI do not want to use slow objects or memory buffers, so many things are not supported!
Gui, show,, CE to AHK
return 

guiClose:
exitapp 
return 

Convert:
gui, Submit, NoHide 
input := trim(InputCE, A_tab A_space)
ouput := ASMToAHK.parseASM(input)
if !InsertCommas
    StringReplace, ouput, ouput, `n`,,`n, All
GuiControl,, OutputAHK, %ouput%
return 

class ASMToAHK
{
    static 16BitRegisters := "ax,cx,dx,bx,sp,bp,si,di"
    static 8BitLowReigsters := "al,cl,dl,bl"
    static 8BitHighReigsters := "ah,ch,dh,bh"

    movzx(a, b, c*)
    {
        return this.mov(a, b)
    }
    readMem(addressExpr, bytes := 4)
    {
        if bytes = 4
            return "readMemory(" addressExpr ", GameIdentifier)"
        return "readMemory(" addressExpr ", GameIdentifier, " bytes ")"
    }
    mov(a, b, convertedRegister := "")
    {
        if convertedRegister ; Due to bug in AHK, cant define method as   mov(a, b, c*), then use c.convertedRegister (named parameter) when passing parameters as an array (it works with function calls, but not object methods) - so give 'convertedRegister' a key value of 3
            return a " |= " b 
        return a " := " b 
    }
    ; Faster to use an actual variable than an object
    push(operand, c*)
    {
        return "stack_" this.StackCount++ " :=  " operand 
       ; return "aStack.Insert(" operand ")"
    }
    pop(operand, c*)
    {
        if this.StackCount <= 0
            alertSuffix := " `; Attention!!"
        return operand " :=  stack_" --this.StackCount alertSuffix
        ;return operand " :=  aStack.remove()" 
    }
    shr(operand, value, c*)
    {
        return operand " >>= " value 
    }
    shl(operand, value, c*)
    {
        return operand " <<= " value 
    }
    and(operand, value, c*)
    {
        return operand " &= " value 
    }
    xor(operand, value, c*)
    {
        return operand " ^= " value 
    }
    not(operand, c*)
    {
        return operand " := ~" operand 
    }     
    lea(operand, value, c*)
    {
        return operand " := " value
    }
    add(operand, value, c*)
    {
        return operand " += " value
    }  
    sub(operand, value, c*)
    {
        return operand " -= " value
    }    
    imul(operand1, operand2, value, c*)
    {
        return operand1 " *= " value
    }
    isValidInstruction(command)
    {
        if command in mov,movzx,push,pop,shr,shl,and,xor,not,lea,add,sub,imul,je,jne
            return true
        return false
    }
    splitCode(asm, byRef command)
    {
        aOperands := []
        command := ""
        pos := RegExMatch(asm, "([a-zA-Z0-9]*) ", out) ; mov [ebp+08],dx
        command := aOperands.Command :=  out1 
        StringReplace, asm, asm, % aOperands.Command
        asm := trim(asm, A_space A_tab)
        for i, operand in StrSplit(asm, ",")
        {
            aOperands[i] := operand

        }
        return aOperands
    }  
    parseASM(asm)
    {
        this.StackCount := 0
        loop, Parse, asm, `n 
        {
            parsedLine := A_LoopField
            if !RegExMatch(parsedLine, "[^\s]+") ; blank line
            {
                r .= "`n"
                continue 
            }

            line := StrSplit(parsedLine, " - ") ; SC2.AssertAndCrash+3B1977 - mov edx,eax 
            line.Pos := line.1 ; SC2.AssertAndCrash+3B1977
            line.ASM := line.2
            line.Code := line.3 ; mov edx,eax 
            line.code := this.ReplaceRegistersAndAlter(line.code, line.ASM)
            aOperands := this.splitCode(line.code, command)
            if !this.isValidInstruction(command)
            || (command = "je" || command = "jne")
            {
                r .= "; " parsedLine " Attention!`n`n"
                continue
            }

            this.AlterOperands(command, aOperands)
            r .= ", " this[command](aOperands*) "`n"
        }
        return Ltrim(r, "," A_Space A_Tab) 
    }
    AlterOperands(command, aOperands)
    {
        for i, register in StrSplit(this.16BitRegisters, ",")
            aOperands.2 := RegExReplace(aOperands.2, "\b(" register ")", "e$1 & 0xFFFF", foundCound), foundCound ? aOperands.3 := True : "" ; .3 = convertedRegister
        for i, register in StrSplit(this.8BitLowReigsters, ",")
            aOperands.2 := RegExReplace(aOperands.2, "\b(" register ")", "e" SubStr(register, 1, 1) "x & 0xFF"), foundCound ? aOperands.3 := True : "" ; .3 = convertedRegister
        for i, register in StrSplit(this.8BitHighReigsters, ",")
            aOperands.2 := RegExReplace(aOperands.2, "\b(" register ")", "(e" SubStr(register, 1, 1) "x >> 8) & 0xFF"), foundCound ? aOperands.3 := True : "" ; .3 = convertedRegister    

        if instr(aOperands.2, "+") && !instr(aOperands.2, "[") 
        {  ; Only noticed CE stuff this up with XOR
            ;SC2.AssertAndCrash+375D3E - 35 DCBA2B77     - xor eax,ntdll.dll+15BADC 
            realAddress := "," this.reverseBytes(strsplit(asm, A_Space).2) ; reverse DCBA2B77
            code := RegExReplace(code, ",(.*)", realAddress) ; replace ,ntdll.dll+15BADC  with , 772BBADC 
        }

        if RegExMatch(aOperands.2, "\[(.*)\]", out) ; word ptr [SC2.exe+2372AA4] -> SC2.exe+2372AA4 (out1)
        {
            if (command = "lea")
                aOperands.2 := out1
            else if InStr(aOperands.2, "word ptr")
                aOperands.2 := this.readMem(out1, 2)
            else aOperands.2  := this.readMem(out1, 4)
        }   
    }
    reverseBytes(str)
    {
        str := trim(str, A_Tab A_Space)
        loop, % StrLen(str) / 2
            r := SubStr(str, 1 + (A_Index - 1) * 2, 2) r
        return r
    }   
    ReplaceRegistersAndAlter(code, asm)
    {       
       ; for i, register in ["eax", "ebx", "ecx", "edx", "esi", "edi", "esp", "ebp"]
        if instr(code, "SC2.exe" "+") 
            StringReplace, code, code, SC2.exe+,  OffsetsSC2Base+, All
        code := RegExReplace(code, "(\b[0-9A-F]+)", "0x$1") ; only caps hex - prevents edx being replaced       
        
        StringReplace, code, code, +, %A_space%+%a_space%, All
        StringReplace, code, code, *, %A_space%*%a_space%, All
        StringReplace, code, code, -, %A_space%-%a_space%, All
        return code
    }
    addHexPrefix(byRef operand)
    {
        operand := RegExReplace(operand, "([0-9A-F]+)", "0x$1") ; only caps hex - prevents edx being replaced
        return operand        
    }


}

