; FP_CALC — Calculador de coma flotante
; Sustituye a RST $28h (ROM Spectrum, dirección $0E9Bh)
;
; ESTADO: STUB — Primera versión sin soporte float.
; La arquitectura zx81sd compila con __ZXB_NO_FLOAT activado (arch_config.asm),
; por lo que este fichero no se incluye en compilaciones normales.
;
; TODO: Integrar el calculador FP del Spectrum reubicado en $0000-$0FFF
;       o una reimplementación libre compatible con el protocolo de bytecodes.
;       Cuando esté listo:
;         1. Eliminar #define __ZXB_NO_FLOAT de arch_config.asm
;         2. Sustituir FP_CALC_ENTRY por la implementación real
;         3. Verificar que todos los RST $28h del runtime se convierten
;            en CALL FP_CALC_ENTRY (gestionado por el backend)
;
; Protocolo RST $28h del Spectrum:
;   - Los bytecodes de operación siguen inmediatamente al CALL en memoria
;   - El calculador lee el flujo de bytecodes desde (SP) tras el CALL
;   - El stack de coma flotante (5 bytes/número) es independiente del stack Z80
;   - El registro E apunta al primer bytecode
;
; Referencias:
;   ROM Spectrum disassembly: https://skoolkid.github.io/rom/
;   FP calculator entry: $0E9Bh — routine CALCULATE

    push namespace core

; Punto de entrada del calculador FP (para cuando se integre la versión real)
FP_CALC_ENTRY:
    ; STUB: no hacer nada — el compilador no debería llegar aquí
    ; con __ZXB_NO_FLOAT activo
    ret

    pop namespace
