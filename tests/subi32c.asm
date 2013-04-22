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
	ld hl, (_level)
	ld de, (_level + 2)
	push de
	push hl
	ld hl, (_le + 2)
	push hl
	ld hl, (_le)
	push hl
	pop hl
	pop de
	call __SWAP32
	call __SUB32
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le + 2)
	push hl
	ld hl, (_le)
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __SUB32
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __SUB32
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_level)
	ld de, (_level + 2)
	ld bc, 0
	push bc
	ld bc, 1
	push bc
	call __SUB32
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
#line 1 "sub32.asm"
	; SUB32 
	; TOP of the stack - DEHL
	; Pops operand out of the stack (CALLEE)
	; and returns result in DEHL
	; Operands come reversed => So we swap then using EX (SP), HL
	
__SUB32:
		exx
		pop bc		; Return address
		exx
	
		ex (sp), hl
		pop bc
		or a 
		sbc hl, bc
	
		ex de, hl
		ex (sp), hl
		pop bc
		sbc hl, bc
		ex de, hl
	
		exx
		push bc		; Put return address
		exx
		ret
		
	
	
#line 59 "subi32c.bas"
#line 1 "swap32.asm"
	; Exchanges current DE HL with the
	; ones in the stack
	
__SWAP32:
		pop bc ; Return address
	
		exx
		pop hl	; exx'
		pop de
	
		exx
		push de ; exx
		push hl
	
		exx		; exx '
		push de
		push hl
		
		exx		; exx
		pop hl
		pop de
	
		push bc
	
		ret
	
#line 60 "subi32c.bas"
	
ZXBASIC_USER_DATA:
_le:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
_l:
	DEFB 00, 00, 00, 00
_level:
	DEFB 01h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
