; String library

#include once <free.asm>

__STR_ISNULL:	; Returns A = FF if HL is 0, 0 otherwise
		ld a, h
		or l
		sub 1		; Only CARRY if HL is NULL
		sbc a, a	; Only FF if HL is NULL (0 otherwise)
		ret


__STRCMP:	; Compares strings at HL, DE: Returns 0 if EQual, -1 if HL < DE, +1 if HL > DE
			; A register is preserved and returned in A'
		PROC ; __FASTCALL__

		LOCAL __STRCMPZERO
		LOCAL __STRCMPEXIT
		LOCAL __STRCMPLOOP
		LOCAL __NOPRESERVEBC
		LOCAL __EQULEN
		LOCAL __EQULEN1
		LOCAL __HLZERO

		ex af, af'	; Saves current A register in A' (it's used by STRXX comparison functions)

		ld a, h
		or l
		jr z, __HLZERO

		ld a, d
		or e
		ld a, 1
		ret z		; Returns +1 if HL is not NULL and DE is NULL

		ld c, (hl)
		inc hl
		ld b, (hl)
		inc hl		; BC = LEN(a$)
		push hl		; HL = &a$, saves it

		ex de, hl
		ld e, (hl)
		inc hl
		ld d, (hl)
		inc hl
		ex de, hl	; HL = LEN(b$), de = &b$

		; At this point Carry is cleared, and A reg. = 1
		sbc hl, bc	; Carry if len(b$) > len(a$)
		jr z, __EQULEN	; Jump if they have the same length so A reg. = 0
		jr c, __EQULEN1 ; Jump if len(b$) > len(a$) so A reg. = 1
__NOPRESERVEBC:
		add hl, bc	; Restore HL (original length)
		ld b, h		; len(b$) <= len(a$)
		ld c, l		; so BC = hl
		dec a		; At this point A register = 0, it must be -1 since len(a$) > len(b$)	
__EQULEN:
		dec a		; A = 0 if len(a$) = len(b$), -1 otherwise
__EQULEN1:
		pop hl		; Recovers A$ pointer
		push af		; Saves A for later (Value to return if strings reach the end)
        ld a, b
        or c
        jr z, __STRCMPZERO ; empty string being compared

		; At this point: BC = lesser length, DE and HL points to b$ and a$ chars respectively
__STRCMPLOOP:
		ld a, (de)
		cpi
		jr nz, __STRCMPEXIT ; (HL) != (DE). Examine carry
		jp po, __STRCMPZERO ; END of string (both are equal)
		inc de
		jp __STRCMPLOOP

__STRCMPZERO:
		pop af		; This is -1 if len(a$) < len(b$), +1 if len(b$) > len(a$), 0 otherwise
		ret

__STRCMPEXIT:		; Sets A with the following value
		dec hl		; Get back to the last char
		cp (hl)
		sbc a, a	; A = -1 if carry => (DE) < (HL); 0 otherwise (DE) > (HL)
		cpl			; A = -1 if (HL) < (DE), 0 otherwise
		add a, a    ; A = A * 2 (thus -2 or 0)
		inc a		; A = A + 1 (thus -1 or 1)

		pop bc		; Discard top of the stack
		ret

__HLZERO:
		or d
		or e
		ret z		; Returns 0 (EQ) if HL == DE == NULL
		ld a, -1
		ret			; Returns -1 if HL is NULL and DE is not NULL

		ENDP

		; The following routines perform string comparison operations (<, >, ==, etc...)
		; On return, A will contain 0 for False, other value for True
		; Register A' will determine whether the incoming strings (HL, DE) will be freed
		; from dynamic memory on exit:
		;		Bit 0 => 1 means HL will be freed.
		;		Bit 1 => 1 means DE will be freed.

__STREQ:	; Compares a$ == b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
		push hl
		push de
		call __STRCMP
		pop de
		pop hl

		;inc a		; If A == -1, return 0
		;jp z, __FREE_STR 
	
		;dec a		; 
		;dec a		; Return -1 if a = 0 (True), returns 0 if A == 1 (False)
        sub 1
        sbc a, a
		jp __FREE_STR


__STRNE:	; Compares a$ != b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
		push hl
		push de
		call __STRCMP
		pop de
		pop hl

		;jp z, __FREE_STR 

		;ld a, 0FFh	; Returns 0xFFh (True)
		jp __FREE_STR


__STRLT:	; Compares a$ < b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
		push hl
		push de
		call __STRCMP
		pop de
		pop hl

		jp z, __FREE_STR ; Returns 0 if A == B

		dec a		; Returns 0 if A == 1 => a$ > b$
		;jp z, __FREE_STR 

		;inc a		; A = FE now (-2). Set it to FF and return
		jp __FREE_STR


__STRLE:	; Compares a$ <= b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
		push hl
		push de
		call __STRCMP
		pop de
		pop hl

		dec a		; Returns 0 if A == 1 => a$ < b$
		;jp z, __FREE_STR 

		;ld a, 0FFh	; A = FE now (-2). Set it to FF and return
		jp __FREE_STR


__STRGT:	; Compares a$ > b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
		push hl
		push de
		call __STRCMP
		pop de
		pop hl

		jp z, __FREE_STR		; Returns 0 if A == B

		inc a		; Returns 0 if A == -1 => a$ < b$
		;jp z, __FREE_STR		; Returns 0 if A == B

		;ld a, 0FFh	; A = FE now (-2). Set it to FF and return
		jp __FREE_STR


__STRGE:	; Compares a$ >= b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
		push hl
		push de
		call __STRCMP
		pop de
		pop hl

		inc a		; Returns 0 if A == -1 => a$ < b$
		;jr z, __FREE_STR

		;ld a, 0FFh	; A = FE now (-2). Set it to FF and return

__FREE_STR: ; This exit point will test A' for bits 0 and 1
			; If bit 0 is 1 => Free memory from HL pointer
			; If bit 1 is 1 => Free memory from DE pointer
			; Finally recovers A, to return the result
		PROC

		LOCAL __FREE_STR2
		LOCAL __FREE_END

		ex af, af'
		bit 0, a
		jr z, __FREE_STR2

		push af
		push de
		call __MEM_FREE
		pop de
		pop af

__FREE_STR2:
		bit 1, a
		jr z, __FREE_END

		ex de, hl
		call __MEM_FREE

__FREE_END:
		ex af, af'
		ret
		
		ENDP

