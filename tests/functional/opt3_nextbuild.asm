	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	ld hl, 2
	push hl
	ld a, 16
	push af
	xor a
	push af
	push af
	push hl
	push af
	ld hl, 49152
	push hl
	call _TileMap
	xor a
	push af
	push af
	push af
	push af
	ld a, 100
	push af
	ld hl, 100
	push hl
	call _UpdateSprite
	ld bc, 0
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
__CALL_BACK__:
	DEFW 0
_UpdateSprite:
	push ix
	ld ix, 0
	add ix, sp
_UpdateSprite__leave:
	exx
	ld hl, 12
__EXIT_FUNCTION:
	ld sp, ix
	pop ix
	pop de
	add hl, sp
	ld sp, hl
	push de
	exx
	ret
_TileMap:
	push ix
	ld ix, 0
	add ix, sp
_TileMap__leave:
	exx
	ld hl, 14
	jp __EXIT_FUNCTION
ZXBASIC_USER_DATA:
; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
