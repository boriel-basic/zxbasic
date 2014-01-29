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

