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
	call __LTI32
	sub 1
	sbc a, a
	ld l, a
	ld h, 0
	ex de, hl
	ld hl, 0
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le + 2)
	push hl
	ld hl, (_le)
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __LTI32
	sub 1
	sbc a, a
	ld l, a
	ld h, 0
	ex de, hl
	ld hl, 0
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __LTI32
	sub 1
	sbc a, a
	ld l, a
	ld h, 0
	ex de, hl
	ld hl, 0
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __LTI32
	sub 1
	sbc a, a
	ld l, a
	ld h, 0
	ex de, hl
	ld hl, 0
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
#line 1 "lti32.asm"


#line 1 "sub32.asm"

	; SUB32
	; Perform TOP of the stack - DEHL
	; Pops operand out of the stack (CALLEE)
	; and returns result in DEHL. Carry an Z are set correctly

__SUB32:
		exx
		pop bc		; saves return address in BC'
		exx

		or a        ; clears carry flag
		ld b, h     ; Operands come reversed => BC <- HL,  HL = HL - BC
		ld c, l
		pop hl
		sbc hl, bc
		ex de, hl

		ld b, h	    ; High part (DE) now in HL. Repeat operation
		ld c, l
		pop hl
		sbc hl, bc
		ex de, hl   ; DEHL now has de 32 bit result

		exx
		push bc		; puts return address back
		exx
		ret
#line 3 "lti32.asm"

__LTI32: ; Test 32 bit values in Top of the stack < HLDE
	    PROC
	    LOCAL checkParity
	    exx
	    pop de ; Preserves return address
	    exx

	    call __SUB32

	    exx
	    push de ; Restores return address
	    exx

	    jp po, checkParity
	    ld a, d
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
#line 83 "gef16.bas"
#line 1 "swap32.asm"

	; Exchanges current DE HL with the
	; ones in the stack

__SWAP32:
		pop bc ; Return address
	    ex (sp), hl
	    inc sp
	    inc sp
	    ex de, hl
	    ex (sp), hl
	    ex de, hl
	    dec sp
	    dec sp
	    push bc
		ret

#line 84 "gef16.bas"

ZXBASIC_USER_DATA:
_level:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
_le:
	DEFB 00h
	DEFB 00h
	DEFB 01h
	DEFB 00h
_l:
	DEFB 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
