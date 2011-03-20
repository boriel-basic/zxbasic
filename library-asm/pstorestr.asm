; vim:ts=4:et:sw=4
; 
; Stores an string (pointer to the HEAP by DE) into the address pointed
; by IX + BC
;

#include once <storestr.asm>

__PSTORE_STR:
    push ix
    pop hl
    add hl, bc
    jp __STORE_STR

