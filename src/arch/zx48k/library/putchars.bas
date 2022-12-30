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
    add     a,64 ; 256 byte "page" for screen - 256*64=16384. Change this if you are working with a screen address elsewhere, such as a buffer.
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

    inc de ; Move to next data item.

    dec b
    jr z, BLPutCharNextColumn
    ;The following code calculates the address of the next line down below current HL address.
    push de ; save DE
    ld   a,l
    and  224
    cp   224
    jp   z,BLPutCharNextThird

BLPutCharSameThird:
    ld   de,-1760
    add  hl,de
    pop de ; get our data point back.
    jp BLPutCharInColumnLoop

BLPutCharNextThird:
    ld de,32
    add hl,de
    pop de ; get our data point back.
    jp BLPutCharInColumnLoop

BLPutCharNextColumn:
    pop bc
    pop hl
    dec b
    jp z, BLPutCharsEnd

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
    add     a,88       ; 88 * 256 = 22528 - start of attributes. Change this if you are working with a buffer or somesuch.
    ld      h,a        ; Put it in the High Byte
    ld      a,l        ; We get y value *32
    and     224        ; Mask with 11100000
    ld      l,a        ; Put it in L
    ld      a,(ix+5)   ; xpos
    add     a,l        ; Add it to the Low byte
    ld      l,a        ; Put it back in L, and we're done. HL=Address.

    push hl            ; save address
    ld a, (ix+13)      ; attribute
    ld de,32
    ld c,(ix+11)       ; height

BLPaintHeightLoop:
    ld b,(ix+9)        ; width

BLPaintWidthLoop:
    ld (hl),a          ; paint a character
    inc l              ; Move to the right (Note that we only would have to inc H if we are crossing from the right edge to the left, and we shouldn't be needing to do that)
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
    add     a,88       ; 88 * 256 = 22528 - start of attributes. Change this if you are working with a buffer or somesuch.
    ld      h,a        ; Put it in the High Byte
    ld      a,l        ; We get y value *32
    and     224        ; Mask with 11100000
    ld      l,a        ; Put it in L
    ld      a,(ix+5)   ; xpos
    add     a,l        ; Add it to the Low byte
    ld      l,a        ; Put it back in L, and we're done. HL=Address.

    push hl            ; save address
    ld d,(ix+13)
    ld e,(ix+12)
    ld c,(ix+11)       ; height

BLPaintDataHeightLoop:
    ld b,(ix+9)        ; width

BLPaintDataWidthLoop:
    ld a,(de)
    ld (hl),a          ; paint a character
    inc l              ; Move to the right (Note that we only would have to inc H if we are crossing from the right edge to the left, and we shouldn't be needing to do that)
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

#pragma pop(case_insensitive)

#endif

