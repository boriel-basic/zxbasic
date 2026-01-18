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
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call .core.__MUL32
	push de
	push hl
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 2
	call .core.__MUL32
	push de
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call .core.__MUL32
	call .core.__MUL32
	ld (_a), hl
	ld (_a + 2), de
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/mul32.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/_mul32.asm"
; Ripped from: http://www.andreadrian.de/oldcpu/z80_number_cruncher.html#moztocid784223
	; Used with permission.
	; Multiplies 32x32 bit integer (DEHL x D'E'H'L')
	; 64bit result is returned in H'L'H L B'C'A C
	    push namespace core
__MUL32_64START:
	    push hl
	    exx
	    ld b, h
	    ld c, l		; BC = Low Part (A)
	    pop hl		; HL = Load Part (B)
	    ex de, hl	; DE = Low Part (B), HL = HightPart(A) (must be in B'C')
	    push hl
	    exx
	    pop bc		; B'C' = HightPart(A)
	    exx			; A = B'C'BC , B = D'E'DE
	    ; multiply routine 32 * 32bit = 64bit
	    ; h'l'hlb'c'ac = b'c'bc * d'e'de
	    ; needs register a, changes flags
	    ;
	    ; this routine was with tiny differences in the
	    ; sinclair zx81 rom for the mantissa multiply
__LMUL:
	    xor     a               ; reset carry flag
	    ld      h, a            ; result bits 32..47 = 0
	    ld      l, a
	    exx
	    ld      h, a            ; result bits 48..63 = 0
	    ld      l, a
	    exx
	    ld      a,b             ; mpr is b'c'ac
	    ld      b,33            ; initialize loop counter
	    jp      __LMULSTART
__LMULLOOP:
	    jr      nc,__LMULNOADD  ; JP is 2 cycles faster than JR. Since it's inside a LOOP
	    ; it can save up to 33 * 2 = 66 cycles
	    ; But JR if 3 cycles faster if JUMP not taken!
	    add     hl,de           ; result += mpd
	    exx
	    adc     hl,de
	    exx
__LMULNOADD:
	    exx
	    rr      h               ; right shift upper
	    rr      l               ; 32bit of result
	    exx
	    rr      h
	    rr      l
__LMULSTART:
	    exx
	    rr      b               ; right shift mpr/
	    rr      c               ; lower 32bit of result
	    exx
	    rra                     ; equivalent to rr a
	    rr      c
	    djnz    __LMULLOOP
	    ret						; result in h'l'hlb'c'ac
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/arith/mul32.asm"
	    push namespace core
__MUL32:
	    ; multiplies 32 bit un/signed integer.
	    ; First operand stored in DEHL, and 2nd onto stack
	    ; Lowest part of 2nd operand on top of the stack
	    ; returns the result in DE.HL
	    exx
	    pop hl	; Return ADDRESS
	    pop de	; Low part
	    ex (sp), hl ; CALLEE -> HL = High part
	    ex de, hl
	    call __MUL32_64START
__TO32BIT:  ; Converts H'L'HLB'C'AC to DEHL (Discards H'L'HL)
	    exx
	    push bc
	    exx
	    pop de
	    ld h, a
	    ld l, c
	    ret
	    pop namespace
#line 41 "arch/zx48k/mul32b.bas"
	END
