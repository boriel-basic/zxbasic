; PIXEL_ADDR — Calcula la dirección del byte de pantalla para coordenadas (Y, X)
; Sustituye a PIXEL_ADDR EQU $22ACh (ROM Spectrum)
;
; Convención (igual que la ROM Spectrum, para no modificar plot.asm):
;   Entrada: A = 191 - Y_real,  C = X  (0-255)
;   Salida:  HL = offset dentro del bitmap (sin la base de pantalla)
;            A  = máscara de bit ($80 >> (X AND 7))
;   Destruye: B, D
;
; Organización bitmap Spectrum:
;   bits [12:11] = tercio vertical  (V AND $C0) >> 6
;   bits [10: 8] = línea en tercio  (V AND $07)
;   bits [ 7: 5] = fila de carácter (V AND $38) >> 3
;   bits [ 4: 0] = columna de byte  X >> 3

    push namespace core

PIXEL_ADDR:
    PROC
    LOCAL BIT_LOOP, DONE_BITS

    ld   d, a               ; D = V = 191-Y

    ; -- Byte alto del offset: tercio (bits 12-11) + línea en tercio (bits 10-8) --
    ld   a, d
    and  $C0                ; A = tercio * 64
    srl  a
    srl  a
    srl  a                  ; A = tercio * 8  → bits [5:3] de H
    ld   h, a
    ld   a, d
    and  $07                ; A = línea en tercio (0-7) → bits [2:0] de H
    or   h
    ld   h, a               ; H = (tercio<<3) | línea_en_tercio

    ; -- Byte bajo del offset: fila de carácter (bits 7-5) + columna de byte (bits 4-0) --
    ld   a, d
    and  $38                ; A = fila_de_char * 8
    rrca
    rrca
    rrca                    ; A = fila_de_char (0-7)
    add  a, a
    add  a, a
    add  a, a
    add  a, a
    add  a, a               ; A = fila_de_char * 32
    ld   b, a
    ld   a, c
    rrca
    rrca
    rrca
    and  $1F                ; A = X / 8  (columna de byte, 0-31)
    add  a, b
    ld   l, a               ; L = fila_de_char*32 + col_byte

    ; -- Máscara de bit: $80 >> (X AND 7) --
    ld   a, c
    and  $07                ; A = X AND 7
    ld   b, a
    ld   a, $80
    or   a
    jr   z, DONE_BITS       ; si X AND 7 = 0, no rotar
BIT_LOOP:
    rrca
    djnz BIT_LOOP
DONE_BITS:
    ret                     ; HL = offset en bitmap, A = máscara bit

    ENDP

    pop namespace
