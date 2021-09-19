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
	DEFB 00h
	DEFB 00h
	DEFB 01h
	DEFB 00h
_le:
	DEFB 00h
	DEFB 00h
	DEFB 02h
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
	call .core.__DIVF16
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le + 2)
	push hl
	ld hl, (_le)
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call .core.__DIVF16
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call .core.__DIVF16
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call .core.__DIVF16
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_level)
	ld de, (_level + 2)
	ld bc, 2
	push bc
	ld bc, 0
	push bc
	call .core.__DIVF16
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/divf16.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/div32.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/neg32.asm"
	    push namespace core
__ABS32:
	    bit 7, d
	    ret z
__NEG32: ; Negates DEHL (Two's complement)
	    ld a, l
	    cpl
	    ld l, a
	    ld a, h
	    cpl
	    ld h, a
	    ld a, e
	    cpl
	    ld e, a
	    ld a, d
	    cpl
	    ld d, a
	    inc l
	    ret nz
	    inc h
	    ret nz
	    inc de
	    ret
	    pop namespace
#line 2 "/zxbasic/src/arch/zx48k/library-asm/div32.asm"
	    ; ---------------------------------------------------------
	    push namespace core
__DIVU32:    ; 32 bit unsigned division
	    ; DEHL = Dividend, Stack Top = Divisor
	    ; OPERANDS P = Dividend, Q = Divisor => OPERATION => P / Q
	    ;
	    ; Changes A, BC DE HL B'C' D'E' H'L'
	    ; ---------------------------------------------------------
	    exx
	    pop hl   ; return address
	    pop de   ; low part
	    ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
__DIVU32START: ; Performs D'E'H'L' / HLDE
	    ; Now switch to DIVIDEND = B'C'BC / DIVISOR = D'E'DE (A / B)
	    push de ; push Lowpart(Q)
	    ex de, hl	; DE = HL
	    ld hl, 0
	    exx
	    ld b, h
	    ld c, l
	    pop hl
	    push de
	    ex de, hl
	    ld hl, 0        ; H'L'HL = 0
	    exx
	    pop bc          ; Pop HightPart(B) => B = B'C'BC
	    exx
	    ld a, 32 ; Loop count
__DIV32LOOP:
	    sll c  ; B'C'BC << 1 ; Output most left bit to carry
	    rl  b
	    exx
	    rl c
	    rl b
	    exx
	    adc hl, hl
	    exx
	    adc hl, hl
	    exx
	    sbc hl,de
	    exx
	    sbc hl,de
	    exx
	    jp nc, __DIV32NOADD	; use JP inside a loop for being faster
	    add hl, de
	    exx
	    adc hl, de
	    exx
	    dec bc
__DIV32NOADD:
	    dec a
	    jp nz, __DIV32LOOP	; use JP inside a loop for being faster
	    ; At this point, quotient is stored in B'C'BC and the reminder in H'L'HL
	    push hl
	    exx
	    pop de
	    ex de, hl ; D'E'H'L' = 32 bits modulus
	    push bc
	    exx
	    pop de    ; DE = B'C'
	    ld h, b
	    ld l, c   ; DEHL = quotient D'E'H'L' = Modulus
	    ret     ; DEHL = quotient, D'E'H'L' = Modulus
__MODU32:    ; 32 bit modulus for 32bit unsigned division
	    ; DEHL = Dividend, Stack Top = Divisor (DE, HL)
	    exx
	    pop hl   ; return address
	    pop de   ; low part
	    ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
	    call __DIVU32START	; At return, modulus is at D'E'H'L'
__MODU32START:
	    exx
	    push de
	    push hl
	    exx
	    pop hl
	    pop de
	    ret
__DIVI32:    ; 32 bit signed division
	    ; DEHL = Dividend, Stack Top = Divisor
	    ; A = Dividend, B = Divisor => A / B
	    exx
	    pop hl   ; return address
	    pop de   ; low part
	    ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
__DIVI32START:
	    exx
	    ld a, d	 ; Save sign
	    ex af, af'
	    bit 7, d ; Negative?
	    call nz, __NEG32 ; Negates DEHL
	    exx		; Now works with H'L'D'E'
	    ex af, af'
	    xor h
	    ex af, af'  ; Stores sign of the result for later
	    bit 7, h ; Negative?
	    ex de, hl ; HLDE = DEHL
	    call nz, __NEG32
	    ex de, hl
	    call __DIVU32START
	    ex af, af' ; Recovers sign
	    and 128	   ; positive?
	    ret z
	    jp __NEG32 ; Negates DEHL and returns from there
__MODI32:	; 32bits signed division modulus
	    exx
	    pop hl   ; return address
	    pop de   ; low part
	    ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
	    call __DIVI32START
	    jp __MODU32START
	    pop namespace
#line 2 "/zxbasic/src/arch/zx48k/library-asm/divf16.asm"
	    push namespace core
__DIVF16:	; 16.16 Fixed point Division (signed)
	    ; DE.HL = Dividend, Stack Top = Divisor
	    ; A = Dividend, B = Divisor => A / B
	    exx
	    pop hl   ; return address
	    pop de   ; low part
	    ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
	    ex de, hl   ; D'E'.H'L' Dividend
__DIVF16START: ; FAST Entry: DEHL => Dividend, D'E'H'L' => Divisor
	    ld a, d	 ; Save sign
	    ex af, af'
	    bit 7, d ; Negative?
	    call nz, __NEG32 ; Negates DEHL
	    exx		; Now works with D'E'.H'L'
	    ex af, af'
	    xor d
	    ex af, af'  ; Stores sign of the result for later
	    bit 7, d ; Negative?
	    call nz, __NEG32
	    exx		 ; Now we have DE.HL => Dividend
	    ld b, 16
__SHIFTALOOP:		; Tries to shift Dividend to the left
	    bit 7, d
	    jp nz, __SHIFTB
	    add hl, hl
	    ex de, hl
	    adc hl, hl
	    ex de, hl
	    djnz __SHIFTALOOP
	    jp __DOF16_DIVRDY
__SHIFTB:       ; Cannot shift Dividend more to the left, try to shift Divisor to the right
	    ld a, b
	    exx
	    ld b, a
	    ; Divisor is in DEHL
__SHIFTBLOOP:
	    bit 1, l
	    jp nz, __DOF16_DIVIDE
	    sra d
	    rr e
	    rr h
	    rr l
	    djnz __SHIFTBLOOP
__DOF16_DIVIDE:
	    ld a, b
	    exx
	    ld b, a
__DOF16_DIVRDY:
	    exx
	    ex de, hl
	    push bc
	    call __DIVU32START
	    pop bc
	    xor a
	    or b
	    jp z, __ENDF16DIV
__SHIFTCLOOP:
	    add hl, hl	; Shift DECIMAL PART << 1
	    ex de, hl
	    adc hl, hl  ; Shift INTEGER PART << 1 Plus Carry
	    ex de, hl
	    djnz __SHIFTCLOOP
__ENDF16DIV: 	   ; Put the sign on the result
	    ex af, af' ; Recovers sign
	    and 128	   ; positive?
	    ret z
	    jp __NEG32 ; Negates DEHL and returns from there
	    pop namespace
#line 63 "divf16c.bas"
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
#line 64 "divf16c.bas"
	END
