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
_c:
	DEFB 00
_aux:
	DEFW __LABEL0
_aux.__DATA__.__PTR__:
	DEFW _aux.__DATA__
_aux.__DATA__:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
__LABEL0:
	DEFW 0000h
	DEFB 01h
_aux1:
	DEFW __LABEL1
_aux1.__DATA__.__PTR__:
	DEFW _aux1.__DATA__
_aux1.__DATA__:
	DEFB 00h
	DEFB 00h
	DEFB 00h
__LABEL1:
	DEFW 0000h
	DEFB 01h
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld a, (_aux.__DATA__ + 4)
	ld (_c), a
	ld a, (_aux1.__DATA__ + -1)
	ld (_c), a
	ld (0), a
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
