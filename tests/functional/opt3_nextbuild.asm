	org 32768
core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (core.__CALL_BACK__), hl
	ei
	jp core.__MAIN_PROGRAM__
core.__CALL_BACK__:
	DEFW 0
core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
core.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_END - core.ZXBASIC_USER_DATA
	core..__LABEL__.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_LEN
	core..__LABEL__.ZXBASIC_USER_DATA EQU core.ZXBASIC_USER_DATA
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
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
core.__END_PROGRAM:
	di
	ld hl, (core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
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
	;; --- end of user code ---
	END
