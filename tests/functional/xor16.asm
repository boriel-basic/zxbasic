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
	ld a, h
	or l
	ld (_b), a
	ld hl, (_a)
	ld a, h
	or l
	sub 1
	sbc a, a
	ld (_b), a
	ld hl, (_a)
	ld a, h
	or l
	ld (_b), a
	ld hl, (_a)
	ld a, h
	or l
	sub 1
	sbc a, a
	ld (_b), a
	ld de, (_a)
	ld hl, (_a)
	call __XOR16
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
#line 1 "xor16.asm"
	
	
	; XOR16 implemented in XOR8.ASM file
#line 1 "xor8.asm"
	
; vim:ts=4:et:
	; FASTCALL boolean xor 8 version.
	; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: A, H)
	; Performs 8bit xor 8bit and returns the boolean
	
__XOR16:
		ld a, h
		or l
	    ld h, a
	
		ld a, d
		or e
	
__XOR8:
	    sub 1
	    sbc a, a
	    ld l, a  ; l = 00h or FFh
	
	    ld a, h
	    sub 1
	    sbc a, a ; a = 00h or FFh
	    xor l
	    ret 
	
#line 4 "xor16.asm"
#line 42 "xor16.bas"
	
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
