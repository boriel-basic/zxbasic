; vim:ts=4:et:sw=4
; 
; Stores an string (pointer to the HEAP by DE) into the address pointed
; by (IX + BC). No new copy of the string is created into the HEAP, since
; it's supposed it's already created (temporary string)
;

#include once <storestr2.asm>

__PSTORE_STR2:
    push ix
    pop hl
    add hl, bc
    jp __STORE_STR2

