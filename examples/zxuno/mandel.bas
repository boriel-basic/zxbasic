'Compile with Boriel ZX Basic Compiler
'Parameters: -t -B -a -O3

'(C)2015 Miguel Angel Rodriguez Jodar (mcleod_ideafix)
'miguel.angel@zxprojects.com

'Distributed under GPL license

#include <radastan.bas>

#define XMAX 127
#define YMAX 95
#define PART 32  'Initial dimension of a square
#define ESC 15   'Max. iterations for escape time algorithm (hint: we use colours 1-15)


declare sub PutPal (entry as ubyte, col as ubyte)
declare function GetPal (entry as ubyte) as ubyte
declare function MakeRGB (r as ubyte, g as ubyte, b as ubyte) as ubyte

'------------------------------------------------------------------------------

Dim i as ubyte
border 0
cls    'A pixel with value 0 means pixel not processed. Processed pixels have values 1-15

RadastanMode(1)

for i = 0 to 7   'Initialize all 64 entries of the ULAplus palette
    PutPal (i,    MakeRGB(i,0,0))       'negro    -> rojo
    PutPal (i+8,  MakeRGB(7,i,0))       'rojo     -> amarillo
    PutPal (i+16, MakeRGB(7,7,i/2))     'amarillo -> blanco
    PutPal (i+24, MakeRGB(7,7-i,3))     'blanco   -> magenta
    PutPal (i+32, MakeRGB(7-i,0,3))     'magenta  -> azul
    PutPal (i+40, MakeRGB(0,i,3))       'azul     -> cyan
    PutPal (i+48, MakeRGB(0,7,(7-i)/2)) 'cyan     -> verde
    PutPal (i+56, MakeRGB(0,7-i,0))     'verde    -> negro
next i

'Main loop: divide screen into PARTxPART squares and process each one
dim y as ubyte
dim x as uinteger
for y = 0 to YMAX step PART
    for x = 0 to XMAX step PART
        mandel (x,y,PART)  'First call to recursive function
    next x
next y

'Palette cycling animation
Dim color0 as ubyte
BucleCicloPaleta:
pause 4
color0 = GetPal(0)
for i = 0 to 62
    PutPal (i, GetPal((i+1) mod 64))
next i
PutPal (63,color0)

if inkey$="" then
    goto BucleCicloPaleta
end if

RadastanMode(0)
border 7
cls
End

'------------------------------------------------------------------------------

function escape (x as uinteger, y as ubyte) as ubyte
    dim cr,ci,zr,zi,tr,ti as fixed
    dim c as uinteger
    dim zrc,zic as fixed

    cr = -2.4+x*3.2/XMAX
    ci = -1.2+y*2.4/YMAX
    zr = cr
    zi = ci
    zrc = cr*cr
    zic = ci*ci
    c = 1
    while (zrc+zic)<4 and c<>ESC
        tr = zrc-zic+cr
        ti = 2*zr*zi+ci
        zr = tr
        zi = ti
        zrc = zr*zr
        zic = zi*zi
        c = c + 1
    end while
    return c
end function


#define PlotR  RadastanPlot
#define PixelR RadastanPoint
#define DrawRH(x, y, l, c)  RadastanHLine(x, y, x + l - 1, c)

sub mandel (x as uinteger, y as ubyte, lv as ubyte)
    dim co1,co2 as ubyte
    dim xx as uinteger
    dim yy as ubyte

    'Base case: compute colour for all pixels of the 2x2 square
    if lv = 2 then
       co1 = escape (x,y)
       RadastanPlot (x,y,co1)
       co1 = escape (x+1,y)
       RadastanPlot (x+1,y,co1)
       co1 = escape (x,y+1)
       RadastanPlot (x,y+1,co1)
       co1 = escape (x+1,y+1)
       RadastanPlot (x+1,y+1,co1)
       return
    end if

    'Compute colours for the perimeter of the current square
    co1 = RadastanPoint (x,y)  'Read first pixel. If not processed...
    if co1 = 0 then     '...compute and plot it.
        co1 = escape (x,y)
        RadastanPlot (x,y,co1)
    end if
    for yy = y to y+lv-1
        xx = x
        do
          co2 = PixelR (xx,yy)  'Read current pixel. If not processed...
          if co2 = 0 then
              co2 = escape (xx,yy)  '... compute and plot it
              PlotR (xx,yy,co2)
          end if
          if co1<>co2 then    'Are they different?
             goto subdividir  'then, abort perimeter calculation and go directly to subdivision
          end if
          if yy=y or yy=y+lv-1 then
             xx = xx + 1
          else
             xx = xx + lv-1
          end if
        loop until xx>=x+lv
    next yy

    'If we reach here, all pixels of the perimeter have the same escape time, so...
    for yy=y to y+lv-1    '... fill the square with the same colour
        DrawRH(x,yy,lv,co1)
    next yy
    return

    'If we reach here, we must partition the current square and recursively start over again
subdividir:
    mandel (x,y,lv/2)
    mandel (x+lv/2,y,lv/2)
    mandel (x,y+lv/2,lv/2)
    mandel (x+lv/2,y+lv/2,lv/2)
end sub

'------------------------------------------------------------------------------

sub PutPal (entry as ubyte, col as ubyte)
    out 48955,entry
    out 65339,col
end sub

function GetPal (entry as ubyte) as ubyte
    out 48955,entry
    return in 65339
end function

function MakeRGB (r as ubyte, g as ubyte, b as ubyte) as ubyte
    return ((g band 7) shl 5) bor ((r band 7) shl 2) bor (b band 3)
end function


