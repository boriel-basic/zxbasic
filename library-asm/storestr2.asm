; Similar to __STORE_STR, but this one is called when
; the value of B$ if already duplicated onto the stack.
; So we needn't call STRASSING to create a duplication
; HL = address of string memory variable
; DE = address of 2n string. It just copies DE into (HL)
; 	freeing (HL) previously.

#include once <free.asm>

__PISTORE_STR2: ; Indirect store temporary string at (IX + BC)
    push ix
    pop hl
    add hl, bc

__ISTORE_STR2:
	ld c, (hl)  ; Dereferences HL
	inc hl
	ld h, (hl)
	ld l, c		; HL = *HL (real string variable address)

__STORE_STR2:
	push hl
	ld c, (hl)
	inc hl
	ld h, (hl)
	ld l, c		; HL = *HL (real string address)

	push de
	call __MEM_FREE
	pop de

	pop hl
	ld (hl), e
	inc hl
	ld (hl), d
	dec hl		; HL points to mem address variable. This might be useful in the future.

	ret

