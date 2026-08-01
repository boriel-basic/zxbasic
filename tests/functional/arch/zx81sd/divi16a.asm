	org $0000
	jp $0100
	org $0008
	di
	halt
	org $0010
	di
	halt
	org $0018
	di
	halt
	org $0020
	di
	halt
	org $0028
	jp .core.FP_CALC_ENTRY
	org $0030
	di
	halt
	org $0038
	push af
.core.__RST38_WAIT:
	in   a, ($AF)
	and  $7E
	jr   z, .core.__RST38_WAIT
	pop  af
	ret
	org $0066
	retn
	org 256
.core.__START_PROGRAM:
	ld   b, 9
	ld   a, 1
	ld   c, 0xe7
	out  (c), a
	ld   b, 10
	ld   a, 2
	ld   c, 0xe7
	out  (c), a
	ld   b, 11
	ld   a, 3
	ld   c, 0xe7
	out  (c), a
	ld   b, 12
	ld   a, 4
	ld   c, 0xe7
	out  (c), a
	ld   b, 13
	ld   a, 5
	ld   c, 0xe7
	out  (c), a
	ld   b, 15
	ld   a, 7
	ld   c, 0xe7
	out  (c), a
	ld   sp, 0x7fff
	jp   .core.__MAIN_PROGRAM__
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_a:
	DEFB 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_a)
	ld de, (_a)
	call .core.__DIVU16
	ld de, (_a)
	call .core.__DIVU16
	ld (_a), hl
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	halt
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/div16.asm"
	; 16 bit division and modulo functions
	; for both signed and unsigned values
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/neg16.asm"
	; Negates HL value (16 bit)
	    push namespace core
__ABS16:
	    bit 7, h
	    ret z
__NEGHL:
	    ld a, l			; HL = -HL
	    cpl
	    ld l, a
	    ld a, h
	    cpl
	    ld h, a
	    inc hl
	    ret
	    pop namespace
#line 5 "/zxbasic/src/lib/arch/zx48k/runtime/arith/div16.asm"
	    push namespace core
__DIVU16:    ; 16 bit unsigned division
	    ; HL = Dividend, Stack Top = Divisor
	    ;   -- OBSOLETE ; Now uses FASTCALL convention
	    ;   ex de, hl
	    ;	pop hl      ; Return address
	    ;	ex (sp), hl ; CALLEE Convention
__DIVU16_FAST:
	    ld a, h
	    ld c, l
	    ld hl, 0
	    ld b, 16
__DIV16LOOP:
	    sll c
	    rla
	    adc hl,hl
	    sbc hl,de
	    jr  nc, __DIV16NOADD
	    add hl,de
	    dec c
__DIV16NOADD:
	    djnz __DIV16LOOP
	    ex de, hl
	    ld h, a
	    ld l, c
	    ret     ; HL = quotient, DE = Mudulus
__MODU16:    ; 16 bit modulus
	    ; HL = Dividend, Stack Top = Divisor
	    ;ex de, hl
	    ;pop hl
	    ;ex (sp), hl ; CALLEE Convention
	    call __DIVU16_FAST
	    ex de, hl	; hl = reminder (modulus)
	    ; de = quotient
	    ret
__DIVI16:	; 16 bit signed division
	    ;	--- The following is OBSOLETE ---
	    ;	ex de, hl
	    ;	pop hl
	    ;	ex (sp), hl 	; CALLEE Convention
__DIVI16_FAST:
	    ld a, d
	    xor h
	    ex af, af'		; BIT 7 of a contains result
	    bit 7, d		; DE is negative?
	    jr z, __DIVI16A
	    ld a, e			; DE = -DE
	    cpl
	    ld e, a
	    ld a, d
	    cpl
	    ld d, a
	    inc de
__DIVI16A:
	    bit 7, h		; HL is negative?
	    call nz, __NEGHL
__DIVI16B:
	    call __DIVU16_FAST
	    ex af, af'
	    or a
	    ret p	; return if positive
	    jp __NEGHL
__MODI16:    ; 16 bit modulus
	    ; HL = Dividend, Stack Top = Divisor
	    ;ex de, hl
	    ;pop hl
	    ;ex (sp), hl ; CALLEE Convention
	    call __DIVI16_FAST
	    ex de, hl	; hl = reminder (modulus)
	    ; de = quotient
	    ret
	    pop namespace
#line 15 "arch/zx81sd/divi16a.bas"
	END
