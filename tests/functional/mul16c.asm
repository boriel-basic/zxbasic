	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	jp __MAIN_PROGRAM__
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_a:
	DEFB 00, 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, (_a)
	ld de, -1
	call __MUL16_FAST
	ld (_a), hl
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/mul16.asm"
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
#line 21 "mul16c.bas"
	END
