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
	xor a
	ld (_b), a
	ld de, 0
	ld hl, 1
	ld bc, (_a + 2)
	push bc
	ld bc, (_a)
	push bc
	call __AND32
	ld (_b), a
	xor a
	ld (_b), a
	ld de, 0
	ld hl, 1
	ld bc, (_a + 2)
	push bc
	ld bc, (_a)
	push bc
	call __AND32
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, (_a + 2)
	push bc
	ld bc, (_a)
	push bc
	call __AND32
	ld (_b), a
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
#line 1 "and32.asm"
	; FASTCALL boolean and 32 version.
	; Performs 32bit and 32bit and returns the boolean
	; result in Accumulator (0 False, not 0 True)
	; First operand in DE,HL 2nd operand into the stack
	
__AND32:
		ld a, l
		or h
		or e
		or d
		sub 1	
		sbc a
	
		ld c, a
	
		pop hl
	
		pop de
		ld a, d
		or e
		pop de
		or d
		or e
		sub 1
		sbc a
	
		or c
		cpl
		jp (hl)
	
	
#line 46 "and32.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00, 00, 00, 00
_b:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
