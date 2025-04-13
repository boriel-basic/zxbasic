	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld (.core.__CALL_BACK__), sp
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
	DEFB 80h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
_b:
	DEFB 81h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, _b + 4
	call .core.__FP_PUSH_REV
	ld a, 082h
	ld de, 00000h
	ld bc, 00000h
	call .core.__DIVF
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/divf.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/stackf.asm"
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
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/arith/divf.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/error.asm"
	; Simple error control routines
; vim:ts=4:et:
	    push namespace core
	ERR_NR    EQU    23610    ; Error code system variable
	; Error code definitions (as in ZX spectrum manual)
; Set error code with:
	;    ld a, ERROR_CODE
	;    ld (ERR_NR), a
	ERROR_Ok                EQU    -1
	ERROR_SubscriptWrong    EQU     2
	ERROR_OutOfMemory       EQU     3
	ERROR_OutOfScreen       EQU     4
	ERROR_NumberTooBig      EQU     5
	ERROR_InvalidArg        EQU     9
	ERROR_IntOutOfRange     EQU    10
	ERROR_NonsenseInBasic   EQU    11
	ERROR_InvalidFileName   EQU    14
	ERROR_InvalidColour     EQU    19
	ERROR_BreakIntoProgram  EQU    20
	ERROR_TapeLoadingErr    EQU    26
	; Raises error using RST #8
__ERROR:
	    ld (__ERROR_CODE), a
	    rst 8
__ERROR_CODE:
	    nop
	    ret
	; Sets the error system variable, but keeps running.
	; Usually this instruction if followed by the END intermediate instruction.
__STOP:
	    ld (ERR_NR), a
	    ret
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/arith/divf.asm"
	; -------------------------------------------------------------
	; Floating point library using the FP ROM Calculator (ZX 48K)
	; All of them uses C EDHL registers as 1st paramter.
	; For binary operators, the 2n operator must be pushed into the
	; stack, in the order BC DE HL (B not used).
	;
	; Uses CALLEE convention
	; -------------------------------------------------------------
	    push namespace core
__DIVF:	; Division
	    PROC
	    LOCAL __DIVBYZERO
	    LOCAL TMP, ERR_SP
	TMP         EQU 23629 ;(DEST)
	ERR_SP      EQU 23613
	    call __FPSTACK_PUSH2
	    ld hl, (ERR_SP)
	    ld (TMP), hl
	    ld hl, __DIVBYZERO
	    push hl
	    ld (ERR_SP), sp
	    ; ------------- ROM DIV
	    rst 28h
	    defb 01h	; EXCHANGE
	    defb 05h	; DIV
	    defb 38h;   ; END CALC
	    pop hl
	    ld hl, (TMP)
	    ld (ERR_SP), hl
	    jp __FPSTACK_POP
__DIVBYZERO:
	    ld hl, (TMP)
	    ld (ERR_SP), hl
	    ld a, ERROR_NumberTooBig
	    ld (ERR_NR), a
	    ; Returns 0 on DIV BY ZERO error
	    xor a
	    ld b, a
	    ld c, a
	    ld d, a
	    ld e, a
	    ret
	    ENDP
	    pop namespace
#line 25 "arch/zx48k/divf00.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/pushf.asm"
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
#line 26 "arch/zx48k/divf00.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/storef.asm"
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
#line 27 "arch/zx48k/divf00.bas"
	END
