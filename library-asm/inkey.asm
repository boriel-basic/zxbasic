; INKEY Function
; Returns a string allocated in dynamic memory
; containing the string.
; An empty string otherwise.

#include once <alloc.asm>

INKEY:
	PROC 
	LOCAL __EMPTY_INKEY
	LOCAL KEY_SCAN
	LOCAL KEY_TEST
	LOCAL KEY_CODE

	ld bc, 3	; 1 char length string 
	call __MEM_ALLOC

	ld a, h
	or l
	ret z	; Return if NULL (No memory)

	push hl ; Saves memory pointer

	call KEY_SCAN
	jp nz, __EMPTY_INKEY
	
	call KEY_TEST
	jp nc, __EMPTY_INKEY

	dec d	; D is expected to be FLAGS so set bit 3 $FF
			; 'L' Mode so no keywords.
	ld e, a	; main key to A
			; C is MODE 0 'KLC' from above still.
	call KEY_CODE ; routine K-DECODE
	pop hl

	ld (hl), 1
	inc hl
	ld (hl), 0
	inc hl
	ld (hl), a
	dec hl
	dec hl	; HL Points to string result
	ret

__EMPTY_INKEY:
	pop hl
	xor a
	ld (hl), a
	inc hl
	ld (hl), a
	dec hl
	ret

KEY_SCAN	EQU 028Eh
KEY_TEST	EQU 031Eh
KEY_CODE	EQU 0333h

	ENDP

