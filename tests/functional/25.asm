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
	ld de, 5
	ld hl, 6553
	ld (_a), hl
	ld (_a + 2), de
	ld hl, (_a)
	ld de, (_a + 2)
	call __NOT32
	ld (_c), a
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
#line 1 "not32.asm"
	
	; -------------------------------------------------------------
	; 32 bit logical NOT
	; -------------------------------------------------------------
	
__NOT32:	; A = ¬A 
		ld a, d
		or e
		or h
		or l
		sub 1	; Gives CARRY only if 0
		sbc a, a; Gives 0 if not carry, FF otherwise
		ret
	
	
#line 26 "25.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00, 00, 00, 00
_c:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
