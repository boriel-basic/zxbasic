; stackf.asm (zx81sd) — Gestión de la pila del calculador FP
;
; Sustituye a zx48k/runtime/stackf.asm, que define __FPSTACK_PUSH/POP como
; direcciones FIJAS de la ROM del Spectrum ($2AB6h STK-STORE, $2BF1h
; STK-FETCH). En zx81sd esas direcciones son parte de nuestro propio
; binario compilado (varían de un programa a otro), así que no se pueden
; usar como constantes — hay que reimplementar ambas rutinas como código
; reubicable normal, usando fp_calc.asm (mismo formato de pila y de número
; de 5 bytes que el motor CALCULATE ya portado).

#include once <fp_calc.asm>

    push namespace core

; ---------------------------------------------------------------------------
; __FPSTACK_PUSH — Apila los registros A,E,D,C,B (5 bytes) en la pila FP
; Sustituye a STK-STORE ($2AB6h ROM Spectrum)
; ---------------------------------------------------------------------------
__FPSTACK_PUSH:
    push bc
    push af
    ld   bc, 5
    call CALC_TEST_ROOM
    pop  af
    pop  bc
    ld   hl, (FP_STKEND)
    ld   (hl), a
    inc  hl
    ld   (hl), e
    inc  hl
    ld   (hl), d
    inc  hl
    ld   (hl), c
    inc  hl
    ld   (hl), b
    inc  hl
    ld   (FP_STKEND), hl
    ret

__FPSTACK_PUSH2: ; Pushes Current A ED CB registers and top of the stack on (SP + 4)
    ; Second argument to push into the stack calculator is popped out of the stack
    ; Since the caller routine also receives the parameters into the top of the stack
    ; four bytes must be removed from SP before pop them out

    call __FPSTACK_PUSH ; Pushes A ED CB into the FP-STACK
    exx
    pop hl       ; Caller-Caller return addr
    exx
    pop hl       ; Caller return addr

    pop af
    pop de
    pop bc

    push hl      ; Caller return addr
    exx
    push hl      ; Caller-Caller return addr
    exx

    jp __FPSTACK_PUSH


__FPSTACK_I16:	; Pushes 16 bits integer in HL into the FP ROM STACK
    ; This format is specified in the ZX 48K Manual
    ; You can push a 16 bit signed integer as
    ; 0 SS LL HH 0, being SS the sign and LL HH the low
    ; and High byte respectively
    ld a, h
    rla			; sign to Carry
    sbc	a, a	; 0 if positive, FF if negative
    ld e, a
    ld d, l
    ld c, h
    xor a
    ld b, a
    jp __FPSTACK_PUSH

; ---------------------------------------------------------------------------
; __FPSTACK_POP — Extrae los últimos 5 bytes de la pila FP a A,E,D,C,B
; Sustituye a STK-FETCH ($2BF1h ROM Spectrum)
; ---------------------------------------------------------------------------
__FPSTACK_POP:
    ld   hl, (FP_STKEND)
    dec  hl
    ld   b, (hl)
    dec  hl
    ld   c, (hl)
    dec  hl
    ld   d, (hl)
    dec  hl
    ld   e, (hl)
    dec  hl
    ld   a, (hl)
    ld   (FP_STKEND), hl
    ret

    pop namespace
