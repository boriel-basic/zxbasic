; load.asm (zx81sd) — LOAD/VERIFY ... CODE desde la tarjeta SD
;
; Sustituye a zx48k/runtime/load.asm (que usa LD-BYTES de cinta, puerto
; $FE y cabeceras de cassette del Spectrum). Aqui el statement LOAD de
; zxbasic carga el fichero desde la SD del SD81 Booster con el comando 9
; del MCU (ver io/sd81_mcu.asm para el protocolo).
;
; Interfaz del compilador (identica a zx48k):
;   pila: A = 1 LOAD / 0 VERIFY; BC = longitud; DE = direccion destino;
;         HL = string de zxbasic con el nombre (hay que liberarlo).
;
; Semantica:
;   - BC = 0: carga el fichero completo en DE.
;   - BC > 0: carga como maximo BC bytes en DE; si el fichero es mayor
;     se descarta el resto (el protocolo obliga a consumirlo); si es
;     menor se marca error de carga.
;   - VERIFY: compara en vez de escribir; diferencia = error de carga.
;   - Error (fichero no existe, etc.): ERR_NR = ERROR_TapeLoadingErr y
;     se retorna (mismo comportamiento "blando" que la version de cinta).
;   - Ojo con extensiones especiales del MCU: un .ROM resetea la CPU
;     (no retorna) y un .WAV solo se reproduce (carga 0 bytes).

#include once <error.asm>
#include once <mem/free.asm>
#include once <io/sd81_mcu.asm>

    push namespace core

LOAD_CODE:
    PROC
    LOCAL LC_FLAG, LC_REQ, LC_DEST, LC_SIZE, LC_N
    LOCAL LC_HAVE_SIZE, LC_USE_REQ, LC_DO_RECV, LC_DRAIN
    LOCAL LC_ERROR, LC_END, LC_ERR_NOFREE
    LOCAL LC_VERIFY

    pop  hl                 ; direccion de retorno
    pop  af                 ; A = 1 LOAD / 0 VERIFY
    pop  bc                 ; longitud solicitada
    pop  de                 ; direccion destino
    ex   (sp), hl           ; CALLEE: HL = string con el nombre

    ld   (LC_FLAG), a
    ld   (LC_REQ), bc
    ld   (LC_DEST), de

    ld   a, h
    or   l
    jp   z, LC_ERR_NOFREE   ; string nulo

    push hl                 ; salva el puntero para MEM_FREE

    ; longitud del nombre 0 -> error (tras liberar)
    ld   e, (hl)
    inc  hl
    ld   d, (hl)
    dec  hl
    ld   a, d
    or   e
    jr   nz, LC_HAVE_SIZE

    pop  hl
    call MEM_FREE
    jp   LC_ERR_NOFREE

LC_HAVE_SIZE:
    ; comando 9 (LOAD) + nombre
    ld   a, 9
    call SD81_MCU_SEND
    call SD81_MCU_SEND_NAME
    pop  hl
    call MEM_FREE           ; el nombre ya viajo: libera el string

    ; tamano real del fichero (little-endian)
    call SD81_MCU_RECV
    ld   l, a
    call SD81_MCU_RECV
    ld   h, a
    ld   (LC_SIZE), hl

    ; n = (LC_REQ = 0) ? size : min(LC_REQ, size)
    ld   bc, (LC_REQ)
    ld   a, b
    or   c
    jr   z, LC_DO_RECV      ; BC=0: n = size (ya en HL)
    or   a
    sbc  hl, bc             ; size - req
    jr   nc, LC_USE_REQ     ; size >= req: n = req
    ld   hl, (LC_SIZE)      ; size < req: n = size (y sera error corto)
    jr   LC_DO_RECV
LC_USE_REQ:
    ld   hl, (LC_REQ)

LC_DO_RECV:
    ld   (LC_N), hl
    ld   b, h
    ld   c, l               ; BC = n
    ld   hl, (LC_DEST)
    ld   a, (LC_FLAG)
    or   a
    jr   z, LC_VERIFY

    call SD81_MCU_RECV_BLOCK
    xor  a                  ; sin diferencias
    jr   LC_DRAIN

LC_VERIFY:
    call SD81_MCU_RECV_VERIFY ; A = 1 si hubo diferencias

LC_DRAIN:
    push af                 ; salva el resultado de la verificacion
    ; descarta lo que sobre: size - n
    ld   hl, (LC_SIZE)
    ld   bc, (LC_N)
    or   a
    sbc  hl, bc
    ld   b, h
    ld   c, l
    call SD81_MCU_RECV_SINK

    call SD81_MCU_RECV      ; byte de estado del MCU
    ld   e, a
    pop  af
    or   e                  ; error si status != 0 o verificacion fallida
    jp   nz, LC_ERROR

    ; carga corta: se pidieron LC_REQ (>0) bytes y el fichero era menor
    ld   bc, (LC_REQ)
    ld   a, b
    or   c
    jr   z, LC_END
    ld   hl, (LC_N)
    or   a
    sbc  hl, bc
    jr   z, LC_END          ; n = req: completo

LC_ERROR:
    ld   a, ERROR_TapeLoadingErr
    ld   (ERR_NR), a
LC_END:
    ret

LC_ERR_NOFREE:
    ld   a, ERROR_InvalidFileName
    ld   (ERR_NR), a
    ret

LC_FLAG:
    defb 0
LC_REQ:
    defw 0
LC_DEST:
    defw 0
LC_SIZE:
    defw 0
LC_N:
    defw 0

    ENDP

    pop namespace
