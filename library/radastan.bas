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


#define RADASTAN_FONT   RadastanHaploFont

DIM RadastanScrAddr as UInteger = 16384
DIM RadastanColRow as UInteger = 0
DIM RadastanFontAddr as UInteger = @RADASTAN_FONT


REM Dummy lines (leave them for now)
dummy = RadastanScrAddr + RadastanColRow + RadastanFontAddr

' ----------------------------------------------------------------
' function RadastanMode
'
' Parameters:
'   enable: 0 => disable (normal mode), otherwise radastan mode
' ----------------------------------------------------------------
sub RadastanMode(enable as Ubyte)
    OUT 64571, 64
    OUT 64827, 3 * SGN(enable)
end sub


' ----------------------------------------------------------------
' function MakeRGB
' Converts an R, G, B color to a byte
'
' Parameters:
'    r: Red component
'    g: Green component
'    b: Blue component
' ----------------------------------------------------------------
function MakeRGB (r as ubyte, g as ubyte, b as ubyte) as ubyte
    return ((g band 7) shl 5) bor ((r band 7) shl 2) bor (b band 3)
end function


' ----------------------------------------------------------------
' Sub RadastanPlot
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
    ld c, 0
    ld a, d      ;' recuperamos el valor vertical
    rra
    rr c
    rra
    rr c
    ld b, a
    ld a, e
    add a, c
    ld c, a
    ex de, hl
    ld hl, (_RadastanScrAddr)
    add hl, bc
    ld a,(hl)
    rr d
    jr c, rplotnext2
    and 240
    or e
    jr rplotfin

rplotnext2:
    and 15
    rl e
    rl e
    rl e
    rl e
    or e

rplotfin:
    ld (hl), a
    ENDP
    end asm
end sub


' ----------------------------------------------------------------
' Sub RadastanPoint
'
' Parameters:
'     x: coord x (horizontal) of pixel to examine
'     y: coord y (vertical) of pixel to examine
'
' Returns:
'     color: color palette (0..15) or -1 if out of screen
' ----------------------------------------------------------------
Function fastcall RadastanPoint(ByVal x as ubyte, ByVal y as ubyte) as Byte
    ASM
    PROC
    LOCAL next2
    pop hl       ; ret addr
    ex (sp), hl  ; callee => h = y
    ld e, a      ; E = x
    ld a, 127
    cp e
    ld a, -1
    ret c        ; Out of screen
    ld a, 95
    cp h
    ld a, -1
    ret c        ; Out of screen
    xor a
    rr e
    adc a, a
    ld c, a      ; c = 0 if even, 1 if odd
    ld a, h
    rrca
    rrca
    and 192
    or e
    ld l, a
    ld a, h
    rrca
    rrca
    and 63
    ld h, a
    ld de, (_RadastanScrAddr)
    add hl, de
    ld a, (hl)
    rr c
    jr c, next2
    rra
    rra
    rra
    rra
next2:
    and 0xF
    ENDP
    END ASM
End Function


' ----------------------------------------------------------------
' Sub RadastanHLine
'
' Draws an horizontal line from (x0, y) to (x1, y)
'
' Parameters:
'     x0: coord x (horizontal) of first pixel to plot
'     y: coord y (vertical) of first pixel to plot
'     x1: coord x (horizontal) of the last pixel to plot
'     color: color palette (0..15)
' ----------------------------------------------------------------
Sub RadastanHLine(ByVal x0 as UByte, ByVal y as UByte, ByVal x1 as UByte, ByVal col as UByte)
    Dim x as UByte
    
    if x1 < x0 
        x = x1
        x1 = x0
        x0 = x
    end if

    FOR x = x0 TO x1
        RadastanPlot(x, y, col)
    NEXT x

End Sub


' ----------------------------------------------------------------
' Sub RadastanDraw
'
' Draws a line from the last plotted position to the given coords.
'
' Parameters:
'     x: coord x (horizontal) of last pixel to plot
'     y: coord y (vertical) of last pixel to plot
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


' ----------------------------------------------------------------
' Sub RadastanCircle
'
' Draws a Circle of radius r with center (x, y)
'
' Parameters:
'     x: coord x (horizontal) of circle center
'     y: coord y (vertical) of circle center
'     r: radius (in pixels)
'     color: color palette (0..15)
' ----------------------------------------------------------------
SUB RadastanCircle(ByVal x0 as Byte, ByVal y0 as Byte, ByVal r as Byte, ByVal colorIdx as UByte)
    DIM x, y, dx, dy, err as Byte

    x = r - 1
    y = 0
    dx = 1
    dy = 1
    err = dx - (r << 1)

    WHILE x >= y
        RadastanPlot(x0 + x, y0 + y, colorIdx)
        RadastanPlot(x0 + y, y0 + x, colorIdx)
        RadastanPlot(x0 - y, y0 + x, colorIdx)
        RadastanPlot(x0 - x, y0 + y, colorIdx)
        RadastanPlot(x0 - x, y0 - y, colorIdx)
        RadastanPlot(x0 - y, y0 - x, colorIdx)
        RadastanPlot(x0 + y, y0 - x, colorIdx)
        RadastanPlot(x0 + x, y0 - y, colorIdx)

        IF err <= 0 THEN
            y = y + 1
            err = err + dy
            dy = dy + 2
        END IF

        IF err > 0 THEN
            x = x - 1
            dx = dx + 2
            err = err + (-r << 1) + dx
        END IF
    END WHILE
END SUB


' ----------------------------------------------------------------
' Sub RadastanFillCircle
'
' Fills a Circle of radius r with center (x, y)
'
' Parameters:
'     x: coord x (horizontal) of circle center
'     y: coord y (vertical) of circle center
'     r: radius (in pixels)
'     color: color palette (0..15)
' ----------------------------------------------------------------
SUB RadastanFillCircle(ByVal x0 as Byte, ByVal y0 as Byte, ByVal r as Byte, ByVal colorIdx as UByte)
    DIM x, y, dx, dy, err as Byte

    x = r - 1
    y = 0
    dx = 1
    dy = 1
    err = dx - (r << 1)

    WHILE x >= y
        RadastanHLine(x0 - x, y0 + y, x0 + x, colorIdx)
        RadastanHLine(x0 - y, y0 + x, x0 + y, colorIdx)
        RadastanHLine(x0 - x, y0 - y, x0 + x, colorIdx)
        RadastanHLine(x0 - y, y0 - x, x0 + y, colorIdx)

        IF err <= 0 THEN
            y = y + 1
            err = err + dy
            dy = dy + 2
        END IF

        IF err > 0 THEN
            x = x - 1
            dx = dx + 2
            err = err + (-r << 1) + dx
        END IF
    END WHILE
END SUB


' ----------------------------------------------------------------
' sub RadastanPalette
'
' Defines a palette entry
'
' Parameters:
'    colorIndex: Palete index entry (0..15)
'    rgb: Color value rgb = binary GGGRRRBB
' ----------------------------------------------------------------
SUB RadastanPalette(ByVal colorIndex as Ubyte, ByVal rgb as UByte) '
   OUT 48955, colorIndex: OUT 65339, rgb
END SUB


' ----------------------------------------------------------------
' Sub RadastanCls
'
' Clears the screen with the given color
'
' Parameters:
'    col: Color index (0..15)
' ----------------------------------------------------------------
SUB fastcall RadastanCls(ByVal col as UByte)
   ASM
   and 0xF
   ld b, a
   rla
   rla
   rla
   rla
   or b
   ld hl, (_RadastanScrAddr)
   ld d, h
   ld e, l
   inc de
   ld bc, 6143
   ld (hl), a
   ldir
   ld hl, 0
   ld (5C7Dh), hl  ; COORDS
   ld (_RadastanColRow), hl
   END ASM
END SUB


' ----------------------------------------------------------------
' sub RadastanFill
'
' Fills the figure with the given color starting from the given
' coordinate.
'
' Parameters:
'     x: coord x (horizontal) of starting point
'     y: coord y (vertical) of starting point
'     color: fill color, palette (0..15)
' ----------------------------------------------------------------
SUB RadastanFill(Byval x as UByte, ByVal y as UByte, ByVal col as Ubyte)
    Const L as Uinteger = 1023
    Const L2 as Uinteger = L * 2 + 1
    DIM buff(L, 1) as UByte
    DIM i, j, paddr as Uinteger
    DIM c as Byte

    paddr = @buff(0, 0)

#define P(x, y) \
    POKE paddr + j, x \
    j = j + 1 \
    POKE paddr + j, y \
    j = (j + 1) bAND L2

    c = RadastanPoint(x, y)
    IF c = -1 THEN ' -1 => Out of Screen
        RETURN
    END IF

    i = 0
    j = 0
    P(x, y)

    WHILE i <> j
        x = PEEK(paddr + i)
        i = i + 1
        y = PEEK(paddr + i)
        i = (i + 1) bAND L2

        IF c <> RadastanPoint(x, y) THEN
            CONTINUE WHILE
        END IF

        RadastanPlot(x, y, col)
        P(x + 1, y)
        P(x - 1, y)
        P(x, y + 1)
        P(x, y - 1)
    END WHILE

#undef P
END SUB


' ----------------------------------------------------------------
' Sub RadastanPrintAt
'
' Places the printing cursor at the given row, column coordinates
'
' Parameters:
'     row: cursor row (0..31)
'     col: cursor column (0..15)
' ----------------------------------------------------------------
SUB FASTCALL RadastanPrintAt(ByVal row as UByte, ByVal col as Ubyte)
    ASM
    ; A register contains row
    pop hl
    ex (sp), hl ; h = col
    ld l, h
    ld h, a
    ld (_RadastanColRow), hl
    ret
    END ASM
END SUB


' ----------------------------------------------------------------
' sub RadastanSetFont
'
' Sets the font to be used for printing by passing the address to
' it.
'
' Parameters:
'     fontaddress: memory address of the font memory area
' ----------------------------------------------------------------
SUB FASTCALL RadastanSetFont(ByVal fontaddress as Uinteger)
    RadastanFontAddr = fontaddress
END SUB


' ----------------------------------------------------------------
' sub RadastanSetScreenAddr
'
' Sets the start of the screen for these routines
'
' Parameters:
'      scraddr: memory address of the beginning of screen area
' ----------------------------------------------------------------
SUB FASTCALL RadastanSetScreenAddr(ByVal scraddr as Uinteger)
    RadastanScrAddr = scraddr
END SUB


' ----------------------------------------------------------------
' Sub RadastanPrintChar
'
' Prints the current character (ASCII Code) at the current
' cursor position. The cursor is updated.
' ----------------------------------------------------------------
SUB FASTCALL RadastanPrintChar(ByVal char as UByte)
    ASM
    PROC
    LOCAL no_inter

    ; FASTCALL => a reg contains char
    push  ix
    ld    ix, 0
    add   ix, sp
    sub   ' '
    ld    b, a
    add   a, a
    add   a, b    ; multiplico por 3
    ld    h, 0
    ld    l, a
    add   hl, hl
    add   hl, hl  ; multiplico por 12

    ld    bc, (_RadastanFontAddr)
    add   hl, bc
    ld    a, r
    ex    af, af'
    di
    ld    sp, hl

    ld    a, (_RadastanColRow + 1)
    ld    l, a
    add   a, a
    add   a, l
    add   a, a
    ld    l, 0
    rra
    rr    l
    rra
    rr    l
    ld    h, a      ; hl = a * 64  => row * 6 * 64
    ld    a, (_RadastanColRow)  ; col
    add   a, a
    add   a, l
    ld    l, a

    ld    bc, (_RadastanScrAddr) ; Screen offset
    add   hl, bc
    ld    bc, 63

    pop   de
    ld    (hl), e   ; pinto primera fila
    inc   hl
    ld    (hl), d
    add   hl, bc

    pop   de
    ld    (hl), e   ; pinto segunda fila
    inc   hl
    ld    (hl), d
    add   hl, bc

    pop   de
    ld    (hl), e   ; pinto tercera fila
    inc   hl
    ld    (hl), d
    add   hl, bc

    pop   de
    ld    (hl), e   ; pinto cuarta fila
    inc   hl
    ld    (hl), d
    add   hl, bc

    pop   de
    ld    (hl), e   ; pinto quinta fila
    inc   hl
    ld    (hl), d
    add   hl, bc

    pop   de
    ld    (hl), e   ; pinto sexta fila
    inc   hl
    ld    (hl), d

    ld    sp, ix
    ex    af, af'
    jp    po, no_inter
    ei
no_inter:
    pop   ix

    ld    a, 31
__RADASTAN_NEXT_PRN_POS:
    ld    hl, _RadastanColRow
    inc   (hl)
    cp    (hl)
    ret   nc
    xor   a
    ld    (hl), a
    inc   hl
    inc   (hl)
    ld    a, 15
    cp    (hl)
    ret   nc
    ld    (hl), a
    ld    a, 6
    jp    _RadastanScrollUp

    ENDP
    END ASM
    DIM dummy as Uinteger
    dummy = @RadastanScrollUp
END SUB


' ----------------------------------------------------------------
' SUB RadastanPrint
'
' Prints the given string in radastan mode. Allows chr$(13) as
' newline and chr$(10) as return
' ----------------------------------------------------------------
SUB RadastanPrint(ByVal s as String)
    DIM dummy as Uinteger
    dummy = @RadastanPrintChar
    ASM
    PROC
    LOCAL loop, next_char, no_newline, no_line_return, finish
    ld l, (ix + 4)
    ld h, (ix + 5)
    ld c, (hl)
    inc hl
    ld b, (hl)
    ld a, b
    or c
    jr z, finish
    ld a, c
    ld c, b
    ld b, a
    inc c

loop:
    inc hl
    ld a, (hl)
    cp 13
    jr nz, no_newline
    xor a
    exx
    call __RADASTAN_NEXT_PRN_POS
    exx
    jp next_char

no_newline:
    cp 10
    jr nz, no_line_return
    xor a
    ld (_RadastanColRow), a
    jp next_char

no_line_return:
    exx
    call _RadastanPrintChar
    exx

next_char:
    djnz loop
    dec c
    jp nz, loop

finish:
    ENDP
    END ASM
END SUB


' ----------------------------------------------------------------
' Sub RadastanHaploFont
'
' Actually not a Sub (do not call!). This just defines the font
' in a function. Use @RadastanHaploFont
' ----------------------------------------------------------------
SUB FASTCALL RadastanHaploFont
    ASM
    incbin "haplofnt.bin"
    END ASM
END SUB


' ----------------------------------------------------------------
' sub RadastaPrintNL
'
' Prints a New Line (update cursor position to the beginning of
' the new line.
' ----------------------------------------------------------------
SUB FASTCALL RadastanPrintNL()
    ASM
    xor a
    jp __RADASTAN_NEXT_PRN_POS:
    END ASM
END SUB


' ----------------------------------------------------------------
' sub RadastanScrollUp
'
' Scrolls ups the screen the given number of lines (up to 96).
' The new entering lines are filled with color index 0
'
' Parameters:
'     lines: number of lines to scroll up
' ----------------------------------------------------------------
SUB FASTCALL RadastanScrollUp(ByVal lines As Byte)
    ASM
    ; scrolls up
    cp    97
    ret   nc
    ccf
    ld    e, 0
    rra
    rr    e
    rra
    rr    e
    ld    d, a      ; de = lines * 64
    ld    hl, 6144
    sbc   hl, de    ; hl = 6144 - lines * 64
    push  de

    ld    b, h
    ld    c, l      ; bc = 6144 - lines * 64
    ex    de, hl    ; hl = lines * 64
    ld    de, (_RadastanScrAddr)
    add   hl, de    ; hl = scr_addr + lines * 64
    ldir

    ; blank last 6 scanlines
    xor   a
    ld    (de), a
    ld    h, d
    ld    l, e
    inc   de
    pop   bc
    dec   bc
    ldir
    END ASM
END SUB


#endif
