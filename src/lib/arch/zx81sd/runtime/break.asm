; CHECK_BREAK — Detección de la tecla BREAK (SHIFT + SPACE)
; ZX81 + SD81 Booster
;
; Los puertos del teclado del ZX81 son idénticos a los del Spectrum
; (puerto $FEh con líneas de dirección en el bus A8-A15).
; TS_BRK ($8020h de la ROM Spectrum) lee las half-rows de CAPS SHIFT y SPACE;
; aquí se reimplementa directamente sin depender de la ROM.
;
; Puerto $FEh:
;   A8  (línea 0, $FEFE) = SHIFT/Z/X/C/V
;   A12 (línea 7, $7FFE) = SPACE/./M/N/B   ← SPACE está aquí, bit 0
;
; BREAK = CAPS SHIFT (bit 0 de $FEFE) + SPACE (bit 0 de $7FFE)

#include once <error.asm>
#include once <sysvars.asm>

    push namespace core

CHECK_BREAK:
    PROC
    LOCAL TS_BRK, NO_BREAK

    push af
    call TS_BRK
    jr   c, NO_BREAK

    ld   a, ERROR_BreakIntoProgram
    jp   __ERROR

NO_BREAK:
    pop  af
    pop  hl         ; ret address
    ex   (sp), hl   ; restaura HL original
    ret

; TS_BRK — Comprueba si BREAK está pulsado
; Salida: carry set = no pulsado; carry clear = BREAK pulsado
; Destruye: A
TS_BRK:
    ld   a, $FE
    in   a, ($FE)   ; half-row SPACE/./M/N/B (A12 high = $7FFE... )
    ; Para leer la half-row de SPACE necesitamos A12=0, resto altos:
    ; Dirección: $7FFE = 0111 1111 1111 1110b → A12=0, A8=1
    ld   a, $7F
    in   a, ($FE)   ; lee half-row 7 (SPACE en bit 0)
    rra             ; bit 0 → carry  (0 = pulsado)
    jr   c, NO_SPACE

    ; SPACE pulsado — comprobar CAPS SHIFT
    ld   a, $FE     ; A8=0 → half-row 0 (CAPS SHIFT en bit 0)
    in   a, ($FE)
    rra             ; bit 0 → carry  (0 = pulsado)
    ret             ; carry clear = ambas pulsadas = BREAK

NO_SPACE:
    scf             ; SPACE no pulsada → no es BREAK
    ret

    ENDP

    pop namespace
