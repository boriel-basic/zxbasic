' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
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
' ----------------------------------------------------------------

sub fastcall ScrollRight
	asm

	PROC
	LOCAL LOOP1
	LOCAL LOOP2

	ld hl, (SCREEN_ADDR)
	ld c, 192 ; 192 lines

LOOP1:

	ld b, 32 ; 32 lines
	or a	 ; clear carry flag
LOOP2:
	rr (hl)
	inc hl
	djnz LOOP2

	dec c
	jp nz, LOOP1 ; JP is faster than JR
	ENDP
	
	end asm
end sub


' ----------------------------------------------------------------
' sub ScrollLeft 
' pyxel by pyxel left scroll
' ----------------------------------------------------------------

sub fastcall ScrollLeft
	asm
	
	PROC
	LOCAL LOOP1
	LOCAL LOOP2

	ld hl, (SCREEN_ADDR)
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


' ----------------------------------------------------------------
' sub ScrollUp 
' pyxel by pyxel left UP
' ----------------------------------------------------------------

sub fastcall ScrollLeft
	asm
	
	PROC
	LOCAL LOOP1
	LOCAL LOOP2

	ld hl, (SCREEN_ADDR)
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


#endif

