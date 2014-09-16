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
    17/08/14
        - Change class name to _ClassMemory


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
        modulePatternScan()
        addressPatternScan()
        processPatternScan()
        rawPatternScan()
    Internal methods: (not as useful)
        pointer()
        getAddressFromOffsets()  
        getModules()
        GetModuleFileNameEx()
        EnumProcessModulesEx()
        GetModuleInformation()
        getNeedleFromAOBPattern()
        VirtualQueryEx()
        patternScan()
        bufferScanForMaskedPattern()      

    Usage:

        **Note: If you wish to try this calc example, ensure you run the 32 bit version of calc.exe - 
                which is in C:\Windows\SysWOW64\calc.exe on 64 bit systems. You can still read/write directly to
                a 64 bit calc process address (I doubt pointers will work), but the getBaseAddressOfModule() example 
                will not work unless the you are using a 64 bit version of ahk (it will return -4 indicating the operation is not possible)

        The contents of this file can be copied directly into your script. Alternately you can copy the classMemory.ahk file into your library folder,
        in which case you will need to use the #include directive in your script i.e. #Include <classMemory>
        You can use this code to check if you have installed the class correctly.
        if (_ClassMemory.__Class != "_ClassMemory")
            msgbox class memory not correctly installed. Or the (global class) variable "_ClassMemory" has been overwritten

        Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
        You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
        Also, if the target process is running as admin, then the script will also require admin rights!
        Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
        hProcessCopy is an optional variable in which the opened handled is stored. 
          
            calc := new _ClassMemory("ahk_exe calc.exe", "", hProcessCopy) 
       
        A couple of ways to check if the above method was successful
            if !isObject(calc)
                msgbox failed to open a handle
            if !hProcessCopy
                msgbox failed to open a handle 

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
            _ClassMemory.insertNullTerminator := False ; This will change the property for all processes
            calc.insertNullTerminator := False ; Changes the property for just this process     


    Notes: 
        If the target process exits and then starts again (or restarts) you will need to free the derived object and then use the new operator to create a new object
        I.e. 
        calc := [] ; or calc := "" ; free the object. This is actually optional if using the line below, as the line below would free the previous derived object calc prior to initialising the new copy.
        calc := new _ClassMemory("ahk_exe calc.exe") ; Create a new derived object to read calcs memory.
*/

class _ClassMemory
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

    ; Method:    __new(program, dwDesiredAccess := "", byRef handle := "", windowMatchMode := 3)
    ; Example:  derivedObject := new _ClassMemory("ahk_exe calc.exe")
    ;           This is the first method which should be called when trying to access a program's memory. 
    ;           If the process is successfully opened, an object is returned which can be used to read that processes memory space.
    ;           [derivedObject].hProcess stores the opened handle.
    ;           If the target process closes and re-opens, simply free the derived object and use the new operator again to open a new handle.
    ; Parameters:
    ;   program             The program to be opened. This can be any AHK windowTitle identifier, such as 
    ;                       ahk_exe, ahk_class, ahk_pid, or simply the window title. e.g. "ahk_exe SC2.exe" or "Starcraft II".
    ;                       It's safer not to use the window title, as some things can have the same window title e.g. an open folder called "Starcraft II"
    ;                       would have the same window title as the game itself.
    ;   dwDesiredAccess     The access rights requested when opening the process.
    ;                       If this parameter is null the process will be opened with the following rights
    ;                       PROCESS_QUERY_INFORMATION, PROCESS_VM_OPERATION, PROCESS_VM_READ, PROCESS_VM_WRITE
    ;                       This access level is sufficient to allow all of the methods in this class to work.
    ;                       Specific process access rights are listed here http://msdn.microsoft.com/en-us/library/windows/desktop/ms684880(v=vs.85).aspx                           
    ;   handle (Output)     Optional variable in which a copy of the opened processes handle will be stored.
    ;                       Values:
    ;                           Null    OpenProcess failed. If the target process has admin rights, then the script also needs to be ran as admin. Consult A_LastError for more information.
    ;                           0       The program isn't running (not found) or you passed an incorrect program identifier parameter. 
    ;                           Positive Integer    A handle to the process. (Success)
    ;   windowMatchMode -   Determines the matching mode used when finding the program (windowTitle).
    ;                       The default value is 3 i.e. an exact match. Refer to AHK's setTitleMathMode for more information.
    ; Return Values: 
    ;   Object  On success an object is returned which can be used to read the processes memory.
    ;   Null    Failure. A_LastError and the optional handle parameter can be consulted for more information. 


    __new(program, dwDesiredAccess := "", byRef handle := "", windowMatchMode := 3)
    {
        if !(handle := this.openProcess(program, dwDesiredAccess, windowMatchMode))
            return ""
        this.readStringLastError := False
        this.BaseAddress := this.getProcessBaseAddress(program, windowMatchMode)
        return this
    }
    ; Called when the derived object is freed.
    __delete()
    {
        this.closeProcess(this.hProcess)
        return
    }

    version()
    {
        return 1.2
    }

    ; Method:   openProcess(program, dwDesiredAccess := "", windowMatchMode := 3)
    ;           Opens a handle to the target program. This handle is required by the other methods.
    ;           The handle is stored in [derivedObject].hProcess
    ;           ***Note: There is no reason to call this method directly. Instead you should use the new operator to open handles
    ;           to new programs, or if the target process closes and re-opens, simply free the derived object and use the new operator again.
    ; Parameters:
    ;   program             The program to be opened. This can be any AHK windowTitle identifier, such as 
    ;                       ahk_exe, ahk_class, ahk_pid, or simply the window title. e.g. "ahk_exe SC2.exe" or "Starcraft II"
    ;                       its safer not to use the window title, as some things can have the same window title - e.g. an open folder called "Starcraft II"
    ;                       would have the same window title as the game itself.
    ;                       the base address of the pointer.
    ;   dwDesiredAccess     The access rights requested when opening the process.
    ;                       If this parameter is null the process will be opened with the following rights
    ;                       PROCESS_QUERY_INFORMATION, PROCESS_VM_OPERATION, PROCESS_VM_READ, PROCESS_VM_WRITE
    ;                       This access level is sufficient to allow all of the methods in this class to work.
    ;                       Specific process access rights are listed here http://msdn.microsoft.com/en-us/library/windows/desktop/ms684880(v=vs.85).aspx                           
    ;   windowMatchMode     Determines the matching mode used when finding the program (windowTitle).
    ;                       The default value is 3 i.e. an exact match. Refer to AHK's setTitleMathMode for more information.
    ; Return Values: 
    ;   0                   The program isn't running or you passed an incorrect program identifier parameter
    ;   Null/blank          OpenProcess failed. If the target process has admin rights, then the script also needs to be ran as admin.
    ;   Positive integer    A handle to the process.

    openProcess(program, dwDesiredAccess := "", windowMatchMode := 3)
    {
        ; if an application closes/restarts the previous handle becomes invalid so reopen it to be safe (closing a now invalid handle is fine i.e. wont cause an issue)
        
        ; This default access level is sufficient to read and write memory addresses.
        ; if the program is run using admin privileges, then this script will also need admin privileges
        if dwDesiredAccess is not integer
            dwDesiredAccess := (PROCESS_QUERY_INFORMATION := 0x0400) | (PROCESS_VM_OPERATION := 0x8) | (PROCESS_VM_READ := 0x10) | (PROCESS_VM_WRITE := 0x20)
        if windowMatchMode
        {
            ; This is a string and will not contain the 0x prefix
            mode :=  A_TitleMatchMode
            ; remove hex prefix as SetTitleMatchMode will throw a run time error. This will occur if integer mode is set to hex.
            StringReplace, windowMatchMode, windowMatchMode, 0x 
            SetTitleMatchMode, %windowMatchMode%
        }
        WinGet, pid, pid, % this.currentProgram := program
        if windowMatchMode
            SetTitleMatchMode, %mode%    ; In case executed in autoexec
        if !pid
            return this.hProcess := 0 
        ; method directly called close handle if already open.
        if this.hProcess  
            this.closeProcess(this.hProcess)
        return this.hProcess := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", pid) ; NULL/Blank if failed to open process for some reason
    }   

    ; When the script exits or the derived object is freed/destroyed any open handles will automatically be closed!
    ; That is, you don't need to call this function.
    closeProcess(hProcess := "")
    {
        ; method called directly and no handle was passed, so assume they mean to close the current handle
        if (hProcess = "")
            hProcess := this.hProcess, this.hProcess := ""
        ; hProcess is this objects hProcess, so blank it.
        ; Probably should only blank it when closeHandle returns success, but if hProcess is valid it shouldn't fail
        ; closeHandle will return success even if the program is no longer running
        else if (hProcess = this.hProcess)
            this.hProcess := ""
        ; if there was an error when opening handle, handle will be null
        if hProcess
            return DllCall("CloseHandle", "UInt", hProcess)
        return ; null returned 
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
            {   ; I could save a few reads here by always reading in 4 byte chunks, and then looping through the 4 byte chunks in charType sizes checking for null.
                if (!DllCall("ReadProcessMemory", "UInt", this.hProcess, "UInt", address + (A_index - 1) * encodingSize, "Ptr", &buffer, "Uint", encodingSize, "Ptr", 0) 
                || ErrorLevel)
                    return "", this.ReadStringLastError := True ;this.hProcess ? "Fail" : "Handle Is closed: " this.hProcess
                else if (0 = NumGet(buffer, 0, charType)) ; NULL terminator
                {
                    if (bufferSize < sizeBytes := A_Index * encodingSize) 
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
    ;       If this property is true, then a null terminator will be included.       

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
            if offsets.maxIndex() = 1
                pointer := offset + this.Read(base)
            Else If (A_Index = 1) 
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
    ; Return Values:    The same as the pointer() method

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

    ; The base address for some programs is dynamic. This can retrieve the current base address of the main module (e.g. calc.exe), 
    ; which can then be added to your various offsets.  
    ; This function will return the correct address regardless of the 
    ; bitness (32 or 64 bit) of both the AHK exe and the target process.

    ; WindowTitle can be anything ahk_exe ahk_class etc
    getProcessBaseAddress(WindowTitle, windowMatchMode := 3)   
    {
        if windowMatchMode
        {
            ; This is a string and will not contain the 0x prefix
            mode := A_TitleMatchMode
            ; remove hex prefix as SetTitleMatchMode will throw a run time error. This will occur if integer mode is set to hex.
            StringReplace, windowMatchMode, windowMatchMode, 0x
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

    getModules(byRef aModules)
    {
        if !this.hProcess
            return -2
        if (A_PtrSize = 4)
        {
            DllCall("IsWow64Process", "Ptr", this.hProcess, "Int*", result)
            if !result 
                return -4 ; AHK is 32bit and target process is 64 bit, this function wont work
        }      
        aModules := []
        if !moduleCount := this.EnumProcessModulesEx(lphModule)
            return -3  
        loop % moduleCount
        {
            this.GetModuleInformation(hModule := numget(lphModule, (A_index - 1) * A_PtrSize), aModuleInfo)
            aModuleInfo.Name := this.GetModuleFileNameEx(hModule)
            aModules.insert(aModuleInfo)
        }
        return round(aModules.MaxIndex())        
    }

    getEndAddressOfLastModule(byRef aModuleInfo := "")
    {
        if !moduleCount := this.EnumProcessModulesEx(lphModule)
            return -3     
        hModule := numget(lphModule, (moduleCount - 1) * A_PtrSize)
        if this.GetModuleInformation(hModule, aModuleInfo)
            return aModuleInfo.lpBaseOfDll + aModuleInfo.SizeOfImage
        return -5
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
 
    ; Method:           modulePatternScan(module := "", aAOBPattern*)
    ;                   Scans the specified module for the specified array of bytes    
    ; Parameters:
    ;   module -        The file name of the module/dll to search e.g. "GDI32.dll", "Battle.net.dll" etc
    ;                   If no module (null) is specified, the executable file of the process will be used. 
    ;                   e.g. C:\Games\StarCraft II\Versions\Base28667\SC2.exe
    ;   aAOBPattern* -  A variadic list of byte values i.e. the array of bytes to find.
    ;                   Wild card bytes should be indicated by using a single '?'.
    ; Return Values:
    ;   Null            Failed to find or retrieve the specified module. ErrorLevel is set to the returned error from getBaseAddressOfModule()
    ;                   refer to that method for more information.
    ;   0               The pattern was not found inside the module
    ;   -9              VirtualQueryEx() failed
    ;   -10             The aAOBPattern* is invalid. No bytes were passed                   

    modulePatternScan(module := "", aAOBPattern*)
    {
        MEM_COMMIT := 0x1000, MEM_MAPPED := 0x40000, MEM_PRIVATE := 0x20000
        , PAGE_NOACCESS := 0x01, PAGE_GUARD := 0x100

        if (result := this.getBaseAddressOfModule(module, aModuleInfo)) > 0 
        {
            if !patternSize := this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
                return -10 ;no pattern
            ; Try to read the entire module in one RPM()
            ; If fails with access (-1) iterate the modules memory pages and search the ones which are readable          
            if (result := this.PatternScan(aModuleInfo.lpBaseOfDll, aModuleInfo.SizeOfImage, patternMask, AOBBuffer)) > 0
                return result  ; Found
            else if (result = 0) ; 0 = not found
                return 0 
            ; else RPM() failed lets iterate the pages
            address := aModuleInfo.lpBaseOfDll
            endAddress := address + aModuleInfo.SizeOfImage
            loop 
            {
                if !this.VirtualQueryEx(address, aRegion)
                    return -9
                if (aRegion.State = MEM_COMMIT 
                && !(aRegion.Protect & PAGE_NOACCESS) ; can't read this area
                && !(aRegion.Protect & PAGE_GUARD) ; can't read this area
                ;&& (aRegion.Type = MEM_MAPPED || aRegion.Type = MEM_PRIVATE) ;Might as well read Image sections as well
                && aRegion.RegionSize >= patternSize)
                {
                    if (result := this.PatternScan(address, aRegion.RegionSize, patternMask, AOBBuffer)) > 0
                        return result
                }
                if (address += aRegion.RegionSize) >= endAddress
                    return 0
            }
        }
        return "", ErrorLevel := result ; failed
    }

    ; Method:               addressPatternScan(startAddress, sizeOfRegionBytes, aAOBPattern*)
    ;                       Scans a specified memory region for an array of bytes pattern.
    ; Parameters:
    ;   startAddress -      The memory address from which to begin the search.
    ;   sizeOfRegionBytes - The numbers of bytes to scan in the memory region.
    ;   aAOBPattern* -      A variadic list of byte values i.e. the array of bytes to find.
    ;                       Wild card bytes should be indicated by using a single '?'.      
    ; Return Values:
    ;   Positive integer    Success. The memory address of the found pattern.
    ;   0                   Pattern not found
    ;   -1                  Failed to read the memory region.
    ;   -10                 An aAOBPattern pattern. No bytes were passed.

    addressPatternScan(startAddress, sizeOfRegionBytes, aAOBPattern*)
    {
        if !this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
            return -10
        return this.PatternScan(startAddress, sizeOfRegionBytes, patternMask, AOBBuffer)   
    }
   
    ; Method:       processPatternScan(aAOBPattern*)
    ;               Scan the memory space of the current process for an array of bytes pattern.  
    ; Parameters:
    ;   startAddress -      The memory address from which to begin the search.
    ;   aAOBPattern* -      A variadic list of byte values i.e. the array of bytes to find.
    ;                       Wild card bytes should be indicated by using a single '?'.
    ; Return Values:
    ;   Positive integer -  Success. The memory address of the found pattern.
    ;   0                   The pattern doesn't exist or possibly VirtualQueryEx() failed while iterating a memory region.
    ;   -1                  VirtualQueryEx() failed to start.
    ;   -2                  Failed to read a memory region.
    ;   -10                 The aAOBPattern* is invalid. (No bytes were passed)

    processPatternScan(startAddress := 0, aAOBPattern*)
    {
        address := startAddress
        MEM_COMMIT := 0x1000       
        MEM_MAPPED := 0x40000
        MEM_PRIVATE := 0x20000
        PAGE_NOACCESS := 0x01
        PAGE_GUARD := 0x100
        if !patternSize := this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
            return -10
        ; >= 0x7FFFFFFF - definitely reached the end of the useful area (at least for a 32 target process)
        while address < 0x7FFFFFFF && this.VirtualQueryEx(address, aInfo)
        {
            if (aInfo.State = MEM_COMMIT) 
            && !(aInfo.Protect & PAGE_NOACCESS) ; can't read this area
            && !(aInfo.Protect & PAGE_GUARD) ; can't read this area
            ;&& (aInfo.Type = MEM_MAPPED || aInfo.Type = MEM_PRIVATE) ;Might as well read Image sections as well
            && aInfo.RegionSize >= patternSize
            {
                if !result := this.PatternScan(address, aInfo.RegionSize, patternMask, AOBBuffer)
                    address += aInfo.RegionSize
                else if result > 0
                    return result ; address of the pattern
                else ; -2 error
                    return result ;"Pattern.Scan() failed at address: " address "`n" A_LastError " | " ErrorLevel
            }
            else address += aInfo.RegionSize
        }
        ; Is there a ways to find the process maximum address? So can differentiate a not found from an error
        ; Finding the last module and doing moduleAddres+moduleSize will still leave pages unscanned. I don't know if this area would be
        ; use to anyone.

        ; If address is non zero assume all pages were iterated. Although I believe it's still possible for this to error out 
        ; during the loop of a non-frozen process (one of the reasons why snapshot32 is better?)
        ; Else there was an issue with VirtualQueryEx
        return address ? 0 : -1 ; "VirtualQueryEx() failed (or pattern not found in process space) at address: " address "`n" A_LastError " | " ErrorLevel
    }

    ; Method:           rawPatternScan(byRef buffer, sizeOfBufferBytes := "", aAOBPattern*)   
    ;                   Scans a binary buffer for an array of bytes pattern. 
    ;                   This is useful if you have already dumped a region of memory via readRawMemory()
    ; Parameters:
    ;   buffer              The binary buffer to be searched.
    ;   sizeOfBufferBytes   The size of the binary buffer. If null or 0 the size is automatically retrieved.
    ;   startOffset         The offset from the start off the buffer from which to begin the search. This must be >= 0.
    ;   aAOBPattern*        A variadic list of byte values i.e. the array of bytes to find.
    ;                       Wild card bytes should be indicated by using a single '?'. 
    ; Return Values:
    ;   >= 0                The offset of the pattern relative to the start of the haystack.
    ;   -1                  Not found.
    ;   -2                  Parameter incorrect.

    rawPatternScan(byRef buffer, sizeOfBufferBytes := "", startOffset := 0, aAOBPattern*)
    {
        if !this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
            return -10
        if sizeOfBufferBytes is not integer
            sizeOfBufferBytes := VarSetCapacity(buffer)
        else if sizeOfBufferBytes <= 0
            sizeOfBufferBytes := VarSetCapacity(buffer)
        if startOffset is not Integer
            startOffset := 0
        else if startOffset < 0
            startOffset := 0
        return this.bufferScanForMaskedPattern(&buffer, sizeOfBufferBytes, patternMask, &AOBBuffer, startOffset)           
    }

    ; Method:           getNeedleFromAOBPattern(byRef patternMask, byRef needleBuffer, aAOBPattern*)
    ;                   Converts an array of bytes pattern (aAOBPattern*) into a binary needle and pattern mask string
    ;                   which are compatible with patternScan() and bufferScanForMaskedPattern().
    ;                   The modulePatternScan(), addressPatternScan(), rawPatternScan(), and processPatternScan() methods
    ;                   allow you to directly search for an array of bytes pattern in a single method call.
    ; Parameters:
    ;   patternMask -   (output) A string which indicates which bytes are wild/no-wild.
    ;   needleBuffer -  (output) The array of bytes passed via aAOBPattern* is converted to a binary needle and stored inside this variable.
    ;   aAOBPattern* -  (input) A variadic list of byte values i.e. the array of bytes from which to create the patternMask and needleBuffer.
    ;                   Wild card bytes should be indicated by using a single '?'.
    ; Return Values:
    ;  The number of bytes in the binary needle and hence the number of characters in the patternMask string. 

    getNeedleFromAOBPattern(byRef patternMask, byRef needleBuffer, aAOBPattern*)
    {
        patternMask := "", VarSetCapacity(needleBuffer, aAOBPattern.MaxIndex())
        for i, v in aAOBPattern
            patternMask .= (v = "?" ? "?" : "x"), NumPut(round(v), needleBuffer, A_Index - 1, "UChar")
        return round(aAOBPattern.MaxIndex())
    }

    ; The handle must have been opened with the PROCESS_QUERY_INFORMATION access right
    VirtualQueryEx(address, byRef aInfo)
    {
        if (aInfo.__Class != "memory._MEMORY_BASIC_INFORMATION")
            aInfo := new this._MEMORY_BASIC_INFORMATION()
        return aInfo.SizeOfStructure = DLLCall("VirtualQueryEx" 
                                                , "Ptr", this.hProcess
                                                , "Ptr", address
                                                , "Ptr", aInfo.pStructure
                                                , "UInt", aInfo.SizeOfStructure
                                                , "UInt") 
    }

    ; Scans a specified memory region for a pattern
    ; Has been replaced with a (much faster) machine code function
    /*
    AHKPatternScan(startAddress, sizeOfRegionBytes, aAOBPattern*)
    {
        if aPattern.MaxIndex() > sizeOfRegionBytes
            return -1
        if !this.ReadRawMemory(startAddress, buffer, sizeOfRegionBytes)
            return -2
        while (i := A_Index - 1) <= sizeOfRegionBytes - aAOBPattern.MaxIndex() 
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
    // The c++ function used to generate the machine code
    int scan(unsigned char* haystack, unsigned int haystackSize, unsigned char* needle, unsigned int needleSize, char* patternMask, unsigned int startOffset)
    {
        for (unsigned int i = startOffset; i <= haystackSize - needleSize; i++)
        {
            for (unsigned int j = 0; needle[j] == haystack[i + j] || patternMask[j] == '?'; j++)
            {
                if (j + 1 == needleSize)
                    return i;
            }
        }
        return -1;
    }
    */

    ; Method:               PatternScan(startAddress, sizeOfRegionBytes, patternMask, byRef needleBuffer)
    ;                       Scans a specified memory region for a binary needle pattern using a machine code function
    ;                       If found it returns the memory address of the needle in the processes memory.
    ; Parameters:
    ;   startAddress -      The memory address from which to begin the search.
    ;   sizeOfRegionBytes - The numbers of bytes to scan in the memory region.
    ;   patternMask -       This string indicates which bytes must match and which bytes are wild. Each wildcard byte must be denoted by a single '?'. 
    ;                       Non wildcards can use any other single character e.g 'x'. There should be no spaces.
    ;                       With the patternMask 'xx??x', the frist, second, and fith bytes must match. The third and fourth bytes are wild.
    ;    needleBuffer -     The variable which contains the binary needle. This needle should consist of UChar bytes.
    ; Return Values:
    ;   Positive integer    The address of the pattern.
    ;   0                   Pattern not found.
    ;   -1                  Failed to read the region.

    patternScan(startAddress, sizeOfRegionBytes, byRef patternMask, byRef needleBuffer)
    {
        if !this.ReadRawMemory(startAddress, buffer, sizeOfRegionBytes)
            return -1      
        if (offset := this.bufferScanForMaskedPattern(&buffer, sizeOfRegionBytes, patternMask, &needleBuffer)) >= 0
            return startAddress + offset 
        else return 0
    }
    ; Method:               bufferScanForMaskedPattern(byRef hayStack, sizeOfHayStackBytes, byRef patternMask, byRef needle)
    ;                       Scans a binary haystack for binary needle against a pattern mask string using a machine code function.
    ; Parameters:
    ;   hayStackAddress -   The address of the binary haystack which is to be searched.
    ;   sizeOfHayStackBytes The total size of the haystack in bytes.
    ;   patternMask -       A string which indicates which bytes must match and which bytes are wild. Each wildcard byte must be denoted by a single '?'. 
    ;                       Non wildcards can use any other single character e.g 'x'. There should be no spaces.
    ;                       With the patternMask 'xx??x', the frist, second, and fith bytes must match. The third and fourth bytes are wild.
    ;   needleAddress -     The address of the binary needle to find. This needle should consist of UChar bytes.
    ;   startOffset -       The offset from the start off the haystack from which to begin the search. This must be >= 0.
    ; Return Values:    
    ;   >= 0                Found. The pattern begins at this offset - relative to the start of the haystack.
    ;   -1                  Not found.
    ;   -2                  Invalid sizeOfHayStackBytes parameter - Must be > 0.

    ; Notes:
    ;       This is a basic function with few safeguards. Incorrect parameters may crash the script.

    bufferScanForMaskedPattern(hayStackAddress, sizeOfHayStackBytes, byRef patternMask, needleAddress, startOffset := 0)
    {
        static p
        if !p
        {
            if A_PtrSize = 4    
                p := this.MCode("1,x86:8B44240853558B6C24182BC5568B74242489442414573BF0773E8B7C241CBB010000008B4424242BF82BD8EB038D49008B54241403D68A0C073A0A740580383F750B8D0C033BCD74174240EBE98B442424463B74241876D85F5E5D83C8FF5BC35F8BC65E5D5BC3")
            else 
                p := this.MCode("1,x64:48895C2408488974241048897C2418448B5424308BF2498BD8412BF1488BF9443BD6774A4C8B5C24280F1F800000000033C90F1F400066660F1F840000000000448BC18D4101418D4AFF03C80FB60C3941380C18740743803C183F7509413BC1741F8BC8EBDA41FFC2443BD676C283C8FF488B5C2408488B742410488B7C2418C3488B5C2408488B742410488B7C2418418BC2C3")
        }
        if (needleSize := StrLen(patternMask)) + startOffset > sizeOfHayStackBytes
            return -1 ; needle can't exist inside this region. And basic check to prevent wrap around error of the UInts in the machine function       
        if (sizeOfHayStackBytes > 0)
            return DllCall(p, "Ptr", hayStackAddress, "UInt", sizeOfHayStackBytes, "Ptr", needleAddress, "UInt", needleSize, "AStr", patternMask, "UInt", startOffset, "cdecl int")
        return -2
    }

    ; Notes: 
    ; Other alternatives for non-wildcard buffer comparison.
    ; Use memchr to find the first byte, then memcmp to compare the remainder of the buffer against the needle and loop if it doesn't match
    ; The function FindMagic() by Lexikos uses this method.
    ; Use scanInBuf() machine code function - but this only supports 32 bit ahk. I could check if needle contains wild card and AHK is 32bit,
    ; then call this function. But need to do a speed comparison to see the benefits, but this should be faster. Although the benefits for 
    ; the size of the memory regions be dumped would most likely be inconsequential as it's already extremely fast.

    MCode(mcode)
    {
        static e := {1:4, 2:1}, c := (A_PtrSize=8) ? "x64" : "x86"
        if !regexmatch(mcode, "^([0-9]+),(" c ":|.*?," c ":)([^,]+)", m)
            return
        if !DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", 0, "uint*", s, "ptr", 0, "ptr", 0)
            return
        p := DllCall("GlobalAlloc", "uint", 0, "ptr", s, "ptr")
        if (c="x64")
            DllCall("VirtualProtect", "ptr", p, "ptr", s, "uint", 0x40, "uint*", op)
        if DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", p, "uint*", s, "ptr", 0, "ptr", 0)
            return p
        DllCall("GlobalFree", "ptr", p)
        return
    }
    class _MEMORY_BASIC_INFORMATION
    {
        __new()
        {   
            if !this.pStructure := DllCall("GlobalAlloc", "UInt", 0, "UInt", this.SizeOfStructure := A_PtrSize = 4 ? 28 : 48, "Ptr")
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
            return this.SizeOfStructure
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
    VirtualQueryEx(address, byRef aInfo)
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

        VarSetCapacity(memInfo, memInfoSize :=  A_PtrSize = 4 ? 28 : 48)
        if (memInfoSize = DLLCall("VirtualQueryEx", "Ptr", this.hProcess, "Ptr", address, "Ptr", &memInfo, "UInt", memInfoSize, "UInt"))
        {
            for field, info in A_PtrSize = 4 ? a32bit : a64bit, aInfo := []
                aInfo[field] := NumGet(memInfo, info.Offset, info.Type)
            return True
        }
        return False
    }


    /*
        _MODULEINFO := "
                        (
                          LPVOID lpBaseOfDll;
                          DWORD  SizeOfImage;
                          LPVOID EntryPoint;
                        )"

    */



/*

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