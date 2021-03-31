; Exchanges current DE HL with the
; ones in the stack

    push namespace core

__SWAP32:
    pop bc ; Return address
    ex (sp), hl
    inc sp
    inc sp
    ex de, hl
    ex (sp), hl
    ex de, hl
    dec sp
    dec sp
    push bc
    ret

    pop namespace

