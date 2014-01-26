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
	ld a, (_a)
	xor a
	ld (_b), a
	ld h, 1
	ld a, (_a)
	and h
	ld (_b), a
	ld a, (_a)
	ld l, a
	ld h, 0
	ld a, l
	ld (_b), a
	ld a, (_a)
	xor a
	ld (_b), a
	ld hl, (_a - 1)
	ld a, 1
	and h
	ld (_b), a
	ld a, (_a)
	ld l, a
	ld h, 0
	ld a, l
	ld (_b), a
	ld hl, (_a - 1)
	ld a, (_a)
	and h
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
#line 1 "and8.asm"
	; FASTCALL boolean and 8 version.
	; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: A, H)
	; Performs 8bit and 8bit and returns the boolean
	
__AND8:
		or a
		ret z
		ld a, h
		ret 
	
#line 46 "band8.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00
_b:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
