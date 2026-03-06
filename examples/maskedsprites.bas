' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyright (C) 2026 Conrado Badenas <conbamen@gmail.com>
'
' Example for
' Print Masked (AND+OR) Sprites, version 2026.03.06
' ----------------------------------------------------------------

#include <cb/maskedsprites.bas>

#include <random.bas>

CONST NUMMAXSPRITES as UByte = 10
CONST NUMSPRITES    as UByte = 7
if NUMSPRITES>NUMMAXSPRITES then stop

dim i,temp as Integer
dim pointx1,pointx2,pointy1,pointy2 as Integer 'for subtractions
dim x0(0 to NUMSPRITES-1) as UByte
dim y0(0 to NUMSPRITES-1) as UByte
dim x1(0 to NUMSPRITES-1) as UByte
dim y1(0 to NUMSPRITES-1) as UByte

for i=0 to NUMSPRITES-1
    y0(i)=255:y1(i)=255:x1(i)=randomLimit(240)
next i:x1(0)=120

SetVisibleScreen(5):if GetVisibleScreen()<>5 then STOP
paper 1:ink 7:border 0:cls

for i=0 to 127
    pointx1=randomLimit(255):pointy1=randomLimit(191)
    pointx2=randomLimit(255):pointy2=randomLimit(191)
    plot pointx1,pointy1:draw pointx2-pointx1,pointy2-pointy1
next i

CopyScreen5ToScreen7()
'print at 11,8;"Esto es Screen5"
SetDrawingScreen7() 'Bank7 is set at $c000
'print at 13,8;"Esto es Screen7"
SetDrawingScreen5() 'Bank7 is still set at $c000
'print at 15,8;"Esto es Screen5"

ASM
    xor a           ;  4 Ts     reseteamos el contador
    ld (23672),a    ; 13 Ts     de FRAMES a 0
END ASM

' Empezamos con VisibleScreen = DrawingScreen = 5
bucle:

    ' La nueva VisibleScreen está lista para que la ULA la saque por la tele
    ' Pero vamos a esperar al principio de un frame para que no haya tearing
    ' El 2 de luego significa que obtendremos 25 FPS como máximo
    ASM
        ld hl,23672
wait:
        ld a,(hl)   ; A = contador de FRAMES
        cp 2        ; 25 FPS como máximo
        jr c,wait   ; repetimos si A < 2
        xor a
        ld (hl),a   ; reseteamos el contador de FRAMES a 0
    END ASM

    ToggleVisibleScreen()
    ' Ahora se puede modificar la DrawingScreen porque no está Visible

    ' Restauramos fondo en x0,y0 si está guardado en MaskedSpritesBackground
    for i=0 to NUMSPRITES-1
        if y0(i)<>255 then RestoreBackground(x0(i),y0(i),MaskedSpritesBackground(i))
    next i

    ' Actualizamos x0,y0 y calculamos nuevos x1,y1
    for i=1 to NUMSPRITES-1
        temp=x1(i): x0(i)=temp
            temp=temp-1
            if temp<0 then temp=240
        x1(i)=temp
        temp=y1(i): y0(i)=temp
            if temp=255 then temp=randomLimit(176)
            if randomLimit(3)=0 then temp=temp+randomLimit(2)-1
            if temp<0   then temp=0
            if temp>176 then temp=176
        y1(i)=temp
    next i

    'Código especial para el prota
    temp=x1(0): x0(0)=temp
        temp=temp+1 -2*(in($dffe) bAND 1) +2*((in($dffe)>>1) bAND 1) '-noP+noO
        if temp<0   then temp=240
        if temp>240 then temp=0
    x1(0)=temp
    temp=y1(0): y0(0)=temp
        if temp=255 then temp=randomLimit(176)
        temp=temp -(in($fdfe) bAND 1) +(in($fbfe) bAND 1) '-noA+noQ
        if temp<0   then temp=0
        if temp>176 then temp=176
    y1(0)=temp

    ' Guardamos fondo en MaskedSpritesBackground y dibujamos sprites en x,y
    for i=NUMSPRITES-1 to 1 step -1
        SaveBackgroundAndDrawSprite(x1(i),y1(i),MaskedSpritesBackground(i),@enemigo0)
    next i
    SaveBackgroundAndDrawSprite(x1(0),y1(0),MaskedSpritesBackground(0),@prota0)

    ' Cambiamos el Set de Backgrounds para la siguiente iteración
    ChangeMaskedSpritesBackgroundSet()

    ' Hemos terminado de dibujar
    ' DrawingScreen actual está lista para ser mostrada ahora mismo
    ' Cambiamos de DrawingScreen para el siguiente ciclo de dibujo
    ToggleDrawingScreen()

    ' Ahora VisibleScreen = DrawingScreen y
    ' lo que se dibuje se verá mientras se dibuja

goto bucle

stop

prota0:
ASM
    defb %11000000,%00000000,%00001111,%00000000;1
    defb %10000000,%00011111,%00000000,%11100000;2
    defb %00000000,%00100000,%00000000,%00111110;3
    defb %00000000,%01001110,%00000000,%11111000;4
    defb %00000000,%01011001,%00000001,%00001100;5
    defb %00000000,%01011010,%00000000,%00010100;6
    defb %00000000,%00000011,%00000000,%11100010;7
    defb %00000000,%01111100,%00000000,%00100010;8
    defb %00000000,%01111100,%00000000,%00100010;8
    defb %00000000,%00000011,%00000000,%11100010;7
    defb %00000000,%01011010,%00000000,%00010100;6
    defb %00000000,%01011001,%00000001,%00001100;5
    defb %00000000,%01001110,%00000000,%11111000;4
    defb %00000000,%00100000,%00000000,%00111110;3
    defb %10000000,%00011111,%00000000,%11100000;2
    defb %11000000,%00000000,%00001111,%00000000;1
END ASM

enemigo0:
ASM
    defb %00000011,%00000000,%11000000,%00000000;1
    defb %00000011,%01111000,%11000000,%00011110;2
    defb %00000011,%01000000,%11000000,%00010000;3
    defb %00000001,%01010000,%10000000,%00010100;4
    defb %00000000,%01001000,%00000000,%00100010;5
    defb %00000000,%00000010,%00000000,%01110000;6
    defb %11100000,%00000111,%00000111,%11100000;7
    defb %11110000,%00000010,%00001111,%01000000;8
    defb %11110000,%00000010,%00001111,%01000000;8
    defb %11100000,%00000111,%00000111,%11100000;7
    defb %00000000,%00001110,%00000000,%01000000;6'
    defb %00000000,%01110100,%00000000,%00011110;5'
    defb %00000001,%01000000,%10000000,%00010000;4'
    defb %00000011,%01010000,%11000000,%00010100;3'
    defb %00000011,%01001000,%11000000,%00010010;2'
    defb %00000011,%00000000,%11000000,%00000000;1
END ASM

