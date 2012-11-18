
; Routine to push Float pointed by HL 
; Into the stack. Notice that the hl points to the last
; 2 bytes of the FP number

__FP_PUSH_REV:
    pop bc
    ld d, (hl)
    dec hl
    ld e, (hl)
    dec hl
    push de
    ld d, (hl)
    dec hl
    ld e, (hl)
    dec hl
    push de
    ld a, (hl)
    push af
    push bc
    ret


