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
	_a.__DATA__ EQU 16384
_a:
	DEFW __LABEL0
_a.__DATA__.__PTR__:
	DEFW 16384
__LABEL0:
	DEFW 0000h
	DEFB 02h
_b:
	DEFW __LABEL1
_b.__DATA__.__PTR__:
	DEFW _b.__DATA__
_b.__DATA__:
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
__LABEL1:
	DEFW 0000h
	DEFB 02h
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, 16
	ld b, h
	ld c, l
	ld hl, _b.__DATA__
	ld de, _a.__DATA__
	ldir
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
	;; --- end of user code ---
	END
