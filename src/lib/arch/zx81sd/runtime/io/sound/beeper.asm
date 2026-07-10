; beeper.asm (zx81sd) — Generador de onda cuadrada por el beeper del SD81
;
; Sustituye a zx48k/runtime/io/sound/beeper.asm, que llama a BEEPER ($03B5)
; de la ROM Spectrum. Aqui se porta el bucle original de la ROM adaptando:
;
;   - Puerto: $FB (ULA emulada del SD81 en modo HiRes Spectrum) en vez de
;     $FE. Mismo formato: bits 2-0 = borde, bit 3 = MIC, bit 4 = altavoz.
;     El borde se toma de la copia sombra __ZX81SD_ULA_SHADOW (beep.asm)
;     en vez de BORDCR ($5C48), y se restaura al terminar.
;   - Reloj: el bucle es identico en T-states (no depende del reloj), pero
;     el periodo HL que llega del COMPILADOR (BEEP const,const se precalcula
;     en el frontend con la formula del Spectrum: HL = 437500/f - 30.125,
;     437500 = 3.5MHz/8) hay que corregirlo para los 3.25 MHz del ZX81:
;         HL' = 406250/f - 30.125 = HL*13/14 - 2.15   (406250/437500 = 13/14)
;     La entrada __BEEPER (la que usa el compilador) aplica esa correccion.
;     La entrada __ZX81SD_BEEPER (interna) recibe el periodo ya en unidades
;     de 3.25 MHz y no corrige nada (la usa nuestro BEEP de beep.asm, que
;     calcula directamente con 406250).
;   - Interrupciones: la ROM hace DI...EI. El runtime zx81sd se ejecuta con
;     las interrupciones deshabilitadas (la FPGA genera el video), asi que
;     se mantiene el DI (inocuo) y NO se hace EI al final.
;
; __ZX81SD_BEEPER — entrada directa (formato ROM $03B5):
;   DE = numero de ciclos - 1
;   HL = periodo del tono: T-states = 236 + 8*HL  (a 3.25 MHz)
;   Modifica: AF, BC, DE, HL, IX (el llamador debe preservar IX si lo usa)

#include once <beep.asm>            ; __ZX81SD_ULA_SHADOW (sombra borde/beeper)

    push namespace core

__ZX81SD_BEEPER:
    PROC
    LOCAL BE_IX3, BE_IX2, BE_IX1, BE_IX0
    LOCAL BE_HL_LP, BE_AGAIN, BE_END

    di                      ; timing exacto (ya suelen estar deshabilitadas)
    ld   a, l
    srl  l
    srl  l                  ; L = parte media del periodo
    cpl
    and  $03                ; A = 3 - parte fina del periodo
    ld   c, a
    ld   b, $00
    ld   ix, BE_IX3
    add  ix, bc             ; IX = entrada al bucle con 0-3 NOPs (parte fina)

    ld   a, (__ZX81SD_ULA_SHADOW)
    and  $07                ; bits 2-0 = borde actual
    or   $08                ; bit 3 (MIC) a 1, como la ROM

BE_IX3:
    nop                     ;(4)  NOPs opcionales: ajuste fino del periodo
BE_IX2:
    nop                     ;(4)
BE_IX1:
    nop                     ;(4)
BE_IX0:
    inc  b                  ;(4)
    inc  c                  ;(4)

BE_HL_LP:
    dec  c                  ;(4)  bucle de duracion del semiciclo
    jr   nz, BE_HL_LP       ;(12/7)

    ld   c, $3F             ;(7)
    dec  b                  ;(4)
    jp   nz, BE_HL_LP       ;(10)

    xor  $10                ;(7)  conmuta el bit del altavoz
    out  (SD81_ULA_PORT), a ;(11)
    ld   b, h               ;(4)  B = parte gruesa del periodo
    ld   c, a               ;(4)  salva el byte del puerto
    bit  4, a               ;(8)  si la salida quedo alta,
    jr   nz, BE_AGAIN       ;(12/7)  hace el semiciclo alto

    ld   a, d               ;(4)  ciclo completo (bajo->bajo):
    or   e                  ;(4)  ¿quedan ciclos?
    jr   z, BE_END          ;(12/7)

    ld   a, c               ;(4)  restaura el byte del puerto
    ld   c, l               ;(4)  C = parte media del periodo
    dec  de                 ;(6)
    jp   (ix)               ;(8)  siguiente ciclo

BE_AGAIN:                   ; a mitad de ciclo
    ld   c, l               ;(4)
    inc  c                  ;(4)  +16 T para igualar semiciclo alto y bajo
    jp   (ix)               ;(8)

BE_END:
    ld   a, (__ZX81SD_ULA_SHADOW)
    out  (SD81_ULA_PORT), a ; deja borde/beeper como estaban (sin EI: ver cabecera)
    ret

    ENDP

; ---------------------------------------------------------------------------
; __BEEPER — Entrada del compilador para BEEP <const>,<const>
;   HL (fastcall)      = numero de ciclos - 1
;   (SP+2) en la pila  = periodo calculado por el frontend PARA 3.5 MHz
; Corrige el periodo a 3.25 MHz (HL' = HL - HL/14 - 2) y llama al bucle.
; ---------------------------------------------------------------------------
__BEEPER:
    PROC
    LOCAL DIV14, DIV14_SKIP

    ex   de, hl             ; DE = ciclos - 1
    pop  hl                 ; direccion de retorno
    ex   (sp), hl           ; HL = periodo (unidades Spectrum) — CALLEE

    push de                 ; salva ciclos
    push hl                 ; salva periodo original
    ex   de, hl             ; DE = dividendo (periodo)
    xor  a                  ; A = resto
    ld   c, 14
    ld   b, 16
DIV14:
    sla  e                  ; desplaza el dividendo (bit 0 entra a 0;
    rl   d                  ; NO usar rl e: arrastraria el acarreo residual
    rla                     ; del cp/sub de la vuelta anterior)
    cp   c
    jr   c, DIV14_SKIP
    sub  c
    inc  e
DIV14_SKIP:
    djnz DIV14              ; DE = periodo / 14
    pop  hl                 ; periodo original
    or   a
    sbc  hl, de             ; HL = periodo - periodo/14  (= periodo*13/14)
    dec  hl
    dec  hl                 ; -2 (~ -30.125*(1-13/14), redondeado)
    pop  de                 ; ciclos - 1

    push ix                 ; el bucle usa IX; el compilador usa IX como frame
    call __ZX81SD_BEEPER
    pop  ix
    ret

    ENDP

    pop namespace
