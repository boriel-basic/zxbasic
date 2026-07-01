; ---------------------------------------------------------------------------
; keyscan.asm — Escaneo directo de la matriz de teclado del ZX81
;
; No hay ROM mapeada en tiempo de ejecucion (el bloque 0 lo ocupa por
; completo nuestro binario compilado), asi que no se puede llamar a la
; rutina KEYBOARD/DECODE de la ROM original. El hardware del teclado, en
; cambio, es el mismo ZX81 de siempre (el SD81 Booster no lo toca), asi
; que se reimplementa aqui el escaneo fisico (puerto $FEFE, 8 filas
; seleccionadas rotando el registro alto del puerto) y una decodificacion
; propia a ASCII.
;
; IMPORTANTE: la ROM del ZX81 decodifica las teclas a SU PROPIO charset
; (con codigos de token para palabras clave de BASIC), no a ASCII. El
; runtime de zx81sd usa el charset Spectrum/ASCII para imprimir (ver
; charset.asm, specfont.bin), asi que la tabla de decodificacion de abajo
; traduce directamente cada tecla a su codigo ASCII, ignorando las teclas
; que en el ZX81 producen tokens de BASIC sin equivalente ASCII simple
; (STOP, AND, OR, THEN, TO, STEP, <=, >=, <>, **, EDIT, GRAPHICS,
; FUNCTION, cursores, LPRINT, LLIST, SLOW, FAST). La tecla RUBOUT
; (SHIFT+0) se traduce a ASCII 12, y ENTER (NEWLINE) a ASCII 13, para
; mantener compatibilidad con la convencion ya usada por stdlib/input.bas.
; ---------------------------------------------------------------------------

    push namespace core

; ---------------------------------------------------------------------------
; __ZX81SD_KEYSCAN
;
; Escanea las 8 filas de la matriz y decodifica la primera tecla
; encontrada (si hay varias pulsadas a la vez, solo se detecta una).
;
; Devuelve:
;   A = codigo ASCII de la tecla pulsada, o 0 si no hay ninguna pulsada,
;       o si la tecla no tiene equivalente ASCII (ver nota arriba), o si
;       solo esta pulsada la tecla SHIFT sola.
;   Flag Z activo si A = 0
;
; Registros modificados: AF, BC, DE, HL
; ---------------------------------------------------------------------------
__ZX81SD_KEYSCAN:
    PROC
    LOCAL ROW_LOOP
    LOCAL NEXT_ROW
    LOCAL FIND_COL
    LOCAL GOT_COL0
    LOCAL GOT_COL1
    LOCAL GOT_COL2
    LOCAL GOT_COL3
    LOCAL GOT_COL4
    LOCAL GOT_KEY
    LOCAL LOOKUP
    LOCAL NO_KEY
    LOCAL UNSHIFT_TABLE
    LOCAL SHIFT_TABLE

    ; D = indice de fila actual (0-7), E = flag SHIFT pulsado (0/1)
    ld d, 0
    ld e, 0
    ld b, $FE           ; B = mitad alta del puerto ($FEFE, $FDFE, ... $7FFE)

ROW_LOOP:
    ld c, $FE
    in a, (c)           ; lee la fila; bits 0-4 = columnas (0 = pulsada)
    and $1F
    cp $1F
    jr z, NEXT_ROW      ; ninguna tecla pulsada en esta fila

    ld l, a             ; L = mapa de bits de columnas pulsadas

    ld a, d
    or a
    jr nz, FIND_COL

    ; Fila 0: la columna 0 es la tecla SHIFT (no genera caracter propio)
    bit 0, l
    jr nz, FIND_COL     ; SHIFT no pulsado, comprobar columnas normalmente
    ld e, 1             ; SHIFT pulsado
    set 0, l            ; descartar ese bit para no confundirlo con datos
    ld a, l
    cp $1F
    jr z, NEXT_ROW      ; en esta fila solo estaba pulsado SHIFT

FIND_COL:
    ; Bucle desenrollado a proposito: usar CP para comparar el contador
    ; de columna sobreescribia A (el mapa de bits que se iba rotando)
    ; antes de que la siguiente vuelta pudiera comprobarlo, con lo que
    ; solo la columna 0 se detectaba bien. Sin bucle no hay ese riesgo.
    ld a, l
    rrca
    jr nc, GOT_COL0
    rrca
    jr nc, GOT_COL1
    rrca
    jr nc, GOT_COL2
    rrca
    jr nc, GOT_COL3
    rrca
    jr nc, GOT_COL4
    jr NEXT_ROW         ; no deberia ocurrir (ya se comprobo cp $1F antes)

GOT_COL0:
    ld c, 0
    jr GOT_KEY
GOT_COL1:
    ld c, 1
    jr GOT_KEY
GOT_COL2:
    ld c, 2
    jr GOT_KEY
GOT_COL3:
    ld c, 3
    jr GOT_KEY
GOT_COL4:
    ld c, 4

GOT_KEY:
    ; indice de tabla = fila*5 + columna - 1
    ; (la fila 0 solo aporta 4 teclas: columnas 1-4, de ahi el -1)
    ld a, d
    add a, a
    add a, a
    add a, d            ; A = fila*5
    add a, c            ; A = fila*5 + columna
    dec a               ; A = indice (0-38)

    ld hl, UNSHIFT_TABLE
    bit 0, e
    jr z, LOOKUP
    ld hl, SHIFT_TABLE

LOOKUP:
    ld c, a
    ld b, 0
    add hl, bc
    ld a, (hl)
    or a                ; fija flag Z segun corresponda
    ret

NEXT_ROW:
    rlc b
    inc d
    ld a, d
    cp 8
    jr nz, ROW_LOOP

NO_KEY:
    xor a
    ret

    ; Orden de filas/columnas identico al de las tablas K-UNSHIFT/K-SHIFT
    ; de la ROM original del ZX81 (fila 0: SHIFT,Z,X,C,V ... fila 7:
    ; ENTER,L,K,J,H / SPACE,.,M,N,B), verificado contra el disassembly.
UNSHIFT_TABLE:
    DEFB 'Z', 'X', 'C', 'V'
    DEFB 'A', 'S', 'D', 'F', 'G'
    DEFB 'Q', 'W', 'E', 'R', 'T'
    DEFB '1', '2', '3', '4', '5'
    DEFB '0', '9', '8', '7', '6'
    DEFB 'P', 'O', 'I', 'U', 'Y'
    DEFB 13,  'L', 'K', 'J', 'H'    ; NEWLINE -> ENTER (ASCII 13)
    DEFB ' ', '.', 'M', 'N', 'B'

SHIFT_TABLE:
    DEFB ':', ';', '?', '/'
    DEFB 0,   0,   0,   0,   0      ; STOP, LPRINT, SLOW, FAST, LLIST
    DEFB '"', 0,   0,   0,   0      ; "" (par de comillas), OR, STEP, <=, <>
    DEFB 0,   0,   0,   0,   0      ; EDIT, AND, THEN, TO, cursor-izq
    DEFB 12,  0,   0,   0,   0      ; RUBOUT (DEL=12), GRAPHICS, cursor der/arr/abj
    DEFB '"', ')', '(', '$', 0      ; ", ), (, $, >=
    DEFB 0,   '=', '+', '-', 0      ; FUNCTION, =, +, -, **
    DEFB 0,   ',', '>', '<', '*'    ; £, ',', >, <, *

    ENDP

    pop namespace
