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
__LABEL0:
	xor a
	ld (_sprite), a
	jp __LABEL2
__LABEL5:
	ld a, (0)
	ld (_lin), a
	ld a, (1)
	ld (_col), a
	xor a
	ld (3), a
__LABEL6:
	ld hl, _sprite
	inc (hl)
__LABEL2:
	ld a, 7
	ld hl, (_sprite - 1)
	cp h
	jp nc, __LABEL5
__LABEL4:
	jp __LABEL0
__LABEL1:
__LABEL__btiles:
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
_sprite:
	DEFB 00
_lin:
	DEFB 00
_col:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
