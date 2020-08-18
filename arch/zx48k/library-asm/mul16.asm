__MUL16:	; Mutiplies HL with the last value stored into de stack
			; Works for both signed and unsigned

		PROC

		LOCAL __MUL16LOOP
        LOCAL __MUL16NOADD
		
		ex de, hl
		pop hl		; Return address
		ex (sp), hl ; CALLEE caller convention

__MUL16_FAST:
        ld b, 16
        ld a, h
        ld c, l
        ld hl, 0

__MUL16LOOP:
        add hl, hl  ; hl << 1
        sla c
        rla         ; a,c << 1
        jp nc, __MUL16NOADD
        add hl, de

__MUL16NOADD:
        djnz __MUL16LOOP

		ret	; Result in hl (16 lower bits)

		ENDP

