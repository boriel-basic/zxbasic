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
	ld de, (_a + 2)
	push de
	push hl
	ld de, 0
	ld hl, 0
	call __OR32
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	push de
	push hl
	ld de, 0
	ld hl, 1
	call __OR32
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 0
	push bc
	call __OR32
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 1
	push bc
	call __OR32
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	push de
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call __OR32
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
#line 1 "or32.asm"
__OR32:  ; Performs logical operation A AND B
			 ; between DEHL and TOP of the stack.
			 ; Returns A = 0 (False) or A = FF (True)
	
		ld a, h
		or l
		or d
		or e
	
		pop hl ; Return address
	
		pop de	
		or d
		or e
	
		pop de	
		or d
		or e   ; A = 0 only if DEHL and TOP of the stack = 0
	
		jp (hl) ; Faster "Ret"
	
	
#line 58 "or32.bas"
	
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
