; This function just returns the address of the UDG of the given str.
; If the str is EMPTY or not a letter, 0 is returned and ERR_NR set
; to "A: Invalid Argument"

; On entry HL points to the string
; and A register is non-zero if the string must be freed (TMP string)

#include once <error.asm>
#include once <const.asm>
#include once <free.asm>

USR_STR:
    ld d, a     ; Saves A flag

	ld a, h
	or l
	jr z, USR_ERROR ; a$ = NULL => Invalid Arg

	ld c, (hl)
	inc hl
	ld a, (hl)
	or c
	jr z, USR_ERROR ; a$ = "" => Invalid Arg

	inc hl
	ld a, (hl) ; Only the 1st char is needed
	and 11011111b ; Convert it to UPPER CASE
	sub 'A'
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl	 ; hl = A * 8
	ld bc, (UDG)
	add hl, bc
    
    ;; Now checks if the string must be released
    ld d, a
    or a
    ret z   ; return if not

    push hl ; saves result since __MEM_FREE changes HL
    call __MEM_FREE
    pop hl
	ret

USR_ERROR:
    ld a, d
    or a
    call nz, __MEM_FREE

	ld a, ERROR_InvalidArg
	ld (ERR_NR), a
	ld hl, 0
	ret
	
