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
	jp __MAIN_PROGRAM__
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_b:
	DEFB 00, 00
_a:
	DEFW __LABEL0
_a.__DATA__.__PTR__:
	DEFW _a.__DATA__
_a.__DATA__:
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
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, (_b)
	push hl
	ld hl, _a
	call __ARRAY
	ld de, (_b)
	ld (hl), e
	inc hl
	ld (hl), d
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
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/mul16.asm"
__MUL16:	; Mutiplies HL with the last value stored into de stack
				; Works for both signed and unsigned
			PROC
			LOCAL __MUL16LOOP
	        LOCAL __MUL16NOADD
			ex de, hl
			pop hl		; Return address
			ex (sp), hl ; CALLEE caller convention
__MUL16_FAST:
	        ld b, 16
	        ld a, h
	        ld c, l
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
#line 20 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
#line 24 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
__ARRAY_PTR:   ;; computes an array offset from a pointer
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c
__ARRAY:
		PROC
		LOCAL LOOP
		LOCAL ARRAY_END
		LOCAL RET_ADDRESS ; Stores return address
		LOCAL TMP_ARR_PTR ; Stores pointer temporarily
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld (TMP_ARR_PTR), hl
	    ex de, hl
		ex (sp), hl	; Return address in HL, array address in the stack
		ld (RET_ADDRESS + 1), hl ; Stores it for later
		exx
		pop hl		; Will use H'L' as the pointer
		ld c, (hl)	; Loads Number of dimensions from (hl)
		inc hl
		ld b, (hl)
		inc hl		; Ready
		exx
		ld hl, 0	; HL = Offset "accumulator"
LOOP:
#line 62 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
		pop bc		; Get next index (Ai) from the stack
#line 72 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
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
	    call __FNMUL
		jp LOOP
ARRAY_END:
		ld a, (hl)
		exx
#line 101 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
	    LOCAL ARRAY_SIZE_LOOP
	    ex de, hl
	    ld hl, 0
	    ld b, a
ARRAY_SIZE_LOOP:
	    add hl, de
	    djnz ARRAY_SIZE_LOOP
#line 111 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
	    ex de, hl
		ld hl, (TMP_ARR_PTR)
		ld a, (hl)
		inc hl
		ld h, (hl)
		ld l, a
		add hl, de  ; Adds element start
RET_ADDRESS:
		jp 0
	    ;; Performs a faster multiply for little 16bit numbs
	    LOCAL __FNMUL, __FNMUL2
__FNMUL:
	    xor a
	    or h
	    jp nz, __MUL16_FAST
	    or l
	    ret z
	    cp 33
	    jp nc, __MUL16_FAST
	    ld b, l
	    ld l, h  ; HL = 0
__FNMUL2:
	    add hl, de
	    djnz __FNMUL2
	    ret
TMP_ARR_PTR:
	    DW 0  ; temporary storage for pointer to tables
		ENDP
#line 25 "array06.bas"
	END
