I only made a couple of very very minor changes to the AHK_H 32W-MD v1.1.15.00 source code. Each change is commented with // MT_Stuff**

These compiled files can be found in the folder "AHK_H modded Source and Files\AHK used by MacroTrainer\"
The AutoHotkey.exe, AutoHotkey.dll, and AutoHotkeySC.bin contain these changes.
The AutoHotkeyMini.dll file is a copy from the standard AHK_H 32W released files.

**When compiling the release exe, DLL, and self-contained (.SC compiler) projects from source ensure that 'Enable DPI Awareness' is enabled for each configuration. (Project --> properties --> configuration properties --> Manifest Tool --> Input and Output.) Without this the reported A_ScreenDPI is incorrect at 150% DPI. Actually with the current MacroTrainer script only the release exe and self-contained projects need this setting (so as to draw/size the options GUI custom colour selection boxes correctly)

ahkdll-master.zip contains the unmodified source code.