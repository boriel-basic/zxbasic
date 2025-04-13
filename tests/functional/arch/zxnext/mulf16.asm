	org 32768
.core.__START_PROGRAM:
	di
	push iy
	ld iy, 0x5C3A  ; ZX Spectrum ROM variables address
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
	DEFB 00, 00, 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_a)
	ld de, (_a + 2)
	ld hl, 0
	ld e, h
	ld d, l
	ld (_b), hl
	ld (_b + 2), de
	ld hl, (_a)
	ld de, (_a + 2)
	ld (_b), hl
	ld (_b + 2), de
	ld hl, (_a)
	ld de, (_a + 2)
	ld hl, 0
	ld e, h
	ld d, l
	ld (_b), hl
	ld (_b + 2), de
	ld hl, (_a)
	ld de, (_a + 2)
	ld (_b), hl
	ld (_b + 2), de
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call .core.__MULF16
	ld (_b), hl
	ld (_b + 2), de
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
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/arith/mulf16.asm"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/neg32.asm"
	    push namespace core
__ABS32:
	    bit 7, d
	    ret z
__NEG32: ; Negates DEHL (Two's complement)
	    ld a, l
	    cpl
	    ld l, a
	    ld a, h
	    cpl
	    ld h, a
	    ld a, e
	    cpl
	    ld e, a
	    ld a, d
	    cpl
	    ld d, a
	    inc l
	    ret nz
	    inc h
	    ret nz
	    inc de
	    ret
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zxnext/runtime/arith/mulf16.asm"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/arith/_mul32.asm"
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
#line 3 "/zxbasic/src/lib/arch/zxnext/runtime/arith/mulf16.asm"
	    push namespace core
__MULF16:		;
	    ld      a, d            ; load sgn into a
	    ex      af, af'         ; saves it
	    call    __ABS32         ; convert to positive
	    exx
	    pop hl ; Return address
	    pop de ; Low part
	    ex (sp), hl ; CALLEE caller convention; Now HL = Hight part, (SP) = Return address
	    ex de, hl	; D'E' = High part (B),  H'L' = Low part (B) (must be in DE)
	    ex      af, af'
	    xor     d               ; A register contains resulting sgn
	    ex      af, af'
	    call    __ABS32         ; convert to positive
	    call __MUL32_64START
	; rounding (was not included in zx81)
__ROUND_FIX:					; rounds a 64bit (32.32) fixed point number to 16.16
	    ; result returned in dehl
	    ; input in h'l'hlb'c'ac
	    sla     a               ; result bit 47 to carry
	    exx
	    ld      hl,0            ; ld does not change carry
	    adc     hl,bc           ; hl = hl + 0 + carry
	    push	hl
	    exx
	    ld      bc,0
	    adc     hl,bc           ; hl = hl + 0 + carry
	    ex		de, hl
	    pop		hl              ; rounded result in de.hl
	    ex      af, af'         ; recovers result sign
	    or      a
	    jp      m, __NEG32      ; if negative, negates it
	    ret
	    pop namespace
#line 44 "arch/zxnext/mulf16.bas"
	END
