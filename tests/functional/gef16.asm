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
	
#line 1 "lti8.asm"
	
__LTI8: ; Test 8 bit values A < H
        ; Returns result in A: 0 = False, !0 = True
	        sub h
	
__LTI:  ; Signed CMP
	        PROC
	        LOCAL __PE
	
	        ld a, 0  ; Sets default to false
__LTI2:
	        jp pe, __PE
	        ; Overflow flag NOT set
	        ret p
	        dec a ; TRUE
	
__PE:   ; Overflow set
	        ret m
	        dec a ; TRUE
	        ret
	        
	        ENDP
#line 3 "lti32.asm"
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
		
	
	
#line 4 "lti32.asm"
	
__LTI32: ; Test 32 bit values HLDE < Top of the stack
	    exx
	    pop de ; Preserves return address
	    exx
	
	    call __SUB32
	
	    exx
	    push de ; Restores return address
	    exx
	
	    ld a, 0
	    jp __LTI2 ; go for sign
	
#line 83 "gef16.bas"
#line 1 "swap32.asm"
	; Exchanges current DE HL with the
	; ones in the stack
	
__SWAP32:
		pop bc ; Return address
	    ex (sp), hl
	    dec sp
	    dec sp
	    ex de, hl
	    ex (sp), hl
	    ex de, hl
	    inc sp
	    inc sp
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
