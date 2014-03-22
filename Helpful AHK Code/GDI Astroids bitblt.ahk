#Persistent
#SingleInstance force
SetBatchLines, -1
sendmode, Input


#SingleInstance, Force
#NoEnv
SetBatchLines, -1

;#Include, Gdip.ahk

If !pToken := Gdip_Startup()
{
   MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
   ExitApp
}
OnExit, Exit

Width := A_ScreenWidth//1.5, Height := A_ScreenHeight//1.5

Gui, 1: +LastFound
Gui, 1: Show, w%Width% h%Height%, Asteroids using gdi+
hwnd1 := WinExist()
hwnddc := GetDC(hwnd1)

hbm := CreateDIBSection(Width, Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc), Gdip_SetSmoothingMode(G, 4)

pBrushSHIP1 := Gdip_BrushCreateSolid(0xffa39f9f)
pBrushSHIP2 := Gdip_BrushCreateSolid(0xff7f7575)
pBrushSHIP3 := Gdip_BrushCreateSolid(0xff4c4a4a)

pBitmapBackground := CreateBackground(Width, Height)

Ship = 5|0|20|10|0|-50|-20|10
x := Width//2, y := Height//2, Vx := Vy := Va := 0
SetTimer, Update, 30
return

;#######################################################################

Update:
arr := ""
Va += GetKeyState("Left") ? -0.1 : GetKeyState("Right") ? 0.1 : 0
Loop, Parse, Ship, |
   Mod(A_Index, 2) ? xt := A_LoopField : arr .= xt*cos(Va)-A_LoopField*Sin(Va) "|" xt*Sin(Va)+A_LoopField*Cos(Va) "|"
StringTrimRight, arr, arr, 1

Vs := GetKeyState("Up") ? 0.4 : GetKeyState("Down") ? -0.2 : 0
Vx := Vx*0.95+Sin(Va)*Vs, Vy := Vy*0.95-Cos(Va)*Vs
x := x < 0 ? Width : x > Width ? 0 : x+Vx , y := y < 0 ? Height : y > Height ? 0 : y+Vy

Gdip_DrawImage(G, pBitmapBackground, 0, 0, Width, Height)

StringSplit, narr, arr, |
1narr := narr1+x "," narr2+y "|" narr3+x "," narr4+y "|" narr5+x "," narr6+y
2narr := narr5+x "," narr6+y "|" narr7+x "," narr8+y "|" narr1+x "," narr2+y
3narr := narr1+x "," narr2+y "|" narr3+x "," narr4+y "|" narr1+x "," ((narr4-narr2)//2)+y "|" narr7+x "," narr8+y

Gdip_FillPolygon(G, pBrushSHIP1, 1narr)
Gdip_FillPolygon(G, pBrushSHIP2, 2narr)
Gdip_FillPolygon(G, pBrushSHIP3, 3narr)
Gdip_DrawImage(G, pBitmap1)
BitBlt(hwnddc, 0, 0, Width, Height, hdc, 0, 0)
return

;#######################################################################

CreateBackground(Width, Height)
{
   pBitmap := Gdip_CreateBitmap(Width, Height)
   G := Gdip_GraphicsFromImage(pBitmap), Gdip_SetSmoothingMode(G, 4)

   pBrushBlack := Gdip_BrushCreateSolid(0xff000000)
   Gdip_FillRectangle(G, pBrushBlack, 0, 0, Width, Height)
   Gdip_DeleteBrush(pBrushBlack)

   pBrushStar := Gdip_BrushCreateSolid(0xffeeeeee)
   Loop, % (Width*Height)/400      ;%
   {
      Random, s, 1, 4
      Random, x, -s//2, Width+(s//2)
      Random, y, -s//2, Height+(s//2)
      Gdip_FillEllipse(G, pBrushStar, x, y, s, s)
   }
   Gdip_DeleteGraphics(G)
   Gdip_DeleteBrush(pBrushStar)
   return pBitmap
}

;#######################################################################

GuiClose:
Exit:
Gdip_DeleteBrush(pBrushSHIP1), Gdip_DeleteBrush(pBrushSHIP2), Gdip_DeleteBrush(pBrushSHIP3)
Gdip_DisposeImage(pBitmapBackground)
SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
Gdip_DeleteGraphics(G)
Gdip_Shutdown(pToken)
ExitApp
return