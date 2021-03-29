	org 32768
core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (core.__CALL_BACK__), hl
	ei
	jp core.__MAIN_PROGRAM__
core.__CALL_BACK__:
	DEFW 0
core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
core.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_END - core.ZXBASIC_USER_DATA
	core..__LABEL__.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_LEN
	core..__LABEL__.ZXBASIC_USER_DATA EQU core.ZXBASIC_USER_DATA
_monsterx:
	DEFB 00
_tiles:
	DEFW __LABEL0
_tiles.__DATA__.__PTR__:
	DEFW _tiles.__DATA__
_tiles.__DATA__:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
__LABEL0:
	DEFW 0000h
	DEFB 02h
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
	ld hl, __LABEL__void
	ld (_tiles.__DATA__ + 0), hl
	ld (_tiles.__DATA__ + 2), hl
__LABEL__void:
	xor a
	push af
	xor a
	push af
	xor a
	push af
	call _settile
	ld hl, 0
	ld b, h
	ld c, l
core.__END_PROGRAM:
	di
	ld hl, (core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
_putChars:
	push ix
	ld ix, 0
	add ix, sp
_putChars__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
_settile:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, __LABEL__void
	push hl
	ld a, 3
	push af
	ld a, 3
	push af
	ld a, (_monsterx)
	ld h, 3
	call core.__MUL8_FAST
	ld l, a
	add a, a
	sbc a, a
	ld h, a
	push hl
	ld a, (_monsterx)
	ld h, 3
	call core.__MUL8_FAST
	ld l, a
	add a, a
	sbc a, a
	ld h, a
	push hl
	call _putChars
_settile__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/mul8.asm"
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
#line 81 "lcd_crash.bas"
	END
