; INKEY Function (zx81sd)
; Returns a string allocated in dynamic memory
; containing the string.
; An empty string otherwise.
;
; La version de zx48k llama a rutinas de la ROM del Spectrum
; (KEY_SCAN/KEY_TEST/KEY_CODE) que no existen en tiempo de ejecucion en
; zx81sd (no hay ROM mapeada). Se sustituye por un escaneo directo de la
; matriz de teclado del ZX81 y una decodificacion propia a ASCII.

#include once <mem/alloc.asm>
#include once <io/keyboard/keyscan.asm>

    push namespace core

INKEY:
    PROC
    LOCAL __EMPTY_INKEY

    ld bc, 3	; 1 char length string
    call __MEM_ALLOC

    ld a, h
    or l
    ret z	; Return if NULL (No memory)

    push hl ; Saves memory pointer

    call __ZX81SD_KEYSCAN
    pop hl
    or a
    jr z, __EMPTY_INKEY

    ld (hl), 1
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), a
    dec hl
    dec hl	; HL Points to string result
    ret

__EMPTY_INKEY:
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    dec hl
    ret

    ENDP

    pop namespace
