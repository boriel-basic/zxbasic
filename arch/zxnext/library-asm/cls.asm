; JUMPS directly to spectrum CLS
; This routine does not clear lower screen

;CLS	EQU	0DAFh

; Our faster implementation

#include once <sposn.asm>

CLS:
	PROC

	LOCAL COORDS
	LOCAL __CLS_SCR
	LOCAL ATTR_P
	LOCAL SCREEN

	ld hl, 0
	ld (COORDS), hl
    ld hl, 1821h
	ld (S_POSN), hl
__CLS_SCR:
	ld hl, SCREEN
	ld (hl), 0
	ld d, h
	ld e, l
	inc de
	ld bc, 6144
	ldir

	; Now clear attributes

	ld a, (ATTR_P)
	ld (hl), a
	ld bc, 767
	ldir
	ret

COORDS	EQU	23677
SCREEN	EQU 16384 ; Default start of the screen (can be changed)
ATTR_P	EQU 23693
;you can poke (SCREEN_SCRADDR) to change CLS, DRAW & PRINTing address

SCREEN_ADDR EQU (__CLS_SCR + 1) ; Address used by print and other screen routines
							    ; to get the start of the screen
	ENDP

