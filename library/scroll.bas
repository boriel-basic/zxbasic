' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com"
'
' Use this file as a template to develop your own library file
' ----------------------------------------------------------------

#ifndef __LIBRARY_SCROLL__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_SCROLL__

#pragma push(case_insensitive)
#pragma case_insensitive = True

' ----------------------------------------------------------------
' sub ScrollRight 
' pyxel by pyxel right scroll
' scrolls 1 pixel right the window defined by (x1, y1, x2, y2)
' ----------------------------------------------------------------

sub fastcall ScrollRight(x1 as uByte, y1 as uByte, x2 as Ubyte, y2 as Ubyte)
	asm

	PROC
	LOCAL LOOP1
	LOCAL LOOP2

    ; a = x1
    pop hl ; RET address
    pop bc ; b = y1
    pop de ; d = x2
    ex (sp), hl ; h = y2, (sp) = RET address. Stack ok now

    ld c, a  ; BC = y1x1
    ld a, d
    sub c
    ret c   ; x1 > x2

    srl a
    srl a
    srl a
    inc a
    ld e, a ; e = (x2 - x1) / 8 + 1

    ld a, h
    sub b
    ret c   ; y1 > y2

    inc a
    ld d, a ; d = y2 - y1 + 1

    ld b, h ; BC = y2x1
    ld a, 191
    LOCAL __PIXEL_ADDR
__PIXEL_ADDR EQU 22ACh
    call __PIXEL_ADDR
 
LOOP1:
    push hl
	ld b, e  ; C cols
	or a	 ; clear carry flag
LOOP2:
	rr (hl)
	inc hl
	djnz LOOP2
    pop hl

	dec d
    ret z	
    call SP.PixelDown
    jp LOOP1
	ENDP
	
	end asm
end sub


' ----------------------------------------------------------------
' sub ScrolLeft
' pyxel by pyxel left scroll
' scrolls 1 pixel left the window defined by (x1, y1, x2, y2)
' ----------------------------------------------------------------

sub fastcall ScrollLeft(x1 as uByte, y1 as uByte, x2 as Ubyte, y2 as Ubyte)
	asm

	PROC
	LOCAL LOOP1
	LOCAL LOOP2

    ; a = x1
    pop hl ; RET address
    pop bc ; b = y1
    pop de ; d = x2
    ex (sp), hl ; h = y2, (sp) = RET address. Stack ok now

    ld c, a  ; BC = y1x1
    ld a, d
    sub c
    ret c   ; x1 > x2

    srl a
    srl a
    srl a
    inc a
    ld e, a ; e = (x2 - x1) / 8 + 1

    ld a, h
    sub b
    ret c   ; y1 > y2

    ld c, d
    inc a
    ld d, a ; d = y2 - y1 + 1

    ld b, h ; BC = y2x1
    ld a, 191
    LOCAL __PIXEL_ADDR
__PIXEL_ADDR EQU 22ACh
    call __PIXEL_ADDR
 
LOOP1:
    push hl
	ld b, e  ; C cols
	or a	 ; clear carry flag
LOOP2:
	rl (hl)
	dec hl
	djnz LOOP2
    pop hl

	dec d
    ret z	
    call SP.PixelDown
    jp LOOP1
	ENDP
	
	end asm
end sub


' ----------------------------------------------------------------
' sub ScrollUp 
' pyxel by pyxel left UP
' ----------------------------------------------------------------

sub fastcall ScrollUp
	asm
	
	PROC
	LOCAL LOOP1
	LOCAL LOOP2

	ld hl, (SCREEN_ADDR)
	ld bc, 6143
	add hl, bc

	ld c, 192 ; 192 lines; 

LOOP1:

	ld b, 32 ; 32 lines
	or a	 ; clear carry flag
LOOP2:
	rl (hl)
	dec hl
	djnz LOOP2

	dec c
	jp nz, LOOP1 ; JP is faster than JR
	ENDP

	end asm
end sub



#pragma pop(case_insensitive)

REM the following is required, because it defines screen start addr
#require "cls.asm"
#require "SP/PixelDown.asm"


#endif

