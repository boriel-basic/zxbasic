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
	DEFB 00, 00
_b:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_a)
	xor a
	ld (_b), a
	ld hl, (_a)
	ld a, h
	or l
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	ld hl, (_a)
	xor a
	ld (_b), a
	ld hl, (_a)
	ld a, h
	or l
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	ld de, (_a)
	ld hl, (_a)
	call .core.__AND16
	sub 1
	sbc a, a
	inc a
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bool/and16.asm"
	; FASTCALL boolean and 16 version.
	; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: DE, HL)
	; Performs 16bit and 16bit and returns the boolean
	    push namespace core
__AND16:
	    ld a, h
	    or l
	    ret z
	    ld a, d
	    or e
	    ret
	    pop namespace
#line 44 "arch/zx48k/and16.bas"
	END
