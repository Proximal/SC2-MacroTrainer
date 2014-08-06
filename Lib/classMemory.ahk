/*
    18/05/14
        -   Fixed issue with get getBaseAddressOfModule() returning the incorrect module 
            when specified module name formed part of another modules name
    10/06/14
        -   Fixed a bug introduced by the above change, which prevented the function returning 
            the base address of the process.
    12/07/14 - version 1.0
        -   Added writeBuffer() method
        -   Added a version number to the class
    30/07/14 - version 1.1
        -   EnumProcessModulesEx() is now used instead of EnumProcessModules().
            This allows for getBaseAddressOfModule() in a 64 bit AHK process to enumerate
            (and find) the modules in a 32 bit target process.
    1/08/14 - version 1.2
        -   getProcessBaseAddress() dllcall now returns Int64. This prevents a negative number (overflow)
            when reading the base address of a 64 bit target process from a 32 bit AHK process.


    RHCP's basic memory class:

    This is a basic wrapper for commonly used read and write memory functions.
    This allows scripts to read/write integers and strings of various types.
    Pointer addresses can easily be read/written by passing the base address and offsets to the various read/write functions
    
    Process handles are kept open between reads. This increases speed.
    Note, if a program closes/restarts then the process handle will be invalid
    and you will need to re-open another handle (blank/destroy the object and then recreate the it)

    read(), readString(), write(), and writeString() can be used to read and write memory addresses respectively.

    ReadRawMemory() can be used to dump large chunks of memory, this is considerably faster when
    reading data from a large structure compared to repeated calls to read().
    Although, most people wouldn't notice the performance difference. This does however require you 
    to retrieve the values using AHK's numget()/strGet() from the dumped memory.

    In a similar fashion writeBuffer() allows a buffer to be be written in a single operation. 
    
    When the new operator is used this class returns an object which can be used to read that processes 
    memory space.
    To read another process simply create another object.

    process handles are automatically closed when the script exits/restarts or when you free the object.

    Note:
    This was written for 32 bit target processes, but the various read/write functions
    should still work when directly reading/writing an address in a 64 bit process. 
    The pointer parts of these functions wont, as I assume pointers are stored as 64bit values.

    Also very large (unsigned) 64 bit integers may not be read correctly - the current function works 
    for the 64 bit ints I use it on. AHK doesn't directly support 64bit unsigned ints anyway

    If the process has admin privileges, then the AHK script will also require admin privileges to work. 

    Commonly used methods:
        read()
        readString()
        ReadRawMemory()
        write()
        writeString()
        writeBuffer()
        getProcessBaseAddress()
        getBaseAddressOfModule()

    Internal methods: (not as useful)
        pointer()
        getAddressFromOffsets()  

    Usage:

        **Note: If you wish to try this calc example, ensure you run the 32 bit version of calc.exe - 
                which is in C:\Windows\SysWOW64\calc.exe on 64 bit systems. You can still read/write directly to
                a 64 bit calc process address (I doubt pointers will work), but the getBaseAddressOfModule() example 
                will not work unless the you are using a 64 bit version of ahk (it will return -4 indicating the operation is not possible)

        The contents of this file can be copied directly into your script. Alternately you can copy the classMemory.ahk file into your library folder,
        in which case you will need to use the #include directive in your script i.e. #Include <classMemory>
        You can use this code to check if you have installed the class correctly.
        if (memory.__Class != "Memory")
            msgbox class memory not correctly installed. Or the (global class) variable "Memory" has been overwritten
        else msgbox class memory correctly installed
        

        Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
        You only need to do this once. But if the process closes, then you will need to reopen.
        Also, if the target process is running as admin, then the script will also require admin rights!
            calc := new memory("ahk_exe calc.exe") ; Note: This can be an ahk_exe, ahk_class, ahk_pid, or simply the window title. 
            
        Get the processes base address
            msgbox % calc.BaseAddress
        
        Get the base address of a module
            msgbox % calc.getBaseAddressOfModule("GDI32.dll")

        The rest of these examples are just for illustration (the addresses specified are probably not valid).
        You can use cheat engine to find real addresses to read and write to for testing purposes.
        
        write 1234 to a UInt at address 0x0016CB60
            calc.write(0x0016CB60, 1234, "UInt")

        read a UInt
            value := calc.read(0x0016CB60, "UInt")

        read a pointer with offsets 0x20 and 0x15C which points to a uchar 
            value := calc.read(pointerBase, "UChar", 0x20, 0x15C)

        Note: read(), readString(), ReadRawMemory(), write(), and writeString() all support pointers/offsets
            An array of pointers can be passed directly, i.e.
            arrayPointerOffsets := [0x20, 0x15C]
            value := calc.read(pointerBase, "UChar", arrayPointerOffsets*)
            Or they can be entered manually
            value := calc.read(pointerBase, "UChar", 0x20, 0x15C)

        
        read a utf-16 null terminated string of unknown size at address 0x1234556 - the function will read each character until the null terminator is found
            string := calc.readString(0x1234556, length := 0, encoding := "utf-16")
        
        read a utf-8 encoded character string which is 12 bytes long at address 0x1234556
            string := calc.readString(0x1234556, 12)

        By default a null terminator is included at the end of written strings for writeString()
        The nullterminator property can be used to change this.
            memory.insertNullTerminator := False ; This will change the property for all processes
            calc.insertNullTerminator := False ; Changes the property for just this process     


    Notes: 
        When opening a new process:
        If returned process handle is zero then the program isn't running or you passed an incorrect program identifier parameter
        If the returned process handle is blank, openProcess failed. If the target process has admin rights, then the script also needs to be ran as admin.

*/

class memory
{
    static baseAddress, hProcess
    , insertNullTerminator := True
    , readStringLastError := False
    , aTypeSize := {    "UChar":    1,  "Char":     1
                    ,   "UShort":   2,  "Short":    2
                    ,   "UInt":     4,  "Int":      4
                    ,   "UFloat":   4,  "Float":    4
                    ,   "Int64":    8,  "Double":   8}  

                    ; Although unsigned 64bit values are not supported, you can read them as int64 or doubles and interpret
                    ; the negative numbers as large values

    ; The byRef handle can be used to check if it opened the process successfully
    ; otherwise can check if the returned value is an object
    ; Refer to openProcess() method for details on these parameters
    __new(program, dwDesiredAccess := "", byRef handle := "", windowMatchMode := 3)
    {
        if !(handle := this.openProcess(program, dwDesiredAccess, windowMatchMode))
            return ""
        this.readStringLastError := False
        this.BaseAddress := this.getProcessBaseAddress(program, windowMatchMode)
        return this
    }
    __delete()
    {
        this.closeProcess(this.hProcess)
        return
    }

    version()
    {
        return 1.1
    }

    ; program can be an ahk_exe, ahk_class, ahk_pid, or simply the window title. e.g. "ahk_exe SC2.exe" or "Starcraft II"
    ; but its safer not to use the window title, as some things can have the same window title - e.g. a folder called "Starcraft II"
    ; would have the same window title as the game itself.

    ; Return Values: 
    ;   0 - The program isn't running or you passed an incorrect program identifier parameter
    ;   Null/blank -  OpenProcess failed. If the target process has admin rights, then the script also needs to be ran as admin.
    ;   Positive integer - A handle to the process.

    openProcess(program, dwDesiredAccess := "", windowMatchMode := "3")
    {
        ; if an application closes/restarts the previous handle becomes invalid so reopen it to be safe (closing a now invalid handle is fine i.e. wont cause an issue)
        
        ; This default access level is sufficient to read and write memory addresses.
        ; if the program is run using admin privileges, then this script will also need admin privileges
        if dwDesiredAccess is not integer
            dwDesiredAccess := (PROCESS_QUERY_INFORMATION := 0x0400) | (PROCESS_VM_OPERATION := 0x8) | (PROCESS_VM_READ := 0x10) | (PROCESS_VM_WRITE := 0x20)
        if windowMatchMode
        {
            mode :=  A_TitleMatchMode
            SetTitleMatchMode, %windowMatchMode%
        }
        WinGet, pid, pid, % this.currentProgram := program
        if windowMatchMode
            SetTitleMatchMode, %mode%    ; In case executed in autoexec
        if !pid
            return  this.hProcess := 0 
        return this.hProcess := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", pid) ; NULL/Blank if failed to open process for some reason
    }   

    ; When the script exits/restarts any open handles will automatically be closed!
    ; That is, you don't need to call this function.
    closeProcess(hProcess)
    {
        ; if there was an error when opening handle, handle will be null
        if hProcess
            return DllCall("CloseHandle", "UInt", hProcess)
        return
    }
    ; Method:   read(address, type := "UInt", aOffsets*)
    ;           Reads various integer type values
    ; Parameters:
    ;       address -   The memory address of the value or if using the offset parameter, 
    ;                   the base address of the pointer.
    ;       type    -   The integer type. 
    ;                   Valid types are UChar, Char, UShort, Short, UInt, Int, UFloat, Float, Int64 and Double. 
    ;                   Note: Types must not contain spaces i.e. " UInt" or "UInt " will not work. 
    ;                   When an invalid type is passed the method returns NULL and sets ErrorLevel to -2
    ;       aOffsets* - A variadic list of offsets. When using offsets the address parameter should equal the base address of the pointer.
    ;                   The address (bass address) and offsets should point to the memory address which holds to the integer.  
    ; Return Values:
    ;       integer -   Indicates success.
    ;       Null    -   Indicates failure. Check ErrorLevel and A_LastError for more information.
    ;       Note:       Since the returned integer value may be 0, to check for success/failure compare the result
    ;                   against null i.e. if (result = "") then an error has occurred.
    ;                   When reading doubles, adjusting "SetFormat, float, totalWidth.DecimalPlaces"
    ;                   may be required depending on your requirements.
    read(address, type := "UInt", aOffsets*)
    {
        ; If invalid type RPM() returns success (as bytes to read resolves to null in dllCall())
        ; so set errorlevel to invalid parameter for DLLCall() i.e. -2
        if !this.aTypeSize.hasKey(type)
            return "", ErrorLevel := -2 
        if DllCall("ReadProcessMemory","UInt",  this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, type "*", result, "UInt", this.aTypeSize[type], "Ptr",0)
            return result
        return        
    }
    ; Method:   ReadRawMemory(address, byRef buffer, bytes := 4, aOffsets*)
    ;           Reads an area of the processes memory and stores it in the buffer variable
    ; Parameters:
    ;       address  -  The memory address of the area to read or if using the offsets parameter
    ;                   the base address of the pointer which points to the memory region.
    ;       buffer   -  The unquoted variable name for the buffer. This variable will receive the contents from the address space.
    ;                   This method calls varsetCapcity() to ensure the variable has an adequate size to perform the operation. 
    ;                   If the variable already has a larger capacity (from a previous call to varsetcapcity()), then it will not be shrunk. 
    ;                   Therefore it is the callers responsibility to ensure that any subsequent actions performed on the buffer variable
    ;                   do not exceed the bytes which have been read - as these remaining bytes could contain anything.
    ;       bytes   -   The number of bytes to be read.          
    ;       aOffsets* - A variadic list of offsets. When using offsets the address parameter should equal the base address of the pointer.
    ;                   The address (bass address) and offsets should point to the memory address which is to be read
    ; Return Values:
    ;       Non Zero -   Indicates success.
    ;       Zero     -   Indicates failure. Check errorLevel and A_LastError for more information
    ; 
    ; Notes:            The contents of the buffer may then be retrieved using AHK's NumGet() and StrGet() functions.           
    ;                   This method offers significant (~30% and up) performance boost when reading large areas of memory. 
    ;                   As calling ReadProcessMemory for four bytes takes a similar amount of time as it does for 1,000 bytes.                

    ReadRawMemory(address, byRef buffer, bytes := 4, aOffsets*)
    {
        VarSetCapacity(buffer, bytes)
        return DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "UInt", bytes, "Ptr", 0)
    }

    ; Method:   readString(address, sizeBytes := 0, encoding := "utf-8", aOffsets*)
    ;           Reads string values of various encoding types
    ; Parameters:
    ;       address -   The memory address of the value or if using the offset parameter, 
    ;                   the base address of the pointer.
    ;       sizeBytes - The size (in bytes) of the string to be read.
    ;                   If zero is passed, then the function will read each character until a null terminator is found
    ;                   and then returns the entire string.
    ;       encoding -  This refers to how the string is stored in the program's memory.
    ;                   UTF-8 and UTF-16 are common. Refer to the AHK manual for other encoding types.
    ;       aOffsets* - A variadic list of offsets. When using offsets the address parameter should equal the base address of the pointer.
    ;                   The address (bass address) and offsets should point to the memory address which holds the string.                             
    ;                   
    ;  Return Values:
    ;       String -    On failure an empty (null) string is always returned. Since it's possible for the actual string 
    ;                   being read to be null (empty), then a null return value should not be used to determine failure of the method.
    ;                   Instead the property [derivedObject].ReadStringLastError can be used to check for success/failure.
    ;                   This property is set to 0 on success and 1 on failure. On failure ErrorLevel and A_LastError should be consulted
    ;                   for more information.
    ; Notes:
    ;       For best performance use the sizeBytes parameter to specify the exact size of the string. 
    ;       If the exact size is not known and the string is null terminated, then specifying the maximum
    ;       possible size of the string will yield the same performance.  
    ;       If neither the actual or maximum size is known and the string is null terminated, then specifying
    ;       zero for the sizeBytes parameter is fine. Generally speaking for all intents and purposes the performance difference is
    ;       inconsequential.  

    readString(address, sizeBytes := 0, encoding := "UTF-8", aOffsets*)
    {
        bufferSize := VarSetCapacity(buffer, sizeBytes ? sizeBytes : 100, 0)
        this.ReadStringLastError := False
        if aOffsets.maxIndex()
            address := this.getAddressFromOffsets(address, aOffsets*)
        if !sizeBytes  ; read until null terminator is found or something goes wrong
        {
            encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1
            charType := encodingSize = 1 ? "Char" : "Short"
            Loop
            {
                if (!DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", address + (A_index - 1) * encodingSize, "Ptr", &buffer, "Uint", encodingSize, "Ptr", 0) 
                || ErrorLevel)
                    return "", this.ReadStringLastError := True ;this.hProcess ? "Fail" : "Handle Is closed: " this.hProcess
                else if (0 = NumGet(buffer, 0, charType)) ; NULL terminator
                {
                    if (bufferSize < sizeBytes := A_Index * encodingSize) ; A_Index will equal the size of the string in bytes
                        VarSetCapacity(buffer, sizeBytes)
                    break
                }   
            }
        }
        if DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", address, "Ptr", &buffer, "Uint", sizeBytes, "Ptr", 0)   
            return StrGet(&buffer,, encoding)  
        return "", this.ReadStringLastError := True ; !this.hProcess ? "Handle Is closed: " this.hProcess : "Fail"              
    }

    ; Method:  writeString(address, string, encoding := "utf-8", aOffsets*)
    ;          Encodes and then writes a string to the process.
    ; Parameters:
    ;       address -   The memory address to which data will be written or if using the offset parameter, 
    ;                   the base address of the pointer.
    ;       string -    The string to be written.
    ;       encoding -  This refers to how the string is to be stored in the program's memory.
    ;                   UTF-8 and UTF-16 are common. Refer to the AHK manual for other encoding types.
    ;       aOffsets* - A variadic list of offsets. When using offsets the address parameter should equal the base address of the pointer.
    ;                   The address (bass address) and offsets should point to the memory address which is to be written to.
    ; Return Values:
    ;       Non Zero -   Indicates success.
    ;       Zero     -   Indicates failure. Check errorLevel and A_LastError for more information
    ; Notes:
    ;       By default a null terminator is included at the end of written strings. 
    ;       This behaviour is determined by the property [derivedObject].insertNullTerminator
    ;       If this property is true, then a null terminator is included.       

    writeString(address, string, encoding := "utf-8", aOffsets*)
    {
        encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1
        requiredSize := StrPut(string, encoding) * encodingSize - (this.insertNullTerminator ? 0 : encodingSize)
        VarSetCapacity(buffer, requiredSize)
        StrPut(string, &buffer, this.insertNullTerminator ? StrLen(string) : StrLen(string) + 1, encoding)
        return DllCall("WriteProcessMemory", "UInt", this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Uint", requiredSize, "Ptr", 0)
    }
    
    ; Method:   write(address, value, type := "Uint", aOffsets*)
    ;           Writes various integer type values to the process.
    ; Parameters:
    ;       address -   The memory address to which data will be written or if using the offset parameter, 
    ;                   the base address of the pointer.
    ;       type    -   The integer type. 
    ;                   Valid types are UChar, Char, UShort, Short, UInt, Int, UFloat, Float, Int64 and Double. 
    ;                   Note: Types must not contain spaces i.e. " UInt" or "UInt " will not work. 
    ;                   When an invalid type is passed the method returns NULL and sets ErrorLevel to -2
    ;       aOffsets* - A variadic list of offsets. When using offsets the address parameter should equal the base address of the pointer.
    ;                   The address (bass address) and offsets should point to the memory address which is to be written to.
    ; Return Values:
    ;       Non Zero -  Indicates success.
    ;       Zero     -  Indicates failure. Check errorLevel and A_LastError for more information
    ;       Null    -   An invalid type was passed. Errorlevel is set to -2

    write(address, value, type := "Uint", aOffsets*)
    {
        if !this.aTypeSize.hasKey(type)
            return "", ErrorLevel := -2 
        return DllCall("WriteProcessMemory", "UInt", this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, type "*", value, "Uint", this.aTypeSize[type], "Ptr", 0) 
    }

    ; Method:   writeBuffer(address, byRef buffer, byRef bufferSize := 0, aOffsets*)
    ;           Writes a buffer to the process.
    ; Parameters:
    ;   address -       The memory address to which the contents of the buffer will be written 
    ;                   or if using the offset parameter, the base address of the pointer.    
    ;   pBuffer -       A pointer to the buffer which is to be written.
    ;                   This does not necessarily have to be the beginning of the buffer itself e.g. pBuffer := &buffer + offset
    ;   sizeBytes -     The number of bytes which are to be written from the buffer.
    ;   aOffsets* -     A variadic list of offsets. When using offsets the address parameter should equal the base address of the pointer.
    ;                   The address (bass address) and offsets should point to the memory address which is to be written to.
    ; Return Values:
    ;       Non Zero -  Indicates success.
    ;       Zero     -  Indicates failure. Check errorLevel and A_LastError for more information
    writeBuffer(address, pBuffer, sizeBytes, aOffsets*)
    {
        return DllCall("WriteProcessMemory", "UInt", this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", pBuffer, "Uint", sizeBytes, "Ptr", 0) 
    }
    ; Method:           pointer(base, finalType := "UInt", offsets*)
    ;                   This is an internal method. Since the other various methods all offer this functionality, they should be used instead.
    ;                   This will read integer values of both pointers and non-pointers (i.e. a single memory address)
    ; Parameters:
    ;   base -          The base address of the pointer or the memory address for a non-pointer.
    ;   finalType -     The type of integer stored at the final address.
    ;                   Valid types are UChar, Char, UShort, Short, UInt, Int, UFloat, Float, Int64 and Double. 
    ;                   Note: Types must not contain spaces i.e. " UInt" or "UInt " will not work. 
    ;                   When an invalid type is passed the method returns NULL and sets ErrorLevel to -2
    ;   aOffsets* -     A variadic list of offsets used to calculate the pointers final address.
    ; Return Values: (The same as the read() method)
    ;       integer -   Indicates success.
    ;       Null    -   Indicates failure. Check ErrorLevel and A_LastError for more information.
    ;       Note:       Since the returned integer value may be 0, to check for success/failure compare the result
    ;                   against null i.e. if (result = "") then an error has occurred.

    pointer(base, finalType := "UInt", offsets*)
    { 

        For index, offset in offsets
        {
            if (index = offsets.maxIndex() && A_index = 1)
                pointer := offset + this.Read(base)
            Else IF (A_Index = 1) 
                pointer := this.Read(offset + this.Read(base))
            Else If (index = offsets.MaxIndex())
                pointer += offset
            Else pointer := this.Read(pointer + offset)
        }   
        Return this.Read(offsets.maxIndex() ? pointer : base, finalType)
    }
    ; Method:           getAddressFromOffsets(address, aOffsets*)
    ;                   This is an internal method used by the various methods to determine the final pointer address.
    ; Parameters:
    ;   address -       The base address of the pointer.
    ;   aOffsets* -     A variadic list of offsets used to calculate the pointers final address.
    ;                   At least one offset must be present.
    ; Return Values: (The same as the pointer() method)

    getAddressFromOffsets(address, aOffsets*)
    {
        lastOffset := aOffsets.Remove() ;remove the highest key so can use pointer() to find final memory address (minus the last offset)
        return  this.pointer(address, "UInt", aOffsets*) + lastOffset       
    }

    ; Interesting note:
    ; Although handles are 64-bit pointers, only the less significant 32 bits are employed in them for the purpose 
    ; of better compatibility (for example, to enable 32-bit and 64-bit processes interact with each other)
    ; Here are examples of such types: HANDLE, HWND, HMENU, HPALETTE, HBITMAP, etc. 
    ; http://www.viva64.com/en/k/0005/

    ; The base adress for some programs is dynamic. This can retrieve the current base address of the main module (e.g. calc.exe), 
    ; which can then be added to your various offsets.  
    ; This function will return the correct address regardless of the 
    ; bitness (32 or 64 bit) of both the AHK exe and the target process.

    ; WindowTitle can be anything ahk_exe ahk_class etc
    ; using quotes around the MatchMode "3", so if setFormat Hex is in effect, it won't give an error with SetTitleMatchMode
    getProcessBaseAddress(WindowTitle, windowMatchMode := "3")   
    {
        if windowMatchMode
        {
            mode := A_TitleMatchMode
            SetTitleMatchMode, %windowMatchMode%    ;mode 3 is an exact match
        }
        WinGet, hWnd, ID, %WindowTitle%
        if windowMatchMode
            SetTitleMatchMode, %mode%    ; In case executed in autoexec
        if !hWnd
            return ; return blank failed to find window
       ; GetWindowLong returns a Long (Int) and GetWindowLongPtr return a Long_Ptr
        return DllCall(A_PtrSize = 4     ; If DLL call fails, returned value will = 0
            ? "GetWindowLong"
            : "GetWindowLongPtr", "Ptr", hWnd, "Uint", -6, "Int64")  ; Use Int64 to prevent negative overflow when AHK is 32 bit and target process is 64bit       
    }   

    ; http://winprogger.com/getmodulefilenameex-enumprocessmodulesex-failures-in-wow64/
    ; http://stackoverflow.com/questions/3801517/how-to-enum-modules-in-a-64bit-process-from-a-32bit-wow-process

    ; Method:           getBaseAddressOfModule(module := "", byRef sizeOfImage := "", byRef entryPoint := "")
    ; Parameters:
    ;   module -        The file name of the module/dll to find e.g. "GDI32.dll", "Battle.net.dll" etc
    ;                   If no module (null) is specified, the address of the base module - main()/program will be returned 
    ;                   e.g. C:\Games\StarCraft II\Versions\Base28667\SC2.exe
    ;   aModuleInfo -   A module Info object is returned in this variable. 
    ;                   This object contains the keys: lpBaseOfDll, SizeOfImage, and EntryPoint 
    ; Return Values: 
    ;   Positive integer - The module's base/load address (success).
    ;   -1 - Module not found
    ;   -2 - The process handle has been closed.
    ;   -3 - EnumProcessModulesEx failed
    ;   -4 - The AHK script is 32 bit and you are trying to access the modules of a 64 bit target process. Or the target process has been closed.
    ;   -5 - GetModuleInformation failed.
    ; Notes:    A 64 bit AHK can enumerate the modules of a target 64 or 32 bit process.
    ;           A 32 bit AHK can only enumerate the modules of a 32 bit process
    ;           This method requires PROCESS_QUERY_INFORMATION + PROCESS_VM_READ access rights. These are included by default with this class.

    getBaseAddressOfModule(module := "", byRef aModuleInfo := "")
    {
        if !this.hProcess
            return -2
        if (A_PtrSize = 4)
        {
            DllCall("IsWow64Process", "Ptr", this.hProcess, "Int*", result)
            if !result 
                return -4 ; AHK is 32bit and target process is 64 bit, this function wont work
        }
        if (module = "")
            mainExeFullPath := this.GetModuleFileNameEx() ; mainExeName = main executable module of the process (will include full directory path)
        if !moduleCount := this.EnumProcessModulesEx(lphModule)
            return -3     
        loop % moduleCount
        {
            ; module will contain directory path as well e.g C:\Windows\syswow65\GDI32.dll
            moduleFullPath := this.GetModuleFileNameEx(hModule := numget(lphModule, (A_index - 1) * A_PtrSize))
            SplitPath, moduleFullPath, fileName ; strips the path so = GDI32.dll
            if (module = "" && mainExeFullPath = moduleFullPath) || (module != "" && module = filename)
            {
                if this.GetModuleInformation(hModule, aModuleInfo)
                    return aModuleInfo.lpBaseOfDll
                else return -5 ; Failed to get module info
            }
        }
        return -1 ; not found
    }

    GetModuleFileNameEx(hModule := 0)
    {
        VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1))
        DllCall("psapi\GetModuleFileNameEx"
                    , "Ptr", this.hProcess
                    , "Uint", hModule
                    , "Ptr", &lpFilename
                    , "Uint", 2048 / (A_IsUnicode ? 2 : 1))
        return StrGet(&lpFilename)
    }

    ; dwFilterFlag
    ;   LIST_MODULES_DEFAULT    0x0  
    ;   LIST_MODULES_32BIT      0x01
    ;   LIST_MODULES_64BIT      0x02
    ;   LIST_MODULES_ALL        0x03
    ; If the function is called by a 32-bit application running under WOW64, the dwFilterFlag option 
    ; is ignored and the function provides the same results as the EnumProcessModules function.
    EnumProcessModulesEx(byRef lphModule, dwFilterFlag := 0x03)
    {
        size := VarSetCapacity(lphModule, 4)
        loop 
        {
            DllCall("psapi\EnumProcessModulesEx"
                        , "Ptr", this.hProcess
                        , "Ptr", &lphModule
                        , "Uint", size
                        , "Uint*", reqSize
                        , "Uint", dwFilterFlag)
            if ErrorLevel
                return 0
            else if (size >= reqSize)
                break
            else 
                size := VarSetCapacity(lphModule, reqSize)  
        }
        return reqSize / A_PtrSize ; module count  ; sizeof(HMODULE) - enumerate the array of HMODULEs     
    }

    GetModuleInformation(hModule, byRef aModuleInfo)
    {
        VarSetCapacity(MODULEINFO, A_PtrSize * 3), aModuleInfo := []
        return DllCall("psapi\GetModuleInformation"
                    , "Ptr", this.hProcess
                    , "UInt", hModule
                    , "Ptr", &MODULEINFO
                    , "UInt", A_PtrSize * 3)
                , aModuleInfo := {  lpBaseOfDll: numget(MODULEINFO, 0, "Ptr")
                                ,   SizeOfImage: numget(MODULEINFO, A_PtrSize, "UInt")
                                ,   EntryPoint: numget(MODULEINFO, A_PtrSize * 2, "Ptr") }
    }  
    
    ; This will scan the memory region of a loaded module
    ;   module -        The file name of the module/dll to find e.g. "GDI32.dll", "Battle.net.dll" etc
    ;                   If no module (null) is specified, the address of the base module - main()/program will be returned 
    ;                   e.g. C:\Games\StarCraft II\Versions\Base28667\SC2.exe
    modulePatternScan(module := "", aAOBPattern*)
    {
        if result := this.getBaseAddressOfModule(module, aModuleInfo)
           return this.patternScan(aModuleInfo.lpBaseOfDll, aModuleInfo.SizeOfImage, aAOBPattern*) 
        return "", ErrorLevel := result ; failed
    }
    ; Scans a specified memory region for a pattern
    patternScan(startAddress, sizeOfRegionBytes, aAOBPattern*)
    {
        if aPattern.MaxIndex() > sizeOfRegionBytes
            return -1
        if !this.ReadRawMemory(startAddress, buffer, sizeOfRegionBytes)
            return -2
        while((i := A_Index - 1) <= sizeOfRegionBytes - aAOBPattern.MaxIndex()) 
        {
            for j, value in aAOBPattern
            {
                if (value != "?" && value != Numget(buffer, i + j - 1, "UChar"))
                    break
                else if aAOBPattern.MaxIndex() = j 
                    return startAddress + i
            }
        }
        return 0
    }
    ; scans the entire memory space of the process
    processPatternScan(aAOBPattern*)
    {
        address := 0
        MEM_COMMIT := 0x1000       
        MEM_MAPPED := 0x40000
        MEM_PRIVATE := 0x20000
        PAGE_NOACCESS := 0x01
        PAGE_GUARD := 0x100
        while this.VirtualQueryEx(address, aInfo)
        {
            if (aInfo.State = MEM_COMMIT) 
            && !(aInfo.Protect & PAGE_NOACCESS) ; can't read this area
            && !(aInfo.Protect & PAGE_GUARD) ; can't read this area
            && (aInfo.Type = MEM_MAPPED || aInfo.Type = MEM_PRIVATE)
            {
                if !result := this.patternScan(address, aInfo.RegionSize, aAOBPattern*)
                    address += aInfo.RegionSize
                else if result > 0
                    return result ; address of the pattern
                else ; negative error (-1 or -2)
                    return result ;"Pattern.Scan() failed at address: " address "`n" A_LastError " | " ErrorLevel
            }
            else address += aInfo.RegionSize
        }
        return 0 ; "VirtualQueryEx() failed (or pattern not found in process space) at address: " address "`n" A_LastError " | " ErrorLevel
    }

    ; The handle must have been opened with the PROCESS_QUERY_INFORMATION access right
    VirtualQueryEx(address, byRef aInfo)
    {
        if !isobject(aInfo)
            aInfo := new this._MEMORY_BASIC_INFORMATION()
        return (aInfo.SizeOf() = DLLCall("VirtualQueryEx" 
                                            , "Ptr", this.hProcess
                                            , "Ptr", address
                                            , "Ptr", aInfo.Ptr()
                                            , "UInt", aInfo.SizeOf() 
                                            , "UInt") )
    }

    class _MEMORY_BASIC_INFORMATION
    {
        __new()
        {   
            ;0x40 is the flag to initialize memory contents to zero.
            if !this.pStructure := DllCall("GlobalAlloc", "UInt", 0x40, "UInt", this.size := A_PtrSize = 4 ? 28 : 48)
                return ""
            return this
        }
        __Delete()
        {
            DllCall("GlobalFree", "Ptr", this.pStructure)
        }
        __get(key)
        {
            static a32bit := {  "BaseAddress": {"Offset": 0, "Type": "UInt"}
                             ,   "AllocationBase": {"Offset": 4, "Type": "UInt"}
                             ,   "AllocationProtect": {"Offset": 8, "Type": "UInt"}
                             ,   "RegionSize": {"Offset": 12, "Type": "UInt"}
                             ,   "State": {"Offset": 16, "Type": "UInt"}
                             ,   "Protect": {"Offset": 20, "Type": "UInt"}
                             ,   "Type": {"Offset": 24, "Type": "UInt"} }
                ; For 64bit the int64 should really be unsigned. But AHK doesn't support these
                ; so this won't work correctly for higher memory address areas
                , a64bit := {   "BaseAddress": {"Offset": 0, "Type": "Int64"}
                            ,    "AllocationBase": {"Offset": 8, "Type": "Int64"}
                            ,    "AllocationProtect": {"Offset": 16, "Type": "UInt"}
                            ,    "RegionSize": {"Offset": 24, "Type": "Int64"}
                            ,    "State": {"Offset": 32, "Type": "UInt"}
                            ,    "Protect": {"Offset": 36, "Type": "UInt"}
                            ,    "Type": {"Offset": 40, "Type": "UInt"} }

            if (A_PtrSize = 4 && a32bit.HasKey(key))
                return numget(this.pStructure+0, a32bit[key].Offset, a32bit[key].Type)
            else if (A_PtrSize = 8 && a64bit.HasKey(key))
                return numget(this.pStructure+0, a64bit[key].Offset, a64bit[key].Type)            
        }
        Ptr()
        {
            return this.pStructure
        }
        sizeOf()
        {
            return this.size
        }
    }

}


/*
32bit
Size: 28

BaseAddress         0   |4
AllocationBase      4   |4
AllocationProtect   8   |4
RegionSize          12  |4
State               16  |4
Protect             20  |4
Type                24  |4

64bit
Size: 48

BaseAddress         0   |8
AllocationBase      8   |8
AllocationProtect   16  |4
__alignment1        20  |4
RegionSize          24  |8
State               32  |4
Protect             36  |4
Type                40  |4
__alignment2        44  |4



    /*
        _MODULEINFO := "
                        (
                          LPVOID lpBaseOfDll;
                          DWORD  SizeOfImage;
                          LPVOID EntryPoint;
                        )"

    */



/*

    ReadRawMemoryTest(address, byref buffer, bytes := 4, byref bytesReadR := 0, aOffsets*)
    {
        VarSetCapacity(buffer, bytes)
        if !DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "UInt", bytes, "Ptr*", bytesRead)
        {
            if !bytesRead
            {
                bytesReadR := bytesRead
                return "Error " DllCall("GetLastError") "`nBytes Read: " bytesRead
            }
        }
        return bytesRead
    }

    ; Return values
    ; -1    An odd number of characters were passed via pattern
    ;       Ensure you use two digits to represent each byte i.e. 05, 0F and ??, and not 5, F or ?
    ; int   represents the number of non-wildcard bytes in the search pattern/needle

    setPattern(pattern, byRef aOffsets, byRef binaryNeedle)
    {
        StringReplace, pattern, pattern, %A_Space%,, All
        StringReplace, pattern, pattern, %A_Tab%,, All
        pattern := RTrim(pattern, "?")              ; can pass patterns beginning with ?? ?? - but it is a little pointless
        loopCount := bufferSize := StrLen(pattern) / 2
        if Mod(StrLen(pattern), 2)
            return -1 
        VarSetCapacity(binaryNeedle, bufferSize)
        aOffsets := [], startGap := 0 ;, prevChar := "??"
        loop, % loopCount
        {
            hexChar := SubStr(pattern, 1 + 2 * (A_Index - 1), 2)
            if (hexChar != "??") && (prevChar = "??" || A_Index = 1)
                binNeedleStartOffset := A_index - 1
            else if (hexChar = "??" && prevChar != "??" && A_Index != 1) 
            {

                aOffsets.Insert({ "binNeedleStartOffset": binNeedleStartOffset
                                , "binNeedleSize": A_Index - 1 - binNeedleStartOffset
                                , "binNeedleGap": !aOffsets.MaxIndex() ? 0 : binNeedleStartOffset - startGap + 1}) ; equals number of wildcard bytes between two sub needles
                startGap := A_index
            }

            if (A_Index = loopCount) ; last char cant be ??
                aOffsets.Insert({ "binNeedleStartOffset": binNeedleStartOffset
                                , "binNeedleSize": A_Index - binNeedleStartOffset
                                , "binNeedleGap": !aOffsets.MaxIndex() ? 0 : binNeedleStartOffset - startGap + 1})

            prevChar := hexChar
            if (hexChar != "??")
            {
                numput("0x" . hexChar, binaryNeedle, A_index - 1, "UChar")
                realNeedleSize++
            }
        }
        return realNeedleSize
    }



    ; This function will only WORK with AHK 32 bit builds!
    ; I'll improve this another time
    ; need to setup module / memory area scanning, so it only reads addresses which have read access
    patternScan(pattern, startAddress, maxOffsetMB := 0, byRef returnAddressAndOffset := 0, dumpSizeMB := 50)
    {
        realNeedleSize := this.setPattern(pattern, aOffsets, binaryNeedle)
        if (realNeedleSize = -1 || realNeedleSize = 0)
            return -2 ;invlaid pattern was passed 
        haystackSizeBytes := dumpSizeMB * 1048576   ;1048576 bytes in a MB
        haystackSizeBytes := 30   ;1048576 bytes in a MB
        maxAddress := startAddress + (maxOffsetMB * 1048576)
        bytesRead := 0

        loop 
        {   
            aaaaindex := A_Index
            currentStartAddress := startAddress + bytesRead ; change this so it starts 1 full needle back from edge
            if (maxOffsetMB && currentStartAddress >= maxAddress)       
                msgbox past final address
            ;   return -1 ; notfound 
            
            if (haystackSizeBytes != bytesRead :=  this.ReadRawMemoryTest(currentStartAddress, Haystack, haystackSizeBytes))
            {
                if !bytesRead
                {
                    return " read failed - Probably reading part an area which cannot be read"
                }
            }
            ;   msgbox % "here currentStartAddress "  chex(currentStartAddress) "`nbytesRead " bytesRead
            ;   return -3 ; failed to dump part of the process memory
            currentStartOffstet := 0
            haystackOffset := 0
            aOffset := aOffsets[arrayIndex := 1]

            loop
            {

                if (-1 != foundOffset := this.scanInBuf(&Haystack, &binaryNeedle + aOffset.binNeedleStartOffset, haystackSizeBytes, aOffset.binNeedleSize, haystackOffset))
                {

                    if (arrayIndex = 1 || foundOffset = haystackOffset)
                    {       
                            
                        if (arrayIndex = 1)
                        {
                            currentStartOffstet := aOffset.binNeedleSize + foundOffset ; save the offset of the match for the first part of the needle - if remainder of needle doesn't match,  resume search from here
                            tmpfoundAddress := foundOffset
                            ;msgbox % "tmpfoundAddress " tmpfoundAddress := foundOffset
                        }
                        if (arrayIndex = aOffsets.MaxIndex())
                        {
                            foundAddress := tmpfoundAddress - aOffsets[1].binNeedleStartOffset ; deduct the first needles starting offset - in case user passed a pattern beginning with ?? eg "?? ?? 00 55"
                            break, 2
                        }   
                        ;msgbox % haystackOffset " haystackOffset" "`ncurrentStartOffstet " currentStartOffstet
                        prevNeedleSize := aOffset.binNeedleSize
                        aOffset := aOffsets[++arrayIndex]
                        ;silly := aOffset.binNeedleGap
                        ;msgbox foundOffset %foundOffset% `nprevNeedleSize %prevNeedleSize%`naOffset.binNeedleGap %silly%
                        haystackOffset := foundOffset + prevNeedleSize + aOffset.binNeedleGap   ; move the start of the haystack ready for the next needle - accounting for previous needle size and any gap/wildcard-bytes between the two needles
                        ;msgbox % haystackOffset " haystackOffset"
                        continue
                    }
                }
                
                if (arrayIndex = 1) ; couldn't find the first part of the needle so dump the next chunk of memory
                {
                    break
                }
                else        ; the subsequent parts of the needle couldn't be found. So resume search from the address immediately next to where the first part of the needle was found
                {   
                    aOffset := aOffsets[arrayIndex := 1]
                    haystackOffset := currentStartOffstet
                }

            }
        }
        if foundAddress
         return 1, returnAddressAndOffset += startAddress + foundAddress
        else return 0
    }

    ;Doesn't WORK with AHK 64 BIT, only works with AHK 32 bit
    ;taken from:
    ;http://www.autohotkey.com/board/topic/23627-machine-code-binary-buffer-searching-regardless-of-null/
    ; -1 not found else returns offset address (starting at 0)
    scanInBuf(haystackAddr, needleAddr, haystackSize, needleSize, StartOffset = 0)
    {  static fun

        ; AHK32Bit a_PtrSize = 4 | AHK64Bit - 8 bytes
        if (a_PtrSize = 8)
          return -1

        ifequal, fun,
        {
          h =
          (  LTrim join
             5589E583EC0C53515256579C8B5D1483FB000F8EC20000008B4D108B451829C129D9410F8E
             B10000008B7D0801C78B750C31C0FCAC4B742A4B742D4B74364B74144B753F93AD93F2AE0F
             858B000000391F75F4EB754EADF2AE757F3947FF75F7EB68F2AE7574EB628A26F2AE756C38
             2775F8EB569366AD93F2AE755E66391F75F7EB474E43AD8975FC89DAC1EB02895DF483E203
             8955F887DF87D187FB87CAF2AE75373947FF75F789FB89CA83C7038B75FC8B4DF485C97404
             F3A775DE8B4DF885C97404F3A675D389DF4F89F82B45089D5F5E5A595BC9C2140031C0F7D0
             EBF0
          )
          varSetCapacity(fun, strLen(h)//2)
          loop % strLen(h)//2
             numPut("0x" . subStr(h, 2*a_index-1, 2), fun, a_index-1, "char")
        }

        return DllCall(&fun, "uInt", haystackAddr, "uInt", needleAddr
                      , "uInt", haystackSize, "uInt", needleSize, "uInt", StartOffset)
    }





    

}
http://www.autohotkey.com/board/topic/73813-which-uint-needs-to-be-ptr-for-64bit-scripts/
*/