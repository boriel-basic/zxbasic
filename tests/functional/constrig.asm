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
	ld a, 07Fh
	ld de, 099B3h
	ld bc, 0F5DBh
	ld hl, _a
	call __STOREF
	ld a, 080h
	ld de, 0BBEFh
	ld bc, 01EA0h
	ld hl, _a
	call __STOREF
	ld a, 07Fh
	ld de, 0C93Fh
	ld bc, 064B0h
	ld hl, _a
	call __STOREF
	ld a, 07Dh
	ld de, 0244Dh
	ld bc, 0B093h
	ld hl, _a
	call __STOREF
	ld a, 081h
	ld de, 03D3Ch
	ld bc, 06791h
	ld hl, _a
	call __STOREF
	ld a, 07Fh
	ld de, 03915h
	ld bc, 030D3h
	ld hl, _a
	call __STOREF
	ld a, 081h
	ld de, 05A20h
	ld bc, 07589h
	ld hl, _a
	call __STOREF
	ld a, 086h
	ld de, 07604h
	ld bc, 00939h
	ld hl, _a
	call __STOREF
	ld a, 081h
	ld de, 0776Fh
	ld bc, 08B50h
	ld hl, _a
	call __STOREF
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

#line 63 "constrig.bas"

ZXBASIC_USER_DATA:
_a:
	DEFB 00, 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
