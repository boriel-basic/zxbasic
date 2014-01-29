; Parameter / Local var load
; A => Offset
; IX = Stack Frame
; RESULT: HL => IX + DE

#include once <iloadf.asm>

__PLOADF:
    push ix
    pop hl
    add hl, de
    jp __LOADF
   
