; ---------------------------------------------------------
; Copyleft (k)2011 by Jose Rodriguez (a.k.a. Boriel)
; http://www.boriel.com 
;
; ZX BASIC Compiler http://www.zxbasic.net
; This code is released under the BSD License
; ---------------------------------------------------------

; Implements both LBOUND(array, N) and UBOUND(array, N) function
; Parameters:
; HL = PTR to array
; [stack - 2] -> N (dimension)

    PROC
    LOCAL __BOUND
    LOCAL __DIM_NOT_EXIST
    LOCAL __CONT

__LBOUND:
    ld a, 4
    jr __BOUND

__UBOUND:
    ld a, 6

__BOUND:
    ex de, hl       ; DE <-- Array ptr
    pop hl          ; HL <-- Ret address
    ex (sp), hl     ; CALLEE: HL <-- N, (SP) <-- Ret address
    ex de, hl       ; DE <-- N, HL <-- ARRAY_PTR

    push hl
    ld c, (hl)
    inc hl
    ld h, (hl)
    ld l, c         ; HL = start of dimension table (first position contains number of dimensions - 1)
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc bc          ; Number of total dimensions of the array
    pop hl          ; Recovers ARRAY PTR
    ex af, af'      ; Saves A for later
    ld a, d
    or e
    jr nz, __CONT   ; N = 0 => Return number of dimensions

    ;; Return the number of dimensions of the array
    ld h, b
    ld l, c
    ret

__CONT:
    dec de
    ex af, af'      ; Recovers A (contains PTR offset)
    ex de, hl       ; HL = N (dimension asked) - 1, DE = Array PTR
    or a
    sbc hl, bc      ; if no Carry => the user asked for a dimension that does not exist. Return 0
    jr nc, __DIM_NOT_EXIST

    add hl, bc      ; restores HL = (N - 1)
    add hl, hl      ; hl *= 2
    ex de, hl       ; hl = ARRAY_PTR + 3, DE jsz = (N - 1) * 2
    ld b, 0
    ld c, a
    add hl, bc      ; HL = &BOUND_PTR
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a         ; LD HL, (HL) => Origin of L/U Bound table

    add hl, de      ; hl += OFFSET __LBOUND._xxxx
    ld e, (hl)      ; de = (hl)
    inc hl
    ld d, (hl)

    ex de, hl       ; hl = de => returns result in HL
    ret

__DIM_NOT_EXIST:
;   The dimension requested by the user does not exists. Return 0
    ld hl, 0
    ret
    ENDP
