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
_x:
	push ix
	ld ix, 0
	add ix, sp
	ld a, 083h
	ld de, 00020h
	ld bc, 00000h
	ld hl, 4
	call __PSTOREF
_x__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
#line 1 "pstoref.asm"

	; Stores FP number in A ED CB at location HL+IX
	; HL = Offset
	; IX = Stack Frame
	; A ED CB = FP Number

#line 1 "storef.asm"

__PISTOREF:	; Indect Stores a float (A, E, D, C, B) at location stored in memory, pointed by (IX + HL)
			push de
			ex de, hl	; DE <- HL
			push ix
			pop hl		; HL <- IX
			add hl, de  ; HL <- IX + HL
			pop de

__ISTOREF:  ; Load address at hl, and stores A,E,D,C,B registers at that address. Modifies A' register
	        ex af, af'
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a     ; HL = (HL)
	        ex af, af'

__STOREF:	; Stores the given FP number in A EDCB at address HL
			ld (hl), a
			inc hl
			ld (hl), e
			inc hl
			ld (hl), d
			inc hl
			ld (hl), c
			inc hl
			ld (hl), b
			ret

#line 7 "pstoref.asm"

	; Stored a float number in A ED CB into the address pointed by IX + HL
__PSTOREF:
		push de
	    ex de, hl  ; DE <- HL
	    push ix
		pop hl	   ; HL <- IX
	    add hl, de ; HL <- IX + DE
		pop de
	    jp __STOREF

#line 37 "params_implicit.bas"

ZXBASIC_USER_DATA:
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
