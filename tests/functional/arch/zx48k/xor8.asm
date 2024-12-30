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
	DEFB 00
_b:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, (_a)
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	ld a, (_a)
	sub 1
	sbc a, a
	neg
	ld (_b), a
	ld a, (_a)
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	ld a, (_a)
	sub 1
	sbc a, a
	neg
	ld (_b), a
	ld hl, (_a - 1)
	ld a, (_a)
	call .core.__XOR8
	neg
	ld (_b), a
	ld hl, (_a - 1)
	ld a, (_a)
	sub h
	sub 1
	sbc a, a
	push af
	ld hl, (_a - 1)
	ld a, (_a)
	sub h
	sub 1
	sbc a, a
	ld h, a
	pop af
	call .core.__XOR8
	neg
	ld (_b), a
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bool/xor8.asm"
; vim:ts=4:et:
	; FASTCALL boolean xor 8 version.
	; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: A, H)
	; Performs 8bit xor 8bit and returns the boolean
	    push namespace core
__XOR16:
	    ld a, h
	    or l
	    ld h, a
	    ld a, d
	    or e
__XOR8:
	    sub 1
	    sbc a, a
	    ld l, a  ; l = 00h or FFh
	    ld a, h
	    sub 1
	    sbc a, a ; a = 00h or FFh
	    xor l
	    ret
	    pop namespace
#line 58 "arch/zx48k/xor8.bas"
	END
