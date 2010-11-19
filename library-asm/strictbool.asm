; This routine is called if --strict-boolean was set at the command line.
; It will make any boolean result to be always 0 or 1

__NORMALIZE_BOOLEAN:
    or a
    ret z
    ld a, 1
    ret

