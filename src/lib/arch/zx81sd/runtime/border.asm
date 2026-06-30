; BORDER — Cambia el color del borde
; SD81 Booster en modo Superfast HiRes Spectrum emula el puerto ULA del
; Spectrum en $FBh: bits 2-0 = color de borde, bits 4-3 = beeper.
;
; Entrada: A = color de borde (bits 2-0, igual que en Spectrum)
; Sustituye a: BORDER EQU $229Bh (ROM Spectrum)

    push namespace core

SD81_ULA_PORT       EQU $FB     ; Puerto ULA emulado en modo HiRes Spectrum

BORDER:
    out  (SD81_ULA_PORT), a
    ret

    pop namespace
