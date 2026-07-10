; sd81_mcu.asm (zx81sd) — Primitivas del protocolo del MCU del SD81 Booster
; para uso desde el RUNTIME en ensamblador (load.asm / save.asm).
;
; (La stdlib mcu.bas lleva sus propias copias de estas rutinas dentro de
; SUBs fastcall; aqui viven las de los statements LOAD/SAVE del compilador.)
;
; Protocolo: puerto $A7 = datos, puerto $AF = reloj (bit 7). El MCU
; invierte el bit de reloj cuando procesa cada lectura/escritura de $A7;
; tras cada operacion hay que esperar ese cambio. NUNCA escribir en $AF
; (provoca un reset del MCU).

    push namespace core

SD81_MCU_DATA   EQU $A7
SD81_MCU_CLOCK  EQU $AF

; ---------------------------------------------------------------------------
; SD81_MCU_SEND — Envia el byte A al MCU y espera a que lo procese.
; Preserva BC, DE, HL. Modifica AF.
; ---------------------------------------------------------------------------
SD81_MCU_SEND:
    PROC
    LOCAL WAIT
    push bc
    ld   b, a               ; salva el dato
    in   a, (SD81_MCU_CLOCK)
    ld   c, a               ; C = reloj previo
    ld   a, b
    out  (SD81_MCU_DATA), a
WAIT:
    in   a, (SD81_MCU_CLOCK)
    xor  c
    jp   p, WAIT
    pop  bc
    ret
    ENDP

; ---------------------------------------------------------------------------
; SD81_MCU_RECV — Lee un byte del MCU en A y espera el toggle posterior.
; Preserva BC, DE, HL. Modifica AF.
; ---------------------------------------------------------------------------
SD81_MCU_RECV:
    PROC
    LOCAL WAIT
    push bc
    in   a, (SD81_MCU_CLOCK)
    ld   c, a               ; reloj previo
    in   a, (SD81_MCU_DATA) ; lee el dato (dispara el toggle del MCU)
    ld   b, a
WAIT:
    in   a, (SD81_MCU_CLOCK)
    xor  c
    jp   p, WAIT
    ld   a, b
    pop  bc
    ret
    ENDP

; ---------------------------------------------------------------------------
; SD81_MCU_SEND_BLOCK — Envia BC bytes desde (HL) al MCU.
; Modifica AF, BC, E, HL. Devuelve HL apuntando tras el bloque.
; ---------------------------------------------------------------------------
SD81_MCU_SEND_BLOCK:
    PROC
    LOCAL LOOP, WAIT
    ld   a, b
    or   c
    ret  z
LOOP:
    in   a, (SD81_MCU_CLOCK)
    ld   e, a               ; reloj previo
    ld   a, (hl)
    out  (SD81_MCU_DATA), a
WAIT:
    in   a, (SD81_MCU_CLOCK)
    xor  e
    jp   p, WAIT
    inc  hl
    dec  bc
    ld   a, b
    or   c
    jr   nz, LOOP
    ret
    ENDP

; ---------------------------------------------------------------------------
; SD81_MCU_RECV_BLOCK — Recibe BC bytes del MCU en (HL).
; Modifica AF, BC, E, HL.
; ---------------------------------------------------------------------------
SD81_MCU_RECV_BLOCK:
    PROC
    LOCAL LOOP, WAIT
    ld   a, b
    or   c
    ret  z
LOOP:
    in   a, (SD81_MCU_CLOCK)
    ld   e, a
    in   a, (SD81_MCU_DATA)
    ld   (hl), a
WAIT:
    in   a, (SD81_MCU_CLOCK)
    xor  e
    jp   p, WAIT
    inc  hl
    dec  bc
    ld   a, b
    or   c
    jr   nz, LOOP
    ret
    ENDP

; ---------------------------------------------------------------------------
; SD81_MCU_RECV_VERIFY — Recibe BC bytes y los compara con (HL).
; Devuelve A = 0 si todo coincide, A = 1 si hubo diferencias.
; (Consume siempre los BC bytes para no desincronizar el protocolo.)
; Modifica AF, BC, DE, HL.
; ---------------------------------------------------------------------------
SD81_MCU_RECV_VERIFY:
    PROC
    LOCAL LOOP, WAIT, SAME
    ld   d, 0               ; flag de diferencias
    ld   a, b
    or   c
    jr   z, SAME
LOOP:
    in   a, (SD81_MCU_CLOCK)
    ld   e, a
    in   a, (SD81_MCU_DATA)
    cp   (hl)
    jr   z, WAIT
    ld   d, 1               ; difiere
WAIT:
    in   a, (SD81_MCU_CLOCK)
    xor  e
    jp   p, WAIT
    inc  hl
    dec  bc
    ld   a, b
    or   c
    jr   nz, LOOP
SAME:
    ld   a, d
    ret
    ENDP

; ---------------------------------------------------------------------------
; SD81_MCU_RECV_SINK — Recibe y descarta BC bytes (mantiene el protocolo
; sincronizado cuando el fichero es mayor que el buffer del llamador).
; Modifica AF, BC, E.
; ---------------------------------------------------------------------------
SD81_MCU_RECV_SINK:
    PROC
    LOCAL LOOP, WAIT
    ld   a, b
    or   c
    ret  z
LOOP:
    in   a, (SD81_MCU_CLOCK)
    ld   e, a
    in   a, (SD81_MCU_DATA)
WAIT:
    in   a, (SD81_MCU_CLOCK)
    xor  e
    jp   p, WAIT
    dec  bc
    ld   a, b
    or   c
    jr   nz, LOOP
    ret
    ENDP

; ---------------------------------------------------------------------------
; SD81_ASC2ZX — Convierte el caracter ASCII en A a codigo de caracter
; ZX81 (los nombres de fichero de los comandos del MCU viajan en ZX81).
; Sin equivalente -> '?' ($0F). Preserva BC, DE, HL.
; ---------------------------------------------------------------------------
SD81_ASC2ZX:
    PROC
    LOCAL NOT_LOWER, NOT_UPPER, NOT_DIGIT, TABLE, TLOOP, TDONE
    cp   'a'
    jr   c, NOT_LOWER
    cp   'z' + 1
    jr   nc, NOT_LOWER
    sub  32                 ; a mayuscula
NOT_LOWER:
    cp   'A'
    jr   c, NOT_UPPER
    cp   'Z' + 1
    jr   nc, NOT_UPPER
    sub  'A' - 38           ; letras: codigos 38-63
    ret
NOT_UPPER:
    cp   '0'
    jr   c, NOT_DIGIT
    cp   '9' + 1
    jr   nc, NOT_DIGIT
    sub  '0' - 28           ; digitos: codigos 28-37
    ret
NOT_DIGIT:
    push hl
    push bc
    ld   hl, TABLE
    ld   b, (TDONE - TABLE) / 2
TLOOP:
    cp   (hl)
    inc  hl
    jr   z, TDONE           ; encontrado: (HL) = codigo ZX81
    inc  hl
    djnz TLOOP
    ld   a, $0F             ; sin equivalente: '?'
    pop  bc
    pop  hl
    ret
TDONE:
    ld   a, (hl)
    pop  bc
    pop  hl
    ret

TABLE:                      ; pares ASCII, codigo ZX81
    defb ' ', $00
    defb '.', $1B
    defb '/', $18
    defb '-', $16
    defb '*', $17
    defb '<', $13
    defb '>', $12
    defb '(', $10
    defb ')', $11
    defb '$', $0D
    defb ':', $0E
    defb ',', $1A
    defb ';', $19
    defb '+', $15
    defb '=', $14
    defb '"', $0B
    ENDP

; ---------------------------------------------------------------------------
; SD81_MCU_SEND_NAME — Envia un string de zxbasic (prefijo de longitud de
; 16 bits + datos) como cadena Pascal para el MCU: byte de longitud
; (recortada a 255) + caracteres convertidos a codigos ZX81.
; Entrada: HL = puntero al string (al prefijo de longitud). HL != 0.
; Modifica AF, BC, HL.
; ---------------------------------------------------------------------------
SD81_MCU_SEND_NAME:
    PROC
    LOCAL LOOP, LENOK
    ld   c, (hl)
    inc  hl
    ld   b, (hl)
    inc  hl                 ; BC = longitud, HL -> caracteres
    ld   a, b
    or   a
    jr   z, LENOK
    ld   c, 255             ; recorta a 255 (limite del protocolo)
LENOK:
    ld   a, c
    call SD81_MCU_SEND      ; longitud
    ld   a, c
    or   a
    ret  z
    ld   b, c
LOOP:
    ld   a, (hl)
    call SD81_ASC2ZX
    call SD81_MCU_SEND
    inc  hl
    djnz LOOP
    ret
    ENDP

    pop namespace
