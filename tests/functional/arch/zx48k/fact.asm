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
_y:
	DEFB 00, 00, 00, 00
_x:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, 1
	ld (_x), a
	jp .LABEL.__LABEL0
.LABEL.__LABEL3:
	ld a, (_x)
	ld l, a
	ld h, 0
	ld e, h
	ld d, h
	ld (_y), hl
	ld (_y + 2), de
.LABEL.__LABEL4:
	ld hl, _x
	inc (hl)
.LABEL.__LABEL0:
	ld a, 10
	ld hl, (_x - 1)
	cp h
	jp nc, .LABEL.__LABEL3
.LABEL.__LABEL2:
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
_fact:
	push ix
	ld ix, 0
	add ix, sp
	ld l, (ix+4)
	ld h, (ix+5)
	ld e, (ix+6)
	ld d, (ix+7)
	push de
	push hl
	ld de, 0
	ld hl, 2
	call .core.__SUB32
	jp nc, .LABEL.__LABEL6
	ld de, 0
	ld hl, 1
	jp _fact__leave
.LABEL.__LABEL6:
	ld l, (ix+4)
	ld h, (ix+5)
	ld e, (ix+6)
	ld d, (ix+7)
	push de
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	ld e, (ix+6)
	ld d, (ix+7)
	push de
	push hl
	ld de, 0
	ld hl, 1
	call .core.__SUB32
	push de
	push hl
	call _fact
	call .core.__MUL32
_fact__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
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
	f
#line 83 "arch/zx48k/fact.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/sub32.asm"
	; SUB32
	; Perform TOP of the stack - DEHL
	; Pops operand out of the stack (CALLEE)
	; and returns result in DEHL. Carry an Z are set correctly
	    push namespace core
__SUB32:
	    exx
	    pop bc		; saves return address in BC'
	    exx
	    or a        ; clears carry flag
	    ld b, h     ; Operands come reversed => BC <- HL,  HL = HL - BC
	    ld c, l
	    pop hl
	    sbc hl, bc
	    ex de, hl
	    ld b, h	    ; High part (DE) now in HL. Repeat operation
	    ld c, l
	    pop hl
	    sbc hl, bc
	    ex de, hl   ; DEHL now has de 32 bit result
	    exx
	    push bc		; puts return address back
	    exx
	    ret
	    pop namespace
#line 84 "arch/zx48k/fact.bas"
	END
