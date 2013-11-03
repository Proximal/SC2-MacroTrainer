#include cURL.ahk
; files is a comma separated list containing full file paths
bugReportPoster(email := "", message := "", files := "", byRef bugResponseTicket := "")
{

	if files
	{
		aFileNames := []
		loop, parse, files, `, 
		{
			if FileExist(A_LoopField)
				aFileNames.insert(A_LoopField)
		}
	}

	FileInstall, Included Files\libcurl.dll, %A_Temp%\libcurl.dll, 1
	if curl_global_init(A_Temp "\libcurl.dll", "CURL_GLOBAL_ALL") ; returns the Global initialization error
		error := "Failed to initialise cURL Global"
	else 
	{
		if (hnd := cURL_Easy_Init()) 
		{
			URL := "http://mt.9xq.ru/issue/create"
			fallbackURL := "http://mt.9xq.ru/issue/fb?m="

			httpAgent := cURL_Version() " MacroTrainer/2.983"
			curl_formadd(fpost, lpost, "CURLFORM_COPYNAME,email,CURLFORM_COPYCONTENTS," email ",CURLFORM_END")
			curl_formadd(fpost, lpost, "CURLFORM_COPYNAME,text,CURLFORM_COPYCONTENTS," message ",CURLFORM_END")

			for i, fileName in aFileNames
		 		curl_formadd(fpost, lpost, "CURLFORM_COPYNAME,upload[" (A_Index - 1) "],CURLFORM_FILE," fileName ",CURLFORM_CONTENTTYPE,application/octet-stream,CURLFORM_END")

			pCurlWriteFunction := RegisterCallback("CurlWriteFunction", "CDecl")
			curl_easy_setopt(hnd, "CURLOPT_WRITEFUNCTION", pCurlWriteFunction)
			curl_easy_setopt(hnd, "CURLOPT_VERBOSE", True)
			curl_easy_setopt(hnd, "CURLOPT_POST", True)
			curl_easy_setopt(hnd, "CURLOPT_URL", URL)
			cURL_easy_setopt(hnd, "CURLOPT_NOPROGRESS", True)
			curl_easy_setopt(hnd, "CURLOPT_FOLLOWLOCATION", True)
			curl_easy_setopt(hnd, "CURLOPT_HTTPPOST", fpost)
			curl_easy_setopt(hnd, "CURLOPT_USERAGENT", httpAgent)
			curl_easy_setopt(hnd, "CURLOPT_MAXREDIRS", 50)

			if (errorCode := curl_easy_perform(hnd)) 
				error .= "`n" curl_easy_strError(errorCode)
			curl_easy_getinfo(hnd, "CURLINFO_RESPONSE_CODE", http_code)
			if (http_code != 201)
				error .= "`nHttp response error. Server Responded with code: " http_code
			cURL_Easy_Cleanup(hnd)	
			if !InStr(bugTicket := cURLLog(), "OK")
				error .= "`nSever bug Ticket invalid"
			else bugResponseTicket := Trim(bugTicket, " `t|OK")
			msgbox % bugResponseTicket
		}
		else error .= "`nFailed to retrieve handle from cURL_Easy_Init()"
	}

	curl_global_cleanup()
	pCurlWriteFunction ? DllCall("GlobalFree", "Ptr", pCurlWriteFunction, "Ptr")
	if error
	{
		StringReplace, error, error, %A_Space%, _, All
		StringReplace, error, error, `n, _, All
		StringReplace, error, error, ., _, All
		httpGet(fallbackURL error)
	}
	return error
}

CurlWriteFunction(pBuffer, size, nitems) 
{
  cURLLog(false, StrGet(pBuffer, size*nitems, "CP0"))
  return size*nitems
}

; server response is OK|XX  - where xx is a number eg 74
cURLLog(clear := True, text := "")
{
	static log
	if StrLen(text) 
		log .= (StrLen(log) ? "`n" : "") . text
	return clear ? (copy := log, log := "") : log 
}