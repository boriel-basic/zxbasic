; -----------------------------------------------------------------------
; VSYNC — Sincronización con el refresco de pantalla
; SD81 Booster: puerto $AFh
;   bit 0     = estado actual de VSYNC (0/1, informativo, no se usa aquí)
;   bits 6-1  = contador de pulsos de VSYNC ocurridos desde la última
;               lectura del puerto (se resetea con cada IN)
;
; Sustituye a HALT + interrupción IM1 del ZX Spectrum.
; Las interrupciones están desactivadas (DI) en toda la ejecución.
; -----------------------------------------------------------------------

#include once <sysvars.asm>

    push namespace core

SD81_DATA_PORT      EQU $AF     ; Puerto de datos MCU del SD81 Booster

; VSYNC_WAIT — Espera a que ocurra al menos un pulso de VSYNC
; Destruye: A
; No modifica ningún otro registro.
VSYNC_WAIT:
    PROC
    LOCAL WAIT_PULSE

WAIT_PULSE:
    in   a, (SD81_DATA_PORT)
    and  $7E                    ; bits 6-1 = contador de pulsos
    jr   z, WAIT_PULSE          ; si 0, ningún pulso desde la última lectura

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
