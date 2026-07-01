; BEEP — Pulso corto de beeper (clic de tecla)
;
; SD81 Booster en modo Superfast HiRes Spectrum emula el puerto ULA del
; Spectrum en $FBh: bits 2-0 = color de borde, bits 4-3 = beeper (ver
; border.asm y Apendice "Modo Spectrum" del manual del SD81 Booster).
; Ambas funciones comparten el mismo puerto de solo escritura, asi que
; se mantiene una copia sombra del ultimo byte escrito para poder
; pulsar el beeper sin alterar el color de borde actual (y viceversa).

    push namespace core

SD81_ULA_PORT        EQU $FB     ; Puerto ULA emulado en modo HiRes Spectrum
SD81_ULA_BEEP_BITS    EQU $18    ; bits 4-3

__ZX81SD_ULA_SHADOW:
    DEFB 0

; ---------------------------------------------------------------------------
; __ZX81SD_KEYCLICK — Pulso breve de beeper (clic de tecla)
; No recibe ni devuelve nada. Registros modificados: AF, BC.
; ---------------------------------------------------------------------------
__ZX81SD_KEYCLICK:
    PROC
    LOCAL CLICK_DELAY

    ld hl, __ZX81SD_ULA_SHADOW
    ld a, (hl)
    or SD81_ULA_BEEP_BITS
    out (SD81_ULA_PORT), a

    ld b, 30
CLICK_DELAY:
    djnz CLICK_DELAY

    ld a, (hl)          ; restaura el byte previo (beeper apagado, borde intacto)
    out (SD81_ULA_PORT), a
    ret

    ENDP

    pop namespace
