; -----------------------------------------------------------------------
; PAUSE — Espera N frames usando VSYNC del SD81 Booster
; Sustituye a CALL $1F3Dh (PAUSE_1 de la ROM Spectrum) que usa HALT.
;
; Entrada: HL = número de frames a esperar
; -----------------------------------------------------------------------

#include once <vsync.asm>

    push namespace core

__PAUSE:
    PROC
    LOCAL PAUSE_LOOP

    ld   b, h
    ld   c, l           ; BC = contador de frames

PAUSE_LOOP:
    ld   a, b
    or   c
    ret  z              ; BC=0 → fin
    call VSYNC_TICK     ; espera un frame e incrementa FRAMES
    dec  bc
    jr   PAUSE_LOOP

    ENDP

    pop namespace
