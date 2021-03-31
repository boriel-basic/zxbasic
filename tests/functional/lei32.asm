	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (.core.__CALL_BACK__), hl
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_level:
	DEFB 01h
	DEFB 00h
	DEFB 00h
	DEFB 00h
_le:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
_l:
	DEFB 00, 00, 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_level)
	ld de, (_level + 2)
	push de
	push hl
	ld de, (_le + 2)
	ld hl, (_le)
	call .core.__SWAP32
	call .core.__LEI32
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le + 2)
	push hl
	ld hl, (_le)
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call .core.__LEI32
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call .core.__LEI32
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call .core.__LEI32
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_level)
	ld de, (_level + 2)
	ld bc, 0
	push bc
	ld bc, 0
	push bc
	call .core.__LEI32
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_l), hl
	ld (_l + 2), de
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/lei32.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/sub32.asm"
	; SUB32
	; Perform TOP of the stack - DEHL
	; Pops operand out of the stack (CALLEE)
	; and returns result in DEHL. Carry an Z are set correctly
	    push namespace core
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
	    pop namespace
#line 3 "/zxbasic/src/arch/zx48k/library-asm/lei32.asm"
	    push namespace core
__LEI32: ; Test 32 bit values Top of the stack <= HL,DE
	    PROC
	    LOCAL checkParity
	    exx
	    pop de ; Preserves return address
	    exx
	    call __SUB32
	    exx
	    push de ; Puts return address back
	    exx
	    ex af, af'
	    ld a, h
	    or l
	    or e
	    or d
	    ld a, 1
	    ret z
	    ex af, af'
	    jp po, checkParity
	    ld a, d
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 83 "lei32.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/swap32.asm"
	; Exchanges current DE HL with the
	; ones in the stack
	    push namespace core
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
	    pop namespace
#line 84 "lei32.bas"
	END
