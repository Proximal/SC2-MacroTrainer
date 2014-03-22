
#SingleInstance force


setworkingdir %A_ScriptDir% ;\..\ 

#include %A_ScriptDir%\..\lib\GDIP.ahk

onexit bye

url=https://dl.dropboxusercontent.com/u/14147708/a.png
ifnotexist, %a_scriptdir%\a.png
URLDownloadToFile, %url%,%a_scriptdir%\a.png

pToken := Gdip_Startup()
Gui, 2:  -Caption +E0x80000 +LastFound +OwnDialogs +Owner +hwndhwnd +alwaysontop
Gui, 2: Show, NA ,dialog

sFile=%a_scriptdir%\a.png
oFile=%a_scriptdir%\avatar.png

pBitmap := Gdip_CreateBitmapFromFile(sFile)
Gdip_GetDimensions(pBitmap, w, h)

hbm := CreateDIBSection(w,h)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
pGraphics:=Gdip_GraphicsFromHDC(hdc)

pBitmapMask := Gdip_CreateBitmap(w, h), G2 := Gdip_GraphicsFromImage(pBitmapMask)
Gdip_SetSmoothingMode(G2, 4)

pBrush := Gdip_BrushCreateSolid(0xff00ff00)
Gdip_FillEllipse(G2, pBrush, 0, 0, w, h)
Gdip_DeleteBrush(pBrush)

pBitmapNew := Gdip_AlphaMask(pBitmap, pBitmapMask, 0, 0)
Gdip_DrawImage(pGraphics, pBitmapNew, 0,0,w,h)
;Gdip_DrawImage(pGraphics, pBitmapMask, 0,0,w,h)


Gdip_SaveBitmapToFile(pBitmap, oFile)
UpdateLayeredWindow(hwnd, hdc,(a_screenwidth-w)//2,(a_screenheight-h)//2,w,h)


return

esc::
bye:
Gdip_DisposeImage(pBitmap), Gdip_DisposeImage(pBitmapMask), Gdip_DisposeImage(pBitmapNew)
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
Gdip_DeleteGraphics(pGraphics)
Gdip_Shutdown(pToken)
exitapp

;#######################################################################
/*
Gdip_AlphaMask(pBitmap, pBitmapMask, x, y, invert=0)
{
    static _AlphaMask
    if !_AlphaMask
    {
        MCode_AlphaMask := "518B4424249983E20303C28BC88B442428995383E20303C28B5424245556C1F902C1F802837C24400057757E85D20F8E0E01000"
        . "08B5C241C8B74242C03C003C0894424388D048D000000000FAF4C2440034C243C894424348B4424208D3C888954244485F67E2C8B5424182B5424208"
        . "BCF8BC38B2C0A332883C00481E5FFFFFF003368FC83C10483EE018969FC75E48B74242C037C2434035C2438836C24440175C15F5E5D33C05B59C385D"
        . "20F8E900000008B5C241C8B74242C03C003C0894424388D048D000000000FAF4C2440034C243C894424348B442420895C24448D3C888954241085F67"
        . "E428B5424182B5424208BC78BCBEB098DA424000000008BFF8B1981E3000000FFBD000000FF2BEB8B1C1081E3FFFFFF000BEB892883C10483C00483E"
        . "E0175D98B74242C8B5C2444035C2438037C2434836C241001895C244475A35F5E5D33C05B59C3"

        VarSetCapacity(_AlphaMask, StrLen(MCode_AlphaMask)//2)
        Loop % StrLen(MCode_AlphaMask)//2      ;%
            NumPut("0x" SubStr(MCode_AlphaMask, (2*A_Index)-1, 2), _AlphaMask, A_Index-1, "char")
    }
    Gdip_GetDimensions(pBitmap, w1, h1), Gdip_GetDimensions(pBitmapMask, w2, h2)
    pBitmapNew := Gdip_CreateBitmap(w1, h1)
    if !pBitmapNew
        return -1

    E1 := Gdip_LockBits(pBitmap, 0, 0, w1, h1, Stride1, Scan01, BitmapData1)
    E2 := Gdip_LockBits(pBitmapMask, 0, 0, w2, h2, Stride2, Scan02, BitmapData2)
    E3 := Gdip_LockBits(pBitmapNew, 0, 0, w1, h1, Stride3, Scan03, BitmapData3)
    if (E1 || E2 || E3)
        return -2

    E := DllCall(&_AlphaMask, "ptr", Scan01, "ptr", Scan02, "ptr", Scan03, "int", w1, "int", h1, "int", w2, "int", h2, "int", Stride1, "int", Stride2, "int", x, "int", y, "int", invert)
    
    Gdip_UnlockBits(pBitmap, BitmapData1), Gdip_UnlockBits(pBitmapMask, BitmapData2), Gdip_UnlockBits(pBitmapNew, BitmapData3)
    return (E = "") ? -3 : pBitmapNew
}
*/