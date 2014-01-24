DownloadFile(UrlToFile, _SaveFileAs, Overwrite := True, UseProgressBar := True) {
    ;Check if the file already exists and if we must not overwrite it
      If (!Overwrite && FileExist(_SaveFileAs))
      {
        FileSelectFile, _SaveFileAs,S, %_SaveFileAs%
        if !_SaveFileAs ; user didnt select anything
          return
      }

    ;Check if the user wants a progressbar
      If (UseProgressBar) {
          ;Make variables global that we need later when creating a timer
            SaveFileAs := _SaveFileAs
          ;Initialize the WinHttpRequest Object
            WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
          ;Download the headers
            WebRequest.Open("HEAD", UrlToFile)
            WebRequest.Send()
          ;Store the header which holds the file size in a variable:
            FinalSize := WebRequest.GetResponseHeader("Content-Length")
            Progress, H80, , Downloading..., %UrlToFile% Download
            SetTimer, DownloadFileFunction_UpdateProgressBar, 100
      }
    ;Download the file
      UrlDownloadToFile, %UrlToFile%, %_SaveFileAs%
    ;Remove the timer and the progressbar  because the download has finished
      If (UseProgressBar) {
          Progress, Off
          SetTimer, DownloadFileFunction_UpdateProgressBar, Off
      }
      return

      DownloadFileFunction_UpdateProgressBar:
    ;Get the current filesize and tick
      CurrentSize := FileOpen(_SaveFileAs, "r").Length ;FileGetSize wouldn't return reliable results
      CurrentSizeTick := A_TickCount
    ;Calculate the downloadspeed
      Speed := Round((CurrentSize/1024-LastSize/1024)/((CurrentSizeTick-LastSizeTick)/1000)) . " Kb/s"
    ;Save the current filesize and tick for the next time
      LastSizeTick := CurrentSizeTick
      LastSize := FileOpen(_SaveFileAs, "r").Length
    ;Calculate percent done
      PercentDone := Round(CurrentSize/FinalSize*100)
    ;Update the ProgressBar
      Progress, %PercentDone%, %PercentDone%`% Done, Downloading...    (%Speed%), Downloading %_SaveFileAs% (%PercentDone%`%)
      return
}