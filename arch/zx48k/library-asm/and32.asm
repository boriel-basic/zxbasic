; FASTCALL boolean and 32 version.
; Performs 32bit and 32bit and returns the boolean
; result in Accumulator (0 False, not 0 True)
; First operand in DE,HL 2nd operand into the stack

__AND32:
    ld a, l
    or h
    or e
    or d

    pop hl
    pop de
    ex (sp), hl
    ret z

    ld a, d
    or e
    or h
    or l

#ifdef NORMALIZE_BOOLEAN
    ret z
    ld a, 1
#endif

    ret
