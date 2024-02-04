    push namespace core

; Performs 8bit x 8bit unsigned (Ubyte) multiplication
; Computes A = A * H
; Note that 8bit x 8bit = 16bit. Higher part of the result is
; discarded (overflow).

__MULU8:
    PROC

    LOCAL __MUL8LOOP
    LOCAL __MUL8B

    ld b, 8
    ld l, a
    xor a

__MUL8LOOP:
    add a, a  ; a << 1
#ifdef __ZXB__CHECK_OVERFLOW__
    ret c
#endif
    sla l
    jr nc, __MUL8B
    add a, h
#ifdef __ZXB__CHECK_OVERFLOW__
    ret c
#endif

__MUL8B:
    djnz __MUL8LOOP

    ret  ; result = A
    ENDP

    pop namespace
