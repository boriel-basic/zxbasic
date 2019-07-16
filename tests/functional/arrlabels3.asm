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
	ld hl, (_a.__DATA__ + 0)
	push hl
	ld a, 5
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
_f:
	push ix
	ld ix, 0
	add ix, sp
	xor a
_f__leave:
	ld sp, ix
	pop ix
	ret
ZXBASIC_USER_DATA:
_a:
	DEFW __LABEL0
_a.__DATA__.__PTR__:
	DEFW _a.__DATA__
_a.__DATA__:
	DEFW _a.__DATA__
	DEFW _a.__DATA__
	DEFW (_a.__DATA__) + (_f)
__LABEL0:
	DEFW 0000h
	DEFB 02h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
