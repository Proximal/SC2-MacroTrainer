;url := CrackUrl("http://user:pass@example.com:80/qwe/index.php?asd=123#test")
;MsgBox % url.scheme "://" url.userName ":" url.password "@" url.hostName ":" url.port url.urlPath url.extraInfo
CrackUrl(url) 
{
    VarSetCapacity(myStruct,60,0)
    numput(60,myStruct,0,"Uint") ; this dll function requires this to be set
    numput(1,myStruct,8,"Uint") ; SchemeLength
    numput(1,myStruct,20,"Uint") ; HostNameLength
    numput(1,myStruct,32,"Uint") ; UserNameLength
    numput(1,myStruct,40,"Uint") ; PasswordLength
    numput(1,myStruct,48,"Uint") ; UrlPathLength
    numput(1,myStruct,56,"Uint") ; ExtraInfoLength
    DllCall("Winhttp.dll\WinHttpCrackUrl","PTR",&url,"UInt",StrLen(url),"UInt",0,"PTR",&myStruct)
 
    urlObj := Object()
    urlObj.scheme := StrGet(NumGet(myStruct,4,"Ptr"),NumGet(myStruct,8,"UInt"))
    urlObj.userName := StrGet(NumGet(myStruct,28,"Ptr"),NumGet(myStruct,32,"UInt"))
    urlObj.password := StrGet(NumGet(myStruct,36,"Ptr"),NumGet(myStruct,40,"UInt"))
    urlObj.hostName := StrGet(NumGet(myStruct,16,"Ptr"),NumGet(myStruct,20,"UInt"))
    urlObj.port := NumGet(myStruct,24,"Int")
    urlObj.urlPath := StrGet(NumGet(myStruct,44,"Ptr"),NumGet(myStruct,48,"UInt"))
    urlObj.extraInfo := StrGet(NumGet(myStruct,52,"Ptr"),NumGet(myStruct,56,"UInt"))
    Return urlObj
}