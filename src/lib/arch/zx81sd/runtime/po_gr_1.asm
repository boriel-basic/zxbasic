; PO_GR_1 — Genera el patrón de bits para caracteres gráficos 128-143
; Sustituye a PO-GR-1 ($0B38, ROM Spectrum). Mismo algoritmo que la ROM.
;
; Los caracteres gráficos Spectrum (CHR$ 128 a CHR$ 143) son bloques
; de 2×2 cuadrantes. El nibble bajo del código determina qué cuadrantes
; están encendidos, con el mapeo EXACTO de la ROM (PO-GR-2, $0B3E):
;
;   bit 0 = cuadrante superior DERECHO   → $0F en filas 0-3
;   bit 1 = cuadrante superior IZQUIERDO → $F0 en filas 0-3
;   bit 2 = cuadrante inferior DERECHO   → $0F en filas 4-7
;   bit 3 = cuadrante inferior IZQUIERDO → $F0 en filas 4-7
;
; (CHR$(129) = ▝, CHR$(130) = ▘, CHR$(143) = bloque macizo.)
;
; Entrada: B = código de carácter (128-143), solo se usan bits 3-0
; Salida:  MEM0 (8 bytes) = patrón del carácter; HL = MEM0
; Destruye: A, B, C

#include once <sysvars.asm>

    push namespace core

PO_GR_1:
    PROC
    LOCAL PO_GR_HALF, PO_GR_FILL

    ld   a, b
    and  $0F
    ld   b, a               ; B = bits de cuadrante
    ld   hl, MEM0
    call PO_GR_HALF         ; filas 0-3 (bits 0-1)
    call PO_GR_HALF         ; filas 4-7 (bits 2-3)
    ld   hl, MEM0           ; devuelve el puntero al patrón
    ret

; Construye media celda (4 filas iguales) a partir de los dos bits
; bajos de B, desplazándolos fuera. Igual que PO-GR-2 de la ROM.
PO_GR_HALF:
    rr   b                  ; bit par → carry
    sbc  a, a               ; $00 o $FF
    and  $0F                ; mitad derecha
    ld   c, a
    rr   b                  ; bit impar → carry
    sbc  a, a
    and  $F0                ; mitad izquierda
    or   c                  ; byte de la fila completo
    ld   c, 4
PO_GR_FILL:
    ld   (hl), a
    inc  hl
    dec  c
    jr   nz, PO_GR_FILL
    ret

    ENDP

    pop namespace
