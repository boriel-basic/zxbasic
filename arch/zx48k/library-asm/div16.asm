; 16 bit division and modulo functions 
; for both signed and unsigned values

#include once <neg16.asm>

__DIVU16:    ; 16 bit unsigned division
             ; HL = Dividend, Stack Top = Divisor

	;   -- OBSOLETE ; Now uses FASTCALL convention
	;   ex de, hl
    ;	pop hl      ; Return address
    ;	ex (sp), hl ; CALLEE Convention

__DIVU16_FAST:
    ld a, h
    ld c, l
    ld hl, 0
    ld b, 16

__DIV16LOOP:
    sll c
    rla
    adc hl,hl
    sbc hl,de
    jr  nc, __DIV16NOADD
    add hl,de
    dec c

__DIV16NOADD:
    djnz __DIV16LOOP

    ex de, hl
    ld h, a
    ld l, c

    ret     ; HL = quotient, DE = Mudulus



__MODU16:    ; 16 bit modulus
             ; HL = Dividend, Stack Top = Divisor

    ;ex de, hl
    ;pop hl
    ;ex (sp), hl ; CALLEE Convention

    call __DIVU16_FAST
    ex de, hl	; hl = reminder (modulus)
				; de = quotient

    ret


__DIVI16:	; 16 bit signed division
	;	--- The following is OBSOLETE ---
	;	ex de, hl
	;	pop hl
	;	ex (sp), hl 	; CALLEE Convention

__DIVI16_FAST:
	ld a, d
	xor h
	ex af, af'		; BIT 7 of a contains result

	bit 7, d		; DE is negative?
	jr z, __DIVI16A	

	ld a, e			; DE = -DE
	cpl
	ld e, a
	ld a, d
	cpl
	ld d, a
	inc de

__DIVI16A:
	bit 7, h		; HL is negative?
	call nz, __NEGHL

__DIVI16B:
	call __DIVU16_FAST
	ex af, af'

	or a	
	ret p	; return if positive
    jp __NEGHL

	
__MODI16:    ; 16 bit modulus
             ; HL = Dividend, Stack Top = Divisor

    ;ex de, hl
    ;pop hl
    ;ex (sp), hl ; CALLEE Convention

    call __DIVI16_FAST
    ex de, hl	; hl = reminder (modulus)
				; de = quotient

    ret

