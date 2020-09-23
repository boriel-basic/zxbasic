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
	jp __MAIN_PROGRAM__
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_a:
	DEFB 00
_b:
	DEFB 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld a, (_a)
	xor a
	ld (_b), a
	ld a, (_a)
	and 1
	ld (_b), a
	ld a, (_a)
	ld l, a
	ld h, 0
	ld a, l
	ld (_b), a
	ld a, (_a)
	xor a
	ld (_b), a
	ld hl, (_a - 1)
	ld a, 1
	and h
	ld (_b), a
	ld a, (_a)
	ld l, a
	ld h, 0
	ld a, l
	ld (_b), a
	ld hl, (_a - 1)
	ld a, (_a)
	and h
	ld (_b), a
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
	END
