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
	ld hl, (_x)
	ld de, (_x + 2)
	ld bc, (_dx)
	add hl, bc
	ex de, hl
	ld bc, (_dx + 2)
	adc hl, bc
	ex de, hl
	ld (_x), hl
	ld (_x + 2), de
	ex de, hl
	xor a
	ld (hl), a
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
ZXBASIC_USER_DATA:
_x:
	DEFB 00, 00, 00, 00
_dx:
	DEFB 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
