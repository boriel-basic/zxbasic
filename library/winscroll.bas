' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Use this file as a template to develop your own library file
' ----------------------------------------------------------------

#ifndef __LIBRARY_WINSCROLL__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_WINSCROLL__

#pragma push(case_insensitive)
#pragma case_insensitive = True

' ---------------------------------------------------------------------
' sub WinScrollRight
' scrolls the window defined by (row, col, width, height) 1 cell right
' ---------------------------------------------------------------------
sub fastcall WinScrollRight(row as uByte, col as uByte, width as Ubyte, height as Ubyte)
	asm
    LOCAL BucleChars
	LOCAL BucleScans
	LOCAL BucleAttrs

    PROC
    ld b, a
    pop hl
    pop de
    ld c, d
    pop de
    ex (sp), hl
    ld e, h
    ld a, e
    or a
    ret z
    or d
    ret z
    push bc
    ld a,b
    and 18h
    or 40h
    ld h,a
    ld a,b
    and 07h
    add a,a
    add a,a
    add a,a
    add a,a
    add a,a
    add a,c
    add a,d
    dec a
    ld l,a   ;HL=top-left window address in bitmap coord
    ld b,e

BucleChars:
    push bc
    ld b,8

BucleScans:
    push bc
    push de
    push hl
    ld c,d
    dec c
    ld b,0
    ld d,h
    ld e,l
    dec l
    lddr
    ; clean up latest
    xor a
    ld (de),a
    pop hl
    pop de
    inc h
    pop bc
    djnz BucleScans
    dec h
    call SP.PixelDown
    pop bc
    djnz BucleChars

    pop bc
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,l
    add a,c
    add a,d
    dec a
    ld l,a
    ld a,h
    add a,58h
    ld h,a    ;HL=top-left window address in attr coord
    ld b,e

BucleAttrs:
    push bc
    push de
    push hl
    ld c,d
    dec c
    ld b,0
    ld d,h
    ld e,l
    dec l
    lddr
    pop hl
    ld de,32
    add hl,de
    pop de
    pop bc
    djnz BucleAttrs

    ENDP
	end asm
end sub


' ---------------------------------------------------------------------
' sub WinScrollLeft
' scrolls the window defined by (row, col, width, height) 1 cell left
' ---------------------------------------------------------------------
sub fastcall WinScrollLeft(row as uByte, col as uByte, width as Ubyte, height as Ubyte)
	asm
	PROC
	LOCAL BucleChars
	LOCAL BucleScans
	LOCAL BucleAttrs

    ld b, a
    pop hl
    pop de
    ld c, d
    pop de
    ex (sp), hl
    ld e, h
    ld a, e
    or a
    ret z
    or d
    ret z
    push bc
    ld a,b
    and 18h
    or 40h
    ld h,a
    ld a,b
    and 07h
    add a,a
    add a,a
    add a,a
    add a,a
    add a,a
    add a,c
    ld l,a   ;HL=top-left window address in bitmap coord
    ld b,e

BucleChars:
    push bc
    ld b,8

BucleScans:
    push bc
    push de
    push hl
    ld c,d
    dec c
    ld b,0
    ld d,h
    ld e,l
    inc e
    ex de,hl
    ldir
    ; clean up latest
    xor a
    ld (de),a
    pop hl
    pop de
    inc h
    pop bc
    djnz BucleScans
    dec h
    call SP.PixelDown
    pop bc
    djnz BucleChars

    pop bc
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,l
    add a,c
    ld l,a
    ld a,h
    add a,58h
    ld h,a    ;HL=top-left address in attr coords
    ld b,e

BucleAttrs:
    push bc
    push de
    push hl
    ld c,d
    dec c
    ld b,0
    ld d,h
    ld e,l
    inc e
    ex de,hl
    ldir
    pop hl
    ld de,32
    add hl,de
    pop de
    pop bc
    djnz BucleAttrs
    ENDP
	end asm
end sub


' ---------------------------------------------------------------------
' sub WinScrollUp
' scrolls the window defined by (row, col, width, height) 1 cell up
' ---------------------------------------------------------------------
sub fastcall WinScrollUp(row as uByte, col as uByte, width as Ubyte, height as Ubyte)
	asm
	PROC
	LOCAL BucleScans, BucleAttrs, ScrollAttrs
	LOCAL CleanLast, CleanLastLoop, EndCleanScan

    ld b, a
    pop hl
    pop de
    ld c, d
    pop de
    ex (sp), hl
    ld e, h
    ld a, e
    or a
    ret z
    or d
    ret z

    push bc
    push de

    ld a,b
    and 18h
    or 40h
    ld h,a
    ld a,b
    and 07h
    add a,a
    add a,a
    add a,a
    add a,a
    add a,a
    add a,c
    ld l,a   ;HL=top-left window address in bitmap coord
    ld a,e
    ld c, d  ; c = width
    ld d, h
    ld e, l
    dec a
    jr z, CleanLast
    add a,a
    add a,a
    add a,a
    ld b, a  ; b = 8 * (height - 1)

    inc h
    inc h
    inc h
    inc h
    inc h
    inc h
    inc h
    call SP.PixelDown

BucleScans:
    push bc
    push de
    push hl
    ld b, 0
    ldir
    pop hl
    pop de
    pop bc
    call SP.PixelDown
    ex de, hl
    call SP.PixelDown
    ex de, hl
    djnz BucleScans

CleanLast:
    ex de,hl
    pop de
    ld b, 8
    ld c, d
    push de

CleanLastLoop:
    push bc
    push hl
    ld (hl), 0
    dec c
    jr z, EndCleanScan
    ld d, h
    ld e, l
    inc de
    ld b, 0
    ldir

EndCleanScan:
    pop hl
    pop bc
    inc h
    djnz CleanLastLoop

ScrollAttrs:
    pop de
    pop bc
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,l
    add a,c
    ld l,a
    ld a,h
    add a,58h
    ld h,a    ;HL=top-left address in attr coords
    ld b,e
    dec b
    ret z

BucleAttrs:
    push bc
    push de
    push hl
    ld b,0
    ld c,d
    ex de,hl
    ld hl,32
    add hl,de
    ldir
    pop hl
    ld de,32
    add hl,de
    pop de
    pop bc
    djnz BucleAttrs
    ENDP
	end asm

end sub


' ---------------------------------------------------------------------
' sub WinScrollDown
' scrolls the window defined by (row, col, width, height) 1 cell down
' ---------------------------------------------------------------------
sub fastcall WinScrollDown(row as uByte, col as uByte, width as Ubyte, height as Ubyte)
	asm
	PROC
	LOCAL BucleScans, BucleAttrs, ScrollAttrs
	LOCAL CleanLast, CleanLastLoop, EndCleanScan

    ld b, a
    pop hl
    pop de
    ld c, d
    pop de
    ex (sp), hl
    ld e, h
    ld a, e
    or a
    ret z
    or d
    ret z

    ld a, b
    add a, e
    dec a
    ld b, a  ; b = row + height - 1 = top most row

    push bc
    push de

    ld a,b
    and 18h
    or 40h
    ld h,a
    ld a,b
    and 07h
    add a,a
    add a,a
    add a,a
    add a,a
    add a,a
    add a,c
    ld l,a   ;HL=bottom-left window address in bitmap coord
    ld a,e
    ld c, d  ; c = width
    ld d, h
    ld e, l
    dec a
    jr z, CleanLast
    add a,a
    add a,a
    add a,a
    ld b, a  ; b = 8 * (height - 1)

    inc d
    inc d
    inc d
    inc d
    inc d
    inc d
    inc d
    call SP.PixelUp

BucleScans:
    push bc
    push de
    push hl
    ld b, 0
    ldir
    pop hl
    pop de
    pop bc
    call SP.PixelUp
    ex de, hl
    call SP.PixelUp
    ex de, hl
    djnz BucleScans

CleanLast:
    ex de,hl
    pop de
    ld b, 8
    ld c, d
    push de

CleanLastLoop:
    push bc
    push hl
    ld (hl), 0
    dec c
    jr z, EndCleanScan
    ld d, h
    ld e, l
    inc de
    ld b, 0
    ldir

EndCleanScan:
    pop hl
    pop bc
    dec h
    djnz CleanLastLoop

ScrollAttrs:
    pop de
    pop bc
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,l
    add a,c
    ld l,a
    ld a,h
    add a,58h
    ld h,a    ;HL=top-left address in attr coords
    ld b,e
    dec b
    ret z

BucleAttrs:
    push bc
    push de
    push hl
    ld b,0
    ld c,d
    ex de,hl
    ld hl,-32
    add hl,de
    ldir
    pop hl
    ld de,-32
    add hl,de
    pop de
    pop bc
    djnz BucleAttrs
    ENDP
	end asm

end sub

#pragma pop(case_insensitive)

REM the following is required, because it defines screen start addr
#require "cls.asm"
#require "SP/PixelDown.asm"
#require "SP/PixelUp.asm"


#endif

