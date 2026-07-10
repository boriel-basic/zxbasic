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

; fp_calc.asm se incluye siempre (no solo cuando el programa usa FLOAT):
; el vector RST $28h (src/arch/zx81sd/backend/main.py, emit_prologue) salta
; incondicionalmente a FP_CALC_ENTRY, así que esa etiqueta debe existir en
; todo binario, aunque el programa concreto no acabe generando código que
; la invoque.
#include once <fp_calc.asm>

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

    ; UDG: área dedicada de 21 caracteres definibles (CHR$(144)-CHR$(164),
    ; como en el Spectrum), reservada en charset.asm DESPUÉS de la fuente.
    ; (La fuente sólo cubre CHR$(32)-CHR$(127): el antiguo "font+896"
    ; apuntaba 128 bytes más allá de su final, sobre código del runtime,
    ; y los POKE USR CHR$ de un programa lo corrompían.)
    ld   hl, __ZX81SD_UDG_AREA
    ld   (UDG), hl

    ; Inicializa los UDGs con copias de las letras A-U (como la ROM del
    ; Spectrum): glifo de 'A' = font + (65-32)*8 = font + 264.
    ld   hl, __ZX81SD_CHARSET + 264
    ld   de, __ZX81SD_UDG_AREA
    ld   bc, 21 * 8
    ldir

    ; Cursor al inicio de pantalla (columna=SCR_COLS, fila=SCR_ROWS)
    ld   a, SCR_ROWS
    ld   h, a
    ld   a, SCR_COLS
    ld   l, a
    ld   (S_POSN), hl

    ; SCREEN_ADDR / SCREEN_ATTR_ADDR son variables RAM (no constantes EQU):
    ; el runtime las lee con LD HL,(SCREEN_ADDR) para obtener la dirección.
    ld   hl, $C000
    ld   (SCREEN_ADDR), hl      ; $801E ← $C000
    ld   (DFCC), hl             ; cursor bitmap al inicio de pantalla

    ld   hl, $D800
    ld   (SCREEN_ATTR_ADDR), hl ; $8020 ← $D800
    ld   (DFCCL), hl            ; cursor attrs al inicio de atributos

    ; COORDS: último punto PLOT = (0,0)
    xor  a
    ld   (COORDS), a
    ld   (COORDS + 1), a

    ; Atributos por defecto: tinta negra sobre fondo blanco (INK 0, PAPER 7)
    ; $38 = 0b00111000 = PAPER 7 + INK 0, igual que el defecto del Spectrum
    ld   a, $38
    ld   (ATTR_P), a
    xor  a
    ld   (MASK_P), a            ; $00 = sin transparencia (COPY_ATTR copia ATTR_P íntegro)
    ld   hl, $0038              ; ATTR_T=$38, MASK_T=$00
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

    ; Calculador de coma flotante (fp_calc.asm): pila FP vacía, MEM en su
    ; posición por defecto (ver sysvars.asm)
    ld   hl, FP_CALC_STACK
    ld   (FP_STKBOT), hl
    ld   (FP_STKEND), hl
    ld   hl, FP_MEM_AREA
    ld   (FP_MEM), hl

    ret

    ENDP

    pop namespace
