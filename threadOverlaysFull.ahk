; <COMPILER: v1.1.15.00>
#persistent
#NoEnv
#NoTrayIcon
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1
ListLines, Off
OnExit, ShutdownProcedure
scriptWinTitle := changeScriptMainWinTitle()
l_GameType := "1v1,2v2,3v3,4v4,FFA"
l_Races := "Terran,Protoss,Zerg"
GLOBAL GameWindowTitle := "StarCraft II"
GLOBAL GameIdentifier := "ahk_exe SC2.exe"
GLOBAL config_file := "MT_Config.ini"
GameExe := "SC2.exe"
UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
{
static Ptr := A_PtrSize ? "UPtr" : "UInt"
if ((x != "") && (y != ""))
VarSetCapacity(pt, 8), NumPut(x, pt, 0, "UInt"), NumPut(y, pt, 4, "UInt")
if (w = "") ||(h = "")
WinGetPos,,, w, h, ahk_id %hwnd%
return DllCall("UpdateLayeredWindow"
, Ptr, hwnd
, Ptr, 0
, Ptr, ((x = "") && (y = "")) ? 0 : &pt
, "int64*", w|h<<32
, Ptr, hdc
, "int64*", 0
, "uint", 0
, "UInt*", Alpha<<16|1<<24
, "uint", 2)
}
BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster="")
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
return DllCall("gdi32\BitBlt"
, Ptr, dDC
, "int", dx
, "int", dy
, "int", dw
, "int", dh
, Ptr, sDC
, "int", sx
, "int", sy
, "uint", Raster ? Raster : 0x00CC0020)
}
StretchBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, sw, sh, Raster="")
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
return DllCall("gdi32\StretchBlt"
, Ptr, ddc
, "int", dx
, "int", dy
, "int", dw
, "int", dh
, Ptr, sdc
, "int", sx
, "int", sy
, "int", sw
, "int", sh
, "uint", Raster ? Raster : 0x00CC0020)
}
SetStretchBltMode(hdc, iStretchMode=4)
{
return DllCall("gdi32\SetStretchBltMode"
, A_PtrSize ? "UPtr" : "UInt", hdc
, "int", iStretchMode)
}
SetImage(hwnd, hBitmap)
{
SendMessage, 0x172, 0x0, hBitmap,, ahk_id %hwnd%
E := ErrorLevel
DeleteObject(E)
return E
}
SetSysColorToControl(hwnd, SysColor=15)
{
WinGetPos,,, w, h, ahk_id %hwnd%
bc := DllCall("GetSysColor", "Int", SysColor, "UInt")
pBrushClear := Gdip_BrushCreateSolid(0xff000000 | (bc >> 16 | bc & 0xff00 | (bc & 0xff) << 16))
pBitmap := Gdip_CreateBitmap(w, h), G := Gdip_GraphicsFromImage(pBitmap)
Gdip_FillRectangle(G, pBrushClear, 0, 0, w, h)
hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
SetImage(hwnd, hBitmap)
Gdip_DeleteBrush(pBrushClear)
Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
return 0
}
Gdip_BitmapFromScreen(Screen=0, Raster="")
{
if (Screen = 0)
{
Sysget, x, 76
Sysget, y, 77
Sysget, w, 78
Sysget, h, 79
}
else if (SubStr(Screen, 1, 5) = "hwnd:")
{
Screen := SubStr(Screen, 6)
if !WinExist( "ahk_id " Screen)
return -2
WinGetPos,,, w, h, ahk_id %Screen%
x := y := 0
hhdc := GetDCEx(Screen, 3)
}
else if (Screen&1 != "")
{
Sysget, M, Monitor, %Screen%
x := MLeft, y := MTop, w := MRight-MLeft, h := MBottom-MTop
}
else
{
StringSplit, S, Screen, |
x := S1, y := S2, w := S3, h := S4
}
if (x = "") || (y = "") || (w = "") || (h = "")
return -1
chdc := CreateCompatibleDC(), hbm := CreateDIBSection(w, h, chdc), obm := SelectObject(chdc, hbm), hhdc := hhdc ? hhdc : GetDC()
BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)
ReleaseDC(hhdc)
pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
return pBitmap
}
Gdip_BitmapFromHWND(hwnd)
{
WinGetPos,,, Width, Height, ahk_id %hwnd%
hbm := CreateDIBSection(Width, Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
PrintWindow(hwnd, hdc)
pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
return pBitmap
}
CreateRectF(ByRef RectF, x, y, w, h)
{
VarSetCapacity(RectF, 16)
NumPut(x, RectF, 0, "float"), NumPut(y, RectF, 4, "float"), NumPut(w, RectF, 8, "float"), NumPut(h, RectF, 12, "float")
}
CreateRect(ByRef Rect, x, y, w, h)
{
VarSetCapacity(Rect, 16)
NumPut(x, Rect, 0, "uint"), NumPut(y, Rect, 4, "uint"), NumPut(w, Rect, 8, "uint"), NumPut(h, Rect, 12, "uint")
}
CreateSizeF(ByRef SizeF, w, h)
{
VarSetCapacity(SizeF, 8)
NumPut(w, SizeF, 0, "float"), NumPut(h, SizeF, 4, "float")
}
CreatePointF(ByRef PointF, x, y)
{
VarSetCapacity(PointF, 8)
NumPut(x, PointF, 0, "float"), NumPut(y, PointF, 4, "float")
}
CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
hdc2 := hdc ? hdc : GetDC()
VarSetCapacity(bi, 40, 0)
NumPut(w, bi, 4, "uint")
, NumPut(h, bi, 8, "uint")
, NumPut(40, bi, 0, "uint")
, NumPut(1, bi, 12, "ushort")
, NumPut(0, bi, 16, "uInt")
, NumPut(bpp, bi, 14, "ushort")
hbm := DllCall("CreateDIBSection"
, Ptr, hdc2
, Ptr, &bi
, "uint", 0
, A_PtrSize ? "UPtr*" : "uint*", ppvBits
, Ptr, 0
, "uint", 0, Ptr)
if !hdc
ReleaseDC(hdc2)
return hbm
}
PrintWindow(hwnd, hdc, Flags=0)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
return DllCall("PrintWindow", Ptr, hwnd, Ptr, hdc, "uint", Flags)
}
DestroyIcon(hIcon)
{
return DllCall("DestroyIcon", A_PtrSize ? "UPtr" : "UInt", hIcon)
}
PaintDesktop(hdc)
{
return DllCall("PaintDesktop", A_PtrSize ? "UPtr" : "UInt", hdc)
}
CreateCompatibleBitmap(hdc, w, h)
{
return DllCall("gdi32\CreateCompatibleBitmap", A_PtrSize ? "UPtr" : "UInt", hdc, "int", w, "int", h)
}
CreateCompatibleDC(hdc=0)
{
return DllCall("CreateCompatibleDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}
SelectObject(hdc, hgdiobj)
{
static Ptr := A_PtrSize ? "UPtr" : "UInt"
return DllCall("SelectObject", Ptr, hdc, Ptr, hgdiobj)
}
DeleteObject(hObject)
{
return DllCall("DeleteObject", A_PtrSize ? "UPtr" : "UInt", hObject)
}
GetDC(hwnd=0)
{
return DllCall("GetDC", A_PtrSize ? "UPtr" : "UInt", hwnd)
}
GetDCEx(hwnd, flags=0, hrgnClip=0)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
return DllCall("GetDCEx", Ptr, hwnd, Ptr, hrgnClip, "int", flags)
}
ReleaseDC(hdc, hwnd=0)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
return DllCall("ReleaseDC", Ptr, hwnd, Ptr, hdc)
}
DeleteDC(hdc)
{
return DllCall("DeleteDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}
Gdip_LibraryVersion()
{
return 1.45
}
Gdip_BitmapFromBRA(ByRef BRAFromMemIn, File, Alternate=0)
{
Static FName = "ObjRelease"
if !BRAFromMemIn
return -1
Loop, Parse, BRAFromMemIn, `n
{
if (A_Index = 1)
{
StringSplit, Header, A_LoopField, |
if (Header0 != 4 || Header2 != "BRA!")
return -2
}
else if (A_Index = 2)
{
StringSplit, Info, A_LoopField, |
if (Info0 != 3)
return -3
}
else
break
}
if !Alternate
StringReplace, File, File, \, \\, All
RegExMatch(BRAFromMemIn, "mi`n)^" (Alternate ? File "\|.+?\|(\d+)\|(\d+)" : "\d+\|" File "\|(\d+)\|(\d+)") "$", FileInfo)
if !FileInfo
return -4
hData := DllCall("GlobalAlloc", "uint", 2, Ptr, FileInfo2, Ptr)
pData := DllCall("GlobalLock", Ptr, hData, Ptr)
DllCall("RtlMoveMemory", Ptr, pData, Ptr, &BRAFromMemIn+Info2+FileInfo1, Ptr, FileInfo2)
DllCall("GlobalUnlock", Ptr, hData)
DllCall("ole32\CreateStreamOnHGlobal", Ptr, hData, "int", 1, A_PtrSize ? "UPtr*" : "UInt*", pStream)
DllCall("gdiplus\GdipCreateBitmapFromStream", Ptr, pStream, A_PtrSize ? "UPtr*" : "UInt*", pBitmap)
If (A_PtrSize)
%FName%(pStream)
Else
DllCall(NumGet(NumGet(1*pStream)+8), "uint", pStream)
return pBitmap
}
Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
{
return DllCall("gdiplus\GdipDrawRectangle", "UPtr", pGraphics, "UPtr", pPen, "float", x, "float", y, "float", w, "float", h)
}
Gdip_DrawRoundedRectangle(pGraphics, pPen, x, y, w, h, r)
{
Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
E := Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
Gdip_ResetClip(pGraphics)
Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
Gdip_DrawEllipse(pGraphics, pPen, x, y, 2*r, 2*r)
Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y, 2*r, 2*r)
Gdip_DrawEllipse(pGraphics, pPen, x, y+h-(2*r), 2*r, 2*r)
Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
Gdip_ResetClip(pGraphics)
return E
}
Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h)
{
return DllCall("gdiplus\GdipDrawEllipse", "UPtr", pGraphics, "UPtr", pPen, "float", x, "float", y, "float", w, "float", h)
}
Gdip_DrawBezier(pGraphics, pPen, x1, y1, x2, y2, x3, y3, x4, y4)
{
return DllCall("gdiplus\GdipDrawBezier"
, "UPtr", pgraphics
, "UPtr", pPen
, "float", x1
, "float", y1
, "float", x2
, "float", y2
, "float", x3
, "float", y3
, "float", x4
, "float", y4)
}
Gdip_DrawArc(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle)
{
return DllCall("gdiplus\GdipDrawArc"
, "UPtr", pGraphics
, "UPtr", pPen
, "float", x
, "float", y
, "float", w
, "float", h
, "float", StartAngle
, "float", SweepAngle)
}
Gdip_DrawPie(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle)
{
return DllCall("gdiplus\GdipDrawPie", "UPtr", pGraphics, "UPtr", pPen, "float", x, "float", y, "float", w, "float", h, "float", StartAngle, "float", SweepAngle)
}
Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2)
{
return DllCall("gdiplus\GdipDrawLine"
, "UPtr", pGraphics
, "UPtr", pPen
, "float", x1
, "float", y1
, "float", x2
, "float", y2)
}
Gdip_DrawLines(pGraphics, pPen, Points)
{
StringSplit, Points, Points, |
VarSetCapacity(PointF, 8*Points0)
Loop, %Points0%
{
StringSplit, Coord, Points%A_Index%, `,
NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
}
return DllCall("gdiplus\GdipDrawLines", "UPtr", pGraphics, "UPtr", pPen, "UPtr", &PointF, "int", Points0)
}
Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
{
return DllCall("gdiplus\GdipFillRectangle"
, "UPtr", pGraphics
, "UPtr", pBrush
, "float", x
, "float", y
, "float", w
, "float", h)
}
Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r)
{
Region := Gdip_GetClipRegion(pGraphics)
Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
E := Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
Gdip_SetClipRegion(pGraphics, Region, 0)
Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
Gdip_FillEllipse(pGraphics, pBrush, x, y, 2*r, 2*r)
Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y, 2*r, 2*r)
Gdip_FillEllipse(pGraphics, pBrush, x, y+h-(2*r), 2*r, 2*r)
Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
Gdip_SetClipRegion(pGraphics, Region, 0)
Gdip_DeleteRegion(Region)
return E
}
Gdip_FillPolygon(pGraphics, pBrush, Points, FillMode=0)
{
StringSplit, Points, Points, |
VarSetCapacity(PointF, 8*Points0)
Loop, %Points0%
{
StringSplit, Coord, Points%A_Index%, `,
NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
}
return DllCall("gdiplus\GdipFillPolygon", "UPtr", pGraphics, "UPtr", pBrush, "UPtr", &PointF, "int", Points0, "int", FillMode)
}
Gdip_FillPie(pGraphics, pBrush, x, y, w, h, StartAngle, SweepAngle)
{
return DllCall("gdiplus\GdipFillPie"
, "UPtr", pGraphics
, "UPtr", pBrush
, "float", x
, "float", y
, "float", w
, "float", h
, "float", StartAngle
, "float", SweepAngle)
}
Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h)
{
return DllCall("gdiplus\GdipFillEllipse", "UPtr", pGraphics, "UPtr", pBrush, "float", x, "float", y, "float", w, "float", h)
}
Gdip_FillRegion(pGraphics, pBrush, Region)
{
return DllCall("gdiplus\GdipFillRegion", "UPtr", pGraphics, "UPtr", pBrush, "UPtr", Region)
}
Gdip_FillPath(pGraphics, pBrush, Path)
{
return DllCall("gdiplus\GdipFillPath", "UPtr", pGraphics, "UPtr", pBrush, "UPtr", Path)
}
Gdip_DrawImagePointsRect(pGraphics, pBitmap, Points, sx="", sy="", sw="", sh="", Matrix=1)
{
StringSplit, Points, Points, |
VarSetCapacity(PointF, 8*Points0)
Loop, %Points0%
{
StringSplit, Coord, Points%A_Index%, `,
NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
}
if (Matrix&1 = "")
ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
else if (Matrix != 1)
ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
if (sx = "" && sy = "" && sw = "" && sh = "")
{
sx := 0, sy := 0
sw := Gdip_GetImageWidth(pBitmap)
sh := Gdip_GetImageHeight(pBitmap)
}
E := DllCall("gdiplus\GdipDrawImagePointsRect"
, "UPtr", pGraphics
, "UPtr", pBitmap
, "UPtr", &PointF
, "int", Points0
, "float", sx
, "float", sy
, "float", sw
, "float", sh
, "int", 2
, "UPtr", ImageAttr
, "UPtr", 0
, "UPtr", 0)
if ImageAttr
Gdip_DisposeImageAttributes(ImageAttr)
return E
}
Gdip_DrawImage(pGraphics, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", Matrix=1)
{
if (Matrix&1 = "")
ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
else if (Matrix != 1)
ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
if (sx = "" && sy = "" && sw = "" && sh = "")
{
if (dx = "" && dy = "" && dw = "" && dh = "")
{
sx := dx := 0, sy := dy := 0
sw := dw := Gdip_GetImageWidth(pBitmap)
sh := dh := Gdip_GetImageHeight(pBitmap)
}
else
{
sx := sy := 0
sw := Gdip_GetImageWidth(pBitmap)
sh := Gdip_GetImageHeight(pBitmap)
}
}
E := DllCall("gdiplus\GdipDrawImageRectRect"
, "UPtr", pGraphics
, "UPtr", pBitmap
, "float", dx
, "float", dy
, "float", dw
, "float", dh
, "float", sx
, "float", sy
, "float", sw
, "float", sh
, "int", 2
, "UPtr", ImageAttr
, "UPtr", 0
, "UPtr", 0)
if ImageAttr
Gdip_DisposeImageAttributes(ImageAttr)
return E
}
Gdip_SetImageAttributesColorMatrix(Matrix)
{
VarSetCapacity(ColourMatrix, 100, 0)
Matrix := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", "", 1), "[^\d-\.]+", "|")
StringSplit, Matrix, Matrix, |
Loop, 25
{
Matrix := (Matrix%A_Index% != "") ? Matrix%A_Index% : Mod(A_Index-1, 6) ? 0 : 1
NumPut(Matrix, ColourMatrix, (A_Index-1)*4, "float")
}
DllCall("gdiplus\GdipCreateImageAttributes", "UPtr*", ImageAttr)
DllCall("gdiplus\GdipSetImageAttributesColorMatrix", "UPtr", ImageAttr, "int", 1, "int", 1, "UPtr", &ColourMatrix, "UPtr", 0, "int", 0)
return ImageAttr
}
Gdip_GraphicsFromImage(pBitmap)
{
DllCall("gdiplus\GdipGetImageGraphicsContext", "UPtr", pBitmap, "UPtr*", pGraphics)
return pGraphics
}
Gdip_GraphicsFromHDC(hdc)
{
DllCall("gdiplus\GdipCreateFromHDC", "UPtr", hdc, "UPtr*", pGraphics)
return pGraphics
}
Gdip_GetDC(pGraphics)
{
DllCall("gdiplus\GdipGetDC", "UPtr", pGraphics, "UPtr*", hdc)
return hdc
}
Gdip_ReleaseDC(pGraphics, hdc)
{
return DllCall("gdiplus\GdipReleaseDC", "UPtr", pGraphics, "UPtr", hdc)
}
Gdip_GraphicsClear(pGraphics, ARGB=0x00ffffff)
{
return DllCall("gdiplus\GdipGraphicsClear", "UPtr", pGraphics, "int", ARGB)
}
Gdip_BlurBitmap(pBitmap, Blur)
{
if (Blur > 100) || (Blur < 1)
return -1
sWidth := Gdip_GetImageWidth(pBitmap), sHeight := Gdip_GetImageHeight(pBitmap)
dWidth := sWidth//Blur, dHeight := sHeight//Blur
pBitmap1 := Gdip_CreateBitmap(dWidth, dHeight)
G1 := Gdip_GraphicsFromImage(pBitmap1)
Gdip_SetInterpolationMode(G1, 7)
Gdip_DrawImage(G1, pBitmap, 0, 0, dWidth, dHeight, 0, 0, sWidth, sHeight)
Gdip_DeleteGraphics(G1)
pBitmap2 := Gdip_CreateBitmap(sWidth, sHeight)
G2 := Gdip_GraphicsFromImage(pBitmap2)
Gdip_SetInterpolationMode(G2, 7)
Gdip_DrawImage(G2, pBitmap1, 0, 0, sWidth, sHeight, 0, 0, dWidth, dHeight)
Gdip_DeleteGraphics(G2)
Gdip_DisposeImage(pBitmap1)
return pBitmap2
}
Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality=75)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
SplitPath, sOutput,,, Extension
if Extension not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
return -1
Extension := "." Extension
DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
VarSetCapacity(ci, nSize)
DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, Ptr, &ci)
if !(nCount && nSize)
return -2
If (A_IsUnicode){
StrGet_Name := "StrGet"
Loop, %nCount%
{
sString := %StrGet_Name%(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
if !InStr(sString, "*" Extension)
continue
pCodec := &ci+idx
break
}
} else {
Loop, %nCount%
{
Location := NumGet(ci, 76*(A_Index-1)+44)
nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
VarSetCapacity(sString, nSize)
DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "str", sString, "int", nSize, "uint", 0, "uint", 0)
if !InStr(sString, "*" Extension)
continue
pCodec := &ci+76*(A_Index-1)
break
}
}
if !pCodec
return -3
if (Quality != 75)
{
Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
if Extension in .JPG,.JPEG,.JPE,.JFIF
{
DllCall("gdiplus\GdipGetEncoderParameterListSize", Ptr, pBitmap, Ptr, pCodec, "uint*", nSize)
VarSetCapacity(EncoderParameters, nSize, 0)
DllCall("gdiplus\GdipGetEncoderParameterList", Ptr, pBitmap, Ptr, pCodec, "uint", nSize, Ptr, &EncoderParameters)
Loop, % NumGet(EncoderParameters, "UInt")
{
elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
{
p := elem+&EncoderParameters-pad-4
NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "UInt")), "UInt")
break
}
}
}
}
if (!A_IsUnicode)
{
nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sOutput, "int", -1, Ptr, 0, "int", 0)
VarSetCapacity(wOutput, nSize*2)
DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sOutput, "int", -1, Ptr, &wOutput, "int", nSize)
VarSetCapacity(wOutput, -1)
if !VarSetCapacity(wOutput)
return -4
E := DllCall("gdiplus\GdipSaveImageToFile", Ptr, pBitmap, Ptr, &wOutput, Ptr, pCodec, "uint", p ? p : 0)
}
else
E := DllCall("gdiplus\GdipSaveImageToFile", Ptr, pBitmap, Ptr, &sOutput, Ptr, pCodec, "uint", p ? p : 0)
return E ? -5 : 0
}
Gdip_GetPixel(pBitmap, x, y)
{
DllCall("gdiplus\GdipBitmapGetPixel", "UPtr", pBitmap, "int", x, "int", y, "uint*", ARGB)
return ARGB
}
Gdip_SetPixel(pBitmap, x, y, ARGB)
{
return DllCall("gdiplus\GdipBitmapSetPixel", "UPtr", pBitmap, "int", x, "int", y, "int", ARGB)
}
Gdip_GetImageWidth(pBitmap)
{
DllCall("gdiplus\GdipGetImageWidth", "UPtr", pBitmap, "uint*", Width)
return Width
}
Gdip_GetImageHeight(pBitmap)
{
DllCall("gdiplus\GdipGetImageHeight", "UPtr", pBitmap, "uint*", Height)
return Height
}
Gdip_GetImageDimensions(pBitmap, ByRef Width, ByRef Height)
{
DllCall("gdiplus\GdipGetImageWidth", "UPtr", pBitmap, "uint*", Width)
DllCall("gdiplus\GdipGetImageHeight", "UPtr", pBitmap, "uint*", Height)
}
Gdip_GetDimensions(pBitmap, ByRef Width, ByRef Height)
{
Gdip_GetImageDimensions(pBitmap, Width, Height)
}
Gdip_GetImagePixelFormat(pBitmap)
{
DllCall("gdiplus\GdipGetImagePixelFormat", "UPtr", pBitmap,"UPtr*", Format)
return Format
}
Gdip_GetDpiX(pGraphics)
{
DllCall("gdiplus\GdipGetDpiX", A_PtrSize ? "UPtr" : "uint", pGraphics, "float*", dpix)
return Round(dpix)
}
Gdip_GetDpiY(pGraphics)
{
DllCall("gdiplus\GdipGetDpiY", A_PtrSize ? "UPtr" : "uint", pGraphics, "float*", dpiy)
return Round(dpiy)
}
Gdip_GetImageHorizontalResolution(pBitmap)
{
DllCall("gdiplus\GdipGetImageHorizontalResolution", A_PtrSize ? "UPtr" : "uint", pBitmap, "float*", dpix)
return Round(dpix)
}
Gdip_GetImageVerticalResolution(pBitmap)
{
DllCall("gdiplus\GdipGetImageVerticalResolution", A_PtrSize ? "UPtr" : "uint", pBitmap, "float*", dpiy)
return Round(dpiy)
}
Gdip_BitmapSetResolution(pBitmap, dpix, dpiy)
{
return DllCall("gdiplus\GdipBitmapSetResolution", A_PtrSize ? "UPtr" : "uint", pBitmap, "float", dpix, "float", dpiy)
}
Gdip_CreateBitmapFromFile(sFile, IconNumber=1, IconSize="")
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
, PtrA := A_PtrSize ? "UPtr*" : "UInt*"
SplitPath, sFile,,, ext
if ext in exe,dll
{
Sizes := IconSize ? IconSize : 256 "|" 128 "|" 64 "|" 48 "|" 32 "|" 16
BufSize := 16 + (2*(A_PtrSize ? A_PtrSize : 4))
VarSetCapacity(buf, BufSize, 0)
Loop, Parse, Sizes, |
{
DllCall("PrivateExtractIcons", "str", sFile, "int", IconNumber-1, "int", A_LoopField, "int", A_LoopField, PtrA, hIcon, PtrA, 0, "uint", 1, "uint", 0)
if !hIcon
continue
if !DllCall("GetIconInfo", Ptr, hIcon, Ptr, &buf)
{
DestroyIcon(hIcon)
continue
}
hbmMask  := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4))
hbmColor := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4) + (A_PtrSize ? A_PtrSize : 4))
if !(hbmColor && DllCall("GetObject", Ptr, hbmColor, "int", BufSize, Ptr, &buf))
{
DestroyIcon(hIcon)
continue
}
break
}
if !hIcon
return -1
Width := NumGet(buf, 4, "int"), Height := NumGet(buf, 8, "int")
hbm := CreateDIBSection(Width, -Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
if !DllCall("DrawIconEx", Ptr, hdc, "int", 0, "int", 0, Ptr, hIcon, "uint", Width, "uint", Height, "uint", 0, Ptr, 0, "uint", 3)
{
DestroyIcon(hIcon)
return -2
}
VarSetCapacity(dib, 104)
DllCall("GetObject", Ptr, hbm, "int", A_PtrSize = 8 ? 104 : 84, Ptr, &dib)
Stride := NumGet(dib, 12, "Int"), Bits := NumGet(dib, 20 + (A_PtrSize = 8 ? 4 : 0))
DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", Stride, "int", 0x26200A, Ptr, Bits, PtrA, pBitmapOld)
pBitmap := Gdip_CreateBitmap(Width, Height)
G := Gdip_GraphicsFromImage(pBitmap)
, Gdip_DrawImage(G, pBitmapOld, 0, 0, Width, Height, 0, 0, Width, Height)
SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmapOld)
DestroyIcon(hIcon)
}
else
{
if (!A_IsUnicode)
{
VarSetCapacity(wFile, 1024)
DllCall("kernel32\MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sFile, "int", -1, Ptr, &wFile, "int", 512)
DllCall("gdiplus\GdipCreateBitmapFromFile", Ptr, &wFile, PtrA, pBitmap)
}
else
DllCall("gdiplus\GdipCreateBitmapFromFile", Ptr, &sFile, PtrA, pBitmap)
}
return pBitmap
}
Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette=0)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", Ptr, hBitmap, Ptr, Palette, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
return pBitmap
}
Gdip_CreateHBITMAPFromBitmap(pBitmap, Background=0xffffffff)
{
DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "uint*", hbm, "int", Background)
return hbm
}
Gdip_CreateBitmapFromHICON(hIcon)
{
DllCall("gdiplus\GdipCreateBitmapFromHICON", A_PtrSize ? "UPtr" : "UInt", hIcon, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
return pBitmap
}
Gdip_CreateHICONFromBitmap(pBitmap)
{
DllCall("gdiplus\GdipCreateHICONFromBitmap", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "uint*", hIcon)
return hIcon
}
Gdip_CreateBitmap(Width, Height, Format=0x26200A)
{
DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", 0, "int", Format, A_PtrSize ? "UPtr" : "UInt", 0, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
Return pBitmap
}
Gdip_CreateBitmapFromClipboard()
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
if !DllCall("OpenClipboard", Ptr, 0)
return -1
if !DllCall("IsClipboardFormatAvailable", "uint", 8)
return -2
if !hBitmap := DllCall("GetClipboardData", "uint", 2, Ptr)
return -3
if !pBitmap := Gdip_CreateBitmapFromHBITMAP(hBitmap)
return -4
if !DllCall("CloseClipboard")
return -5
DeleteObject(hBitmap)
return pBitmap
}
Gdip_SetBitmapToClipboard(pBitmap)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
off1 := A_PtrSize = 8 ? 52 : 44, off2 := A_PtrSize = 8 ? 32 : 24
hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
DllCall("GetObject", Ptr, hBitmap, "int", VarSetCapacity(oi, A_PtrSize = 8 ? 104 : 84, 0), Ptr, &oi)
hdib := DllCall("GlobalAlloc", "uint", 2, Ptr, 40+NumGet(oi, off1, "UInt"), Ptr)
pdib := DllCall("GlobalLock", Ptr, hdib, Ptr)
DllCall("RtlMoveMemory", Ptr, pdib, Ptr, &oi+off2, Ptr, 40)
DllCall("RtlMoveMemory", Ptr, pdib+40, Ptr, NumGet(oi, off2 - (A_PtrSize ? A_PtrSize : 4), Ptr), Ptr, NumGet(oi, off1, "UInt"))
DllCall("GlobalUnlock", Ptr, hdib)
DllCall("DeleteObject", Ptr, hBitmap)
DllCall("OpenClipboard", Ptr, 0)
DllCall("EmptyClipboard")
DllCall("SetClipboardData", "uint", 8, Ptr, hdib)
DllCall("CloseClipboard")
}
Gdip_CloneBitmapArea(pBitmap, x, y, w, h, Format=0x26200A)
{
DllCall("gdiplus\GdipCloneBitmapArea"
, "float", x
, "float", y
, "float", w
, "float", h
, "int", Format
, A_PtrSize ? "UPtr" : "UInt", pBitmap
, A_PtrSize ? "UPtr*" : "UInt*", pBitmapDest)
return pBitmapDest
}
Gdip_CreatePen(ARGB, w)
{
DllCall("gdiplus\GdipCreatePen1", "UInt", ARGB, "float", w, "int", 2, "UPtr*", pPen)
return pPen
}
Gdip_CreatePenFromBrush(pBrush, w)
{
DllCall("gdiplus\GdipCreatePen2", "UPtr", pBrush, "float", w, "int", 2, "UPtr*", pPen)
return pPen
}
Gdip_BrushCreateSolid(ARGB=0xff000000)
{
DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, "UPtr*", pBrush)
return pBrush
}
Gdip_BrushCreateHatch(ARGBfront, ARGBback, HatchStyle=0)
{
DllCall("gdiplus\GdipCreateHatchBrush", "int", HatchStyle, "UInt", ARGBfront, "UInt", ARGBback, A_PtrSize ? "UPtr*" : "UInt*", pBrush)
return pBrush
}
Gdip_CreateTextureBrush(pBitmap, WrapMode=1, x=0, y=0, w="", h="")
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
, PtrA := A_PtrSize ? "UPtr*" : "UInt*"
if !(w && h)
DllCall("gdiplus\GdipCreateTexture", Ptr, pBitmap, "int", WrapMode, PtrA, pBrush)
else
DllCall("gdiplus\GdipCreateTexture2", Ptr, pBitmap, "int", WrapMode, "float", x, "float", y, "float", w, "float", h, PtrA, pBrush)
return pBrush
}
Gdip_CreateLineBrush(x1, y1, x2, y2, ARGB1, ARGB2, WrapMode=1)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
CreatePointF(PointF1, x1, y1), CreatePointF(PointF2, x2, y2)
DllCall("gdiplus\GdipCreateLineBrush", Ptr, &PointF1, Ptr, &PointF2, "Uint", ARGB1, "Uint", ARGB2, "int", WrapMode, A_PtrSize ? "UPtr*" : "UInt*", LGpBrush)
return LGpBrush
}
Gdip_CreateLineBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode=1, WrapMode=1)
{
CreateRectF(RectF, x, y, w, h)
DllCall("gdiplus\GdipCreateLineBrushFromRect", A_PtrSize ? "UPtr" : "UInt", &RectF, "int", ARGB1, "int", ARGB2, "int", LinearGradientMode, "int", WrapMode, A_PtrSize ? "UPtr*" : "UInt*", LGpBrush)
return LGpBrush
}
Gdip_CloneBrush(pBrush)
{
DllCall("gdiplus\GdipCloneBrush", A_PtrSize ? "UPtr" : "UInt", pBrush, A_PtrSize ? "UPtr*" : "UInt*", pBrushClone)
return pBrushClone
}
Gdip_DeletePen(pPen)
{
return DllCall("gdiplus\GdipDeletePen", A_PtrSize ? "UPtr" : "UInt", pPen)
}
Gdip_DeleteBrush(pBrush)
{
return DllCall("gdiplus\GdipDeleteBrush", A_PtrSize ? "UPtr" : "UInt", pBrush)
}
Gdip_DisposeImage(pBitmap)
{
return DllCall("gdiplus\GdipDisposeImage", A_PtrSize ? "UPtr" : "UInt", pBitmap)
}
Gdip_DeleteGraphics(pGraphics)
{
return DllCall("gdiplus\GdipDeleteGraphics", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}
Gdip_DisposeImageAttributes(ImageAttr)
{
return DllCall("gdiplus\GdipDisposeImageAttributes", A_PtrSize ? "UPtr" : "UInt", ImageAttr)
}
Gdip_DeleteFont(hFont)
{
return DllCall("gdiplus\GdipDeleteFont", A_PtrSize ? "UPtr" : "UInt", hFont)
}
Gdip_DeleteStringFormat(hFormat)
{
return DllCall("gdiplus\GdipDeleteStringFormat", A_PtrSize ? "UPtr" : "UInt", hFormat)
}
Gdip_DeleteFontFamily(hFamily)
{
return DllCall("gdiplus\GdipDeleteFontFamily", A_PtrSize ? "UPtr" : "UInt", hFamily)
}
Gdip_DeleteMatrix(Matrix)
{
return DllCall("gdiplus\GdipDeleteMatrix", A_PtrSize ? "UPtr" : "UInt", Matrix)
}
Gdip_TextToGraphics(pGraphics, Text, Options, Font="Arial", Width="", Height="", Measure=0)
{
IWidth := Width, IHeight:= Height
RegExMatch(Options, "i)X([\-\d\.]+)(p*)", xpos)
RegExMatch(Options, "i)Y([\-\d\.]+)(p*)", ypos)
RegExMatch(Options, "i)W([\-\d\.]+)(p*)", Width)
RegExMatch(Options, "i)H([\-\d\.]+)(p*)", Height)
RegExMatch(Options, "i)C(?!(entre|enter))([a-f\d]+)", Colour)
RegExMatch(Options, "i)Top|Up|Bottom|Down|vCentre|vCenter", vPos)
RegExMatch(Options, "i)NoWrap", NoWrap)
RegExMatch(Options, "i)R(\d)", Rendering)
RegExMatch(Options, "i)S(\d+)(p*)", Size)
if !Gdip_DeleteBrush(Gdip_CloneBrush(Colour2))
PassBrush := 1, pBrush := Colour2
if !(IWidth && IHeight) && (xpos2 || ypos2 || Width2 || Height2 || Size2)
return -1
Style := 0, Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
Loop, Parse, Styles, |
{
if RegExMatch(Options, "i)\b" A_loopField)
Style |= (A_LoopField != "StrikeOut") ? (A_Index-1) : 8
}
Align := 0, Alignments := "Near|Left|Centre|Center|Far|Right"
Loop, Parse, Alignments, |
{
if RegExMatch(Options, "i)\b" A_loopField)
Align |= A_Index//2.1
}
xpos := (xpos1 != "") ? xpos2 ? IWidth*(xpos1/100) : xpos1 : 0
ypos := (ypos1 != "") ? ypos2 ? IHeight*(ypos1/100) : ypos1 : 0
Width := Width1 ? Width2 ? IWidth*(Width1/100) : Width1 : IWidth
Height := Height1 ? Height2 ? IHeight*(Height1/100) : Height1 : IHeight
if !PassBrush
Colour := "0x" (Colour2 ? Colour2 : "ff000000")
Rendering := ((Rendering1 >= 0) && (Rendering1 <= 5)) ? Rendering1 : 4
Size := (Size1 > 0) ? Size2 ? IHeight*(Size1/100) : Size1 : 12
hFamily := Gdip_FontFamilyCreate(Font)
hFont := Gdip_FontCreate(hFamily, Size, Style)
FormatStyle := NoWrap ? 0x4000 | 0x1000 : 0x4000
hFormat := Gdip_StringFormatCreate(FormatStyle)
pBrush := PassBrush ? pBrush : Gdip_BrushCreateSolid(Colour)
if !(hFamily && hFont && hFormat && pBrush && pGraphics)
return !pGraphics ? -2 : !hFamily ? -3 : !hFont ? -4 : !hFormat ? -5 : !pBrush ? -6 : 0
CreateRectF(RC, xpos, ypos, Width, Height)
Gdip_SetStringFormatAlign(hFormat, Align)
Gdip_SetTextRenderingHint(pGraphics, Rendering)
ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
if vPos
{
StringSplit, ReturnRC, ReturnRC, |
if (vPos = "vCentre") || (vPos = "vCenter")
ypos += (Height-ReturnRC4)//2
else if (vPos = "Top") || (vPos = "Up")
ypos := 0
else if (vPos = "Bottom") || (vPos = "Down")
ypos := Height-ReturnRC4
CreateRectF(RC, xpos, ypos, Width, ReturnRC4)
ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
}
if !Measure
E := Gdip_DrawString(pGraphics, Text, hFont, hFormat, pBrush, RC)
if !PassBrush
Gdip_DeleteBrush(pBrush)
Gdip_DeleteStringFormat(hFormat)
Gdip_DeleteFont(hFont)
Gdip_DeleteFontFamily(hFamily)
return E ? E : ReturnRC
}
Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, ByRef RectF)
{
if (!A_IsUnicode)
{
nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "UPtr", &sString, "int", -1, "UPtr", 0, "int", 0)
VarSetCapacity(wString, nSize*2)
DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "UPtr", &sString, "int", -1, "UPtr", &wString, "int", nSize)
}
return DllCall("gdiplus\GdipDrawString"
, "UPtr", pGraphics
, "UPtr", A_IsUnicode ? &sString : &wString
, "int", -1
, "UPtr", hFont
, "UPtr", &RectF
, "UPtr", hFormat
, "UPtr", pBrush)
}
Gdip_MeasureString(pGraphics, sString, hFont, hFormat, ByRef RectF)
{
VarSetCapacity(RC, 16)
if !A_IsUnicode
{
nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "UPtr", &sString, "int", -1, "uint", 0, "int", 0)
VarSetCapacity(wString, nSize*2)
DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "UPtr", &sString, "int", -1, "UPtr", &wString, "int", nSize)
}
DllCall("gdiplus\GdipMeasureString"
, "UPtr", pGraphics
, "UPtr", A_IsUnicode ? &sString : &wString
, "int", -1
, "UPtr", hFont
, "UPtr", &RectF
, "UPtr", hFormat
, "UPtr", &RC
, "uint*", Chars
, "uint*", Lines)
return &RC ? NumGet(RC, 0, "float") "|" NumGet(RC, 4, "float") "|" NumGet(RC, 8, "float") "|" NumGet(RC, 12, "float") "|" Chars "|" Lines : 0
}
Gdip_SetStringFormatAlign(hFormat, Align)
{
return DllCall("gdiplus\GdipSetStringFormatAlign", "UPtr", hFormat, "int", Align)
}
Gdip_StringFormatCreate(Format=0, Lang=0)
{
DllCall("gdiplus\GdipCreateStringFormat", "int", Format, "int", Lang, A_PtrSize ? "UPtr*" : "UInt*", hFormat)
return hFormat
}
Gdip_FontCreate(hFamily, Size, Style=0)
{
DllCall("gdiplus\GdipCreateFont", A_PtrSize ? "UPtr" : "UInt", hFamily, "float", Size, "int", Style, "int", 0, A_PtrSize ? "UPtr*" : "UInt*", hFont)
return hFont
}
Gdip_FontFamilyCreate(Font)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
if (!A_IsUnicode)
{
nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, "uint", 0, "int", 0)
VarSetCapacity(wFont, nSize*2)
DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, Ptr, &wFont, "int", nSize)
}
DllCall("gdiplus\GdipCreateFontFamilyFromName"
, Ptr, A_IsUnicode ? &Font : &wFont
, "uint", 0
, A_PtrSize ? "UPtr*" : "UInt*", hFamily)
return hFamily
}
Gdip_CreateAffineMatrix(m11, m12, m21, m22, x, y)
{
DllCall("gdiplus\GdipCreateMatrix2", "float", m11, "float", m12, "float", m21, "float", m22, "float", x, "float", y, A_PtrSize ? "UPtr*" : "UInt*", Matrix)
return Matrix
}
Gdip_CreateMatrix()
{
DllCall("gdiplus\GdipCreateMatrix", A_PtrSize ? "UPtr*" : "UInt*", Matrix)
return Matrix
}
Gdip_CreatePath(BrushMode=0)
{
DllCall("gdiplus\GdipCreatePath", "int", BrushMode, A_PtrSize ? "UPtr*" : "UInt*", Path)
return Path
}
Gdip_AddPathEllipse(Path, x, y, w, h)
{
return DllCall("gdiplus\GdipAddPathEllipse", A_PtrSize ? "UPtr" : "UInt", Path, "float", x, "float", y, "float", w, "float", h)
}
Gdip_AddPathPolygon(Path, Points)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
StringSplit, Points, Points, |
VarSetCapacity(PointF, 8*Points0)
Loop, %Points0%
{
StringSplit, Coord, Points%A_Index%, `,
NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
}
return DllCall("gdiplus\GdipAddPathPolygon", Ptr, Path, Ptr, &PointF, "int", Points0)
}
Gdip_DeletePath(Path)
{
return DllCall("gdiplus\GdipDeletePath", A_PtrSize ? "UPtr" : "UInt", Path)
}
Gdip_SetTextRenderingHint(pGraphics, RenderingHint)
{
return DllCall("gdiplus\GdipSetTextRenderingHint", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", RenderingHint)
}
Gdip_SetInterpolationMode(pGraphics, InterpolationMode)
{
return DllCall("gdiplus\GdipSetInterpolationMode", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", InterpolationMode)
}
Gdip_SetSmoothingMode(pGraphics, SmoothingMode)
{
return DllCall("gdiplus\GdipSetSmoothingMode", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", SmoothingMode)
}
Gdip_SetCompositingMode(pGraphics, CompositingMode=0)
{
return DllCall("gdiplus\GdipSetCompositingMode", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", CompositingMode)
}
Gdip_Startup()
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
if !DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
DllCall("LoadLibrary", "str", "gdiplus")
VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
DllCall("gdiplus\GdiplusStartup", A_PtrSize ? "UPtr*" : "uint*", pToken, Ptr, &si, Ptr, 0)
return pToken
}
Gdip_Shutdown(pToken)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
DllCall("gdiplus\GdiplusShutdown", Ptr, pToken)
if hModule := DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
DllCall("FreeLibrary", Ptr, hModule)
return 0
}
Gdip_RotateBitmap(pBitmap, Angle, Dispose=1)
{
Gdip_GetImageDimensions(pBitmap, Width, Height)
Gdip_GetRotatedDimensions(Width, Height, Angle, RWidth, RHeight)
Gdip_GetRotatedTranslation(Width, Height, Angle, xTranslation, yTranslation)
pBitmap2 := Gdip_CreateBitmap(RWidth, RHeight)
G2 := Gdip_GraphicsFromImage(pBitmap2), Gdip_SetSmoothingMode(G2, 4), Gdip_SetInterpolationMode(G2, 7)
Gdip_TranslateWorldTransform(G2, xTranslation, yTranslation)
Gdip_RotateWorldTransform(G2, Angle)
Gdip_DrawImage(G2, pBitmap, 0, 0, Width, Height)
Gdip_ResetWorldTransform(G2)
Gdip_DeleteGraphics(G2)
if Dispose
Gdip_DisposeImage(pBitmap)
return pBitmap2
}
Gdip_RotateWorldTransform(pGraphics, Angle, MatrixOrder=0)
{
return DllCall("gdiplus\GdipRotateWorldTransform", A_PtrSize ? "UPtr" : "UInt", pGraphics, "float", Angle, "int", MatrixOrder)
}
Gdip_ScaleWorldTransform(pGraphics, x, y, MatrixOrder=0)
{
return DllCall("gdiplus\GdipScaleWorldTransform", A_PtrSize ? "UPtr" : "UInt", pGraphics, "float", x, "float", y, "int", MatrixOrder)
}
Gdip_TranslateWorldTransform(pGraphics, x, y, MatrixOrder=0)
{
return DllCall("gdiplus\GdipTranslateWorldTransform", A_PtrSize ? "UPtr" : "UInt", pGraphics, "float", x, "float", y, "int", MatrixOrder)
}
Gdip_ResetWorldTransform(pGraphics)
{
return DllCall("gdiplus\GdipResetWorldTransform", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}
Gdip_GetRotatedTranslation(Width, Height, Angle, ByRef xTranslation, ByRef yTranslation)
{
pi := 3.14159, TAngle := Angle*(pi/180)
Bound := (Angle >= 0) ? Mod(Angle, 360) : 360-Mod(-Angle, -360)
if ((Bound >= 0) && (Bound <= 90))
xTranslation := Height*Sin(TAngle), yTranslation := 0
else if ((Bound > 90) && (Bound <= 180))
xTranslation := (Height*Sin(TAngle))-(Width*Cos(TAngle)), yTranslation := -Height*Cos(TAngle)
else if ((Bound > 180) && (Bound <= 270))
xTranslation := -(Width*Cos(TAngle)), yTranslation := -(Height*Cos(TAngle))-(Width*Sin(TAngle))
else if ((Bound > 270) && (Bound <= 360))
xTranslation := 0, yTranslation := -Width*Sin(TAngle)
}
Gdip_GetRotatedDimensions(Width, Height, Angle, ByRef RWidth, ByRef RHeight)
{
pi := 3.14159, TAngle := Angle*(pi/180)
if !(Width && Height)
return -1
RWidth := Ceil(Abs(Width*Cos(TAngle))+Abs(Height*Sin(TAngle)))
RHeight := Ceil(Abs(Width*Sin(TAngle))+Abs(Height*Cos(Tangle)))
}
Gdip_ImageRotateFlip(pBitmap, RotateFlipType=1)
{
return DllCall("gdiplus\GdipImageRotateFlip", A_PtrSize ? "UPtr" : "UInt", pBitmap, "int", RotateFlipType)
}
Gdip_SetClipRect(pGraphics, x, y, w, h, CombineMode=0)
{
return DllCall("gdiplus\GdipSetClipRect",  "UPtr", pGraphics, "float", x, "float", y, "float", w, "float", h, "int", CombineMode)
}
Gdip_SetClipPath(pGraphics, Path, CombineMode=0)
{
return DllCall("gdiplus\GdipSetClipPath", "UPtr", pGraphics, Ptr, Path, "int", CombineMode)
}
Gdip_ResetClip(pGraphics)
{
return DllCall("gdiplus\GdipResetClip", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}
Gdip_GetClipRegion(pGraphics)
{
Region := Gdip_CreateRegion()
DllCall("gdiplus\GdipGetClip", A_PtrSize ? "UPtr" : "UInt", pGraphics, "UInt*", Region)
return Region
}
Gdip_SetClipRegion(pGraphics, Region, CombineMode=0)
{
return DllCall("gdiplus\GdipSetClipRegion", "UPtr", pGraphics, "UPtr", Region, "int", CombineMode)
}
Gdip_CreateRegion()
{
DllCall("gdiplus\GdipCreateRegion", "UInt*", Region)
return Region
}
Gdip_DeleteRegion(Region)
{
return DllCall("gdiplus\GdipDeleteRegion", A_PtrSize ? "UPtr" : "UInt", Region)
}
Gdip_LockBits(pBitmap, x, y, w, h, ByRef Stride, ByRef Scan0, ByRef BitmapData, LockMode = 3, PixelFormat = 0x26200a)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
CreateRect(Rect, x, y, w, h)
VarSetCapacity(BitmapData, 16+2*(A_PtrSize ? A_PtrSize : 4), 0)
E := DllCall("Gdiplus\GdipBitmapLockBits", Ptr, pBitmap, Ptr, &Rect, "uint", LockMode, "int", PixelFormat, Ptr, &BitmapData)
Stride := NumGet(BitmapData, 8, "Int")
Scan0 := NumGet(BitmapData, 16, Ptr)
return E
}
Gdip_UnlockBits(pBitmap, ByRef BitmapData)
{
Ptr := A_PtrSize ? "UPtr" : "UInt"
return DllCall("Gdiplus\GdipBitmapUnlockBits", Ptr, pBitmap, Ptr, &BitmapData)
}
Gdip_SetLockBitPixel(ARGB, Scan0, x, y, Stride)
{
Numput(ARGB, Scan0+0, (x*4)+(y*Stride), "UInt")
}
Gdip_GetLockBitPixel(Scan0, x, y, Stride)
{
return NumGet(Scan0+0, (x*4)+(y*Stride), "UInt")
}
Gdip_PixelateBitmap(pBitmap, ByRef pBitmapOut, BlockSize)
{
static PixelateBitmap
Ptr := A_PtrSize ? "UPtr" : "UInt"
if (!PixelateBitmap)
{
if A_PtrSize != 8
MCode_PixelateBitmap =
		(LTrim Join
		558BEC83EC3C8B4514538B5D1C99F7FB56578BC88955EC894DD885C90F8E830200008B451099F7FB8365DC008365E000894DC88955F08945E833FF897DD4
		397DE80F8E160100008BCB0FAFCB894DCC33C08945F88945FC89451C8945143BD87E608B45088D50028BC82BCA8BF02BF2418945F48B45E02955F4894DC4
		8D0CB80FAFCB03CA895DD08BD1895DE40FB64416030145140FB60201451C8B45C40FB604100145FC8B45F40FB604020145F883C204FF4DE475D6034D18FF
		4DD075C98B4DCC8B451499F7F98945148B451C99F7F989451C8B45FC99F7F98945FC8B45F899F7F98945F885DB7E648B450C8D50028BC82BCA83C103894D
		C48BC82BCA41894DF48B4DD48945E48B45E02955E48D0C880FAFCB03CA895DD08BD18BF38A45148B7DC48804178A451C8B7DF488028A45FC8804178A45F8
		8B7DE488043A83C2044E75DA034D18FF4DD075CE8B4DCC8B7DD447897DD43B7DE80F8CF2FEFFFF837DF0000F842C01000033C08945F88945FC89451C8945
		148945E43BD87E65837DF0007E578B4DDC034DE48B75E80FAF4D180FAFF38B45088D500203CA8D0CB18BF08BF88945F48B45F02BF22BFA2955F48945CC0F
		B6440E030145140FB60101451C0FB6440F010145FC8B45F40FB604010145F883C104FF4DCC75D8FF45E4395DE47C9B8B4DF00FAFCB85C9740B8B451499F7
		F9894514EB048365140033F63BCE740B8B451C99F7F989451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB
		038975F88975E43BDE7E5A837DF0007E4C8B4DDC034DE48B75E80FAF4D180FAFF38B450C8D500203CA8D0CB18BF08BF82BF22BFA2BC28B55F08955CC8A55
		1488540E038A551C88118A55FC88540F018A55F888140183C104FF4DCC75DFFF45E4395DE47CA68B45180145E0015DDCFF4DC80F8594FDFFFF8B451099F7
		FB8955F08945E885C00F8E450100008B45EC0FAFC38365DC008945D48B45E88945CC33C08945F88945FC89451C8945148945103945EC7E6085DB7E518B4D
		D88B45080FAFCB034D108D50020FAF4D18034DDC8BF08BF88945F403CA2BF22BFA2955F4895DC80FB6440E030145140FB60101451C0FB6440F010145FC8B
		45F40FB604080145F883C104FF4DC875D8FF45108B45103B45EC7CA08B4DD485C9740B8B451499F7F9894514EB048365140033F63BCE740B8B451C99F7F9
		89451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB038975F88975103975EC7E5585DB7E468B4DD88B450C
		0FAFCB034D108D50020FAF4D18034DDC8BF08BF803CA2BF22BFA2BC2895DC88A551488540E038A551C88118A55FC88540F018A55F888140183C104FF4DC8
		75DFFF45108B45103B45EC7CAB8BC3C1E0020145DCFF4DCC0F85CEFEFFFF8B4DEC33C08945F88945FC89451C8945148945103BC87E6C3945F07E5C8B4DD8
		8B75E80FAFCB034D100FAFF30FAF4D188B45088D500203CA8D0CB18BF08BF88945F48B45F02BF22BFA2955F48945C80FB6440E030145140FB60101451C0F
		B6440F010145FC8B45F40FB604010145F883C104FF4DC875D833C0FF45108B4DEC394D107C940FAF4DF03BC874068B451499F7F933F68945143BCE740B8B
		451C99F7F989451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB038975F88975083975EC7E63EB0233F639
		75F07E4F8B4DD88B75E80FAFCB034D080FAFF30FAF4D188B450C8D500203CA8D0CB18BF08BF82BF22BFA2BC28B55F08955108A551488540E038A551C8811
		8A55FC88540F018A55F888140883C104FF4D1075DFFF45088B45083B45EC7C9F5F5E33C05BC9C21800
)
else
MCode_PixelateBitmap =
		(LTrim Join
		4489442418488954241048894C24085355565741544155415641574883EC28418BC1448B8C24980000004C8BDA99488BD941F7F9448BD0448BFA8954240C
		448994248800000085C00F8E9D020000418BC04533E4458BF299448924244C8954241041F7F933C9898C24980000008BEA89542404448BE889442408EB05
		4C8B5C24784585ED0F8E1A010000458BF1418BFD48897C2418450FAFF14533D233F633ED4533E44533ED4585C97E5B4C63BC2490000000418D040A410FAF
		C148984C8D441802498BD9498BD04D8BD90FB642010FB64AFF4403E80FB60203E90FB64AFE4883C2044403E003F149FFCB75DE4D03C748FFCB75D0488B7C
		24188B8C24980000004C8B5C2478418BC59941F7FE448BE8418BC49941F7FE448BE08BC59941F7FE8BE88BC69941F7FE8BF04585C97E4048639C24900000
		004103CA4D8BC1410FAFC94863C94A8D541902488BCA498BC144886901448821408869FF408871FE4883C10448FFC875E84803D349FFC875DA8B8C249800
		0000488B5C24704C8B5C24784183C20448FFCF48897C24180F850AFFFFFF8B6C2404448B2424448B6C24084C8B74241085ED0F840A01000033FF33DB4533
		DB4533D24533C04585C97E53488B74247085ED7E42438D0C04418BC50FAF8C2490000000410FAFC18D04814863C8488D5431028BCD0FB642014403D00FB6
		024883C2044403D80FB642FB03D80FB642FA03F848FFC975DE41FFC0453BC17CB28BCD410FAFC985C9740A418BC299F7F98BF0EB0233F685C9740B418BC3
		99F7F9448BD8EB034533DB85C9740A8BC399F7F9448BD0EB034533D285C9740A8BC799F7F9448BC0EB034533C033D24585C97E4D4C8B74247885ED7E3841
		8D0C14418BC50FAF8C2490000000410FAFC18D04814863C84A8D4431028BCD40887001448818448850FF448840FE4883C00448FFC975E8FFC2413BD17CBD
		4C8B7424108B8C2498000000038C2490000000488B5C24704503E149FFCE44892424898C24980000004C897424100F859EFDFFFF448B7C240C448B842480
		000000418BC09941F7F98BE8448BEA89942498000000896C240C85C00F8E3B010000448BAC2488000000418BCF448BF5410FAFC9898C248000000033FF33
		ED33F64533DB4533D24533C04585FF7E524585C97E40418BC5410FAFC14103C00FAF84249000000003C74898488D541802498BD90FB642014403D00FB602
		4883C2044403D80FB642FB03F00FB642FA03E848FFCB75DE488B5C247041FFC0453BC77CAE85C9740B418BC299F7F9448BE0EB034533E485C9740A418BC3
		99F7F98BD8EB0233DB85C9740A8BC699F7F9448BD8EB034533DB85C9740A8BC599F7F9448BD0EB034533D24533C04585FF7E4E488B4C24784585C97E3541
		8BC5410FAFC14103C00FAF84249000000003C74898488D540802498BC144886201881A44885AFF448852FE4883C20448FFC875E941FFC0453BC77CBE8B8C
		2480000000488B5C2470418BC1C1E00203F849FFCE0F85ECFEFFFF448BAC24980000008B6C240C448BA4248800000033FF33DB4533DB4533D24533C04585
		FF7E5A488B7424704585ED7E48418BCC8BC5410FAFC94103C80FAF8C2490000000410FAFC18D04814863C8488D543102418BCD0FB642014403D00FB60248
		83C2044403D80FB642FB03D80FB642FA03F848FFC975DE41FFC0453BC77CAB418BCF410FAFCD85C9740A418BC299F7F98BF0EB0233F685C9740B418BC399
		F7F9448BD8EB034533DB85C9740A8BC399F7F9448BD0EB034533D285C9740A8BC799F7F9448BC0EB034533C033D24585FF7E4E4585ED7E42418BCC8BC541
		0FAFC903CA0FAF8C2490000000410FAFC18D04814863C8488B442478488D440102418BCD40887001448818448850FF448840FE4883C00448FFC975E8FFC2
		413BD77CB233C04883C428415F415E415D415C5F5E5D5BC3
)
VarSetCapacity(PixelateBitmap, StrLen(MCode_PixelateBitmap)//2)
Loop % StrLen(MCode_PixelateBitmap)//2
NumPut("0x" SubStr(MCode_PixelateBitmap, (2*A_Index)-1, 2), PixelateBitmap, A_Index-1, "UChar")
DllCall("VirtualProtect", Ptr, &PixelateBitmap, Ptr, VarSetCapacity(PixelateBitmap), "uint", 0x40, A_PtrSize ? "UPtr*" : "UInt*", 0)
}
Gdip_GetImageDimensions(pBitmap, Width, Height)
if (Width != Gdip_GetImageWidth(pBitmapOut) || Height != Gdip_GetImageHeight(pBitmapOut))
return -1
if (BlockSize > Width || BlockSize > Height)
return -2
E1 := Gdip_LockBits(pBitmap, 0, 0, Width, Height, Stride1, Scan01, BitmapData1)
E2 := Gdip_LockBits(pBitmapOut, 0, 0, Width, Height, Stride2, Scan02, BitmapData2)
if (E1 || E2)
return -3
E := DllCall(&PixelateBitmap, Ptr, Scan01, Ptr, Scan02, "int", Width, "int", Height, "int", Stride1, "int", BlockSize)
Gdip_UnlockBits(pBitmap, BitmapData1), Gdip_UnlockBits(pBitmapOut, BitmapData2)
return 0
}
Gdip_ToARGB(A, R, G, B)
{
return (A << 24) | (R << 16) | (G << 8) | B
}
Gdip_FromARGB(ARGB, ByRef A, ByRef R, ByRef G, ByRef B)
{
A := (0xff000000 & ARGB) >> 24
R := (0x00ff0000 & ARGB) >> 16
G := (0x0000ff00 & ARGB) >> 8
B := 0x000000ff & ARGB
}
Gdip_AFromARGB(ARGB)
{
return (0xff000000 & ARGB) >> 24
}
Gdip_RFromARGB(ARGB)
{
return (0x00ff0000 & ARGB) >> 16
}
Gdip_GFromARGB(ARGB)
{
return (0x0000ff00 & ARGB) >> 8
}
Gdip_BFromARGB(ARGB)
{
return 0x000000ff & ARGB
}
StrGetB(Address, Length=-1, Encoding=0)
{
if Length is not integer
Encoding := Length,  Length := -1
if (Address+0 < 1024)
return
if Encoding = UTF-16
Encoding = 1200
else if Encoding = UTF-8
Encoding = 65001
else if SubStr(Encoding,1,2)="CP"
Encoding := SubStr(Encoding,3)
if !Encoding
{
if (Length == -1)
Length := DllCall("lstrlen", "uint", Address)
VarSetCapacity(String, Length)
DllCall("lstrcpyn", "str", String, "uint", Address, "int", Length + 1)
}
else if Encoding = 1200
{
char_count := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0x400, "uint", Address, "int", Length, "uint", 0, "uint", 0, "uint", 0, "uint", 0)
VarSetCapacity(String, char_count)
DllCall("WideCharToMultiByte", "uint", 0, "uint", 0x400, "uint", Address, "int", Length, "str", String, "int", char_count, "uint", 0, "uint", 0)
}
else if Encoding is integer
{
char_count := DllCall("MultiByteToWideChar", "uint", Encoding, "uint", 0, "uint", Address, "int", Length, "uint", 0, "int", 0)
VarSetCapacity(String, char_count * 2)
char_count := DllCall("MultiByteToWideChar", "uint", Encoding, "uint", 0, "uint", Address, "int", Length, "uint", &String, "int", char_count * 2)
String := StrGetB(&String, char_count, 1200)
}
return String
}
SetImageX(hCtrl, hBM)
{
hdcSrc  := DllCall( "CreateCompatibleDC", UInt,0 )
hdcDst  := DllCall( "GetDC", UInt,hCtrl )
VarSetCapacity( bm,24,0 )
DllCall( "GetObject", UInt,hbm, UInt,24, UInt,&bm )
w := Numget( bm,4 ), h := Numget( bm,8 )
hbmOld  := DllCall( "SelectObject", UInt,hdcSrc, UInt,hBM )
hbmNew  := DllCall( "CreateBitmap", Int,w, Int,h, UInt,NumGet( bm,16,"UShort" )
, UInt,NumGet( bm,18,"UShort" ), Int,0 )
hbmOld2 := DllCall( "SelectObject", UInt,hdcDst, UInt,hbmNew )
DllCall( "BitBlt", UInt,hdcDst, Int,0, Int,0, Int,w, Int,h
, UInt,hdcSrc, Int,0, Int,0, UInt,0x00CC0020 )
DllCall( "SelectObject", UInt,hdcSrc, UInt,hbmOld )
DllCall( "DeleteDC",  UInt,hdcSrc ),   DllCall( "ReleaseDC", UInt,hCtrl, UInt,hdcDst )
DllCall( "SendMessage", UInt,hCtrl, UInt,0x0B, UInt,0, UInt,0 )
oBM := DllCall( "SendMessage", UInt,hCtrl, UInt,0x172, UInt,0, UInt,hBM )
DllCall( "SendMessage", UInt,hCtrl, UInt,0x0B, UInt,1, UInt,0 )
DllCall( "DeleteObject", UInt,oBM )
}
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
Loop % StrLen(MCode_AlphaMask)//2
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
Global B_LocalCharacterNameID
, B_LocalPlayerSlot
, B_pStructure
, S_pStructure
, O_pStatus
, O_pXcam
, O_pCamDistance
, O_pCamAngle
, O_pCamRotation
, O_pYcam
, O_pTeam
, O_pType
, O_pVictoryStatus
, O_pName
, O_pRacePointer
, O_pColour
, O_pAccountID
, O_pAPM
, O_pEPM
, O_pWorkerCount
, O_pWorkersBuilt
, O_pHighestWorkerCount
, O_pBaseCount
, O_pSupplyCap
, O_pSupply
, O_pMinerals
, O_pGas
, O_pArmySupply
, O_pMineralIncome
, O_pGasIncome
, O_pArmyMineralSize
, O_pArmyGasSize
, P_IdleWorker
, O1_IdleWorker
, O2_IdleWorker
, B_Timer
, B_rStructure
, S_rStructure
, P_ChatFocus
, O1_ChatFocus
, O2_ChatFocus
, P_MenuFocus
, O1_MenuFocus
, P_SocialMenu
, B_uCount
, B_uHighestIndex
, B_uStructure
, S_uStructure
, O_uModelPointer
, O_uTargetFilter
, O_uBuildStatus
, O_XelNagaActive
, O_uOwner
, O_uX
, O_uY
, O_uZ
, O_uDestinationX
, O_uDestinationY
, O_P_uCmdQueuePointer
, O_P_uAbilityPointer
, O_uChronoState
, O_uInjectState
, O_uBuffPointer
, O_uHpDamage
, O_uShieldDamage
, O_uEnergy
, O_uTimer
, O_cqState
, O_mUnitID
, O_mSubgroupPriority
, O_mMiniMapSize
, B_SelectionStructure
, B_CtrlGroupOneStructure
, S_CtrlGroup
, S_scStructure
, O_scTypeCount
, O_scTypeHighlighted
, O_scUnitIndex
, B_localArmyUnitCount
, O1_localArmyUnitCount
, O2_localArmyUnitCount
, B_TeamColours
, P_SelectionPage
, O1_SelectionPage
, O2_SelectionPage
, O3_SelectionPage
, DeadFilterFlag
, BuriedFilterFlag
, B_MapStruct
, O_mLeft
, O_mBottom
, O_mRight
, O_mTop
, aUnitMoveStates
, B_UnitCursor
, O1_UnitCursor
, O2_UnitCursor
, P_IsUserPerformingAction
, O1_IsUserPerformingAction
, P_IsBuildCardDisplayed
, 01_IsBuildCardDisplayed
, 02_IsBuildCardDisplayed
, 03_IsBuildCardDisplayed
, P_ChatInput
, O1_ChatInput
, O2_ChatInput
, O3_ChatInput
, O4_ChatInput
, B_CameraDragScroll
, B_InputStructure
, B_iMouseButtons
, B_iSpace
, B_iNums
, B_iChars
, B_iTilda
, B_iNonAlphNumChars
, B_iNonCharKeys
, B_iFkeys
, B_iModifiers
, B_CameraMovingViaMouseAtScreenEdge
, 01_CameraMovingViaMouseAtScreenEdge
, 02_CameraMovingViaMouseAtScreenEdge
, 03_CameraMovingViaMouseAtScreenEdge
, B_IsGamePaused
, B_FramesPerSecond
, B_Gamespeed
, B_ReplayFolder
, B_HorizontalResolution
, B_VerticalResolution
global aUnitModel := []
, aStringTable := []
, aMiniMapUnits := []
loadMemoryAddresses(base, version := "")
{
if (version = "2.1.0.28667")
{
versionMatch := "2.1.0.28667"
B_LocalCharacterNameID := base + 0x04F0918C
B_LocalPlayerSlot := base + 0x112D5F0
B_ReplayWatchedPlayer := B_LocalPlayerSlot + 0x1
B_pStructure := base + 0x035EF0E8
S_pStructure := 0xE10
O_pStatus := 0x0
O_pXcam := 0x8
O_pYcam := 0xC
O_pCamDistance := 0x10
O_pCamAngle := 0x14
O_pCamRotation := 0x18
O_pTeam := 0x1C
O_pType := 0x1D
O_pVictoryStatus := 0x1E
O_pName := 0x60
O_pRacePointer := 0x158
O_pColour := 0x1B0
O_pAccountID := 0x1C0
O_pAPM := 0x5E8
O_pEPM := 0x5D8
O_pWorkerCount := 0x7D8
O_pTotalUnitsBuilt := 0x658
O_pWorkersBuilt := 0x7E8
O_pHighestWorkerCount := 0x800
O_pBaseCount := 0x848
O_pSupplyCap := 0x898
O_pSupply := 0x8B0
O_pMinerals := 0x8F0
O_pGas := 0x8F8
O_pArmySupply := 0x8D0
O_pMineralIncome := 0x970
O_pGasIncome := 0x978
O_pArmyMineralSize := 0xC58
O_pArmyGasSize := 0xC80
P_IdleWorker := base + 0x0310E870
O1_IdleWorker := 0x358
O2_IdleWorker := 0x244
B_Timer := base + 0x353C41C
B_rStructure := base + 0x02F6C850
S_rStructure := 0x10
P_ChatFocus := base + 0x0310E870
O1_ChatFocus := 0x394
O2_ChatFocus := 0x174
P_MenuFocus := base + 0x04FEF2F4
O1_MenuFocus := 0x17C
P_SocialMenu := base + 0x0409B098
B_uCount := base + 0x366CAE8
B_uHighestIndex := base + 0x366CB00
B_uStructure := base + 0x366CB40
S_uStructure := 0x1C0
O_uModelPointer := 0x8
O_uTargetFilter := 0x14
O_uBuildStatus := 0x18
O_XelNagaActive := 0x34
O_uOwner := 0x41
O_uX := 0x4C
O_uY := 0x50
O_uZ := 0x54
O_uDestinationX := 0x80
O_uDestinationY := 0x84
O_P_uCmdQueuePointer := 0xD4
O_P_uAbilityPointer := 0xDC
O_uChronoState := 0xE6
O_uInjectState := 0xE7
O_uHpDamage := 0x114
O_uShieldDamage := 0x118
O_uEnergy := 0x11c
O_uTimer := 0x16C
O_cqState := 0x40
O_mUnitID := 0x6
O_mSubgroupPriority := 0x3A8
O_mMiniMapSize := 0x3AC
B_SelectionStructure := base + 0x31D2048
B_CtrlGroupOneStructure := base + 0x031D7270
S_CtrlGroup := 0x1B60
S_scStructure := 0x4
O_scTypeCount := 0x2
O_scTypeHighlighted := 0x4
O_scUnitIndex := 0x8
B_localArmyUnitCount := base + 0x0310E870
O1_localArmyUnitCount := 0x354
O2_localArmyUnitCount := 0x248
B_TeamColours := base + 0x310F9BC
P_SelectionPage := base + 0x0310E870
O1_SelectionPage := 0x320
O2_SelectionPage := 0x15C
O3_SelectionPage := 0x14C
DeadFilterFlag := 0x0000000200000000
BuriedFilterFlag := 0x0000000010000000
B_MapStruct := base + 0x353C3B4
O_mLeft := B_MapStruct + 0xDC
O_mBottom := B_MapStruct + 0xE0
O_mRight := B_MapStruct + 0xE4
O_mTop := B_MapStruct + 0xE8
aUnitMoveStates := { Idle: -1
, Amove: 0
, Patrol: 1
, HoldPosition: 2
, Move: 256
, Follow: 512
, FollowNoAttack: 515}
B_UnitCursor :=	base + 0x0310E870
O1_UnitCursor := 0x2C0
O2_UnitCursor := 0x21C
P_IsUserPerformingAction := base + 0x0310E870
O1_IsUserPerformingAction := 0x230
P_IsBuildCardDisplayed := base + 0x0312226C
01_IsBuildCardDisplayed := 0x7C
02_IsBuildCardDisplayed := 0x74
03_IsBuildCardDisplayed := 0x398
P_ChatInput := base + 0x0310EDEC
O1_ChatInput := 0x16C
O2_ChatInput := 0xC
O3_ChatInput := 0x278
O4_ChatInput := 0x0
B_CameraDragScroll := base + 0x30518F0
B_InputStructure := base + 0x3051C00
B_iMouseButtons := B_InputStructure + 0x0
B_iSpace := B_iMouseButtons + 0x8
B_iNums := B_iSpace + 0x2
B_iChars := B_iNums + 0x2
B_iTilda := B_iChars + 0x4
B_iNonAlphNumChars := B_iTilda + 0x2
B_iNonCharKeys := B_iNonAlphNumChars + 0x2
B_iFkeys := B_iNonCharKeys + 0x2
B_iModifiers := B_iFkeys + 0x6
B_CameraMovingViaMouseAtScreenEdge := base + 0x0310E870
01_CameraMovingViaMouseAtScreenEdge	:= 0x2C0
02_CameraMovingViaMouseAtScreenEdge	:= 0x20C
03_CameraMovingViaMouseAtScreenEdge	:= 0x5A4
B_IsGamePaused := base + 0x31F8A5D
B_FramesPerSecond := base + 0x04FA80EC
B_Gamespeed  := base + 0x4EF35B8
B_ReplayFolder :=  base + 0x04F701F8
B_HorizontalResolution := base + 0x4FEEDA8
B_VerticalResolution := B_HorizontalResolution + 0x4
P1_CurrentBaseCam := 0x25C
}
else
{
if (version = "2.1.1.29261")
versionMatch := "2.1.1.29261"
else if (version = "2.1.2.30315")
versionMatch := "2.1.2.30315"
else if (version = "2.1.3.30508" || !version)
versionMatch := "2.1.3.30508"
else versionMatch := false
B_LocalCharacterNameID := base + 0x04F15C14
B_LocalPlayerSlot := base + 0x112E5F0
B_ReplayWatchedPlayer := B_LocalPlayerSlot + 0x1
B_pStructure := base + 0x35F55A8
S_pStructure := 0xE10
O_pStatus := 0x0
O_pXcam := 0x8
O_pYcam := 0xC
O_pCamDistance := 0x10
O_pCamAngle := 0x14
O_pCamRotation := 0x18
O_pTeam := 0x1C
O_pType := 0x1D
O_pVictoryStatus := 0x1E
O_pName := 0x60
O_pRacePointer := 0x158
O_pColour := 0x1B0
O_pAccountID := 0x1C0
O_pAPM := 0x5E8
O_pEPM := 0x5D8
O_pWorkerCount := 0x7D8
O_pTotalUnitsBuilt := 0x658
O_pWorkersBuilt := 0x7E8
O_pHighestWorkerCount := 0x800
O_pBaseCount := 0x848
O_pSupplyCap := 0x898
O_pSupply := 0x8B0
O_pMinerals := 0x8F0
O_pGas := 0x8F8
O_pArmySupply := 0x8D0
O_pMineralIncome := 0x970
O_pGasIncome := 0x978
O_pArmyMineralSize := 0xC58
O_pArmyGasSize := 0xC80
P_IdleWorker := base + 0x03114D30
O1_IdleWorker := 0x358
O2_IdleWorker := 0x244
B_Timer := base + 0x35428DC
B_rStructure := base + 0x02F6C850
S_rStructure := 0x10
P_ChatFocus := base + 0x03114D30
O1_ChatFocus := 0x394
O2_ChatFocus := 0x174
P_MenuFocus := base + 0x04FFA324
O1_MenuFocus := 0x17C
P_SocialMenu := base + 0x0409B098
B_uCount := base + 0x3672FA8
B_uHighestIndex := base + 0x3672FC0
B_uStructure := base + 0x3673000
S_uStructure := 0x1C0
O_uModelPointer := 0x8
O_uTargetFilter := 0x14
O_uBuildStatus := 0x18
O_XelNagaActive := 0x34
O_uOwner := 0x41
O_uX := 0x4C
O_uY := 0x50
O_uZ := 0x54
O_uDestinationX := 0x80
O_uDestinationY := 0x84
O_P_uCmdQueuePointer := 0xD4
O_P_uAbilityPointer := 0xDC
O_uChronoState := 0xE6
O_uInjectState := 0xE7
O_uBuffPointer := 0xEC
O_uHpDamage := 0x114
O_uShieldDamage := 0x118
O_uEnergy := 0x11c
O_uTimer := 0x16C
O_cqState := 0x40
O_mUnitID := 0x6
O_mSubgroupPriority := 0x3A8
O_mMiniMapSize := 0x3AC
B_SelectionStructure := base + 0x31D8508
B_CtrlGroupOneStructure := base + 0x31DD730
S_CtrlGroup := 0x1B60
S_scStructure := 0x4
O_scTypeCount := 0x2
O_scTypeHighlighted := 0x4
O_scUnitIndex := 0x8
B_localArmyUnitCount := base + 0x03114D30
O1_localArmyUnitCount := 0x354
O2_localArmyUnitCount := 0x248
B_TeamColours := base + 0x3115E7C
P_SelectionPage := base + 0x03114D30
O1_SelectionPage := 0x320
O2_SelectionPage := 0x15C
O3_SelectionPage := 0x14C
DeadFilterFlag := 0x0000000200000000
BuriedFilterFlag := 0x0000000010000000
B_MapStruct := base + 0x3542874
O_mLeft := B_MapStruct + 0xDC
O_mBottom := B_MapStruct + 0xE0
O_mRight := B_MapStruct + 0xE4
O_mTop := B_MapStruct + 0xE8
aUnitMoveStates := { Idle: -1
, Amove: 0
, Patrol: 1
, HoldPosition: 2
, Move: 256
, Follow: 512
, FollowNoAttack: 515}
B_UnitCursor :=	base + 0x03114D30
O1_UnitCursor := 0x2C0
O2_UnitCursor := 0x21C
P_IsUserPerformingAction := base + 0x03114D30
O1_IsUserPerformingAction := 0x230
P_IsBuildCardDisplayed := base + 0x0312872C
01_IsBuildCardDisplayed := 0x7C
02_IsBuildCardDisplayed := 0x74
03_IsBuildCardDisplayed := 0x398
P_ChatInput := base + 0x0310EDEC
O1_ChatInput := 0x16C
O2_ChatInput := 0xC
O3_ChatInput := 0x278
O4_ChatInput := 0x0
B_CameraDragScroll := base + 0x3057DB0
B_InputStructure := base + 0x30580C0
B_iMouseButtons := B_InputStructure + 0x0
B_iSpace := B_iMouseButtons + 0x8
B_iNums := B_iSpace + 0x2
B_iChars := B_iNums + 0x2
B_iTilda := B_iChars + 0x4
B_iNonAlphNumChars := B_iTilda + 0x2
B_iNonCharKeys := B_iNonAlphNumChars + 0x2
B_iFkeys := B_iNonCharKeys + 0x2
B_iModifiers := B_iFkeys + 0x6
B_CameraMovingViaMouseAtScreenEdge := base + 0x03114D30
01_CameraMovingViaMouseAtScreenEdge := 0x2C0
02_CameraMovingViaMouseAtScreenEdge := 0x20C
03_CameraMovingViaMouseAtScreenEdge := 0x5A4
B_IsGamePaused := base + 0x31FEF1D
B_FramesPerSecond := base + 0x04FBD484
B_Gamespeed  := base + 0x4EFE5E8
B_ReplayFolder :=  base + 0x4F7B228
B_HorizontalResolution := base + 0x4FF9DD8
B_VerticalResolution := B_HorizontalResolution + 0x4
}
return versionMatch
}
getMapLeft()
{	global
return ReadMemory(O_mLeft, GameIdentifier) / 4096
}
getMapBottom()
{	global
return ReadMemory(O_mBottom, GameIdentifier) / 4096
}
getMapRight()
{	global
return ReadMemory(O_mRight, GameIdentifier) / 4096
}
getMapTop()
{	global
return ReadMemory(O_mTop, GameIdentifier) / 4096
}
IsInControlGroup(group, unitIndex)
{
count := getControlGroupCount(Group)
ReadRawMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (group - 1), GameIdentifier, Memory,  O_scUnitIndex + count * S_scStructure)
loop, % count
{
if (unitIndex = (NumGet(Memory, O_scUnitIndex + (A_Index - 1) * S_scStructure, "UInt") >> 18))
Return 1
}
Return 0
}
numgetControlGroupMemory(BYREF MemDump, group)
{
if count := getControlGroupCount(Group)
ReadRawMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (group - 1) + O_scUnitIndex, GameIdentifier, MemDump, count * S_scStructure)
return count
}
getCtrlGroupedUnitIndex(group, i=0)
{	global
Return ReadMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (group - 1) + O_scUnitIndex + i * S_scStructure, GameIdentifier) >> 18
}
getControlGroupCount(Group)
{	global
Return	ReadMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (Group - 1), GameIdentifier, 2)
}
getTime()
{	global
Return Round(ReadMemory(B_Timer, GameIdentifier)/4096, 1)
}
getGameTickCount()
{	global
Return ReadMemory(B_Timer, GameIdentifier)
}
ReadRawUnit(unit, ByRef Memory)
{	GLOBAL
ReadRawMemory(B_uStructure + unit * S_uStructure, GameIdentifier, Memory, S_uStructure)
return
}
getSelectedUnitIndex(i=0)
{	global
Return ReadMemory(B_SelectionStructure + O_scUnitIndex + i * S_scStructure, GameIdentifier) >> 18
}
getSelectionTypeCount()
{	global
Return	ReadMemory(B_SelectionStructure + O_scTypeCount, GameIdentifier, 2)
}
getSelectionHighlightedGroup()
{	global
Return ReadMemory(B_SelectionStructure + O_scTypeHighlighted, GameIdentifier, 2)
}
getSelectionCount()
{ 	global
Return ReadMemory(B_SelectionStructure, GameIdentifier, 2)
}
getIdleWorkers()
{	global
return pointer(GameIdentifier, P_IdleWorker, O1_IdleWorker, O2_IdleWorker)
}
getPlayerSupply(player="")
{ global
If (player = "")
player := aLocalPlayer["Slot"]
Return round(ReadMemory(((B_pStructure + O_pSupply) + (player-1)*S_pStructure), GameIdentifier)  / 4096)
}
getPlayerSupplyCap(player="")
{ 	Local SupplyCap
If (player = "")
player := aLocalPlayer["Slot"]
SupplyCap := round(ReadMemory(((B_pStructure + O_pSupplyCap) + (player-1)*S_pStructure), GameIdentifier)  / 4096)
if (SupplyCap > 200)
return 200
else return SupplyCap
}
getPlayerSupplyCapTotal(player="")
{ 	GLOBAL
If (player = "")
player := aLocalPlayer["Slot"]
Return round(ReadMemory(((B_pStructure + O_pSupplyCap) + (player-1)*S_pStructure), GameIdentifier)  / 4096)
}
getPlayerWorkerCount(player="")
{ global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(((B_pStructure + O_pWorkerCount) + (player-1)*S_pStructure), GameIdentifier)
}
getPlayerWorkersBuilt(player="")
{ global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(((B_pStructure + O_pWorkersBuilt) + (player-1)*S_pStructure), GameIdentifier)
}
getPlayerWorkersLost(player="")
{ 	global aLocalPlayer
If (player = "")
player := aLocalPlayer["Slot"]
return getPlayerWorkersBuilt() - getPlayerWorkerCount()
}
getPlayerHighestWorkerCount(player="")
{ global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + O_pHighestWorkerCount + (player-1)*S_pStructure, GameIdentifier)
}
getUnitType(Unit)
{ global
LOCAL pUnitModel := ReadMemory(B_uStructure + (Unit * S_uStructure) + O_uModelPointer, GameIdentifier)
if !aUnitModel[pUnitModel]
getUnitModelInfo(pUnitModel)
return aUnitModel[pUnitModel].Type
}
getUnitName2(unit)
{	global
Return substr(ReadMemory_Str(ReadMemory(ReadMemory(((ReadMemory(B_uStructure + (Unit * S_uStructure)
+ O_uModelPointer, GameIdentifier)) << 5) + 0xC, GameIdentifier), GameIdentifier) + 0x29, GameIdentifier), 6)
}
getUnitName(unit)
{
mp := ReadMemory(B_uStructure + Unit * S_uStructure + O_uModelPointer, GameIdentifier) << 5
pNameDataAddress := ReadMemory(mp + 0xC, GameIdentifier)
pNameDataAddress := ReadMemory(pNameDataAddress, GameIdentifier)
NameDataAddress := ReadMemory(pNameDataAddress, GameIdentifier)
return substr(ReadMemory_Str(NameDataAddress + 0x20, GameIdentifier), 11)
}
getUnitOwner(Unit)
{ 	global
Return	ReadMemory((B_uStructure + (Unit * S_uStructure)) + O_uOwner, GameIdentifier, 1)
}
getMiniMapRadius(Unit)
{
LOCAL pUnitModel := ReadMemory(B_uStructure + (Unit * S_uStructure) + O_uModelPointer, GameIdentifier)
if !aUnitModel[pUnitModel]
getUnitModelInfo(pUnitModel)
return aUnitModel[pUnitModel].MiniMapRadius
}
getUnitCount()
{	global
return ReadMemory(B_uCount, GameIdentifier)
}
getHighestUnitIndex()
{	global
Return ReadMemory(B_uHighestIndex, GameIdentifier)
}
getPlayerName(i)
{	global
Return ReadMemory_Str(B_pStructure + O_pName + (i-1) * S_pStructure, GameIdentifier)
}
getPlayerRace(i)
{	global
local Race
Race := ReadMemory_Str(ReadMemory(ReadMemory(B_pStructure + O_pRacePointer + (i-1)*S_pStructure, GameIdentifier) + 4, GameIdentifier), GameIdentifier)
If (Race == "Terr")
Race := "Terran"
Else if (Race == "Prot")
Race := "Protoss"
Else If (Race == "Zerg")
Race := "Zerg"
Else If (Race == "Neut")
Race := "Neutral"
Else
Race := "Race Error"
Return Race
}
getPlayerType(i)
{	global
static oPlayerType := {	  0: "None"
, 1: "User"
, 2: "Computer"
, 3: "Neutral"
, 4: "Hostile"
, 5: "Referee"
, 6: "Spectator" }
Return oPlayerType[ ReadMemory((B_pStructure + O_pType) + (i-1) * S_pStructure, GameIdentifier, 1) ]
}
getPlayerVictoryStatus(i)
{	global
static oPlayerStatus := {	  0: "Playing"
, 1: "Victorious"
, 2: "Defeated"
, 3: "Tied" }
Return oPlayerStatus[ ReadMemory((B_pStructure + O_pVictoryStatus) + (i-1) * S_pStructure, GameIdentifier, 1) ]
}
isPlayerActive(player)
{
Return (ReadMemory((B_pStructure + O_pStatus) + (player-1) * S_pStructure, GameIdentifier, 1) & 1)
}
getPlayerTeam(player="")
{	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory((B_pStructure + O_pTeam) + (player-1) * S_pStructure, GameIdentifier, 1)
}
getPlayerColour(i)
{	static aPlayerColour
if !isObject(aPlayerColour)
{
aPlayerColour := []
Colour_List := "White|Red|Blue|Teal|Purple|Yellow|Orange|Green|Light Pink|Violet|Light Grey|Dark Green|Brown|Light Green|Dark Grey|Pink"
Loop, Parse, Colour_List, |
aPlayerColour[a_index - 1] := A_LoopField
}
Return aPlayerColour[ReadMemory((B_pStructure + O_pColour) + (i-1) * S_pStructure, GameIdentifier)]
}
getLocalPlayerNumber()
{	global
Return ReadMemory(B_LocalPlayerSlot, GameIdentifier, 1)
}
getBaseCameraCount(player="")
{ 	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory((B_pStructure + O_pBaseCount) + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerMineralIncome(player="")
{ 	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + O_pMineralIncome + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerGasIncome(player="")
{ 	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + O_pGasIncome + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerArmySupply(player="")
{ 	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + O_pArmySupply + (player-1) * S_pStructure, GameIdentifier) / 4096
}
getPlayerArmySizeMinerals(player="")
{ 	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + O_pArmyMineralSize + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerArmySizeGas(player="")
{ 	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + O_pArmyGasSize + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerMinerals(player="")
{ 	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + O_pMinerals + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerGas(player="")
{ 	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + O_pGas + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerCameraPositionX(Player="")
{	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pXcam, GameIdentifier) / 4096
}
getPlayerCameraPositionY(Player="")
{	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pYcam, GameIdentifier) / 4096
}
getPlayerCameraDistance(Player="")
{	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pCamDistance, GameIdentifier) / 4096
}
getPlayerCameraAngle(Player="")
{	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pCamAngle, GameIdentifier) / 4096
}
getPlayerCameraRotation(Player="")
{	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pCamRotation, GameIdentifier) / 4096
}
getPlayerCurrentAPM(Player="")
{	global
If (player = "")
player := aLocalPlayer["Slot"]
Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pAPM, GameIdentifier)
}
isUnderConstruction(building)
{ 	global
return getUnitTargetFilter(building) & aUnitTargetFilter.UnderConstruction
}
isUnitAStructure(unit)
{	GLOBAL
return getUnitTargetFilter(unit) & aUnitTargetFilter.Structure
}
getUnitEnergy(unit)
{	global
Return Floor(ReadMemory(B_uStructure + (unit * S_uStructure) + O_uEnergy, GameIdentifier) / 4096)
}
numgetUnitEnergy(ByRef unitDump, unit)
{	global
Return Floor(numget(unitDump, unit * S_uStructure + O_uEnergy, "Uint") / 4096)
}
getUnitHpDamage(unit)
{	global
Return Floor(ReadMemory(B_uStructure + (unit * S_uStructure) + O_uHpDamage, GameIdentifier) / 4096)
}
getUnitShieldDamage(unit)
{	global
Return Floor(ReadMemory(B_uStructure + (unit * S_uStructure) + O_uShieldDamage, GameIdentifier) / 4096)
}
getUnitPositionX(unit)
{	global
Return ReadMemory(B_uStructure + (unit * S_uStructure) + O_uX, GameIdentifier) /4096
}
getUnitPositionY(unit)
{	global
Return ReadMemory(B_uStructure + (unit * S_uStructure) + O_uY, GameIdentifier) /4096
}
getUnitPositionZ(unit)
{	global
Return ReadMemory(B_uStructure + (unit * S_uStructure) + O_uZ, GameIdentifier) /4096
}
isTransportDropQueued(transportIndex)
{
getUnitQueuedCommands(transportIndex, aCommands)
for i, command in aCommands
{
if (command.ability = "MedivacTransport"
|| command.ability = "WarpPrismTransport"
|| command.ability = "OverlordTransport")
return i
}
return 0
}
getUnitQueuedCommands(unit, byRef aQueuedMovements)
{
static aTargetFlags := { "overrideUnitPositon":  0x1
, "unknown02": 0x2
, "unknown04": 0x4
, "targetIsPoint": 0x8
, "targetIsUnit": 0x10
, "useUnitPosition": 0x20 }
aQueuedMovements := []
if (CmdQueue := ReadMemory(B_uStructure + unit * S_uStructure + O_P_uCmdQueuePointer, GameIdentifier))
{
pNextCmd := ReadMemory(CmdQueue, GameIdentifier)
loop
{
ReadRawMemory(pNextCmd & -2, GameIdentifier, cmdDump, 0x42)
targetFlag := numget(cmdDump, 0x38, "UInt")
if !aStringTable.hasKey(pString := numget(cmdDump, 0x18, "UInt"))
aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
state := numget(cmdDump, O_cqState, "Short")
aQueuedMovements.insert({ "targetX": targetX := numget(cmdDump, 0x28, "Int") / 4096
, "targetY": numget(cmdDump, 0x2C, "Int") / 4096
, "targetZ": numget(cmdDump, 0x30, "Int") / 4096
, "ability": aStringTable[pString]
, "state": state })
if (A_Index > 20 || !(targetFlag & aTargetFlags.targetIsPoint || targetFlag & aTargetFlags.targetIsUnit || targetFlag = 7))
{
aQueuedMovements := []
return 0
}
} Until (1 & pNextCmd := numget(cmdDump, 0, "Int"))
return aQueuedMovements.MaxIndex()
}
else return 0
}
getUnitQueuedCommandString(aQueuedCommandsOrUnitIndex)
{
if !isObject(aQueuedCommandsOrUnitIndex)
{
unitIndex := aQueuedCommandsOrUnitIndex
aQueuedCommandsOrUnitIndex := []
getUnitQueuedCommands(unitIndex, aQueuedCommandsOrUnitIndex)
}
for i, command in aQueuedCommandsOrUnitIndex
{
if (command.ability = "move")
{
if (command.state = aUnitMoveStates.Patrol)
s .= "Patrol,"
else if (command.state	= aUnitMoveStates.Move)
s .= "Move,"
else if (command.state	= aUnitMoveStates.Follow)
s .= "Follow,"
else if (command.state = aUnitMoveStates.HoldPosition)
s .= "Hold,"
else if (movement.state	= aUnitMoveStates.FollowNoAttack)
s .= "FNA,"
}
else if (command.ability = "attack")
s .= "Attack,"
else s .= command.ability ","
}
if s
Sort, s, D`, U
return s
}
getUnitMoveState(unit)
{
local CmdQueue, BaseCmdQueStruct
if (CmdQueue := ReadMemory(B_uStructure + unit * S_uStructure + O_P_uCmdQueuePointer, GameIdentifier))
{
BaseCmdQueStruct := ReadMemory(CmdQueue, GameIdentifier) & -2
return ReadMemory(BaseCmdQueStruct + O_cqState, GameIdentifier, 2)
}
else return -1
}
arePlayerColoursEnabled()
{	global
return !ReadMemory(B_TeamColours, GameIdentifier)
}
getArmyUnitCount()
{
return Round(pointer(GameIdentifier, B_localArmyUnitCount, O1_localArmyUnitCount, O2_localArmyUnitCount))
}
isGamePaused()
{	global
Return ReadMemory(B_IsGamePaused, GameIdentifier)
}
isMenuOpen()
{ 	global
Return  pointer(GameIdentifier, P_MenuFocus, O1_MenuFocus)
}
isChatOpen()
{ 	global
Return  pointer(GameIdentifier, P_ChatFocus, O1_ChatFocus, O2_ChatFocus)
}
isSocialMenuFocused()
{
Return  pointer(GameIdentifier, P_SocialMenu, 0x3DC, 0x3C4, 0x3A8, 0xA4)
}
getUnitTimer(unit)
{	global
return ReadMemory(B_uStructure + unit * S_uStructure + O_uTimer, GameIdentifier)
}
getUnitsHoldingXelnaga(Xelnaga)
{
p1 := ReadMemory(getUnitAbilityPointer(Xelnaga) + 0x18, GameIdentifier)
if (ReadMemory(p1 + 0xC, GameIdentifier) = 227)
{
loop, 16
{
if (unit := ReadMemory(p1 + (A_Index - 1) * 4 + 0x28 , GameIdentifier))
units .= unit >> 18 ","
}
return RTrim(units, ",")
}
return -1
}
getLocalUnitHoldingXelnaga(Xelnaga)
{
p1 := ReadMemory(getUnitAbilityPointer(Xelnaga) + 0x18, GameIdentifier)
if (ReadMemory(p1 + 0xC, GameIdentifier) = 227)
{
if (unit := ReadMemory(p1 + aLocalPlayer.slot * 4 + 0x28 , GameIdentifier))
return unit >> 18
}
return -1
}
findXelnagas(byRef aXelnagas)
{
aXelnagas := []
loop, % getHighestUnitIndex()
{
if (aUnitID.XelNagaTower = getUnitType(A_Index - 1))
aXelnagas.insert(A_Index - 1)
}
if aXelnagas.MaxIndex()
return aXelnagas.MaxIndex()
else return 0
}
isLocalUnitHoldingXelnaga(unitIndex)
{
static tickCount := 0, unitsOnTower
if (A_TickCount - tickCount > 5)
{
tickCount := A_TickCount
unitsOnTower := ""
for i, xelnagaIndex in aXelnagas
{
if ((unitOnTower := getLocalUnitHoldingXelnaga(xelnagaIndex)) > 0)
unitsOnTower .= unitOnTower ","
}
}
if unitIndex in %unitsOnTower%
return 1
return 0
}
getReplayFolder()
{	GLOBAL
Return ReadMemory_Str(B_ReplayFolder, GameIdentifier)
}
getChatText()
{ 	Global
Local ChatAddress := pointer(GameIdentifier, P_ChatInput, O1_ChatInput, O2_ChatInput
, O3_ChatInput, O4_ChatInput)
return ReadMemory_Str(ChatAddress, GameIdentifier)
}
getFPS()
{
return ReadMemory(B_FramesPerSecond, GameIdentifier)
}
getGameSpeed()
{
static aGameSpeed := { 	0: Slower
,	1: Slow
,	2: Normal
,	3: Fast
,	4: Faster }
return aGameSpeed[ReadMemory(B_Gamespeed, GameIdentifier)]
}
getWarpGateCooldown(WarpGate)
{	global B_uStructure, S_uStructure, O_P_uAbilityPointer, GameIdentifier
u_AbilityPointer := B_uStructure + WarpGate * S_uStructure + O_P_uAbilityPointer
ablilty := ReadMemory(u_AbilityPointer, GameIdentifier) & 0xFFFFFFFC
p1 := ReadMemory(ablilty + 0x28, GameIdentifier)
if !(p2 := ReadMemory(p1 + 0x1C, GameIdentifier))
return 0
p3 := ReadMemory(p2 + 0xC, GameIdentifier)
cooldown := ReadMemory(p3 + 0x4, GameIdentifier)
if (cooldown >= 0 && !(cooldown >> 31 & 1))
return cooldown
else return 0
}
getMedivacBoostCooldown(unit)
{
if (!(p1 := ReadMemory(getUnitAbilityPointer(unit) + 0x28, GameIdentifier))
|| !(p2 := readmemory(p1+0x1c, GameIdentifier)) )
return 0
p3 := readmemory(p2+0xc, GameIdentifier)
return ReadMemory(p3+0x4, GameIdentifier)
}
getUnitAbilityPointer(unit)
{	global
return ReadMemory(B_uStructure + unit * S_uStructure + O_P_uAbilityPointer, GameIdentifier) & 0xFFFFFFFC
}
numgetUnitAbilityPointer(byRef unitDump, unit)
{
return numget(unitDump, unit * S_uStructure + O_P_uAbilityPointer, "UInt") & 0xFFFFFFFC
}
isUnitStimed(unit)
{
structure := readmemory(getUnitAbilityPointer(unit) + 0x20, GameIdentifier)
return (readmemory(structure + 0x38, GameIdentifier) = 6144) ? 1 : 0
}
isUnitChronoed(unit)
{	global
if (128 = ReadMemory(B_uStructure + unit * S_uStructure + O_uChronoState, GameIdentifier, 1))
return 1
else return 0
}
numgetIsUnitChronoed(byref unitDump, unit)
{	global
if (128 = numget(unitDump, unit * S_uStructure + O_uChronoState, "UChar"))
return 1
else return 0
}
isHatchInjected(Hatch)
{	global
if (4 = ReadMemory(B_uStructure + Hatch * S_uStructure + O_uInjectState, GameIdentifier, 1))
return 1
else return 0
}
isWorkerInProductionOld(unit)
{
local state
local type := getUnitType(unit)
if (type = aUnitID["CommandCenterFlying"] || type = aUnitID["OrbitalCommandFlying"])
state := -1
else if ( type = aUnitID["Nexus"])
{
local p2 := ReadMemory(getUnitAbilityPointer(unit) + 0x24, GameIdentifier)
state := ReadMemory(p2 + 0x88, GameIdentifier, 1)
if (state = 0x43)
state := 1
else
state := 0
}
Else if (type = aUnitID["CommandCenter"])
{
state := ReadMemory(getUnitAbilityPointer(unit) + 0x9, GameIdentifier, 1)
if (state = 0x12)
state := 1
else if (state = 32 || state = 64)
state := -1
else
state := 0
}
Else if  (type =  aUnitID["PlanetaryFortress"])
{
local p1 := ReadMemory(getUnitAbilityPointer(unit) + 0x5C, GameIdentifier)
state := ReadMemory(p1 + 0x28, GameIdentifier, 1)
}
else if (type =  aUnitID["OrbitalCommand"])
{
state := ReadMemory(getUnitAbilityPointer(unit) + 0x9, GameIdentifier, 1)
if (state = 0x11)
state := 1
else state := 0
}
return state
}
isWorkerInProduction(unit)
{
GLOBAL aUnitID
type := getUnitType(unit)
if (type = aUnitID["CommandCenterFlying"] || type = aUnitID["OrbitalCommandFlying"])
state := 0
Else if (type = aUnitID["CommandCenter"] && isCommandCenterMorphing(unit))
state := 1
else if (type = aUnitID["PlanetaryFortress"])
getBuildStatsPF(unit, state)
else
getBuildStats(unit, state)
return state
}
isCommandCenterMorphing(unit)
{
local state
state := ReadMemory(getUnitAbilityPointer(unit) + 0x9, GameIdentifier, 1)
if (state = 32 )
return aUnitID["PlanetaryFortress"]
else if (state = 64)
return aUnitID["OrbitalCommand"]
return 0
}
isHatchLairOrSpireMorphing(unit, type := 0)
{
local state
if !type
type := getUnitType(unit)
state := ReadMemory(getUnitAbilityPointer(unit) + 0x8, GameIdentifier, 1)
if (state = 9 && type = aUnitID["Hatchery"])
return aUnitID["Lair"]
else if (state = 17 && type = aUnitID["Lair"])
return aUnitID["Hive"]
else if (state = 4 && type = aUnitID["Spire"])
return aUnitID["GreaterSpire"]
return 0
}
isMotherShipCoreMorphing(unit)
{
state := ReadMemory(getUnitAbilityPointer(unit) + 0x8, GameIdentifier, 1)
return state = 8 ? 1 : 0
}
IsUserMovingCamera()
{
if (IsCameraDragScrollActivated() || IsCameraDirectionalKeyScrollActivated() || IsCameraMovingViaMouseAtScreenEdge())
return 1
else return 0
}
IsCameraDirectionalKeyScrollActivated()
{
GLOBAL
Return ReadMemory(B_iNonCharKeys, GameIdentifier, 1)
}
IsMouseButtonActive()
{	GLOBAL
Return ReadMemory(B_iMouseButtons, GameIdentifier, 1)
}
IsCameraMovingViaMouseAtScreenEdge()
{	GLOBAL
return pointer(GameIdentifier, B_CameraMovingViaMouseAtScreenEdge, 01_CameraMovingViaMouseAtScreenEdge, 02_CameraMovingViaMouseAtScreenEdge, 03_CameraMovingViaMouseAtScreenEdge)
}
IsKeyDownSC2Input(CheckMouseButtons := False)
{	GLOBAL
if (CheckMouseButtons && IsMouseButtonActive())
|| ReadMemory(B_iSpace, GameIdentifier, 1)
|| ReadMemory(B_iNums, GameIdentifier, 2)
|| ReadMemory(B_iChars, GameIdentifier, 4)
|| ReadMemory(B_iTilda, GameIdentifier, 1)
|| ReadMemory(B_iNonAlphNumChars, GameIdentifier, 2)
|| ReadMemory(B_iNonCharKeys, GameIdentifier, 2)
|| ReadMemory(B_iFkeys, GameIdentifier, 2)
|| ReadMemory(B_iModifiers, GameIdentifier, 1)
return 1
return 0
}
debugSCKeyState()
{
return "B_iSpace: " ReadMemory(B_iSpace, GameIdentifier, 1)
. "`nB_iNums: " ReadMemory(B_iNums, GameIdentifier, 2)
. "`n" "B_iChars: " ReadMemory(B_iChars, GameIdentifier, 4)
. "`n" "B_iTilda: " ReadMemory(B_iTilda, GameIdentifier, 1)
. "`n" "B_iNonAlphNumChars: " ReadMemory(B_iNonAlphNumChars, GameIdentifier, 2)
. "`n" "B_iNonCharKeys: " ReadMemory(B_iNonCharKeys, GameIdentifier, 2)
. "`n" "B_iFkeys: " ReadMemory(B_iFkeys, GameIdentifier, 2)
. "`n" "B_iFkeys: " ReadMemory(B_iFkeys, GameIdentifier, 2)
. "`n" "B_iModifiers: " ReadMemory(B_iModifiers, GameIdentifier, 1)
}
IsCameraDragScrollActivated()
{	GLOBAL
Return ReadMemory(B_CameraDragScroll, GameIdentifier, 1)
}
readModifierState()
{	GLOBAL
return ReadMemory(B_iModifiers, GameIdentifier, 1)
}
readKeyBoardNumberState()
{	GLOBAL
return ReadMemory(B_iNums, GameIdentifier, 2)
}
getSCModState(KeyName)
{
state := readModifierState()
if instr(KeyName, "Shift")
return state & 1
else if instr(KeyName, "Ctrl") || instr(KeyName, "Control")
return state & 2
else if instr(KeyName, "Alt")
return state & 4
else return 0
}
WriteModifiers(shift := 0, ctrl := 0, alt := 0, ExactValue := 0)
{
LOCAL value
if shift
value += 1
if ctrl
value += 2
if alt
value += 4
if ExactValue
value := ExactValue
Return WriteMemory(B_iModifiers, GameIdentifier, value,"Char")
}
isGatewayProducingOrConvertingToWarpGate(Gateway)
{
GLOBAL GameIdentifier
state := readmemory(getUnitAbilityPointer(Gateway) + 0x8, GameIdentifier, 1)
if (state = 0x0F || state = 0x21)
return 1
else return 0
}
isGatewayConvertingToWarpGate(Gateway)
{
GLOBAL GameIdentifier
state := readmemory(getUnitAbilityPointer(Gateway) + 0x8, GameIdentifier, 1)
if (state = 0x21)
return 1
else return 0
}
SetPlayerMinerals(amount=99999)
{ 	global
player := getLocalPlayerNumber()
Return WriteMemory(B_pStructure + O_pMinerals + (player-1) * S_pStructure, GameIdentifier, amount,"UInt")
}
SetPlayerGas(amount=99999)
{ 	global
player := getLocalPlayerNumber()
Return WriteMemory(B_pStructure + O_pGas + (player-1) * S_pStructure, GameIdentifier, amount,"UInt")
}
getBuildStatsPF(unit, byref QueueSize := "",  QueuePosition := 0)
{	GLOBAL GameIdentifier
STATIC O_pQueueArray := 0x34, O_IndexParentTypes := 0x18, O_unitsQueued := 0x28
CAbilQueue := ReadMemory(getUnitAbilityPointer(unit) + 0x5C, GameIdentifier)
localQueSize := ReadMemory(CAbilQueue + O_unitsQueued, GameIdentifier, 1)
if IsByRef(QueueSize)
QueueSize := localQueSize
queuedArray := readmemory(CAbilQueue + O_pQueueArray, GameIdentifier)
B_QueuedUnitInfo := readmemory(queuedArray + 4 * QueuePosition, GameIdentifier)
if localQueSize
return getPercentageUnitCompleted(B_QueuedUnitInfo)
else return 0
}
cHex(dec, useClipboard := True)
{
return useClipboard ? clipboard := substr(dectohex(dec), 3) : substr(dectohex(dec), 3)
}
getBuildStats(building, byref QueueSize := "", byRef item := "")
{
pAbilities := getUnitAbilityPointer(building)
AbilitiesCount := getAbilitiesCount(pAbilities)
CAbilQueueIndex := getCAbilQueueIndex(pAbilities, AbilitiesCount)
B_QueuedUnitInfo := getPointerToQueuedUnitInfo(pAbilities, CAbilQueueIndex, localQueSize)
if IsByRef(QueueSize)
QueueSize := localQueSize
if IsByRef(item)
{
if localQueSize
{
if !aStringTable.hasKey(pString := readMemory(B_QueuedUnitInfo + 0xD0, GameIdentifier))
aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
item := aStringTable[pString]
}
else item := ""
}
if localQueSize
return getPercentageUnitCompleted(B_QueuedUnitInfo)
else return 0
}
getStructureProductionInfo(unit, type, byRef aInfo, byRef totalQueueSize := "", percent := True)
{
STATIC O_pQueueArray := 0x34, O_IndexParentTypes := 0x18, O_unitsQueued := 0x28
, aOffsets := []
aInfo := []
if (!pAbilities := getUnitAbilityPointer(unit))
return 0
if !aOffsets.HasKey(type)
{
if (type = aUnitID.PlanetaryFortress)
aOffsets[type] := 0x5C
else
{
CAbilQueueIndex := getCAbilQueueIndex(pAbilities, getAbilitiesCount(pAbilities))
if (CAbilQueueIndex != -1)
aOffsets[type] := O_IndexParentTypes + 4 * CAbilQueueIndex
else
aOffsets[type] := -1
}
}
if (aOffsets[type] = -1)
return 0
CAbilQueue := readmemory(pAbilities + aOffsets[type], GameIdentifier)
totalQueueSize := readmemory(CAbilQueue + O_unitsQueued, GameIdentifier)
queuedArray := readmemory(CAbilQueue + O_pQueueArray, GameIdentifier)
while (A_Index <= totalQueueSize && B_QueuedUnitInfo := readmemory(queuedArray + 4 * (A_index-1), GameIdentifier) )
{
if !aStringTable.hasKey(pString := readMemory(B_QueuedUnitInfo + 0xD0, GameIdentifier))
aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
item := aStringTable[pString]
if progress := percent ? getPercentageUnitCompleted(B_QueuedUnitInfo) : getTimeUntilUnitCompleted(B_QueuedUnitInfo)
aInfo.insert({ "Item": item, "progress": progress})
else break
}
return round(aInfo.maxIndex())
}
getStructureProductionInfoCurrent(unit, byRef aInfo)
{
STATIC O_pQueueArray := 0x34, O_IndexParentTypes := 0x18, O_unitsQueued := 0x28
aInfo := []
if (!pAbilities := getUnitAbilityPointer(unit))
return 0
if (-1 = CAbilQueueIndex := getCAbilQueueIndex(pAbilities, getAbilitiesCount(pAbilities)))
return 0
CAbilQueue := readmemory(pAbilities + O_IndexParentTypes + 4 * CAbilQueueIndex, GameIdentifier)
QueueSize := readmemory(CAbilQueue + O_unitsQueued, GameIdentifier)
queuedArray := readmemory(CAbilQueue + O_pQueueArray, GameIdentifier)
while (A_Index <= QueueSize && B_QueuedUnitInfo := readmemory(queuedArray + 4 * (A_index-1), GameIdentifier) )
{
if !aStringTable.hasKey(pString := readMemory(B_QueuedUnitInfo + 0xD0, GameIdentifier))
aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
item := aStringTable[pString]
if progress := getPercentageUnitCompleted(B_QueuedUnitInfo)
aInfo.insert({ "Item": item, "progress": progress})
else break
}
return round(aInfo.maxIndex())
}
getZergProductionStringFromEgg(eggUnitIndex)
{
p := readmemory(getUnitAbilityPointer(eggUnitIndex) + 0x1C, GameIdentifier)
p := readmemory(p + 0x34, GameIdentifier)
p := readmemory(p, GameIdentifier)
p := readmemory(p + 0xf4, GameIdentifier)
if !aStringTable.haskey(pString := readmemory(p, GameIdentifier) )
return aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
return aStringTable[pString]
}
getZergProductionFromEgg(eggUnitIndex)
{
item := []
p := readmemory(getUnitAbilityPointer(eggUnitIndex) + 0x1C, GameIdentifier)
p := readmemory(p + 0x34, GameIdentifier)
p := readmemory(p, GameIdentifier)
timeRemaining := readmemory(p + 0x6C, GameIdentifier)
totalTime := readmemory(p + 0x68, GameIdentifier)
p := readmemory(p + 0xf4, GameIdentifier)
if !aStringTable.haskey(pString := readmemory(p, GameIdentifier) )
aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
item.Progress := round((totalTime - timeRemaining)/totalTime, 2)
item.Type := aUnitID[(item.Item := aStringTable[pString])]
item.Count := item.Type = aUnitID.Zergling ? 2 : 1
return item
}
getAbilityIndex(abilityID, abilitiesCount, ByteArrayAddress := "", byRef byteArrayDump := "")
{
if !byteArrayDump
ReadRawMemory(ByteArrayAddress, GameIdentifier, byteArrayDump, abilitiesCount)
loop % abilitiesCount
{
if (abilityID = numget(byteArrayDump, A_Index-1, "Char"))
return A_Index - 1
}
return -1
}
findAbilityTypePointer(pAbilities, unitType, abilityString)
{
static aUnitAbilitiesOffsets := [], B_AbilityStringPointer := 0xA4
, O_IndexParentTypes := 0x18
if aUnitAbilitiesOffsets[unitType].hasKey(abilityString)
return pAbilities + aUnitAbilitiesOffsets[unitType, abilityString]
p1 := readmemory(pAbilities, GameIdentifier)
loop
{
if (!p := ReadMemory(p1 + B_AbilityStringPointer + (A_Index - 1)*4, GameIdentifier))
return 0
if (abilityString = string := ReadMemory_Str(ReadMemory(p + 0x4, GameIdentifier), GameIdentifier))
return pAbilities + (aUnitAbilitiesOffsets[unitType, abilityString] := O_IndexParentTypes + (A_Index - 1)*4)
} until (A_Index > 100)
return  0
}
getStructureRallyPoints(unitIndex, byRef aRallyPoints := "")
{
static O_IndexParentTypes := 0x18, cAbilRally := 0x1a
aRallyPoints := []
pAbilities := getUnitAbilityPointer(unitIndex)
abilitiesCount := getAbilitiesCount(pAbilities)
ByteArrayAddress := ReadMemory(pAbilities, GameIdentifier) + 0x3
cAbilRallyIndex := getAbilityIndex(cAbilRally, abilitiesCount, ByteArrayAddress)
if (cAbilRallyIndex >= 0)
{
pCAbillityStruct := readmemory(pAbilities + O_IndexParentTypes + 4 * cAbilRallyIndex, GameIdentifier)
bRallyStruct := readmemory(pCAbillityStruct + 0x34, GameIdentifier)
if (rallyCount := readMemory(bRallyStruct, GameIdentifier))
{
ReadRawMemory(bRallyStruct, GameIdentifier, rallyDump, 0x14 + 0x1C * rallyCount)
while (A_Index <= rallyCount)
{
aRallyPoints.insert({ "x": numget(rallyDump, (A_Index-1) * 0x1C + 0xC, "Int") / 4096
, "y": numget(rallyDump, (A_Index-1) * 0x1C + 0x10, "Int") / 4096
, "z": numget(rallyDump, (A_Index-1) * 0x1C + 0x14, "Int") / 4096 })
}
}
return rallyCount
}
return -1
}
getPercentageUnitCompleted(B_QueuedUnitInfo)
{	GLOBAL GameIdentifier
STATIC O_TotalTime := 0x68, O_TimeRemaining := 0x6C
TotalTime := ReadMemory(B_QueuedUnitInfo + O_TotalTime, GameIdentifier)
RemainingTime := ReadMemory(B_QueuedUnitInfo + O_TimeRemaining, GameIdentifier)
return round( (TotalTime - RemainingTime) / TotalTime, 2)
}
getTimeUntilUnitCompleted(B_QueuedUnitInfo)
{	GLOBAL GameIdentifier
STATIC O_TotalTime := 0x68, O_TimeRemaining := 0x6C
TotalTime := ReadMemory(B_QueuedUnitInfo + O_TotalTime, GameIdentifier)
RemainingTime := ReadMemory(B_QueuedUnitInfo + O_TimeRemaining, GameIdentifier)
if (TotalTime = RemainingTime)
return 0
return round(RemainingTime / 65536, 2)
}
getPointerAddressToQueuedUnitInfo(pAbilities, CAbilQueueIndex, byref QueueSize := "")
{	GLOBAL GameIdentifier
STATIC O_pQueueArray := 0x34, O_IndexParentTypes := 0x18, O_unitsQueued := 0x28
CAbilQueue := readmemory(pAbilities + O_IndexParentTypes + 4 * CAbilQueueIndex, GameIdentifier)
QueueSize := readmemory(CAbilQueue + O_unitsQueued, GameIdentifier)
return queuedArray := readmemory(CAbilQueue + O_pQueueArray, GameIdentifier)
}
getPointerToQueuedUnitInfo(pAbilities, CAbilQueueIndex, byref QueueSize := "", QueuePosition := 0)
{	GLOBAL GameIdentifier
STATIC O_pQueueArray := 0x34, O_IndexParentTypes := 0x18, O_unitsQueued := 0x28
CAbilQueue := readmemory(pAbilities + O_IndexParentTypes + 4 * CAbilQueueIndex, GameIdentifier)
if IsByRef(QueueSize)
QueueSize := readmemory(CAbilQueue + O_unitsQueued, GameIdentifier)
queuedArray := readmemory(CAbilQueue + O_pQueueArray, GameIdentifier)
return readmemory(queuedArray + 4 * QueuePosition, GameIdentifier)
}
getAbilitiesCount(pAbilities)
{	GLOBAL GameIdentifier
return ReadMemory(pAbilities + 0x16, GameIdentifier, 1)
}
getCAbilQueueIndex(pAbilities, AbilitiesCount)
{	GLOBAL GameIdentifier
STATIC CAbilQueue := 0x19
ByteArrayAddress := ReadMemory(pAbilities, GameIdentifier) + 0x3
ReadRawMemory(ByteArrayAddress, GameIdentifier, MemDump, AbilitiesCount)
loop % AbilitiesCount
if (CAbilQueue = numget(MemDump, A_Index-1, "Char"))
return A_Index-1
return -1
}
getAbilListIndex(pAbilities, AbilitiesCount)
{	GLOBAL GameIdentifier
STATIC CAbilQueue := 0x19
abilties := []
ByteArrayAddress := ReadMemory(pAbilities, GameIdentifier) + 0x3
ReadRawMemory(ByteArrayAddress, GameIdentifier, MemDump, AbilitiesCount)
loop % AbilitiesCount
abilties.insert(CAbilQueue := dectohex(numget(MemDump, A_Index-1, "Char")))
return abilties
}
SC2HorizontalResolution()
{	GLOBAL
return  ReadMemory(B_HorizontalResolution, GameIdentifier)
}
SC2VerticalResolution()
{	GLOBAL
return  ReadMemory(B_VerticalResolution, GameIdentifier)
}
getCharacerInfo(byref returnName := "", byref returnID := "")
{	GLOBAL B_LocalCharacterNameID, GameIdentifier
CharacterString := ReadMemory_Str(B_LocalCharacterNameID, GameIdentifier)
StringSplit, OutputArray, CharacterString, #
returnName := OutputArray1
returnID := OutputArray2
return OutputArray0
}
numGetControlGroupObject(Byref oControlGroup, Group)
{	GLOBAL B_CtrlGroupOneStructure, S_CtrlGroup, GameIdentifier, S_scStructure, O_scUnitIndex
oControlGroup := []
GroupSize := getControlGroupCount(Group)
ReadRawMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (group - 1), GameIdentifier, MemDump, GroupSize * S_scStructure + O_scUnitIndex)
oControlGroup["Count"]	:= oControlGroup["Types"] := 0
oControlGroup.units := []
loop % numget(MemDump, 0, "Short")
{
unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
if (!isUnitDead(unit) && isUnitLocallyOwned(unit))
{
oControlGroup.units.insert({ "UnitIndex": unit
, "Type": Type := getUnitType(unit)
, "Energy": getUnitEnergy(unit)
, "x": getUnitPositionX(unit)
, "y": getUnitPositionY(unit)
, "z": getUnitPositionZ(unit)})
oControlGroup["Count"]++
if Type not in %typeList%
{
typeList .= "," Type
oControlGroup["Types"]++
}
}
}
return oControlGroup["Count"]
}
numGetSelectionSorted(ByRef aSelection, ReverseOrder := False)
{
aSelection := []
selectionCount := getSelectionCount()
ReadRawMemory(B_SelectionStructure, GameIdentifier, MemDump, selectionCount * S_scStructure + O_scUnitIndex)
aSelection.Count := numget(MemDump, 0, "Short")
aSelection.Types := numget(MemDump, O_scTypeCount, "Short")
aSelection.HighlightedGroup := numget(MemDump, O_scTypeHighlighted, "Short")
aStorage := []
loop % aSelection.Count
{
priority := -1 * getUnitSubGroupPriority(unitIndex := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18)
, unitId := getUnitType(unitIndex)
, subGroupAlias := getUnitTargetFilter(unitIndex) & aUnitTargetFilter.Hallucination
? unitId  - .1
: (aUnitSubGroupAlias.hasKey(unitId)
? aUnitSubGroupAlias[unitId]
:  unitId)
, sIndices .= "," unitIndex
if !isUnitLocallyOwned(unitIndex)
nonLocalUnitSelected := True
if !isObject(aStorage[priority, subGroupAlias])
aStorage[priority, subGroupAlias] := []
aStorage[priority, subGroupAlias].insert({"unitIndex": unitIndex, "unitId": unitId})
}
aSelection.IndicesString := substr(sIndices, 2)
if (aSelection.Count && !nonLocalUnitSelected)
aSelection.IsGroupable := True
aSelection.units := []
aSelection.TabPositions := []
aSelection.TabSizes := []
TabPosition := unitPortrait := 0
for priority, object in aStorage
{
for subGroupAlias, object2 in object
{
if (TabPosition = aSelection.HighlightedGroup)
aSelection.HighlightedId :=  object2[object2.minIndex()].unitId
aSelection.TabPositions[object2[object2.minIndex()].unitId] := TabPosition
tabSize := 0
for index, unit in object2
{
aSelection.units.insert({ "priority": -1*priority
, "subGroupAlias": subGroupAlias
, "unitIndex": unit.unitIndex
, "unitId": unit.unitId
, "tabPosition": TabPosition
, "unitPortrait": unitPortrait++})
tabSize++
}
aSelection.TabSizes[object2[object2.minIndex()].unitId] := tabSize
TabPosition++
}
}
if ReverseOrder
aSelection.units := reverseArray(aSelection.units)
return aSelection["Count"]
}
numGetSelectionBubbleSort(ByRef aSelection, ReverseOrder := False)
{
aSelection := []
selectionCount := getSelectionCount()
ReadRawMemory(B_SelectionStructure, GameIdentifier, MemDump, selectionCount * S_scStructure + O_scUnitIndex)
aSelection.Count := numget(MemDump, 0, "Short")
aSelection.Types := numget(MemDump, O_scTypeCount, "Short")
aSelection.HighlightedGroup := numget(MemDump, O_scTypeHighlighted, "Short")
aSelection.units := []
loop % aSelection.Count
{
aSelection.units.insert({ "unitIndex": unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
, "unitId": unitId := getUnitType(unit)
, "priority": getUnitSubGroupPriority(unit)
, "subGroup": getUnitTargetFilter(unit) & aUnitTargetFilter.Hallucination
? unitId  - .1
: (aUnitSubGroupAlias.hasKey(unitId)
? aUnitSubGroupAlias[unitId]
:  unitId)
, name: aUnitName[unitId]})
}
bubbleSort2DArray(aSelection.units, "unitIndex", !ReverseOrder)
bubbleSort2DArray(aSelection.units, "subGroup", !ReverseOrder)
bubbleSort2DArray(aSelection.units, "Priority", ReverseOrder)
return aSelection["Count"]
}
isInSelection(unitIndex)
{
selectionCount := getSelectionCount()
ReadRawMemory(B_SelectionStructure, GameIdentifier, MemDump, selectionCount * S_scStructure + O_scUnitIndex)
loop % selectionCount
{
if (unitIndex = numget(MemDump, (A_Index-1) * S_scStructure + O_scUnitIndex, "Int") >> 18)
return 1
}
return 0
}
numGetUnitSelectionObject(ByRef aSelection, mode = 0)
{	GLOBAL O_scTypeCount, O_scTypeHighlighted, S_scStructure, O_scUnitIndex, GameIdentifier, B_SelectionStructure
aSelection := []
selectionCount := getSelectionCount()
ReadRawMemory(B_SelectionStructure, GameIdentifier, MemDump, selectionCount * S_scStructure + O_scUnitIndex)
aSelection["Count"]	:= numget(MemDump, 0, "Short")
aSelection["Types"]	:= numget(MemDump, O_scTypeCount, "Short")
aSelection["HighlightedGroup"]	:= numget(MemDump, O_scTypeHighlighted, "Short")
aSelection.units := []
if (mode = "Sort")
{
loop % aSelection["Count"]
{
unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
aSelection.units.insert({ "Type": getUnitType(unit), "UnitIndex": unit, "Priority": getUnitSubGroupPriority(unit)})
}
bubbleSort2DArray(aSelection.units, "UnitIndex", 1)
bubbleSort2DArray(aSelection.units, "Priority", 0)
}
else if (mode = "UnSortedWithPriority")
loop % aSelection["Count"]
{
unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
aSelection.units.insert({ "Type": getUnitType(unit), "UnitIndex": unit, "Priority": getUnitSubGroupPriority(unit)})
}
else
loop % aSelection["Count"]
{
unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
, owner := getUnitOwner(unit), Type := getUnitType(unit), aSelection.units.insert({"UnitIndex": unit, "Type": Type, "Owner": Owner})
}
return aSelection["Count"]
}
getUnitSelectionPage()
{	global
return pointer(GameIdentifier, P_SelectionPage, O1_SelectionPage, O2_SelectionPage, O3_SelectionPage)
}
getMaxPageValue(count := "")
{
if (count = "")
count := getSelectionCount()
if (count <= 0)
return 0
return (i := Ceil(count / 24)) > 5 ? 5 : i - 1
}
numgetUnitTargetFilter(ByRef Memory, unit)
{
return numget(Memory, Unit * S_uStructure + O_uTargetFilter, "Int64")
}
getUnitTargetFilter(Unit)
{
return ReadMemory(B_uStructure + Unit * S_uStructure + O_uTargetFilter, GameIdentifier, 8)
}
numgetUnitOwner(ByRef Memory, Unit)
{ global
return numget(Memory, Unit * S_uStructure + O_uOwner, "Char")
}
numgetUnitModelPointer(ByRef Memory, Unit)
{ global
return numget(Memory, Unit * S_uStructure + O_uModelPointer, "Int")
}
getGroupedQueensWhichCanInject(ByRef aControlGroup,  CheckMoveState := 0)
{	GLOBAL aUnitID, O_scTypeCount, O_scTypeHighlighted, S_CtrlGroup, O_scUnitIndex, GameIdentifier, B_CtrlGroupOneStructure
, S_uStructure, GameIdentifier, MI_Queen_Group, S_scStructure, aUnitMoveStates
aControlGroup := []
group := MI_Queen_Group
groupCount := getControlGroupCount(Group)
ReadRawMemory(B_CtrlGroupOneStructure + S_CtrlGroup * (Group - 1), GameIdentifier, MemDump, groupCount * S_CtrlGroup + O_scUnitIndex)
aControlGroup["UnitCount"]	:= numget(MemDump, 0, "Short")
aControlGroup["Types"]	:= numget(MemDump, O_scTypeCount, "Short")
aControlGroup.Queens := []
aControlGroup.AllQueens := []
loop % groupCount
{
unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
if (isUnitDead(unit) || !isUnitLocallyOwned(Unit))
continue
if (aUnitID["Queen"] = type := getUnitType(unit))
{
aControlGroup.AllQueens.insert({ "unit": unit})
if (energy := getUnitEnergy(unit) >= 25)
{
if CheckMoveState
{
commandString := getUnitQueuedCommandString(unit)
if !(InStr(commandString, "SpawnLarva") || InStr(commandString, "Patrol") || InStr(commandString, "Move") || InStr(commandString, "Attack")
|| InStr(commandString, "QueenBuild") || InStr(commandString, "Transfusion"))
aControlGroup.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aControlGroup.Queens[aControlGroup.Queens.MaxIndex(), "Type"] := Type
}
else
aControlGroup.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aControlGroup.Queens[aControlGroup.Queens.MaxIndex(), "Type"] := Type
}
}
}
aControlGroup["QueenCount"] := round(aControlGroup.Queens.maxIndex())
return 	aControlGroup.Queens.maxindex()
}
getSelectedQueensWhichCanInject(ByRef aSelection, CheckMoveState := 0)
{	GLOBAL aUnitID, O_scTypeCount, O_scTypeHighlighted, S_scStructure, O_scUnitIndex, GameIdentifier, B_SelectionStructure
, S_uStructure, GameIdentifier, aUnitMoveStates
aSelection := []
selectionCount := getSelectionCount()
ReadRawMemory(B_SelectionStructure, GameIdentifier, MemDump, selectionCount * S_scStructure + O_scUnitIndex)
aSelection["SelectedUnitCount"]	:= numget(MemDump, 0, "Short")
aSelection["Types"]	:= numget(MemDump, O_scTypeCount, "Short")
aSelection["HighlightedGroup"]	:= numget(MemDump, O_scTypeHighlighted, "Short")
aSelection.Queens := []
loop % selectionCount
{
unit := numget(MemDump,(A_Index-1) * S_scStructure + O_scUnitIndex , "Int") >> 18
type := getUnitType(unit)
if (isUnitLocallyOwned(Unit) && aUnitID["Queen"] = type && ((energy := getUnitEnergy(unit)) >= 25))
{
if CheckMoveState
{
commandString := getUnitQueuedCommandString(unit)
if !(InStr(commandString, "Patrol") || InStr(commandString, "Move") || InStr(commandString, "Attack")
|| InStr(commandString, "QueenBuild") || InStr(commandString, "Transfusion"))
aSelection.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aSelection.Queens[aSelection.Queens.MaxIndex(), "Type"] := Type
}
else
aSelection.Queens.insert(objectGetUnitXYZAndEnergy(unit)), aSelection.Queens[aSelection.Queens.MaxIndex(), "Type"] := Type
}
}
aSelection["Count"] := round(aSelection.Queens.maxIndex())
return 	aSelection.Queens.maxindex()
}
isQueenNearHatch(Queen, Hatch, MaxXYdistance)
{
x_dist := Abs(Queen.X - Hatch.X)
y_dist := Abs(Queen.Y- Hatch.Y)
Return Result := (x_dist > MaxXYdistance) || (y_dist > MaxXYdistance) || (Abs(Queen.Z - Hatch.Z) > 1) ? 0 : 1
}
isUnitNearUnit(Queen, Hatch, MaxXYdistance)
{
x_dist := Abs(Queen.X - Hatch.X)
y_dist := Abs(Queen.Y- Hatch.Y)
Return Result := (x_dist > MaxXYdistance) || (y_dist > MaxXYdistance) || (Abs(Queen.Z - Hatch.Z) > 1) ? 0 : 1
}
objectGetUnitXYZAndEnergy(unit)
{	Local UnitDump
ReadRawMemory(B_uStructure + unit * S_uStructure, GameIdentifier, UnitDump, S_uStructure)
Local x := numget(UnitDump, O_uX, "int")/4096, y := numget(UnitDump, O_uY, "int")/4096, Local z := numget(UnitDump, O_uZ, "int")/4096
Local Energy := numget(UnitDump, O_uEnergy, "int")/4096
return { "unit": unit, "X": x, "Y": y, "Z": z, "Energy": energy}
}
numGetUnitPositionXFromMemDump(ByRef MemDump, Unit)
{	global
return numget(MemDump, Unit * S_uStructure + O_uX, "int")/4096
}
numGetUnitPositionYFromMemDump(ByRef MemDump, Unit)
{	global
return numget(MemDump, Unit * S_uStructure + O_uY, "int")/4096
}
numGetUnitPositionZFromMemDump(ByRef MemDump, Unit)
{	global
return numget(MemDump, Unit * S_uStructure + O_uZ, "int")/4096
}
numGetIsHatchInjectedFromMemDump(ByRef MemDump, Unit)
{	global
return (4 = numget(MemDump, Unit * S_uStructure + O_uInjectState, "UChar")) ? 1 : 0
}
numGetUnitPositionXYZFromMemDump(ByRef MemDump, Unit)
{
position := []
, position.x := numGetUnitPositionXFromMemDump(MemDump, Unit)
, position.y := numGetUnitPositionYFromMemDump(MemDump, Unit)
, position.z := numGetUnitPositionZFromMemDump(MemDump, Unit)
return position
}
SortUnitsByAge(unitlist="", units*)
{
List := []
if unitlist
{
units := []
loop, parse, unitlist, |
units[A_index] := A_LoopField
}
for index, unit in units
List[A_Index] := {Unit:unit,Age:getUnitTimer(unit)}
bubbleSort2DArray(List, "Age", 0)
For index, obj in List
SortedList .= List[index].Unit "|"
return RTrim(SortedList, "|")
}
getBaseCamIndex()
{	global
return pointer(GameIdentifier, B_CurrentBaseCam, P1_CurrentBaseCam)
}
SortBasesByBaseCam(BaseList, CurrentHatchCam)
{
BaseList := SortUnitsByAge(BaseList)
loop, parse, BaseList, |
if (A_loopfield <> CurrentHatchCam)
if CurrentIndex
list .= A_LoopField "|"
else
LoList .= A_LoopField "|"
else
{
CurrentIndex := A_index
list .= A_LoopField "|"
}
if LoList
list := list LoList
return RTrim(list, "|")
}
getSubGroupAliasArray(byRef object)
{
if !isObject(object)
object := []
object := {aUnitID.VikingFighter: aUnitID.VikingAssault
, aUnitID.BarracksTechLab: aUnitID.TechLab
, aUnitID.FactoryTechLab: aUnitID.TechLab
, aUnitID.StarportTechLab: aUnitID.TechLab
, aUnitID.BarracksReactor: aUnitID.Reactor
, aUnitID.FactoryReactor: aUnitID.Reactor
, aUnitID.StarportReactor: aUnitID.Reactor
, aUnitID.WidowMineBurrowed: aUnitID.WidowMine
, aUnitID.SiegeTankSieged: aUnitID.SiegeTank
, aUnitID.HellBat: aUnitID.Hellion
, aUnitID.ChangelingZealot: aUnitID.Changeling
, aUnitID.ChangelingMarineShield: aUnitID.Changeling
, aUnitID.ChangelingMarine: aUnitID.Changeling
, aUnitID.ChangelingZerglingWings: aUnitID.Changeling
, aUnitID.ChangelingZergling: aUnitID.Changeling}
return
}
getUnitSubGroupPriority(unit)
{
if !aUnitModel[pUnitModel := ReadMemory(B_uStructure + (Unit * S_uStructure) + O_uModelPointer, GameIdentifier)]
getUnitModelInfo(pUnitModel)
return aUnitModel[pUnitModel].RealSubGroupPriority
}
setupMiniMapUnitListsOld()
{	local list, unitlist, ListType, listCount
list := "UnitHighlightList1,UnitHighlightList2,UnitHighlightList3,UnitHighlightList4,UnitHighlightList5,UnitHighlightList6,UnitHighlightList7,UnitHighlightExcludeList"
Loop, Parse, list, `,
{
ListType := A_LoopField
Active%ListType% := ""
StringReplace, unitlist, %A_LoopField%, %A_Space%, , All
unitlist := Trim(unitlist, " `t , |")
loop, parse, unitlist, `,
Active%ListType% .= aUnitID[A_LoopField] ","
Active%ListType% := RTrim(Active%ListType%, " ,")
listCount++
}
allActiveActiveUnitHighlightLists := ""
loop, % listCount - 1
{
loop, parse, ActiveUnitHighlightList%A_Index%, ","
allActiveActiveUnitHighlightLists .= A_LoopField ","
}
allActiveActiveUnitHighlightLists := RTrim(allActiveActiveUnitHighlightLists, " ,")
Return
}
setupMiniMapUnitLists(byRef aMiniMapUnits)
{	local list, unitlist, ListType
aUnitHighlights := []
aMiniMapUnits.Highlight := []
aMiniMapUnits.Exclude := []
list := "UnitHighlightList1,UnitHighlightList2,UnitHighlightList3,UnitHighlightList4,UnitHighlightList5,UnitHighlightList6,UnitHighlightList7,UnitHighlightExcludeList"
Loop, Parse, list, `,
{
StringReplace, unitlist, %A_LoopField%, %A_Space%, , All
StringReplace, unitlist, unitlist, %A_Tab%, , All
unitlist := Trim(unitlist, ", |")
listNumber := A_Index
if (A_LoopField = "UnitHighlightExcludeList")
{
loop, parse, unitlist, `,
aMiniMapUnits.Exclude[aUnitID[A_LoopField]] := True
}
else
{
loop, parse, unitlist, `,
aMiniMapUnits.Highlight[aUnitID[A_LoopField]] := "UnitHighlightList" listNumber "Colour"
}
}
Return
}
SetMiniMap(byref minimap)
{
minimap := []
minimap.MapLeft := getmapleft()
minimap.MapRight := getmapright()
minimap.MapTop := getMaptop()
minimap.MapBottom := getMapBottom()
AspectRatio := getScreenAspectRatio()
If (AspectRatio = "16:10")
{
ScreenLeft := (27/1680) * A_ScreenWidth
ScreenBottom := (1036/1050) * A_ScreenHeight
ScreenRight := (281/1680) * A_ScreenWidth
ScreenTop := (786/1050) * A_ScreenHeight
}
Else If (AspectRatio = "5:4")
{
ScreenLeft := (25/1280) * A_ScreenWidth
ScreenBottom := (1011/1024) * A_ScreenHeight
ScreenRight := (257/1280) * A_ScreenWidth
Screentop := (783/1024) * A_ScreenHeight
}
Else If (AspectRatio = "4:3")
{
ScreenLeft := (25/1280) * A_ScreenWidth
ScreenBottom := (947/960) * A_ScreenHeight
ScreenRight := (257/1280) * A_ScreenWidth
ScreenTop := (718/960) * A_ScreenHeight
}
Else
{
ScreenLeft 		:= (29/1920) * A_ScreenWidth
ScreenBottom 	:= (1066/1080) * A_ScreenHeight
ScreenRight 	:= (289/1920) * A_ScreenWidth
ScreenTop 		:= (807/1080) * A_ScreenHeight
}
minimap.ScreenWidth := ScreenRight - ScreenLeft
minimap.ScreenHeight := ScreenBottom - ScreenTop
minimap.MapPlayableWidth 	:= minimap.MapRight - minimap.MapLeft
minimap.MapPlayableHeight 	:= minimap.MapTop - minimap.MapBottom
if (minimap.MapPlayableWidth >= minimap.MapPlayableHeight)
{
minimap.scale := minimap.Screenwidth / minimap.MapPlayableWidth
X_Offset := 0
minimap.ScreenLeft := ScreenLeft + X_Offset
minimap.ScreenRight := ScreenRight - X_Offset
Y_offset := (minimap.ScreenHeight - minimap.scale * minimap.MapPlayableHeight) / 2
minimap.ScreenTop := ScreenTop + Y_offset
minimap.ScreenBottom := ScreenBottom - Y_offset
minimap.Height := minimap.ScreenBottom - minimap.ScreenTop
minimap.Width := minimap.ScreenWidth
}
else
{
minimap.scale := minimap.ScreenHeight / minimap.MapPlayableHeight
X_Offset:= (minimap.ScreenWidth - minimap.scale * minimap.MapPlayableWidth)/2
minimap.ScreenLeft := ScreenLeft + X_Offset
minimap.ScreenRight := ScreenRight - X_Offset
Y_offset := 0
minimap.ScreenTop := ScreenTop + Y_offset
minimap.ScreenBottom := ScreenBottom - Y_offset
minimap.Height := minimap.ScreenHeight
minimap.Width := minimap.ScreenRight - minimap.ScreenLeft
}
minimap.UnitMinimumRadius := 1 / minimap.scale
minimap.UnitMaximumRadius  := 10
minimap.AddToRadius := 1 / minimap.scale
Return
}
initialiseBrushColours(aHexColours, byRef a_pBrushes)
{
Global UnitHighlightHallucinationsColour, UnitHighlightInvisibleColour
, UnitHighlightList1Colour, UnitHighlightList2Colour, UnitHighlightList3Colour
, UnitHighlightList4Colour, UnitHighlightList5Colour, UnitHighlightList6Colour
, UnitHighlightList7Colour
if aHexColours[aHexColours.MinIndex()]
deleteBrushArray(a_pBrushes)
a_pBrushes := []
for colour, hexValue in aHexColours
a_pBrushes[colour] := Gdip_BrushCreateSolid(0xcFF hexValue)
a_pBrushes["TransparentBlack"] := Gdip_BrushCreateSolid(0x78000000)
a_pBrushes["ScanChrono"] := Gdip_BrushCreateSolid(0xCCFF00B3)
a_pBrushes["UnitHighlightHallucinationsColour"] := Gdip_BrushCreateSolid(UnitHighlightHallucinationsColour)
a_pBrushes["UnitHighlightInvisibleColour"] := Gdip_BrushCreateSolid(UnitHighlightInvisibleColour)
a_pBrushes["UnitHighlightList1Colour"] := Gdip_BrushCreateSolid(UnitHighlightList1Colour)
a_pBrushes["UnitHighlightList2Colour"] := Gdip_BrushCreateSolid(UnitHighlightList2Colour)
a_pBrushes["UnitHighlightList3Colour"] := Gdip_BrushCreateSolid(UnitHighlightList3Colour)
a_pBrushes["UnitHighlightList4Colour"] := Gdip_BrushCreateSolid(UnitHighlightList4Colour)
a_pBrushes["UnitHighlightList5Colour"] := Gdip_BrushCreateSolid(UnitHighlightList5Colour)
a_pBrushes["UnitHighlightList6Colour"] := Gdip_BrushCreateSolid(UnitHighlightList6Colour)
a_pBrushes["UnitHighlightList7Colour"] := Gdip_BrushCreateSolid(UnitHighlightList7Colour)
return
}
deleteBrushArray(byRef a_pBrushes)
{
for colour, pBrush in a_pBrushes
Gdip_DeleteBrush(pBrush)
a_pBrushes := []
return
}
initialisePenColours(aHexColours, penSize := 1)
{
a_pPens := []
for colour, hexValue in aHexColours
a_pPens[colour] := Gdip_CreatePen(0xcFF hexValue, penSize)
return a_pPens
}
deletePens(byRef a_pPens)
{
for i, pPen in a_pPens
Gdip_DeletePen(pPen)
a_pPens := []
return
}
drawUnitRectangle(G, x, y, width, height, colour := "black")
{
global minimap
width *= minimap.scale
height *= minimap.scale
x := x - width / 2
y := y - height /2
Gdip_DrawRectangle(G, a_pPens[colour], x, y, width, height)
}
FillUnitRectangle(G, x, y, width, height, colour)
{ 	global minimap
width *= minimap.scale
height *= minimap.scale
x := x - width / 2
y := y - height /2
Gdip_FillRectangle(G, a_pBrushes[colour], x, y, width, height)
}
isUnitLocallyOwned(Unit)
{	global aLocalPlayer
Return aLocalPlayer["Slot"] = getUnitOwner(Unit) ? 1 : 0
}
isOwnerLocal(Owner)
{	global aLocalPlayer
Return aLocalPlayer["Slot"] = Owner ? 1 : 0
}
GetEnemyRaces()
{	global aPlayer, aLocalPlayer
For slot_number in aPlayer
{	If ( aLocalPlayer["Team"] <>  team := aPlayer[slot_number, "Team"] )
{
If ( EnemyRaces <> "")
EnemyRaces .= ", "
EnemyRaces .= aPlayer[slot_number, "Race"]
}
}
return EnemyRaces .= "."
}
GetGameType(aPlayer)
{
For slot_number in aPlayer
{	team := aPlayer[slot_number, "Team"]
TeamsList .= Team "|"
Player_i ++
}
Sort, TeamsList, D| N U
TeamsList := SubStr(TeamsList, 1, -1)
Loop, Parse, TeamsList, |
Team_i := A_Index
If (Team_i > 2)
Return "FFA"
Else
Return Ceil(Player_i/Team_i) "v" Ceil(Player_i/Team_i)
}
GetEnemyTeamSize()
{	global aPlayer, aLocalPlayer
For slot_number in aPlayer
If aLocalPlayer["Team"] <> aPlayer[slot_number, "Team"]
EnemyTeam_i ++
Return EnemyTeam_i
}
GetEBases()
{	global aPlayer, aLocalPlayer, aUnitID, DeadFilterFlag
EnemyBase_i := GetEnemyTeamSize()
Unitcount := DumpUnitMemory(MemDump)
while (A_Index <= Unitcount)
{
unit := A_Index - 1
TargetFilter := numgetUnitTargetFilter(MemDump, unit)
if (TargetFilter & DeadFilterFlag)
Continue
pUnitModel := numgetUnitModelPointer(MemDump, Unit)
Type := numgetUnitModelType(pUnitModel)
owner := numgetUnitOwner(MemDump, Unit)
IF (( type = aUnitID["Nexus"] ) OR ( type = aUnitID["CommandCenter"] ) OR ( type = aUnitID["Hatchery"] )) AND (aPlayer[Owner, "Team"] <> aLocalPlayer["Team"])
{
Found_i ++
list .=  unit "|"
}
}
Return SubStr(list, 1, -1)
}
DumpUnitMemory(BYREF MemDump)
{
LOCAL UnitCount := getHighestUnitIndex()
ReadRawMemory(B_uStructure, GameIdentifier, MemDump, UnitCount * S_uStructure)
return UnitCount
}
class cUnitModelInfo
{
__New(pUnitModel)
{  global GameIdentifier, O_mUnitID, O_mMiniMapSize, O_mSubgroupPriority
ReadRawMemory((pUnitModel<< 5) & 0xFFFFFFFF, GameIdentifier, uModelData, O_mMiniMapSize+4)
this.Type := numget(uModelData, O_mUnitID, "Short")
this.MiniMapRadius := numget(uModelData, O_mMiniMapSize, "int")/4096
this.RealSubGroupPriority := numget(uModelData, O_mSubgroupPriority, "Short")
}
}
numgetUnitModelType(pUnitModel)
{  global aUnitModel
if !aUnitModel[pUnitModel]
getUnitModelInfo(pUnitModel)
return aUnitModel[pUnitModel].Type
}
numgetUnitModelMiniMapRadius(pUnitModel)
{  global aUnitModel
if !aUnitModel[pUnitModel]
getUnitModelInfo(pUnitModel)
return aUnitModel[pUnitModel].MiniMapRadius
}
numgetUnitModelPriority(pUnitModel)
{  global aUnitModel
if !aUnitModel[pUnitModel]
getUnitModelInfo(pUnitModel)
return aUnitModel[pUnitModel].RealSubGroupPriority
}
getUnitModelInfo(pUnitModel)
{  global aUnitModel
aUnitModel[pUnitModel] := new cUnitModelInfo(pUnitModel)
return
}
isUnitDead(unit)
{ 	global
return	getUnitTargetFilter(unit) & DeadFilterFlag
}
SetupUnitIDArray(byref aUnitID, byref aUnitName)
{
#LTrim
l_UnitTypes =
( Comments 
	__sight__ = 0,
	System_Snapshot_Dummy = 1,
	__unitName__Burrowed = 2,
	__unitName__ = 3,
	__id__Weapon = 4,
	BeaconRally = 5,
	BeaconArmy = 6,
	BeaconAttack = 7,
	BeaconDefend = 8,
	BeaconHarass = 9,
	BeaconIdle = 10,
	BeaconAuto = 11,
	BeaconDetect = 12,
	BeaconScout = 13,
	BeaconClaim = 14,
	BeaconExpand = 15,
	BeaconCustom1 = 16,
	BeaconCustom2 = 17,
	BeaconCustom3 = 18,
	BeaconCustom4 = 19,
	__id__ = 20,
	CUnit = 21,
	DESTRUCTIBLE = 22,
	ITEM = 23,
	POWERUP = 24,
	SMCAMERA = 25,
	SMCHARACTER = 26,
	STARMAP = 27,
	SMSET = 28,
	MISSILE = 29,
	MISSILE_INVULNERABLE = 30,
	MISSILE_HALFLIFE = 31,
	PLACEHOLDER = 32,
	PLACEHOLDER_AIR = 33,
	PATHINGBLOCKER = 34,
	BEACON = 35,
	Ball = 36,
	StereoscopicOptionsUnit = 37,
	Colossus = 38,
	TechLab = 39,
	Reactor = 40,
	__unit__ = 41,
	InfestorTerran = 42,
	BanelingCocoon = 43,
	Baneling = 44,
	Mothership = 45,
	PointDefenseDrone = 46,
	Changeling = 47,
	ChangelingZealot = 48,
	ChangelingMarineShield = 49,
	ChangelingMarine = 50,
	ChangelingZerglingWings = 51,
	ChangelingZergling = 52,
	InfestedTerran = 53,
	CommandCenter = 54,
	SupplyDepot = 55,
	Refinery = 56,
	Barracks = 57,
	EngineeringBay = 58,
	MissileTurret = 59,
	Bunker = 60,
	SensorTower = 61,
	GhostAcademy = 62,
	Factory = 63,
	Starport = 64,
	MercCompound = 65,
	Armory = 66,
	FusionCore = 67,
	AutoTurret = 68,
	SiegeTankSieged = 69,
	SiegeTank = 70,
	VikingAssault = 71,
	VikingFighter = 72,
	CommandCenterFlying = 73,
	BarracksTechLab = 74,
	BarracksReactor = 75,
	FactoryTechLab = 76,
	FactoryReactor = 77,
	StarportTechLab = 78,
	StarportReactor = 79,
	FactoryFlying = 80,
	StarportFlying = 81,
	SCV = 82,
	BarracksFlying = 83,
	SupplyDepotLowered = 84,
	Marine = 85,
	Reaper = 86,
	Ghost = 87,
	Marauder = 88,
	Thor = 89,
	Hellion = 90,
	Medivac = 91,
	Banshee = 92,
	Raven = 93,
	Battlecruiser = 94,
	Nuke = 95,
	Nexus = 96,
	Pylon = 97,
	Assimilator = 98,
	Gateway = 99,
	Forge = 100,
	FleetBeacon = 101,
	TwilightCouncil = 102,
	PhotonCannon = 103,
	Stargate = 104,
	TemplarArchive = 105,
	DarkShrine = 106,
	RoboticsBay = 107,
	RoboticsFacility = 108,
	CyberneticsCore = 109,
	Zealot = 110,
	Stalker = 111,
	HighTemplar = 112,
	DarkTemplar = 113,
	Sentry = 114,
	Phoenix = 115,
	Carrier = 116,
	VoidRay = 117,
	WarpPrism = 118,
	Observer = 119,
	Immortal = 120,
	Probe = 121,
	Interceptor = 122,
	Hatchery = 123,
	CreepTumor = 124,
	Extractor = 125,
	SpawningPool = 126,
	EvolutionChamber = 127,
	HydraliskDen = 128,
	Spire = 129,
	UltraliskCavern = 130,
	InfestationPit = 131,
	NydusNetwork = 132,
	BanelingNest = 133,
	RoachWarren = 134,
	SpineCrawler = 135,
	SporeCrawler = 136,
	Lair = 137,
	Hive = 138,
	GreaterSpire = 139,
	Egg = 140,
	Drone = 141,
	Zergling = 142,
	Overlord = 143,
	Hydralisk = 144,
	Mutalisk = 145,
	Ultralisk = 146,
	Roach = 147,
	Infestor = 148,
	Corruptor = 149,
	BroodLordCocoon = 150,
	BroodLord = 151,
	BanelingBurrowed = 152,
	DroneBurrowed = 153,
	HydraliskBurrowed = 154,
	RoachBurrowed = 155,
	ZerglingBurrowed = 156,
	InfestorTerranBurrowed = 157,
	RedstoneLavaCritterBurrowed = 158,
	RedstoneLavaCritterInjuredBurrowed = 159,
	RedstoneLavaCritter = 160,
	RedstoneLavaCritterInjured = 161,
	QueenBurrowed = 162,
	Queen = 163,
	InfestorBurrowed = 164,
	OverlordCocoon = 165,
	Overseer = 166,
	PlanetaryFortress = 167,
	UltraliskBurrowed = 168,
	OrbitalCommand = 169,
	WarpGate = 170,
	OrbitalCommandFlying = 171,
	ForceField = 172,
	WarpPrismPhasing = 173,
	CreepTumorBurrowed = 174,
	CreepTumorQueen = 175,
	SpineCrawlerUprooted = 176,
	SporeCrawlerUprooted = 177,
	Archon = 178,
	NydusCanal = 179,
	BroodlingEscort = 180,
	RichMineralField = 181,
	__unitName__Flying = 182,
	XelNagaTower = 183,
	GhostAcademyFlying = 184,
	SupplyDepotDrop = 185,
	LurkerDen = 186,
	InfestedTerransEgg = 187,
	Larva = 188,
	ReaperPlaceholder = 189,
	NeedleSpinesWeapon = 190,
	CorruptionWeapon = 191,
	InfestedTerransWeapon = 192,
	NeuralParasiteWeapon = 193,
	PointDefenseDroneReleaseWeapon = 194,
	HunterSeekerWeapon = 195,
	MULE = 196,
	BroodLordSecondaryWeapon = 197,
	ThorAAWeapon = 198,
	PunisherGrenadesLMWeapon = 199,
	VikingFighterWeapon = 200,
	ATALaserBatteryLMWeapon = 201,
	ATSLaserBatteryLMWeapon = 202,
	LongboltMissileWeapon = 203,
	D8ChargeWeapon = 204,
	YamatoWeapon = 205,
	IonCannonsWeapon = 206,
	AcidSalivaWeapon = 207,
	SpineCrawlerWeapon = 208,
	SporeCrawlerWeapon = 209,
	GlaiveWurmWeapon = 210,
	GlaiveWurmM2Weapon = 211,
	GlaiveWurmM3Weapon = 212,
	StalkerWeapon = 213,
	EMP2Weapon = 214,
	BacklashRocketsLMWeapon = 215,
	PhotonCannonWeapon = 216,
	ParasiteSporeWeapon = 217,
	BroodlingEscortLaunchAWeapon = 218,
	Broodling = 219,
	BroodLordBWeapon = 220,
	BroodlingEscortMissileWeapon = 221,
	BroodlingEscortFallbackMissileWeapon = 222,
	AutoTurretReleaseWeapon = 223,
	LarvaReleaseMissile = 224,
	AcidSpinesWeapon = 225,
	FrenzyWeapon = 226,
	ContaminateWeapon = 227,
	BroodlingDefault = 228,
	Critter = 229,
	CritterStationary = 230,
	Shape = 231,
	FungalGrowthMissile = 232,
	NeuralParasiteTentacleMissile = 233,
	Beacon_Protoss = 234,
	Beacon_ProtossSmall = 235,
	Beacon_Terran = 236,
	Beacon_TerranSmall = 237,
	Beacon_Zerg = 238,
	Beacon_ZergSmall = 239,
	Lyote = 240,
	CarrionBird = 241,
	KarakMale = 242,
	KarakFemale = 243,
	UrsadakFemaleExotic = 244,
	UrsadakMale = 245,
	UrsadakFemale = 246,
	UrsadakCalf = 247,
	UrsadakMaleExotic = 248,
	UtilityBot = 249,
	CommentatorBot1 = 250,
	CommentatorBot2 = 251,
	CommentatorBot3 = 252,
	CommentatorBot4 = 253,
	Scantipede = 254,
	Dog = 255,
	Sheep = 256,
	Cow = 257,
	InfestedTerransEggPlacement = 258,
	InfestorTerransWeapon = 259,
	MineralField = 261,
	VespeneGeyser = 262,
	SpacePlatformGeyser = 263,
	RichVespeneGeyser = 264,
	DestructibleSearchlight = 265,
	DestructibleBullhornLights = 265,
	DestructibleStreetlight = 266,
	DestructibleSpacePlatformSign = 267,
	DestructibleStoreFrontCityProps = 268,
	DestructibleBillboardTall = 269,
	DestructibleBillboardScrollingText = 270,
	DestructibleSpacePlatformBarrier = 271,
	DestructibleSignsDirectional = 272,
	DestructibleSignsConstruction = 273,
	DestructibleSignsFunny = 274,
	DestructibleSignsIcons = 275,
	DestructibleSignsWarning = 276,
	DestructibleGarage = 277,
	DestructibleGarageLarge = 278,
	DestructibleTrafficSignal = 279,
	TrafficSignal = 280,
	BraxisAlphaDestructible1x1 = 281,
	BraxisAlphaDestructible2x2 = 282,
	DestructibleDebris4x4 = 283,
	DestructibleDebris6x6 = 284,
	DestructibleRock2x4Vertical = 285,
	DestructibleRock2x4Horizontal = 286,
	DestructibleRock2x6Vertical = 287,
	DestructibleRock2x6Horizontal = 288,
	DestructibleRock4x4 = 289,
	DestructibleRock6x6 = 290,
	DestructibleRampDiagonalHugeULBR = 291,
	DestructibleRampDiagonalHugeBLUR = 292,
	DestructibleRampVerticalHuge = 293,
	DestructibleRampHorizontalHuge = 294,
	DestructibleDebrisRampDiagonalHugeULBR = 295,
	DestructibleDebrisRampDiagonalHugeBLUR = 296,
	MengskStatueAlone = 297,
	MengskStatue = 298,
	WolfStatue = 299,
	GlobeStatue = 300,
	Weapon = 301,
	GlaiveWurmBounceWeapon = 302,
	BroodLordWeapon = 303,
	BroodLordAWeapon = 304,
	CreepBlocker1x1 = 305,
	PathingBlocker1x1 = 306,
	PathingBlocker2x2 = 307,
	AutoTestAttackTargetGround = 308,
	AutoTestAttackTargetAir = 309,
	AutoTestAttacker = 310,
	HelperEmitterSelectionArrow = 311,
	MultiKillObject = 312,
	ShapeGolfball = 313,
	ShapeCone = 314,
	ShapeCube = 315,
	ShapeCylinder = 316,
	ShapeDodecahedron = 317,
	ShapeIcosahedron = 318,
	ShapeOctahedron = 319,
	ShapePyramid = 320,
	ShapeRoundedCube = 321,
	ShapeSphere = 322,
	ShapeTetrahedron = 323,
	ShapeThickTorus = 324,
	ShapeThinTorus = 325,
	ShapeTorus = 326,
	Shape4PointStar = 327,
	Shape5PointStar = 328,
	Shape6PointStar = 329,
	Shape8PointStar = 330,
	ShapeArrowPointer = 331,
	ShapeBowl = 332,
	ShapeBox = 333,
	ShapeCapsule = 334,
	ShapeCrescentMoon = 335,
	ShapeDecahedron = 336,
	ShapeDiamond = 337,
	ShapeFootball = 338,
	ShapeGemstone = 339,
	ShapeHeart = 340,
	ShapeJack = 341,
	ShapePlusSign = 342,
	ShapeShamrock = 343,
	ShapeSpade = 344,
	ShapeTube = 345,
	ShapeEgg = 346,
	ShapeYenSign = 347,
	ShapeX = 348,
	ShapeWatermelon = 349,
	ShapeWonSign = 350,
	ShapeTennisball = 351,
	ShapeStrawberry = 352,
	ShapeSmileyFace = 353,
	ShapeSoccerball = 354,
	ShapeRainbow = 355,
	ShapeSadFace = 356,
	ShapePoundSign = 357,
	ShapePear = 358,
	ShapePineapple = 359,
	ShapeOrange = 360,
	ShapePeanut = 361,
	ShapeO = 362,
	ShapeLemon = 363,
	ShapeMoneyBag = 364,
	ShapeHorseshoe = 365,
	ShapeHockeyStick = 366,
	ShapeHockeyPuck = 367,
	ShapeHand = 368,
	ShapeGolfClub = 369,
	ShapeGrape = 370,
	ShapeEuroSign = 371,
	ShapeDollarSign = 372,
	ShapeBasketball = 373,
	ShapeCarrot = 374,
	ShapeCherry = 375,
	ShapeBaseball = 376,
	ShapeBaseballBat = 377,
	ShapeBanana = 378,
	ShapeApple = 379,
	ShapeCashLarge = 380,
	ShapeCashMedium = 381,
	ShapeCashSmall = 382,
	ShapeFootballColored = 383,
	ShapeLemonSmall = 384,
	ShapeOrangeSmall = 385,
	ShapeTreasureChestOpen = 386,
	ShapeTreasureChestClosed = 387,
	ShapeWatermelonSmall = 388,
	UnbuildableRocksDestructible = 389,
	UnbuildableBricksDestructible = 390,
	UnbuildablePlatesDestructible = 391,
	BattlecruiserDefensiveMatrix = 392,
	BattlecruiserHurricane = 393,
	BattlecruiserYamato = 394,
	__unitLink__ = 395,
	WarpBubble = 396,
	HydraliskGroundWeapon = 397,
	HydraliskAirWeapon = 398,
	OverseerGasCloud = 399,
	D8Charge = 400,
	RoachEgg = 401,
	CorruptorEgg = 402,
	QueenCocoon = 403,
	GreaterObservatory = 404,
	AssaultMorphModel = 405,
	FighterMorphModel = 406,
	HellBat = 410,
	HellionTank = 410,
	TalonsMissileWeapon = 411,
	MothershipCore = 414,
	Locust = 418,
	SwarmHostBurrowed = 422,
	SwarmHost = 423,
	Oracle = 424,
	Tempest = 425,
	WidowMine = 427,
	Viper = 428,
	WidowMineBurrowed = 429,
	ProtossVespeneGeyser = 511,
	VespeneGeyserPretty = 515, ; **This has same name as 262 geyser - so i give it a new one This is on a new 1v1 map Habitation Station LE - This geyser isn't in the map editor though (perhaps there's a setting to get it though)		
	Artosilop = 562,
	ThorHighImpactPayload = 588,
	PhotonOverCharge = MothershipCoreApplyPurifyAB ; No quotes. Dirty hack to allow removal of PO from unit panel
)
#LTrim, off
if !isobject(aUnitID)
aUnitID := []
if !isobject(aUnitName)
aUnitName := []
loop, parse, l_UnitTypes, `,
{
StringSplit, Item , A_LoopField, =
name := trim(Item1, " `t `n"), UnitID := trim(Item2, " `t `n")
aUnitID[name] := UnitID
aUnitName[UnitID] := name
}
Return
}
setupTargetFilters(byref Array)
{
aUnitTargetFilter := {Outer: 0x0000800000000000
, Unstoppable: 0x0000400000000000
, Summoned: 0x0000200000000000
, Stunned: 0x0000100000000000
, Radar: 0x0000080000000000
, Detector: 0x0000040000000000
, Passive: 0x0000020000000000
, Benign: 0x0000010000000000
, HasShields: 0x0000008000000000
, HasEnergy: 0x0000004000000000
, Invulnerable: 0x0000002000000000
, Hallucination: 0x0000001000000000
, Hidden: 0x0000000800000000
, Revivable: 0x0000000400000000
, Dead: 0x0000000200000000
, UnderConstruction: 0x0000000100000000
, Stasis: 0x0000000080000000
, Visible: 0x0000000040000000
, Cloaked: 0x0000000020000000
, Buried: 0x0000000010000000
, PreventReveal: 0x0000000008000000
, PreventDefeat: 0x0000000004000000
, CanHaveShields: 0x0000000002000000
, CanHaveEnergy: 0x0000000001000000
, Uncommandable: 0x0000000000800000
, Item: 0x0000000000400000
, Destructable: 0x0000000000200000
, Missile: 0x0000000000100000
, ResourcesHarvestable: 0x0000000000080000
, ResourcesRaw: 0x0000000000040000
, Worker: 0x0000000000020000
, Heroic: 0x0000000000010000
, Hover: 0x0000000000008000
, Structure: 0x0000000000004000
, Massive: 0x0000000000002000
, Psionic: 0x0000000000001000
, Mechanical: 0x0000000000000800
, Robotic: 0x0000000000000400
, Biological: 0x0000000000000200
, Armored: 0x0000000000000100
, Light: 0x0000000000000080
, Ground: 0x0000000000000040
, Air: 0x0000000000000020
, Enemy: 0x0000000000000010
, Neutral: 0x0000000000000008
, Ally: 0x0000000000000004
, Player: 0x0000000000000002
, Self: 0x0000000000000001}
Array := aUnitTargetFilter
return
}
SetupColourArrays(ByRef HexColour, Byref MatrixColour)
{
If IsByRef(HexColour)
HexColour := []
If IsByRef(MatrixColour)
MatrixColour := []
HexCoulourList := "White=FFFFFF|Red=B4141E|Blue=0042FF|Teal=1CA7EA|Purple=540081|Yellow=EBE129|Orange=FE8A0E|Green=168000|Light Pink=CCA6FC|Violet=1F01C9|Light Grey=525494|Dark Green=106246|Brown=4E2A04|Light Green=96FF91|Dark Grey=232323|Pink=E55BB0|Black=000000"
loop, parse, HexCoulourList, |
{
StringSplit, Item , A_LoopField, =
If IsByRef(HexColour)
HexColour[Item1] := Item2
If IsByRef(MatrixColour)
{
colour := Item2
colourRed := "0x" substr(colour, 1, 2)
colourGreen := "0x" substr(colour, 3, 2)
colourBlue := "0x" substr(colour, 5, 2)
colourRed := Round(colourRed/0xFF,2)
colourGreen := Round(colourGreen/0xFF,2)
colourBlue := Round(colourBlue/0xFF,2)
Matrix =
		(
0		|0		|0		|0		|0
0		|0		|0		|0		|0
0		|0		|0		|0		|0
0		|0		|0		|1		|0
%colourRed%	|%colourGreen%	|%colourBlue%	|0		|1
)
MatrixColour[Item1] := Matrix
}
}
Return
}
CreatepBitmaps(byref a_pBitmap, aUnitID, MatrixColour)
{
a_pBitmap := []
l_Races := "Terran,Protoss,Zerg"
loop, parse, l_Races, `,
{
loop, 2
{
Background := A_index - 1
a_pBitmap[A_loopfield,"Mineral",Background] := Gdip_CreateBitmapFromFile(A_Temp "\Mineral_" Background A_loopfield ".png")
a_pBitmap[A_loopfield,"Gas",Background] := Gdip_CreateBitmapFromFile(A_Temp "\Gas_" Background A_loopfield ".png")
a_pBitmap[A_loopfield,"Supply",Background] := Gdip_CreateBitmapFromFile(A_Temp "\Supply_" Background A_loopfield ".png")
}
a_pBitmap[A_loopfield,"Worker"] := Gdip_CreateBitmapFromFile(A_Temp "\Worker_0" A_loopfield ".png")
a_pBitmap[A_loopfield,"Army"] := Gdip_CreateBitmapFromFile(A_Temp "\Army_" A_loopfield ".png")
a_pBitmap[A_loopfield,"RacePretty"] := Gdip_CreateBitmapFromFile(A_Temp "\" A_loopfield "90.png")
a_pBitmap[A_loopfield,"RaceFlat"]  := Gdip_CreateBitmapFromFile(A_Temp "\Race_" A_loopfield "Flat.png")
Width := Gdip_GetImageWidth(a_pBitmap[A_loopfield,"RaceFlat"]), Height := Gdip_GetImageHeight(a_pBitmap[A_loopfield,"RaceFlat"])
for colour, matrix in MatrixColour
{
a_pBitmap[A_loopfield, "RaceFlatColour", colour] := Gdip_CreateBitmap(Width, Height)
G2 := Gdip_GraphicsFromImage(a_pBitmap[A_loopfield, "RaceFlatColour", colour])
Gdip_SetSmoothingMode(G2, 4)
Gdip_SetInterpolationMode(G2, 7)
Gdip_DrawImage(G2, a_pBitmap[A_loopfield,"RaceFlat"], "", "", "", "", "", "", "", "", matrix)
Gdip_DeleteGraphics(G2)
}
}
Loop, %A_Temp%\UnitPanelMacroTrainer\*.png
{
StringReplace, FileTitle, A_LoopFileName, .%A_LoopFileExt%
if aUnitID[FileTitle]
a_pBitmap[aUnitID[FileTitle]] := Gdip_CreateBitmapFromFile(A_LoopFileFullPath)
else
a_pBitmap[FileTitle] := Gdip_CreateBitmapFromFile(A_LoopFileFullPath)
}
a_pBitmap["PurpleX16"] := Gdip_CreateBitmapFromFile(A_Temp "\PurpleX16.png")
a_pBitmap["GreenX16"] := Gdip_CreateBitmapFromFile(A_Temp "\GreenX16.png")
a_pBitmap["RedX16"] := Gdip_CreateBitmapFromFile(A_Temp "\RedX16.png")
}
deletepBitMaps(byRef a_pBitmap)
{
for i, v in a_pBitmap
{
if IsObject(v)
deletepBitMaps(a_pBitmap[i])
else
{
Gdip_DisposeImage(v)
}
}
a_pBitmap := []
return
}
getPlayers(byref aPlayer, byref aLocalPlayer, byref aEnemyAndLocalPlayer := "")
{
aPlayer := [], aLocalPlayer := [], aEnemyAndLocalPlayer := []
Loop, 15
{
if !getPlayerName(A_Index)
|| IsInList(getPlayerType(A_Index), "None", "Neutral", "Hostile", "Referee", "Spectator")
Continue
aPlayer.insert(A_Index, new c_Player(A_Index) )
If (A_Index = getLocalPlayerNumber()) OR (debug AND getPlayerName(A_Index) == debug_name)
aLocalPlayer :=  new c_Player(A_Index)
}
for slotNumber, player in aPlayer
{
if player.Team != aLocalPlayer.Team
aEnemyAndLocalPlayer.insert(player)
}
aEnemyAndLocalPlayer.Insert(aLocalPlayer)
return
}
IsInList(Var, items*)
{
for key, item in items
{
If (var = item)
Return 1
}
return 0
}
class c_Player
{
__New(i)
{
this.Slot := i
this.Type := getPlayerType(i)
this.Name := getPlayerName(i)
this.Team := getPlayerTeam(i)
this.Race := getPlayerRace(i)
this.Colour := getPlayerColour(i)
}
}
Class c_EnemyUnit
{
__New(unit)
{
this.Radius := getMiniMapRadius(Unit)
this.Owner := getUnitOwner(Unit)
this.Type := getUnitType(Unit)
this.X := getUnitPositionX(unit)
this.Y := getUnitPositionY(unit)
this.TargetFilter := getUnitTargetFilter(Unit)
}
}
ParseEnemyUnits(ByRef a_EnemyUnits, ByRef aPlayer)
{ global DeadFilterFlag
LocalTeam := getPlayerTeam(), a_EnemyUnitsTmp := []
While (A_Index <= getHighestUnitIndex())
{
unit := A_Index -1
Filter := getUnitTargetFilter(unit)
If (Filter & DeadFilterFlag) || (type = "Fail")
Continue
Owner := getUnitOwner(unit)
if  (aPlayer[Owner, "Team"] <> LocalTeam AND Owner)
a_EnemyUnitsTmp[Unit] := new c_EnemyUnit(Unit)
}
a_EnemyUnits := a_EnemyUnitsTmp
}
getLongestPlayerName(aPlayer, includeLocalPlayer := False)
{
localTeam := getPlayerTeam(getLocalPlayerNumber())
for slotNumber, Player in aPlayer
{
if ((player.team != localTeam || (slotNumber = aLocalPlayer["Slot"] && includeLocalPlayer ))
&& StrLen(player.name) > StrLen(LongestName))
LongestName := player.name
}
return LongestName
}
getLongestPlayerNames(byRef LongestEnemyName, byRef LongestIncludeSelf)
{
hbm := CreateDIBSection(600, 200)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
for slotNumber, Player in aPlayer
{
if (player.team != localTeam)
{
data := gdip_TextToGraphics(G, player.name, "x0y0 Bold cFFFFFFFF r4 s17", "Arial")
StringSplit, size, data, |
if (size3 > longestSize)
longestSize := size3, LongestEnemyName := player.name
}
}
data := gdip_TextToGraphics(G, aLocalPlayer.Name, "x0y0 Bold cFFFFFFFF r4 s17", "Arial")
StringSplit, size, data, |
if (size3 > longestSize)
LongestIncludeSelf := aLocalPlayer.Name
else LongestIncludeSelf := LongestEnemyName
Gdip_DeleteGraphics(G)
UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayMatchTransparency)
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
return
}
areOverlaysWaitingToRedraw()
{
global
if (!ReDrawIncome || !ReDrawResources || !ReDrawArmySize || !ReDrawWorker
|| !ReDrawIdleWorkers || !RedrawUnit || !ReDrawLocalPlayerColour || !ReDrawMiniMap
|| !RedrawMacroTownHall || !RedrawLocalUpgrades)
return False
return True
}
DestroyOverlays()
{
global
Try Gui, APMOverlay: Destroy
Try Gui, MiniMapOverlay: Destroy
Try Gui, IncomeOverlay: Destroy
Try Gui, ResourcesOverlay: Destroy
Try Gui, ArmySizeOverlay: Destroy
Try Gui, WorkerOverlay: Destroy
Try Gui, idleWorkersOverlay: Destroy
Try Gui, LocalPlayerColourOverlay: Destroy
Try Gui, UnitOverlay: Destroy
Try Gui, MacroTownHall: Destroy
Try Gui, LocalUpgradesOverlay: Destroy
local lOverlayFunctions := "DrawAPMOverlay,DrawIncomeOverlay,DrawUnitOverlay,DrawResourcesOverlay"
. ",DrawArmySizeOverlay,DrawWorkerOverlay,DrawIdleWorkersOverlay,DrawMacroTownHallOverlay"
. ",DrawLocalUpgradesOverlay"
loop, parse, lOverlayFunctions, `,
{
if IsFunc(A_LoopField)
try %A_LoopField%(-1)
}
ReDrawOverlays := ReDrawAPM := ReDrawIncome := ReDrawResources
:= ReDrawArmySize := ReDrawWorker := ReDrawIdleWorkers
:= RedrawUnit := ReDrawLocalPlayerColour := ReDrawMiniMap
:= RedrawMacroTownHall := RedrawLocalUpgrades := True
return True
}
setDrawingQuality(G)
{
Gdip_SetSmoothingMode(G, 4)
Gdip_SetCompositingMode(G, 0)
return
}
Draw(G,x,y,l=11,h=11,colour=0x880000ff, Mode=0)
{
static pPen, a_pBrushes := []
if Mode
{
if !pPen
pPen := Gdip_CreatePen(0xFF000000, 1)
addtorad := 1/minimap.ratio
Gdip_DrawRectangle(G, pPen, (x - l/2), (y - h/2), l * addtorad , h * addtorad)
}
if (Mode = 0) || (Mode = 3)
{
if !a_pBrushes[colour]
a_pBrushes[colour] := Gdip_BrushCreateSolid(colour)
Gdip_FillRectangle(G, a_pBrushes[colour], (x - l/2), (y - h/2), l, h)
}
}
getUnitMiniMapMousePos(Unit, ByRef  Xvar="", ByRef  Yvar="")
{
global minimap
uX := getUnitPositionX(Unit), uY := getUnitPositionY(Unit)
uX -= minimap.MapLeft, uY -= minimap.MapBottom
Xvar := round(minimap.ScreenLeft + (uX/minimap.MapPlayableWidth * minimap.Width))
Yvar := round(minimap.Screenbottom - ( uY/minimap.MapPlayableHeight * minimap.Height))
return
}
mapToMiniMapPos(x, y, ByRef  Xvar="", ByRef  Yvar="")
{
global minimap
x -= minimap.MapLeft, y -= minimap.MapBottom
Xvar := round(minimap.ScreenLeft + (x/minimap.MapPlayableWidth * minimap.Width))
Yvar := round(minimap.Screenbottom - ( y/minimap.MapPlayableHeight * minimap.Height))
return
}
getMiniMapPos(Unit, ByRef  Xvar="", ByRef  Yvar="")
{
global minimap
uX := getUnitPositionX(Unit), uY := getUnitPositionY(Unit)
uX -= minimap.MapLeft, uY -= minimap.MapBottom
Xvar := minimap.ScreenLeft + (uX/minimap.MapPlayableWidth * minimap.Width)
Yvar := minimap.Screenbottom - ( uY/minimap.MapPlayableHeight * minimap.Height)
return
}
convertCoOrdindatesToMiniMapPos(ByRef  X, ByRef  Y)
{
global minimap
X -= minimap.MapLeft, Y -= minimap.MapBottom
, X := round(minimap.ScreenLeft + (X/minimap.MapPlayableWidth * minimap.Width))
, Y := round(minimap.Screenbottom - (Y/minimap.MapPlayableHeight * minimap.Height))
return
}
isUserPerformingAction()
{
if ( isUserBusyBuilding() || IsUserMovingCamera() || IsMouseButtonActive()
||  isCastingReticleActive() )
return 1
else return 0
}
isUserPerformingActionIgnoringCamera()
{	GLOBAL
if ( isUserBusyBuilding() || IsMouseButtonActive()
||  isCastingReticleActive() )
return 1
else return 0
}
isCastingReticleActive()
{	GLOBAL
return pointer(GameIdentifier, P_IsUserPerformingAction, O1_IsUserPerformingAction)
}
isUserBusyBuilding()
{ 	GLOBAL
if ( 6 = pointer(GameIdentifier, P_IsBuildCardDisplayed, 01_IsBuildCardDisplayed, 02_IsBuildCardDisplayed, 03_IsBuildCardDisplayed))
return 1
else return 0
}
ifTypeInList(type, byref list)
{
if type in %list%
return 1
return 0
}
IniRead(File, Section, Key="", DefaultValue="")
{
IniRead, Output, %File%, %Section%, %Key%, %DefaultValue%
Return Output
}
createAlertArray()
{
local alert_array := []
loop, parse, l_GameType, `,
{
IniRead, BAS_on_%A_LoopField%, %config_file%, Building & Unit Alert %A_LoopField%, enable, 1
alert_array[A_LoopField, "Enabled"] := BAS_on_%A_LoopField%
loop,
{
IniRead, temp_name, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_name_warning
if (  temp_name = "ERROR" )
{
alert_array[A_LoopField, "list", "size"] := A_Index-1
break
}
IniRead, temp_DWB, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_Dont_Warn_Before_Time, 0
IniRead, temp_DWA, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_Dont_Warn_After_Time, 54000
IniRead, Temp_repeat, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_repeat_on_new, 0
IniRead, Temp_IDName, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_IDName
alert_array[A_LoopField, A_Index, "Name"] := temp_name
alert_array[A_LoopField, A_Index, "DWB"] := temp_DWB
alert_array[A_LoopField, A_Index, "DWA"] := temp_DWA
alert_array[A_LoopField, A_Index, "Repeat"] := Temp_repeat
alert_array[A_LoopField, A_Index, "IDName"] := Temp_IDName
}
}
Return alert_array
}
convertObjectToList(Object, Delimiter="|")
{
for index, item in Object
if (A_index = 1)
List .= item
else
List .= "|" item
return List
}
ConvertListToObject(byref Object, List, Delimiter="|", ClearObject = 0)
{
if (!IsObject(object) || ClearObject)
object := []
loop, parse, List, %delimiter%
object.insert(A_LoopField)
return
}
exitApp()
{
ExitApp
return
}
tSpeak(Message, SAPIVol := "", SAPIRate := "")
{	global speech_volume, aThreads
if (SAPIVol = "")
SAPIVol := speech_volume
if SAPIVol
aThreads.Speech.ahkPostFunction("speak", Message, SAPIVol, SAPIRate)
return
}
doUnitDetection(unit, type, owner, mode = "")
{
global config_file, alert_array, time, MiniMapWarning, PrevWarning, GameIdentifier, aUnitID, GameType
static Alert_TimedOut := [], Alerted_Buildings := [], Alerted_Buildings_Base := []
static l_WarningArrays := "Alert_TimedOut,Alerted_Buildings,Alerted_Buildings_Base"
time := getTime()
if (Mode = "Reset")
{
Alert_TimedOut := [],, Alerted_Buildings := [], Alerted_Buildings_Base := []
Iniwrite, 0, %config_file%, Resume Warnings, Resume
IniDelete, %config_file%, Resume Warnings
return
}
else If (Mode = "Save")
{
loop, parse, l_WarningArrays, `,
{
For index, Object in %A_loopfield%
{
if (A_index <> 1)
l_AlertShutdown .= ","
if (A_loopfield = "Alert_TimedOut")
For PlayerNumber, object2 in Object
For Alert, warned_base in Object2
l_AlertShutdown .= PlayerNumber " " Alert " " warned_base
else
For PlayerNumber, warned_base in Object
l_AlertShutdown .= PlayerNumber " " warned_base
}
Iniwrite, %l_AlertShutdown%, %config_file%, Resume Warnings, %A_loopfield%
l_AlertShutdown := ""
}
Iniwrite, 1, %config_file%, Resume Warnings, Resume
return
}
Else if (Mode = "Resume")
{
Alert_TimedOut := [], Alerted_Buildings := [], Alerted_Buildings_Base := []
Iniwrite, 0, %config_file%, Resume Warnings, Resume
loop, parse, l_WarningArrays, `,
{
ArrayName := A_loopfield
%ArrayName% := []
Iniread, string, %config_file%, Resume Warnings, %ArrayName%, %A_space%
if (string != A_Space)
loop, parse, string, `,
{
StringSplit, VarOut, A_loopfield, %A_Space%
if (ArrayName = "Alert_TimedOut")
%ArrayName%[A_index, VarOut1, VarOut2] := VarOut3
else
%ArrayName%[A_index, VarOut1] := VarOut2
}
}
IniDelete, %config_file%, Resume Warnings
return
}
loop_AlertList:
loop, % alert_array[GameType, "list", "size"]
{
Alert_Index := A_Index
if  ( type = aUnitID[alert_array[GameType, A_Index, "IDName"]] )
{
if ( time < alert_array[GameType, A_Index, "DWB"] OR time > alert_array[GameType, A_Index, "DWA"]  )
{
For index, object in Alert_TimedOut
if ( unit = object[owner, Alert_Index] )
continue, loop_AlertList
Alert_TimedOut[Alert_TimedOut.maxindex() ? Alert_TimedOut.maxindex()+1 : 1, owner, Alert_Index] := unit
continue, loop_AlertList
}
Else
{
For index, object in Alert_TimedOut
if ( unit = object[owner, Alert_Index] )
break loop_AlertList
If  !alert_array[GameType, A_Index, "Repeat"]
For index, warned_type in Alerted_Buildings
if ( Alert_Index = warned_type[owner] )
break loop_AlertList
For index, warned_unit in Alerted_Buildings_Base
if ( unit = warned_unit[owner] )
break loop_AlertList
}
PrevWarning := []
MiniMapWarning.insert({ "Unit": PrevWarning.unitIndex := unit
, "Time": Time
, "UnitTimer": PrevWarning.UnitTimer := getUnitTimer(unit)
, "Type": PrevWarning.Type := type
, "Owner":  PrevWarning.Owner := owner})
PrevWarning.speech := alert_array[GameType, A_Index, "Name"]
tSpeak(alert_array[GameType, A_Index, "Name"])
if (!alert_array[GameType, A_Index, "Repeat"])
Alerted_Buildings.insert({(owner): Alert_Index})
Alerted_Buildings_Base.insert({(owner): unit})
break loop_AlertList
}
}
return
}
announcePreviousUnitWarning()
{
global
If PrevWarning
{
if (getUnitTimer(PrevWarning.unitIndex) < PrevWarning.UnitTimer
|| getUnitOwner(PrevWarning.unitIndex) != PrevWarning.Owner
|| getUnitType(PrevWarning.unitIndex) != PrevWarning.Type)
{
tSpeak(PrevWarning.speech " is dead.")
}
else
{
tSpeak(PrevWarning.speech)
MiniMapWarning.insert({ "Unit": PrevWarning.unitIndex
, "Time":  getTime()
, "UnitTimer": PrevWarning.UnitTimer
, "Type": PrevWarning.Type
, "Owner":  PrevWarning.Owner})
}
}
Else tSpeak("There have been no alerts")
return
}
readConfigFile()
{
Global
IniRead, read_version, %config_file%, Version, version, 1
IniRead, auto_inject, %config_file%, Auto Inject, auto_inject_enable, 1
IniRead, auto_inject_alert, %config_file%, Auto Inject, alert_enable, 1
IniRead, auto_inject_time, %config_file%, Auto Inject, auto_inject_time, 41
IniRead, cast_inject_key, %config_file%, Auto Inject, auto_inject_key, F5
IniRead, Inject_control_group, %config_file%, Auto Inject, control_group, 9
IniRead, Inject_spawn_larva, %config_file%, Auto Inject, spawn_larva, v
IniRead, HotkeysZergBurrow, %config_file%, Auto Inject, HotkeysZergBurrow, r
section := "MiniMap Inject"
IniRead, MI_Queen_Group, %config_file%, %section%, MI_Queen_Group, 7
IniRead, MI_QueenDistance, %config_file%, %section%, MI_QueenDistance, 17
IniRead, manual_inject_timer, %config_file%, Manual Inject Timer, manual_timer_enable, 0
IniRead, manual_inject_time, %config_file%, Manual Inject Timer, manual_inject_time, 43
IniRead, inject_start_key, %config_file%, Manual Inject Timer, start_stop_key, Lwin & RButton
IniRead, inject_reset_key, %config_file%, Manual Inject Timer, reset_key, Lwin & LButton
IniRead, InjectTimerAdvancedEnable, %config_file%, Manual Inject Timer, InjectTimerAdvancedEnable, 0
IniRead, InjectTimerAdvancedTime, %config_file%, Manual Inject Timer, InjectTimerAdvancedTime, 43
IniRead, InjectTimerAdvancedLarvaKey, %config_file%, Manual Inject Timer, InjectTimerAdvancedLarvaKey, e
IniRead, W_inject_ding_on, %config_file%, Inject Warning, ding_on, 1
IniRead, W_inject_speech_on, %config_file%, Inject Warning, speech_on, 0
IniRead, w_inject_spoken, %config_file%, Inject Warning, w_inject, Inject
section := "Forced Inject"
IniRead, F_Inject_Enable, %config_file%, %section%, F_Inject_Enable, 0
IniRead, FInjectHatchFrequency, %config_file%, %section%, FInjectHatchFrequency, 2500
IniRead, FInjectHatchMaxHatches, %config_file%, %section%, FInjectHatchMaxHatches, 10
IniRead, FInjectAPMProtection, %config_file%, %section%, FInjectAPMProtection, 190
IniRead, F_InjectOff_Key, %config_file%, %section%, F_InjectOff_Key, Lwin & F5
IniRead, idle_enable, %config_file%, Idle AFK Game Pause, enable, 0
IniRead, idle_time, %config_file%, Idle AFK Game Pause, idle_time, 15
IniRead, UserIdle_LoLimit, %config_file%, Idle AFK Game Pause, UserIdle_LoLimit, 3
IniRead, UserIdle_HiLimit, %config_file%, Idle AFK Game Pause, UserIdle_HiLimit, 10
IniRead, chat_text, %config_file%, Idle AFK Game Pause, chat_text, Sorry, please give me 2 minutes. Thanks :)
IniRead, name, %config_file%, Starcraft Settings & Keys, name, YourNameHere
IniRead, pause_game, %config_file%, Starcraft Settings & Keys, pause_game, {Pause}
IniRead, base_camera, %config_file%, Starcraft Settings & Keys, base_camera, {Backspace}
IniRead, NextSubgroupKey, %config_file%, Starcraft Settings & Keys, NextSubgroupKey, {Tab}
IniRead, escape, %config_file%, Starcraft Settings & Keys, escape, {escape}
section := "Backspace Inject Keys"
IniRead, BI_create_camera_pos_x, %config_file%, %section%, create_camera_pos_x, +{F6}
IniRead, BI_camera_pos_x, %config_file%, %section%, camera_pos_x, {F6}
section := "Forgotten Gateway/Warpgate Warning"
IniRead, warpgate_warn_on, %config_file%, %section%, enable, 1
IniRead, sec_warpgate, %config_file%, %section%, warning_count, 1
IniRead, delay_warpgate_warn, %config_file%, %section%, initial_time_delay, 10
IniRead, delay_warpgate_warn_followup, %config_file%, %section%, follow_up_time_delay, 15
IniRead, w_warpgate, %config_file%, %section%, spoken_warning, "WarpGate"
section := "Chrono Boost Gateway/Warpgate"
IniRead, CG_control_group, %config_file%, %section%, CG_control_group, 9
IniRead, CG_nexus_Ctrlgroup_key, %config_file%, %section%, CG_nexus_Ctrlgroup_key, 4
IniRead, chrono_key, %config_file%, %section%, chrono_key, c
IniRead, CG_chrono_remainder, %config_file%, %section%, CG_chrono_remainder, 2
IniRead, ChronoBoostSleep, %config_file%, %section%, ChronoBoostSleep, 50
if IsFunc(FunctionName := "iniReadAutoChrono")
%FunctionName%(aAutoChronoCopy, aAutoChrono)
IniRead, auto_inject_sleep, %config_file%, Advanced Auto Inject Settings, auto_inject_sleep, 50
IniRead, Inject_SleepVariance, %config_file%, Advanced Auto Inject Settings, Inject_SleepVariance, 0
Inject_SleepVariance := 1 + (Inject_SleepVariance/100)
IniRead, CanQueenMultiInject, %config_file%, Advanced Auto Inject Settings, CanQueenMultiInject, 1
IniRead, Inject_RestoreSelection, %config_file%, Advanced Auto Inject Settings, Inject_RestoreSelection, 1
IniRead, Inject_RestoreScreenLocation, %config_file%, Advanced Auto Inject Settings, Inject_RestoreScreenLocation, 1
IniRead, drag_origin, %config_file%, Advanced Auto Inject Settings, drag_origin, Left
IniRead, race_reading, %config_file%, Read Opponents Spawn-Races, enable, 1
IniRead, Auto_Read_Races, %config_file%, Read Opponents Spawn-Races, Auto_Read_Races, 1
IniRead, read_races_key, %config_file%, Read Opponents Spawn-Races, read_key, LWin & F1
IniRead, workeron, %config_file%, Worker Production Helper, warning_enable, 1
IniRead, workerProductionTPIdle, %config_file%, Worker Production Helper, workerProductionTPIdle, 10
IniRead, workerproduction_time, %config_file%, Worker Production Helper, production_time_lapse, 24
workerproduction_time_if := workerproduction_time
IniRead, mineralon, %config_file%, Minerals, warning_enable, 1
IniRead, mineraltrigger, %config_file%, Minerals, mineral_trigger, 1000
IniRead, gas_on, %config_file%, Gas, warning_enable, 0
IniRead, gas_trigger, %config_file%, Gas, gas_trigger, 600
IniRead, idleon, %config_file%, Idle Workers, warning_enable, 1
IniRead, idletrigger, %config_file%, Idle Workers, idle_trigger, 5
IniRead, supplyon, %config_file%, Supply, warning_enable, 1
IniRead, minimum_supply, %config_file%, Supply, minimum_supply, 11
IniRead, supplylower, %config_file%, Supply, supplylower, 40
IniRead, supplymid, %config_file%, Supply, supplymid, 80
IniRead, supplyupper, %config_file%, Supply, supplyupper, 120
IniRead, sub_lowerdelta, %config_file%, Supply, sub_lowerdelta, 4
IniRead, sub_middelta, %config_file%, Supply, sub_middelta, 5
IniRead, sub_upperdelta, %config_file%, Supply, sub_upperdelta, 6
IniRead, above_upperdelta, %config_file%, Supply, above_upperdelta, 8
IniRead, sec_supply, %config_file%, Additional Warning Count, supply, 1
IniRead, sec_mineral, %config_file%, Additional Warning Count, minerals, 1
IniRead, sec_gas, %config_file%, Additional Warning Count, gas, 0
IniRead, sec_workerprod, %config_file%, Additional Warning Count, worker_production, 1
IniRead, sec_idle, %config_file%, Additional Warning Count, idle_workers, 0
Short_Race_List := "Terr|Prot|Zerg", section := "Auto Control Group", A_UnitGroupSettings := []
Loop, Parse, l_Races, `,
while (10 > i := A_index - 1)
A_UnitGroupSettings["LimitGroup", A_LoopField, i, "Enabled"] := IniRead(config_file, section, A_LoopField "_LimitGroup_" i, 0)
loop, parse, Short_Race_List, |
{
If (A_LoopField = "Terr")
Race := "Terran"
Else if (A_LoopField = "Prot")
Race := "Protoss"
Else If (A_LoopField = "Zerg")
Race := "Zerg"
A_UnitGroupSettings["AutoGroup", Race, "Enabled"] := IniRead(config_file, section, "AG_Enable_" A_LoopField , 0)
loop, 10
{
String := IniRead(config_file, section, "AG_" A_LoopField A_Index - 1, A_Space)
StringReplace, String, String, |, `, %a_space%, All
if Instr(String, A_Space A_Space)
StringReplace, String, String, %A_Space%%A_Space%, %A_Space%, All
list := ""
loop, parse, String, `,
{
if aUnitID.HasKey(string := Trim(A_LoopField, "`, `t"))
list .= string ", "
}
A_UnitGroupSettings[Race, A_Index - 1] := Trim(list, "`, `t")
}
}
IniRead, AGBufferDelay, %config_file%, %section%, AGBufferDelay, 50
IniRead, AGKeyReleaseDelay, %config_file%, %section%, AGKeyReleaseDelay, 60
IniRead, AGRestrictBufferDelay, %config_file%, %section%, AGRestrictBufferDelay, 90
aAGHotkeys := []
loop 10
{
group := A_index -1
IniRead, AGAddToGroup%group%, %config_file%, %section%, AGAddToGroup%group%, +%group%
IniRead, AGSetGroup%group%, %config_file%, %section%, AGSetGroup%group%, ^%group%
IniRead, AGInvokeGroup%group%, %config_file%, %section%, AGInvokeGroup%group%, %group%
aAGHotkeys["add", group] := AGAddToGroup%group%
aAGHotkeys["set", group] := AGSetGroup%group%
aAGHotkeys["invoke", group] := AGInvokeGroup%group%
}
section := "Volume"
IniRead, speech_volume, %config_file%, %section%, speech, 100
IniRead, programVolume, %config_file%, %section%, program, 100
IniRead, w_supply, %config_file%, Warnings, supply, "Supply"
IniRead, w_mineral, %config_file%, Warnings, minerals, "Money"
IniRead, w_gas, %config_file%, Warnings, gas, "Gas"
IniRead, w_workerprod_T, %config_file%, Warnings, worker_production_T, "Build SCV"
IniRead, w_workerprod_P, %config_file%, Warnings, worker_production_P, "Build Probe"
IniRead, w_workerprod_Z, %config_file%, Warnings, worker_production_Z, "Build Drone"
IniRead, w_idle, %config_file%, Warnings, idle_workers, "Idle"
IniRead, additional_delay_supply, %config_file%, Additional Warning Delay, supply, 10
IniRead, additional_delay_minerals, %config_file%, Additional Warning Delay, minerals, 10
IniRead, additional_delay_gas, %config_file%, Additional Warning Delay, gas, 10
IniRead, additional_delay_worker_production, %config_file%, Additional Warning Delay, worker_production, 25
IniRead, additional_idle_workers, %config_file%, Additional Warning Delay, idle_workers, 10
IniRead, worker_count_local_key, %config_file%, Misc Hotkey, worker_count_key, F8
IniRead, worker_count_enemy_key, %config_file%, Misc Hotkey, enemy_worker_count, Lwin & F8
IniRead, warning_toggle_key, %config_file%, Misc Hotkey, pause_resume_warnings_key, Lwin & Pause
IniRead, ping_key, %config_file%, Misc Hotkey, ping_map, Lwin & MButton
section := "Misc Settings"
IniRead, input_method, %config_file%, %section%, input_method, Input
IniRead, pSendDelay, %config_file%, %section%, pSendDelay, -1
IniRead, pClickDelay, %config_file%, %section%, pClickDelay, -1
IniRead, EventKeyDelay, %config_file%, %section%, EventKeyDelay, -1
IniRead, auto_update, %config_file%, %section%, auto_check_updates, 1
IniRead, launch_settings, %config_file%, %section%, launch_settings, 0
IniRead, MaxWindowOnStart, %config_file%, %section%, MaxWindowOnStart, 1
IniRead, HumanMouse, %config_file%, %section%, HumanMouse, 0
IniRead, HumanMouseTimeLo, %config_file%, %section%, HumanMouseTimeLo, 70
IniRead, HumanMouseTimeHi, %config_file%, %section%, HumanMouseTimeHi, 110
IniRead, UnitDetectionTimer_ms, %config_file%, %section%, UnitDetectionTimer_ms, 3500
IniRead, MTCustomIcon, %config_file%, %section%, MTCustomIcon, %A_Space%
IniRead, MTCustomProgramName, %config_file%, %section%, MTCustomProgramName, %A_Space%
MTCustomProgramName := Trim(MTCustomProgramName)
section := "Key Blocking"
IniRead, BlockingStandard, %config_file%, %section%, BlockingStandard, 1
IniRead, BlockingFunctional, %config_file%, %section%, BlockingFunctional, 1
IniRead, BlockingNumpad, %config_file%, %section%, BlockingNumpad, 1
IniRead, BlockingMouseKeys, %config_file%, %section%, BlockingMouseKeys, 1
IniRead, BlockingMultimedia, %config_file%, %section%, BlockingMultimedia, 1
IniRead, LwinDisable, %config_file%, %section%, LwinDisable, 1
IniRead, Key_EmergencyRestart, %config_file%, %section%, Key_EmergencyRestart, <#Space
aButtons := []
aButtons.List := getKeyboardAndMouseButtonArray(BlockingStandard*1 + BlockingFunctional*2 + BlockingNumpad*4
+ BlockingMouseKeys*8 + BlockingMultimedia*16)
section := "AutoWorkerProduction"
IniRead, EnableAutoWorkerTerranStart, %config_file%, %section%, EnableAutoWorkerTerranStart, 0
IniRead, EnableAutoWorkerProtossStart, %config_file%, %section%, EnableAutoWorkerProtossStart, 0
IniRead, ToggleAutoWorkerState_Key, %config_file%, %section%, ToggleAutoWorkerState_Key, #F2
IniRead, AutoWorkerQueueSupplyBlock, %config_file%, %section%, AutoWorkerQueueSupplyBlock, 1
IniRead, AutoWorkerAlwaysGroup, %config_file%, %section%, AutoWorkerAlwaysGroup, 1
IniRead, AutoWorkerAPMProtection, %config_file%, %section%, AutoWorkerAPMProtection, 160
IniRead, AutoWorkerStorage_T_Key, %config_file%, %section%, AutoWorkerStorage_T_Key, 3
IniRead, AutoWorkerStorage_P_Key, %config_file%, %section%, AutoWorkerStorage_P_Key, 3
IniRead, Base_Control_Group_T_Key, %config_file%, %section%, Base_Control_Group_T_Key, 4
IniRead, Base_Control_Group_P_Key, %config_file%, %section%, Base_Control_Group_P_Key, 4
IniRead, AutoWorkerMakeWorker_T_Key, %config_file%, %section%, AutoWorkerMakeWorker_T_Key, s
IniRead, AutoWorkerMakeWorker_P_Key, %config_file%, %section%, AutoWorkerMakeWorker_P_Key, e
IniRead, AutoWorkerMaxWorkerTerran, %config_file%, %section%, AutoWorkerMaxWorkerTerran, 80
IniRead, AutoWorkerMaxWorkerPerBaseTerran, %config_file%, %section%, AutoWorkerMaxWorkerPerBaseTerran, 30
IniRead, AutoWorkerMaxWorkerProtoss, %config_file%, %section%, AutoWorkerMaxWorkerProtoss, 80
IniRead, AutoWorkerMaxWorkerPerBaseProtoss, %config_file%, %section%, AutoWorkerMaxWorkerPerBaseProtoss, 30
section := "Misc Automation"
IniRead, SelectArmyEnable, %config_file%, %section%, SelectArmyEnable, 0
IniRead, Sc2SelectArmy_Key, %config_file%, %section%, Sc2SelectArmy_Key, {F2}
IniRead, castSelectArmy_key, %config_file%, %section%, castSelectArmy_key, F2
IniRead, SleepSelectArmy, %config_file%, %section%, SleepSelectArmy, 15
IniRead, ModifierBeepSelectArmy, %config_file%, %section%, ModifierBeepSelectArmy, 1
IniRead, SelectArmyOnScreen, %config_file%, %section%, SelectArmyOnScreen, 0
IniRead, SelectArmyDeselectXelnaga, %config_file%, %section%, SelectArmyDeselectXelnaga, 1
IniRead, SelectArmyDeselectPatrolling, %config_file%, %section%, SelectArmyDeselectPatrolling, 1
IniRead, SelectArmyDeselectHoldPosition, %config_file%, %section%, SelectArmyDeselectHoldPosition, 0
IniRead, SelectArmyDeselectFollowing, %config_file%, %section%, SelectArmyDeselectFollowing, 0
IniRead, SelectArmyDeselectLoadedTransport, %config_file%, %section%, SelectArmyDeselectLoadedTransport, 0
IniRead, SelectArmyDeselectQueuedDrops, %config_file%, %section%, SelectArmyDeselectQueuedDrops, 0
IniRead, SelectArmyControlGroupEnable, %config_file%, %section%, SelectArmyControlGroupEnable, 0
IniRead, Sc2SelectArmyCtrlGroup, %config_file%, %section%, Sc2SelectArmyCtrlGroup, 1
IniRead, SplitUnitsEnable, %config_file%, %section%, SplitUnitsEnable, 0
IniRead, castSplitUnit_key, %config_file%, %section%, castSplitUnit_key, F4
IniRead, SplitctrlgroupStorage_key, %config_file%, %section%, SplitctrlgroupStorage_key, 9
IniRead, SleepSplitUnits, %config_file%, %section%, SleepSplitUnits, 20
IniRead, l_DeselectArmy, %config_file%, %section%, l_DeselectArmy, %A_Space%
IniRead, DeselectSleepTime, %config_file%, %section%, DeselectSleepTime, 0
IniRead, RemoveUnitEnable, %config_file%, %section%, RemoveUnitEnable, 0
IniRead, castRemoveUnit_key, %config_file%, %section%, castRemoveUnit_key, +Esc
IniRead, RemoveDamagedUnitsEnable, %config_file%, %section%, RemoveDamagedUnitsEnable, 0
IniRead, castRemoveDamagedUnits_key, %config_file%, %section%, castRemoveDamagedUnits_key, !F1
IniRead, RemoveDamagedUnitsCtrlGroup, %config_file%, %section%, RemoveDamagedUnitsCtrlGroup, 9
IniRead, RemoveDamagedUnitsHealthLevel, %config_file%, %section%, RemoveDamagedUnitsHealthLevel, 90
RemoveDamagedUnitsHealthLevel := round(RemoveDamagedUnitsHealthLevel / 100, 3)
IniRead, RemoveDamagedUnitsShieldLevel, %config_file%, %section%, RemoveDamagedUnitsShieldLevel, 15
RemoveDamagedUnitsShieldLevel := round(RemoveDamagedUnitsShieldLevel / 100, 3)
IniRead, EasyUnloadTerranEnable, %config_file%, %section%, EasyUnloadTerranEnable, 0
IniRead, EasyUnloadProtossEnable, %config_file%, %section%, EasyUnloadProtossEnable, 0
IniRead, EasyUnloadZergEnable, %config_file%, %section%, EasyUnloadZergEnable, 0
IniRead, EasyUnloadHotkey, %config_file%, %section%, EasyUnloadHotkey, F5
IniRead, EasyUnloadQueuedHotkey, %config_file%, %section%, EasyUnloadQueuedHotkey, +F5
IniRead, EasyUnload_T_Key, %config_file%, %section%, EasyUnload_T_Key, d
IniRead, EasyUnload_P_Key, %config_file%, %section%, EasyUnload_P_Key, d
IniRead, EasyUnload_Z_Key, %config_file%, %section%, EasyUnload_Z_Key, d
IniRead, EasyUnloadStorageKey, %config_file%, %section%, EasyUnloadStorageKey, 9
IniRead, Playback_Alert_Key, %config_file%, Alert Location, Playback_Alert_Key, <#F7
alert_array := [],	alert_array := createAlertArray()
section := "Overlays"
DesktopScreenCoordinates(XminScreen, YminScreen, XmaxScreen, YmaxScreen)
list := "APMOverlay,IncomeOverlay,ResourcesOverlay,ArmySizeOverlay,WorkerOverlay,IdleWorkersOverlay,UnitOverlay,LocalPlayerColourOverlay,MacroTownHallOverlay,LocalUpgradesOverlay"
loop, parse, list, `,
{
IniRead, Draw%A_LoopField%, %config_file%, %section%, Draw%A_LoopField%, 0
IniRead, %A_LoopField%Scale, %config_file%, %section%, %A_LoopField%Scale, 1
if (%A_LoopField%Scale < .5)
%A_LoopField%Scale := .5
IniRead, %A_LoopField%X, %config_file%, %section%, %A_LoopField%X, % A_ScreenWidth/2
if (%A_LoopField%X = "" || %A_LoopField%X < XminScreen || %A_LoopField%X >= XmaxScreen - 30)
%A_LoopField%X := A_ScreenWidth/2
IniRead, %A_LoopField%Y, %config_file%, %section%, %A_LoopField%Y, % A_ScreenHeight/2
if (%A_LoopField%Y = "" || %A_LoopField%Y < YminScreen || %A_LoopField%Y >= YmaxScreen - 30)
%A_LoopField%Y := A_ScreenHeight/2
}
IniRead, ToggleAPMOverlayKey, %config_file%, %section%, ToggleAPMOverlayKey, <#A
IniRead, ToggleUnitOverlayKey, %config_file%, %section%, ToggleUnitOverlayKey, <#U
IniRead, ToggleIdleWorkersOverlayKey, %config_file%, %section%, ToggleIdleWorkersOverlayKey, <#L
IniRead, ToggleMinimapOverlayKey, %config_file%, %section%, ToggleMinimapOverlayKey, <#H
IniRead, ToggleIncomeOverlayKey, %config_file%, %section%, ToggleIncomeOverlayKey, <#I
IniRead, ToggleResourcesOverlayKey, %config_file%, %section%, ToggleResourcesOverlayKey, <#R
IniRead, ToggleArmySizeOverlayKey, %config_file%, %section%, ToggleArmySizeOverlayKey, <#A
IniRead, ToggleWorkerOverlayKey, %config_file%, %section%, ToggleWorkerOverlayKey, <#W
IniRead, AdjustOverlayKey, %config_file%, %section%, AdjustOverlayKey, Home
IniRead, ToggleIdentifierKey, %config_file%, %section%, ToggleIdentifierKey, <#Q
IniRead, OverlayIdent, %config_file%, %section%, OverlayIdent, 2
IniRead, SplitUnitPanel, %config_file%, %section%, SplitUnitPanel, 1
IniRead, unitPanelAlignNewUnits, %config_file%, %section%, unitPanelAlignNewUnits, 1
IniRead, DrawUnitUpgrades, %config_file%, %section%, DrawUnitUpgrades, 1
IniRead, unitPanelDrawStructureProgress, %config_file%, %section%, unitPanelDrawStructureProgress, 1
IniRead, unitPanelDrawUnitProgress, %config_file%, %section%, unitPanelDrawUnitProgress, 1
IniRead, unitPanelDrawUpgradeProgress, %config_file%, %section%, unitPanelDrawUpgradeProgress, 1
OverlayBackgrounds := False
IniRead, MiniMapRefresh, %config_file%, %section%, MiniMapRefresh, 300
IniRead, OverlayRefresh, %config_file%, %section%, OverlayRefresh, 1000
IniRead, UnitOverlayRefresh, %config_file%, %section%, UnitOverlayRefresh, 4500
IniRead, APMOverlayMode, %config_file%, %section%, APMOverlayMode, 0
IniRead, drawLocalPlayerResources, %config_file%, %section%, drawLocalPlayerResources, 0
IniRead, drawLocalPlayerIncome, %config_file%, %section%, drawLocalPlayerIncome, 0
IniRead, drawLocalPlayerArmy, %config_file%, %section%, drawLocalPlayerArmy, 0
IniRead, overlayAPMTransparency, %config_file%, %section%, overlayAPMTransparency, 255
IniRead, overlayIncomeTransparency, %config_file%, %section%, overlayIncomeTransparency, 255
IniRead, overlayMatchTransparency, %config_file%, %section%, overlayMatchTransparency, 255
IniRead, overlayResourceTransparency, %config_file%, %section%, overlayResourceTransparency, 255
IniRead, overlayArmyTransparency, %config_file%, %section%, overlayArmyTransparency, 255
IniRead, overlayHarvesterTransparency, %config_file%, %section%, overlayHarvesterTransparency, 255
IniRead, overlayIdleWorkerTransparency, %config_file%, %section%, overlayIdleWorkerTransparency, 255
IniRead, overlayLocalColourTransparency, %config_file%, %section%, overlayLocalColourTransparency, 255
IniRead, overlayMinimapTransparency, %config_file%, %section%, overlayMinimapTransparency, 255
IniRead, overlayMacroTownHallTransparency, %config_file%, %section%, overlayMacroTownHallTransparency, 255
IniRead, overlayLocalUpgradesTransparency, %config_file%, %section%, overlayLocalUpgradesTransparency, 255
IniRead, localUpgradesItemsPerRow, %config_file%, %section%, localUpgradesItemsPerRow, 6
section := "UnitPanelFilter"
aUnitPanelUnits := []
loop, parse, l_Races, `,
{
race := A_LoopField,
IniRead, list, %config_file%, %section%, %race%FilteredCompleted, %A_Space%
aUnitPanelUnits[race, "FilteredCompleted"] := []
ConvertListToObject(aUnitPanelUnits[race, "FilteredCompleted"], list)
IniRead, list, %config_file%, %section%, %race%FilteredUnderConstruction, %A_Space%
aUnitPanelUnits[race, "FilteredUnderConstruction"] := []
ConvertListToObject(aUnitPanelUnits[race, "FilteredUnderConstruction"], list)
list := ""
}
section := "MiniMap"
IniRead, UnitHighlightList1, %config_file%, %section%, UnitHighlightList1, SporeCrawler, SporeCrawlerUprooted, MissileTurret, PhotonCannon, Observer
IniRead, UnitHighlightList2, %config_file%, %section%, UnitHighlightList2, DarkTemplar, Changeling, ChangelingZealot, ChangelingMarineShield, ChangelingMarine, ChangelingZerglingWings, ChangelingZergling
IniRead, UnitHighlightList3, %config_file%, %section%, UnitHighlightList3, %A_Space%
IniRead, UnitHighlightList4, %config_file%, %section%, UnitHighlightList4, %A_Space%
IniRead, UnitHighlightList5, %config_file%, %section%, UnitHighlightList5, %A_Space%
IniRead, UnitHighlightList6, %config_file%, %section%, UnitHighlightList6, %A_Space%
IniRead, UnitHighlightList7, %config_file%, %section%, UnitHighlightList7, %A_Space%
IniRead, UnitHighlightList1Colour, %config_file%, %section%, UnitHighlightList1Colour, 0xFFFFFFFF
IniRead, UnitHighlightList2Colour, %config_file%, %section%, UnitHighlightList2Colour, 0xFFFF00FF
IniRead, UnitHighlightList3Colour, %config_file%, %section%, UnitHighlightList3Colour, 0xFF09C7CA
IniRead, UnitHighlightList4Colour, %config_file%, %section%, UnitHighlightList4Colour, 0xFFFFFF00
IniRead, UnitHighlightList5Colour, %config_file%, %section%, UnitHighlightList5Colour, 0xFF00FFFF
IniRead, UnitHighlightList6Colour, %config_file%, %section%, UnitHighlightList6Colour, 0xFFFFC663
IniRead, UnitHighlightList7Colour, %config_file%, %section%, UnitHighlightList7Colour, 0xFF21FBFF
UnitHighlightList1Colour |= 0xFF000000, UnitHighlightList2Colour |= 0xFF000000
UnitHighlightList3Colour |= 0xFF000000, UnitHighlightList4Colour |= 0xFF000000
UnitHighlightList5Colour |= 0xFF000000, UnitHighlightList6Colour |= 0xFF000000
UnitHighlightList7Colour |= 0xFF000000
IniRead, HighlightInvisible, %config_file%, %section%, HighlightInvisible, 1
IniRead, UnitHighlightInvisibleColour, %config_file%, %section%, UnitHighlightInvisibleColour, 0xFFB7FF00
UnitHighlightInvisibleColour |= 0xFF000000
IniRead, HighlightHallucinations, %config_file%, %section%, HighlightHallucinations, 1
IniRead, UnitHighlightHallucinationsColour, %config_file%, %section%, UnitHighlightHallucinationsColour, 0xFF808080
UnitHighlightHallucinationsColour |= 0xFF000000
if !isObject(aChooseColourCustomPalette)
{
aChooseColourCustomPalette := []
loop 7
aChooseColourCustomPalette.insert(UnitHighlightList%A_Index%Colour & 0xFFFFFF)
aChooseColourCustomPalette.insert(UnitHighlightInvisibleColour & 0xFFFFFF)
aChooseColourCustomPalette.insert(UnitHighlightHallucinationsColour & 0xFFFFFF)
}
IniRead, UnitHighlightExcludeList, %config_file%, %section%, UnitHighlightExcludeList, CreepTumor, CreepTumorBurrowed
IniRead, DrawMiniMap, %config_file%, %section%, DrawMiniMap, 1
IniRead, TempHideMiniMapKey, %config_file%, %section%, TempHideMiniMapKey, !Space
IniRead, DrawSpawningRaces, %config_file%, %section%, DrawSpawningRaces, 1
IniRead, DrawAlerts, %config_file%, %section%, DrawAlerts, 1
IniRead, DrawUnitDestinations, %config_file%, %section%, DrawUnitDestinations, 0
IniRead, DrawPlayerCameras, %config_file%, %section%, DrawPlayerCameras, 0
IniRead, HostileColourAssist, %config_file%, %section%, HostileColourAssist, 0
section := "Hidden Options"
IniRead, AutoGroupTimer, %config_file%, %section%, AutoGroupTimer, 30
IniRead, AutoGroupTimerIdle, %config_file%, %section%, AutoGroupTimerIdle, 5
Iniread, ResumeWarnings, %config_file%, Resume Warnings, Resume, 0
section := "Misc Info"
IniRead, MT_HasWarnedLanguage, %config_file%, %section%, MT_HasWarnedLanguage, 0
IniRead, MT_Restart, %config_file%, %section%, RestartMethod, 0
if MT_Restart
IniWrite, 0, %config_file%, %section%, RestartMethod
IniRead, MT_DWMwarned, %config_file%, %section%, MT_DWMwarned, 0
if IsFunc(FunctionName := "iniReadQuickSelect")
%FunctionName%(aQuickSelectCopy, aQuickSelect)
initialiseBrushColours(aHexColours, a_pBrushes)
return
}
stripModifiers(pressedKey)
{
StringReplace, pressedKey, pressedKey, ^
StringReplace, pressedKey, pressedKey, +
StringReplace, pressedKey, pressedKey, !
StringReplace, pressedKey, pressedKey, *
StringReplace, pressedKey, pressedKey, ~
return pressedKey
}
getCursorUnit()
{
p1 := readMemory(B_UnitCursor, GameIdentifier)
p2 := readMemory(p1 + O1_UnitCursor, GameIdentifier)
if (index := readMemory(p2 + O2_UnitCursor, GameIdentifier))
return index >> 18
return -1
}
getCargoCount(unit, byRef isUnloading := "")
{
transportStructure := readmemory(getUnitAbilityPointer(unit) + 0x24, GameIdentifier)
totalLoaded := readmemory(transportStructure + 0x3C, GameIdentifier)
totalUnloaded := readmemory(transportStructure + 0x40, GameIdentifier)
isUnloading := readmemory(transportStructure + 0x0C, GameIdentifier) = 259 ? 1 : 0
return totalLoaded - totalUnloaded
}
isTransportUnloading(unit)
{
transportStructure := readmemory(getUnitAbilityPointer(unit) + 0x24, GameIdentifier)
return readmemory(transportStructure + 0x0C, GameIdentifier) = 259 ? 1 : 0
}
getUnitMaxHp(unit)
{   global B_uStructure, S_uStructure, O_uModelPointer
mp := readMemory(B_uStructure + unit * S_uStructure + O_uModelPointer, GameIdentifier) << 5 & 0xFFFFFFFF
addressArray := readMemory(mp + 0xC, GameIdentifier, 4)
pCurrentModel := readMemory(addressArray + 0x4, GameIdentifier, 4)
return round(readMemory(pCurrentModel + 0x2C, GameIdentifier) / 4096)
}
getUnitMaxShield(unit)
{   global B_uStructure, S_uStructure, O_uModelPointer
mp := readMemory(B_uStructure + unit * S_uStructure + O_uModelPointer, GameIdentifier) << 5 & 0xFFFFFFFF
addressArray := readMemory(mp + 0xC, GameIdentifier, 4)
pCurrentModel := readMemory(addressArray + 0x4, GameIdentifier, 4)
return round(readMemory(pCurrentModel + 0xA0, GameIdentifier) / 4096)
}
getUnitCurrentHp(unit)
{
return getUnitMaxHp(unit) - getUnitHpDamage(unit)
}
getUnitPercentHP(unit)
{
return (!percent := ((maxHP := getUnitMaxHp(unit)) - getUnitHpDamage(unit)) / maxHP) ? 1 : percent
}
getUnitPercentShield(unit)
{
return ((maxShield := getUnitMaxShield(unit)) - getUnitShieldDamage(unit)) / maxShield
}
getUnitCurrentShields(unit)
{
return getUnitMaxShield(unit) - getUnitShieldDamage(unit)
}
getCurrentHpAndShields(unit, byRef result)
{
global B_uStructure, S_uStructure, O_uModelPointer
result := []
mp := readMemory(B_uStructure + unit * S_uStructure + O_uModelPointer, GameIdentifier) << 5 & 0xFFFFFFFF
addressArray := readMemory(mp + 0xC, GameIdentifier, 4)
pCurrentModel := readMemory(addressArray + 0x4, GameIdentifier, 4)
result.health := round(readMemory(pCurrentModel + 0x2C, GameIdentifier) / 4096) - getUnitHpDamage(unit)
result.shields :=  round(readMemory(pCurrentModel + 0xA0, GameIdentifier) / 4096) - getUnitShieldDamage(unit)
result.unitIndex := unit
return
}
getStructureMorphProgress(pAbilities, unitType)
{
p := pointer(GameIdentifier, findAbilityTypePointer(pAbilities, unitType, "BuildInProgress"), 0x10, 0xD4)
timeRemaining := ReadMemory(p + 0x98, GameIdentifier)
totalTime := ReadMemory(p + 0xB4, GameIdentifier)
return round((totalTime - timeRemaining)/totalTime, 2)
}
getUnitMorphTimeOld(unit)
{
p := ReadMemory(B_uStructure + unit * S_uStructure + O_P_uCmdQueuePointer, GameIdentifier)
timeRemaining := ReadMemory(p + 0x98, GameIdentifier)
totalTime := ReadMemory(p + 0xB4, GameIdentifier)
return round((totalTime - timeRemaining)/totalTime, 2)
}
getUnitMorphTime(unit, unitType, percent := True)
{
static targetIsPoint := 0x8, targetIsUnit := 0x10, hasRun := False, aMorphStrings
if !hasRun
{
hasRun := True
aMorphStrings := { 	aUnitID.OverlordCocoon: ["MorphToOverseer"]
,	aUnitID.BroodLordCocoon: ["MorphToBroodLord"]
,	aUnitID.Spire: ["UpgradeToGreaterSpire"]
,  aUnitID.Hatchery: ["UpgradeToLair"]
,	aUnitID.Lair: ["UpgradeToHive"]
,  aUnitID.MothershipCore: ["MorphToMothership"]
,	aUnitID.CommandCenter: ["UpgradeToOrbital", "UpgradeToPlanetaryFortress"]}
}
if (CmdQueue := ReadMemory(B_uStructure + unit * S_uStructure + O_P_uCmdQueuePointer, GameIdentifier))
{
pNextCmd := ReadMemory(CmdQueue, GameIdentifier)
loop
{
ReadRawMemory(pNextCmd & -2, GameIdentifier, cmdDump, 0xB8)
targetFlag := numget(cmdDump, 0x38, "UInt")
if !aStringTable.hasKey(pString := numget(cmdDump, 0x18, "UInt"))
aStringTable[pString] := ReadMemory_Str(readMemory(pString + 0x4, GameIdentifier), GameIdentifier)
for i, morphString in aMorphStrings[unitType]
{
if (morphString = aStringTable[pString])
{
timeRemaining := numget(cmdDump, 0x98, "UInt")
totalTime := numget(cmdDump, 0xB4, "UInt")
return round(percent
? (totalTime - timeRemaining)/totalTime
: timeRemaining / 65536
, 2)
}
}
} Until (A_Index > 20 || !(targetFlag & targetIsPoint || targetFlag & targetIsUnit || targetFlag = 7)
|| 1 & pNextCmd := numget(cmdDump, 0, "Int"))
}
else return 0
}
getBanelingMorphTime(pAbilities)
{
p := pointer(GameIdentifier, findAbilityTypePointer(pAbilities, aUnitID.BanelingCocoon, "MorphZerglingToBaneling"), 0x12c, 0x0)
totalTime := ReadMemory(p + 0x68, GameIdentifier)
timeRemaining := ReadMemory(p + 0x6c, GameIdentifier)
return round((totalTime - timeRemaining)/totalTime, 2)
}
getArchonMorphTime(pAbilities)
{
pMergeable := readmemory(findAbilityTypePointer(pAbilities, aUnitID.Archon, "Mergeable"), GameIdentifier)
totalTime := ReadMemory(pMergeable + 0x28, GameIdentifier)
timeRemaining := ReadMemory(pMergeable + 0x2C, GameIdentifier)
return round((totalTime - timeRemaining)/totalTime, 2)
}
getAddonStatus(pAbilities, unitType)
{
STATIC O_IndexParentTypes := 0x18, hasRun := False, aAddonStrings := [], aOffsets := []
if !hasRun
{
hasRun := True
aAddonStrings := { 	aUnitID.Barracks: "BarracksAddOns"
,	aUnitID.Factory: "FactoryAddOns"
,	aUnitID.Starport: "StarportAddOns"}
}
if aAddonStrings.HasKey(unitType) && readmemory(readmemory(findAbilityTypePointer(pAbilities, unitType, aAddonStrings[unitType]), GameIdentifier) + 0x28, GameIdentifier)
{
if !aOffsets.HasKey(unitType)
aOffsets[unitType] := O_IndexParentTypes + 4 * getCAbilQueueIndex(pAbilities, getAbilitiesCount(pAbilities))
if readmemory(readmemory(pAbilities + aOffsets[unitType], GameIdentifier) + 0x48, GameIdentifier)
return 1
return -1
}
return 0
}
getBuildProgress(pAbilities, type)
{
static O_TotalBuildTime := 0x28, O_TimeRemaining := 0x2C
if pBuild := findAbilityTypePointer(pAbilities, type, type != aUnitID["NydusCanal"] ? "BuildInProgress" : "BuildinProgressNydusCanal")
{
B_Build := ReadMemory(pBuild, GameIdentifier)
totalTime := readmemory(B_Build + O_TotalBuildTime, GameIdentifier)
remainingTime := readmemory(B_Build + O_TimeRemaining, GameIdentifier)
return round((totalTime - remainingTime) / totalTime, 2)
}
else return 1
}
getUnitBuff(unit, byRef buffNameOrObject)
{
static aBuffStringOffsets := []
if !buffArray := ReadMemory(B_uStructure + unit * S_uStructure + O_uBuffPointer, GameIdentifier)
return 0
buffCount := 0
while (p := ReadMemory(buffArray + 0x04 + 4*(A_Index-1), GameIdentifier)) && (A_Index < 20)
{
if !baseTimer := ReadMemory(p + 0x58, GameIdentifier)
continue
if !p := ReadMemory(baseTimer + 0x4, GameIdentifier) & -2
continue
if !p := ReadMemory(p + 0x4, GameIdentifier)
continue
if !p := ReadMemory(p + 0xA8, GameIdentifier)
continue
aBuffStringOffsets.HasKey(p)
? buffString := aBuffStringOffsets[p]
: aBuffStringOffsets[p] := buffString := ReadMemory_Str(ReadMemory(p + 0x4, GameIdentifier), GameIdentifier)
if buffString
{
totalTime :=  ReadMemory(baseTimer, GameIdentifier)
, remainingTime := ReadMemory(baseTimer+ 0x10, GameIdentifier)
, percent := round((totalTime - remainingTime) / totalTime, 2)
if IsObject(buffNameOrObject)
buffNameOrObject.insert(buffString, percent), buffCount++
else if (buffNameOrObject = buffString)
return percent
}
}
if IsObject(buffNameOrObject)
return buffCount
return 0
}
getTownHallLarvaCount(unit)
{
if !buffArray := ReadMemory(B_uStructure + unit * S_uStructure + O_uBuffPointer, GameIdentifier)
return 0
if !p :=  ReadMemory(buffArray + 0x8, GameIdentifier)
return 0
return ReadMemory(p + 0x5C, GameIdentifier)
}
isPhotonOverChargeActive(unit)
{
return (1 = ReadMemory(ReadMemory(findAbilityTypePointer(getUnitAbilityPointer(unit), aUnitID["Nexus"], "attackProtossBuilding"), GameIdentifier) + 0x54, GameIdentifier)
? True
: False)
}
getunitAddress(unit)
{
return B_uStructure + unit * S_uStructure
}
getUnitTargetFilterString(unit)
{
targetFilter := getUnitTargetFilter(unit)
for k, v in aUnitTargetFilter
v & targetFilter ? s .= (s ? "`n" : "") k
return s
}
twoUIntAsUint64(uInt1, uInt2 := "")
{
if (uInt2 = "")
uInt2 := uInt1
VarSetCapacity(address, 8, 0)
NumPut(uInt1, address, 0, "UInt")
NumPut(uInt2, address, 4, "UInt")
return numget(address, 0, "UInt64")
}
twoBoolsAsShort(bool1, bool2 := "")
{
if (bool2 = "")
bool2 := bool1
VarSetCapacity(address, 2, 0)
NumPut(bool1, address, 0, "Char")
NumPut(bool2, address, 1, "Char")
return numget(address, 0, "Short")
}
twoShortsAsInt(short1, short2 := "")
{
if (short2 = "")
short2 := short1
VarSetCapacity(address, 4, 0)
NumPut(short1, address, 0, "Short")
NumPut(short2, address, 2, "Short")
return numget(address, 0, "UInt")
}
debug(text, byRef newHeader := 0)
{
FileAppend, % (newHeader != 0 ? newHeader : A_Min ":" A_Sec " - ") text "`n", *
return
}
log(text, logFile := "log.txt")
{
FileAppend, %text%`n, %logFile%
return
}
formatSeconds(seconds)
{
seconds := ceil(seconds)
time = 19990101
time += %seconds%, seconds
FormatTime, mss, %time%, m:ss
return lTrim(seconds//3600 ":" mss, "0:")
}
Global aUnitID, aUnitName, aUnitSubGroupAlias, aUnitTargetFilter, aHexColours
, aUnitModel,  aPlayer, aLocalPlayer, minimap
, a_pBrushes := [], a_pPens := [], a_pBitmap
SetupUnitIDArray(aUnitID, aUnitName)
getSubGroupAliasArray(aUnitSubGroupAlias)
setupTargetFilters(aUnitTargetFilter)
SetupColourArrays(aHexColours, MatrixColour)
a_pPens := initialisePenColours(aHexColours)
CreatepBitmaps(a_pBitmap, aUnitID, MatrixColour)
global aUnitInfo := []
readConfigFile(), hasReadConfig := True
global aOverlayTitles := []
for i, overlay in ["IncomeOverlay", "ResourcesOverlay", "ArmySizeOverlay", "WorkerOverlay", "IdleWorkersOverlay", "UnitOverlay", "LocalPlayerColourOverlay", "APMOverlay", "MacroTownHallOverlay", "LocalUpgradesOverlay"]
aOverlayTitles[overlay] := getRandomString_Az09(10, 20)
global MT_CurrentGame
global aPlayer, aLocalPlayer
global aEnemyAndLocalPlayer
gameChange()
return
ShutdownProcedure:
Closed := ReadMemory()
Closed := ReadRawMemory()
Closed := ReadMemory_Str()
ExitApp
Return
gClock:
if (!time := getTime())
gameChange()
return
gosubAllOverlays:
if hasReadConfig
{
gosub, overlayTimer
gosub, unitPanelOverlayTimer
}
return
overlayTimer:
If (WinActive(GameIdentifier) || Dragoverlay)
{
If DrawIncomeOverlay
DrawIncomeOverlay(ReDrawIncome, IncomeOverlayScale, OverlayIdent, OverlayBackgrounds, Dragoverlay)
If DrawAPMOverlay
DrawAPMOverlay(ReDrawAPM, APMOverlayScale, OverlayIdent, modeAPM_EPM, Dragoverlay)
If DrawResourcesOverlay
DrawResourcesOverlay(ReDrawResources, ResourcesOverlayScale, OverlayIdent, OverlayBackgrounds, Dragoverlay)
If DrawArmySizeOverlay
DrawArmySizeOverlay(ReDrawArmySize, ArmySizeOverlayScale, OverlayIdent, OverlayBackgrounds, Dragoverlay)
If DrawWorkerOverlay
DrawWorkerOverlay(ReDrawWorker, WorkerOverlayScale, Dragoverlay)
If DrawIdleWorkersOverlay
DrawIdleWorkersOverlay(ReDrawIdleWorkers, IdleWorkersOverlayScale, dragOverlay)
if (DrawLocalPlayerColourOverlay && (GameType != "1v1" && GameType != "FFA"))
DrawLocalPlayerColour(ReDrawLocalPlayerColour, LocalPlayerColourOverlayScale, DragOverlay)
If DrawMacroTownHallOverlay
DrawMacroTownHallOverlay(RedrawMacroTownHall, MacroTownHallOverlayScale, DragOverlay)
}
else if (!WinActive(GameIdentifier) && !Dragoverlay && !areOverlaysWaitingToRedraw())
DestroyOverlays()
Return
unitPanelOverlayTimer:
If (WinActive(GameIdentifier) || Dragoverlay)
{
If (DrawUnitOverlay || DrawUnitUpgrades)
{
getEnemyUnitCount(aEnemyUnits, aEnemyUnitConstruction, aEnemyCurrentUpgrades)
FilterUnits(aEnemyUnits, aEnemyUnitConstruction, aUnitPanelUnits)
DrawUnitOverlay(RedrawUnit, UnitOverlayScale, OverlayIdent, Dragoverlay)
}
If DrawLocalUpgradesOverlay
DrawLocalUpgradesOverlay(RedrawLocalUpgrades, LocalUpgradesOverlayScale, DragOverlay)
}
else if (!WinActive(GameIdentifier) && !Dragoverlay && !areOverlaysWaitingToRedraw())
DestroyOverlays()
return
updateUserSettings()
{
Global hasReadConfig
readConfigFile()
hasReadConfig := True
}
gameChange()
{
global
if !hasReadConfig
readConfigFile(), hasReadConfig := True
if !hasLoadedMemoryAddresses
{
Process, wait, %GameExe%
while (!(B_SC2Process := getProcessBaseAddress(GameIdentifier)) || B_SC2Process < 0)
sleep 400
hasLoadedMemoryAddresses := loadMemoryAddresses(B_SC2Process)
}
if (Time := getTime())
{
aUnitModel := [], aStringTable := [], MT_CurrentGame := []
if WinActive(GameIdentifier)
ReDrawMiniMap := ReDrawIncome := ReDrawResources := ReDrawArmySize := ReDrawWorker := RedrawUnit := ReDrawIdleWorkers := ReDrawLocalPlayerColour := 1
getPlayers(aPlayer, aLocalPlayer, aEnemyAndLocalPlayer)
GameType := GetGameType(aPlayer)
getLongestPlayerNames(LongestEnemyName, LongestName)
MT_CurrentGame.LongestEnemyName := LongestEnemyName, MT_CurrentGame.LongestName := LongestName
SetTimer, overlayTimer, %OverlayRefresh%
SetTimer, unitPanelOverlayTimer, %UnitOverlayRefresh%
settimer, gClock, 1000, -4
}
else
{
SetTimer, overlayTimer, off
SetTimer, unitPanelOverlayTimer, off
SetTimer, gClock, off
DestroyOverlays()
}
return
}
increaseOverlayTimer()
{
global
SetTimer, overlayTimer, 50
SetTimer, unitPanelOverlayTimer, 50
SetTimer, overlayTimerSetOriginal, -60000
return
overlayTimerSetOriginal:
SetTimer, overlayTimer, %OverlayRefresh%
SetTimer, unitPanelOverlayTimer, %UnitOverlayRefresh%
return
}
restoreOverlayTimer()
{
global
SetTimer, overlayTimer, %OverlayRefresh%
SetTimer, overlayTimer, %UnitOverlayRefresh%
return
}
overlayToggle(hotkey)
{
global
if 0
{
If ((ActiveOverlays := DrawIncomeOverlay + DrawResourcesOverlay + DrawArmySizeOverlay + DrawAPMOverlay + ((DrawUnitOverlay || DrawUnitUpgrades) ? 1 : 0)) > 1)
{
DrawResourcesOverlay := DrawArmySizeOverlay := DrawAPMOverlay := DrawIncomeOverlay := DrawUnitOverlay := DrawUnitUpgrades := 0
DrawResourcesOverlay(-1), DrawArmySizeOverlay(-1), DrawAPMOverlay(-1), DrawIncomeOverlay(-1), DrawUnitOverlay(-1)
}
Else If (ActiveOverlays = 0)
DrawIncomeOverlay := 1
Else
{
If DrawIncomeOverlay
DrawResourcesOverlay := !DrawIncomeOverlay := DrawUnitOverlay := 0, DrawIncomeOverlay(-1)
Else If DrawResourcesOverlay
DrawArmySizeOverlay := !DrawResourcesOverlay := DrawUnitOverlay := 0, DrawResourcesOverlay(-1)
Else If DrawArmySizeOverlay
DrawAPMOverlay := !DrawResourcesOverlay := DrawArmySizeOverlay :=  0, DrawArmySizeOverlay(-1)
Else If DrawAPMOverlay
DrawUnitUpgrades := DrawUnitOverlay := !DrawAPMOverlay :=  0, DrawAPMOverlay(-1)
Else If (DrawUnitOverlay || DrawUnitUpgrades)
DrawResourcesOverlay := DrawArmySizeOverlay := DrawAPMOverlay := DrawIncomeOverlay := 1
}
SetTimer, gosubAllOverlays, -5
}
Else If (hotkey = ToggleIncomeOverlayKey "")
{
If (!DrawIncomeOverlay := !DrawIncomeOverlay)
DrawIncomeOverlay(-1)
}
Else If (hotkey = ToggleResourcesOverlayKey "")
{
If (!DrawResourcesOverlay := !DrawResourcesOverlay)
DrawResourcesOverlay(-1)
}
Else If (hotkey = ToggleArmySizeOverlayKey "")
{
If (!DrawArmySizeOverlay := !DrawArmySizeOverlay)
DrawArmySizeOverlay(-1)
}
Else If (hotkey = ToggleWorkerOverlayKey "")
{
If (!DrawWorkerOverlay := !DrawWorkerOverlay)
DrawWorkerOverlay(-1)
}
Else If (hotkey = ToggleIdleWorkersOverlayKey "")
{
If (!DrawIdleWorkersOverlay := !DrawIdleWorkersOverlay)
DrawIdleWorkersOverlay(-1)
}
Else If (hotkey = ToggleUnitOverlayKey "")
{
if (!DrawUnitOverlay && !DrawUnitUpgrades)
DrawUnitOverlay := True
else if (DrawUnitOverlay && !DrawUnitUpgrades)
DrawUnitUpgrades := True
else if (DrawUnitOverlay && DrawUnitUpgrades)
DrawUnitOverlay := False, DrawUnitUpgrades := True
else if (!DrawUnitOverlay && DrawUnitUpgrades)
DrawUnitUpgrades := False
If (!DrawUnitOverlay && !DrawUnitUpgrades)
DrawUnitOverlay(-1)
}
SetTimer, gosubAllOverlays, -5
Return
}
toggleIdentifier()
{
global
If OverlayIdent = 3
OverlayIdent := 0
Else OverlayIdent ++
Iniwrite, %OverlayIdent%, %config_file%, Overlays, OverlayIdent
SetTimer, gosubAllOverlays, -5
return
}
HiWord(number)
{
if (number & 0x80000000)
return (number >> 16)
return (number >> 16) & 0xffff
}
OverlayResize_WM_MOUSEWHEEL(wParam)
{
local WheelMove, ActiveTitle, newScale, Scale
WheelMove := wParam > 0x7FFFFFFF ? HiWord(-(~wParam)-1)/120 :  HiWord(wParam)/120
WinGetActiveTitle, ActiveTitle
for overlayName, overlayTitle in aOverlayTitles
{
if (ActiveTitle = overlayTitle)
{
newScale := %overlayName%Scale + WheelMove*.05
if (newScale >= .5)
%overlayName%Scale := newScale
else newScale := %overlayName%Scale := .5
IniWrite, %newScale%, %config_file%, Overlays, %overlayName%Scale
return
}
}
return
}
OverlayMove_LButtonDown()
{
PostMessage, 0xA1, 2
}
DrawIdleWorkersOverlay(ByRef Redraw, UserScale=1,Drag=0, expand=1)
{	global aLocalPlayer, GameIdentifier, config_file, IdleWorkersOverlayX, IdleWorkersOverlayY, a_pBitmap, overlayIdleWorkerTransparency
static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0
DestX := DestY := 0
idleCount := getIdleWorkers()
If (Redraw = -1 || !idleCount)
{
Try Gui, idleWorkersOverlay: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier) && idleCount)
{
Try Gui, idleWorkersOverlay: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, idleWorkersOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
Gui, idleWorkersOverlay: Show, NA X%idleWorkersOverlayX% Y%idleWorkersOverlayY% W400 H400, % aOverlayTitles["idleWorkersOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
}
If (Drag AND !DragPrevious)
{	DragPrevious := 1
Gui, idleWorkersOverlay: -E0x20
}
Else if (!Drag AND DragPrevious)
{	DragPrevious := 0
Gui, idleWorkersOverlay: +E0x20 +LastFound
WinGetPos,idleWorkersOverlayX,idleWorkersOverlayY
IniWrite, %idleWorkersOverlayX%, %config_file%, Overlays, idleWorkersOverlayX
Iniwrite, %idleWorkersOverlayY%, %config_file%, Overlays, idleWorkersOverlayY
}
hbm := CreateDIBSection(400, 400)
, hdc := CreateCompatibleDC()
, obm := SelectObject(hdc, hbm)
, G := Gdip_GraphicsFromHDC(hdc)
, Gdip_SetInterpolationMode(G, 2)
pBitmap := a_pBitmap[aLocalPlayer["Race"],"Worker"]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
expandOnIdle := 4
if expand
{
increased := floor(idlecount / expandOnIdle)/8
if (increased > .5)
increased := .5
UserScale += increased
}
Options := " cFFFFFFFF r4 s" 18*UserScale
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_TextToGraphics(G, idleCount, "x"(DestX+Width+2*UserScale) "y"(DestY+(Height//4)) Options, Font, TextWidthHeight, TextWidthHeight)
Gdip_DeleteGraphics(G)
UpdateLayeredWindow(hwnd1, hdc,,,,, overlayIdleWorkerTransparency)
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
Return
}
DrawIncomeOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, Background=0,Drag=0)
{	global aLocalPlayer, aHexColours, aPlayer, GameIdentifier, IncomeOverlayX, IncomeOverlayY, config_file, a_pBitmap, overlayIncomeTransparency
, drawLocalPlayerIncome
static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0
DestX := i := 0
Options := " cFFFFFFFF r4 s" 17*UserScale
If (Redraw = -1)
{
Try Gui, IncomeOverlay: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier))
{
Try Gui, IncomeOverlay: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, IncomeOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
Gui, IncomeOverlay: Show, NA X%IncomeOverlayX% Y%IncomeOverlayY% W400 H400, % aOverlayTitles["IncomeOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
}
If (Drag AND !DragPrevious)
{	DragPrevious := 1
Gui, IncomeOverlay: -E0x20
}
Else if (!Drag AND DragPrevious)
{	DragPrevious := 0
Gui, IncomeOverlay: +E0x20 +LastFound
WinGetPos,IncomeOverlayX,IncomeOverlayY,w,h
IniWrite, %IncomeOverlayX%, %config_file%, Overlays, IncomeOverlayX
Iniwrite, %IncomeOverlayY%, %config_file%, Overlays, IncomeOverlayY
}
hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
, hdc := CreateCompatibleDC()
, obm := SelectObject(hdc, hbm)
, G := Gdip_GraphicsFromHDC(hdc)
, Gdip_SetInterpolationMode(G, 2)
For index, player in aEnemyAndLocalPlayer
{
if ((slot_number := player["Slot"]) != aLocalPlayer["Slot"] || drawLocalPlayerIncome)
{
DestY := i ? i*Height : 0
If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
{
IF (PlayerIdentifier = 2)
OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
Else IF (PlayerIdentifier = 1)
OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font)
if !LongestNameSize
{
if drawLocalPlayerIncome
longestName := MT_CurrentGame.LongestName
else
longestName := MT_CurrentGame.LongestEnemyName
LongestNameData :=	gdip_TextToGraphics(G, longestName, "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale, Font)
StringSplit, LongestNameSize, LongestNameData, |
LongestNameSize := LongestNameSize3
}
DestX := LongestNameSize+10*UserScale
}
Else If (PlayerIdentifier = 3)
{
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
DestX := Width+10*UserScale
}
Else
{
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
}
Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_TextToGraphics(G, getPlayerMineralIncome(slot_number), "x"(DestX+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Gas",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, DestX + (85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_TextToGraphics(G, getPlayerGasIncome(slot_number), "x"(DestX+(85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Worker"]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, DestX + (2*85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
TextData := Gdip_TextToGraphics(G, getPlayerWorkerCount(slot_number), "x"(DestX+(2*85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)
StringSplit, TextSize, TextData, |
if (WindowWidth < CurrentWidth := DestX+(2*85*UserScale)+Width+5*UserScale + TextSize3)
WindowWidth := CurrentWidth
i++
}
}
WindowHeight := DestY+Height
if !WindowWidth
WindowWidth := 20
else if (WindowWidth > A_ScreenWidth)
WindowWidth := A_ScreenWidth
if !WindowHeight
WindowHeight := 20
else if (WindowHeight > A_ScreenHeight)
WindowHeight := A_ScreenHeight
Gdip_DeleteGraphics(G)
UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayIncomeTransparency)
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
Return
}
DrawAPMOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, modeAPM_EPM=0,Drag=0)
{	global aLocalPlayer, aHexColours, aPlayer, GameIdentifier, APMOverlayX, APMOverlayY, config_file, a_pBitmap, overlayAPMTransparency
, APMOverlayMode
static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0
DestX := i := 0
Options := " cFFFFFFFF Right r4 s" 20*UserScale
If (Redraw = -1)
{
Try Gui, APMOverlay: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier))
{
Try Gui, APMOverlay: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, APMOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
Gui, APMOverlay: Show, NA X%APMOverlayX% Y%APMOverlayY% W400 H400, % aOverlayTitles["APMOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
}
If (Drag AND !DragPrevious)
{	DragPrevious := 1
Gui, APMOverlay: -E0x20
}
Else if (!Drag AND DragPrevious)
{	DragPrevious := 0
Gui, APMOverlay: +E0x20 +LastFound
WinGetPos,APMOverlayX,APMOverlayY,w,h
IniWrite, %APMOverlayX%, %config_file%, Overlays, APMOverlayX
Iniwrite, %APMOverlayY%, %config_file%, Overlays, APMOverlayY
}
hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
, hdc := CreateCompatibleDC()
, obm := SelectObject(hdc, hbm)
, G := Gdip_GraphicsFromHDC(hdc)
, Gdip_SetInterpolationMode(G, 2)
DestX := 0
For index, player in aEnemyAndLocalPlayer
{
slot_number := player["Slot"]
if ( (( slot_number = aLocalPlayer["Slot"] && APMOverlayMode) || (slot_number != aLocalPlayer["Slot"] && (!APMOverlayMode || APMOverlayMode = -1))) && isPlayerActive(slot_number))
{
DestY := i ? i*Height : 0
If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
{
IF (PlayerIdentifier = 2)
OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
Else IF (PlayerIdentifier = 1)
OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font)
if !LongestNameSize
{
if (APMOverlayMode = -1)
longestName := MT_CurrentGame.LongestName
else if (APMOverlayMode = 0)
longestName := MT_CurrentGame.LongestEnemyName
else
longestName := aLocalPlayer["Name"]
LongestNameData :=	gdip_TextToGraphics(G, longestName, "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale, Font)
StringSplit, LongestNameSize, LongestNameData, |
LongestNameSize := LongestNameSize3
}
DestX := LongestNameSize+10*UserScale
}
Else If (PlayerIdentifier = 3)
{
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
DestX := Width+10*UserScale
DestY += Height//4
}
TextData := Gdip_TextToGraphics(G, getPlayerCurrentAPM(slot_number), "x"DestX "y"DestY " W" 50*UserScale " "  Options, Font)
StringSplit, TextSize, TextData, |
if (Height < TextSize4)
Height := TextSize4
if (WindowWidth < CurrentWidth := DestX+(40*UserScale) + TextSize3)
WindowWidth := CurrentWidth
Height += 5*userscale
i++
}
}
WindowHeight := DestY+Height
if !WindowWidth
WindowWidth := 20
else if (WindowWidth > A_ScreenWidth)
WindowWidth := A_ScreenWidth
if !WindowHeight
WindowHeight := 20
else if (WindowHeight > A_ScreenHeight)
WindowHeight := A_ScreenHeight
Gdip_DeleteGraphics(G)
UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayAPMTransparency)
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
Return
}
DrawResourcesOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, Background=0,Drag=0)
{	global aLocalPlayer, aHexColours, aPlayer, GameIdentifier, config_file, ResourcesOverlayX, ResourcesOverlayY, a_pBitmap, overlayResourceTransparency
, drawLocalPlayerResources
static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0
DestX := i := 0
Options := " Right cFFFFFFFF r4 s" 17*UserScale
If (Redraw = -1)
{
Try Gui, ResourcesOverlay: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier))
{
Try Gui, ResourcesOverlay: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, ResourcesOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
Gui, ResourcesOverlay: Show, NA X%ResourcesOverlayX% Y%ResourcesOverlayY% W400 H400, % aOverlayTitles["ResourcesOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
}
If (Drag AND !DragPrevious)
{	DragPrevious := 1
Gui, ResourcesOverlay: -E0x20
}
Else if (!Drag AND DragPrevious)
{	DragPrevious := 0
Gui, ResourcesOverlay: +E0x20 +LastFound
WinGetPos,ResourcesOverlayX,ResourcesOverlayY
IniWrite, %ResourcesOverlayX%, %config_file%, Overlays, ResourcesOverlayX
Iniwrite, %ResourcesOverlayY%, %config_file%, Overlays, ResourcesOverlayY
}
hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
, hdc := CreateCompatibleDC()
, obm := SelectObject(hdc, hbm)
, G := Gdip_GraphicsFromHDC(hdc)
, Gdip_SetInterpolationMode(G, 2)
For index, player in aEnemyAndLocalPlayer
{
if ((slot_number := player["Slot"]) != aLocalPlayer["Slot"] || drawLocalPlayerResources)
{
DestY := i ? i*Height : 0
If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
{
IF (PlayerIdentifier = 2)
OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
Else IF (PlayerIdentifier = 1)
OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font)
if !LongestNameSize
{
if drawLocalPlayerResources
longestName := MT_CurrentGame.LongestName
else
longestName := MT_CurrentGame.LongestEnemyName
LongestNameData :=	gdip_TextToGraphics(G, longestName, "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale	, Font)
StringSplit, LongestNameSize, LongestNameData, |
LongestNameSize := LongestNameSize3
}
DestX := LongestNameSize+10*UserScale
}
Else If (PlayerIdentifier = 3)
{	pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
DestX := Width+10*UserScale
}
Else
{
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
}
Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_TextToGraphics(G, getPlayerMinerals(slot_number), "x"(DestX+Width+5*UserScale) "y"(DestY+(Height//4)) Options  " w" 45*UserScale , Font, TextWidthHeight, TextWidthHeight)
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Gas",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, DestX + (85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_TextToGraphics(G, getPlayerGas(slot_number), "x"(DestX+(80*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options  " w" 45*UserScale, Font, TextWidthHeight,TextWidthHeight)
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Supply",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, DestX + (2*85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
TextData := Gdip_TextToGraphics(G, getPlayerSupply(slot_number)"/"getPlayerSupplyCap(slot_number), "x"(DestX+(2*83*UserScale)+Width+3*UserScale) "y"(DestY+(Height//4)) Options  " w" 70*UserScale, Font, TextWidthHeight, TextWidthHeight)
StringSplit, TextSize, TextData, |
if (WindowWidth < CurrentWidth := DestX+(2*85*UserScale)+Width+5*UserScale + TextSize3*2)
WindowWidth := CurrentWidth
Height += 5*userscale
i++
}
}
WindowHeight := DestY+Height
if !WindowWidth
WindowWidth := 20
else if (WindowWidth > A_ScreenWidth)
WindowWidth := A_ScreenWidth
if !WindowHeight
WindowHeight := 20
else if (WindowHeight > A_ScreenHeight)
WindowHeight := A_ScreenHeight
Gdip_DeleteGraphics(G)
, UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayResourceTransparency)
, SelectObject(hdc, obm)
, DeleteObject(hbm)
, DeleteDC(hdc)
Return
}
DrawArmySizeOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, Background=0,Drag=0)
{	global aLocalPlayer, aHexColours, aPlayer, GameIdentifier, config_file, ArmySizeOverlayX, ArmySizeOverlayY, a_pBitmap, overlayArmyTransparency
, drawLocalPlayerArmy
static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0
DestX := i := 0
Options := " cFFFFFFFF r4 s" 17*UserScale
If (Redraw = -1)
{
Try Gui, ArmySizeOverlay: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier))
{
Try Gui, ArmySizeOverlay: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, ArmySizeOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
Gui, ArmySizeOverlay: Show, NA X%ArmySizeOverlayX% Y%ArmySizeOverlayY% W400 H400, % aOverlayTitles["ArmySizeOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
}
If (Drag AND !DragPrevious)
{	DragPrevious := 1
Gui, ArmySizeOverlay: -E0x20
}
Else if (!Drag AND DragPrevious)
{	DragPrevious := 0
Gui, ArmySizeOverlay: +E0x20 +LastFound
WinGetPos,ArmySizeOverlayX,ArmySizeOverlayY
IniWrite, %ArmySizeOverlayX%, %config_file%, Overlays, ArmySizeOverlayX
Iniwrite, %ArmySizeOverlayY%, %config_file%, Overlays, ArmySizeOverlayY
}
hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
, hdc := CreateCompatibleDC()
, obm := SelectObject(hdc, hbm)
, G := Gdip_GraphicsFromHDC(hdc)
, Gdip_SetInterpolationMode(G, 2)
For index, player in aEnemyAndLocalPlayer
{
if ((slot_number := player["Slot"]) != aLocalPlayer["Slot"] || drawLocalPlayerArmy)
{
DestY := i ? i*Height : 0
If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
{
IF (PlayerIdentifier = 2)
OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
Else IF (PlayerIdentifier = 1)
OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font)
if !LongestNameSize
{
if (DrawArmySizeOverlay = -1)
longestName := MT_CurrentGame.LongestName
else
longestName := MT_CurrentGame.LongestEnemyName
LongestNameData :=	gdip_TextToGraphics(G, longestName, "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale	, Font)
StringSplit, LongestNameSize, LongestNameData, |
LongestNameSize := LongestNameSize3
}
DestX := LongestNameSize+10*UserScale
}
Else If (PlayerIdentifier = 3)
{
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
DestX := Width+10*UserScale
}
Else
{
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Mineral",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
}
Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_TextToGraphics(G, ArmyMinerals := getPlayerArmySizeMinerals(slot_number), "x"(DestX+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Gas",Background]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, DestX + (85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_TextToGraphics(G, getPlayerArmySizeGas(slot_number), "x"(DestX+(85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"Army"]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, DestX + (2*85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
TextData := Gdip_TextToGraphics(G, round(getPlayerArmySupply(slot_number)) "/" getPlayerSupply(slot_number), "x"(DestX+(2*85*UserScale)+Width+3*UserScale) "y"(DestY+(Height//4)) Options, Font)
StringSplit, TextSize, TextData, |
if (WindowWidth < CurrentWidth := DestX+(2*85*UserScale)+Width+5*UserScale + TextSize3)
WindowWidth := CurrentWidth
i++
}
}
WindowHeight := DestY+Height
if !WindowWidth
WindowWidth := 20
else if (WindowWidth > A_ScreenWidth)
WindowWidth := A_ScreenWidth
if !WindowHeight
WindowHeight := 20
else if (WindowHeight > A_ScreenHeight)
WindowHeight := A_ScreenHeight
Gdip_DeleteGraphics(G)
, UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayArmyTransparency)
, SelectObject(hdc, obm)
, DeleteObject(hbm)
, DeleteDC(hdc)
Return
}
DrawWorkerOverlay(ByRef Redraw, UserScale=1,Drag=0)
{	global aLocalPlayer, GameIdentifier, config_file, WorkerOverlayX, WorkerOverlayY, a_pBitmap, overlayHarvesterTransparency
static Font := "Arial", overlayCreated, hwnd1, DragPrevious := False
Options := " cFFFFFFFF r4 s" 18*UserScale
DestX := DestY := 0
If (Redraw = -1)
{
Try Gui, WorkerOverlay: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier))
{
Try Gui, WorkerOverlay: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, WorkerOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
Gui, WorkerOverlay: Show, NA X%WorkerOverlayX% Y%WorkerOverlayY% W400 H400, % aOverlayTitles["WorkerOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
}
If (Drag AND !DragPrevious)
{
DragPrevious := True
Gui, WorkerOverlay: -E0x20
}
Else if (!Drag AND DragPrevious)
{
DragPrevious := False
Gui, WorkerOverlay: +E0x20 +LastFound
WinGetPos,WorkerOverlayX,WorkerOverlayY
IniWrite, %WorkerOverlayX%, %config_file%, Overlays, WorkerOverlayX
Iniwrite, %WorkerOverlayY%, %config_file%, Overlays, WorkerOverlayY
}
hbm := CreateDIBSection(400, 400)
, hdc := CreateCompatibleDC()
, obm := SelectObject(hdc, hbm)
, G := Gdip_GraphicsFromHDC(hdc)
, Gdip_SetInterpolationMode(G, 2)
pBitmap := a_pBitmap[aLocalPlayer["Race"],"Worker"]
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_TextToGraphics(G, getPlayerWorkerCount(aLocalPlayer["Slot"]), "x"(DestX+Width+2*UserScale) "y"(DestY+(Height//4)) Options, Font, TextWidthHeight, TextWidthHeight)
Gdip_DeleteGraphics(G)
UpdateLayeredWindow(hwnd1, hdc,,,,, overlayHarvesterTransparency)
, SelectObject(hdc, obm)
, DeleteObject(hbm)
, DeleteDC(hdc)
Return
}
DrawLocalPlayerColour(ByRef Redraw, UserScale=1,Drag=0)
{	global aLocalPlayer, GameIdentifier, config_file, LocalPlayerColourOverlayX, LocalPlayerColourOverlayY, a_pBitmap, aHexColours, overlayLocalColourTransparency
static overlayCreated, hwnd1, DragPrevious := 0,  PreviousPlayerColours := 0
playerColours := arePlayerColoursEnabled()
if (!playerColours && PreviousPlayerColours)
{
Redraw := 1
PreviousPlayerColours := 0
}
else if (playerColours && !PreviousPlayerColours)
{
Try Gui, LocalPlayerColourOverlay: Destroy
overlayCreated := False
PreviousPlayerColours := 1
return
}
else if playerColours
return
If (Redraw = -1)
{
Try Gui, LocalPlayerColourOverlay: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier))
{
Try Gui, LocalPlayerColourOverlay: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, LocalPlayerColourOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
Gui, LocalPlayerColourOverlay: Show, NA X%LocalPlayerColourOverlayX% Y%LocalPlayerColourOverlayY% W200 H200, % aOverlayTitles["LocalPlayerColourOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
}
If (Drag AND !DragPrevious)
{	DragPrevious := 1
Gui, LocalPlayerColourOverlay: -E0x20
}
Else if (!Drag AND DragPrevious)
{	DragPrevious := 0
Gui, LocalPlayerColourOverlay: +E0x20 +LastFound
WinGetPos,LocalPlayerColourOverlayX,LocalPlayerColourOverlayY
IniWrite, %LocalPlayerColourOverlayX%, %config_file%, Overlays, LocalPlayerColourOverlayX
Iniwrite, %LocalPlayerColourOverlayY%, %config_file%, Overlays, LocalPlayerColourOverlayY
}
hbm := CreateDIBSection(200, 200)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
Gdip_SetSmoothingMode(G, 4)
colour := aLocalPlayer["Colour"]
Radius := 12 * UserScale
Gdip_FillEllipse(G, a_pBrushes[colour], 0, 0, Radius, Radius)
Gdip_DeleteGraphics(G)
UpdateLayeredWindow(hwnd1, hdc,,,,, overlayLocalColourTransparency)
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
Return
}
getEnemyUnitCount(byref aEnemyUnits, byref aEnemyUnitConstruction, byref aEnemyCurrentUpgrades)
{
GLOBAL DeadFilterFlag, aPlayer, aLocalPlayer, aUnitTargetFilter, aUnitInfo, aMiscUnitPanelInfo
aEnemyUnits := [], aEnemyUnitConstruction := [], aEnemyCurrentUpgrades := [], aMiscUnitPanelInfo := []
static aUnitMorphingNames := {"Egg": True, "BanelingCocoon": True, "BroodLordCocoon": True, "OverlordCocoon": True, "MothershipCore": True, "Mothership": True }
loop, % Unitcount := DumpUnitMemory(MemDump)
{
TargetFilter := numgetUnitTargetFilter(MemDump, unit := A_Index - 1)
if (TargetFilter & DeadFilterFlag || TargetFilter & aUnitTargetFilter.Hallucination)
Continue
owner := numgetUnitOwner(MemDump, Unit)
if  (aPlayer[Owner, "Team"] <> aLocalPlayer["Team"] && Owner)
{
pUnitModel := numgetUnitModelPointer(MemDump, Unit)
Type := numgetUnitModelType(pUnitModel)
if  (Type < aUnitID["Colossus"])
continue
if (!Priority := aUnitInfo[Type, "Priority"])
aUnitInfo[Type, "Priority"] := Priority := numgetUnitModelPriority(pUnitModel)
if (aUnitInfo[Type, "isStructure"] = "")
aUnitInfo[Type, "isStructure"] := TargetFilter & aUnitTargetFilter.Structure
if (TargetFilter & aUnitTargetFilter.UnderConstruction)
{
pAbilities := numgetUnitAbilityPointer(MemDump, unit)
if (Type = aUnitID.Archon )
progress := getArchonMorphTime(pAbilities)
else
progress := getBuildProgress(pAbilities, Type)
aEnemyUnitConstruction[Owner, Priority, Type] := {"progress": progress > aEnemyUnitConstruction[Owner, Priority, Type].Progress
? progress
: aEnemyUnitConstruction[Owner, Priority, Type].Progress
, "count": round(aEnemyUnitConstruction[Owner, Priority, Type].Count) + 1}
aEnemyUnitConstruction[Owner, "TotalCount"] := round(aEnemyUnitConstruction[Owner, "TotalCount"]) + 1
}
Else
{
if (TargetFilter & aUnitTargetFilter.Structure)
{
chronoed := False
if (aPlayer[owner, "Race"] = "Protoss")
{
if numgetIsUnitChronoed(MemDump, unit)
{
chronoed := True
aMiscUnitPanelInfo["chrono", owner, Type] := round(aMiscUnitPanelInfo["chrono", owner, Type]) + 1
}
if (type = aUnitID["Nexus"])
{
if (chronoBoosts := floor(numgetUnitEnergy(MemDump, unit)/25))
aMiscUnitPanelInfo["chronoBoosts", owner] := round(aMiscUnitPanelInfo["chronoBoosts", owner]) + chronoBoosts
if isPhotonOverChargeActive(unit) && progress := getUnitBuff(unit, "MothershipCoreApplyPurifyAB")
{
aEnemyUnitConstruction[Owner, 50, "MothershipCoreApplyPurifyAB"] := {"progress": progress > aEnemyUnitConstruction[Owner, 50, "MothershipCoreApplyPurifyAB"].Progress
? progress
: aEnemyUnitConstruction[Owner, 50, "MothershipCoreApplyPurifyAB"].Progress
, "count": round(aEnemyUnitConstruction[Owner, 50, "MothershipCoreApplyPurifyAB"].Count) + 1}
, aUnitInfo["MothershipCoreApplyPurifyAB", "isStructure"]  := True
, aUnitInfo["MothershipCoreApplyPurifyAB", "Priority"]  := 50
}
}
}
else if (aPlayer[owner, "Race"] = "Terran") && (Type = aUnitID["OrbitalCommand"] || Type = aUnitID["OrbitalCommandFlying"])
{
if (scanCount := floor(numgetUnitEnergy(MemDump, unit)/50))
aMiscUnitPanelInfo["Scans", owner] := round(aMiscUnitPanelInfo["Scans", owner]) + scanCount
}
if (queueSize := getStructureProductionInfo(unit, type, aQueueInfo))
{
for i, aProduction in aQueueInfo
{
if (QueuedType := aUnitID[aProduction.Item])
{
QueuedPriority := aUnitInfo[QueuedType, "Priority"]
aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType] := {"progress": (aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType].progress > aProduction.progress ? aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType].progress : aProduction.progress)
, "count": round(aEnemyUnitConstruction[Owner, QueuedPriority, QueuedType].count) + 1 }
}
else if a_pBitmap.haskey(aProduction.Item)
{
aEnemyCurrentUpgrades[Owner, aProduction.Item] := {"progress": (aEnemyCurrentUpgrades[Owner, aProduction.Item].progress > aProduction.progress ? aEnemyCurrentUpgrades[Owner, aProduction.Item].progress : aProduction.progress)
, "count": round(aEnemyCurrentUpgrades[Owner, aProduction.Item].count) + 1 }
if chronoed
aMiscUnitPanelInfo[owner, "ChronoUpgrade", aProduction.Item] := True
}
}
}
if (Type = aUnitID["CommandCenter"] && MorphingType := isCommandCenterMorphing(unit))
{
if !Priority := aUnitInfo[MorphingType, "Priority"]
{
if (MorphingType = aUnitID.OrbitalCommand)
Priority := aUnitInfo[Type, "Priority"] + 1
else Priority := aUnitInfo[Type, "Priority"]
aUnitInfo[MorphingType, "isStructure"] := True
}
progress := getUnitMorphTime(unit, type)
aEnemyUnitConstruction[Owner, Priority, MorphingType] := {"progress": (aEnemyUnitConstruction[Owner, Priority, MorphingType].progress > aProduction.progress ? aEnemyUnitConstruction[Owner, Priority, MorphingType].progress : progress)
, "count": round(aEnemyUnitConstruction[Owner, Priority, MorphingType].count) + 1 }
}
else if (Type = aUnitID["Hatchery"] || Type = aUnitID["Lair"] || Type = aUnitID["Spire"]) && MorphingType := isHatchLairOrSpireMorphing(unit, Type)
{
aUnitInfo[MorphingType, "isStructure"] := True
progress := getUnitMorphTime(unit, type)
aEnemyUnitConstruction[Owner, Priority, MorphingType] := {"progress": (aEnemyUnitConstruction[Owner, Priority, MorphingType].progress > progress ? aEnemyUnitConstruction[Owner, Priority, MorphingType].progress : progress)
, "count": round(aEnemyUnitConstruction[Owner, Priority, MorphingType].count) + 1 }
aEnemyUnits[Owner, Priority, Type] := round(aEnemyUnits[Owner, Priority, Type]) + 1
}
else
aEnemyUnits[Owner, Priority, Type] := round(aEnemyUnits[Owner, Priority, Type]) + 1
}
else
{
if aUnitMorphingNames.HasKey(aUnitName[type])
{
if (Type = aUnitId.Egg)
{
aProduction := getZergProductionFromEgg(unit)
QueuedPriority := aUnitInfo[aProduction.Type, "Priority"], progress :=  aProduction.progress, type := aProduction.Type
count := aProduction.Count
}
else if (Type = aUnitID.BanelingCocoon)
{
progress := getBanelingMorphTime(numgetUnitAbilityPointer(MemDump, unit))
QueuedPriority := aUnitInfo[aUnitID.Baneling, "Priority"], Count := 1
}
else if (Type = aUnitID.BroodLordCocoon)
{
progress := getUnitMorphTime(unit, Type)
QueuedPriority := aUnitInfo[Type := aUnitID.BroodLord, "Priority"], Count := 1
}
else if (Type = aUnitID.OverlordCocoon)
{
progress := getUnitMorphTime(unit, Type)
QueuedPriority := aUnitInfo[Type := aUnitID.Overseer, "Priority"], Count := 1
}
else if (Type = aUnitId.MothershipCore || Type = aUnitId.Mothership)
{
if isMotherShipCoreMorphing(unit)
{
progress := getUnitMorphTime(unit, Type)
QueuedPriority := aUnitInfo[Type, "Priority"], Count := 1, Type := aUnitID.Mothership
}
else
{
aMiscUnitPanelInfo["MotherShipEnergy", owner] := getUnitEnergy(unit)
aEnemyUnits[Owner, Priority, Type] := round(aEnemyUnits[Owner, Priority, Type]) + 1
continue
}
}
aEnemyUnitConstruction[Owner, QueuedPriority, Type] := {"progress": (aEnemyUnitConstruction[Owner, QueuedPriority, Type].progress > progress ? aEnemyUnitConstruction[Owner, QueuedPriority, Type].progress : progress)
, "count": round(aEnemyUnitConstruction[Owner, QueuedPriority, Type].count) + Count}
}
else
aEnemyUnits[Owner, Priority, Type] := round(aEnemyUnits[Owner, Priority, Type]) + 1
}
}
}
}
Return
}
FilterUnits(byref aEnemyUnits, byref aEnemyUnitConstruction, byref aUnitPanelUnits)
{	global aUnitInfo
STATIC aRemovedUnits := {"Terran": ["TechLab","BarracksTechLab","BarracksReactor","FactoryTechLab","Reactor","FactoryReactor","StarportTechLab","StarportReactor"]
, "Protoss": ["Interceptor"]
, "Zerg": ["CreepTumorBurrowed","Broodling","Locust"]}
STATIC aAddUnits 	:=	{"Terran": {SupplyDepotLowered: "SupplyDepot", WidowMineBurrowed: "WidowMine", CommandCenterFlying: "CommandCenter", OrbitalCommandFlying: "OrbitalCommand"
, BarracksFlying: "Barracks", FactoryFlying: "Factory", StarportFlying: "Starport", SiegeTankSieged: "SiegeTank",  ThorHighImpactPayload: "Thor", VikingAssault: "VikingFighter"}
, "Zerg": {DroneBurrowed: "Drone", ZerglingBurrowed: "Zergling", HydraliskBurrowed: "Hydralisk", UltraliskBurrowed: "Ultralisk", RoachBurrowed: "Roach"
, InfestorBurrowed: "Infestor", BanelingBurrowed: "Baneling", QueenBurrowed: "Queen", SporeCrawlerUprooted: "SporeCrawler", SpineCrawlerUprooted: "SpineCrawler"}}
STATIC aAddConstruction := {"Terran": {BarracksTechLab: "TechLab", BarracksReactor: "Reactor", FactoryTechLab: "TechLab", FactoryReactor: "Reactor", StarportTechLab: "TechLab", StarportReactor: "Reactor"}}
STATIC aUnitOrder := 	{"Terran": ["SCV", "OrbitalCommand", "PlanetaryFortress", "CommandCenter"]
, "Protoss": ["Probe", "Nexus"]
, "Zerg": ["Drone","Hive","Lair", "Hatchery"]}
STATIC aAddMorphing := {"Zerg": {BanelingCocoon: "Baneling"}}
for owner, priorityObject in aEnemyUnits
{
race := aPlayer[owner, "Race"]
if (race = "Zerg" && priorityObject[aUnitInfo[aUnitID["Drone"], "Priority"], aUnitID["Drone"]] && aEnemyUnitConstruction[Owner, "TotalCount"])
{
priorityObject[aUnitInfo[aUnitID["Drone"], "Priority"], aUnitID["Drone"]] -= aEnemyUnitConstruction[Owner, "TotalCount"]
- round(aEnemyUnitConstruction[owner, aUnitInfo[aUnitID["NydusCanal"], "Priority"], aUnitID["NydusCanal"], "Count"])
- round(aEnemyUnitConstruction[owner, aUnitInfo[aUnitID["CreepTumorQueen"], "Priority"], aUnitID["CreepTumorQueen"], "Count"])
- round(aEnemyUnitConstruction[owner, aUnitInfo[aUnitID["CreepTumor"], "Priority"], aUnitID["CreepTumor"], "Count"])
if (priorityObject[aUnitInfo[aUnitID["Drone"], "Priority"], aUnitID["Drone"]] <= 0)
priorityObject[aUnitInfo[aUnitID["Drone"], "Priority"]].remove(aUnitID["Drone"], "")
}
for index, removeUnit in aRemovedUnits[race]
{
removeUnit := aUnitID[removeUnit]
priority := aUnitInfo[removeUnit, "Priority"]
priorityObject[priority].remove(removeUnit, "")
}
for subUnit, mainUnit in aAddUnits[Race]
{
subunit := aUnitID[subUnit]
subPriority := aUnitInfo[subunit, "Priority"]
if (total := priorityObject[subPriority, subunit])
{
mainUnit := aUnitID[mainUnit]
if !priority := aUnitInfo[mainUnit, "Priority"]
priority := subPriority
if (aUnitInfo[mainUnit, "isStructure"] = "")
aUnitInfo[mainUnit, "isStructure"] := aUnitInfo[subUnit, "isStructure"]
priorityObject[priority, mainUnit] := round(priorityObject[priority, mainUnit]) + total
priorityObject[subPriority].remove(subunit, "")
}
}
for subUnit, mainUnit in aAddMorphing[Race]
{
subunit := aUnitID[subUnit]
subPriority := aUnitInfo[subunit, "Priority"]
if (total := priorityObject[subPriority, subunit])
{
mainUnit := aUnitID[mainUnit]
if !priority := aUnitInfo[mainUnit, "Priority"]
priority := 16
aEnemyUnitConstruction[owner, Priority, mainUnit] := round(aEnemyUnitConstruction[owner, Priority, mainUnit]) + total
priorityObject[subPriority].remove(subunit, "")
}
}
for index, removeUnit in aUnitPanelUnits[race, "FilteredCompleted"]
{
removeUnit := aUnitID[removeUnit]
if ("" != priority := aUnitInfo[removeUnit, "Priority"])
priorityObject[priority].remove(removeUnit, "")
}
for index, unit in aUnitOrder[race]
{
if (count := priorityObject[aUnitInfo[aUnitID[unit], "Priority"], aUnitID[unit]])
{
index := 0 - aUnitOrder[race].maxindex() + A_index
priorityObject[index, aUnitID[unit]] := count
priority := aUnitInfo[aUnitID[unit], "Priority"]
priorityObject[priority].remove(aUnitID[unit], "")
}
}
}
for owner, priorityObject in aEnemyUnitConstruction
{
race := aPlayer[owner, "Race"]
for subUnit, mainUnit in aAddConstruction[Race]
{
subunit := aUnitID[subUnit]
subPriority := aUnitInfo[subunit, "Priority"]
if (total := priorityObject[subPriority, subunit, "Count"])
{
subProgress := priorityObject[subPriority, subunit, "progress"]
mainUnit := aUnitID[mainUnit]
if !priority := aUnitInfo[mainUnit, "Priority"]
priority := subPriority
if (aUnitInfo[mainUnit, "isStructure"] = "")
aUnitInfo[mainUnit, "isStructure"] := aUnitInfo[subUnit, "isStructure"]
if priorityObject[priority, mainUnit, "Count"]
{
priorityObject[priority, mainUnit, "Count"] += total
if (priorityObject[priority, mainUnit, "progress"] < subProgress)
priorityObject[priority, mainUnit, "progress"] := subProgress
}
else
{
priorityObject[priority, mainUnit, "Count"] := total
priorityObject[priority, mainUnit, "progress"] := subProgress
}
priorityObject[subPriority].remove(subunit, "")
aEnemyUnitConstruction[Owner, "TotalCount"] -= total
}
}
for index, removeUnit in aUnitPanelUnits[race, "FilteredUnderConstruction"]
{
removeUnit := aUnitID[removeUnit]
priority := aUnitInfo[removeUnit, "Priority"]
if removeUnit is not integer
priorityObject[priority].remove(removeUnit)
else priorityObject[priority].remove(removeUnit, "")
}
for index, unit in aUnitOrder[race]
if (count := priorityObject[aUnitInfo[aUnitID[unit], "Priority"], aUnitID[unit]].count)
{
index := 0 - aUnitOrder[race].maxindex() + A_index
priorityObject[index, aUnitID[unit]] :=  priorityObject[aUnitInfo[aUnitID[unit], "Priority"], aUnitID[unit]]
priority := aUnitInfo[aUnitID[unit], "Priority"]
priorityObject[priority].remove(aUnitID[unit], "")
}
}
return
}
DrawUnitOverlay(ByRef Redraw, UserScale = 1, PlayerIdentifier = 0, Drag = 0)
{
GLOBAL aEnemyUnits, aEnemyUnitConstruction, a_pBitmap, aPlayer, aLocalPlayer, aHexColours, GameIdentifier, config_file, UnitOverlayX, UnitOverlayY
, aUnitInfo, SplitUnitPanel, aEnemyCurrentUpgrades, DrawUnitOverlay, DrawUnitUpgrades, aMiscUnitPanelInfo, aUnitID, overlayMatchTransparency
, unitPanelDrawStructureProgress, unitPanelDrawUnitProgress, unitPanelDrawUpgradeProgress, unitPanelAlignNewUnits
static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0
If (Redraw = -1)
{
Try Gui, UnitOverlay: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier))
{
Try Gui, UnitOverlay: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, UnitOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
Gui, UnitOverlay: Show, NA X%UnitOverlayX% Y%UnitOverlayY% W400 H400, % aOverlayTitles["UnitOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
}
If (Drag AND !DragPrevious)
{	DragPrevious := 1
Gui, UnitOverlay: -E0x20
}
Else if (!Drag AND DragPrevious)
{	DragPrevious := 0
Gui, UnitOverlay: +E0x20 +LastFound
WinGetPos,UnitOverlayX,UnitOverlayY
IniWrite, %UnitOverlayX%, %config_file%, Overlays, UnitOverlayX
Iniwrite, %UnitOverlayY%, %config_file%, Overlays, UnitOverlayY
}
hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
, hdc := CreateCompatibleDC()
, obm := SelectObject(hdc, hbm)
, G := Gdip_GraphicsFromHDC(hdc)
, Gdip_SetSmoothingMode(G, 4)
, Gdip_SetInterpolationMode(G, 2)
Height := DestY := 0
, rowMultiplier := (DrawUnitOverlay ? (SplitUnitPanel ? 2 : 1) : 0) + (DrawUnitUpgrades ? 1 : 0)
for slot_number, priorityObject in aEnemyUnits
{
Height += 7*userscale
, DestY := (rowMultiplier * Height + ((unitPanelDrawUnitProgress || unitPanelDrawStructureProgress ) ? 8 * UserScale : 0)) * (A_Index - 1)
, destUnitSplitY :=  DestY + ((unitPanelDrawUnitProgress || unitPanelDrawStructureProgress ) ? 5 * UserScale : 0)
If (PlayerIdentifier = 1 || PlayerIdentifier = 2 )
{
IF (PlayerIdentifier = 2)
OptionsName := " Bold cFF" aHexColours[aPlayer[slot_number, "Colour"]] " r4 s" 17*UserScale
Else
OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale
gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY +12*UserScale)  OptionsName, Font)
if !LongestNameSize
{
LongestNameData :=	gdip_TextToGraphics(G, MT_CurrentGame.LongestEnemyName
, "x0" "y"(DestY)  " Bold c00FFFFFF r4 s" 17*UserScale, Font)
StringSplit, LongestNameSize, LongestNameData, |
LongestNameSize := LongestNameSize3
}
DestX := LongestNameSize+5*UserScale
}
Else If (PlayerIdentifier = 3)
{
pBitmap := a_pBitmap[aPlayer[slot_number, "Race"],"RaceFlatColour", aPlayer[slot_number, "Colour"]]
, SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
, Width *= UserScale *.5, Height *= UserScale *.5
, Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY + Height/5, Width, Height, 0, 0, SourceWidth, SourceHeight)
, DestX := Width+15*UserScale
}
else DestX := 0
firstColumnX  := maxStructureDestX := maxUnitDestX := DestX
structureY := DestY
if DrawUnitOverlay
{
for priority, object in priorityObject
{
for unit, unitCount in object
{
if !(pBitmap := a_pBitmap[unit])
continue
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
, Width *= UserScale *.5, Height *= UserScale *.5
if SplitUnitPanel
{
if aUnitInfo[unit, "isStructure"]
DestX := maxStructureDestX, DestY := structureY
else
DestX := maxUnitDestX, DestY := destUnitSplitY + Height * 1.1
}
Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
if (unit = aUnitID.MothershipCore || unit = aUnitID.Mothership)
{
energy := aMiscUnitPanelInfo["MotherShipEnergy", slot_number]
if (energy < 100)
{
Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .6*Width, DestY + .6*Height, Width/2.5, Height/2.5, 5)
if (energy < 10)
gdip_TextToGraphics(G, energy, "x"(DestX + .5*Width + .4*Width/2) "y"(DestY + .5*Height + .3*Height/2)  " Bold Italic cFFCD00FF r4 s" 11*UserScale, Font)
else
gdip_TextToGraphics(G, energy, "x"(DestX + .5*Width + .18*Width/2) "y"(DestY + .5*Height + .3*Height/2) " Bold Italic cFFCD00FF r4 s" 11*UserScale, Font)
}
else
{
Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .5*Width, DestY + .6*Height, (Width/2.5) +  .1*Width, Height/2.5, 5)
, gdip_TextToGraphics(G, energy, "x"(DestX + .45*Width) "y"(DestY + .5*Height + .3*Height/2)  " Bold Italic cFFCD00FF r4 s" 11*UserScale, Font)
}
}
else
{
Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .6*Width, DestY + .6*Height, Width/2.5, Height/2.5, 5)
if (unitCount >= 10)
gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .18*Width/2) "y"(DestY + .5*Height + .3*Height/2)  " Bold cFFFFFFFF r4 s" 11*UserScale, Font)
Else
gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .35*Width/2) "y"(DestY + .5*Height + .3*Height/2)  " Bold cFFFFFFFF r4 s" 11*UserScale, Font)
}
if ((chronos := aMiscUnitPanelInfo["chrono", slot_number, unit]))
{
if (chronos = 1)
Gdip_FillEllipse(G, a_pBrushes["ScanChrono"], DestX + .2*Width/2, DestY + .15*Height/2, 5*UserScale, 5*UserScale)
Else
{
Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX, DestY, Width/2.5, Height/2.5, 5)
if (chronoCount >= 10)
gdip_TextToGraphics(G, chronos, "x"(DestX + .1*Width/2) "y"(DestY + .10*Height/2)  " Bold Italic cFFFF00B3 r4 s" 11*UserScale, Font)
else
gdip_TextToGraphics(G, chronos, "x"(DestX + .2*Width/2) "y"(DestY + .10*Height/2) " Bold Italic cFFFF00B3 r4 s" 11*UserScale, Font)
}
}
if 	( (unit = aUnitID.OrbitalCommand  && (chronoScanCount := aMiscUnitPanelInfo["Scans", slot_number]))
|| (unit = aUnitID.Nexus && (chronoScanCount := aMiscUnitPanelInfo["chronoBoosts", slot_number])))
{
Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX, DestY + .6*Height, Width/2.5, Height/2.5, 5)
if (chronoScanCount >= 10)
gdip_TextToGraphics(G, chronoScanCount, "x"(DestX + .1*Width/2) "y"(DestY + .5*Height + .3*Height/2)  " Bold Italic cFF00FFFF r4 s" 11*UserScale, Font)
else
gdip_TextToGraphics(G, chronoScanCount, "x"(DestX + .2*Width/2) "y"(DestY + .5*Height + .3*Height/2) " Bold Italic cFF00FFFF r4 s" 11*UserScale, Font)
}
if (unitCount := aEnemyUnitConstruction[slot_number, priority, unit].count)
{
progress := aEnemyUnitConstruction[slot_number, priority, unit].progress
, Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .6*Width, DestY, Width/2.5, Height/2.5, 5)
if (unitCount >= 10)
gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .16*Width/2) "y"(DestY + .10*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
Else
gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .3*Width/2) "y"(DestY + .10*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
if (unitPanelDrawStructureProgress && aUnitInfo[unit, "isStructure"]) || (unitPanelDrawUnitProgress && !aUnitInfo[unit, "isStructure"])
{
Gdip_SetSmoothingMode(G, 0)
, Gdip_FillRectangle(G, a_pBrushes.TransparentBlack, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width - 10 * UserScale *.5, Height/16)
, Gdip_FillRectangle(G, a_pBrushes.Green, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width*progress - progress * 10 * UserScale *.5, Height/16)
, Gdip_SetSmoothingMode(G, 4)
}
aEnemyUnitConstruction[slot_number, priority].remove(unit, "")
}
if SplitUnitPanel
{
if aUnitInfo[unit, "isStructure"]
maxStructureDestX += (Width+5*UserScale)
else
maxUnitDestX += (Width+5*UserScale)
}
else DestX += (Width+5*UserScale)
}
}
DestX += (Width+5*UserScale)
maxStructureDestX += (Width+5*UserScale)
maxUnitDestX += (Width+5*UserScale)
if unitPanelAlignNewUnits
{
if (maxStructureDestX < maxUnitDestX)
maxStructureDestX := maxUnitDestX
else maxUnitDestX := maxStructureDestX
}
for ConstructionPriority, priorityConstructionObject in aEnemyUnitConstruction[slot_number]
{
for unit, item in priorityConstructionObject
{
if (unit != "TotalCount" && pBitmap := a_pBitmap[unit])
{
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
, Width *= UserScale *.5, Height *= UserScale *.5
if SplitUnitPanel
{
if aUnitInfo[unit, "isStructure"]
DestX := maxStructureDestX, DestY := structureY
else
DestX := maxUnitDestX, DestY := destUnitSplitY + Height * 1.1
}
Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .6*Width, DestY, Width/2.5, Height/2.5, 5)
if (item.count >= 10)
gdip_TextToGraphics(G, item.count, "x"(DestX + .5*Width + .16*Width/2) "y"(DestY + .10*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
Else
gdip_TextToGraphics(G, item.count, "x"(DestX + .5*Width + .3*Width/2) " y"(DestY + .10*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
if (unitPanelDrawStructureProgress && aUnitInfo[unit, "isStructure"]) || (unitPanelDrawUnitProgress && !aUnitInfo[unit, "isStructure"])
{
Gdip_SetSmoothingMode(G, 0)
, Gdip_FillRectangle(G, a_pBrushes.TransparentBlack, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width - 10 * UserScale *.5, Height/16)
, Gdip_FillRectangle(G, a_pBrushes.Green, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width*item.progress - item.progress * 10 * UserScale *.5, Height/16)
, Gdip_SetSmoothingMode(G, 4)
}
if SplitUnitPanel
{
if aUnitInfo[unit, "isStructure"]
maxStructureDestX += (Width+5*UserScale)
else
maxUnitDestX += (Width+5*UserScale)
}
else DestX += (Width+5*UserScale)
}
}
}
if SplitUnitPanel
{
if (maxStructureDestX > WindowWidth)
WindowWidth := maxStructureDestX
else if (maxUnitDestX > WindowWidth)
WindowWidth := maxUnitDestX
}
else if (DestX > WindowWidth)
WindowWidth := DestX
}
if DrawUnitUpgrades
{
offset := (SplitUnitPanel ? 2 : 1) * ((unitPanelDrawUnitProgress || unitPanelDrawStructureProgress) ? 5 : 0) * userscale
, destUpgradesY := structureY  + Height * 1.1 * (rowMultiplier - 1) + offset
, UpgradeX := firstColumnX
for itemName, item in aEnemyCurrentUpgrades[slot_number]
{
if (pBitmap := a_pBitmap[itemName])
{
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
, Width *= UserScale *.5, Height *= UserScale *.5
, Gdip_DrawImage(G, pBitmap, UpgradeX, destUpgradesY, Width, Height, 0, 0, SourceWidth, SourceHeight)
if (item.count > 1)
{
Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, UpgradeX + .6*Width, destUpgradesY, Width/2.5, Height/2.5, 5)
, gdip_TextToGraphics(G, item.count, "x"(UpgradeX + .5*Width + .4*Width/2) "y"(destUpgradesY + .15*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
}
if unitPanelDrawUpgradeProgress
{
Gdip_SetSmoothingMode(G, 0)
, Gdip_FillRectangle(G, a_pBrushes.TransparentBlack, UpgradeX + 5 * UserScale *.5, floor(destUpgradesY+Height), Width - 10 * UserScale *.5, Height/16)
, Gdip_FillRectangle(G, a_pBrushes.Green, UpgradeX + 5 * UserScale *.5, floor(destUpgradesY+Height), Width*item.progress - item.progress * 10 * UserScale *.5, Height/16)
, Gdip_SetSmoothingMode(G, 4)
}
if aMiscUnitPanelInfo[slot_number, "ChronoUpgrade", itemName]
Gdip_FillEllipse(G, a_pBrushes["ScanChrono"], UpgradeX + .2*Width/2, destUpgradesY + .2*Height/2, ceil(5*UserScale), ceil(5*UserScale))
UpgradeX += (Width+5*UserScale)
}
}
if (UpgradeX > WindowWidth)
WindowWidth := UpgradeX
}
}
WindowHeight := DestY + 4*Height
, WindowWidth += width *3
if !WindowWidth
WindowWidth := DestX ? DestX : 20
else if (WindowWidth > A_ScreenWidth)
WindowWidth := A_ScreenWidth
if !WindowHeight
WindowHeight := 20
else if (WindowHeight > A_ScreenHeight)
WindowHeight := A_ScreenHeight
Gdip_DeleteGraphics(G)
, UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayMatchTransparency)
, SelectObject(hdc, obm)
, DeleteObject(hbm)
, DeleteDC(hdc)
Return
}
DrawMacroTownHallOverlay(ByRef Redraw, UserScale=1, Drag=0)
{
global overlayMacroTownHallTransparency, MacroTownHallOverlayX, MacroTownHallOverlayY
static Font := "Arial", overlayCreated, hwnd1, DragPrevious := False, aTownHalls := []
If (Redraw = -1)
{
Try Gui, MacroTownHall: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier))
{
Try Gui, MacroTownHall: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, MacroTownHall: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound +ToolWindow +AlwaysOnTop
Gui, MacroTownHall: Show, NA X%MacroTownHallOverlayX% Y%MacroTownHallOverlayY% W400 H400, % aOverlayTitles["MacroTownHallOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
aTownHalls := {	aUnitID.OrbitalCommand: True
, 	aUnitID.Nexus: True
, 	aUnitID.Hatchery : True, aUnitID.Lair : True, aUnitID.Hive : True}
}
If (Drag AND !DragPrevious)
{
DragPrevious := True
Gui, MacroTownHall: -E0x20
}
Else if (!Drag AND DragPrevious)
{
DragPrevious := False
Gui, MacroTownHall: +E0x20 +LastFound
WinGetPos, MacroTownHallOverlayX, MacroTownHallOverlayY
IniWrite, %MacroTownHallOverlayX%, %config_file%, Overlays, MacroTownHallOverlayX
Iniwrite, %MacroTownHallOverlayY%, %config_file%, Overlays, MacroTownHallOverlayY
}
if (aLocalPlayer.Race = "Terran")
pBitmap := a_pBitmap[aUnitID.OrbitalCommand], energyRequired := 50, textColour := " cFFCD00FF "
else if (aLocalPlayer.Race = "Protoss")
pBitmap := a_pBitmap[aUnitID.Nexus], energyRequired := 25, textColour := " cFFCD00FF "
else pBitmap := a_pBitmap[aUnitID.Larva], textColour := " cFFFFFFFF "
macroCount := 0, aCheckedUnits := []
loop 10
{
loop, % numgetControlGroupMemory(MemDump, A_Index - 1)
{
if !aCheckedUnits.HasKey((unit := NumGet(MemDump, (A_Index - 1) * 4, "UInt") >> 18))
&& aTownHalls.HasKey(getUnitType(unit))
&& isUnitLocallyOwned(unit) && !(getUnitTargetFilter(unit) & (aUnitTargetFilter.Dead | aUnitTargetFilter.UnderConstruction))
macroCount += aLocalPlayer.Race = "Terran" || aLocalPlayer.Race = "Protoss" ? Floor(getUnitEnergy(unit)/energyRequired) : getTownHallLarvaCount(unit)
aCheckedUnits[unit] := True
}
}
hbm := CreateDIBSection(400, 400)
, hdc := CreateCompatibleDC()
, obm := SelectObject(hdc, hbm)
, G := Gdip_GraphicsFromHDC(hdc)
, Gdip_SetInterpolationMode(G, 2)
, SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
, Width *= UserScale *.4, Height *= UserScale *.4
, stringData := Gdip_TextToGraphics(G, macroCount, "x"(Width+2*UserScale) "y" (Height)  textColour "r4 s" 18*UserScale, Font)
StringSplit, stringData, stringData, |
if (aLocalPlayer.Race = "Terran" || aLocalPlayer.Race = "Protoss" )
Gdip_DrawImage(G, pBitmap, 0, stringData2 - (stringData4/2), Width, Height, 0, 0, SourceWidth, SourceHeight)
else
Gdip_DrawImage(G, pBitmap, 0, stringData2 - (stringData4/4), Width, Height, 0, 0, SourceWidth, SourceHeight)
Gdip_DeleteGraphics(G)
UpdateLayeredWindow(hwnd1, hdc,,,,, overlayMacroTownHallTransparency)
, SelectObject(hdc, obm)
, DeleteObject(hbm)
, DeleteDC(hdc)
Return
}
getLocalUpgrades(byRef aUpgrades, percentMode)
{
static aUpgradeStructures := [], aMorphingStructures := []
if !aUpgradeStructures.MaxIndex()
{
upgradeStructures := "CommandCenter|EngineeringBay|Armory|BarracksTechLab|FactoryTechLab|StarportTechLab|GhostAcademy|FusionCore"
. "|Forge|CyberneticsCore|TwilightCouncil|FleetBeacon|RoboticsBay|TemplarArchive"
. "|Hatchery|Lair|Hive|SpawningPool|EvolutionChamber|RoachWarren|BanelingNest|HydraliskDen|InfestationPit|Spire|GreaterSpire|UltraliskCavern"
morphingStructures := "CommandCenter|Hatchery|Lair|Spire"
aUpgradeStructures := []
loop, parse, upgradeStructures, |
{
aUpgradeStructures[aUnitID[A_LoopField]] :=  True
}
aMorphingStructures := []
loop, parse, morphingStructures, |
aMorphingStructures[aUnitID[A_LoopField]] :=  True
}
aUpgrades := []
deadOrUnderConstruction := aUnitTargetFilter.Dead | aUnitTargetFilter.UnderConstruction
loop, % DumpUnitMemory(MemDump)
{
if (numgetUnitTargetFilter(MemDump, unit := A_Index - 1) & deadOrUnderConstruction)
|| numgetUnitOwner(MemDump, Unit) != aLocalPlayer["Slot"]
|| !aUpgradeStructures.HasKey(Type := numgetUnitModelType(numgetUnitModelPointer(MemDump, Unit)))
Continue
if aMorphingStructures.HasKey(Type)
{
if (Type = aUnitID["CommandCenter"] && MorphingType := isCommandCenterMorphing(unit))
|| ((Type = aUnitID["Hatchery"] || Type = aUnitID["Lair"] || Type = aUnitID["Spire"]) && (MorphingType := isHatchLairOrSpireMorphing(unit, Type)))
{
progress := getUnitMorphTime(unit, type, percentMode)
name := aUnitName[MorphingType]
aUpgrades["zzzz" name] := {Name: name, Progress: percentMode
? (aUpgrades["zzzz" name].progress > progress ? aUpgrades["zzzz" name].progress : progress)
:  (aUpgrades["zzzz" name].progress && aUpgrades["zzzz" name].progress < progress ? aUpgrades["zzzz" name].progress : progress)
, count: round(aUpgrades["zzzz" name].Count) + 1}
hasItems := True
continue
}
else if (Type = aUnitID["CommandCenter"])
continue
}
if (queueSize := getStructureProductionInfo(unit, type, aQueueInfo,, percentMode))
{
for i, aProduction in aQueueInfo
{
if a_pBitmap.haskey(aProduction.Item)
{
hasItems := True
name := aProduction.Item
progress := aProduction.progress
aUpgrades[name] := {Name: name, Progress: percentMode
? (aUpgrades[name].progress > progress ? aUpgrades[name].progress : progress)
: (aUpgrades[name].progress && aUpgrades[name].progress < progress ? aUpgrades[name].progress : progress)
, count: round(aUpgrades[name].Count) + 1
, chrono: aLocalPlayer["Race"] = "Protoss" ? numgetIsUnitChronoed(MemDump, unit) : 0}
}
}
}
}
return (hasItems)
}
DrawLocalUpgradesOverlay(ByRef Redraw, UserScale = 1, Drag = 0)
{
global localUpgradesItemsPerRow, LocalUpgradesOverlayX, LocalUpgradesOverlayY, overlayLocalUpgradesTransparency
, DrawLocalUpgradesOverlay
static Font := "Arial", overlayCreated, hwnd1, DragPrevious := 0, upgradesExistPrevious := 0
percentMode := (DrawLocalUpgradesOverlay = 1)
If (Redraw = -1)
{
Try Gui, LocalUpgradesOverlay: Destroy
overlayCreated := False
Redraw := 0
Return
}
Else if (ReDraw AND WinActive(GameIdentifier))
{
Try Gui, LocalUpgradesOverlay: Destroy
overlayCreated := False
Redraw := 0
}
If (!overlayCreated)
{
Gui, LocalUpgradesOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound +ToolWindow +AlwaysOnTop
Gui, LocalUpgradesOverlay: Show, NA X%LocalUpgradesOverlayX% Y%LocalUpgradesOverlayY% W400 H400, % aOverlayTitles["LocalUpgradesOverlay"]
OnMessage(0x201, "OverlayMove_LButtonDown")
OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
overlayCreated := True
}
If (Drag AND !DragPrevious)
{	DragPrevious := 1
Gui, LocalUpgradesOverlay: -E0x20
}
Else if (!Drag AND DragPrevious)
{	DragPrevious := 0
Gui, LocalUpgradesOverlay: +E0x20 +LastFound
WinGetPos, LocalUpgradesOverlayX, LocalUpgradesOverlayY
IniWrite, %LocalUpgradesOverlayX%, %config_file%, Overlays, LocalUpgradesOverlayX
Iniwrite, %LocalUpgradesOverlayY%, %config_file%, Overlays, LocalUpgradesOverlayY
}
DestX := DestY := 0
if !localUpgradesItemsPerRow
localUpgradesItemsPerRow := 9999
upgradesExist := getLocalUpgrades(aUpgrades, percentMode)
if (upgradesExist) || (!upgradesExist && upgradesExistPrevious) || drag
{
if (drag && !upgradesExist)
{
progress := percentMode ? .80 : 65
aUpgrades := {	1: {name: "ResearchShieldWall", progress: progress, count: 1}
,	2: {name: "Stimpack", progress: progress, count: 1}
,	3: {name: "ResearchExtendedThermalLance", progress: progress, count: 1}
,	4: {name: "ResearchWarpGate", progress: progress, count: 1}
,	5: {name: "zerglingmovementspeed", progress: progress, count: 1}
,	6: {name: "Lair", progress: progress, count: 2}	}
}
hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
, hdc := CreateCompatibleDC()
, obm := SelectObject(hdc, hbm)
, G := Gdip_GraphicsFromHDC(hdc)
, Gdip_SetSmoothingMode(G, 4)
, Gdip_SetInterpolationMode(G, 2)
rowCount := 0, windowWidth := WindowHeight := 20
for i, upgrade in aUpgrades
{
if !(pBitmap := a_pBitmap[aUnitID.HasKey(upgrade.name) ? aUnitID[upgrade.name] : upgrade.name])
continue
SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
, Width *= UserScale *.5, Height *= UserScale *.5
Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
if (upgrade.Count > 1)
{
Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack, DestX + .6*Width, DestY, Width/2.5, Height/2.5, 5)
, gdip_TextToGraphics(G, upgrade.Count, "x"(DestX + .5*Width + .3*Width/2) "y"(DestY + .10*Height/2)  " Bold Italic cFFFFFFFF r4 s" 11*UserScale, Font)
}
if (upgrade.Chrono)
Gdip_FillEllipse(G, a_pBrushes["ScanChrono"], DestX + .2*Width/2, DestY + .2*Height/2, 6*UserScale, 6*UserScale)
if percentMode
{
Gdip_SetSmoothingMode(G, 0)
, Gdip_FillRectangle(G, a_pBrushes.TransparentBlack, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width - 10 * UserScale *.5, Height/12)
, Gdip_FillRectangle(G, a_pBrushes.Green, DestX + 5 * UserScale *.5, floor(DestY+Height + 5 * UserScale *.5), Width*upgrade.progress - upgrade.progress * 10 * UserScale *.5, Height/12)
, Gdip_SetSmoothingMode(G, 4)
}
else
{
Gdip_FillRoundedRectangle(G, a_pBrushes.TransparentBlack,  DestX + 5 * UserScale *.5, floor(DestY+Height + 3 * UserScale *.5), Width - 10 * UserScale *.5, Height/2.5, 2)
, gdip_TextToGraphics(G, formatSeconds(upgrade.progress), "x"(DestX + Width//2) " y"floor(DestY+Height + 5 * UserScale *.5)  " centre cFFFFFFFF r4 s" 12*UserScale, Font)
}
if (DestX > windowWidth)
windowWidth := DestX
if (DestY > WindowHeight)
WindowHeight := DestY
if (++rowCount >= localUpgradesItemsPerRow)
DestX := 0, DestY += Height + (percentMode ? 10 : 17) * UserScale, rowCount := 0
else DestX += Width+5*UserScale
}
windowWidth += 2*Width, WindowHeight += 2*Height
if (WindowWidth > A_ScreenWidth)
WindowWidth := A_ScreenWidth
if (WindowHeight > A_ScreenHeight)
WindowHeight := A_ScreenHeight
Gdip_DeleteGraphics(G)
, UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight, overlayLocalUpgradesTransparency)
, SelectObject(hdc, obm)
, DeleteObject(hbm)
, DeleteDC(hdc)
}
upgradesExistPrevious := upgradesExist
Return
}
changeScriptMainWinTitle(newTitle := "")
{
static currentTitle := A_ScriptFullPath " - AutoHotkey"
prevDetectWindows := A_DetectHiddenWindows
prevMatchMode := A_TitleMatchMode
DetectHiddenWindows, On
SetTitleMatchMode, 2
if (newTitle = "")
{
loop, % rand(2,20)
newTitle .= (rand(0,4) ? Chr(rand(97, 122)) : Chr(rand(48, 57)))
}
WinSetTitle, %currentTitle%,, %newTitle%
currentTitle := newTitle
DetectHiddenWindows, %prevDetectWindows%
SetTitleMatchMode, %prevMatchMode%
return newTitle
}
ReadMemory(MADDRESS=0,PROGRAM="",BYTES=4)
{
Static OLDPROC, ProcessHandle
VarSetCapacity(buffer, BYTES)
If (PROGRAM != OLDPROC)
{
if ProcessHandle
closed := DllCall("CloseHandle", "UInt", ProcessHandle), ProcessHandle := 0, OLDPROC := ""
if PROGRAM
{
WinGet, pid, pid, % OLDPROC := PROGRAM
if !pid
return "Process Doesn't Exist", OLDPROC := ""
ProcessHandle := DllCall("OpenProcess", "Int", 16, "Int", 0, "UInt", pid)
}
}
If !(ProcessHandle && DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Ptr", &buffer, "UInt", BYTES, "Ptr", 0))
return !ProcessHandle ? "Handle Closed: " closed : "Fail"
else if (BYTES = 1)
Type := "UChar"
else if (BYTES = 2)
Type := "UShort"
else if (BYTES = 4)
Type := "UInt"
else
Type := "Int64"
return numget(buffer, 0, Type)
}
ReadRawMemory(MADDRESS=0,PROGRAM="", byref Buffer="", BYTES=4)
{
Static OLDPROC, ProcessHandle
VarSetCapacity(Buffer, BYTES)
If (PROGRAM != OLDPROC)
{
if ProcessHandle
closed := DllCall("CloseHandle", "UInt", ProcessHandle), ProcessHandle := 0,  OLDPROC := ""
if PROGRAM
{
WinGet, pid, pid, % OLDPROC := PROGRAM
if !pid
return "Process Doesn't Exist", OLDPROC := ""
ProcessHandle := DllCall("OpenProcess", "Int", 16, "Int", 0, "UInt", pid)
}
}
If (ProcessHandle && DllCall("ReadProcessMemory","UInt",ProcessHandle,"UInt",MADDRESS,"Ptr",&Buffer,"UInt",BYTES,"Ptr*",bytesread))
return bytesread
return !ProcessHandle ? "Handle Closed:" closed : "Fail"
}
pointer(game, base, offsets*)
{
For index, offset in offsets
{
if (index = offsets.maxIndex() && A_index = 1)
pointer := offset + ReadMemory(base, game)
Else
{
IF (A_Index = 1)
pointer := ReadMemory(offset + ReadMemory(base, game), game)
Else If (index = offsets.MaxIndex())
pointer += offset
Else pointer := ReadMemory(pointer + offset, game)
}
}
Return ReadMemory(pointer, game)
}
ReadMemory_Str(MADDRESS := 0, PROGRAM := "", size := 0)
{
Static OLDPROC, ProcessHandle
If (PROGRAM != OLDPROC)
{
if ProcessHandle
{
closed := DllCall("CloseHandle", "UInt", ProcessHandle)
ProcessHandle := 0, OLDPROC := ""
if !PROGRAM
return closed
}
if PROGRAM
{
WinGet, pid, pid, % OLDPROC := PROGRAM
if !pid
return "Process Doesn't Exist", OLDPROC := ""
ProcessHandle := DllCall("OpenProcess", "Int", 16, "Int", 0, "UInt", pid)
}
}
bufferSize := VarSetCapacity(Output, size ? size : 100, 0)
If !size
{
Loop
{
success := DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS + A_Index - 1, "Ptr", &Output, "Uint", 1, "Ptr", 0)
if (ErrorLevel || !success)
return
else if (0 = NumGet(Output, 0, "Char"))
{
if (bufferSize < size := A_Index)
VarSetCapacity(Output, size)
break
}
}
}
DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Ptr", &Output, "Uint", size, "Ptr", 0)
return StrGet(&Output,, "UTF-8")
}
WriteMemory(WriteAddress = "", PROGRAM="", Data="", TypeOrLength = "")
{
Static OLDPROC, hProcess, pid
If (PROGRAM != OLDPROC)
{
if hProcess
closed := DllCall("CloseHandle", "UInt", hProcess), hProcess := 0, OLDPROC := ""
if PROGRAM
{
WinGet, pid, pid, % OLDPROC := PROGRAM
if !pid
return "Process Doesn't Exist", OLDPROC := ""
hProcess := DllCall("OpenProcess", "Int", 0x8 | 0x20, "Int", 0, "UInt", pid)
}
}
If Data is Number
{
If TypeOrLength is Integer
{
DataAddress := Data
DataSize := TypeOrLength
}
Else
{
If (TypeOrLength = "Double" or TypeOrLength = "Int64")
DataSize = 8
Else If (TypeOrLength = "Int" or TypeOrLength = "UInt"
or TypeOrLength = "Float")
DataSize = 4
Else If (TypeOrLength = "Short" or TypeOrLength = "UShort")
DataSize = 2
Else If (TypeOrLength = "Char" or TypeOrLength = "UChar")
DataSize = 1
Else {
Return False
}
VarSetCapacity(Buf, DataSize, 0)
NumPut(Data, Buf, 0, TypeOrLength)
DataAddress := &Buf
}
}
Else
{
DataAddress := &Data
If TypeOrLength is Integer
{
If A_IsUnicode
DataSize := TypeOrLength * 2
Else
DataSize := TypeOrLength
}
Else
{
If A_IsUnicode
DataSize := (StrLen(Data) + 1) * 2
Else
DataSize := StrLen(Data) + 1
}
}
if (hProcess && DllCall("WriteProcessMemory", "UInt", hProcess
, "UInt", WriteAddress
, "UInt", DataAddress
, "UInt", DataSize
, "UInt", 0))
return
else  return !hProcess ? "Handle Closed:" closed : "Fail"
}
DecToHex(Value)
{
oldfrmt := A_FormatInteger
hex := Value
SetFormat, IntegerFast, Hex
hex += 0
hex .= ""
SetFormat, IntegerFast, %oldfrmt%
return hex
}
reverseArray(Byref a)
{
aIndices := []
for index, in a
aIndices.insert(index)
aStorage := []
loop % aIndices.maxIndex()
aStorage.insert(a[aIndices[aIndices.maxIndex() - A_index + 1]])
a := aStorage
return aStorage
}
bubbleSort2DArray(Byref a, key, ascending := True)
{
aStorage := []
unsorted := True
While unsorted
{
unsorted := False
For index, in a
{
if (lastIndex = index)
break
if (A_Index > 1) &&  (ascending
? (a[prevIndex, key] > a[index, key])
: (a[prevIndex, key] < a[index, key]))
{
aStorage := a[index]
, a[index] := a[prevIndex]
, a[prevIndex] := aStorage
, unsorted := True
}
prevIndex := index
}
lastIndex := prevIndex
}
}
getScreenAspectRatio()
{
AspectRatio := Round(A_ScreenWidth / A_ScreenHeight, 2)
if ( AspectRatio = Round(1680/1050, 2))
AspectRatio := "16:10"
else if (AspectRatio = Round(1920/1080, 2))
AspectRatio := "16:9"
else if (AspectRatio = Round(1280/1024, 2))
AspectRatio := "5:4"
else if (AspectRatio = Round(1600/1200, 2))
AspectRatio := "4:3"
else AspectRatio := "Unknown"
return AspectRatio
}
getKeyboardAndMouseButtonArray(keyList=31)
{
l_StandardKeysList=
       (ltrim join|
        *A|*B|*C|*D|*E|*F|*G|*H|*I|*J|*K|*L|*M|*N|*O|*P|*Q|*R|*S|*T|*U|*V|*W|*X|*Y|*Z
        *0|*1|*2|*3|*4|*5|*6|*7|*8|*9
        *``|*-|*=|*[|*]|*`\|*;
        *'|*,|*.|*/
        *Space
        *Tab
        *Enter
        *Escape
        *Backspace
        *Delete
        *ScrollLock
        *CapsLock
        *NumLock
        *PrintScreen
        *CtrlBreak
        *Pause
        *Break
        *Insert
        *Home
        *End
        *PgUp
        *PgDn
        *Up
        *Down
        *Left
        *Right
)
l_FunctionKeysList=
       (ltrim join|
        *F1|*F2|*F3|*F4|*F5|*F6|*F7|*F8|*F9|*F10
        *F11|*F12|*F13|*F14|*F15|*F16|*F17|*F18|*F19|*F20
        *F21|*F22|*F23|*F24
)
l_ModifierKeysList := "*Shift|*Control|*Alt"
l_NumpadKeysList=
       (ltrim join|
        *NumLock
        *NumpadDiv
        *NumpadMult
        *NumpadAdd
        *NumpadSub
        *NumpadEnter
        *NumpadDel
        *NumpadIns
        *NumpadClear
        *NumpadUp
        *NumpadDown
        *NumpadLeft
        *NumpadRight
        *NumpadHome
        *NumpadEnd
        *NumpadPgUp
        *NumpadPgDn
        *Numpad0
        *Numpad1
        *Numpad2
        *Numpad3
        *Numpad4
        *Numpad5
        *Numpad6
        *Numpad7
        *Numpad8
        *Numpad9
        *NumpadDot
)
l_MouseKeysList=
       (ltrim join|
        LButton
        *LButton
        +LButton
        ^LButton
        !LButton
        +^LButton
        +!LButton
        ^!LButton
        +^!LButton
        LButton Up
        *LButton Up
        +LButton Up
        ^LButton Up
        !LButton Up
        +^LButton Up
        +!LButton Up
        ^!LButton Up
        +^!LButton Up
        *RButton
        *MButton
        *WheelDown
        *WheelUp
        *XButton1
        *XButton2
)
l_MultimediaKeysList=
       (ltrim join|
        *Browser_Back
        *Browser_Forward
        *Browser_Refresh
        *Browser_Stop
        *Browser_Search
        *Browser_Favorites
        *Browser_Home
        *Volume_Mute
        *Volume_Down
        *Volume_Up
        *Media_Next
        *Media_Prev
        *Media_Stop
        *Media_Play_Pause
        *Launch_Mail
        *Launch_Media
        *Launch_App1
        *Launch_App2
)
l_Keys := []
if (keyList & 1)
loop, parse, l_StandardKeysList, |
l_Keys.insert(A_Loopfield)
if (keyList & 2)
loop, parse, l_FunctionKeysList, |
l_Keys.insert(A_Loopfield)
if (keyList & 4)
loop, parse, l_NumpadKeysList, |
l_Keys.insert(A_Loopfield)
if (keyList & 8)
loop, parse, l_MouseKeysList, |
l_Keys.insert(A_Loopfield)
if (keyList & 16)
loop, parse, l_MultimediaKeysList, |
l_Keys.insert(A_Loopfield)
if (keyList & 32)
loop, parse, l_ModifierKeysList, |
l_Keys.insert(A_Loopfield)
return l_Keys
}
DesktopScreenCoordinates(byref Xmin, byref Ymin, byref Xmax, byref Ymax)
{
SysGet, Xmin, 76
SysGet, Ymin, 77
SysGet, VirtualScreenWidth, 78
SysGet, VirtualScreenHeight, 79
Xmax := Xmin + VirtualScreenWidth
Ymax := Ymin + VirtualScreenHeight
return
}
getRandomString_Az09(minLength, maxLength, insertSpace := True)
{
loop, % l := rand(minLength, maxLength)
{
if (A_Index > 1 && A_Index != l && insertSpace && !rand(0, 5))
s .= A_Space
else if rand(0, 4)
s .= Chr(rand(0, 2) ? rand(97, 122) : rand(65, 90) )
else
s .= rand(0, 9)
}
return s
}
getProcessBaseAddress(WindowTitle, MatchMode=3)
{
mode :=  A_TitleMatchMode
SetTitleMatchMode, %MatchMode%
WinGet, hWnd, ID, %WindowTitle%
SetTitleMatchMode, %mode%
if !hWnd
return
BaseAddress := DllCall(A_PtrSize = 4
? "GetWindowLong"
: "GetWindowLongPtr", "Ptr", hWnd, "Uint", -6, "UInt")
return BaseAddress
}
rand(a=0.0, b=1)
{
random, r, a, b
return r
}