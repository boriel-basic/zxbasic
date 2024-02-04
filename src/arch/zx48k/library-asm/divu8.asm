; --------------------------------
; 8 bit signed integer division Divides A / H
; Returns the quotient in A and the reminder in L
; --------------------------------
    push namespace core

__DIVU8:
    ld l, h
    ld h, a        ; At this point do H / L

    ld b, 8

    xor a          ; A = 0, Carry Flag = 0

__DIV8LOOP:
    sla h
    rla
    cp l
    jr c, __DIV8NOSUB
    sub l
    inc h

__DIV8NOSUB:
    djnz __DIV8LOOP

    ld l, a        ; save remainder
    ld a, h        ;
    ret            ; a = Quotient,

__MODU8:           ; 8 bit module. Returns A mod (Top of stack) (unsigned operands)
    call __DIVU8_FAST
    ld a, l        ; Remainder
    ret            ; a = Modulus

    pop namespace

