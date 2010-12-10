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
	call __BAND32
	ld a, l
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	push de
	push hl
	ld de, 0
	ld hl, 1
	call __BAND32
	ld a, l
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	push de
	push hl
	ld de, 0
	ld hl, 65535
	call __BAND32
	ld a, l
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 0
	push bc
	call __BAND32
	ld a, l
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 1
	push bc
	call __BAND32
	ld a, l
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 65535
	push bc
	call __BAND32
	ld a, l
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	push de
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call __BAND32
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
#line 1 "band32.asm"
	; FASTCALL bitwise and 32 version.
	; Performs 32bit and 32bit and returns the bitwise
	; result in DE,HL
	; First operand in DE,HL 2nd operand into the stack
	
__BAND32:
	    ld b, h
	    ld c, l ; BC <- HL
	
	    pop hl  ; Return address
	    ex (sp), hl ; HL <- Lower part of 2nd Operand
	
		ld a, b
	    and h
	    ld b, a
	
	    ld a, c
	    and l
	    ld c, a ; BC <- BC & HL
	
		pop hl  ; Return dddress
	    ex (sp), hl ; HL <- High part of 2nd Operand
	
	    ld a, d
	    and h
	    ld d, a
	
	    ld a, e
	    and l
	    ld e, a ; DE <- DE & HL
	
	    ld h, b
	    ld l, c ; HL <- BC  ; Always return DE,HL pair regs
	
	    ret
	
#line 81 "band32.bas"
	
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
