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
)

gui, add, text, xm ym, Cheat Engine Code:
gui, add, edit, xm w600 h300 vInputCE, %ExampleInput%
gui, add, button, % "xp+" ((600//2)-60//2) " y+10 w60 h40 gConvert", Convert
gui, add, text, xm y+0, Output:
gui, add, edit, xm w600 h300 vOutputAHK, This script is only meant to facilitate the conversion of ASM to AHK.`nThe output must be checked and corrected.`nI do not want to use slow objects or memory buffers, so many things are not supported!
Gui, show,, CE to AHK
return 

Convert:
gui, Submit, NoHide 
input := trim(InputCE, A_tab A_space)
GuiControl,, OutputAHK, % ASMToAHK.parseASM(input)
return 

class ASMToAHK
{
    16BitRegisters := "AX,CX,DX,BX,SP,BP,SI,DI"
    8BitLowReigsters := "AL,CL,DL,BL,SL,BL,SL,DL"
    8BitHighReigsters := "AH,CH,DH,BH,SH,BH,SH,DH"

    movzx(a, b, c*)
    {
        if b in % this.16BitRegisters
        {
            b := "e" b ; AX -> EAX
            return a " := " b " & 0xFFFF" 
        }
        else if b in % this.8BitLowReigsters
        {
            b := "e" substr(b, 1, 1) "x" ; AL -> EAX
            return a " := " b " & 0xFF" ; 0 - 8 bits
        }
        else if b in % this.8BitHighReigsters
        {
            b := "e" substr(b, 1, 1) "x" ; AH -> EAX
            return a " := (" b " >> 8 ) & 0xFF"  ; 8-16 bits
        }
        return this.mov(a, b)
    }
    readMem(addressExpr, bytes := 4)
    {
        if bytes = 4
            return "readMemory(" addressExpr ", GameIdentifier)"
        return "readMemory(" addressExpr ", GameIdentifier, " bytes ")"
    }
    mov(a, b)
    {
        if b in % this.16BitRegisters
        {
            b := "e" b ; AX -> EAX
            return a " |= " b " & 0xFFFF" 
        }
        else if b in % this.8BitLowReigsters
        {
            b := "e" substr(b, 1, 1) "x" ; AL -> EAX
            return a " |= " b " & 0xFF" ; 0 - 8 bits
        }
        else if b in % this.8BitHighReigsters
        {
            b := "e" substr(b, 1, 1) "x" ; AH -> EAX
            return a " |= (" b " >> 8 ) & 0xFF"  ; 8-16 bits
        }
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
        if command in mov,movzx,push,pop,shr,shl,and,xor,not,lea,sub,imul,je,jne
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
                s .= "; " parsedLine " Attention!`n`n"
                continue
            }

            this.AlterOperands(command, aOperands)
            r .= ", " this[command](aOperands*) "`n"
        }
        return Ltrim(r, "," A_Space A_Tab) 
    }
    AlterOperands(command, aOperands)
    {
        for i, operand in aOperands
        {
            if (i = 1)
                continue 
            if RegExMatch(operand, "\[(.*)\]", out) ; word ptr [SC2.exe+2372AA4] -> SC2.exe+2372AA4 (out1)
            {
                if (command = "lea")
                    aOperands[i] := out1
                else if InStr(operand, "word ptr")
                    aOperands[i] := this.readMem(out1, 2)
                else aOperands[i]  := this.readMem(out1, 4)
            }
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
        aOperands := this.splitCode(code, command)
        if instr(aOperands.2, "+") && !instr(aOperands.2, "[") 
        {  ; Only noticed CE stuff this up with XOR
            ;SC2.AssertAndCrash+375D3E - 35 DCBA2B77     - xor eax,ntdll.dll+15BADC 
            realAddress := "," this.reverseBytes(strsplit(asm, A_Space).2) ; reverse DCBA2B77
            code := RegExReplace(code, ",(.*)", realAddress) ; replace ,ntdll.dll+15BADC  with , 772BBADC 
        }
        
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
    convertSourceOperand(byRef operand, instruction := "")
    {
        static aWordRegisters := ["ax", "bx","cx","dx","si","di"]
        if instr(operand, this.dllName "+") 
            StringReplace, operand, operand, % this.dllName "+",  "dllBaseAddress+", All
        operand := RegExReplace(operand, "([0-9A-F]+)", "0x$1") ; only caps hex - prevents edx being replaced
        for i, wordRegister in aWordRegisters
            operand := RegExReplace(operand, "\b" wordRegister, "e$1 & 0xFFFF")
        return operand
    }

}

