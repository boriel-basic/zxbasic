; beep.asm (zx81sd) — Comando BEEP duracion, tono (version con expresiones)
;
; Sustituye a zx48k/runtime/io/sound/beep.asm, que llama a BEEP ($03F8) de
; la ROM Spectrum. Aqui se porta la rutina original usando el calculador FP
; propio (fp_calc.asm) y el bucle de beeper propio (io/sound/beeper.asm).
;
;   BEEP dur, pitch
;     dur   = duracion en segundos (0 a 10)
;     pitch = semitonos sobre/bajo el DO central (-60 a 127)
;
; Diferencias con la ROM:
;   - MEM-0 esta en FP_MEM_AREA (sysvars propias), no en $5C92.
;   - FIND-INT1/FIND-INT2 se sustituyen por __FPSTACK_POP + __FTOU32REG
;     (ya portados y verificados en zx81sd).
;   - La constante 437500 (= 3.5MHz/8 del Spectrum) se sustituye por
;     406250 (= 3.25MHz/8 del ZX81). El resto del bytecode es identico.
;
; Entrada (convencion del compilador, igual que en zx48k):
;   Duracion en A,E,D,C,B (float); tono en la pila de maquina (float).

#include once <error.asm>
#include once <stackf.asm>
#include once <fp_calc.asm>
#include once <ftou32reg.asm>
#include once <io/sound/beeper.asm>

    push namespace core

BEEP:
    PROC
    LOCAL BEEP_I_OK, BEEP_OCTAVE, BEEP_ERROR, BEEP_SEMITONES

    call __FPSTACK_PUSH     ; duracion -> pila FP

    pop  hl                 ; direccion de retorno
    pop  af
    pop  de
    pop  bc                 ; tono (float) desde la pila de maquina
    push hl                 ; CALLEE

    call __FPSTACK_PUSH     ; tono -> pila FP

;   Igual que la ROM ($03F8): separa el tono en parte entera (mem-0) y
;   fraccionaria, y deja en la pila 1 + 0.05776226 * frac(tono).

    rst  28h                ;; FP-CALC      dur, tono.
    defb $31                ;;duplicate     dur, tono, tono.
    defb $27                ;;int           dur, tono, int(tono).
    defb $C0                ;;st-mem-0      (tono entero a mem-0)
    defb $03                ;;subtract      dur, frac(tono).
    defb $34                ;;stk-data      constante 0.05776226
    defb $EC                ;;Exponent: $7C, Bytes: 4
    defb $6C, $98, $1F, $F5
    defb $04                ;;multiply
    defb $A1                ;;stk-one
    defb $0F                ;;addition      dur, 1 + 0.0577*frac.
    defb $38                ;;end-calc

;   mem-0 contiene el tono entero en formato entero-pequeno:
;   0, signo (0/FF), LSB, MSB, 0. Comprueba -128 <= tono <= 127.

    ld   hl, FP_MEM_AREA
    ld   a, (hl)            ; el primer byte debe ser 0 (forma entera)
    and  a
    jp   nz, BEEP_ERROR

    inc  hl
    ld   c, (hl)            ; C = byte de signo (0/FF)
    inc  hl
    ld   b, (hl)            ; B = LSB (complemento a dos)
    ld   a, b
    rla
    sbc  a, a               ; A = 0/FF segun el bit 7 de B
    cp   c                  ; debe coincidir con el signo
    jp   nz, BEEP_ERROR

    inc  hl
    cp   (hl)               ; y el MSB debe ser 0/FF igualmente
    jp   nz, BEEP_ERROR

    ld   a, b               ; A = tono + 60
    add  a, $3C
    jp   p, BEEP_I_OK       ; si -60 <= tono, sigue

    jp   po, BEEP_ERROR     ; fuera de rango por abajo

BEEP_I_OK:                  ; aqui -60 <= tono <= 127, A = tono+60 (0-187)
    ld   b, $FA             ; B = -6 octavas bajo el DO central

BEEP_OCTAVE:
    inc  b                  ; octava siguiente
    sub  $0C                ; 12 semitonos = 1 octava
    jr   nc, BEEP_OCTAVE

    add  a, $0C             ; A = semitonos sobre DO (0-11)
    push bc                 ; B = desplazamiento de octava (-5..10)

    ; HL = BEEP_SEMITONES + A*5  (LOC-MEM de la ROM)
    ld   c, a
    add  a, a
    add  a, a
    add  a, c               ; A = A*5 (max 55, sin acarreo)
    ld   c, a
    ld   b, 0
    ld   hl, BEEP_SEMITONES
    add  hl, bc

    ; STACK-NUM: apila el float de la tabla (frecuencia del semitono)
    ld   a, (hl)
    inc  hl
    ld   e, (hl)
    inc  hl
    ld   d, (hl)
    inc  hl
    ld   c, (hl)
    inc  hl
    ld   b, (hl)
    call __FPSTACK_PUSH

    rst  28h                ;; FP-CALC      dur, factor, freq.
    defb $04                ;;multiply      dur, freq ajustada a frac(tono).
    defb $38                ;;end-calc      (HL -> exponente del resultado)

    pop  af                 ; A = desplazamiento de octava
    add  a, (hl)            ; freq *= 2^octava (suma al exponente)
    ld   (hl), a

    rst  28h                ;; FP-CALC      dur, freq.
    defb $C0                ;;st-mem-0      (frecuencia a mem-0)
    defb $02                ;;delete        dur.
    defb $31                ;;duplicate     dur, dur.
    defb $38                ;;end-calc

    ; comprueba 0 <= duracion <= 10 (como FIND-INT1 + CP 11 de la ROM)
    call __FPSTACK_POP
    bit  7, e               ; negativa -> error
    jp   nz, BEEP_ERROR
    call __FTOU32REG        ; DEHL = int(duracion)
    ld   a, d
    or   e
    or   h
    jp   nz, BEEP_ERROR
    ld   a, l
    cp   $0B
    jp   nc, BEEP_ERROR

;   Calcula los parametros del bucle del beeper:
;     ciclos  = duracion * frecuencia
;     periodo = 406250 / frecuencia - 30.125   (406250 = 3.25MHz / 8)

    rst  28h                ;; FP-CALC      dur.
    defb $E0                ;;get-mem-0     dur, freq.
    defb $04                ;;multiply      ciclos.
    defb $E0                ;;get-mem-0     ciclos, freq.
    defb $34                ;;stk-data      constante 406250
    defb $80                ;;Exponent: $93, Bytes: 3
    defb $43
    defb $46, $5D, $40
    defb $01                ;;exchange      ciclos, 406250, freq.
    defb $05                ;;division      ciclos, 406250/freq.
    defb $34                ;;stk-data      constante 30.125
    defb $35                ;;Exponent: $85, Bytes: 1
    defb $71
    defb $03                ;;subtract      ciclos, periodo.
    defb $38                ;;end-calc

    call __FPSTACK_POP
    call __FTOU32REG        ; HL = periodo
    push hl
    call __FPSTACK_POP
    call __FTOU32REG        ; HL = ciclos
    ex   de, hl             ; DE = ciclos
    pop  hl                 ; HL = periodo

    ld   a, d
    or   e
    ret  z                  ; duracion 0: nada que hacer (evita 65536 ciclos)
    dec  de                 ; DE = ciclos - 1

    push ix                 ; el beeper usa IX (frame pointer del compilador)
    call __ZX81SD_BEEPER
    pop  ix
    ret

BEEP_ERROR:
    ld   a, ERROR_IntOutOfRange
    jp   __ERROR

; Tabla de semitonos de la ROM ($046E): frecuencias de la octava central.
; Octavas arriba/abajo = multiplicar por 2^n (se suma n al exponente).

BEEP_SEMITONES:
    defb $89, $02, $D0, $12, $86    ; 261.625565290  DO
    defb $89, $0A, $97, $60, $75    ; 277.182631135  DO#
    defb $89, $12, $D5, $17, $1F    ; 293.664768100  RE
    defb $89, $1B, $90, $41, $02    ; 311.126983881  RE#
    defb $89, $24, $D0, $53, $CA    ; 329.627557039  MI
    defb $89, $2E, $9D, $36, $B1    ; 349.228231549  FA
    defb $89, $38, $FF, $49, $3E    ; 369.994422674  FA#
    defb $89, $43, $FF, $6A, $73    ; 391.995436072  SOL
    defb $89, $4F, $A7, $00, $54    ; 415.304697513  SOL#
    defb $89, $5C, $00, $00, $00    ; 440.000000000  LA
    defb $89, $69, $14, $F6, $24    ; 466.163761616  LA#
    defb $89, $76, $F1, $10, $05    ; 493.883301378  SI

    ENDP

    pop namespace
