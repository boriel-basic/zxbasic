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
_dataSprite:
	DEFB 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, 4
	ld (31744), a
	ld hl, (_dataSprite)
	ld (hl), 83
	ld de, 11
	add hl, de
	push hl
	ld hl, (_dataSprite)
	ld de, 4
	add hl, de
	ld a, (hl)
	ld h, 6
	call .core.__MUL8_FAST
	pop hl
	ld (hl), a
	ld hl, (_dataSprite)
	ld de, 12
	add hl, de
	push hl
	ld hl, (_dataSprite)
	ld de, 5
	add hl, de
	ld a, (hl)
	pop hl
	add a, a
	add a, a
	ld (hl), a
	ld hl, (_dataSprite)
	ld de, 17
	add hl, de
	ld de, 56978
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (_dataSprite)
	ld de, 30
	add hl, de
	push hl
	ld hl, (_dataSprite)
	ld de, 8
	add hl, de
	ld a, (hl)
	pop hl
	ld (hl), a
	ld hl, 0
	ld (31748), hl
	ld hl, (_dataSprite)
	ld de, 6
	add hl, de
	xor a
	ld (hl), a
	ld hl, (_dataSprite)
	inc de
	add hl, de
	ld (hl), a
	ld hl, (_dataSprite)
	inc de
	add hl, de
	ld (hl), a
	ld hl, (_dataSprite)
	ld de, 21
	add hl, de
	ld (hl), a
	ld hl, (_dataSprite)
	inc de
	add hl, de
	ld (hl), a
	ld hl, (_dataSprite)
	inc de
	add hl, de
	ld (hl), a
	ld hl, (_dataSprite)
	inc de
	add hl, de
	ld (hl), a
	ld bc, 0
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
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
#line 90 "arch/zx48k/opt3_haplo05.bas"
	END
