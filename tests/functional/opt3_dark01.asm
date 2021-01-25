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
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_a:
	DEFB 00
_bPtr:
	DEFB 00, 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, 32768
	ld (_bPtr), hl
	jp __LABEL0
__LABEL3:
	ld hl, (_bPtr)
	ld a, (hl)
	cpl
	ld (_a), a
	ld (hl), a
	inc hl
	ld (_bPtr), hl
__LABEL0:
	ld hl, 32793
	ld de, (_bPtr)
	or a
	sbc hl, de
	jp nc, __LABEL3
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
	;; --- end of user code ---
	END
