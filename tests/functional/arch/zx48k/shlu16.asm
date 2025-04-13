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
	DEFB 00, 00
_b:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, (_b)
	ld b, a
	ld hl, (_a)
	or a
	jr z, .LABEL.__LABEL1
.LABEL.__LABEL0:
	add hl, hl
	djnz .LABEL.__LABEL0
.LABEL.__LABEL1:
	ld (_a), hl
	add hl, hl
	ld (_a), hl
	pop hl
	ld (_a), hl
	ld a, (_b)
	xor a
	ld l, a
	ld h, 0
	ld (_a), hl
	ld de, (_a)
	ld hl, (_a)
	call .core.__EQ16
	sub 1
	sbc a, a
	inc a
	push af
	ld a, (_b)
	pop hl
	or a
	ld b, a
	ld a, h
	jr z, .LABEL.__LABEL7
.LABEL.__LABEL6:
	add a, a
	djnz .LABEL.__LABEL6
.LABEL.__LABEL7:
	ld l, a
	ld h, 0
	ld (_a), hl
	ld hl, (_b - 1)
	ld a, (_b)
	sub h
	sub 1
	sbc a, a
	neg
	ld b, a
	ld hl, (_a)
	or a
	jr z, .LABEL.__LABEL9
.LABEL.__LABEL8:
	add hl, hl
	djnz .LABEL.__LABEL8
.LABEL.__LABEL9:
	ld (_a), hl
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/eq16.asm"
	    push namespace core
__EQ16:	; Test if 16bit values HL == DE
    ; Returns result in A: 0 = False, FF = True
	    xor a	; Reset carry flag
	    sbc hl, de
	    ret nz
	    inc a
	    ret
	    pop namespace
#line 71 "arch/zx48k/shlu16.bas"
	END
