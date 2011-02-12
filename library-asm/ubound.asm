; ---------------------------------------------------------
; Copyleft (k)2011 by Jose Rodriguez (a.k.a. Boriel)
; http://www.boriel.com 
;
; ZX BASIC Compiler http://www.zxbasic.net
; This code is released under the BSD License
; ---------------------------------------------------------

; Implements the LBOUND(array, N) function

; Parameters:
;   HL = N (dimension)
;   [stack - 2] -> LBound table for the var
;   Returns entry [N] in HL

__LBOUND:
    add hl, hl      ; hl *= 2
    ex de, hl
    pop hl
    ex (sp), hl     ; __CALLEE

    add hl, de      ; hl += OFFSET __LBOUND._xxxx
    ld e, (hl)      ; de = (hl)
    inc hl
    ld d, (hl)

    ex de, hl       ; hl = de => returns result in HL
    ret


__UBOUND:
    add hl, hl
    ex de, hl       ; DE = N * 2
    pop hl          ; ret address
    pop bc          ; array_address
    ex (sp), hl     ; __CALLEE; hl = OFFSET __LBOUND._xxxx

    add hl, de      ; hl = __LBOUND._xxxx + N * 2
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a         ; hl = (hl) => hl = LBound value

    ld a, d
    or e
    ret z           ; if Offset == 0, return just the number of dims

    push bc
    push hl
    pop bc
    pop hl          ; xchg BC, HL  => BC = Lbound(arr, N) hl = array address

    add hl, de      ; HL = array addr + N * 2
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a         ; hl = (hl) => hl => Number of cells in the dimension

    add hl, bc      ; hl = Ncelss + LBound(arr, N)
    ret
    
    

    

    
    


