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
	ld a, (_b)
	ld l, a
	ld h, 0
	push hl
	ld hl, _a
	call __ARRAY
	ld a, (_b)
	ld (hl), a
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
	
#line 15 "array.asm"
	
#line 19 "/home/boriel/src/zxb/trunk/library-asm/array.asm"
	
__ARRAY:
		PROC
	
		LOCAL LOOP
		LOCAL ARRAY_END
		LOCAL RET_ADDRESS ; Stores return address
	
		pop de		; Return address
		ld (RET_ADDRESS), de ; Stores it for later
	
		push hl		; Indexes pointer goes to H'L'
		exx
		pop hl		; Will use H'L' as the pointer
		ld c, (hl)	; Loads Number of dimensions from (hl)
		inc hl
		ld b, (hl)
		inc hl		; Ready
		exx
			
		ld hl, 0	; BC = Offset "accumulator"
	
#line 44 "/home/boriel/src/zxb/trunk/library-asm/array.asm"
	
LOOP:
		pop bc		; Get next index (Ai) from the stack
	
#line 56 "/home/boriel/src/zxb/trunk/library-asm/array.asm"
	
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
	
#line 76 "/home/boriel/src/zxb/trunk/library-asm/array.asm"
		;call __MUL16_FAST	; HL *= DE
	    call __FNMUL
#line 82 "/home/boriel/src/zxb/trunk/library-asm/array.asm"
		jp LOOP
		
ARRAY_END:
		ld e, (hl)
		inc hl
		ld d, c			; C = 0 => DE = E = Element size
		push hl
		push de
		exx
	
#line 96 "/home/boriel/src/zxb/trunk/library-asm/array.asm"
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
#line 127 "/home/boriel/src/zxb/trunk/library-asm/array.asm"
	
		pop de
		add hl, de  ; Adds element start
	
		ld de, (RET_ADDRESS)
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
	
	RET_ADDRESS	EQU	23563	; DEFADD variable. 
	
		ENDP
		
#line 26 "array03.bas"
	
ZXBASIC_USER_DATA:
_b:
	DEFB 00
_a:
	DEFW 0000h
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
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
