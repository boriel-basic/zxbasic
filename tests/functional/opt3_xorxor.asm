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
_push:
	DEFB 00
_suck:
	DEFB 00
_paso:
	DEFB 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
__LABEL__looproom:
	xor a
	ld (_push), a
	ld (_suck), a
	ld a, 4
	ld (_paso), a
	jp __LABEL__looproom
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
#line 15
	;; --- end of user code ---
#line 16
	END
