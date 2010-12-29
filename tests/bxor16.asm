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
	ld hl, (_a)
	ld a, l
	ld (_b), a
	ld hl, (_a)
	push hl
	ld de, 1
	pop hl
	call __BXOR16
	ld a, l
	ld (_b), a
	ld hl, (_a)
	call __NEGHL
	ld a, l
	ld (_b), a
	ld hl, (_a)
	ld a, l
	ld (_b), a
	ld hl, (_a)
	push hl
	ld de, 1
	pop hl
	call __BXOR16
	ld a, l
	ld (_b), a
	ld hl, (_a)
	call __NEGHL
	ld a, l
	ld (_b), a
	ld hl, (_a)
	push hl
	ld hl, (_a)
	ex de, hl
	pop hl
	call __BXOR16
	ld a, l
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
#line 1 "neg16.asm"
	; Negates HL value (16 bit)
__ABS16:
		bit 7, h
		ret z
	
__NEGHL:
		ld a, l			; HL = -HL
		cpl
		ld l, a
		ld a, h
		cpl
		ld h, a
		inc hl
		ret
	
#line 54 "bxor16.bas"
#line 1 "bxor16.asm"
; vim:ts=4:et:
	; FASTCALL bitwise xor 16 version.
	; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: A, H)
	; Performs 16bit xor 16bit and returns the boolean
; Input: HL, DE
; Output: HL <- HL XOR DE
	
__BXOR16:
		ld a, h
		xor d
	    ld h, a
	
	    ld a, l
	    xor e
	    ld l, a
	
	    ret 
	
#line 55 "bxor16.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00, 00
_b:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
