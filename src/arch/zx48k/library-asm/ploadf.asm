; Parameter / Local var load
; A => Offset
; IX = Stack Frame
; RESULT: HL => IX + DE

#include once <iloadf.asm>

    push namespace core

__PLOADF:
    push ix
    pop hl
    add hl, de
    jp __LOADF

    pop namespace

