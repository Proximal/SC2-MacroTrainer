; <COMPILER: v1.1.15.00>
#NoEnv
#NoTrayIcon
#SingleInstance Off
PreprocessScript(ByRef ScriptText, AhkScript, ExtraFiles, FileList="", FirstScriptDir="", Options="", iOption=0)
{
SplitPath, AhkScript, ScriptName, ScriptDir
if !IsObject(FileList)
{
FileList := [AhkScript]
ScriptText := "; <COMPILER: v" A_AhkVersion ">`n"
FirstScriptDir := ScriptDir
IsFirstScript := true
Options := { comm: ";", esc: "``" }
OldWorkingDir := A_WorkingDir
SetWorkingDir, %ScriptDir%
}
IfNotExist, %AhkScript%
if !iOption
Util_Error((IsFirstScript ? "Script" : "#include") " file """ AhkScript """ cannot be opened.")
else return
cmtBlock := false, contSection := false
Loop, Read, %AhkScript%
{
tline := Trim(A_LoopReadLine)
if !cmtBlock
{
if !contSection
{
if StrStartsWith(tline, Options.comm)
continue
else if tline =
continue
else if StrStartsWith(tline, "/*")
{
cmtBlock := true
continue
}
}
if StrStartsWith(tline, "(")
contSection := true
else if StrStartsWith(tline, ")")
contSection := false
tline := RegExReplace(tline, "\s+" RegExEscape(Options.comm) ".*$", "")
if !contSection && RegExMatch(tline, "i)#Include(Again)?[ \t]*[, \t]?\s+(.*)$", o)
{
IsIncludeAgain := (o1 = "Again")
IgnoreErrors := false
IncludeFile := o2
if RegExMatch(IncludeFile, "\*[iI]\s+?(.*)", o)
IgnoreErrors := true, IncludeFile := Trim(o1)
if RegExMatch(IncludeFile, "^<(.+)>$", o)
{
if IncFile2 := FindLibraryFile(o1, FirstScriptDir)
{
IncludeFile := IncFile2
goto _skip_findfile
}
}
StringReplace, IncludeFile, IncludeFile, `%A_ScriptDir`%, %FirstScriptDir%, All
StringReplace, IncludeFile, IncludeFile, `%A_AppData`%, %A_AppData%, All
StringReplace, IncludeFile, IncludeFile, `%A_AppDataCommon`%, %A_AppDataCommon%, All
if FileExist(IncludeFile) = "D"
{
SetWorkingDir, %IncludeFile%
continue
}
_skip_findfile:
IncludeFile := Util_GetFullPath(IncludeFile)
AlreadyIncluded := false
for k,v in FileList
if (v = IncludeFile)
{
AlreadyIncluded := true
break
}
if(IsIncludeAgain || !AlreadyIncluded)
{
if !AlreadyIncluded
FileList._Insert(IncludeFile)
PreprocessScript(ScriptText, IncludeFile, ExtraFiles, FileList, FirstScriptDir, Options, IgnoreErrors)
}
}else if !contSection && RegExMatch(tline, "i)^FileInstall[ \t]*[, \t][ \t]*([^,]+?)[ \t]*,", o)
{
if o1 ~= "[^``]%"
Util_Error("Error: Invalid ""FileInstall"" syntax found. ")
_ := Options.esc
StringReplace, o1, o1, %_%`%, `%, All
StringReplace, o1, o1, %_%`,, `,, All
StringReplace, o1, o1, %_%%_%,, %_%,, All
ExtraFiles._Insert(o1)
ScriptText .= tline "`n"
}else if !contSection && RegExMatch(tline, "i)^#CommentFlag\s+(.+)$", o)
Options.comm := o1, ScriptText .= tline "`n"
else if !contSection && RegExMatch(tline, "i)^#EscapeChar\s+(.+)$", o)
Options.esc := o1, ScriptText .= tline "`n"
else if !contSection && RegExMatch(tline, "i)^#DerefChar\s+(.+)$", o)
Util_Error("Error: #DerefChar is not supported.")
else if !contSection && RegExMatch(tline, "i)^#Delimiter\s+(.+)$", o)
Util_Error("Error: #Delimiter is not supported.")
else
ScriptText .= (contSection ? A_LoopReadLine : tline) "`n"
}else if StrStartsWith(tline, "*/")
cmtBlock := false
}
if IsFirstScript
{
Util_Status("Auto-including any functions called from a library...")
ilibfile = %A_Temp%\_ilib.ahk
FileDelete, %ilibfile%
static AhkPath := A_IsCompiled ? A_ScriptDir "\..\AutoHotkey.exe" : A_AhkPath
RunWait, "%AhkPath%" /iLib "%ilibfile%" "%AhkScript%", %FirstScriptDir%, UseErrorLevel
IfExist, %ilibfile%
PreprocessScript(ScriptText, ilibfile, ExtraFiles, FileList, FirstScriptDir, Options)
FileDelete, %ilibfile%
StringTrimRight, ScriptText, ScriptText, 1
}
if OldWorkingDir
SetWorkingDir, %OldWorkingDir%
}
FindLibraryFile(name, ScriptDir)
{
libs := [ScriptDir "\Lib", A_MyDocuments "\AutoHotkey\Lib", A_ScriptDir "\..\Lib", SubStr(A_AhkPath,1,InStr(A_AhkPath,"\",1,0)) "Lib",A_ScriptDir "\..\..\Lib"]
p := InStr(name, "_")
if p
name_lib := SubStr(name, 1, p-1)
for each,lib in libs
{
file := lib "\" name ".ahk"
IfExist, %file%
return file
if !p
continue
file := lib "\" name_lib ".ahk"
IfExist, %file%
return file
}
}
StrStartsWith(ByRef v, ByRef w)
{
return SubStr(v, 1, StrLen(w)) = w
}
RegExEscape(t)
{
static _ := "\.*?+[{|()^$"
Loop, Parse, _
StringReplace, t, t, %A_LoopField%, \%A_LoopField%, All
return t
}
ReplaceAhkIcon(re, IcoFile, ExeFile)
{
global _EI_HighestIconID
static iconID := 159
ids := EnumIcons(ExeFile, iconID)
if !IsObject(ids)
return false
f := FileOpen(IcoFile, "r")
if !IsObject(f)
return false
VarSetCapacity(igh, 8), f.RawRead(igh, 6)
if NumGet(igh, 0, "UShort") != 0 || NumGet(igh, 2, "UShort") != 1
return false
wCount := NumGet(igh, 4, "UShort")
VarSetCapacity(rsrcIconGroup, rsrcIconGroupSize := 6 + wCount*14)
NumPut(NumGet(igh, "Int64"), rsrcIconGroup, "Int64")
ige := &rsrcIconGroup + 6
Loop, % ids._MaxIndex()
DllCall("UpdateResource", "ptr", re, "ptr", 3, "ptr", ids[A_Index], "ushort", 0x409, "ptr", 0, "uint", 0, "uint")
Loop, %wCount%
{
thisID := ids[A_Index]
if !thisID
thisID := ++ _EI_HighestIconID
f.RawRead(ige+0, 12)
NumPut(thisID, ige+12, "UShort")
imgOffset := f.ReadUInt()
oldPos := f.Pos
f.Pos := imgOffset
VarSetCapacity(iconData, iconDataSize := NumGet(ige+8, "UInt"))
f.RawRead(iconData, iconDataSize)
f.Pos := oldPos
DllCall("UpdateResource", "ptr", re, "ptr", 3, "ptr", thisID, "ushort", 0x409, "ptr", &iconData, "uint", iconDataSize, "uint")
ige += 14
}
DllCall("UpdateResource", "ptr", re, "ptr", 14, "ptr", iconID, "ushort", 0x409, "ptr", &rsrcIconGroup, "uint", rsrcIconGroupSize, "uint")
return true
}
EnumIcons(ExeFile, iconID)
{
global _EI_HighestIconID
static pEnumFunc := RegisterCallback("EnumIcons_Enum")
hModule := DllCall("LoadLibraryEx", "str", ExeFile, "ptr", 0, "ptr", 2, "ptr")
if !hModule
return
_EI_HighestIconID := 0
if DllCall("EnumResourceNames", "ptr", hModule, "ptr", 3, "ptr", pEnumFunc, "uint", 0) = 0
{
DllCall("FreeLibrary", "ptr", hModule)
return
}
hRsrc := DllCall("FindResource", "ptr", hModule, "ptr", iconID, "ptr", 14, "ptr")
hMem := DllCall("LoadResource", "ptr", hModule, "ptr", hRsrc, "ptr")
pDirHeader := DllCall("LockResource", "ptr", hMem, "ptr")
pResDir := pDirHeader + 6
wCount := NumGet(pDirHeader+4, "UShort")
iconIDs := []
Loop, %wCount%
{
pResDirEntry := pResDir + (A_Index-1)*14
iconIDs[A_Index] := NumGet(pResDirEntry+12, "UShort")
}
DllCall("FreeLibrary", "ptr", hModule)
return iconIDs
}
EnumIcons_Enum(hModule, type, name, lParam)
{
global _EI_HighestIconID
if (name < 0x10000) && name > _EI_HighestIconID
_EI_HighestIconID := name
return 1
}
AhkCompile(ByRef AhkFile, ExeFile="", ByRef CustomIcon="", BinFile="", UseMPRESS="", UseCompression="")
{
global ExeFileTmp
AhkFile := Util_GetFullPath(AhkFile)
if AhkFile =
Util_Error("Error: Source file not specified.")
SplitPath, AhkFile,, AhkFile_Dir,, AhkFile_NameNoExt
if ExeFile =
ExeFile = %AhkFile_Dir%\%AhkFile_NameNoExt%.exe
else
ExeFile := Util_GetFullPath(ExeFile)
ExeFileTmp := ExeFile
if BinFile =
BinFile = %A_ScriptDir%\AutoHotkeySC.bin
Util_DisplayHourglass()
FileCopy, %BinFile%, %ExeFile%, 1
if ErrorLevel
Util_Error("Error: Unable to copy AutoHotkeySC binary file to destination.")
BundleAhkScript(ExeFile, AhkFile, CustomIcon,UseCompression)
if FileExist(A_ScriptDir "\mpress.exe") && UseMPRESS
{
Util_Status("Compressing final executable...")
RunWait, "%A_ScriptDir%\mpress.exe" -q -x "%ExeFile%",, Hide
}
Util_HideHourglass()
Util_Status("")
}
BundleAhkScript(ExeFile, AhkFile, IcoFile="", UseCompression="")
{
SplitPath, AhkFile,, ScriptDir
ExtraFiles := []
PreprocessScript(ScriptBody, AhkFile, ExtraFiles)
ScriptBody :=Trim(ScriptBody,"`n")
If UseCompression {
VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
StrPut(ScriptBody, &BinScriptBody, "UTF-8")
If !BinScriptBody_Len:=VarZ_Compress(BinScriptBody,StrPut(ScriptBody, "UTF-8")+2,0x102){
VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
StrPut(ScriptBody, &BinScriptBody, "UTF-8")
}
} else {
VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
StrPut(ScriptBody, &BinScriptBody, "UTF-8")
}
module := DllCall("BeginUpdateResource", "str", ExeFile, "uint", 0, "ptr")
if !module
Util_Error("Error: Error opening the destination file.")
if IcoFile
{
Util_Status("Changing the main icon...")
if !ReplaceAhkIcon(module, IcoFile, ExeFile)
{
gosub _EndUpdateResource
Util_Error("Error changing icon: Unable to read icon or icon was of the wrong format.")
}
}
Util_Status("Compressing and adding: Master Script")
if !DllCall("UpdateResource", "ptr", module, "ptr", 10, "str", IcoFile ? ">AHK WITH ICON<" : ">AUTOHOTKEY SCRIPT<"
, "ushort", 0x409, "ptr", &BinScriptBody, "uint", BinScriptBody_Len, "uint")
goto _FailEnd
oldWD := A_WorkingDir
SetWorkingDir, %ScriptDir%
for each,file in ExtraFiles
{
Util_Status("Compressing and adding: " file)
StringUpper, resname, file
IfNotExist, %file%
goto _FailEnd2
FileGetSize, filesize, %file%
VarSetCapacity(filedata, filesize)
FileRead, filedata, *c %file%
If UseCompression {
If !filesize:=VarZ_Compress(filedata,filesize,0x2)
FileGetSize, filesize, %file%
}
if !DllCall("UpdateResource", "ptr", module, "ptr", 10, "str", resname
, "ushort", 0x409, "ptr", &filedata, "uint", filesize, "uint")
goto _FailEnd2
VarSetCapacity(filedata, 0)
}
SetWorkingDir, %oldWD%
gosub _EndUpdateResource
return
_FailEnd:
gosub _EndUpdateResource
Util_Error("Error adding script file:`n`n" AhkFile)
_FailEnd2:
gosub _EndUpdateResource
Util_Error("Error adding FileInstall file:`n`n" file)
_EndUpdateResource:
if !DllCall("EndUpdateResource", "ptr", module, "uint", 0)
Util_Error("Error: Error opening the destination file.")
return
}
Util_GetFullPath(path)
{
VarSetCapacity(fullpath, 260 * (!!A_IsUnicode + 1))
if DllCall("GetFullPathName", "str", path, "uint", 260, "str", fullpath, "ptr", 0, "uint")
return fullpath
else
return ""
}
SendMode Input
DEBUG := !A_IsCompiled
if A_IsUnicode
FileEncoding, UTF-8
gosub BuildBinFileList
gosub LoadSettings
if 0 != 0
goto CLIMain
IcoFile := LastIcon
BinFileId := FindBinFile(LastBinFile)
Menu, FileMenu, Add, &Convert, Convert
Menu, FileMenu, Add
Menu, FileMenu, Add, E&xit`tAlt+F4, GuiClose
Menu, HelpMenu, Add, &Help, Help
Menu, HelpMenu, Add
Menu, HelpMenu, Add, &About, About
Menu, MenuBar, Add, &File, :FileMenu
Menu, MenuBar, Add, &Help, :HelpMenu
Gui, Menu, MenuBar
Gui, +LastFound
GuiHwnd := WinExist("")
Gui, Add, Text, x287 y34,
(
©2004-2009 Chris Mallet
©2008-2011 Steve Gray (Lexikos)
©2011-%A_Year% fincs
©2012-%A_Year% HotKeyIt
http://www.autohotkey.com
Note: Compiling does not guarantee source code protection.
)
Gui, Add, Text, x11 y117 w570 h2 +0x1007
Gui, Add, GroupBox, x11 y124 w570 h86, Required Parameters
Gui, Add, Text, x17 y151, &Source (script file)
Gui, Add, Edit, x137 y146 w315 h23 +Disabled vAhkFile, %AhkFile%
Gui, Add, Button, x459 y146 w53 h23 gBrowseAhk, &Browse
Gui, Add, Text, x17 y180, &Destination (.exe file)
Gui, Add, Edit, x137 y176 w315 h23 +Disabled vExeFile, %Exefile%
Gui, Add, Button, x459 y176 w53 h23 gBrowseExe, B&rowse
Gui, Add, GroupBox, x11 y219 w570 h128, Optional Parameters
Gui, Add, Text, x18 y245, Custom Icon (.ico file)
Gui, Add, Edit, x138 y241 w315 h23 +Disabled vIcoFile, %IcoFile%
Gui, Add, Button, x461 y241 w53 h23 gBrowseIco, Br&owse
Gui, Add, Button, x519 y241 w53 h23 gDefaultIco, D&efault
Gui, Add, Text, x18 y274, Base File (.bin)
Gui, Add, DDL, x138 y270 w315 h23 R10 AltSubmit vBinFileId Choose%BinFileId%, %BinNames%
Gui, Add, CheckBox, x138 y298 w315 h20 gCheckCompression vUseCompression Checked%LastUseCompression%, Use compression to reduce size of resulting exe
Gui, Add, CheckBox, x138 y320 w315 h20 gCheckCompression vUseMpress Checked%LastUseMPRESS%, Use MPRESS (if present) to compress resulting exe
Gui, Add, Button, x258 y351 w75 h28 +Default gConvert, > &Convert <
Gui, Add, Statusbar,, Ready
if !A_IsCompiled
Gui, Add, Pic, x40 y5 +0x801000, %A_ScriptDir%\logo.gif
else
gosub AddPicture
Gui, Show, w594 h405, Ahk2Exe for AutoHotkey v%A_AhkVersion% -- Script to EXE Converter
return
CheckCompression:
Gui,Submit,NoHide
If (A_GuiControl="UseCompression" && %A_GuiControl%)
GuiControl,,UseMPress,0
else if (A_GuiControl="UseMPress" && %A_GuiControl%)
GuiControl,,UseCompression,0
Return
GuiClose:
Gui, Submit
gosub SaveSettings
ExitApp
GuiDropFiles:
if A_EventInfo > 2
Util_Error("You cannot drop more than one file into this window!")
SplitPath, A_GuiEvent,,, dropExt
if (dropExt = "ahk")
GuiControl,, AhkFile, %A_GuiEvent%
else if dropExt = ico
GuiControl,, IcoFile, %A_GuiEvent%
return
AddPicture:
Gui, Add, Text, x40 y5 +0x80100E hwndhPicCtrl
hRSrc := DllCall("FindResource", "ptr", 0, "str", "LOGO.GIF", "ptr", 10, "ptr")
sData := DllCall("SizeofResource", "ptr", 0, "ptr", hRSrc, "uint")
hRes  := DllCall("LoadResource", "ptr", 0, "ptr", hRSrc, "ptr")
pData := DllCall("LockResource", "ptr", hRes, "ptr")
hGlob := DllCall("GlobalAlloc", "uint", 2, "uint", sData, "ptr")
pGlob := DllCall("GlobalLock", "ptr", hGlob, "ptr")
DllCall("msvcrt\memcpy", "ptr", pGlob, "ptr", pData, "uint", sData, "CDecl")
DllCall("GlobalUnlock", "ptr", hGlob)
DllCall("ole32\CreateStreamOnHGlobal", "ptr", hGlob, "int", 1, "ptr*", pStream)
hGdip := DllCall("LoadLibrary", "str", "gdiplus")
VarSetCapacity(si, 16, 0), NumPut(1, si, "UChar")
DllCall("gdiplus\GdiplusStartup", "ptr*", gdipToken, "ptr", &si, "ptr", 0)
DllCall("gdiplus\GdipCreateBitmapFromStream", "ptr", pStream, "ptr*", pBitmap)
DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pBitmap, "ptr*", hBitmap, "uint", 0)
SendMessage, 0x172, 0, hBitmap,, ahk_id %hPicCtrl%
DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
DllCall("gdiplus\GdiplusShutdown", "ptr", gdipToken)
DllCall("FreeLibrary", "ptr", hGdip)
ObjRelease(pStream)
return
Never:
FileInstall, logo.gif, NEVER
return
BuildBinFileList:
BinFiles := ["AutoHotkeySC.bin"]
BinNames = (Default)
Loop, %A_ScriptDir%\..\*.bin,0,1
{
SplitPath, A_LoopFileFullPath,,d,, n
FileGetVersion, v, %A_LoopFileFullPath%
BinFiles._Insert(A_LoopFileFullPath)
BinNames .= "|v" v " " n ".bin (..\" SubStr(d,InStr(d,"\",1,0)+1) ")"
}
Loop, %A_ScriptDir%\..\*.exe,0,1
{
SplitPath, A_LoopFileFullPath,,d,, n
FileGetVersion, v, %A_LoopFileFullPath%
BinFiles._Insert(A_LoopFileFullPath)
BinNames .= "|v" v " " n ".exe" " (..\" SubStr(d,InStr(d,"\",1,0)+1) ")"
}
Loop, %A_ScriptDir%\..\*.dll,0,1
{
SplitPath, A_LoopFileFullPath,,d,, n
FileGetVersion, v, %A_LoopFileFullPath%
BinFiles._Insert(A_LoopFileFullPath)
BinNames .= "|v" v " " n ".dll" " (..\" SubStr(d,InStr(d,"\",1,0)+1) ")"
}
return
FindBinFile(name)
{
global BinFiles
for k,v in BinFiles
if (v = name)
return k
return 1
}
CLIMain:
Error_ForceExit := true
p := []
Loop, %0%
{
if %A_Index% = /NoDecompile
Util_Error("Error: /NoDecompile is not supported.")
else p._Insert(%A_Index%)
}
if Mod(p._MaxIndex(), 2)
goto BadParams
Loop, % p._MaxIndex() // 2
{
p1 := p[2*(A_Index-1)+1]
p2 := p[2*(A_Index-1)+2]
if p1 not in /in,/out,/icon,/pass,/bin,/mpress
goto BadParams
if p1 = /pass
Util_Error("Error: Password protection is not supported.")
if p2 =
goto BadParams
StringTrimLeft, p1, p1, 1
gosub _Process%p1%
}
if !AhkFile
goto BadParams
if !IcoFile
IcoFile := LastIcon
if !BinFile
BinFile := A_ScriptDir "\" LastBinFile
if UseMPRESS =
UseMPRESS := LastUseMPRESS
CLIMode := true
gosub ConvertCLI
ExitApp
BadParams:
Util_Info("Command Line Parameters:`n`n" A_ScriptName " /in infile.ahk [/out outfile.exe] [/icon iconfile.ico] [/bin AutoHotkeySC.bin]")
ExitApp
_ProcessIn:
AhkFile := p2
return
_ProcessOut:
ExeFile := p2
return
_ProcessIcon:
IcoFile := p2
return
_ProcessBin:
CustomBinFile := true
BinFile := p2
return
_ProcessMPRESS:
UseMPRESS := p2
return
BrowseAhk:
Gui, +OwnDialogs
FileSelectFile, ov, 1, %LastScriptDir%, Open, AutoHotkey files (*.ahk)
if ErrorLevel
return
GuiControl,, AhkFile, %ov%
return
BrowseExe:
Gui, +OwnDialogs
FileSelectFile, ov, S16, %LastExeDir%, Save As, Executable files (*.exe;*.dll)
if ErrorLevel
return
GuiControl,, ExeFile, %ov%
return
BrowseIco:
Gui, +OwnDialogs
FileSelectFile, ov, 1, %LastIconDir%, Open, Icon files (*.ico)
if ErrorLevel
return
GuiControl,, IcoFile, %ov%
return
DefaultIco:
GuiControl,, IcoFile
return
Convert:
Gui, +OwnDialogs
Gui, Submit, NoHide
BinFile := BinFiles[BinFileId]
ConvertCLI:
AhkCompile(AhkFile, ExeFile, IcoFile, BinFile, UseMpress,UseCompression)
if !CLIMode
Util_Info("Conversion complete.")
else
FileAppend, Successfully compiled: %ExeFile%`n, *
return
LoadSettings:
RegRead, LastScriptDir, HKCU, Software\AutoHotkey\Ahk2Exe, LastScriptDir
RegRead, LastExeDir, HKCU, Software\AutoHotkey\Ahk2Exe, LastExeDir
RegRead, LastIconDir, HKCU, Software\AutoHotkey\Ahk2Exe, LastIconDir
RegRead, LastIcon, HKCU, Software\AutoHotkey\Ahk2Exe, LastIcon
RegRead, LastBinFile, HKCU, Software\AutoHotkey\Ahk2Exe, LastBinFile
RegRead, LastUseCompression, HKCU, Software\AutoHotkey\Ahk2Exe, LastUseCompression
RegRead, LastUseMPRESS, HKCU, Software\AutoHotkey\Ahk2Exe, LastUseMPRESS
if LastBinFile =
LastBinFile = AutoHotkeySC.bin
if LastUseMPRESS
LastUseMPRESS := true
return
SaveSettings:
SplitPath, AhkFile,, AhkFileDir
if ExeFile
SplitPath, ExeFile,, ExeFileDir
else
ExeFileDir := LastExeDir
if IcoFile
SplitPath, IcoFile,, IcoFileDir
else
IcoFileDir := ""
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastScriptDir, %AhkFileDir%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastExeDir, %ExeFileDir%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastIconDir, %IcoFileDir%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastIcon, %IcoFile%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastUseCompression, %UseCompression%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastUseMPRESS, %UseMPRESS%
if !CustomBinFile
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastBinFile, % BinFiles[BinFileId]
return
Help:
helpfile = %A_ScriptDir%\..\AutoHotkey.chm
IfNotExist, %helpfile%
Util_Error("Error: cannot find AutoHotkey help file!")
VarSetCapacity(ak, ak_size := 8+5*A_PtrSize+4, 0)
NumPut(ak_size, ak, 0, "UInt")
name = Ahk2Exe
NumPut(&name, ak, 8)
DllCall("hhctrl.ocx\HtmlHelp", "ptr", GuiHwnd, "str", helpfile, "uint", 0x000D, "ptr", &ak)
return
About:
MsgBox, 64, About Ahk2Exe,
(
Ahk2Exe - Script to EXE Converter

Original version:
  Copyright ©1999-2003 Jonathan Bennett & AutoIt Team
  Copyright ©2004-2009 Chris Mallet
  Copyright ©2008-2011 Steve Gray (Lexikos)

Script rewrite:
  Copyright ©2011-%A_Year% fincs
  Copyright ©2012-%A_Year% HotKeyIt
)
return
Util_Status(s)
{
SB_SetText(s)
}
Util_Error(txt, doexit=1)
{
global CLIMode, Error_ForceExit, ExeFileTmp
if ExeFileTmp && FileExist(ExeFileTmp)
{
FileDelete, %ExeFileTmp%
ExeFileTmp =
}
Util_HideHourglass()
MsgBox, 16, Ahk2Exe Error, % txt
if CLIMode
FileAppend, Failed to compile: %ExeFile%`n, *
Util_Status("Ready")
if doexit
if !Error_ForceExit
Exit
else
ExitApp
}
Util_Info(txt)
{
MsgBox, 64, Ahk2Exe, % txt
}
Util_DisplayHourglass()
{
DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32514, "ptr"))
}
Util_HideHourglass()
{
DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32512, "ptr"))
}
VarZ_Compress( ByRef Data, DataSize, CompressionMode = 0x102,RECURSIVE = 0 ) {
Static STATUS_SUCCESS := 0x0,   HdrSz := 18
If ( NumGet( Data, "UInt" ) = 0x005F5A4C )
Return 0, ErrorLevel := -1
DllCall( "ntdll\RtlGetCompressionWorkSpaceSize"
, UInt,  CompressionMode
, UIntP, CompressBufferWorkSpaceSize
, UIntP, CompressFragmentWorkSpaceSize )
VarSetCapacity( CompressBufferWorkSpace, CompressBufferWorkSpaceSize )
TempSize := VarSetCapacity( TempData, DataSize )
NTSTATUS := DllCall( "ntdll\RtlCompressBuffer"
, UShort,  CompressionMode
, PTR,  &Data
, UInt,  DataSize
, PTR,  &TempData
, UInt,  TempSize
, UInt,  CompressFragmentWorkSpaceSize
, UIntP, FinalCompressedSize
, PTR,  &CompressBufferWorkSpace
,  UInt )
If ( NTSTATUS <> STATUS_SUCCESS  ||  FinalCompressedSize + HdrSz > DataSize )
Return 0, ErrorLevel := ( NTSTATUS ? NTSTATUS : -2 )
VarSetCapacity( Data, FinalCompressedSize + HdrSz, 0 )
NumPut( 0x005F5A4C, Data, "UInt" )
Numput( CompressionMode, Data, 8, "UShort" )
NumPut( DataSize, Data, 10, "UInt" )
NumPut( FinalCompressedSize, Data, 14, "UInt" )
DllCall( "RtlMoveMemory", PTR,  &Data + HdrSz
, PTR,  &TempData
, PTR,  FinalCompressedSize )
DllCall( "shlwapi\HashData", PTR,  &Data + 8
, UInt,  FinalCompressedSize + 10
, PTR,  &Data + 4
, UInt,  4 )
If !RECURSIVE && NumPut( 0x315F5A4C, Data, "UInt" )
If MultiCompressedSize:= VarZ_Compress(Data,FinalCompressedSize + HdrSz,CompressionMode,1)
return MultiCompressedSize
else NumPut( 0x005F5A4C, Data, "UInt" )
Return FinalCompressedSize + HdrSz
}
VarZ_Uncompress( ByRef D ) {
IfNotEqual, A_Tab, % ID:=NumGet(D,"UInt"), IfNotEqual, ID, 0x5F5A4C,  Return 0, ErrorLevel := -1
savedHash := NumGet(D,4,"UInt"), TZ := NumGet(D,10,"UInt"), DZ := NumGet(D,14,"UInt")
DllCall( "shlwapi\HashData", UInt,&D+8, UInt,DZ+10, UIntP,Hash, UInt,4 )
IfNotEqual, Hash, %savedHash%, Return 0, ErrorLevel := -2
VarSetCapacity( TD,TZ,0 ), NTSTATUS := DllCall( "ntdll\RtlDecompressBuffer", UShort
, NumGet(D,8,"UShort"), PTR, &TD, UInt,TZ, PTR,&D+18, UInt,DZ, UIntP,Final, UInt )
IfNotEqual, NTSTATUS, 0, Return 0, ErrorLevel := NTSTATUS
VarSetCapacity( D,Final,0 ), DllCall( "RtlMoveMemory", PTR,&D, PTR,&TD, PTR,Final )
If NumGet(D,"UInt")=0x315F5A4C && NumPut(0x005F5A4C,D,"UInt")
Return VarZ_Uncompress( D )
Return Final, VarSetCapacity( D,-1 )
}
VarZ_Load( ByRef Data, SrcFile ) {
FileGetSize, DataSize, %SrcFile%
If !ErrorLevel {
FileRead, Data, *c %SrcFile%
If !ErrorLevel
Return DataSize
}
}
VarZ_Save( ByRef Data, DataSize, TrgFile ) {
hFile :=  DllCall( "_lcreat", ( A_IsUnicode ? "AStr" : "Str" ),TrgFile, UInt,0,PTR )
IfLess, hFile, 1, Return "", ErrorLevel := 1
nBytes := DllCall( "_lwrite", PTR,hFile, PTR,&Data, UInt,DataSize, UInt )
DllCall( "_lclose", PTR,hFile )
Return nBytes
} 