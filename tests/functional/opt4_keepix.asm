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
	call _test
	ld bc, 0
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
__CALL_BACK__:
	DEFW 0
_test:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	push hl
	push hl
	inc sp
	call RND
	push bc
	push de
	push af
	ld a, 083h
	ld de, 00020h
	ld bc, 00000h
	call __MULF
	ld hl, -5
	call __PSTOREF
	push ix
	pop hl
	ld de, -5
	add hl, de
	call __PLOADF
	push bc
	push de
	push af
	ld a, 081h
	ld de, 00000h
	ld bc, 00000h
	call __ADDF
	ld hl, -5
	call __PSTOREF
_test__leave:
	ld sp, ix
	pop ix
	ret
#line 1 "addf.asm"

#line 1 "stackf.asm"

	; -------------------------------------------------------------
	; Functions to manage FP-Stack of the ZX Spectrum ROM CALC
	; -------------------------------------------------------------


	__FPSTACK_PUSH EQU 2AB6h	; Stores an FP number into the ROM FP stack (A, ED CB)
	__FPSTACK_POP  EQU 2BF1h	; Pops an FP number out of the ROM FP stack (A, ED CB)

__FPSTACK_PUSH2: ; Pushes Current A ED CB registers and top of the stack on (SP + 4)
	                 ; Second argument to push into the stack calculator is popped out of the stack
	                 ; Since the caller routine also receives the parameters into the top of the stack
	                 ; four bytes must be removed from SP before pop them out

	    call __FPSTACK_PUSH ; Pushes A ED CB into the FP-STACK
	    exx
	    pop hl       ; Caller-Caller return addr
	    exx
	    pop hl       ; Caller return addr

	    pop af
	    pop de
	    pop bc

	    push hl      ; Caller return addr
	    exx
	    push hl      ; Caller-Caller return addr
	    exx

	    jp __FPSTACK_PUSH


__FPSTACK_I16:	; Pushes 16 bits integer in HL into the FP ROM STACK
					; This format is specified in the ZX 48K Manual
					; You can push a 16 bit signed integer as
					; 0 SS LL HH 0, being SS the sign and LL HH the low
					; and High byte respectively
		ld a, h
		rla			; sign to Carry
		sbc	a, a	; 0 if positive, FF if negative
		ld e, a
		ld d, l
		ld c, h
		xor a
		ld b, a
		jp __FPSTACK_PUSH
#line 2 "addf.asm"

	; -------------------------------------------------------------
	; Floating point library using the FP ROM Calculator (ZX 48K)
	; All of them uses A EDCB registers as 1st paramter.
	; For binary operators, the 2n operator must be pushed into the
	; stack, in the order AF DE BC (F not used).
	;
	; Uses CALLEE convention
	; -------------------------------------------------------------

__ADDF:	; Addition
		call __FPSTACK_PUSH2

		; ------------- ROM ADD
		rst 28h
		defb 0fh	; ADD
		defb 38h;   ; END CALC

		jp __FPSTACK_POP

#line 54 "opt4_keepix.bas"
#line 1 "mulf.asm"



	; -------------------------------------------------------------
	; Floating point library using the FP ROM Calculator (ZX 48K)
	; All of them uses A EDCB registers as 1st paramter.
	; For binary operators, the 2n operator must be pushed into the
	; stack, in the order A DE BC.
	;
	; Uses CALLEE convention
	; -------------------------------------------------------------

__MULF:	; Multiplication
		call __FPSTACK_PUSH2

		; ------------- ROM MUL
		rst 28h
		defb 04h	;
		defb 38h;   ; END CALC

		jp __FPSTACK_POP

#line 55 "opt4_keepix.bas"
#line 1 "ploadf.asm"

	; Parameter / Local var load
	; A => Offset
	; IX = Stack Frame
; RESULT: HL => IX + DE

#line 1 "iloadf.asm"

	; __FASTCALL__ routine which
	; loads a 40 bits floating point into A ED CB
	; stored at position pointed by POINTER HL
	;A DE, BC <-- ((HL))

__ILOADF:
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a

	; __FASTCALL__ routine which
	; loads a 40 bits floating point into A ED CB
	; stored at position pointed by POINTER HL
	;A DE, BC <-- (HL)

__LOADF:    ; Loads a 40 bits FP number from address pointed by HL
		ld a, (hl)
		inc hl
		ld e, (hl)
		inc hl
		ld d, (hl)
		inc hl
		ld c, (hl)
		inc hl
		ld b, (hl)
		ret

#line 7 "ploadf.asm"

__PLOADF:
	    push ix
	    pop hl
	    add hl, de
	    jp __LOADF

#line 56 "opt4_keepix.bas"
#line 1 "pstoref.asm"

	; Stores FP number in A ED CB at location HL+IX
	; HL = Offset
	; IX = Stack Frame
	; A ED CB = FP Number

#line 1 "storef.asm"

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

#line 7 "pstoref.asm"

	; Stored a float number in A ED CB into the address pointed by IX + HL
__PSTOREF:
		push de
	    ex de, hl  ; DE <- HL
	    push ix
		pop hl	   ; HL <- IX
	    add hl, de ; HL <- IX + DE
		pop de
	    jp __STOREF

#line 57 "opt4_keepix.bas"
#line 1 "random.asm"

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

#line 58 "opt4_keepix.bas"

ZXBASIC_USER_DATA:
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
