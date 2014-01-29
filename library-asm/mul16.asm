__MUL16:	; Mutiplies HL with the last value stored into de stack
			; Works for both signed and unsigned

		PROC

		LOCAL __MUL16LOOP
        LOCAL __MUL16NOADD
		
		ex de, hl
		pop hl		; Return address
		ex (sp), hl ; CALLEE caller convention

;;__MUL16_FAST:	; __FASTCALL ENTRY: HL = 1st operand, DE = 2nd Operand
;;		ld c, h
;;		ld a, l	 ; C,A => 1st Operand
;;
;;		ld hl, 0 ; Accumulator
;;		ld b, 16
;;
;;__MUL16LOOP:
;;		sra c	; C,A >> 1  (Arithmetic)
;;		rra
;;
;;		jr nc, __MUL16NOADD
;;		add hl, de
;;
;;__MUL16NOADD:
;;		sla e
;;		rl d
;;			
;;		djnz __MUL16LOOP

__MUL16_FAST:
        ld b, 16
        ld a, d
        ld c, e
        ex de, hl
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

