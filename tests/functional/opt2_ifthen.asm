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
	ld hl, (_toloX)
	ld a, (hl)
	cp 3
	sbc a, a
	ld d, a
	ld hl, (_toloX)
	ld a, 107
	cp (hl)
	sbc a, a
	or d
	ld d, a
	ld hl, (_toloY)
	ld a, (hl)
	cp 2
	sbc a, a
	or d
	ld d, a
	ld hl, (_toloY)
	ld a, 86
	cp (hl)
	sbc a, a
	or d
	push af
	ld hl, (_toloX)
	ld a, (hl)
	ld hl, (_doorX - 1)
	sub h
	sub 1
	sbc a, a
	push af
	ld hl, (_toloY)
	ld a, (hl)
	ld hl, (_doorY - 1)
	sub h
	sub 1
	sbc a, a
	ld h, a
	pop af
	or a
	jr z, __LABEL2
	ld a, h
__LABEL2:
	pop de
	or d
	jp z, __LABEL1
	xor a
	ld hl, (_toloX)
	ld (hl), a
__LABEL1:
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
_toloX:
	DEFB 00, 00
_toloY:
	DEFB 00, 00
_doorX:
	DEFB 00
_doorY:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
