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
	ld hl, 0
	ld a, l
	ld (_b), a
	ld de, 1
	ld hl, (_a)
	call __BAND16
	ld a, l
	ld (_b), a
	pop hl
	ld a, l
	ld (_b), a
	ld hl, (_a)
	ld hl, 0
	ld a, l
	ld (_b), a
	ld de, 1
	ld hl, (_a)
	call __BAND16
	ld a, l
	ld (_b), a
	pop hl
	ld a, l
	ld (_b), a
	ld de, (_a)
	ld hl, (_a)
	call __BAND16
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
#line 1 "band16.asm"
	
; vim:ts=4:et:
	; FASTCALL bitwise and16 version.
	; result in hl 
; __FASTCALL__ version (operands: A, H)
	; Performs 16bit or 16bit and returns the boolean
; Input: HL, DE
; Output: HL <- HL AND DE
	
__BAND16:
		ld a, h
		and d
	    ld h, a
	
	    ld a, l
	    and e
	    ld l, a
	
	    ret 
	
#line 47 "band16.bas"
	
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
