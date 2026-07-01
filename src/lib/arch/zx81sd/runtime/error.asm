; Simple error control routines — ZX81 + SD81 Booster
; Sustituye RST 8 (error handler de la ROM Spectrum) por una parada
; limpia: guarda el código de error en ERR_NR y detiene la CPU.
; Las interrupciones ya están desactivadas (DI desde el bootstrap).

#include once <sysvars.asm>

    push namespace core

; Códigos de error (compatibles con el manual del ZX Spectrum)
ERROR_Ok                EQU    -1
ERROR_SubscriptWrong    EQU     2
ERROR_OutOfMemory       EQU     3
ERROR_OutOfScreen       EQU     4
ERROR_NumberTooBig      EQU     5
ERROR_InvalidArg        EQU     9
ERROR_IntOutOfRange     EQU    10
ERROR_NonsenseInBasic   EQU    11
ERROR_InvalidFileName   EQU    14
ERROR_InvalidColour     EQU    19
ERROR_BreakIntoProgram  EQU    20
ERROR_TapeLoadingErr    EQU    26

; __ERROR — Detiene la ejecución con un código de error en A.
; Sustituye a: RST 8 (ROM Spectrum)
__ERROR:
    ld (__ERROR_CODE), a
    ld (ERR_NR), a          ; guardar en sysvar
    di                      ; asegurar interrupciones desactivadas
    halt                    ; detener CPU
__ERROR_CODE:
    nop                     ; byte de código de error (para compatibilidad con llamadores)
    ret                     ; no se alcanza, pero mantiene la estructura original

; __STOP — Guarda el código de error y continúa (para END del programa).
__STOP:
    ld (ERR_NR), a
    ret

    pop namespace
