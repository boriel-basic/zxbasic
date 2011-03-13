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
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 0
	call __XOR32
	ld (_b), a
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 1
	call __XOR32
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 0
	push bc
	call __XOR32
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 1
	push bc
	call __XOR32
	ld (_b), a
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call __XOR32
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
#line 1 "xor32.asm"
	; FASTCALL boolean xor 8 version.
	; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: A, H)
	; Performs 32bit xor 32bit and returns the boolean
	
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
	
#line 7 "xor32.asm"
	
__XOR32:
	    ld a, h
	    or l
	    or d
	    or e
	    ld c, a
	
	    pop hl  ; RET address
	    pop de
	    ex (sp), hl
	    ld a, h
	    or l
	    or d
	    or e
	    ld h, c
	    jp __XOR8
	
#line 58 "xor32.bas"
	
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
