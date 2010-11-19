#include once <print.asm>
#include once <sposn.asm>
#include once <attr.asm>

; PRINT command routine
; Prints string pointed by HL

PRINT_STR:
__PRINTSTR:		; __FASTCALL__ Entry to print_string
		PROC
		LOCAL __PRINT_STR_LOOP

		ld a, h
		or l
		ret z	; Return if the pointer is NULL

		ld c, (hl)
		inc hl
		ld b, (hl)
		inc hl	; BC = LEN(a$); HL = &a$

__PRINT_STR:
; Fastcall Entry
; It ONLY prints strings
; HL = String start
; BC = String length (Number of chars)
		ex de, hl	; Uses DE for printing since HL might be needed later (e.g. for __MEM_FREE)

__PRINT_STR_LOOP:
		ld a, b
		or c
		ret z 	; Return if BC (counter = 0)

		ld a, (de)
		call __PRINTCHAR
		inc de 
		dec bc
		jp __PRINT_STR_LOOP

		ENDP

