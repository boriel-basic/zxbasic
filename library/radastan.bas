' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2017
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Radastan mode library for ZX UNO and compatible machines
' ----------------------------------------------------------------

#ifndef __LIBRARY_RADASTAN__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_RADASTAN__

' ----------------------------------------------------------------
' function NAME
'
' Parameters:
'     x <explanation>
'     y <explanation>
'
' Returns:
'     <explanation> (When nothing to return, use SUB instead)
' ----------------------------------------------------------------
sub RadastanMode(enable as Ubyte)
    OUT 64571, 64
    OUT 64827, 3 * SGN(enable)
end sub


' ----------------------------------------------------------------
' function RadastanPlot
'
' Parameters:
'     x: coord x (horizontal) of pixel to plot
'     y: coord y (vertical) of pixel to plot
'     color: color palette (0..15)
' ----------------------------------------------------------------
sub fastcall RadastanPlot(ByVal x as ubyte, ByVal y as ubyte, ByVal colorIdx as ubyte)
    asm
    PROC
    LOCAL rplotnext2, rplotfin, COORDS
COORDS EQU 5C7Dh
    pop hl       ; ret addr
    pop de       ; D = y
    ld e, a      ; E = x
    ex (sp), hl  ; callee, h = color
    ld a, 127
    cp e 
    ret c        ; Out of screen
    ld a, 95
    cp d
    ret c        ; Out of screen
    ld (COORDS), de  ; Stores pixel coords 
    ld l, h      ; l = color
    xor a
    rr e
    adc a, a
    xor 1
    ld h, a
    ld a, d      ;' recuperamos el valor vertical
    rrca
    rrca         ;' rotamos para dejar su valor en multiplos de 64 (linea, de dos en dos pixels)
    and 192      ;' borramos el resto de bits por si las moscas
    or e         ;' sumamos el valor horizontal
    ld e, a      ;' e preparado
    ld a, d      ;' cargamos el valor vertical
    rrca
    rrca         ;' rotamos para quedarnos con los bits altos
    and 63       ;' borramos el resto de bits
    or 64        ;' nos posicionamos a partir de 16384 (16384=64+0 en dos bytes)
    ld d, a      ;' d preparado, ya tenemos la posicion en pantalla
    ld a,(de)
    rr h
    jr c, rplotnext2
    and 240
    or l
    jr rplotfin

rplotnext2:
    and 15
    rl l
    rl l
    rl l
    rl l
    or l

rplotfin:
    ld (de), a
    ENDP
    end asm
end sub


' ----------------------------------------------------------------
' function RadastanDraw
'
' Draws a line from the last plotted position to the given coords.
'
' Parameters:
'     x: coord x (horizontal) of pixel to plot
'     y: coord y (vertical) of pixel to plot
'     color: color palette (0..15)
' ----------------------------------------------------------------
SUB RadastanDraw(ByVal x1 as Byte, ByVal y1 as Byte, Byval colorIdx as Ubyte)
    DIM sx, sy as Byte
    DIM x, y, x0, y0 as Byte
    DIM p, dx, dy, iE, iNE as Integer

    LET x0 = PEEK 5C7Dh
    LET y0 = PEEK 5C7Eh

    LET dx = x1 - x0
    LET dy = y1 - y0

    LET sy = SGN(dy)
    IF dy < 0 THEN
        LET dy = -dy
    END IF

    LET sx = SGN(dx)
    IF dx < 0 THEN
        LET dx = -dx
    END IF

    LET x = x0
    LET y = y0
    RadastanPlot(x, y, colorIdx)

    IF dx > dy THEN
        LET p = 2 * dy - dx
        LET iE = 2 * dy
        LET iNE = 2 * (dy - dx)
        WHILE x <> x1
            LET x = x + sx
            IF p < 0 THEN
                LET p = p + iE
            ELSE
                LET y = y + sy
                LET p = p + iNE
            END IF
            RadastanPlot(x, y, colorIdx)
        END WHILE
    ELSE
        LET p = 2 * dx - dy
        LET iE = 2 * dx
        LET iNE = 2 * (dx - dy)
        WHILE y <> y1
            LET y = y + sy
            IF p < 0 THEN
                LET p = p + iE
            ELSE
                LET x = x + sx
                LET p = p + iNE
            END IF
            RadastanPlot(x, y, colorIdx)
        END WHILE
    END IF
END SUB


SUB RadastanPalette(ByVal colorIndex as Ubyte, ByVal rgb as UByte) ' color=0-15, rgb = binary GGGRRRBB
   OUT 48955, 64: OUT 65339, 1
   OUT 48955, colorIndex: OUT 65339, rgb
END SUB


SUB fastcall RadastanCls(color as ubyte)
   ASM
   and 0xF
   ld b, a
   rla
   rla
   rla
   rla
   or b
   ld hl, 16384
   ld de, 16385
   ld bc, 6143
   ld (hl), a
   ldir
   ld hl, 0
   ld (5C7Dh), hl  ; COORDS
   END ASM
END SUB


#endif
