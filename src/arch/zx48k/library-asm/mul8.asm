    push namespace core

__MUL8:		; Performs 8bit x 8bit multiplication
    PROC

    ;LOCAL __MUL8A
    LOCAL __MUL8LOOP
    LOCAL __MUL8B
    ; 1st operand (byte) in A, 2nd operand into the stack (AF)
    pop hl	; return address
    ex (sp), hl ; CALLE convention

__MUL8_FAST: ; __FASTCALL__ entry, a = a * h (8 bit mul) and Carry

    ld b, 8
    ld l, a
    xor a

__MUL8LOOP:
    add a, a ; a *= 2
#ifdef __ZXB__CHECK_OVERFLOW__
    ret c
#endif
    sla l
    jp nc, __MUL8B
    add a, h

__MUL8B:
    djnz __MUL8LOOP

    ret		; result = HL
    ENDP

    pop namespace
