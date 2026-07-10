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
; ESQUEMA DE TECLAS (2026-07-04, revisado tras probar en el emulador)
; --------------------------------------------------------------------
; El teclado fisico del ZX81 no tiene mayuscula/minuscula por tecla (SHIFT
; da simbolos, no la version en mayuscula de la letra) — a diferencia del
; Spectrum, donde SHIFT+letra si da la mayuscula de esa letra via la ROM
; (K-DECODE en modo L). Para poder imprimir el juego de caracteres
; completo sin depender de teclado externo:
;
;   Sin modificador       -> minuscula (a, s, d... como hasta ahora)
;   SHIFT + letra         -> MAYUSCULA de esa letra
;   SHIFT + "2"           -> conmuta CAPS LOCK (persistente; no imprime nada)
;   CAPS LOCK activo      -> minuscula pasa a mayuscula (SHIFT sigue dando
;                            mayuscula igual, no hay interaccion: es un OR)
;   "." (con o sin SHIFT) -> "." o "," exactamente igual que en el ZX81
;                            real (SHIFT+"." = ",")
;
; SHIFT es comodo de mantener pulsado con una mano mientras se pulsa la
; letra con la otra (aqui __ZX81SD_KEYSCAN SI detecta la simultaneidad
; real, con dos lecturas de puerto dedicadas para SHIFT y una tercera
; tecla). Pero un primer diseno que anadia un segundo modificador de
; simbolo con "." (pulsar "."+tecla a la vez para sacar el simbolo
; impreso en el teclado del ZX81) resulto impracticable de teclear: al
; usarse desde INPUT, la rutina de lectura ya compromete la tecla "."
; en cuanto se detecta pulsada sola, sin dar tiempo a que la segunda
; tecla llegue a la vez (no son dedos que se muevan en paralelo como
; SHIFT+letra, sino una pulsacion despues de otra). Por eso ese segundo
; modificador se ha movido a stdlib/input.bas, como una "tecla muerta"
; a nivel de composicion de caracteres (se pulsa "." y LUEGO la tecla
; del simbolo, secuencialmente, sin necesidad de mantenerlas a la vez):
; ver __ZX81SD_SYMBOL_FOR mas abajo, que da el mapeo tecla->simbolo que
; usa esa logica.
;
; IMPORTANTE: la ROM del ZX81 decodifica las teclas a SU PROPIO charset
; (con codigos de token para palabras clave de BASIC), no a ASCII. El
; runtime de zx81sd usa el charset Spectrum/ASCII para imprimir (ver
; charset.asm, specfont.bin), asi que las tablas de decodificacion de
; abajo traducen directamente cada tecla a su codigo ASCII, ignorando las
; teclas que en el ZX81 producen tokens de BASIC sin equivalente ASCII
; simple (STOP, AND, OR, THEN, TO, STEP, <=, >=, <>, **, EDIT, GRAPHICS,
; FUNCTION, cursores, LPRINT, LLIST, SLOW, FAST). La tecla RUBOUT
; (SHIFT+0) se traduce a ASCII 12, y ENTER (NEWLINE) a ASCII 13, para
; mantener compatibilidad con la convencion ya usada por stdlib/input.bas.
; ---------------------------------------------------------------------------

    push namespace core

; --- Tablas de decodificacion, en ambito de fichero (no LOCAL a ningun
;     PROC): las usa __ZX81SD_KEYSCAN y tambien __ZX81SD_SYMBOL_FOR. ---
;
; Orden de filas/columnas identico al de las tablas K-UNSHIFT/K-SHIFT de
; la ROM original del ZX81 (fila 0: SHIFT,Z,X,C,V ... fila 7: ENTER,L,K,
; J,H / SPACE,.,M,N,B), verificado contra el disassembly.
__ZX81SD_UNSHIFT_TABLE:
    DEFB 'z', 'x', 'c', 'v'
    DEFB 'a', 's', 'd', 'f', 'g'
    DEFB 'q', 'w', 'e', 'r', 't'
    DEFB '1', '2', '3', '4', '5'
    DEFB '0', '9', '8', '7', '6'
    DEFB 'p', 'o', 'i', 'u', 'y'
    DEFB 13,  'l', 'k', 'j', 'h'    ; NEWLINE -> ENTER (ASCII 13)
    DEFB ' ', '.', 'm', 'n', 'b'

; __ZX81SD_SYMBOL_TABLE — simbolos impresos en el teclado del ZX81 bajo
; SHIFT. Alineada posicion a posicion con __ZX81SD_UNSHIFT_TABLE (mismo
; indice = misma tecla fisica); la usa __ZX81SD_SYMBOL_FOR para el modo
; de composicion "." + tecla de stdlib/input.bas.
__ZX81SD_SYMBOL_TABLE:
    DEFB ':', ';', '?', '/'
    DEFB 0,   0,   0,   0,   0      ; STOP, LPRINT, SLOW, FAST, LLIST
    DEFB '"', 0,   0,   0,   0      ; "" (par de comillas), OR, STEP, <=, <>
    DEFB 0,   0,   0,   0,   0      ; EDIT, [CAPS LOCK], THEN, TO, cursor-izq
    DEFB 12,  0,   0,   0,   0      ; RUBOUT (DEL=12), GRAPHICS, cursor der/arr/abj
    DEFB '"', ')', '(', '$', 0      ; ", ), (, $, >=
    DEFB 0,   '=', '+', '-', 0      ; FUNCTION, =, +, -, **
    DEFB 0,   ',', '>', '<', '*'    ; £, ',', >, <, *

; __ZX81SD_CAPS_TABLE — igual que __ZX81SD_SYMBOL_TABLE, pero con la
; MAYUSCULA en cada posicion que en UNSHIFT_TABLE es una letra (para
; SHIFT+letra, y para el modo CAPS LOCK persistente). Las posiciones que
; no son letra se dejan igual que en SYMBOL_TABLE (digitos, ENTER,
; SPACE, RUBOUT...).
__ZX81SD_CAPS_TABLE:
    DEFB 'Z', 'X', 'C', 'V'
    DEFB 'A', 'S', 'D', 'F', 'G'
    DEFB 'Q', 'W', 'E', 'R', 'T'
    DEFB 0,   0,   0,   0,   0      ; digitos 1-5 (el "2" se intercepta antes)
    DEFB 12,  0,   0,   0,   0      ; digitos 0,9,8,7,6 (RUBOUT en el "0")
    DEFB 'P', 'O', 'I', 'U', 'Y'
    DEFB 0,   'L', 'K', 'J', 'H'    ; ENTER sin cambio, L/K/J/H en mayuscula
    DEFB 0,   ',', 'M', 'N', 'B'    ; SPACE sin cambio, "." no se alcanza aqui

; --- Estado persistente del teclado (sobrevive entre llamadas) ---
__ZX81SD_KBD_CAPSLOCK:   DEFB 0    ; 1 = CAPS LOCK activo
__ZX81SD_KBD_CAPS_EDGE:  DEFB 0    ; deteccion de flanco para el combo SHIFT+"2"

; --- Estado transitorio (se recalcula en cada llamada a __ZX81SD_KEYSCAN) ---
__ZX81SD_KBD_SHIFT:        DEFB 0
__ZX81SD_KBD_OTHER_VALID:  DEFB 0
__ZX81SD_KBD_OTHER_IDX:    DEFB 0

; ---------------------------------------------------------------------------
; __ZX81SD_KEYSCAN
;
; Escanea el teclado y decodifica la tecla pulsada segun el esquema de
; arriba (SHIFT como modificador de mayuscula, CAPS LOCK persistente).
;
; Devuelve:
;   A = codigo ASCII de la tecla pulsada, o 0 si no hay ninguna pulsada,
;       si la combinacion no tiene equivalente ASCII, si solo esta
;       pulsado SHIFT solo, o si se acaba de conmutar el CAPS LOCK
;       (SHIFT+"2").
;   Flag Z activo si A = 0
;
; Registros modificados: AF, BC, DE, HL
; ---------------------------------------------------------------------------
__ZX81SD_KEYSCAN:
    PROC
    LOCAL FIND_OTHER
    LOCAL ROW_LOOP
    LOCAL NEXT_ROW
    LOCAL FIND_COL
    LOCAL GOT_COL0
    LOCAL GOT_COL1
    LOCAL GOT_COL2
    LOCAL GOT_COL3
    LOCAL GOT_COL4
    LOCAL GOT_KEY
    LOCAL OTHER_FOUND
    LOCAL OTHER_NONE
    LOCAL NOT_ROW0

    LOCAL DECIDE
    LOCAL HAVE_SHIFT
    LOCAL SHIFT_ALONE
    LOCAL CHECK_CAPS_KEY
    LOCAL DO_CAPS_TOGGLE
    LOCAL CAPS_EDGE_DONE
    LOCAL NO_SHIFT
    LOCAL NO_KEY
    LOCAL USE_UNSHIFT
    LOCAL USE_CAPS_FOR_PLAIN
    LOCAL LOOKUP_OTHER_IN_HL
    LOCAL RESET_CAPS_EDGE

    LOCAL SHIFT_BIT_SET

    ; --- 1. Leer SHIFT (fila 0, columna 0) con una lectura dedicada ---
    ld bc, $FEFE
    in a, (c)
    and $01
    ld a, 1
    jr z, SHIFT_BIT_SET
    xor a
SHIFT_BIT_SET:
    ld (__ZX81SD_KBD_SHIFT), a

    ; --- 2. Buscar otra tecla pulsada (excluyendo SHIFT) ---
    xor a
    ld (__ZX81SD_KBD_OTHER_VALID), a
    call FIND_OTHER          ; carry activo = encontrada (indice en A)
    jr nc, DECIDE
    ld (__ZX81SD_KBD_OTHER_IDX), a
    ld a, 1
    ld (__ZX81SD_KBD_OTHER_VALID), a

DECIDE:
    ld a, (__ZX81SD_KBD_SHIFT)
    or a
    jr nz, HAVE_SHIFT
    jr NO_SHIFT

HAVE_SHIFT:
    ld a, (__ZX81SD_KBD_OTHER_VALID)
    or a
    jr nz, CHECK_CAPS_KEY

SHIFT_ALONE:
    ; Solo SHIFT: sin caracter, y se reinicia la deteccion de flanco del
    ; combo SHIFT+"2" (no puede haber toggle sin la tecla "2" presente).
    call RESET_CAPS_EDGE
    xor a
    ret

CHECK_CAPS_KEY:
    ld a, (__ZX81SD_KBD_OTHER_IDX)
    cp 15                    ; indice de la tecla "2" (fila 3, columna 1)
    jr z, DO_CAPS_TOGGLE

    ; SHIFT + letra (o cualquier otra tecla, salvo "2"): __ZX81SD_CAPS_TABLE
    ; (mayuscula en las posiciones de letra; en el resto, igual que
    ; __ZX81SD_SYMBOL_TABLE — p.ej. SHIFT+"." sigue dando ",").
    call RESET_CAPS_EDGE
    ld hl, __ZX81SD_CAPS_TABLE
    jr LOOKUP_OTHER_IN_HL

DO_CAPS_TOGGLE:
    ; Conmuta CAPS LOCK solo en el flanco de subida del combo (para no
    ; conmutarlo en cada llamada mientras se mantiene pulsado).
    ld a, (__ZX81SD_KBD_CAPS_EDGE)
    or a
    jr nz, CAPS_EDGE_DONE
    ld a, 1
    ld (__ZX81SD_KBD_CAPS_EDGE), a
    ld a, (__ZX81SD_KBD_CAPSLOCK)
    xor 1
    ld (__ZX81SD_KBD_CAPSLOCK), a
CAPS_EDGE_DONE:
    xor a                    ; SHIFT+"2" es mudo: nunca devuelve caracter
    ret

NO_SHIFT:
    call RESET_CAPS_EDGE

    ld a, (__ZX81SD_KBD_OTHER_VALID)
    or a
    jr z, NO_KEY

    ; Sin SHIFT: __ZX81SD_UNSHIFT_TABLE (minuscula), salvo que CAPS LOCK
    ; este activo, en cuyo caso se usa __ZX81SD_CAPS_TABLE (mayuscula en
    ; las letras). "." cae aqui igual que cualquier otra tecla: siempre
    ; devuelve "." (o "," si SHIFT, ya cubierto arriba).
    ld a, (__ZX81SD_KBD_CAPSLOCK)
    or a
    jr z, USE_UNSHIFT
    jr USE_CAPS_FOR_PLAIN

USE_UNSHIFT:
    ld hl, __ZX81SD_UNSHIFT_TABLE
    jr LOOKUP_OTHER_IN_HL

USE_CAPS_FOR_PLAIN:
    ld hl, __ZX81SD_CAPS_TABLE

LOOKUP_OTHER_IN_HL:
    ld a, (__ZX81SD_KBD_OTHER_IDX)
    ld e, a
    ld d, 0
    add hl, de
    ld a, (hl)
    or a
    ret

NO_KEY:
    xor a
    ret

RESET_CAPS_EDGE:
    xor a
    ld (__ZX81SD_KBD_CAPS_EDGE), a
    ret

; ---------------------------------------------------------------------------
; FIND_OTHER — busca una tecla pulsada distinta de SHIFT (fila 0, col 0).
; Devuelve acarreo INACTIVO si no encuentra ninguna; si encuentra una,
; acarreo ACTIVO y A = indice (0-38, formula fila*5+columna-1). Se usa el
; acarreo (no Z) porque el indice 0 (tecla Z) es un resultado valido con
; A=0, que haria Z activo por error si se usara ese flag para
; "encontrada/no encontrada".
; Registros modificados: AF, BC, DE, HL.
; ---------------------------------------------------------------------------
FIND_OTHER:
    ld d, 0                  ; D = indice de fila actual (0-7)
    ld b, $FE                ; B = mitad alta del puerto ($FEFE...$7FFE)

ROW_LOOP:
    ld c, $FE
    in a, (c)                ; lee la fila; bits 0-4 = columnas (0 = pulsada)
    and $1F

    ld l, a                  ; L = mapa de bits de columnas pulsadas

    ld a, d
    or a
    jr nz, NOT_ROW0
    set 0, l                 ; fila 0: descartar SHIFT (columna 0)
NOT_ROW0:
    ld a, l
    cp $1F
    jr z, NEXT_ROW           ; nada mas pulsado en esta fila

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
    jr NEXT_ROW              ; no deberia ocurrir (ya se comprobo cp $1F antes)

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
    add a, d                 ; A = fila*5
    add a, c                 ; A = fila*5 + columna
    dec a                    ; A = indice (0-38)
    jr OTHER_FOUND

NEXT_ROW:
    rlc b
    inc d
    ld a, d
    cp 8
    jr nz, ROW_LOOP

OTHER_NONE:
    xor a
    ret                      ; carry inactivo (xor siempre lo limpia)

OTHER_FOUND:
    scf                      ; carry activo; A ya tiene el indice (GOT_KEY)
    ret

    ENDP

; ---------------------------------------------------------------------------
; __ZX81SD_SYMBOL_FOR — dado un caracter ASCII (el que devolveria una
; pulsacion normal sin modificadores, es decir uno de los que aparecen en
; __ZX81SD_UNSHIFT_TABLE), devuelve el simbolo del ZX81 que le
; corresponde bajo el antiguo modificador SHIFT del ZX81 (o 0 si esa
; tecla no tiene simbolo). La usa stdlib/input.bas para componer simbolos
; como una "tecla muerta": el usuario pulsa "." y LUEGO esta tecla, sin
; necesitar mantenerlas pulsadas a la vez (ver cabecera del fichero).
;
; Entrada: A = caracter ASCII de la segunda tecla
; Salida:  A = simbolo del ZX81, o 0 si esa tecla no tiene simbolo
; Registros modificados: AF, BC, DE, HL
; ---------------------------------------------------------------------------
__ZX81SD_SYMBOL_FOR:
    PROC
    LOCAL SEARCH_LOOP
    LOCAL FOUND
    LOCAL NOT_FOUND

    ld c, a                  ; C = caracter buscado
    ld hl, __ZX81SD_UNSHIFT_TABLE
    ld de, __ZX81SD_SYMBOL_TABLE
    ld b, 39                 ; numero de entradas de ambas tablas

SEARCH_LOOP:
    ld a, (hl)
    cp c
    jr z, FOUND
    inc hl
    inc de
    djnz SEARCH_LOOP
    jr NOT_FOUND

FOUND:
    ld a, (de)
    or a
    ret

NOT_FOUND:
    xor a
    ret

    ENDP

    pop namespace
