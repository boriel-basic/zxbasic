; --------------------------------
; 8 bit signed integer division Divides A / H
; Returns the quotient in A and the reminder in L
; --------------------------------

#include once <divu8.asm>

__DIVI8:
    ld e, a		; store operands for later
    ld c, h

    or a		; negative?
    jp p, __DIV8A
    neg			; Make it positive

__DIV8A:
    ex af, af'
    ld a, h
    or a
    jp p, __DIV8B
    neg
    ld h, a		; make it positive

__DIV8B:
    ex af, af'
    call __DIVU8

    ld a, c
    xor l		; bit 7 of A = 1 if result is negative

    ld a, h		; Quotient
    ret p		; return if positive

    neg
    ret

__MODI8:		; 8 bit module. Returns A mod (Top of stack) (For singed operands)
    call __DIVI8
    ld a, l		; remainder
    ret		    ; a = Modulus

    pop namespace
