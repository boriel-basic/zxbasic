; BOOTSTRAP — Inicialización de las sysvars del runtime (stage 2, parte ASM)
;
; El hardware (paginación bloques 1-5, SP, DI) es inicializado directamente
; por el prólogo del backend Python (emit_prologue), que emite esas
; instrucciones como constantes de arquitectura conocidas en tiempo de
; compilación.
;
; Esta rutina se ocupa de los valores por defecto de las sysvars en $8000+.
; Se registra con #init para que el compilador inserte automáticamente
; CALL SD81_INIT_SYSVARS en el prólogo, justo antes del salto al programa.

#include once <sysvars.asm>
#include once <charset.asm>

#init .core.SD81_INIT_SYSVARS

    push namespace core

; SD81_INIT_SYSVARS — Inicializa el bloque de variables del runtime en $8000
SD81_INIT_SYSVARS:
    PROC

    ; CHARS apunta 256 bytes ANTES del inicio del font (convención Spectrum):
    ; el runtime calcula glifo = CHARS + código*8, sin restar 32.
    ; Así CHR$(32)=space → CHARS+256 = font[0], CHR$(72)='H' → CHARS+576 = font[40].
    ld   hl, __ZX81SD_CHARSET - 256
    ld   (CHARS), hl

    ; UDG: primer carácter definible por el usuario (CHR$(144) en Spectrum)
    ; = font base + (144-32)*8 = font + 896. Con la convención CHARS-256:
    ; UDG = CHARS + 144*8 = __ZX81SD_CHARSET - 256 + 1152 = __ZX81SD_CHARSET + 896
    ld   hl, __ZX81SD_CHARSET + 896
    ld   (UDG), hl

    ; Cursor al inicio de pantalla (columna=SCR_COLS, fila=SCR_ROWS)
    ld   a, SCR_ROWS
    ld   h, a
    ld   a, SCR_COLS
    ld   l, a
    ld   (S_POSN), hl

    ; SCREEN_ADDR / SCREEN_ATTR_ADDR son variables RAM (no constantes EQU):
    ; el runtime las lee con LD HL,(SCREEN_ADDR) para obtener la dirección.
    ld   hl, $C000
    ld   (SCREEN_ADDR), hl      ; $801D ← $C000
    ld   (DFCC), hl             ; cursor bitmap al inicio de pantalla

    ld   hl, $D800
    ld   (SCREEN_ATTR_ADDR), hl ; $801F ← $D800
    ld   (DFCCL), hl            ; cursor attrs al inicio de atributos

    ; COORDS: último punto PLOT = (0,0)
    xor  a
    ld   (COORDS), a
    ld   (COORDS + 1), a

    ; Atributos por defecto: tinta negra sobre fondo blanco (INK 0, PAPER 7)
    ; $38 = 0b00111000 = PAPER 7 + INK 0, igual que el defecto del Spectrum
    ld   a, $38
    ld   (ATTR_P), a
    ld   hl, $F838              ; ATTR_T=$38, MASK_T=$F8
    ld   (ATTR_T), hl

    ; Flags a cero
    xor  a
    ld   (FLAGS2), a
    ld   (P_FLAG), a
    ld   (TV_FLAG), a
    ld   (ERR_NR), a

    ; Contadores a cero
    ld   hl, 0
    ld   (FRAMES), hl
    ld   (RANDOM_SEED_LOW), hl

    ret

    ENDP

    pop namespace
