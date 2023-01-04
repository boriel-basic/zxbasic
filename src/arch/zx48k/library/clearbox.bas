' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2008-2023
' by Paul Fisher (a.k.a. BritLion) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_CLEARBOX__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_CLEARBOX__

#pragma push(case_insensitive)
#pragma case_insensitive = True


' ----------------------------------------------------------------
' SUB clearBox
'
' Blanks the pixels for a box, measured in Character Squares
' from print positions X,Y to X + Width, Y + height
'
' Parameters:
'   x - x coordinate (cell column)
'   y - y coordinate (cell row)
'   width - width (number of columns)
'   height - height (number of rows)
'
' ----------------------------------------------------------------
SUB clearBox(x as uByte, y as uByte, width as uByte, height as uByte)
' THE ERROR CHECKING IS NONEXISTENT.
' Please make sure you send sensible data -
' 0 < x < 32, 0 < y < 23, x + width < 32 and y + height < 23
' Britlion 2012.

ASM
    PROC
    LOCAL clearbox_outer_loop, clearbox_mid_loop
    LOCAL clearbox_inner_loop, clearbox_row_skip

    ld b,(IX+5)     ;' get x value
    ld c,(IX+7)     ;' get y value

    ld a, c         ;' Set HL to screen offset byte for this character.
    and 24
    ld h, a
    ld a, c
    and 7
    rra
    rra
    rra
    rra
    add a, b
    ld l, a

    ld b, (IX+11)   ;' get height
    ld c,(IX+9)     ;' get width

clearbox_outer_loop:
    xor a
    push bc       ;' save height.
    push hl       ;' save screen address.

    ld de, (.core.SCREEN_ADDR)
    add hl, de    ; 'Adds offset to the screen address pointer
    ld d, 8       ;' 8 rows to a character.
clearbox_mid_loop:
    push hl       ;' save screen address
    ld b,c        ;' get width.

clearbox_inner_loop:
    ld (hl), a    ;' write out a zero to the screen.

    inc hl        ;' go right.
    djnz clearbox_inner_loop    ;' repeat.

    pop hl        ;' recover screen address
    inc h         ;' down a row (+256)

    dec d
    jp nz, clearbox_mid_loop  ;' repeat for this row.

    pop hl        ;' get back address at start of line
    pop bc        ;' get back char count.

    ld a, 32      ;' Go down to next character row.
    add a, l
    ld l, a
    jr nc, clearbox_row_skip

    ld a, 8
    add a, h
    ld h, a

clearbox_row_skip:
    djnz clearbox_outer_loop

    ENDP
END ASM
END SUB



#require "sysvars.asm"

#pragma pop(case_insensitive)

#endif

