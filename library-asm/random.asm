; RANDOM functions

#include once <mul32.asm>

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

FRAMES EQU	23672
	ENDP

RANDOM_SEED_HIGH:	; RANDOM seed, 16 higher bits
	DEFW 0000h		; HIGH RANDOM SEED

RANDOM_SEED_LOW 	EQU 23670	; RANDOM seed, 16 lower bits


RAND:
	; Returns a 32 bit random integer based on seed.
	; This is a very fast and interesting generator
	; See Numerical Recipes, 2nd ED

	ld de, 25
	ld hl, 26125
	push de
	push hl		; PUSH 32bit value 1664525

	ld de, (RANDOM_SEED_HIGH)
	ld hl, (RANDOM_SEED_LOW)
	call __MUL32	; DE HL = 166425 * SEED

	ld bc, 62303	; DEHL = 1013904223 = 15470 * 65536 + 62303
	add hl, bc
	ld (RANDOM_SEED_LOW), hl

	ex de, hl
	ld bc, 15470
	adc hl, bc
	ld (RANDOM_SEED_HIGH), hl
	ex de, hl
	ret

RND:
	; Returns a FLOATING point integer
	; using RAND as a mantissa
	PROC
	LOCAL RND_LOOP
	LOCAL RND_END

	call RAND	
	ld a, d	
	or e
	or h
	or l
    ld b, h
	ld c, l
	ret z		; Return 0 if 0

	; We already have a random 32 bit mantissa in ED CB
	ld l, 81h	; Exponent
	set 7, e	; Recover highest mantissa bit
	; At this point we have 1 .. 2) FP number;
	; We subtract 1 to obtain the 0..1) Range

	; To subtract 1, we only have to subtract the highest byte (40h)
	ld a, e
	sub	40h
	ld e, a

	; Now we must shift left until highest bit is 1
RND_LOOP:
	dec l
	sla b
	rl c
	rl d
	rla
	jp p, RND_LOOP	; Loop if bit 7 is not one

RND_END:
	and 7Fh		; Clear highest bit (positive sign)
	ld e, a
    ld a, l     ; saves exponent in A
	ret

	ENDP

