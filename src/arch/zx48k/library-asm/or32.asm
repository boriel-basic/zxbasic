__OR32:  ; Performs logical operation A AND B
         ; between DEHL and TOP of the stack.
         ; Returns A = 0 (False) or A = FF (True)

    ld a, h
    or l
    or d
    or e

    pop hl ; Return address
    pop de
    ex (sp), hl

    or d
    or e
    or h
    or l

#ifdef NORMALIZE_BOOLEAN
    ; Ensure it returns 0 or 1
    ret z
    ld a, 1
#endif
    ret

