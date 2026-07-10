; str.asm (zx81sd) — La funcion STR$( )
;
; Sustituye a zx48k/runtime/str.asm, que usa el literal 'str$' ($2Eh) del
; calculador de la ROM junto con STK-STO-$ y RECLAIM2 (ROM $19E8h) para
; construir la cadena en el area de trabajo de la ROM. Aqui se usa
; directamente fp_tostr.asm (conversion simplificada ya portada) y se copia
; el resultado a un bloque nuevo del heap propio (mem/alloc.asm).

#include once <fp_tostr.asm>
#include once <mem/alloc.asm>

    push namespace core

__STR:
__STR_FAST:
    ; Entrada: A,E,D,C,B = valor FLOAT
    ; Salida:  HL = puntero a la cadena (heap), formato [longitud(2B)][texto]
    call FP_TO_STR      ; HL = puntero al texto, BC = longitud
    PROC
    LOCAL __STR_END

    push hl             ; guarda puntero al texto (FP_STR_BUF)
    push bc             ; guarda longitud

    ld   hl, 2
    add  hl, bc
    ld   b, h
    ld   c, l
    call __MEM_ALLOC    ; HL = nuevo bloque de (longitud+2) bytes (o NULL)

    pop  bc             ; longitud del texto
    pop  de             ; puntero al texto (FP_STR_BUF)

    ld   a, h
    or   l
    jr   z, __STR_END   ; sin memoria -> devuelve NULL

    push hl
    ld   (hl), c
    inc  hl
    ld   (hl), b
    inc  hl             ; HL = destino del texto

    ex   de, hl         ; HL = origen (texto), DE = destino
    ldir

    pop  hl             ; HL = puntero a la cadena resultante

__STR_END:
    ret

    ENDP

    pop namespace
