; -------------------------------------------------------------
; Functions to manage FP-Stack of the ZX Spectrum ROM CALC
; -------------------------------------------------------------


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
