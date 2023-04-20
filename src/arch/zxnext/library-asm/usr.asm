; Emulates the USR Sinclair BASIC function
; Result value returns in BC
; We use HL for returning values, su we must
; copy BC into HL before returning
;
; The incoming parameter is HL (Address to JUMP)
;

#include once <table_jump.asm>

    push namespace core

USR:
    push ix       ; must preserve IX
    call CALL_HL
    pop ix
    ld h, b
    ld l, c
    ret

    pop namespace
