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
_a:
	DEFB 00, 00, 00, 00, 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld de, 0
	ld hl, 0
	call RANDOMIZE
	call RND
	ld hl, _a
	call __STOREF
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/random.asm"
	; RANDOM functions
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
	RANDOM_SEED_HIGH EQU RAND+6 ; RANDOM seed, 16 higher bits
	RANDOM_SEED_LOW  EQU 23670  ; RANDOM seed, 16 lower bits
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
	    ld  d,l         ; y = z
	    ld  e,a         ; w = t
	    ld  (RANDOM_SEED_HIGH),de
	    push af
	    djnz RAND_LOOP
	    pop de
	    pop af
	    ld e, a
	    pop hl
	    pop af
	    ld l, a
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
	    ld l, 81h    ; Exponent
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
#line 23 "rnd.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/storef.asm"
__PISTOREF:	; Indect Stores a float (A, E, D, C, B) at location stored in memory, pointed by (IX + HL)
			push de
			ex de, hl	; DE <- HL
			push ix
			pop hl		; HL <- IX
			add hl, de  ; HL <- IX + HL
			pop de
__ISTOREF:  ; Load address at hl, and stores A,E,D,C,B registers at that address. Modifies A' register
	        ex af, af'
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a     ; HL = (HL)
	        ex af, af'
__STOREF:	; Stores the given FP number in A EDCB at address HL
			ld (hl), a
			inc hl
			ld (hl), e
			inc hl
			ld (hl), d
			inc hl
			ld (hl), c
			inc hl
			ld (hl), b
			ret
#line 24 "rnd.bas"
	END
