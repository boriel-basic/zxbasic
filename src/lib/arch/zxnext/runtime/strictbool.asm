; This routine is called if --strict-boolean was set at the command line.
; It will make any boolean result to be always 0 or 1

    push namespace core

__NORMALIZE_BOOLEAN:
    sub 1
    sbc a, a
    inc a
    ret

    pop namespace
