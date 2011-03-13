; (K)opyleft - by Jose M. Rodriguez de la Rosa (a.k.a. Boriel)
; 2009 - This is Free OpenSource BSD code
; vim: et:ts=4:sw=4

; Copies a vector of strings from one place to another
; reallocating strings of the destiny vector to hold source strings.
; This is used in the following code:
; DIM a$(20) : DIM b$(20): a$ = b$

#include once <lddede.asm>
#include once <strcpy.asm>

STR_ARRAYCOPY:
; Copies an array of string a$ = b$
; Parameters in the stack:
; a$, b$, num. of elements;
    pop hl  ; ret address
    pop bc  ; num of elements
    pop de  ; source array + offset to the 1st elem.
    ex (sp), hl ; Calle -> hl = destiny array + offset to the 1st elem.

; FASTCALL ENTRY

; HL = a$ + offset
; DE = b$ + offset
; BC = Number of elements

__STR_ARRAYCOPY:
    PROC
    LOCAL LOOP

LOOP:
    ld a, b
    or c
    ret z ; Done!

    dec bc
    push bc
    push de

    ld a,(hl)
    inc hl
    ld c,(hl)
    dec hl
    push hl

    ld h, c
    ld l, a
    call __LOAD_DE_DE
    call __STRASSIGN

    ex de, hl
    pop hl
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    pop de
    pop bc
    inc de
    inc de
    jp LOOP

    ENDP


