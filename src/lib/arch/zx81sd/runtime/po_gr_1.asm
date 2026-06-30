; PO_GR_1 — Genera el patrón de bits para caracteres gráficos 128-143
; Sustituye a PO_GR_1 EQU $0B38h (ROM Spectrum)
;
; Los caracteres gráficos Spectrum (CHR$ 128 a CHR$ 143) son bloques
; de pixels 2×2 en cuadrantes. El nibble bajo del código determina
; qué cuadrantes están encendidos (bit 0 = TL, 1 = TR, 2 = BL, 3 = BR).
;
; Entrada: B = código de carácter (128-143), solo se usan bits 3-0
; Salida:  MEM0 (5 bytes) = patrón de 8 bytes del carácter generado
;          HL = MEM0 (para que plot lo use directamente)
; Destruye: A, B, C, D, E
;
; Patrón generado: 4 líneas top + 4 líneas bottom
;   top_byte  = $FF si bit 0 (TL) || $F0 si bit 1 (TR) || combinación
;   bot_byte  = igual pero mirando bits 2 (BL) y 3 (BR)
;
; Codificación exacta:
;   bit 0 = cuadrante superior izquierdo  → pixels $F0 en filas 0-3
;   bit 1 = cuadrante superior derecho    → pixels $0F en filas 0-3
;   bit 2 = cuadrante inferior izquierdo  → pixels $F0 en filas 4-7
;   bit 3 = cuadrante inferior derecho    → pixels $0F en filas 4-7

#include once <sysvars.asm>

    push namespace core

PO_GR_1:
    PROC

    ld   a, b               ; A = código gráfico (128-143)
    and  $0F                ; quedarnos solo con los 4 bits de cuadrante

    ; Calcular byte superior (filas 0-3)
    ld   c, $00
    bit  0, a               ; TL activo?
    jr   z, NO_TL
    ld   c, $F0
NO_TL:
    bit  1, a               ; TR activo?
    jr   z, NO_TR
    ld   b, c
    or   $0F
    ld   c, a
    ld   a, b
NO_TR:
    ; C = byte superior

    ; Calcular byte inferior (filas 4-7)
    ld   d, a               ; guardar A (bits cuadrante)
    ld   e, $00
    bit  2, d               ; BL activo?
    jr   z, NO_BL
    ld   e, $F0
NO_BL:
    bit  3, d               ; BR activo?
    jr   z, NO_BR
    ld   a, e
    or   $0F
    ld   e, a
NO_BR:
    ; E = byte inferior

    ; Rellenar MEM0 con 8 bytes: 4x C, 4x E
    ld   hl, MEM0
    ld   a, c
    ld   (hl), a
    inc  hl
    ld   (hl), a
    inc  hl
    ld   (hl), a
    inc  hl
    ld   (hl), a
    inc  hl
    ld   a, e
    ld   (hl), a
    inc  hl
    ld   (hl), a
    inc  hl
    ld   (hl), a
    inc  hl
    ld   (hl), a

    ld   hl, MEM0           ; devolver puntero al patrón
    ret

    ENDP

    pop namespace
