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
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_y:
	DEFB 00
_x:
	DEFW __LABEL7
_x.__DATA__.__PTR__:
	DEFW _x.__DATA__
	DEFW _x.__LBOUND__
	DEFW _x.__UBOUND__
_x.__DATA__:
	DEFB 01h
	DEFB 02h
	DEFB 03h
	DEFB 04h
	DEFB 05h
__LABEL7:
	DEFW 0000h
	DEFB 01h
_x.__LBOUND__:
	DEFW 0000h
_x.__UBOUND__:
	DEFW 0004h
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, _x
	push hl
	call _maxValue
	ld (_y), a
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
_maxValue:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	push hl
	inc sp
	ld hl, 1
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	call __LBOUND
	ld (ix-3), l
	ld (ix-2), h
	jp __LABEL0
__LABEL3:
	ld a, (ix-1)
	push af
	ld l, (ix-3)
	ld h, (ix-2)
	push hl
	push ix
	pop hl
	ld de, 4
	add hl, de
	call __ARRAY_PTR
	pop af
	cp (hl)
	jp nc, __LABEL6
	ld l, (ix-3)
	ld h, (ix-2)
	push hl
	push ix
	pop hl
	ld de, 4
	add hl, de
	call __ARRAY_PTR
	ld a, (hl)
	ld (ix-1), a
__LABEL6:
__LABEL4:
	ld l, (ix-3)
	ld h, (ix-2)
	inc hl
	ld (ix-3), l
	ld (ix-2), h
__LABEL0:
	ld l, (ix-3)
	ld h, (ix-2)
	push hl
	ld hl, 1
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	call __UBOUND
	pop de
	or a
	sbc hl, de
	jp nc, __LABEL3
__LABEL2:
	ld a, (ix-1)
_maxValue__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
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
#line 20 "array.asm"
#line 24 "/zxbasic/arch/zx48k/library-asm/array.asm"
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
#line 62 "/zxbasic/arch/zx48k/library-asm/array.asm"
		pop bc		; Get next index (Ai) from the stack
#line 72 "/zxbasic/arch/zx48k/library-asm/array.asm"
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
#line 101 "/zxbasic/arch/zx48k/library-asm/array.asm"
	    LOCAL ARRAY_SIZE_LOOP
	    ex de, hl
	    ld hl, 0
	    ld b, a
ARRAY_SIZE_LOOP:
	    add hl, de
	    djnz ARRAY_SIZE_LOOP
#line 111 "/zxbasic/arch/zx48k/library-asm/array.asm"
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
#line 92 "lbound13.bas"
#line 1 "bound.asm"
	; ---------------------------------------------------------
	; Copyleft (k)2011 by Jose Rodriguez (a.k.a. Boriel)
; http://www.boriel.com
	;
; ZX BASIC Compiler http://www.zxbasic.net
	; This code is released under the BSD License
	; ---------------------------------------------------------
	; Implements both LBOUND(array, N) and UBOUND(array, N) function
; Parameters:
	; HL = PTR to array
	; [stack - 2] -> N (dimension)
	    PROC
	    LOCAL __BOUND
	    LOCAL __DIM_NOT_EXIST
	    LOCAL __CONT
__LBOUND:
	    ld a, 4
	    jr __BOUND
__UBOUND:
	    ld a, 6
__BOUND:
	    ex de, hl       ; DE <-- Array ptr
	    pop hl          ; HL <-- Ret address
    ex (sp), hl     ; CALLEE: HL <-- N, (SP) <-- Ret address
	    ex de, hl       ; DE <-- N, HL <-- ARRAY_PTR
	    push hl
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c         ; HL = start of dimension table (first position contains number of dimensions - 1)
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    inc bc          ; Number of total dimensions of the array
	    pop hl          ; Recovers ARRAY PTR
	    ex af, af'      ; Saves A for later
	    ld a, d
	    or e
	    jr nz, __CONT   ; N = 0 => Return number of dimensions
	    ;; Return the number of dimensions of the array
	    ld h, b
	    ld l, c
	    ret
__CONT:
	    dec de
	    ex af, af'      ; Recovers A (contains PTR offset)
	    ex de, hl       ; HL = N (dimension asked) - 1, DE = Array PTR
	    or a
	    sbc hl, bc      ; if no Carry => the user asked for a dimension that does not exist. Return 0
	    jr nc, __DIM_NOT_EXIST
	    add hl, bc      ; restores HL = (N - 1)
	    add hl, hl      ; hl *= 2
	    ex de, hl       ; hl = ARRAY_PTR + 3, DE jsz = (N - 1) * 2
	    ld b, 0
	    ld c, a
	    add hl, bc      ; HL = &BOUND_PTR
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a         ; LD HL, (HL) => Origin of L/U Bound table
	    add hl, de      ; hl += OFFSET __LBOUND._xxxx
	    ld e, (hl)      ; de = (hl)
	    inc hl
	    ld d, (hl)
	    ex de, hl       ; hl = de => returns result in HL
	    ret
__DIM_NOT_EXIST:
	;   The dimension requested by the user does not exists. Return 0
	    ld hl, 0
	    ret
	    ENDP
#line 93 "lbound13.bas"
	END
