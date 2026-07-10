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
MASK_P              EQU SYSVAR_BASE + $0F   ; DB  — máscara permanente ($00 = sin transparencia)
ATTR_T              EQU SYSVAR_BASE + $10   ; DB  — atributo temporal
; MASK_T se accede implícitamente como ATTR_T+1 ($8011) via LD HL,(ATTR_T)
P_FLAG              EQU SYSVAR_BASE + $12   ; DB  — flags de impresión (OVER/INVERSE perm.)
MEM0                EQU SYSVAR_BASE + $13   ; 5B  — buffer temporal para rutinas gráficas
TV_FLAG             EQU SYSVAR_BASE + $18   ; DB  — flags de control de salida a pantalla
ERR_NR              EQU SYSVAR_BASE + $19   ; DB  — código de error (-1 = sin error)
FRAMES              EQU SYSVAR_BASE + $1A   ; DW  — contador de frames VSYNC (software)
RANDOM_SEED_LOW     EQU SYSVAR_BASE + $1C   ; DW  — semilla RNG (16 bits bajos)
SCREEN_ADDR         EQU SYSVAR_BASE + $1E   ; DW  — puntero al framebuffer (init: $C000)
SCREEN_ATTR_ADDR    EQU SYSVAR_BASE + $20   ; DW  — puntero a atributos   (init: $D800)

; --- Sysvars del calculador de coma flotante (fp_calc.asm) --------------
; Equivalentes a STKBOT/STKEND/BREG/MEM de la ROM Spectrum ($5C63/$5C65/
; $5C67/$5C68), pero apuntando a un buffer fijo propio en vez de al área
; de trabajo dinámica de la ROM (aquí no existe "memoria libre creciente"
; entre el programa y la pila de máquina).
;
; IMPORTANTE: FP_BREG debe estar INMEDIATAMENTE DESPUÉS de FP_STKEND — el
; motor CALCULATE (L338E, ENT-TABLE) explota la contigüidad de memoria de
; la ROM original (STKEND_hi seguido de BREG) para cargar ambos con un
; único LD BC,(FP_STKEND+1): C=STKEND_hi, B=BREG. No reordenar.
FP_STKBOT           EQU SYSVAR_BASE + $22   ; DW — base de la pila de números FP
FP_STKEND           EQU SYSVAR_BASE + $24   ; DW — siguiente posición libre en la pila FP
FP_BREG             EQU SYSVAR_BASE + $26   ; DB — literal en curso (para fp-calc-2/dec-jr-nz)
FP_MEM              EQU SYSVAR_BASE + $27   ; DW — puntero al área MEM (6 celdas de 5B)
FP_CALC_STACK       EQU SYSVAR_BASE + $29   ; 60B — pila de números FP (12 números máx.)
FP_CALC_STACK_END   EQU FP_CALC_STACK + 60
FP_MEM_AREA         EQU SYSVAR_BASE + $65   ; 30B — área MEM (6 celdas de 5 bytes)

; Tamaño total del bloque de sysvars: $83 bytes

; --- Constantes de pantalla ---------------------------------------------

SCR_COLS            EQU 33      ; Columnas + 1 (32 columnas visibles)
SCR_ROWS            EQU 24      ; Filas (24 filas visibles)
SCR_SIZE            EQU (SCR_ROWS << 8) + SCR_COLS

    pop namespace
