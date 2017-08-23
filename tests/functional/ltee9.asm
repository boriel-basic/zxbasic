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
__LABEL__UDGS:
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
_start:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	push hl
	ld hl, __LABEL__UDGS
	ld (_x), hl
	ld hl, (__LABEL__UDGS) / (256)
	ld (_x), hl
	ld hl, (((__LABEL__UDGS) / (256)) & 0xFFFFFFFF) & 0xFFFF
	ld (_x), hl
__LABEL__UDGS:
	ld hl, (__LABEL__UDGS)
	ld de, 0
	push de
	push hl
	ld hl, ((((__LABEL__UDGS) / (256)) & 0xFFFFFFFF) * (256)) & 0xFFFF
	ld de, ((((__LABEL__UDGS) / (256)) & 0xFFFFFFFF) * (256)) >> 16
	call __SUB32
	ld (_x), hl
	ld hl, (((__LABEL__UDGS) & 0xFFFFFFFF) - ((((__LABEL__UDGS) / (256)) & 0xFFFFFFFF) * (256))) & 0xFFFF
	ld de, (((__LABEL__UDGS) & 0xFFFFFFFF) - ((((__LABEL__UDGS) / (256)) & 0xFFFFFFFF) * (256))) >> 16
	ld bc, -4
	call __PSTORE32
	ld hl, (_x)
	ld de, 256
	call __DIVU16
	ld (_x), hl
	ld de, 256
	call __DIVU16
	ld de, 0
	ld (_x), hl
	ld de, 0
	push de
	push hl
	ld hl, (_x)
	ld de, 256
	call __DIVU16
	ld de, 0
	push de
	push hl
	ld de, 0
	ld hl, 256
	call __MUL32
	call __SUB32
	ld (_x), hl
	ld de, 0
	push de
	push hl
	ld hl, (_x)
	ld de, 256
	call __DIVU16
	ld de, 0
	push de
	push hl
	ld de, 0
	ld hl, 256
	call __MUL32
	call __SUB32
	ld (_x), hl
_start__leave:
	ld sp, ix
	pop ix
	ret
#line 1 "div16.asm"
	; 16 bit division and modulo functions 
	; for both signed and unsigned values
	
#line 1 "neg16.asm"
	; Negates HL value (16 bit)
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
	
#line 5 "div16.asm"
	
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
	
#line 85 "ltee9.bas"
#line 1 "mul32.asm"
#line 1 "_mul32.asm"
	
; Ripped from: http://www.andreadrian.de/oldcpu/z80_number_cruncher.html#moztocid784223
	; Used with permission.
	; Multiplies 32x32 bit integer (DEHL x D'E'H'L')
	; 64bit result is returned in H'L'H L B'C'A C
	
	
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
	        and     a               ; reset carry flag
	        sbc     hl,hl           ; result bits 32..47 = 0
	        exx
	        sbc     hl,hl           ; result bits 48..63 = 0
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
	       
#line 2 "mul32.asm"
	
__MUL32:	; multiplies 32 bit un/signed integer.
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
	
	
#line 86 "ltee9.bas"
#line 1 "pstore32.asm"
#line 1 "store32.asm"
__PISTORE32:
			push hl
			push ix
			pop hl
			add hl, bc
			pop bc
	
__ISTORE32:  ; Load address at hl, and stores E,D,B,C integer at that address
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
	
__STORE32:	; Stores the given integer in DEBC at address HL
			ld (hl), c
			inc hl
			ld (hl), b
			inc hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret
			
#line 2 "pstore32.asm"
	
	; Stores a 32 bit integer number (DE,HL) at (IX + BC)
__PSTORE32:
			push hl
			push ix
			pop hl
			add hl, bc
			pop bc
			jp __STORE32
#line 87 "ltee9.bas"
#line 1 "sub32.asm"
	; SUB32 
	; Perform TOP of the stack - DEHL
	; Pops operand out of the stack (CALLEE)
	; and returns result in DEHL. Carry an Z are set correctly
	
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
#line 88 "ltee9.bas"
	
ZXBASIC_USER_DATA:
_x:
	DEFB 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
