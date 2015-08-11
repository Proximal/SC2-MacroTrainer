getWinKillScript(windowTitle)
{
    script = 
    ( Comments
        #NoEnv
        #NoTrayIcon
        DetectHiddenWindows, On
        msgbox `%A_AhkPath`%
        winTitle := "%windowTitle%" ; Using the script hidden window title kills it first loop even if options menu is open
        WinWaitClose, `%winTitle`%,, 1
        while WinExist(winTitle) && A_index <= 4
        {
            winkill, `%winTitle`%
            sleep 200 
        }
        exitapp          
    )
    return script
}
