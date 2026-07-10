; PIXEL_ADDR — Calcula la dirección (offset) del byte de pantalla para (B=Y, C=X)
; Sustituye a PIXEL_ADDR EQU $22ACh (ROM Spectrum)
;
; Interfaz idéntica a la ROM Spectrum para compatibilidad con plot.asm / draw.asm:
;   Entrada: A = 191 (límite superior Y), B = Y (0=abajo, 191=arriba), C = X (0-255)
;   Salida:  HL = offset dentro del bitmap desde $0000 (sin base de pantalla)
;            A  = X AND 7  (posición del bit, 0=izquierda/bit7, 7=derecha/bit0)
;   Destruye: B (como la ROM). DEBE preservar D y E: draw.asm salva B' en D'
;   alrededor de esta llamada (ld d,b / call PIXEL_ADDR / ld b,d), igual que
;   hacía con PIXEL-ADD ($22AC) de la ROM Spectrum, que tampoco tocaba DE.
;
; El llamador (plot.asm, draw.asm) añade la base de pantalla:
;   res 6, h        ; no-op en nuestro caso (H siempre en $00-$17)
;   add hl, (SCREEN_ADDR)
;
; Organización bitmap Spectrum interleaved:
;   V = 191 - Y  (Y desde abajo → V desde arriba)
;   H = (V AND $C0)>>3 | (V AND $07)     → tercio + línea en tercio
;   L = (V AND $38)<<2 | (C>>3)          → fila de char*32 + columna byte

    push namespace core

PIXEL_ADDR:
    PROC

    sub  b               ; A = 191 - Y  (convierte coord Spectrum a offset desde arriba)
    ld   b, a            ; B = V = 191-Y  (B ya no se necesita: era la Y de entrada)

    ; -- H: tercio (bits 12-11) + línea en tercio (bits 10-8) --
    and  $C0             ; A = (V AND $C0) = tercio * 64
    rrca
    rrca
    rrca                 ; A = tercio * 8
    ld   h, a
    ld   a, b
    and  $07             ; A = línea en tercio (0-7)
    or   h
    ld   h, a            ; H = (tercio<<3) | línea_en_tercio

    ; -- L: fila de carácter (bits 7-5) + columna de byte (bits 4-0) --
    ld   a, b
    and  $38             ; A = fila_de_char * 8
    rlca
    rlca                 ; A = fila_de_char * 32 (tras AND $38 no hay acarreo al rotar)
    ld   b, a
    ld   a, c
    rrca
    rrca
    rrca
    and  $1F             ; A = X / 8  (columna de byte, 0-31)
    add  a, b
    ld   l, a            ; L = fila_de_char*32 + col_byte

    ; -- Retornar A = X AND 7 (posición del bit dentro del byte) --
    ld   a, c
    and  $07             ; A = X AND 7

    ret

    ENDP

    pop namespace
