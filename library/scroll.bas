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
' pixel by pixel right scroll
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
' pixel by pixel left scroll
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
' sub ScrolUp
' pixel by pixel up scroll
' scrolls 1 pixel up the window defined by (x1, y1, x2, y2)
' ----------------------------------------------------------------
sub fastcall ScrollUp(x1 as uByte, y1 as uByte, x2 as Ubyte, y2 as Ubyte)
	asm

	PROC
	LOCAL LOOP1

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
    ex af, af'  ; save it for later

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
 
    ld a, d     ; Num. of scan lines
    ld b, 0
    exx
    ld b, a     ; Scan lines counter
    ex af, af'  ; Recovers cols
    ld c, a
LOOP1:
    exx
    ld d, h
    ld e, l
	ld c, a  ; C cols
    call SP.PixelDown
    push hl
    ldir
    pop hl
    exx
    ld a, c  ; Recovers C Cols
    djnz LOOP1

    ; Clears bottom line
    exx
    ld (hl), 0
    ld d, h
    ld e, l
    inc de
    ld c, a
    dec c
    ret z
    ldir
	ENDP
	
	end asm
end sub


' ----------------------------------------------------------------
' sub ScrolDown
' pixel by pixel down scroll
' scrolls 1 pixel down the window defined by (x1, y1, x2, y2)
' ----------------------------------------------------------------
sub fastcall ScrollDown(x1 as uByte, y1 as uByte, x2 as Ubyte, y2 as Ubyte)
	asm

	PROC
	LOCAL LOOP1

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
    ex af, af'  ; save it for later

    ld a, h
    sub b
    ret c   ; y1 > y2

    inc a
    ld d, a ; d = y2 - y1 + 1

    ld a, 191
    LOCAL __PIXEL_ADDR
__PIXEL_ADDR EQU 22ACh
    call __PIXEL_ADDR
 
    ld a, d     ; Num. of scan lines
    ld b, 0
    exx
    ld b, a     ; Scan lines counter
    ex af, af'  ; Recovers cols
    ld c, a
LOOP1:
    exx
    ld d, h
    ld e, l
	ld c, a  ; C cols
    call SP.PixelUp
    push hl
    ldir
    pop hl
    exx
    ld a, c  ; Recovers C Cols
    djnz LOOP1

    ; Clears top line
    exx
    ld (hl), 0
    ld d, h
    ld e, l
    inc de
    ld c, a
    dec c
    ret z
    ldir

	ENDP
	
	end asm
end sub

#pragma pop(case_insensitive)

REM the following is required, because it defines screen start addr
#require "cls.asm"
#require "SP/PixelDown.asm"
#require "SP/PixelUp.asm"


#endif

