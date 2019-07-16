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
	ld a, (_b.__DATA__ + 7)
	ld (_a), a
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
_a:
	DEFB 00
_b:
	DEFW __LABEL0
_b.__DATA__.__PTR__:
	DEFW _b.__DATA__
_b.__DATA__:
	DEFB 0A0h
	DEFB 0A1h
	DEFB 0A2h
	DEFB 0A3h
	DEFB 0B0h
	DEFB 0B1h
	DEFB 0B2h
	DEFB 0B3h
	DEFB 0C0h
	DEFB 0C1h
	DEFB 0C2h
	DEFB 0C3h
__LABEL0:
	DEFW 0001h
	DEFW 0004h
	DEFB 01h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
