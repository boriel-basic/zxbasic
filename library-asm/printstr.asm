#include once <print.asm>
#include once <sposn.asm>
#include once <attr.asm>
#include once <free.asm>

; PRINT command routine
; Prints string pointed by HL

PRINT_STR:
__PRINTSTR:		; __FASTCALL__ Entry to print_string
		PROC
		LOCAL __PRINT_STR_LOOP
        LOCAL __PRINT_STR_END

        ld d, a ; Saves A reg (Flag) for later

		ld a, h
		or l
		ret z	; Return if the pointer is NULL

        push hl

		ld c, (hl)
		inc hl
		ld b, (hl)
		inc hl	; BC = LEN(a$); HL = &a$

__PRINT_STR_LOOP:
		ld a, b
		or c
		jr z, __PRINT_STR_END 	; END if BC (counter = 0)

		ld a, (hl)
		call __PRINTCHAR
		inc hl
		dec bc
		jp __PRINT_STR_LOOP

__PRINT_STR_END:
        pop hl
        ld a, d ; Recovers A flag
        or a   ; If not 0 this is a temporary string. Free it
        ret z
        jp __MEM_FREE ; Frees str from heap and return from there

__PRINT_STR:
        ; Fastcall Entry
        ; It ONLY prints strings
        ; HL = String start
        ; BC = String length (Number of chars)
        push hl ; Push str address for later
        ld d, a ; Saves a FLAG
        jp __PRINT_STR_LOOP

		ENDP

