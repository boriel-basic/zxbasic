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
_a:
	DEFB 00, 00, 00, 00, 00
_b:
	DEFB 00, 00, 00, 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
.LABEL._10:
	ld hl, _a + 4
	call .core.__FP_PUSH_REV
	ld a, 081h
	ld de, 00000h
	ld bc, 00000h
	call .core.__ADDF
	ld hl, _a
	call .core.__STOREF
	ld hl, _b + 4
	call .core.__FP_PUSH_REV
	ld a, 081h
	ld de, 00000h
	ld bc, 00000h
	call .core.__ADDF
	ld hl, _b
	call .core.__STOREF
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/addf.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/stackf.asm"
	; -------------------------------------------------------------
	; Functions to manage FP-Stack of the ZX Spectrum ROM CALC
	; -------------------------------------------------------------
	    push namespace core
	__FPSTACK_PUSH EQU 2AB6h	; Stores an FP number into the ROM FP stack (A, ED CB)
	__FPSTACK_POP  EQU 2BF1h	; Pops an FP number out of the ROM FP stack (A, ED CB)
__FPSTACK_PUSH2: ; Pushes Current A ED CB registers and top of the stack on (SP + 4)
	    ; Second argument to push into the stack calculator is popped out of the stack
	    ; Since the caller routine also receives the parameters into the top of the stack
	    ; four bytes must be removed from SP before pop them out
	    call __FPSTACK_PUSH ; Pushes A ED CB into the FP-STACK
	    exx
	    pop hl       ; Caller-Caller return addr
	    exx
	    pop hl       ; Caller return addr
	    pop af
	    pop de
	    pop bc
	    push hl      ; Caller return addr
	    exx
	    push hl      ; Caller-Caller return addr
	    exx
	    jp __FPSTACK_PUSH
__FPSTACK_I16:	; Pushes 16 bits integer in HL into the FP ROM STACK
	    ; This format is specified in the ZX 48K Manual
	    ; You can push a 16 bit signed integer as
	    ; 0 SS LL HH 0, being SS the sign and LL HH the low
	    ; and High byte respectively
	    ld a, h
	    rla			; sign to Carry
	    sbc	a, a	; 0 if positive, FF if negative
	    ld e, a
	    ld d, l
	    ld c, h
	    xor a
	    ld b, a
	    jp __FPSTACK_PUSH
	    pop namespace
#line 2 "/zxbasic/src/arch/zx48k/library-asm/addf.asm"
	; -------------------------------------------------------------
	; Floating point library using the FP ROM Calculator (ZX 48K)
	; All of them uses A EDCB registers as 1st paramter.
	; For binary operators, the 2n operator must be pushed into the
	; stack, in the order AF DE BC (F not used).
	;
	; Uses CALLEE convention
	; -------------------------------------------------------------
	    push namespace core
__ADDF:	; Addition
	    call __FPSTACK_PUSH2
	    ; ------------- ROM ADD
	    rst 28h
	    defb 0fh	; ADD
	    defb 38h;   ; END CALC
	    jp __FPSTACK_POP
	    pop namespace
#line 34 "labelsent.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/pushf.asm"
	; Routine to push Float pointed by HL
	; Into the stack. Notice that the hl points to the last
	; byte of the FP number.
	; Uses H'L' B'C' and D'E' to preserve ABCDEHL registers
	    push namespace core
__FP_PUSH_REV:
	    push hl
	    exx
	    pop hl
	    pop bc ; Return Address
	    ld d, (hl)
	    dec hl
	    ld e, (hl)
	    dec hl
	    push de
	    ld d, (hl)
	    dec hl
	    ld e, (hl)
	    dec hl
	    push de
	    ld d, (hl)
	    push de
	    push bc ; Return Address
	    exx
	    ret
	    pop namespace
#line 35 "labelsent.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/storef.asm"
	    push namespace core
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
	    pop namespace
#line 36 "labelsent.bas"
	END
