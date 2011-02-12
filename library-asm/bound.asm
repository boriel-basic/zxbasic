; ---------------------------------------------------------
; Copyleft (k)2011 by Jose Rodriguez (a.k.a. Boriel)
; http://www.boriel.com 
;
; ZX BASIC Compiler http://www.zxbasic.net
; This code is released under the BSD License
; ---------------------------------------------------------

; Implements bothe the LBOUND(array, N) and RBOUND(array, N) function

; Parameters:
;   HL = N (dimension)
;   [stack - 2] -> LBound table for the var
;   Returns entry [N] in HL

__BOUND:
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

