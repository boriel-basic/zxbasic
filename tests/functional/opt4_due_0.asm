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
_k:
	DEFB 05h
_n:
	DEFB 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld a, (_k)
	xor 31
	ld (_k), a
	ld a, (_n)
	add a, a
	add a, a
	add a, a
	add a, a
	add a, a
	ld hl, (_k - 1)
	or h
	ld (_k), a
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
	END
