#include cURL.ahk
; files is a comma separated list containing full file paths
bugReportPoster(email := "", message := "", files := "", byRef bugResponseTicket := "")
{

	if files
	{
		uploadSize := 0
		aFileNames := []
		loop, parse, files, `, 
		{
			if FileExist(A_LoopField)
			{
				aFileNames.insert(A_LoopField)
				FileGetSize, fileSizeBytes, %A_LoopField%
				uploadSize += fileSizeBytes
				if (fileSizeBytes > 1048576) ; max 1mb/file
					return -1
			}
		}
		if (uploadSize > 1048576 * 7) ; 7MB upload limit (think 8 but lets be safe - its heaps anyway)
			return -1 ; -1 indicating file size error
	}

	FileInstall, Included Files\libcurl.dll, %A_Temp%\libcurl.dll, 1
	if (ErrorLevel)	
		return fallback("FileInstall error while load libcurl.dll")

	if (errorCode := curl_global_init(A_Temp "\libcurl.dll", "CURL_GLOBAL_ALL")) {

	    ; returns the Global initialization error
		return fallback("Failed to initialise cURL Global n" errorCode)
	}

	if (hnd := cURL_Easy_Init()) {
		URL := "http://mt.9xq.ru/issue/create"
		
		httpAgent := cURL_Version() " MacroTrainer/2.983"

		if errorCode := curl_formadd(fpost, lpost, ["CURLFORM_COPYNAME", "email", "CURLFORM_COPYCONTENTS", email, "CURLFORM_END"])
			return curl_fallback("Error in curl_formadd email n" errorCode, hnd)

		if errorCode := curl_formadd(fpost, lpost, ["CURLFORM_COPYNAME","text","CURLFORM_COPYCONTENTS", message ,"CURLFORM_END"])
			return curl_fallback("Error in curl_formadd message n" errorCode, hnd)

		for i, fileName in aFileNames
			if errorCode := curl_formadd(fpost, lpost, ["CURLFORM_COPYNAME","upload[" (A_Index - 1) "]","CURLFORM_FILE", fileName,"CURLFORM_CONTENTTYPE","application/octet-stream","CURLFORM_END"])
				return curl_fallback("Error in curl_formadd file n" errorCode, hnd)

		pCurlWriteFunction := RegisterCallback("CurlWriteFunction", "CDecl")
		if errorCode := curl_easy_setopt(hnd, "CURLOPT_WRITEFUNCTION", pCurlWriteFunction)
			return curl_fallback("Error CURLOPT_WRITEFUNCTION n" errorCode, hnd, pCurlWriteFunction)
		if errorCode := curl_easy_setopt(hnd, "CURLOPT_VERBOSE", True)
			return curl_fallback("Error CURLOPT_VERBOSE n" errorCode, hnd, pCurlWriteFunction)
		if errorCode := curl_easy_setopt(hnd, "CURLOPT_POST", True)
			return curl_fallback("Error CURLOPT_POST n" errorCode, hnd, pCurlWriteFunction)
		if errorCode := curl_easy_setopt(hnd, "CURLOPT_URL", URL)
			return curl_fallback("Error CURLOPT_URL n" errorCode, hnd, pCurlWriteFunction)
		if errorCode := cURL_easy_setopt(hnd, "CURLOPT_NOPROGRESS", True)
			return curl_fallback("Error CURLOPT_NOPROGRESS n" errorCode, hnd, pCurlWriteFunction)
		if errorCode := curl_easy_setopt(hnd, "CURLOPT_FOLLOWLOCATION", True)
			return curl_fallback("Error CURLOPT_FOLLOWLOCATION n" errorCode, hnd, pCurlWriteFunction)
		if errorCode := curl_easy_setopt(hnd, "CURLOPT_HTTPPOST", fpost)
			return curl_fallback("Error CURLOPT_HTTPPOST n" errorCode, hnd, pCurlWriteFunction)
		if errorCode := curl_easy_setopt(hnd, "CURLOPT_USERAGENT", httpAgent)
			return curl_fallback("Error CURLOPT_USERAGENT n" errorCode, hnd, pCurlWriteFunction)
		if errorCode := curl_easy_setopt(hnd, "CURLOPT_MAXREDIRS", 50)
			return curl_fallback("Error CURLOPT_MAXREDIRS n" errorCode, hnd, pCurlWriteFunction)

		if (errorCode := curl_easy_perform(hnd)) 
			return curl_fallback("Error curl_easy_perform n" errorCode, hnd, pCurlWriteFunction) ; curl_easy_strError(errorCode)

		if errorCode := curl_easy_getinfo(hnd, "CURLINFO_RESPONSE_CODE", http_code)
			return curl_fallback("Error curl_easy_perform n" errorCode, hnd, pCurlWriteFunction)
	
		pCurlWriteFunction ? DllCall("GlobalFree", "Ptr", pCurlWriteFunction, "Ptr")

		if (http_code != 201)
			return curl_fallback("Error Http response error. Server Responded with code: " http_code, hnd)

		cURL_Easy_Cleanup(hnd)

		if (substr(bugTicket := cURLLog(), 1, 3) != "OK|") {
			return curl_fallback("Sever bug Ticket invalid")
		} else {
			bugResponseTicket := LTrim(bugTicket, " `tOK|")
		}
	} else {
		curl_global_cleanup()
		return fallback("Failed to retrieve handle from cURL_Easy_Init")
	}
	curl_global_cleanup()
}

curl_fallback(error, hnd := False, pCurlWriteFunction := False) {
	pCurlWriteFunction ? DllCall("GlobalFree", "Ptr", pCurlWriteFunction, "Ptr")
	hnd ? cURL_Easy_Cleanup(hnd)
	curl_global_cleanup()
	return fallback(error)
}


fallback(error) {
	message := error
	StringReplace, message, message, %A_Space%, _, All
	StringReplace, message, message, `n, _, All
	StringReplace, message, message, ., _, All	
	fallbackURL := "http://mt.9xq.ru/issue/fb?m=" message
	httpGet(fallbackURL)
	return error
}

CurlWriteFunction(pBuffer, size, nitems) {
  cURLLog(false, StrGet(pBuffer, size*nitems, "CP0"))
  return size*nitems
}

; server response is OK|XX  - where xx is a number eg 74
cURLLog(clear := True, text := "") {
	static log
	if StrLen(text) 
		log .= (StrLen(log) ? "`n" : "") . text
	return clear ? (copy := log, log := "") : log 
}