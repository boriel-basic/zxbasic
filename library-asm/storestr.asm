; vim:ts=4:et:sw=4
; Stores value of current string pointed by DE register into address pointed by HL
; Returns DE = Address pointer  (&a$)
; Returns HL = HL               (b$ => might be needed later to free it from the heap)
;
; e.g. => HL = _variableName    (DIM _variableName$)
;         DE = Address into the HEAP
;
; This function will resize (REALLOC) the space pointed by HL
; before copying the content of b$ into a$


#include once <strcpy.asm>

__PISTORE_STR:          ; Indirect assignement at (IX + BC)
    push ix
    pop hl
    add hl, bc

__ISTORE_STR:           ; Indirect assignement, hl point to a pointer to a pointer to the heap!
    ld c, (hl)
    inc hl
    ld h, (hl)
    ld l, c             ; HL = (HL)

__STORE_STR:
    push de             ; Pointer to b$
    push hl             ; Array pointer to variable memory address

    ld c, (hl)
    inc hl
    ld h, (hl)
    ld l, c             ; HL = (HL)

    call __STRASSIGN    ; HL (a$) = DE (b$); HL changed to a new dynamic memory allocation
    ex de, hl           ; DE = new address of a$
    pop hl              ; Recover variable memory address pointer

    ld (hl), e
    inc hl
    ld (hl), d          ; Stores a$ ptr into elemem ptr

    pop hl              ; Returns ptr to b$ in HL (Caller might needed to free it from memory)
    ret

