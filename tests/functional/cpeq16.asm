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
	ld de, (_b)
	ld hl, (_a)
	or a
	sbc hl, de
	jp nz, __LABEL1
	ld de, (_a)
	ld hl, (_a)
	add hl, de
	ld (_b), hl
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
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
#line 1 "eq16.asm"
	
__EQ16:	; Test if 16bit values HL == DE
		; Returns result in A: 0 = False, FF = True
			xor a	; Reset carry flag
			sbc hl, de
			ret nz
			inc a
			ret
	
#line 28 "cpeq16.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00, 00
_b:
	DEFB 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
