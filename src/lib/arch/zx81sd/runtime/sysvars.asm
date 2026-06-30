; -----------------------------------------------------------------------
; ZX81 + SD81 Booster System Variables
;
; SCREEN_ADDR / SCREEN_ATTR_ADDR: bloque 6 ($C000), pantalla Spectrum
; emulada por la FPGA del SD81 Booster en modo Superfast HiRes Spectrum.
;
; Las variables dinámicas del runtime se sitúan en $8000+ (bloques 4-5),
; fuera de la zona de código ejecutable ($0000-$7FFF), para no partir
; el espacio de ejecución del usuario.
; -----------------------------------------------------------------------

; Estos ficheros se incluyen siempre a través de sysvars.asm (primer fichero
; en incluirse en cualquier programa zx81sd) para que sus #init se registren
; en la primera pasada del preprocesador, antes de que emit_prologue() genere
; las llamadas CALL a las rutinas de inicialización.
#include once <bootstrap.asm>

    push namespace core

; --- Variables dinámicas del runtime ($8000+) ---------------------------
; Zona de datos (bloques 4-5), no ejecutable sin MC45.
;
; SCREEN_ADDR y SCREEN_ATTR_ADDR son variables RAM (no constantes EQU)
; porque el runtime de zx48k las lee con direccionamiento indirecto:
;   LD HL, (SCREEN_ADDR)  →  carga el CONTENIDO de esa posición de memoria.
; SD81_INIT_SYSVARS las inicializa con $C000 y $D800 respectivamente.

SYSVAR_BASE         EQU $8000

CHARS               EQU SYSVAR_BASE + $00   ; DW  — puntero a charset (8x8)
UDG                 EQU SYSVAR_BASE + $02   ; DW  — puntero a UDGs
COORDS              EQU SYSVAR_BASE + $04   ; DW  — última coordenada PLOT (X,Y)
FLAGS2              EQU SYSVAR_BASE + $06   ; DB  — flags de pantalla (OVER/INVERSE/etc.)
ECHO_E              EQU SYSVAR_BASE + $07   ; DB  — (reservado)
DFCC                EQU SYSVAR_BASE + $08   ; DW  — siguiente dirección bitmap para PRINT
DFCCL               EQU SYSVAR_BASE + $0A   ; DW  — siguiente dirección attrs para PRINT
S_POSN              EQU SYSVAR_BASE + $0C   ; DW  — posición cursor (H=fila, L=columna)
ATTR_P              EQU SYSVAR_BASE + $0E   ; DB  — atributo permanente (INK/PAPER/etc.)
ATTR_T              EQU SYSVAR_BASE + $0F   ; DW  — atributo temporal + máscara
P_FLAG              EQU SYSVAR_BASE + $11   ; DB  — flags de impresión (OVER/INVERSE perm.)
MEM0                EQU SYSVAR_BASE + $12   ; 5B  — buffer temporal para rutinas gráficas
TV_FLAG             EQU SYSVAR_BASE + $17   ; DB  — flags de control de salida a pantalla
ERR_NR              EQU SYSVAR_BASE + $18   ; DB  — código de error (-1 = sin error)
FRAMES              EQU SYSVAR_BASE + $19   ; DW  — contador de frames VSYNC (software)
RANDOM_SEED_LOW     EQU SYSVAR_BASE + $1B   ; DW  — semilla RNG (16 bits bajos)
SCREEN_ADDR         EQU SYSVAR_BASE + $1D   ; DW  — puntero al framebuffer (init: $C000)
SCREEN_ATTR_ADDR    EQU SYSVAR_BASE + $1F   ; DW  — puntero a atributos   (init: $D800)

; Tamaño total del bloque de sysvars: $21 bytes

; --- Constantes de pantalla ---------------------------------------------

SCR_COLS            EQU 33      ; Columnas + 1 (32 columnas visibles)
SCR_ROWS            EQU 24      ; Filas (24 filas visibles)
SCR_SIZE            EQU (SCR_ROWS << 8) + SCR_COLS

    pop namespace
