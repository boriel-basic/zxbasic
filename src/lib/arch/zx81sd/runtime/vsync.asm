; -----------------------------------------------------------------------
; VSYNC — Sincronización con el refresco de pantalla
; SD81 Booster: puerto $A7h, bit 0 = estado VSYNC
;   bit 0 = 0 → pantalla pintándose (blanking activo)
;   bit 0 = 1 → blanking vertical completado, inicio de nuevo frame
;
; Sustituye a HALT + interrupción IM1 del ZX Spectrum.
; Las interrupciones están desactivadas (DI) en toda la ejecución.
; -----------------------------------------------------------------------

#include once <sysvars.asm>

    push namespace core

SD81_DATA_PORT      EQU $A7     ; Puerto de datos MCU del SD81 Booster

; VSYNC_WAIT — Espera al inicio del siguiente frame
; Destruye: A
; No modifica ningún otro registro.
VSYNC_WAIT:
    PROC
    LOCAL WAIT_LOW
    LOCAL WAIT_HIGH

    ; Esperar a que VSYNC baje (por si estamos en medio de un pulso)
WAIT_LOW:
    in   a, (SD81_DATA_PORT)
    rrca                        ; bit 0 → carry
    jr   c, WAIT_LOW            ; si carry=1, todavía en blanking anterior

    ; Esperar el flanco de subida (inicio real del blanking)
WAIT_HIGH:
    in   a, (SD81_DATA_PORT)
    rrca
    jr   nc, WAIT_HIGH          ; si carry=0, aún no ha llegado el VSYNC

    ret
    ENDP

; VSYNC_TICK — Espera un frame e incrementa el contador FRAMES
; Destruye: A, HL
VSYNC_TICK:
    call VSYNC_WAIT
    ld   hl, (FRAMES)
    inc  hl
    ld   (FRAMES), hl
    ret

    pop namespace
