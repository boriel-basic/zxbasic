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
	ld hl, (_c)
	ld (_a.__DATA__ + 28), hl
	ld hl, 0
	ld b, h
	ld c, l
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
ZXBASIC_USER_DATA:
_c:
	DEFB 00, 00
	_a.__DATA__ EQU 30000
_a:
	DEFW __LABEL0
_a.__DATA__.__PTR__:
	DEFW 30000
__LABEL0:
	DEFW 0001h
	DEFW 0006h
	DEFB 02h
; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
