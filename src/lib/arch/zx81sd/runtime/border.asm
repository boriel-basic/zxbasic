; BORDER — Cambia el color del borde
; SD81 Booster en modo Superfast HiRes Spectrum emula el puerto ULA del
; Spectrum en $FBh: bits 2-0 = color de borde, bits 4-3 = beeper.
; El beeper (ver beep.asm) usa el mismo puerto, asi que se preservan
; los bits 4-3 actuales (guardados en __ZX81SD_ULA_SHADOW) en vez de
; sobrescribir el byte completo.
;
; Entrada: A = color de borde (bits 2-0, igual que en Spectrum)
; Sustituye a: BORDER EQU $229Bh (ROM Spectrum)

#include once <beep.asm>

    push namespace core

BORDER:
    and  $07
    ld   b, a
    ld   hl, __ZX81SD_ULA_SHADOW
    ld   a, (hl)
    and  $18            ; conserva los bits de beeper
    or   b
    ld   (hl), a
    out  (SD81_ULA_PORT), a
    ret

    pop namespace
