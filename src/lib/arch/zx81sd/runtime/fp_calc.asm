; ===========================================================================
; fp_calc.asm — Calculador de coma flotante (RST $28h) para ZX81 + SD81 Booster
;
; Port del calculador de la ROM del ZX Spectrum 48K (CALCULATE, $335B, y las
; rutinas de las que depende) a código propio en RAM, ya que en zx81sd no hay
; ninguna ROM mapeada en tiempo de ejecucion (el bloque 0 lo ocupa entero
; nuestro binario compilado).
;
; Gracias a este port, todo el runtime de coma flotante de zx48k (addf.asm,
; subf.asm, mulf.asm, divf.asm, negf.asm, cmp/*.asm, bool/*.asm, math/*.asm,
; str.asm, printf.asm, val.asm...) funciona TAL CUAL, sin modificar ni un
; solo fichero: todos ellos hacen "rst 28h" seguido de bytes de "literal" de
; operacion calculadora, y ahora $0028 contiene codigo real (ver
; src/arch/zx81sd/backend/main.py, emit_prologue) en vez de un DI/HALT.
;
; FASE 1 (este fichero): motor CALCULATE + pila de numeros FP + aritmetica
; (suma/resta/multiplicacion/division) + comparaciones numericas + booleanas
; (AND/OR/NOT) + funciones unarias basicas (ABS/NEGATE/SGN/INT/truncate).
; Pendiente en fases posteriores: SIN/COS/TAN/ASN/ACS/ATN/LN/EXP/SQR (usan el
; "series generator" ya portado aqui, mas la tabla de coeficientes de cada
; funcion, que aun no esta), STR$ (conversion numero->texto) y VAL (parseo de
; texto->numero, con semantica simplificada: solo literales decimales, no
; evaluacion de expresiones completas como hace la ROM real — ver conversacion
; de diseño).
;
; Formato de los numeros (5 bytes), identico al de la ROM Spectrum:
;   Entero pequeño:  byte1=$00, byte2=signo($00/$FF), byte3=lo, byte4=hi, byte5=$00
;   Coma flotante:   byte1=exponente sesgado(+$80), byte2..5=mantisa de 32 bits
;                    con el bit 7 del byte2 usado como signo (bit de mantisa
;                    implicito, siempre a 1 salvo cuando se usa para el signo)
;
; Referencia: disassembly comentado de la ROM del ZX Spectrum 48K
; (C:\ClaudeCode\ZXBASIC-SD81\Spectrum48.asm), seccion "FLOATING-POINT
; CALCULATOR". Las etiquetas Lxxxx conservan la direccion original de la ROM
; (solo como identificador legible, no como direccion real: aqui son
; reubicables) para facilitar la referencia cruzada con el disassembly.
; ===========================================================================

#include once <sysvars.asm>
#include once <error.asm>
#include once <stackf.asm>
; fp_calc.asm se incluye siempre (no solo cuando el programa usa FLOAT):
; ver src/arch/zx81sd/backend/main.py. Por eso debe bastarse a si mismo e
; incluir aqui stackf.asm (de donde vienen __FPSTACK_PUSH/__FPSTACK_POP),
; en vez de depender de que el fichero que lo incluya lo haga tambien.

    push namespace core

; ---------------------------------------------------------------------------
; Punto de entrada — sustituye a RST $28h
; ---------------------------------------------------------------------------
FP_CALC_ENTRY:
    jp L335B

; ---------------------------------------------------------------------------
; TEST-ROOM propio — sustituye a TEST-ROOM ($1F05, que comprobaba espacio
; libre contra el puntero de pila SP). Aqui la pila de numeros FP es un
; buffer fijo (FP_CALC_STACK..FP_CALC_STACK_END en sysvars.asm), asi que
; basta comprobar que FP_STKEND + BC no se sale del buffer.
; Entrada: BC = bytes requeridos. Sale con BC intacto si hay espacio.
; ---------------------------------------------------------------------------
CALC_TEST_ROOM:
    push hl
    push de
    ld   hl, (FP_STKEND)
    add  hl, bc
    ld   de, FP_CALC_STACK_END
    or   a
    sbc  hl, de
    pop  de
    pop  hl
    jr   c, CALC_TEST_ROOM_OK
    ld   a, ERROR_OutOfMemory
    jp   __ERROR
CALC_TEST_ROOM_OK:
    ret

; ---------------------------------------------------------------------------
; THE 'TEST FIVE SPACES' SUBROUTINE ($33A9 TEST-5-SP)
; ---------------------------------------------------------------------------
L33A9:
    push de
    push hl
    ld   bc, 5
    call CALC_TEST_ROOM
    pop  hl
    pop  de
    ret

; ---------------------------------------------------------------------------
; STACK-NUM ($33B4) — apila un numero de 5 bytes apuntado por HL
; ---------------------------------------------------------------------------
L33B4:
    ld   de, (FP_STKEND)
    call L33C0
    ld   (FP_STKEND), de
    ret

; ---------------------------------------------------------------------------
; MOVE-FP / duplicate (literal $31, $33C0)
; ---------------------------------------------------------------------------
L33C0:
    call L33A9
    ldir
    ret

; ---------------------------------------------------------------------------
; stk-data (literal $34, $33C6) / STK-CONST ($33C8) / STK-ZEROS ($33F1)
; ---------------------------------------------------------------------------
L33C6:
    ld   h, d
    ld   l, e

L33C8:
    call L33A9
    exx
    push hl
    exx
    ex   (sp), hl
    push bc
    ld   a, (hl)
    and  $C0
    rlca
    rlca
    ld   c, a
    inc  c
    ld   a, (hl)
    and  $3F
    jr   nz, L33DE
    inc  hl
    ld   a, (hl)
L33DE:
    add  a, $50
    ld   (de), a
    ld   a, 5
    sub  c
    inc  hl
    inc  de
    ld   b, 0
    ldir
    pop  bc
    ex   (sp), hl
    exx
    pop  hl
    exx
    ld   b, a
    xor  a
L33F1:
    dec  b
    ret  z
    ld   (de), a
    inc  de
    jr   L33F1

; ---------------------------------------------------------------------------
; SKIP-CONS ($33F7 / $33F8)
; ---------------------------------------------------------------------------
L33F7:
    and  a
L33F8:
    ret  z
    push af
    push de
    ld   de, 0
    call L33C8
    pop  de
    pop  af
    dec  a
    jr   L33F8

; ---------------------------------------------------------------------------
; LOC-MEM ($3406)
; ---------------------------------------------------------------------------
L3406:
    ld   c, a
    rlca
    rlca
    add  a, c
    ld   c, a
    ld   b, 0
    add  hl, bc
    ret

; ---------------------------------------------------------------------------
; get-mem-xx (literales $E0-$FF, $340F)
; ---------------------------------------------------------------------------
L340F:
    push de
    ld   hl, (FP_MEM)
    call L3406
    call L33C0
    pop  hl
    ret

; ---------------------------------------------------------------------------
; stk-const-xx (literales $A0-$BF, $341B) + tabla de constantes
; ---------------------------------------------------------------------------
L341B:
    ld   h, d
    ld   l, e
    exx
    push hl
    ld   hl, L32C5
    exx
    call L33F7
    call L33C8
    exx
    pop  hl
    exx
    ret

; ---------------------------------------------------------------------------
; st-mem-xx (literales $C0-$DF, $342D)
; ---------------------------------------------------------------------------
L342D:
    push hl
    ex   de, hl
    ld   hl, (FP_MEM)
    call L3406
    ex   de, hl
    call L33C0
    ex   de, hl
    pop  hl
    ret

; ---------------------------------------------------------------------------
; exchange (literal $01, $343C)
; ---------------------------------------------------------------------------
L343C:
    ld   b, 5
L343E:
    ld   a, (de)
    ld   c, (hl)
    ex   de, hl
    ld   (de), a
    ld   (hl), c
    inc  hl
    inc  de
    djnz L343E
    ex   de, hl
    ret

; ---------------------------------------------------------------------------
; series generator (literales $80-$9F, $3449) — necesario para SIN/COS/EXP/LN
; (aun sin las tablas de coeficientes; se añadirán en una fase posterior)
; ---------------------------------------------------------------------------
L3449:
    ld   b, a
    call L335E
    defb $31            ;;duplicate       x,x
    defb $0F            ;;addition        x+x
    defb $C0            ;;st-mem-0        x+x
    defb $02            ;;delete          .
    defb $A0            ;;stk-zero        0
    defb $C2            ;;st-mem-2        0
L3453:
    defb $31            ;;duplicate       v,v.
    defb $E0            ;;get-mem-0       v,v,x+2
    defb $04            ;;multiply        v,v*x+2
    defb $E2            ;;get-mem-2       v,v*x+2,v
    defb $C1            ;;st-mem-1
    defb $03            ;;subtract
    defb $38            ;;end-calc
    call L33C6
    call L3362
    defb $0F            ;;addition
    defb $01            ;;exchange
    defb $C2            ;;st-mem-2
    defb $02            ;;delete
    defb $35            ;;dec-jr-nz
    defb (L3453 - $) & 0FFh   ;;back to G-LOOP
    defb $E1            ;;get-mem-1
    defb $03            ;;subtract
    defb $38            ;;end-calc
    ret

; ---------------------------------------------------------------------------
; abs (literal $2A, $346A) / negate (literal $1B, $346E) / sgn (literal $29,
; $3492)
; ---------------------------------------------------------------------------
L346A:
    ld   b, $FF
    jr   L3474

L346E:
    call L34E9
    ret  c
    ld   b, 0
L3474:
    ld   a, (hl)
    and  a
    jr   z, L3483
    inc  hl
    ld   a, b
    and  $80
    or   (hl)
    rla
    ccf
    rra
    ld   (hl), a
    dec  hl
    ret
L3483:
    push de
    push hl
    call L2D7F
    pop  hl
    ld   a, b
    or   c
    cpl
    ld   c, a
    call L2D8E
    pop  de
    ret

L3492:
    call L34E9
    ret  c
    push de
    ld   de, 1
    inc  hl
    rl   (hl)
    dec  hl
    sbc  a, a
    ld   c, a
    call L2D8E
    pop  de
    ret

; ---------------------------------------------------------------------------
; INT-FETCH ($2D7F) / INT-STORE ($2D8E)
; ---------------------------------------------------------------------------
L2D7F:
    inc  hl
    ld   c, (hl)
    inc  hl
    ld   a, (hl)
    xor  c
    sub  c
    ld   e, a
    inc  hl
    ld   a, (hl)
    adc  a, c
    xor  c
    ld   d, a
    ret

L2D8E:
    push hl
    ld   (hl), 0
    inc  hl
    ld   (hl), c
    inc  hl
    ld   a, e
    xor  c
    sub  c
    ld   (hl), a
    inc  hl
    ld   a, d
    adc  a, c
    xor  c
    ld   (hl), a
    inc  hl
    ld   (hl), 0
    pop  hl
    ret

; ---------------------------------------------------------------------------
; PREP-ADD ($2F9B)
; ---------------------------------------------------------------------------
L2F9B:
    ld   a, (hl)
    ld   (hl), 0
    and  a
    ret  z
    inc  hl
    bit  7, (hl)
    set  7, (hl)
    dec  hl
    ret  z
    push bc
    ld   bc, 5
    add  hl, bc
    ld   b, c
    ld   c, a
    scf
L2FAF:
    dec  hl
    ld   a, (hl)
    cpl
    adc  a, 0
    ld   (hl), a
    djnz L2FAF
    ld   a, c
    pop  bc
    ret

; ---------------------------------------------------------------------------
; FETCH-TWO ($2FBA)
; ---------------------------------------------------------------------------
L2FBA:
    push hl
    push af
    ld   c, (hl)
    inc  hl
    ld   b, (hl)
    ld   (hl), a
    inc  hl
    ld   a, c
    ld   c, (hl)
    push bc
    inc  hl
    ld   c, (hl)
    inc  hl
    ld   b, (hl)
    ex   de, hl
    ld   d, a
    ld   e, (hl)
    push de
    inc  hl
    ld   d, (hl)
    inc  hl
    ld   e, (hl)
    push de
    exx
    pop  de
    pop  hl
    pop  bc
    exx
    inc  hl
    ld   d, (hl)
    inc  hl
    ld   e, (hl)
    pop  af
    pop  hl
    ret

; ---------------------------------------------------------------------------
; SHIFT-FP ($2FDD) / ADD-BACK ($3004)
; ---------------------------------------------------------------------------
L2FDD:
    and  a
    ret  z
    cp   $21
    jr   nc, L2FF9
    push bc
    ld   b, a
L2FE5:
    exx
    sra  l
    rr   d
    rr   e
    exx
    rr   d
    rr   e
    djnz L2FE5
    pop  bc
    ret  nc
    call L3004
    ret  nz
L2FF9:
    exx
    xor  a
L2FFB:
    ld   l, 0
    ld   d, a
    ld   e, l
    exx
    ld   de, 0
    ret

L3004:
    inc  e
    ret  nz
    inc  d
    ret  nz
    exx
    inc  e
    jr   nz, L300D
    inc  d
L300D:
    exx
    ret

; ---------------------------------------------------------------------------
; subtract (literal $03, $300F) / addition (literal $0F, $3014)
; ---------------------------------------------------------------------------
L300F:
    ex   de, hl
    call L346E
    ex   de, hl

L3014:
    ld   a, (de)
    or   (hl)
    jr   nz, L303E
    push de
    inc  hl
    push hl
    inc  hl
    ld   e, (hl)
    inc  hl
    ld   d, (hl)
    inc  hl
    inc  hl
    inc  hl
    ld   a, (hl)
    inc  hl
    ld   c, (hl)
    inc  hl
    ld   b, (hl)
    pop  hl
    ex   de, hl
    add  hl, bc
    ex   de, hl
    adc  a, (hl)
    rrca
    adc  a, 0
    jr   nz, L303C
    sbc  a, a
    ld   (hl), a
    inc  hl
    ld   (hl), e
    inc  hl
    ld   (hl), d
    dec  hl
    dec  hl
    dec  hl
    pop  de
    ret
L303C:
    dec  hl
    pop  de
L303E:
    call L3293
    exx
    push hl
    exx
    push de
    push hl
    call L2F9B
    ld   b, a
    ex   de, hl
    call L2F9B
    ld   c, a
    cp   b
    jr   nc, L3055
    ld   a, b
    ld   b, c
    ex   de, hl
L3055:
    push af
    sub  b
    call L2FBA
    call L2FDD
    pop  af
    pop  hl
    ld   (hl), a
    push hl
    ld   l, b
    ld   h, c
    add  hl, de
    exx
    ex   de, hl
    adc  hl, bc
    ex   de, hl
    ld   a, h
    adc  a, l
    ld   l, a
    rra
    xor  l
    exx
    ex   de, hl
    pop  hl
    rra
    jr   nc, L307C
    ld   a, 1
    call L2FDD
    inc  (hl)
    jr   z, L309F
L307C:
    exx
    ld   a, l
    and  $80
    exx
    inc  hl
    ld   (hl), a
    dec  hl
    jr   z, L30A5
    ld   a, e
    neg
    ccf
    ld   e, a
    ld   a, d
    cpl
    adc  a, 0
    ld   d, a
    exx
    ld   a, e
    cpl
    adc  a, 0
    ld   e, a
    ld   a, d
    cpl
    adc  a, 0
    jr   nc, L30A3
    rra
    exx
    inc  (hl)
L309F:
    jp   z, L31AD
    exx
L30A3:
    ld   d, a
    exx
L30A5:
    xor  a
    jp   L3155

; ---------------------------------------------------------------------------
; HL-HL*DE ($30A9) / PREP-M/D ($30C0)
; ---------------------------------------------------------------------------
L30A9:
    push bc
    ld   b, 16
    ld   a, h
    ld   c, l
    ld   hl, 0
L30B1:
    add  hl, hl
    jr   c, L30BE
    rl   c
    rla
    jr   nc, L30BC
    add  hl, de
    jr   c, L30BE
L30BC:
    djnz L30B1
L30BE:
    pop  bc
    ret

L30C0:
    call L34E9
    ret  c
    inc  hl
    xor  (hl)
    set  7, (hl)
    dec  hl
    ret

; ---------------------------------------------------------------------------
; multiply (literal $04, $30CA)
; ---------------------------------------------------------------------------
L30CA:
    ld   a, (de)
    or   (hl)
    jr   nz, L30F0
    push de
    push hl
    push de
    call L2D7F
    ex   de, hl
    ex   (sp), hl
    ld   b, c
    call L2D7F
    ld   a, b
    xor  c
    ld   c, a
    pop  hl
    call L30A9
    ex   de, hl
    pop  hl
    jr   c, L30EF
    ld   a, d
    or   e
    jr   nz, L30EA
    ld   c, a
L30EA:
    call L2D8E
    pop  de
    ret
L30EF:
    pop  de
L30F0:
    call L3293
    xor  a
    call L30C0
    ret  c
    exx
    push hl
    exx
    push de
    ex   de, hl
    call L30C0
    ex   de, hl
    jr   c, L315D
    push hl
    call L2FBA
    ld   a, b
    and  a
    sbc  hl, hl
    exx
    push hl
    sbc  hl, hl
    exx
    ld   b, $21
    jr   L3125
L3114:
    jr   nc, L311B
    add  hl, de
    exx
    adc  hl, de
    exx
L311B:
    exx
    rr   h
    rr   l
    exx
    rr   h
    rr   l
L3125:
    exx
    rr   b
    rr   c
    exx
    rr   c
    rra
    djnz L3114
    ex   de, hl
    exx
    ex   de, hl
    exx
    pop  bc
    pop  hl
    ld   a, b
    add  a, c
    jr   nz, L313B
    and  a
L313B:
    dec  a
    ccf
L313D:
    rla
    ccf
    rra
    jp   p, L3146
    jr   nc, L31AD
    and  a
L3146:
    inc  a
    jr   nz, L3151
    jr   c, L3151
    exx
    bit  7, d
    exx
    jr   nz, L31AD
L3151:
    ld   (hl), a
    exx
    ld   a, b
    exx
L3155:
    jr   nc, L316C
    ld   a, (hl)
    and  a
L3159:
    ld   a, $80
    jr   z, L315E
L315D:
    xor  a
L315E:
    exx
    and  d
    call L2FFB
    rlca
    ld   (hl), a
    jr   c, L3195
    inc  hl
    ld   (hl), a
    dec  hl
    jr   L3195
L316C:
    ld   b, $20
L316E:
    exx
    bit  7, d
    exx
    jr   nz, L3186
    rlca
    rl   e
    rl   d
    exx
    rl   e
    rl   d
    exx
    dec  (hl)
    jr   z, L3159
    djnz L316E
    jr   L315D
L3186:
    rla
    jr   nc, L3195
    call L3004
    jr   nz, L3195
    exx
    ld   d, $80
    exx
    inc  (hl)
    jr   z, L31AD
L3195:
    push hl
    inc  hl
    exx
    push de
    exx
    pop  bc
    ld   a, b
    rla
    rl   (hl)
    rra
    ld   (hl), a
    inc  hl
    ld   (hl), c
    inc  hl
    ld   (hl), d
    inc  hl
    ld   (hl), e
    pop  hl
    pop  de
    exx
    pop  hl
    exx
    ret

L31AD:
    ld   a, ERROR_NumberTooBig
    jp   __ERROR

; ---------------------------------------------------------------------------
; division (literal $05, $31AF)
; ---------------------------------------------------------------------------
L31AF:
    call L3293
    ex   de, hl
    xor  a
    call L30C0
    jr   c, L31AD
    ex   de, hl
    call L30C0
    ret  c
    exx
    push hl
    exx
    push de
    push hl
    call L2FBA
    exx
    push hl
    ld   h, b
    ld   l, c
    exx
    ld   h, c
    ld   l, b
    xor  a
    ld   b, $DF
    jr   L31E2
L31D2:
    rla
    rl   c
    exx
    rl   c
    rl   b
    exx
L31DB:
    add  hl, hl
    exx
    adc  hl, hl
    exx
    jr   c, L31F2
L31E2:
    sbc  hl, de
    exx
    sbc  hl, de
    exx
    jr   nc, L31F9
    add  hl, de
    exx
    adc  hl, de
    exx
    and  a
    jr   L31FA
L31F2:
    and  a
    sbc  hl, de
    exx
    sbc  hl, de
    exx
L31F9:
    scf
L31FA:
    inc  b
    jp   m, L31D2
    push af
    jr   z, L31E2
    ld   e, a
    ld   d, c
    exx
    ld   e, c
    ld   d, b
    pop  af
    rr   b
    pop  af
    rr   b
    exx
    pop  bc
    pop  hl
    ld   a, b
    sub  c
    jp   L313D

; ---------------------------------------------------------------------------
; Integer truncation towards zero (literal $3A, $3214)
; ---------------------------------------------------------------------------
L3214:
    ld   a, (hl)
    and  a
    ret  z
    cp   $81
    jr   nc, L3221
    ld   (hl), 0
    ld   a, $20
    jr   L3272
L3221:
    cp   $91
    jr   nz, L323F
    inc  hl
    inc  hl
    inc  hl
    ld   a, $80
    and  (hl)
    dec  hl
    or   (hl)
    dec  hl
    jr   nz, L3233
    ld   a, $80
    xor  (hl)
L3233:
    dec  hl
    jr   nz, L326C
    ld   (hl), a
    inc  hl
    ld   (hl), $FF
    dec  hl
    ld   a, $18
    jr   L3272
L323F:
    jr   nc, L326D
    push de
    cpl
    add  a, $91
    inc  hl
    ld   d, (hl)
    inc  hl
    ld   e, (hl)
    dec  hl
    dec  hl
    ld   c, 0
    bit  7, d
    jr   z, L3252
    dec  c
L3252:
    set  7, d
    ld   b, 8
    sub  b
    add  a, b
    jr   c, L325E
    ld   e, d
    ld   d, 0
    sub  b
L325E:
    jr   z, L3267
    ld   b, a
L3261:
    srl  d
    rr   e
    djnz L3261
L3267:
    call L2D8E
    pop  de
    ret
L326C:
    ld   a, (hl)
L326D:
    sub  $A0
    ret  p
    neg
L3272:
    push de
    ex   de, hl
    dec  hl
    ld   b, a
    srl  b
    srl  b
    srl  b
    jr   z, L3283
L327E:
    ld   (hl), 0
    dec  hl
    djnz L327E
L3283:
    and  $07
    jr   z, L3290
    ld   b, a
    ld   a, $FF
L328A:
    sla  a
    djnz L328A
    and  (hl)
    ld   (hl), a
L3290:
    ex   de, hl
    pop  de
    ret

; ---------------------------------------------------------------------------
; RE-ST-TWO ($3293) / RESTK-SUB ($3296) / re-stack (literal $3D, $3297)
; ---------------------------------------------------------------------------
L3293:
    call L3296
L3296:
    ex   de, hl
L3297:
    ld   a, (hl)
    and  a
    ret  nz
    push de
    call L2D7F
    xor  a
    inc  hl
    ld   (hl), a
    dec  hl
    ld   (hl), a
    ld   b, $91
    ld   a, d
    and  a
    jr   nz, L32B1
    or   e
    ld   b, d
    jr   z, L32BD
    ld   d, e
    ld   e, b
    ld   b, $89
L32B1:
    ex   de, hl
L32B2:
    dec  b
    add  hl, hl
    jr   nc, L32B2
    rrc  c
    rr   h
    rr   l
    ex   de, hl
L32BD:
    dec  hl
    ld   (hl), e
    dec  hl
    ld   (hl), d
    dec  hl
    ld   (hl), b
    pop  de
    ret

; ---------------------------------------------------------------------------
; THE 'TABLE OF CONSTANTS' ($32C5-$32D6)
; ---------------------------------------------------------------------------
L32C5:  ;;stk-zero
    defb $00, $B0, $00
L32C8:  ;;stk-one
    defb $40, $B0, $00, $01
L32CC:  ;;stk-half
    defb $30, $00
L32CE:  ;;stk-pi/2
    defb $F1, $49, $0F, $DA, $A2
L32D3:  ;;stk-ten
    defb $40, $B0, $00, $0A

; ---------------------------------------------------------------------------
; THE 'TABLE OF ADDRESSES' ($32D7) — tbl-addrs
;
; Las entradas para funciones no soportadas (cadenas, USR, PEEK, IN, CODE,
; LEN, READ-IN, VAL$) apuntan a CALC_UNSUPPORTED, que detiene la ejecucion
; con un error claro si alguna vez se generase ese literal (no deberia
; ocurrir: el compilador de ZX BASIC no emite esos literales para nuestro
; runtime, ver la lista de literales usados en arith/cmp/bool/math/*.asm).
; ---------------------------------------------------------------------------
L32D7:
    defw L368F         ; $00 jump-true
    defw L343C         ; $01 exchange
    defw L33A1         ; $02 delete
    defw L300F         ; $03 subtract
    defw L30CA         ; $04 multiply
    defw L31AF         ; $05 division
    defw L3851          ; $06 to-power
    defw L351B         ; $07 or
    defw L3524         ; $08 no-&-no
    defw L353B         ; $09 no-l-eql
    defw L353B         ; $0A no-gr-eql
    defw L353B         ; $0B nos-neql
    defw L353B         ; $0C no-grtr
    defw L353B         ; $0D no-less
    defw L353B         ; $0E nos-eql
    defw L3014         ; $0F addition
    defw CALC_UNSUPPORTED ; $10 str-&-no
    defw CALC_UNSUPPORTED ; $11 str-l-eql
    defw CALC_UNSUPPORTED ; $12 str-gr-eql
    defw CALC_UNSUPPORTED ; $13 strs-neql
    defw CALC_UNSUPPORTED ; $14 str-grtr
    defw CALC_UNSUPPORTED ; $15 str-less
    defw CALC_UNSUPPORTED ; $16 strs-eql
    defw CALC_UNSUPPORTED ; $17 strs-add
    defw CALC_UNSUPPORTED ; $18 val$
    defw CALC_UNSUPPORTED ; $19 usr-$
    defw CALC_UNSUPPORTED ; $1A read-in
    defw L346E          ; $1B negate
    defw CALC_UNSUPPORTED ; $1C code
    defw CALC_UNSUPPORTED ; $1D val (pendiente: parseo numerico propio)
    defw CALC_UNSUPPORTED ; $1E len
    defw L37B5          ; $1F sin
    defw L37AA          ; $20 cos
    defw L37DA          ; $21 tan
    defw L3833          ; $22 asn
    defw L3843          ; $23 acs
    defw L37E2          ; $24 atn
    defw L3713          ; $25 ln
    defw L36C4          ; $26 exp
    defw L36AF          ; $27 int
    defw L384A          ; $28 sqr
    defw L3492          ; $29 sgn
    defw L346A          ; $2A abs
    defw CALC_UNSUPPORTED ; $2B peek
    defw CALC_UNSUPPORTED ; $2C in
    defw CALC_UNSUPPORTED ; $2D usr-no
    defw CALC_UNSUPPORTED ; $2E str$ (pendiente)
    defw CALC_UNSUPPORTED ; $2F chr$
    defw L3501          ; $30 not
    defw L33C0          ; $31 duplicate
    defw L36A0          ; $32 n-mod-m
    defw L3686          ; $33 jump
    defw L33C6          ; $34 stk-data
    defw L367A          ; $35 dec-jr-nz
    defw L3506          ; $36 less-0
    defw L34F9          ; $37 greater-0
    defw L369B          ; $38 end-calc
    defw L3783          ; $39 get-argt
    defw L3214          ; $3A truncate
    defw L33A2          ; $3B fp-calc-2
    defw CALC_UNSUPPORTED ; $3C e-to-fp
    defw L3297          ; $3D re-stack
    defw L3449          ; series-xx    $80-$9F
    defw L341B          ; stk-const-xx $A0-$BF
    defw L342D          ; st-mem-xx    $C0-$DF
    defw L340F          ; get-mem-xx   $E0-$FF

CALC_UNSUPPORTED:
    ld   a, ERROR_InvalidArg
    jp   __ERROR

; ---------------------------------------------------------------------------
; THE 'CALCULATE' SUBROUTINE ($335B) — motor principal
; ---------------------------------------------------------------------------
L335B:
    call L35BF
L335E:
    ld   a, b
    ld   (FP_BREG), a
L3362:
    exx
    ex   (sp), hl
    exx
L3365:
    ld   (FP_STKEND), de
    exx
    ld   a, (hl)
    inc  hl
L336C:
    push hl
    and  a
    jp   p, L3380
    ld   d, a
    and  $60
    rrca
    rrca
    rrca
    rrca
    add  a, $7C
    ld   l, a
    ld   a, d
    and  $1F
    jr   L338E
L3380:
    cp   $18
    jr   nc, L338C
    exx
    ld   bc, $FFFB
    ld   d, h
    ld   e, l
    add  hl, bc
    exx
L338C:
    rlca
    ld   l, a
L338E:
    ld   de, L32D7
    ld   h, 0
    add  hl, de
    ld   e, (hl)
    inc  hl
    ld   d, (hl)
    ld   hl, L3365
    ex   (sp), hl
    push de
    exx
    ld   bc, (FP_STKEND + 1)    ; C=STKEND_hi, B=FP_BREG (ver nota en sysvars.asm)
    ret

; ---------------------------------------------------------------------------
; delete (literal $02) — un simple RET; tambien destino de salto indirecto
; ---------------------------------------------------------------------------
L33A1:
    ret

; ---------------------------------------------------------------------------
; fp-calc-2 (literal $3B) — reentrada de un solo literal
; ---------------------------------------------------------------------------
L33A2:
    pop  af
    ld   a, (FP_BREG)
    exx
    jr   L336C

; ---------------------------------------------------------------------------
; STK-PNTRS ($35BF)
; ---------------------------------------------------------------------------
L35BF:
    ld   hl, (FP_STKEND)
    ld   de, $FFFB
    push hl
    add  hl, de
    pop  de
    ret

; ---------------------------------------------------------------------------
; jump-true (literal $00) / jump (literal $33) / dec-jr-nz (literal $35)
; ---------------------------------------------------------------------------
L368F:
    inc  de
    inc  de
    ld   a, (de)
    dec  de
    dec  de
    and  a
    jr   nz, L3686
    exx
    inc  hl
    exx
    ret

L367A:
    exx
    push hl
    ld   hl, FP_BREG
    dec  (hl)
    pop  hl
    jr   nz, L3687
    inc  hl
    exx
    ret

L3686:
    exx
L3687:
    ld   e, (hl)
    ld   a, e
    rla
    sbc  a, a
    ld   d, a
    add  hl, de
    exx
    ret

; ---------------------------------------------------------------------------
; end-calc (literal $38)
; ---------------------------------------------------------------------------
L369B:
    pop  af
    exx
    ex   (sp), hl
    exx
    ret

; ---------------------------------------------------------------------------
; n-mod-m (literal $32) — implementado como programa del propio calculador
; ---------------------------------------------------------------------------
L36A0:
    rst  28h
    defb $C0, $02, $31, $E0, $05, $27, $E0, $01, $C0, $04, $03, $E0, $38
    ret

; ---------------------------------------------------------------------------
; int (literal $27) — implementado como programa del propio calculador
; ---------------------------------------------------------------------------
L36AF:
    rst  28h
    defb $31            ;;duplicate
    defb $36            ;;less-0
    defb $00            ;;jump-true
    defb (L36B7 - $) & 0FFh  ;;a X-NEG
    defb $3A            ;;truncate
    defb $38            ;;end-calc
    ret
L36B7:
    defb $31            ;;duplicate
    defb $3A            ;;truncate
    defb $C0            ;;st-mem-0
    defb $03            ;;subtract
    defb $E0            ;;get-mem-0
    defb $01            ;;exchange
    defb $30            ;;not
    defb $00            ;;jump-true
    defb (L36C2 - $) & 0FFh  ;;a EXIT
    defb $A1            ;;stk-one
    defb $03            ;;subtract
L36C2:
    defb $38            ;;end-calc

; ---------------------------------------------------------------------------
; TEST-ZERO ($34E9) / GREATER-0 (literal $37) / NOT (literal $30) /
; less-0 (literal $36) / SIGN-TO-C / FP-0/1
; ---------------------------------------------------------------------------
L34E9:
    push hl
    push bc
    ld   b, a
    ld   a, (hl)
    inc  hl
    or   (hl)
    inc  hl
    or   (hl)
    inc  hl
    or   (hl)
    ld   a, b
    pop  bc
    pop  hl
    ret  nz
    scf
    ret

L34F9:
    call L34E9
    ret  c
    ld   a, $FF
    jr   L3507

L3501:
    call L34E9
    jr   L350B

L3506:
    xor  a
L3507:
    inc  hl
    xor  (hl)
    dec  hl
    rlca
L350B:
    push hl
    ld   a, 0
    ld   (hl), a
    inc  hl
    ld   (hl), a
    inc  hl
    rla
    ld   (hl), a
    rra
    inc  hl
    ld   (hl), a
    inc  hl
    ld   (hl), a
    pop  hl
    ret

; ---------------------------------------------------------------------------
; or (literal $07) / no-&-no (literal $08)
; ---------------------------------------------------------------------------
L351B:
    ex   de, hl
    call L34E9
    ex   de, hl
    ret  c
    scf
    jr   L350B

L3524:
    ex   de, hl
    call L34E9
    ex   de, hl
    ret  nc
    and  a
    jr   L350B

; ---------------------------------------------------------------------------
; comparaciones numericas (literales $09-$0E, $353B) — solo la rama numerica;
; no se soportan comparaciones de cadenas via calculador en este runtime.
; ---------------------------------------------------------------------------
L353B:
    ld   a, b
    sub  8
    bit  2, a
    jr   nz, L3543
    dec  a
L3543:
    rrca
    jr   nc, L354E
    push af
    push hl
    call L343C
    pop  de
    ex   de, hl
    pop  af
L354E:
    rrca
    push af
    call L300F
    jr   L358C

; ---------------------------------------------------------------------------
; END-TESTS ($358C)
; ---------------------------------------------------------------------------
L358C:
    pop  af
    push af
    call c, L3501
    pop  af
    push af
    call nc, L34F9
    pop  af
    rrca
    call nc, L3501
    ret

; ===========================================================================
; FASE 4: SIN/COS/TAN/ASN/ACS/ATN/LN/EXP/SQR
;
; Todas estas funciones son, igual que "int" o "n-mod-m" mas arriba,
; programas del propio calculador (rst 28h + bytes de literal), identicos a
; los de la ROM, apoyados en el "series generator" (L3449/L3453) ya portado.
; Solo se han corregido los offsets de jump-true/jump (recalculados con la
; misma formula ya usada en el resto del fichero: (destino - $) & 0FFh) y se
; ha sustituido "RST 08h ; DEFB <codigo>" (ERROR-1 de la ROM) por el
; mecanismo de error propio (ERROR_xxx + jp __ERROR).
; ===========================================================================

; ---------------------------------------------------------------------------
; STACK-A ($2D28) / STACK-BC ($2D2B) — apila A (o BC) como entero pequeño
; ---------------------------------------------------------------------------
L2D28:
    ld   c, a
    ld   b, 0
L2D2B:
    xor  a
    ld   e, a
    ld   d, c
    ld   c, b
    ld   b, a
    call __FPSTACK_PUSH
    rst  28h
    defb $38            ;;end-calc (recalcula HL/DE tras el push)
    and  a
    ret

; ---------------------------------------------------------------------------
; FP-TO-BC ($2DA2) — recoge el ultimo valor de la pila FP en BC (redondeando)
; ---------------------------------------------------------------------------
L2DA2:
    rst  28h
    defb $38            ;;end-calc -> HL apunta al ultimo valor
    ld   a, (hl)
    and  a
    jr   z, L2DAD
    rst  28h
    defb $A2            ;;stk-half
    defb $0F            ;;addition
    defb $27            ;;int
    defb $38            ;;end-calc
L2DAD:
    rst  28h
    defb $02            ;;delete
    defb $38            ;;end-calc
    push hl
    push de
    ex   de, hl
    ld   b, (hl)
    call L2D7F
    xor  a
    sub  b
    bit  7, c
    ld   b, d
    ld   c, e
    ld   a, e
    pop  de
    pop  hl
    ret

; ---------------------------------------------------------------------------
; FP-TO-A ($2DD5) — como FP-TO-BC pero devuelve A, con overflow en carry
; ---------------------------------------------------------------------------
L2DD5:
    call L2DA2
    ret  c
    push af
    dec  b
    inc  b
    jr   z, L2DE1
    pop  af
    scf
    ret
L2DE1:
    pop  af
    ret

; ---------------------------------------------------------------------------
; get-argt (literal $39, $3783) — reduce el argumento de sin/cos a -1..+1
; ---------------------------------------------------------------------------
L3783:
    rst  28h
    defb $3D            ;;re-stack
    defb $34            ;;stk-data
    defb $EE            ;;Exponent: $7E, Bytes: 4
    defb $22, $F9, $83, $6E
    defb $04            ;;multiply
    defb $31            ;;duplicate
    defb $A2            ;;stk-half
    defb $0F            ;;addition
    defb $27            ;;int
    defb $03            ;;subtract
    defb $31            ;;duplicate
    defb $0F            ;;addition
    defb $31            ;;duplicate
    defb $0F            ;;addition
    defb $31            ;;duplicate
    defb $2A            ;;abs
    defb $A1            ;;stk-one
    defb $03            ;;subtract
    defb $31            ;;duplicate
    defb $37            ;;greater-0
    defb $C0            ;;st-mem-0
    defb $00            ;;jump-true
    defb (L37A1 - $) & 0FFh    ;;a ZPLUS
    defb $02            ;;delete
    defb $38            ;;end-calc
    ret
L37A1:
    defb $A1            ;;stk-one
    defb $03            ;;subtract
    defb $01            ;;exchange
    defb $36            ;;less-0
    defb $00            ;;jump-true
    defb (L37A8 - $) & 0FFh    ;;a YNEG
    defb $1B            ;;negate
L37A8:
    defb $38            ;;end-calc
    ret

; ---------------------------------------------------------------------------
; cos (literal $20, $37AA) — cae en sin/C-ENT (codigo compartido)
; ---------------------------------------------------------------------------
L37AA:
    rst  28h
    defb $39            ;;get-argt
    defb $2A            ;;abs
    defb $A1            ;;stk-one
    defb $03            ;;subtract
    defb $E0            ;;get-mem-0
    defb $00            ;;jump-true
    defb (L37B7 - $) & 0FFh    ;;a C-ENT
    defb $1B            ;;negate
    defb $33            ;;jump
    defb (L37B7 - $) & 0FFh    ;;a C-ENT

; ---------------------------------------------------------------------------
; sin (literal $1F, $37B5) / C-ENT ($37B7, compartido con cos)
; ---------------------------------------------------------------------------
L37B5:
    rst  28h
    defb $39            ;;get-argt
L37B7:
    defb $31            ;;duplicate
    defb $31            ;;duplicate
    defb $04            ;;multiply
    defb $31            ;;duplicate
    defb $0F            ;;addition
    defb $A1            ;;stk-one
    defb $03            ;;subtract
    defb $86            ;;series-06
    defb $14, $E6
    defb $5C, $1F, $0B
    defb $A3, $8F, $38, $EE
    defb $E9, $15, $63, $BB, $23
    defb $EE, $92, $0D, $CD, $ED
    defb $F1, $23, $5D, $1B, $EA
    defb $04            ;;multiply
    defb $38            ;;end-calc
    ret

; ---------------------------------------------------------------------------
; tan (literal $21, $37DA) — sin(x) / cos(x)
; ---------------------------------------------------------------------------
L37DA:
    rst  28h
    defb $31            ;;duplicate
    defb $1F            ;;sin
    defb $01            ;;exchange
    defb $20            ;;cos
    defb $05            ;;division
    defb $38            ;;end-calc
    ret

; ---------------------------------------------------------------------------
; atn (literal $24, $37E2)
; ---------------------------------------------------------------------------
L37E2:
    call L3297          ; re-stack
    ld   a, (hl)
    cp   $81
    jr   c, L37F8       ; SMALL
    rst  28h
    defb $A1            ;;stk-one
    defb $1B            ;;negate
    defb $01            ;;exchange
    defb $05            ;;division
    defb $31            ;;duplicate
    defb $36            ;;less-0
    defb $A3            ;;stk-pi/2
    defb $01            ;;exchange
    defb $00            ;;jump-true
    defb (L37FA - $) & 0FFh    ;;a CASES
    defb $1B            ;;negate
    defb $33            ;;jump
    defb (L37FA - $) & 0FFh    ;;a CASES
L37F8:
    rst  28h
    defb $A0            ;;stk-zero
L37FA:
    defb $01            ;;exchange
    defb $31            ;;duplicate
    defb $31            ;;duplicate
    defb $04            ;;multiply
    defb $31            ;;duplicate
    defb $0F            ;;addition
    defb $A1            ;;stk-one
    defb $03            ;;subtract
    defb $8C            ;;series-0C
    defb $10, $B2
    defb $13, $0E
    defb $55, $E4, $8D
    defb $58, $39, $BC
    defb $5B, $98, $FD
    defb $9E, $00, $36, $75
    defb $A0, $DB, $E8, $B4
    defb $63, $42, $C4
    defb $E6, $B5, $09, $36, $BE
    defb $E9, $36, $73, $1B, $5D
    defb $EC, $D8, $DE, $63, $BE
    defb $F0, $61, $A1, $B3, $0C
    defb $04            ;;multiply
    defb $0F            ;;addition
    defb $38            ;;end-calc
    ret

; ---------------------------------------------------------------------------
; asn (literal $22, $3833)
; ---------------------------------------------------------------------------
L3833:
    rst  28h
    defb $31            ;;duplicate
    defb $31            ;;duplicate
    defb $04            ;;multiply
    defb $A1            ;;stk-one
    defb $03            ;;subtract
    defb $1B            ;;negate
    defb $28            ;;sqr
    defb $A1            ;;stk-one
    defb $0F            ;;addition
    defb $05            ;;division
    defb $24            ;;atn
    defb $31            ;;duplicate
    defb $0F            ;;addition
    defb $38            ;;end-calc
    ret

; ---------------------------------------------------------------------------
; acs (literal $23, $3843)
; ---------------------------------------------------------------------------
L3843:
    rst  28h
    defb $22            ;;asn
    defb $A3            ;;stk-pi/2
    defb $03            ;;subtract
    defb $1B            ;;negate
    defb $38            ;;end-calc
    ret

; ---------------------------------------------------------------------------
; ln (literal $25, $3713)
; ---------------------------------------------------------------------------
L3713:
    rst  28h
    defb $3D            ;;re-stack
    defb $31            ;;duplicate
    defb $37            ;;greater-0
    defb $00            ;;jump-true
    defb (L371C - $) & 0FFh    ;;a VALID
    defb $38            ;;end-calc
    ld   a, ERROR_InvalidArg
    jp   __ERROR
L371C:
    defb $A0            ;;stk-zero
    defb $02            ;;delete
    defb $38            ;;end-calc
    ld   a, (hl)
    ld   (hl), $80
    call L2D28
    rst  28h
    defb $34            ;;stk-data
    defb $38            ;;Exponent: $88, Bytes: 1
    defb $00
    defb $03            ;;subtract
    defb $01            ;;exchange
    defb $31            ;;duplicate
    defb $34            ;;stk-data
    defb $F0            ;;Exponent: $80, Bytes: 4
    defb $4C, $CC, $CC, $CD
    defb $03            ;;subtract
    defb $37            ;;greater-0
    defb $00            ;;jump-true
    defb (L373D - $) & 0FFh    ;;a GRE.8
    defb $01            ;;exchange
    defb $A1            ;;stk-one
    defb $03            ;;subtract
    defb $01            ;;exchange
    defb $38            ;;end-calc
    inc  (hl)
    rst  28h
L373D:
    defb $01            ;;exchange
    defb $34            ;;stk-data
    defb $F0            ;;Exponent: $80, Bytes: 4
    defb $31, $72, $17, $F8
    defb $04            ;;multiply
    defb $01            ;;exchange
    defb $A2            ;;stk-half
    defb $03            ;;subtract
    defb $A2            ;;stk-half
    defb $03            ;;subtract
    defb $31            ;;duplicate
    defb $34            ;;stk-data
    defb $32            ;;Exponent: $82, Bytes: 1
    defb $20
    defb $04            ;;multiply
    defb $A2            ;;stk-half
    defb $03            ;;subtract
    defb $8C            ;;series-0C
    defb $11, $AC
    defb $14, $09
    defb $56, $DA, $A5
    defb $59, $30, $C5
    defb $5C, $90, $AA
    defb $9E, $70, $6F, $61
    defb $A1, $CB, $DA, $96
    defb $A4, $31, $9F, $B4
    defb $E7, $A0, $FE, $5C, $FC
    defb $EA, $1B, $43, $CA, $36
    defb $ED, $A7, $9C, $7E, $5E
    defb $F0, $6E, $23, $80, $93
    defb $04            ;;multiply
    defb $0F            ;;addition
    defb $38            ;;end-calc
    ret

; ---------------------------------------------------------------------------
; exp (literal $26, $36C4)
; ---------------------------------------------------------------------------
L36C4:
    rst  28h
    defb $3D            ;;re-stack
    defb $34            ;;stk-data
    defb $F1            ;;Exponent: $81, Bytes: 4
    defb $38, $AA, $3B, $29
    defb $04            ;;multiply
    defb $31            ;;duplicate
    defb $27            ;;int
    defb $C3            ;;st-mem-3
    defb $03            ;;subtract
    defb $31            ;;duplicate
    defb $0F            ;;addition
    defb $A1            ;;stk-one
    defb $03            ;;subtract
    defb $88            ;;series-08
    defb $13, $36
    defb $58, $65, $66
    defb $9D, $78, $65, $40
    defb $A2, $60, $32, $C9
    defb $E7, $21, $F7, $AF, $24
    defb $EB, $2F, $B0, $B0, $14
    defb $EE, $7E, $BB, $94, $58
    defb $F1, $3A, $7E, $F8, $CF
    defb $E3            ;;get-mem-3
    defb $38            ;;end-calc
    call L2DD5
    jr   nz, L3705      ; N-NEGTV
    jr   c, L3703       ; REPORT-6b
    add  a, (hl)
    jr   nc, L370C      ; RESULT-OK
L3703:
    ld   a, ERROR_NumberTooBig
    jp   __ERROR
L3705:
    jr   c, L370E       ; RSLT-ZERO
    sub  (hl)
    jr   nc, L370E      ; RSLT-ZERO
    neg
L370C:
    ld   (hl), a
    ret
L370E:
    rst  28h
    defb $02            ;;delete
    defb $A0            ;;stk-zero
    defb $38            ;;end-calc
    ret

; ---------------------------------------------------------------------------
; sqr (literal $28, $384A) — cae en to-power (codigo compartido)
; ---------------------------------------------------------------------------
L384A:
    rst  28h
    defb $31            ;;duplicate
    defb $30            ;;not
    defb $00            ;;jump-true
    defb (L386C - $) & 0FFh    ;;a LAST
    defb $A2            ;;stk-half
    defb $38            ;;end-calc

; ---------------------------------------------------------------------------
; to-power (literal $06, $3851)
; ---------------------------------------------------------------------------
L3851:
    rst  28h
    defb $01            ;;exchange
    defb $31            ;;duplicate
    defb $30            ;;not
    defb $00            ;;jump-true
    defb (L385D - $) & 0FFh    ;;a XIS0
    defb $25            ;;ln
    defb $04            ;;multiply
    defb $38            ;;end-calc
    jp   L36C4
L385D:
    defb $02            ;;delete
    defb $31            ;;duplicate
    defb $30            ;;not
    defb $00            ;;jump-true
    defb (L386A - $) & 0FFh    ;;a ONE
    defb $A0            ;;stk-zero
    defb $01            ;;exchange
    defb $37            ;;greater-0
    defb $00            ;;jump-true
    defb (L386C - $) & 0FFh    ;;a LAST
    defb $A1            ;;stk-one
    defb $01            ;;exchange
    defb $05            ;;division
L386A:
    defb $02            ;;delete
    defb $A1            ;;stk-one
L386C:
    defb $38            ;;end-calc
    ret

; ===========================================================================
; FASE 5: STK-TO-A / STK-TO-BC / CD-PRMS1
;
; Rutinas auxiliares de la ROM usadas por DRAW3 (modo arco) y CIRCLE-DRAW.
; No son literales del calculador (no se invocan via rst 28h + defb), sino
; rutinas normales que a su vez usan el calculador ya portado (FP-TO-A,
; STACK-A, y los literales sqr/sin/stk-data/etc de fp_calc.asm).
; ===========================================================================

; ---------------------------------------------------------------------------
; STK-TO-A ($2314) — comprime el ultimo valor de la pila FP en A.
; C = $01 si es positivo o cero, $FF si es negativo.
; Error IntOutOfRange (sustituye a REPORT-Bc / RST 08h) si >= 256.
; ---------------------------------------------------------------------------
L2314:
    call L2DD5          ; FP-TO-A: A = valor comprimido, Z si signo positivo
    jr   c, L24F9
    ld   c, $01
    ret  z
    ld   c, $FF
    ret

L24F9:
    ld   a, ERROR_IntOutOfRange
    jp   __ERROR

; ---------------------------------------------------------------------------
; STK-TO-BC ($2307) — recoge dos valores de la pila FP: el primero (mas
; antiguo) en BC, el segundo (mas reciente) en DE (bajo, con signo en E/D).
; ---------------------------------------------------------------------------
L2307:
    call L2314
    ld   b, a
    push bc
    call L2314
    ld   e, c
    pop  bc
    ld   d, c
    ld   c, a
    ret

; ---------------------------------------------------------------------------
; CD-PRMS1 ($247D) — CIRCLE/DRAW PARAMETERS: a partir del "diametro" z (tope
; de pila) y el angulo total en mem-5, calcula el numero de lineas rectas
; (B, multiplo de 4, max 252) y deja en mem-1/mem-3/mem-4 sin(a/2), cos(a) y
; sin(a) del angulo de paso "a" = ANGULO/lineas.
; ---------------------------------------------------------------------------
L247D:
    rst  28h
    defb $31            ;;duplicate     z, z.
    defb $28            ;;sqr           z, sqr(z).
    defb $34            ;;stk-data      z, sqr(z), 2.
    defb $32            ;;Exponent: $82, Bytes: 1
    defb $00            ;;(+00,+00,+00)
    defb $01            ;;exchange      z, 2, sqr(z).
    defb $05            ;;division      z, 2/sqr(z).
    defb $E5            ;;get-mem-5     z, 2/sqr(z), ANGLE.
    defb $01            ;;exchange      z, ANGLE, 2/sqr(z)
    defb $05            ;;division      z, ANGLE*sqr(z)/2 (=num. lineas)
    defb $2A            ;;abs           (solo para arco)
    defb $38            ;;end-calc      z, numero de lineas.

    call L2DD5          ; FP-TO-A
    jr   c, L247D_USE252

    and  $FC            ; multiplo de 4 (p.ej. 29 -> 28)
    add  a, $04          ; podria dar overflow -> 256
    jr   nc, L247D_SAVE

L247D_USE252:
    ld   a, $FC          ; limite de 252 (para arco)

L247D_SAVE:
    push af              ; conserva el contador de lineas
    call L2D28           ; apila el contador modificado

    rst  28h
    defb $E5            ;;get-mem-5     z, A, ANGLE.
    defb $01            ;;exchange      z, ANGLE, A.
    defb $05            ;;division      z, ANGLE/A. (angulo de paso = a)
    defb $31            ;;duplicate     z, a, a.
    defb $1F            ;;sin           z, a, sin(a)
    defb $C4            ;;st-mem-4      z, a, sin(a)
    defb $02            ;;delete        z, a.
    defb $31            ;;duplicate     z, a, a.
    defb $A2            ;;stk-half      z, a, a, 1/2.
    defb $04            ;;multiply      z, a, a/2.
    defb $1F            ;;sin           z, a, sin(a/2).
    defb $C1            ;;st-mem-1      z, a, sin(a/2).
    defb $01            ;;exchange      z, sin(a/2), a.
    defb $C0            ;;st-mem-0      z, sin(a/2), a.  (solo para arco)
    defb $02            ;;delete        z, sin(a/2).
    defb $31            ;;duplicate     z, sin(a/2), sin(a/2).
    defb $04            ;;multiply      z, sin(a/2)^2.
    defb $31            ;;duplicate     z, sin(a/2)^2, sin(a/2)^2.
    defb $0F            ;;addition      z, 2*sin(a/2)^2.
    defb $A1            ;;stk-one       z, 2*sin(a/2)^2, 1.
    defb $03            ;;subtract      z, 2*sin(a/2)^2-1.
    defb $1B            ;;negate        z, 1-2*sin(a/2)^2 = cos(a).
    defb $C3            ;;st-mem-3      z, cos(a).
    defb $02            ;;delete        z.
    defb $38            ;;end-calc      z.

    pop  bc              ; restaura el contador de lineas
    ret

    pop namespace
