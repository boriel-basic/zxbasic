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
	ld a, (_VOFFS48K)
	ld hl, (_b - 1)
	sub h
	ld (_d1), a
	ld a, (_VOFFS128K)
	ld hl, (_b - 1)
	sub h
	ld (_d2), a
	ld a, (_VOFFSPEN)
	ld hl, (_b - 1)
	sub h
	ld (_d3), a
	ld a, (_d1)
	ld (0), a
	ld a, (_d2)
	ld (1), a
	ld a, (_d3)
	ld (2), a
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
_b:
	DEFB 00
_d1:
	DEFB 00
_d2:
	DEFB 00
_d3:
	DEFB 00
_f:
	DEFB 00
_VOFFS48K:
	DEFB 00
_VOFFS128K:
	DEFB 00
_VOFFSPEN:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
