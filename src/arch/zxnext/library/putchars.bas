' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2008-2023
' by Paul Fisher (a.k.a. BritLion) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_PUTCHARS__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_PUTCHARS__

#pragma push(case_insensitive)
#pragma case_insensitive = True


' ----------------------------------------------------------------
' SUB putChars
'
' Fills a rectangle region of the screen width a char
'
' Parameters:
'   x - x coordinate (cell column)
'   y - y coordinate (cell row)
'   width - width (number of columns)
'   height - height (number of rows)
'   dataAddress - Chars bytes address
'
' ----------------------------------------------------------------
SUB putChars(x as uByte,y as uByte, width as uByte, height as uByte, dataAddress as uInteger)
' Copyleft Britlion. Feel free to use as you will. Please attribute me if you use this, however!

    Asm
    PROC
    LOCAL BLPutChar, BLPutCharColumnLoop, BLPutCharInColumnLoop, BLPutCharSameThird
    LOCAL BLPutCharNextThird, BLPutCharNextColumn, BLPutCharsEnd

BLPutChar:
    ld      a,(ix+5)
    ld      l,a
    ld      a,(ix+7) ; Y value
    ld      d,a
    and     24
    ld      h,a
    ld      a,d
    and     7
    rrca
    rrca
    rrca
    or      l
    ld      l,a

    push hl ; save our address
    ld e,(ix+12) ; data address
    ld d,(ix+13)
    ld b,(ix+9) ; width
    push bc ; save our column count

BLPutCharColumnLoop:
    ld b, (ix+11) ; height

BLPutCharInColumnLoop:

    push hl
    push de
    ld de, (.core.SCREEN_ADDR)
    add hl, de     ;Adds the offset to the screen att address
    pop de

    ; gets screen address in HL, and bytes address in DE. Copies the 8 bytes to the screen
    ld a,(de) ; First Row
    ld (hl),a

    inc de
    inc h
    ld a,(de)
    ld (hl),a ; second Row

    inc de
    inc h
    ld a,(de)
    ld (hl),a ; Third Row

    inc de
    inc h
    ld a,(de)
    ld (hl),a ; Fourth Row

    inc de
    inc h
    ld a,(de)
    ld (hl),a ; Fifth Row

    inc de
    inc h
    ld a,(de)
    ld (hl),a ; Sixth Row

    inc de
    inc h
    ld a,(de)
    ld (hl),a ; Seventh Row

    inc de
    inc h
    ld a,(de)
    ld (hl),a ; Eighth Row

    pop hl
    inc de ; Move to next data item.
    dec b
    jr z, BLPutCharNextColumn

    ;The following code calculates the address of the next line down below current HL address.
    push de ; save DE
    ld   a,l
    and  224
    cp   224
    jr   z,BLPutCharNextThird

BLPutCharSameThird:
    ld   de,32
    add  hl,de
    pop de ; get our data point back.
    jp BLPutCharInColumnLoop

BLPutCharNextThird:
    ld de,1824
    add hl,de
    pop de ; get our data point back.
    jp BLPutCharInColumnLoop

BLPutCharNextColumn:
    pop bc
    pop hl
    dec b
    jr z, BLPutCharsEnd

    inc l   ; Note this would normally be Increase HL - but block painting should never need to increase H, since that would wrap around.
    push hl
    push bc
    jp BLPutCharColumnLoop

BLPutCharsEnd:
    ENDP
    End Asm
END SUB


' ----------------------------------------------------------------
' SUB Paint
'
' Fills a rectangle region of the screen width a color
'
' Parameters:
'   x - x coordinate (cell column)
'   y - y coordinate (cell row)
'   width - width (number of columns)
'   height - height (number of rows)
'   attribute - byte-encoded attr
'
' ----------------------------------------------------------------
SUB paint (x as uByte,y as uByte, width as uByte, height as uByte, attribute as ubyte)
REM Copyleft Britlion. Feel free to use as you will. Please attribute me if you use this, however!

    Asm
    PROC
    LOCAL BLPaintHeightLoop, BLPaintWidthLoop, BLPaintWidthExitLoop, BLPaintHeightExitLoop

    ld      a,(ix+7)   ;ypos
    rrca
    rrca
    rrca               ; Multiply by 32
    ld      l,a        ; Pass to L
    and     3          ; Mask with 00000011
    ld      h,a        ; Put it in the High Byte
    ld      a,l        ; We get y value *32
    and     224        ; Mask with 11100000
    ld      l,a        ; Put it in L
    ld      a,(ix+5)   ; xpos
    add     a,l        ; Add it to the Low byte
    ld      l,a        ; Put it back in L, and we're done. HL=Address.
    ld      de,(.core.SCREEN_ATTR_ADDR)
    add     hl, de     ;Adds the offset to the screen att address

    push hl            ; save address
    ld a, (ix+13)      ; attribute
    ld de,32
    ld c,(ix+11)       ; height

BLPaintHeightLoop:
    ld b,(ix+9)        ; width

BLPaintWidthLoop:
    ld (hl),a          ; paint a character
    inc hl
    djnz BLPaintWidthLoop

BLPaintWidthExitLoop:
    pop hl             ; recover our left edge
    dec c
    jr z, BLPaintHeightExitLoop

    add hl,de          ; move 32 down
    push hl            ; save it again
    jp BLPaintHeightLoop

BLPaintHeightExitLoop:
    ENDP
    End Asm
END SUB


' ----------------------------------------------------------------
' SUB PaintData
'
' Fills a rectangle region of the screen width a colors from a
' stored at a memory address.
'
' Parameters:
'   x - x coordinate (cell column)
'   y - y coordinate (cell row)
'   width - width (number of columns)
'   height - height (number of rows)
'   address - address of the byte-encoded attr sequence
'
' ----------------------------------------------------------------
SUB paintData(x as uByte,y as uByte, width as uByte, height as uByte, address as uInteger)
REM Copyleft Britlion. Feel free to use as you will. Please attribute me if you use this, however!

    Asm
    PROC
    LOCAL BLPaintDataHeightLoop, BLPaintDataWidthLoop, BLPaintDataWidthExitLoop, BLPaintDataHeightExitLoop

    ld      a,(ix+7)   ;ypos
    rrca
    rrca
    rrca               ; Multiply by 32
    ld      l,a        ; Pass to L
    and     3          ; Mask with 00000011
    ld      h,a        ; Put it in the High Byte
    ld      a,l        ; We get y value *32
    and     224        ; Mask with 11100000
    ld      l,a        ; Put it in L
    ld      a,(ix+5)   ; xpos
    add     a,l        ; Add it to the Low byte
    ld      l,a        ; Put it back in L, and we're done. HL=Address.
    ld      de,(.core.SCREEN_ATTR_ADDR)
    add     hl, de     ;Adds the offset to the screen att address

    push hl            ; save address
    ld d,(ix+13)
    ld e,(ix+12)
    ld c,(ix+11)       ; height

BLPaintDataHeightLoop:
    ld b,(ix+9)        ; width

BLPaintDataWidthLoop:
    ld a,(de)
    ld (hl),a          ; paint a character
    inc hl
    inc de
    djnz BLPaintDataWidthLoop

BLPaintDataWidthExitLoop:
    pop hl             ; recover our left edge
    dec c
    jr z, BLPaintDataHeightExitLoop
    push de
    ld de,32
    add hl,de          ; move 32 down
    pop de
    push hl            ; save it again
    jp BLPaintDataHeightLoop

BLPaintDataHeightExitLoop:
    ENDP
    End Asm
END SUB


' ----------------------------------------------------------------
' SUB putCharsOverMode
'
' Fills a rectangle region of the screen width a char
'
' Parameters:
'   x - x coordinate (cell column)
'   y - y coordinate (cell row)
'   width - width (number of columns)
'   height - height (number of rows)
'   overMode- the way the characters are combined with the background.
'              matches the values of the OVER command:
'               0 - the characters are simply replaced.
'               1 - the characters are combined with an Exclusive OR (XOR).
'               2 - the characters are combined using an AND function.
'               3 - the characters are combined using an OR function.
'   dataAddress - Chars bytes address
'
' ----------------------------------------------------------------
SUB putCharsOverMode(x as uByte,y as uByte, width as uByte, height as uByte, _
                     overMode as uByte, dataAddress as uInteger)

    Asm
    PROC
    LOCAL BLPutChar, BLPutCharColumnLoop, BLPutCharInColumnLoop, BLPutCharSameThird
    LOCAL BLPutCharNextThird, BLPutCharNextColumn, BLPutCharsEnd
    LOCAL op1, op2, op3, op4, op5, op6, op7, op8, opTable, noCarry

    ld      a,(ix+13)
    and     3
    ld      hl, opTable
    add     a, l
    jp      nc, noCarry
    inc     h
noCarry:
    ld      l, a
    ld      a, (hl)
    ld      (op1), a
    ld      (op2), a
    ld      (op3), a
    ld      (op4), a
    ld      (op5), a
    ld      (op6), a
    ld      (op7), a
    ld      (op8), a
    jp      BLPutChar

opTable:
    DEFB $00      ;  00 - NOP - $00
    DEFB $AE      ;  01 - XOR (HL) - $AE
    DEFB $A6      ;  02 - AND (HL) - $A6
    DEFB $B6      ;  03 - OR (HL) - $B6

BLPutChar:
    ld      a,(ix+5)
    ld      l,a
    ld      a,(ix+7) ; Y value
    ld      d,a
    and     24
    ld      h,a
    ld      a,d
    and     7
    rrca
    rrca
    rrca
    or      l
    ld      l,a

    push hl ; save our address
    ld e,(ix+14) ; data address
    ld d,(ix+15)
    ld b,(ix+9) ; width
    push bc ; save our column count

BLPutCharColumnLoop:
    ld b, (ix+11) ; height

BLPutCharInColumnLoop:
    push hl
    push de
    ld de, (.core.SCREEN_ADDR)
    add hl, de     ;Adds the offset to the screen att address
    pop de
    ; gets screen address in HL, and bytes address in DE. Copies the 8 bytes to the screen
    ld a,(de) ; First Row
op1:
    nop
    ld (hl),a

    inc de
    inc h
    ld a,(de)
op2:
    nop
    ld (hl),a ; second Row

    inc de
    inc h
    ld a,(de)
op3:
    nop
    ld (hl),a ; Third Row

    inc de
    inc h
    ld a,(de)
op4:
    nop
    ld (hl),a ; Fourth Row

    inc de
    inc h
    ld a,(de)
op5:
    nop
    ld (hl),a ; Fifth Row

    inc de
    inc h
    ld a,(de)
op6:
    nop
    ld (hl),a ; Sixth Row

    inc de
    inc h
    ld a,(de)
op7:
    nop
    ld (hl),a ; Seventh Row

    inc de
    inc h
    ld a,(de)
op8:
    nop
    ld (hl),a ; Eighth Row

    pop hl
    inc de ; Move to next data item.
    dec b
    jr z, BLPutCharNextColumn

    ;The following code calculates the address of the next line down below current HL address.
    push de ; save DE
    ld   a,l
    and  224
    cp   224
    jr   z,BLPutCharNextThird

BLPutCharSameThird:
    ld   de,32
    add  hl,de
    pop de ; get our data point back.
    jp BLPutCharInColumnLoop

BLPutCharNextThird:
    ld de,1824
    add hl,de
    pop de ; get our data point back.
    jp BLPutCharInColumnLoop

BLPutCharNextColumn:
    pop bc
    pop hl
    dec b
    jr z, BLPutCharsEnd

    inc l   ; Note this would normally be Increase HL - but block painting should never need to increase H, since that would wrap around.
    push hl
    push bc
    jp BLPutCharColumnLoop

BLPutCharsEnd:
    ENDP
    End Asm
END SUB

#require "sysvars.asm"

#pragma pop(case_insensitive)

#endif

