	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	ld hl, (_b)
	push hl
	ld hl, 5
	push hl
	ld hl, (_b)
	push hl
	ld hl, 10
	push hl
	ld hl, _a
	call __ARRAY
	ld (hl), 7
	ld hl, (_b)
	push hl
	ld hl, 5
	push hl
	ld hl, (_b)
	ld de, 6
	add hl, de
	push hl
	ld hl, 10
	push hl
	ld hl, _a
	call __ARRAY
	ld a, (hl)
	ld (_c), a
	ld (_c), a
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
#line 1 "array.asm"

; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	; -------------------------------------------------------------------
	; Simple array Index routine
	; Number of total indexes dimensions - 1 at beginning of memory
	; HL = Start of array memory (First two bytes contains N-1 dimensions)
	; Dimension values on the stack, (top of the stack, highest dimension)
	; E.g. A(2, 4) -> PUSH <4>; PUSH <2>

	; For any array of N dimension A(aN-1, ..., a1, a0)
	; and dimensions D[bN-1, ..., b1, b0], the offset is calculated as
	; O = [a0 + b0 * (a1 + b1 * (a2 + ... bN-2(aN-1)))]
; What I will do here is to calculate the following sequence:
	; ((aN-1 * bN-2) + aN-2) * bN-3 + ...


#line 1 "mul16.asm"

__MUL16:	; Mutiplies HL with the last value stored into de stack
				; Works for both signed and unsigned

			PROC

			LOCAL __MUL16LOOP
	        LOCAL __MUL16NOADD

			ex de, hl
			pop hl		; Return address
			ex (sp), hl ; CALLEE caller convention

;;__MUL16_FAST:	; __FASTCALL ENTRY: HL = 1st operand, DE = 2nd Operand
	;;		ld c, h
	;;		ld a, l	 ; C,A => 1st Operand
	;;
	;;		ld hl, 0 ; Accumulator
	;;		ld b, 16
	;;
;;__MUL16LOOP:
	;;		sra c	; C,A >> 1  (Arithmetic)
	;;		rra
	;;
	;;		jr nc, __MUL16NOADD
	;;		add hl, de
	;;
;;__MUL16NOADD:
	;;		sla e
	;;		rl d
	;;
	;;		djnz __MUL16LOOP

__MUL16_FAST:
	        ld b, 16
	        ld a, d
	        ld c, e
	        ex de, hl
	        ld hl, 0

__MUL16LOOP:
	        add hl, hl  ; hl << 1
	        sla c
	        rla         ; a,c << 1
	        jp nc, __MUL16NOADD
	        add hl, de

__MUL16NOADD:
	        djnz __MUL16LOOP

			ret	; Result in hl (16 lower bits)

			ENDP

#line 20 "array.asm"


#line 1 "error.asm"

	; Simple error control routines
; vim:ts=4:et:

	ERR_NR    EQU    23610    ; Error code system variable


	; Error code definitions (as in ZX spectrum manual)

; Set error code with:
	;    ld a, ERROR_CODE
	;    ld (ERR_NR), a


	ERROR_Ok                EQU    -1
	ERROR_SubscriptWrong    EQU     2
	ERROR_OutOfMemory       EQU     3
	ERROR_OutOfScreen       EQU     4
	ERROR_NumberTooBig      EQU     5
	ERROR_InvalidArg        EQU     9
	ERROR_IntOutOfRange     EQU    10
	ERROR_NonsenseInBasic   EQU    11
	ERROR_InvalidFileName   EQU    14
	ERROR_InvalidColour     EQU    19
	ERROR_BreakIntoProgram  EQU    20
	ERROR_TapeLoadingErr    EQU    26


	; Raises error using RST #8
__ERROR:
	    ld (__ERROR_CODE), a
	    rst 8
__ERROR_CODE:
	    nop
	    ret

	; Sets the error system variable, but keeps running.
	; Usually this instruction if followed by the END intermediate instruction.
__STOP:
	    ld (ERR_NR), a
	    ret
#line 23 "array.asm"
#line 24 "/Users/boriel/Documents/src/zxbasic/zxbasic/library-asm/array.asm"

__ARRAY:
		PROC

		LOCAL LOOP
		LOCAL ARRAY_END
		LOCAL RET_ADDRESS ; Stores return address

		ex (sp), hl	; Return address in HL, array address in the stack
		ld (RET_ADDRESS + 1), hl ; Stores it for later

		exx
		pop hl		; Will use H'L' as the pointer
		ld c, (hl)	; Loads Number of dimensions from (hl)
		inc hl
		ld b, (hl)
		inc hl		; Ready
		exx

		ld hl, 0	; BC = Offset "accumulator"

LOOP:

	    pop de
#line 49 "/Users/boriel/Documents/src/zxbasic/zxbasic/library-asm/array.asm"
		pop bc		; Get next index (Ai) from the stack


	    ex de, hl
	    or a
	    sbc hl, bc
	    ld a, ERROR_SubscriptWrong
	    jp c, __ERROR
	    ex de, hl
#line 59 "/Users/boriel/Documents/src/zxbasic/zxbasic/library-asm/array.asm"

		add hl, bc	; Adds current index

		exx			; Checks if B'C' = 0
		ld a, b		; Which means we must exit (last element is not multiplied by anything)
		or c
		jr z, ARRAY_END		; if B'Ci == 0 we are done

		ld e, (hl)			; Loads next dimension into D'E'
		inc hl
		ld d, (hl)
		inc hl
		push de
		dec bc				; Decrements loop counter
		exx
		pop de				; DE = Max bound Number (i-th dimension)

		;call __MUL16_FAST	; HL *= DE
	    call __FNMUL
		jp LOOP

ARRAY_END:
		ld e, (hl)
		inc hl
		ld d, c			; C = 0 => DE = E = Element size
		push hl
		push de
		exx

#line 92 "/Users/boriel/Documents/src/zxbasic/zxbasic/library-asm/array.asm"
	    LOCAL ARRAY_SIZE_LOOP

	    ex de, hl
	    ld hl, 0
	    pop bc
	    ld b, c
ARRAY_SIZE_LOOP:
	    add hl, de
	    djnz ARRAY_SIZE_LOOP

	    ;; Even faster
	    ;pop bc

	    ;ld d, h
	    ;ld e, l

	    ;dec c
	    ;jp z, __ARRAY_FIN

	    ;add hl, hl
	    ;dec c
	    ;jp z, __ARRAY_FIN

	    ;add hl, hl
	    ;dec c
	    ;dec c
	    ;jp z, __ARRAY_FIN

	    ;add hl, de
    ;__ARRAY_FIN:
#line 123 "/Users/boriel/Documents/src/zxbasic/zxbasic/library-asm/array.asm"

		pop de
		add hl, de  ; Adds element start

RET_ADDRESS:
		ld de, 0
		push de
		ret			; HL = (Start of Elements + Offset)

	    ;; Performs a faster multiply for little 16bit numbs
	    LOCAL __FNMUL, __FNMUL2

__FNMUL:
	    xor a
	    or d
	    jp nz, __MUL16_FAST

	    or e
	    ex de, hl
	    ret z

	    cp 33
	    jp nc, __MUL16_FAST

	    ld b, l
	    ld l, h  ; HL = 0

__FNMUL2:
	    add hl, de
	    djnz __FNMUL2
	    ret

		ENDP

#line 44 "arrcheck.bas"

ZXBASIC_USER_DATA:
_c:
	DEFB 00
_b:
	DEFB 05h
	DEFB 00h
_a:
	DEFW 0001h
	DEFW 0006h
	DEFB 01h
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
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
