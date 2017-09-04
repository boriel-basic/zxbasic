; ------------------------------------------------------
; Implements ON .. GOTO
; ------------------------------------------------------

__ON_GOSUB:
    pop hl
    ex (sp), hl  ; hl = beginning of table
    call __ON_GOTO_START
    ret

__ON_GOTO:
    pop hl
    ex (sp), hl  ; hl = beginning of table

__ON_GOTO_START:
    ; hl = address of jump table
    ; a = index (0..255)
    cp (hl) ; length of last post
    ret nc  ; a >= length of last position (out of range)
    inc hl
    pop de  ; removes ret addr from the stack
    ld d, 0
    add a, a
    ld e, a
    rl d
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    jp (hl)
