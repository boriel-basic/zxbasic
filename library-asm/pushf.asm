
; Routine to push Float pointed by HL 
; Into the stack. Notice that the hl points to the last
; byte of the FP number.
; Uses H'L' B'C' and D'E' to preserve ABCDEHL registers

__FP_PUSH_REV:
    push hl
    exx
    pop hl
    pop bc ; Return Address
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
    ld d, (hl)
    push de
    push bc ; Return Address
    exx
    ret


