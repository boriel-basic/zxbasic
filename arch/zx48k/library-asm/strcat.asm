#include once <alloc.asm>
#include once <strlen.asm>

__ADDSTR:	; Implements c$ = a$ + b$
			; hl = &a$, de = &b$ (pointers)


__STRCAT2:	; This routine creates a new string in dynamic space
			; making room for it. Then copies a$ + b$ into it.
			; HL = a$, DE = b$

		PROC

		LOCAL __STR_CONT
		LOCAL __STRCATEND

		push hl
		call __STRLEN
		ld c, l
		ld b, h		; BC = LEN(a$)
		ex (sp), hl ; (SP) = LEN (a$), HL = a$
		push hl		; Saves pointer to a$

		inc bc
		inc bc		; +2 bytes to store length

		ex de, hl
		push hl
		call __STRLEN
		; HL = len(b$)

		add hl, bc	; Total str length => 2 + len(a$) + len(b$)

		ld c, l
		ld b, h		; BC = Total str length + 2
		call __MEM_ALLOC 
		pop de		; HL = c$, DE = b$ 

		ex de, hl	; HL = b$, DE = c$
		ex (sp), hl ; HL = a$, (SP) = b$ 

		exx
		pop de		; D'E' = b$ 
		exx

		pop bc		; LEN(a$)

		ld a, d
		or e
		ret z		; If no memory: RETURN

__STR_CONT:
		push de		; Address of c$

		ld a, h
		or l
		jr nz, __STR_CONT1 ; If len(a$) != 0 do copy

        ; a$ is NULL => uses HL = DE for transfer
		ld h, d
		ld l, e
		ld (hl), a	; This will copy 00 00 at (DE) location
        inc de      ; 
        dec bc      ; Ensure BC will be set to 1 in the next step

__STR_CONT1:        ; Copies a$ (HL) into c$ (DE)
		inc bc			
		inc bc		; BC = BC + 2
		ldir		; MEMCOPY: c$ = a$
		pop hl		; HL = c$

		exx
		push de		; Recovers b$; A ex hl,hl' would be very handy
		exx

		pop de		; DE = b$ 

__STRCAT: ; ConCATenate two strings a$ = a$ + b$. HL = ptr to a$, DE = ptr to b$
		  ; NOTE: Both DE, BC and AF are modified and lost
		  ; Returns HL (pointer to a$)
		  ; a$ Must be NOT NULL
		ld a, d
		or e
		ret z		; Returns if de is NULL (nothing to copy)

		push hl		; Saves HL to return it later

		ld c, (hl)
		inc hl
		ld b, (hl)
		inc hl
		add hl, bc	; HL = end of (a$) string ; bc = len(a$)
		push bc		; Saves LEN(a$) for later

		ex de, hl	; DE = end of string (Begin of copy addr)
		ld c, (hl)
		inc hl
		ld b, (hl)	; BC = len(b$)

		ld a, b
		or c
		jr z, __STRCATEND; Return if len(b$) == 0

		push bc			 ; Save LEN(b$)
		inc hl			 ; Skip 2nd byte of len(b$)
		ldir			 ; Concatenate b$

		pop bc			 ; Recovers length (b$)
		pop hl			 ; Recovers length (a$)
		add hl, bc		 ; HL = LEN(a$) + LEN(b$) = LEN(a$+b$)
		ex de, hl		 ; DE = LEN(a$+b$)
		pop hl

		ld (hl), e		 ; Updates new LEN and return
		inc hl
		ld (hl), d
		dec hl
		ret

__STRCATEND:
		pop hl		; Removes Len(a$)
		pop hl		; Restores original HL, so HL = a$
		ret

		ENDP

