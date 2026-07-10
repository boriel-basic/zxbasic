; fp_tostr.asm (zx81sd) — Conversión de un FLOAT a texto ASCII decimal
;
; Usado por printf.asm (PRINT de un FLOAT) y str.asm (STR$) en zx81sd.
;
; La ROM del Spectrum resuelve esto con PRINT-FP, una rutina enorme que
; además soporta notación científica (E-format) y se apoya en mecanismos
; ajenos a zx81sd (canales CHAN-OPEN, área de "workspace" del editor BASIC
; que crece con BC-SPACES). Aquí, por acuerdo explícito, se implementa una
; versión simplificada: signo + parte entera + hasta 5 decimales, sin
; notación científica, recortando ceros finales (y el punto si todos los
; decimales resultan cero). Cubre el uso habitual de PRINT/STR$ con FLOAT.
;
; Se apoya en el calculador ya portado (fp_calc.asm: duplicate/int/subtract/
; negate) y en rutinas Z80 puras ya existentes y verificadas en zx81sd:
; __FTOU32REG/__FTOU8 (conversión FLOAT -> entero, sin ROM) y __DIVU32.

#include once <fp_calc.asm>
#include once <stackf.asm>
#include once <ftou32reg.asm>
#include once <arith/div32.asm>

    push namespace core

; --- Variables de trabajo (no reentrante, uso transitorio) ------------------
FP_STR_ORIG:    defb 0, 0, 0, 0, 0  ; A E D C B del valor (se vuelve positivo)
FP_STR_INT:     defb 0, 0, 0, 0, 0  ; parte entera
FP_STR_FRAC:    defb 0, 0, 0, 0, 0  ; parte fraccionaria (se actualiza cada iteración)
FP_STR_COUNT:   defb 0              ; contador de decimales restantes
FP_STR_WR:      defw 0              ; cursor de escritura en FP_STR_BUF
FP_STR_BUF:     defs 24             ; buffer de salida (signo + entero + '.' + decimales)

; ---------------------------------------------------------------------------
; STORE5 — Guarda A,E,D,C,B en (HL),(HL+1)..(HL+4)
; LOAD5  — Carga A,E,D,C,B desde (HL),(HL+1)..(HL+4)
; (Z80 no tiene LD E,(nn)/LD D,(nn)/etc, solo LD A,(nn) y LD rr,(nn) con pares;
; por eso se accede siempre indirectamente vía HL.)
; ---------------------------------------------------------------------------
STORE5:
    ld   (hl), a
    inc  hl
    ld   (hl), e
    inc  hl
    ld   (hl), d
    inc  hl
    ld   (hl), c
    inc  hl
    ld   (hl), b
    ret

LOAD5:
    ld   a, (hl)
    inc  hl
    ld   e, (hl)
    inc  hl
    ld   d, (hl)
    inc  hl
    ld   c, (hl)
    inc  hl
    ld   b, (hl)
    ret

; ---------------------------------------------------------------------------
; EMIT_CHAR — Escribe A en el buffer de salida y avanza el cursor
; ---------------------------------------------------------------------------
EMIT_CHAR:
    push hl
    ld   hl, (FP_STR_WR)
    ld   (hl), a
    inc  hl
    ld   (FP_STR_WR), hl
    pop  hl
    ret

; ---------------------------------------------------------------------------
; EMIT_U32 — Escribe DEHL (entero sin signo de 32 bits) como digitos decimales
; en el buffer de salida (sin ceros a la izquierda; "0" si el valor es cero).
; Mismo algoritmo que __PRINTU32 (printi32.asm/printnum.asm), pero escribiendo
; en el buffer en vez de en pantalla.
; ---------------------------------------------------------------------------
EMIT_U32:
    PROC
    LOCAL EMIT_U32_LOOP
    LOCAL EMIT_U32_START
    LOCAL EMIT_U32_CONT

    ld   b, 0

EMIT_U32_LOOP:
    ld   a, h
    or   l
    or   d
    or   e
    jp   z, EMIT_U32_START

    push bc
    ld   bc, 0
    push bc
    ld   bc, 10
    push bc
    call __DIVU32
    pop  bc

    exx
    ld   a, l
    or   '0'
    push af
    exx
    inc  b
    jp   EMIT_U32_LOOP

EMIT_U32_START:
    ld   a, b
    or   a
    jp   nz, EMIT_U32_CONT
    ld   a, '0'
    call EMIT_CHAR
    ret

EMIT_U32_CONT:
    pop  af
    push bc
    call EMIT_CHAR
    pop  bc
    djnz EMIT_U32_CONT
    ret

    ENDP

; ---------------------------------------------------------------------------
; FP_TO_STR — Convierte un FLOAT a texto ASCII decimal
; Entrada: A,E,D,C,B = valor FLOAT (convención habitual del runtime)
; Salida:  HL = puntero al texto (sin prefijo de longitud), BC = longitud
; ---------------------------------------------------------------------------
FP_TO_STR:
    PROC
    LOCAL FP_TO_STR_POS
    LOCAL FP_TO_STR_POS2
    LOCAL FP_TO_STR_FRACLOOP
    LOCAL FP_TO_STR_FRACDONE
    LOCAL FP_TO_STR_TRIMLOOP
    LOCAL FP_TO_STR_TRIMDOT
    LOCAL FP_TO_STR_TRIMKEEP
    LOCAL FP_TO_STR_DONE

    ld   hl, FP_STR_ORIG
    call STORE5

    ld   hl, FP_STR_BUF
    ld   (FP_STR_WR), hl

    ; ¿Es cero? (forma canonica: A=0 y mantisa completa a 0)
    or   e
    or   d
    or   c
    or   b
    jr   nz, FP_TO_STR_POS
    ld   a, '0'
    call EMIT_CHAR
    jp   FP_TO_STR_DONE

FP_TO_STR_POS:
    ; El bit 7 de E es el signo tanto en formato entero-pequeno como en
    ; coma flotante completa (ver fp_calc.asm / __FTOU32REG).
    ld   a, (FP_STR_ORIG + 1)
    bit  7, a
    jr   z, FP_TO_STR_POS2

    ld   a, '-'
    call EMIT_CHAR

    ; Vuelve positivo el valor original (negate) para trabajar siempre en abs
    ld   hl, FP_STR_ORIG
    call LOAD5
    call __FPSTACK_PUSH
    rst  28h
    defb $1B                ;;negate
    defb $38                ;;end-calc
    call __FPSTACK_POP
    ld   hl, FP_STR_ORIG
    call STORE5

FP_TO_STR_POS2:
    ; intx = INT(x)  (x ya es >= 0 en este punto)
    ld   hl, FP_STR_ORIG
    call LOAD5
    call __FPSTACK_PUSH
    rst  28h
    defb $31                ;;duplicate
    defb $27                ;;int
    defb $38                ;;end-calc
    call __FPSTACK_POP
    ld   hl, FP_STR_INT
    call STORE5

    ; frac = x - intx
    ld   hl, FP_STR_INT
    call LOAD5
    call __FPSTACK_PUSH
    rst  28h
    defb $03                ;;subtract
    defb $38                ;;end-calc
    call __FPSTACK_POP
    ld   hl, FP_STR_FRAC
    call STORE5

    ; imprime la parte entera (ya es >= 0, cabe en 32 bits sin signo)
    ld   hl, FP_STR_INT
    call LOAD5
    call __FTOU32REG        ; DEHL = parte entera
    call EMIT_U32

    ld   a, '.'
    call EMIT_CHAR
    ld   a, 5
    ld   (FP_STR_COUNT), a

FP_TO_STR_FRACLOOP:
    ld   hl, FP_STR_FRAC
    call LOAD5
    call __FPSTACK_PUSH      ; pila: [frac]

    xor  a
    ld   d, 10
    ld   e, a
    ld   c, a
    ld   b, a
    call __FPSTACK_PUSH      ; pila: [frac, 10]
    rst  28h
    defb $04                ;;multiply
    defb $38                ;;end-calc
                             ; pila: [frac*10]
    rst  28h
    defb $31                ;;duplicate
    defb $27                ;;int
    defb $38                ;;end-calc
                             ; pila: [frac*10, digito]
    call __FPSTACK_POP
    call __FTOU8             ; A = digito (0-9)
    push af                  ; guarda el digito (igual que val.asm con rst 28h)

    pop  af
    push af
    ld   d, a
    xor  a
    ld   e, a
    ld   c, a
    ld   b, a
    call __FPSTACK_PUSH      ; pila: [frac*10, digito]
    rst  28h
    defb $03                ;;subtract
    defb $38                ;;end-calc
                             ; pila: [frac*10 - digito] = nuevo frac
    call __FPSTACK_POP
    ld   hl, FP_STR_FRAC
    call STORE5

    pop  af                  ; recupera el digito
    or   '0'
    call EMIT_CHAR

    ld   hl, FP_STR_COUNT
    dec  (hl)
    jr   nz, FP_TO_STR_FRACLOOP

FP_TO_STR_FRACDONE:
    ; recorta ceros finales (y el punto si todos los decimales eran cero)
    ld   hl, (FP_STR_WR)

FP_TO_STR_TRIMLOOP:
    dec  hl
    ld   a, (hl)
    cp   '.'
    jr   z, FP_TO_STR_TRIMDOT
    cp   '0'
    jr   nz, FP_TO_STR_TRIMKEEP
    jr   FP_TO_STR_TRIMLOOP

FP_TO_STR_TRIMDOT:
    ld   (FP_STR_WR), hl
    jp   FP_TO_STR_DONE

FP_TO_STR_TRIMKEEP:
    inc  hl
    ld   (FP_STR_WR), hl

FP_TO_STR_DONE:
    ld   hl, (FP_STR_WR)
    ld   de, FP_STR_BUF
    or   a
    sbc  hl, de              ; HL = longitud del texto
    ld   b, h
    ld   c, l
    ld   hl, FP_STR_BUF
    ret

    ENDP

    pop namespace
