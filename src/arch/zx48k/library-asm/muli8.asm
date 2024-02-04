    push namespace core

; This routine is used only if Overflow Check is enabled.
; Otherwise, MULU8 is used, since it works also for signed bytes.

; Performs 8bit x 8bit signed (Byte) multiplication
; Computes A = A * H
; Note that 8bit x 8bit = 16bit. Higher part of the result is
; discarded (overflow).

__MULI8:
    PROC

    LOCAL __MUL16LOOP
    LOCAL __MUL8B

    ld c, a
    rla
    sbc a, a    ; AC = A sith sign propagated
    ex af, af'  ; saves accumulator
    xor a
    ld e, h
    rl h
    sbc a, a
    ld d, a     ; DE = H with sign propagated
    ex af, af'
    ld hl, 0    ; HL = 0, accumulator
    ld b, 16

__MUL16LOOP:
    add hl, hl  ; hl << 1
    rl c
    rla
    jr nc, __MUL8B
    add hl, de

__MUL8B:
    djnz __MUL16LOOP

    ; check overflow
    ld a, l
    rla       ; moves sign to carry
    ld a, h   ; H should be 0 or 0xFF
    adc a, 0  ; H + Carry should be 0
    jp nz, __OVERFLOW_ERROR
    ld a, l

    ret       ; result in the top of the stack
    ENDP

    pop namespace
