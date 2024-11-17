	org 32768
.core.__START_PROGRAM:
	di
	push iy
	ld iy, 0x5C3A  ; ZX Spectrum ROM variables address
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
	DEFB 81h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, 000h
	ld de, 00000h
	ld bc, 00000h
	push bc
	push de
	push af
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call .core.BEEP
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	pop iy
	ei
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/io/sound/beep.asm"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/stackf.asm"
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
#line 2 "/zxbasic/src/lib/arch/zxnext/runtime/io/sound/beep.asm"
	    push namespace core
BEEP:	; The beep command, as in BASIC
	    ; Duration in C,ED,LH (float)
	    ; Pitch in top of the stack
	    CALL __FPSTACK_PUSH
	    pop hl    ; RET address
	    pop af
	    pop de
	    pop bc    ; Recovers PITCH from the stack
	    push hl    ; CALLEE, now ret addr in top of the stack
	    CALL __FPSTACK_PUSH  ; Pitch onto the FP stack
	    push ix   ; BEEP routine modifies IX. We have to preserve it
	    call 03F8h
	    pop ix
	    ret
	    pop namespace
#line 23 "arch/zxnext/opt1_beep_var.bas"
	END
