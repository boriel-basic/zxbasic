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
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 0
	call .core.__OR32
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 1
	call .core.__OR32
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 0
	push bc
	call .core.__OR32
	sub 1
	sbc a, a
	inc a
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 1
	push bc
	call .core.__OR32
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
	call .core.__OR32
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
	pop de
	or d
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bool/or32.asm"
	    push namespace core
__OR32:  ; Performs logical operation A AND B
	    ; between DEHL and TOP of the stack.
	    ; Returns A = 0 (False) or A = FF (True)
	    ld a, h
	    or l
	    or d
	    or e
	    pop hl ; Return address
	    pop de
	    ex (sp), hl
	    or d
	    or e
	    or h
	    or l
#line 26 "/zxbasic/src/lib/arch/zx48k/runtime/bool/or32.asm"
	    ret
	    pop namespace
#line 93 "arch/zx48k/or32.bas"
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
#line 94 "arch/zx48k/or32.bas"
	END
