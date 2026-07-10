; printf.asm (zx81sd) — PRINT de un numero FLOAT
;
; Sustituye a zx48k/runtime/printf.asm, que usa el literal 'str$' ($2Eh) del
; calculador de la ROM (STR$ + STK-STO-$ + heap temporal) para despues
; imprimir la cadena resultante. Aqui se usa directamente fp_tostr.asm
; (conversion simplificada ya portada) e imprime sus caracteres uno a uno,
; sin pasar por el heap.

#include once <fp_tostr.asm>
#include once <print.asm>

    push namespace core

__PRINTF:
    ; Entrada: A,E,D,C,B = valor FLOAT
    call FP_TO_STR      ; HL = puntero al texto, BC = longitud
    PROC
    LOCAL __PRINTF_LOOP

__PRINTF_LOOP:
    ld   a, b
    or   c
    ret  z

    ld   a, (hl)
    push hl
    push bc
    call __PRINTCHAR
    pop  bc
    pop  hl
    inc  hl
    dec  bc
    jr   __PRINTF_LOOP

    ENDP

    pop namespace
