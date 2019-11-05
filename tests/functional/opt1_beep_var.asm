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
	ld a, 000h
	ld de, 00000h
	ld bc, 00000h
	push bc
	push de
	push af
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call BEEP
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
#line 1 "beep.asm"
#line 1 "stackf.asm"
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
#line 2 "beep.asm"
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
#line 28 "opt1_beep_var.bas"
ZXBASIC_USER_DATA:
_a:
	DEFB 81h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
