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
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_a - 1)
	ld a, (_a)
	call .core.__MUL8_FAST
	push af
	ld a, (_a)
	add a, a
	ld h, a
	ld a, (_a)
	call .core.__MUL8_FAST
	ld h, a
	pop af
	call .core.__MUL8_FAST
	ld (_a), a
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	halt
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/mul8.asm"
	    push namespace core
__MUL8:		; Performs 8bit x 8bit multiplication
	    PROC
	    ;LOCAL __MUL8A
	    LOCAL __MUL8LOOP
	    LOCAL __MUL8B
	    ; 1st operand (byte) in A, 2nd operand into the stack (AF)
	    pop hl	; return address
	    ex (sp), hl ; CALLE convention
;;__MUL8_FAST: ; __FASTCALL__ entry
	;;	ld e, a
	;;	ld d, 0
	;;	ld l, d
	;;
	;;	sla h
	;;	jr nc, __MUL8A
	;;	ld l, e
	;;
;;__MUL8A:
	;;
	;;	ld b, 7
;;__MUL8LOOP:
	;;	add hl, hl
	;;	jr nc, __MUL8B
	;;
	;;	add hl, de
	;;
;;__MUL8B:
	;;	djnz __MUL8LOOP
	;;
	;;	ld a, l ; result = A and HL  (Truncate to lower 8 bits)
__MUL8_FAST: ; __FASTCALL__ entry, a = a * h (8 bit mul) and Carry
	    ld b, 8
	    ld l, a
	    xor a
__MUL8LOOP:
	    add a, a ; a *= 2
	    sla l
	    jp nc, __MUL8B
	    add a, h
__MUL8B:
	    djnz __MUL8LOOP
	    ret		; result = HL
	    ENDP
	    pop namespace
#line 22 "arch/zx81sd/mul8b.bas"
	END
