; Stores FP number in A ED CB at location HL+IX
; HL = Offset
; IX = Stack Frame
; A ED CB = FP Number

#include once <storef.asm>

; Stored a float number in A ED CB into the address pointed by IX + HL
__PSTOREF:
	push de
    ex de, hl  ; DE <- HL
    push ix
	pop hl	   ; HL <- IX
    add hl, de ; HL <- IX + DE
	pop de	
    jp __STOREF

