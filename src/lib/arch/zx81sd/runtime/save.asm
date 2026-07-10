; save.asm (zx81sd) — SAVE ... CODE a la tarjeta SD
;
; Sustituye a zx48k/runtime/save.asm (que usa SA-BYTES de cinta de la
; ROM Spectrum). El statement SAVE de zxbasic guarda el bloque en la SD
; del SD81 Booster con el comando 10 del MCU (ver io/sd81_mcu.asm).
;
; Interfaz del compilador (identica a zx48k):
;   pila: BC = longitud; DE = direccion origen;
;         HL = string de zxbasic con el nombre (hay que liberarlo).
;
; Errores ("blandos", como la version de cinta): nombre nulo/vacio ->
; ERROR_InvalidFileName; longitud 0 -> ERROR_InvalidArg; fallo del MCU
; (SD llena, etc.) -> ERROR_TapeLoadingErr. En todos se retorna con
; ERR_NR puesto.

#include once <error.asm>
#include once <mem/free.asm>
#include once <io/sd81_mcu.asm>

    push namespace core

SAVE_CODE:
    PROC
    LOCAL SC_LEN, SC_SRC
    LOCAL SC_HAVE_NAME, SC_ERR_NAME_NOFREE, SC_DO_SAVE

    pop  hl                 ; direccion de retorno
    pop  bc                 ; longitud
    pop  de                 ; direccion origen
    ex   (sp), hl           ; CALLEE: HL = string con el nombre

    ld   (SC_LEN), bc
    ld   (SC_SRC), de

    ld   a, h
    or   l
    jp   z, SC_ERR_NAME_NOFREE  ; string nulo

    ; longitud del bloque 0 -> error (liberando el string)
    ld   a, b
    or   c
    jr   nz, SC_HAVE_NAME
    call MEM_FREE
    ld   a, ERROR_InvalidArg
    ld   (ERR_NR), a
    ret

SC_HAVE_NAME:
    ; nombre vacio -> error (tras liberar)
    ld   e, (hl)
    inc  hl
    ld   d, (hl)
    dec  hl
    ld   a, d
    or   e
    jr   nz, SC_DO_SAVE

    call MEM_FREE
    jp   SC_ERR_NAME_NOFREE

SC_DO_SAVE:
    ; comando 10 (SAVE) + nombre + longitud + datos + status
    push hl
    ld   a, 10
    call SD81_MCU_SEND
    pop  hl
    push hl
    call SD81_MCU_SEND_NAME
    pop  hl
    call MEM_FREE

    ld   bc, (SC_LEN)
    ld   a, c
    call SD81_MCU_SEND      ; longitud, byte bajo
    ld   a, b
    call SD81_MCU_SEND      ; longitud, byte alto

    ld   hl, (SC_SRC)
    call SD81_MCU_SEND_BLOCK

    call SD81_MCU_RECV      ; byte de estado
    or   a
    ret  z
    ld   a, ERROR_TapeLoadingErr
    ld   (ERR_NR), a
    ret

SC_ERR_NAME_NOFREE:
    ld   a, ERROR_InvalidFileName
    ld   (ERR_NR), a
    ret

SC_LEN:
    defw 0
SC_SRC:
    defw 0

    ENDP

    pop namespace
