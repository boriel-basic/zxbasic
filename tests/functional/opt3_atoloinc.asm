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
	ld a, 1
	ld (_level), a
	ld (_key), a
	ld (_doorstate), a
	xor a
	ld (_doorid), a
	ld (_nfires), a
	ld (_key), a
	ld a, (_level)
	ld (_key), a
	ld a, (_doorid)
	ld (_doorstate), a
	ld hl, _nfires
	inc (hl)
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
_level:
	DEFB 00
_key:
	DEFB 00
_doorstate:
	DEFB 00
_doorid:
	DEFB 00
_nfires:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
