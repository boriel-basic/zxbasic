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
	ld de, 0
	ld hl, 0
	call RANDOMIZE
	ld de, 0
	ld hl, 32
	call RANDOMIZE
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
#line 1 "random.asm"
	; RANDOM functions
	
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
	
	
#line 4 "random.asm"
	
RANDOMIZE:
	    ; Randomize with 32 bit seed in DE HL
	    ; if SEED = 0, calls ROM to take frames as seed
	    PROC
	
	    LOCAL TAKE_FRAMES
	    LOCAL FRAMES
	    
	    ld a, h
	    or l
	    or d
	    or e
	    jr z, TAKE_FRAMES
	
	    ld (RANDOM_SEED_LOW), hl
	    ld (RANDOM_SEED_HIGH), de
	    ret
	
TAKE_FRAMES:
	    ; Takes the seed from frames
	    ld hl, (FRAMES)
	    ld (RANDOM_SEED_LOW), hl
	    ld hl, (FRAMES + 2)
	    ld (RANDOM_SEED_HIGH), hl
	    ret
	
	FRAMES EQU    23672
	    ENDP
	
	RANDOM_SEED_HIGH EQU RAND+6    ; RANDOM seed, 16 higher bits
	RANDOM_SEED_LOW     EQU 23670  ; RANDOM seed, 16 lower bits
	
	
RAND:
	    PROC
	    LOCAL RAND_LOOP
	    ld b, 4 
RAND_LOOP:
	    ld  hl,(RANDOM_SEED_LOW)   ; xz -> yw
	    ld  de,0C0DEh   ; yw -> zt
	    ld  (RANDOM_SEED_LOW),de  ; x = y, z = w
	    ld  a,e         ; w = w ^ ( w << 3 )
	    add a,a
	    add a,a
	    add a,a
	    xor e
	    ld  e,a
	    ld  a,h         ; t = x ^ (x << 1)
	    add a,a
	    xor h
	    ld  d,a
	    rra             ; t = t ^ (t >> 1) ^ w
	    xor d
	    xor e
	    ld  h,l         ; y = z
	    ld  l,a         ; w = t
	    ld  (RANDOM_SEED_HIGH),hl
	    push af
	    djnz RAND_LOOP
	    pop af
	    pop af
	    ld d, a
	    pop af
	    ld e, a
	    pop af
	    ld h, a
	    ret
	    ENDP
	
RND:
	    ; Returns a FLOATING point integer
	    ; using RAND as a mantissa
	    PROC
	    LOCAL RND_LOOP
	
	    call RAND
	    ; BC = HL since ZX BASIC uses ED CB A registers for FP
	    ld b, h
	    ld c, l
	
	    ld a, e
	    or d
	    or c
	    or b
	    ret z   ; Returns 0 if BC=DE=0
	
	    ; We already have a random 32 bit mantissa in ED CB
	    ; From 0001h to FFFFh
	
	    ld l, 81h	; Exponent
	    ; At this point we have [0 .. 1) FP number;
	
	    ; Now we must shift mantissa left until highest bit goes into carry
	    ld a, e ; Use A register for rotating E faster (using RLA instead of RL E)
RND_LOOP:
	    dec l
	    sla b
	    rl c
	    rl d
	    rla
	    jp nc, RND_LOOP
	
	    ; Now undo last mantissa left-shift once
	    ccf ; Clears carry to insert a 0 bit back into mantissa -> positive FP number
	    rra
	    rr d   
	    rr c
	    rr b
	    
	    ld e, a     ; E must have the highest byte
	    ld a, l     ; exponent in A
	    ret
	
	    ENDP
	
#line 24 "randomize.bas"
	
ZXBASIC_USER_DATA:
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
