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
	ld hl, _aglobal.__DATA__
	ld de, 4
	add hl, de
	push hl
	ld a, 99
	pop hl
	ld (hl), a
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
ZXBASIC_USER_DATA:
_aglobal:
	DEFW __LABEL0
_aglobal.__DATA__.__PTR__:
	DEFW _aglobal.__DATA__
_aglobal.__DATA__:
	DEFB 00h
	DEFB 01h
	DEFB 02h
	DEFB 03h
	DEFB 04h
	DEFB 05h
	DEFB 06h
	DEFB 07h
	DEFB 08h
__LABEL0:
	DEFW 0001h
	DEFW 0003h
	DEFB 01h
; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
