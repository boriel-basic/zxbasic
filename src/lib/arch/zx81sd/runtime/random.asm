; RANDOM functions — ZX81 + SD81 Booster
; Adaptación de zx48k/runtime/random.asm:
;   - FRAMES usa el contador VSYNC software en SYSVAR_BASE+$19
;   - RANDOM_SEED_LOW en SYSVAR_BASE+$1B (en vez de sysvar Spectrum 23670)
;   - RANDOM_SEED_HIGH sigue siendo RAND+1 (operando inline de ld de,imm16)
;   - Sin cambios en el algoritmo RNG (xorshift)

#include once <sysvars.asm>

    push namespace core

RANDOMIZE:
    ; Randomize with 32 bit seed in DE HL
    ; if SEED = 0, uses FRAMES counter as seed
    PROC

    LOCAL TAKE_FRAMES

    ld a, h
    or l
    or d
    or e
    jr z, TAKE_FRAMES

    ld (RANDOM_SEED_LOW), hl
    ld (RANDOM_SEED_HIGH), de
    ret

TAKE_FRAMES:
    ; Toma la semilla del contador VSYNC (sustituye al contador de frames de la ROM)
    ld hl, (FRAMES)
    ld (RANDOM_SEED_LOW), hl
    ld hl, 0
    ld (RANDOM_SEED_HIGH), hl
    ret

    ENDP

RANDOM_SEED_HIGH EQU RAND + 1  ; Operando inline de ld de,imm16 (self-modifying seed)

RAND:
    PROC
    ld  de, 0C0DEh              ; yw → zt  (DE = semilla alta, se sobreescribe cada vez)
    ld  hl, (RANDOM_SEED_LOW)   ; xz → yw
    ld  (RANDOM_SEED_LOW), de   ; x = y, z = w
    ld  a, e                    ; w = w ^ (w << 3)
    add a, a
    add a, a
    add a, a
    xor e
    ld  e, a
    ld  a, h                    ; t = x ^ (x << 1)
    add a, a
    xor h
    ld  d, a
    rra                         ; t = t ^ (t >> 1) ^ w
    xor d
    xor e
    ld  d, l                    ; y = z
    ld  e, a                    ; w = t
    ld  (RANDOM_SEED_HIGH), de
    ret
    ENDP

RND:
    ; Returns a FLOATING point integer using RAND as mantissa
    PROC
    LOCAL RND_LOOP

    call RAND
    ld b, h
    ld c, l

    ld a, e
    or d
    or c
    or b
    ret z

    ld l, 81h
    ld a, e
RND_LOOP:
    dec l
    sla b
    rl c
    rl d
    rla
    jp nc, RND_LOOP

    ccf
    rra
    rr d
    rr c
    rr b

    ld e, a
    ld a, l
    ret

    ENDP

    pop namespace
