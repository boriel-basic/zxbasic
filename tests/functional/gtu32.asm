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
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_level:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
_le:
	DEFB 01h
	DEFB 00h
	DEFB 00h
	DEFB 00h
_l:
	DEFB 00, 00, 00, 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, (_level)
	ld de, (_level + 2)
	push de
	push hl
	ld de, (_le + 2)
	ld hl, (_le)
	call __SWAP32
	pop bc
	or a
	sbc hl, bc
	ex de, hl
	pop de
	sbc hl, de
	sbc a, a
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le + 2)
	push hl
	ld hl, (_le)
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	pop bc
	or a
	sbc hl, bc
	ex de, hl
	pop de
	sbc hl, de
	sbc a, a
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	pop bc
	or a
	sbc hl, bc
	ex de, hl
	pop de
	sbc hl, de
	sbc a, a
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	pop bc
	or a
	sbc hl, bc
	ex de, hl
	pop de
	sbc hl, de
	sbc a, a
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_level)
	ld de, (_level + 2)
	ld bc, 0
	push bc
	ld bc, 1
	or a
	sbc hl, bc
	ex de, hl
	pop de
	sbc hl, de
	sbc a, a
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
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
#line 1 "swap32.asm"
	; Exchanges current DE HL with the
	; ones in the stack
__SWAP32:
		pop bc ; Return address
	    ex (sp), hl
	    inc sp
	    inc sp
	    ex de, hl
	    ex (sp), hl
	    ex de, hl
	    dec sp
	    dec sp
	    push bc
		ret
#line 112 "gtu32.bas"
	END
