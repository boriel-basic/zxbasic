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
	DEFB 00, 00, 00, 00
_b:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	xor a
	ld (_b), a
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 1
	call .core.__AND32
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	xor a
	ld (_b), a
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 1
	call .core.__AND32
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call .core.__AND32
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call .core.__EQ32
	push af
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call .core.__EQ32
	ld h, a
	pop af
	or a
	jr z, .LABEL.__LABEL0
	ld a, h
.LABEL.__LABEL0:
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bool/and32.asm"
	; FASTCALL boolean and 32 version.
	; Performs 32bit and 32bit and returns the boolean
	; result in Accumulator (0 False, not 0 True)
	; First operand in DE,HL 2nd operand into the stack
	    push namespace core
__AND32:
	    ld a, l
	    or h
	    or e
	    or d
	    pop hl
	    pop de
	    ex (sp), hl
	    ret z
	    ld a, d
	    or e
	    or h
	    or l
#line 28 "/zxbasic/src/lib/arch/zx48k/runtime/bool/and32.asm"
	    ret
	    pop namespace
#line 79 "arch/zx48k/and32.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/eq32.asm"
	    push namespace core
__EQ32:	; Test if 32bit value HLDE equals top of the stack
    ; Returns result in A: 0 = False, FF = True
	    exx
	    pop bc ; Return address
	    exx
	    xor a	; Reset carry flag
	    pop bc
	    sbc hl, bc ; Low part
	    ex de, hl
	    pop bc
	    sbc hl, bc ; High part
	    exx
	    push bc ; CALLEE
	    exx
	    ld a, h
	    or l
	    or d
	    or e   ; a = 0 and Z flag set only if HLDE = 0
	    ld a, 1
	    ret z
	    xor a
	    ret
	    pop namespace
#line 80 "arch/zx48k/and32.bas"
	END
