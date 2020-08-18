__MUL8:		; Performs 8bit x 8bit multiplication
	PROC

	;LOCAL __MUL8A
	LOCAL __MUL8LOOP
	LOCAL __MUL8B
			; 1st operand (byte) in A, 2nd operand into the stack (AF)
	pop hl	; return address
	ex (sp), hl ; CALLE convention

;;__MUL8_FAST: ; __FASTCALL__ entry
;;	ld e, a
;;	ld d, 0
;;	ld l, d
;;	
;;	sla h	
;;	jr nc, __MUL8A
;;	ld l, e
;;
;;__MUL8A:
;;
;;	ld b, 7
;;__MUL8LOOP:
;;	add hl, hl
;;	jr nc, __MUL8B
;;
;;	add hl, de
;;
;;__MUL8B:
;;	djnz __MUL8LOOP
;;
;;	ld a, l ; result = A and HL  (Truncate to lower 8 bits)

__MUL8_FAST: ; __FASTCALL__ entry, a = a * h (8 bit mul) and Carry

    ld b, 8
    ld l, a
    xor a

__MUL8LOOP:
    add a, a ; a *= 2
    sla l
    jp nc, __MUL8B
    add a, h

__MUL8B:
    djnz __MUL8LOOP
	
	ret		; result = HL
	ENDP

