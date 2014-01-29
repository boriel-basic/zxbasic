#include once <printnum.asm>
#include once <printi16.asm>
#include once <neg32.asm>

__PRINTF16:	; Prints a 32bit 16.16 fixed point number
	PROC

	LOCAL __PRINT_FIX_LOOP
	LOCAL __PRINTF16_2

	bit 7, d	
	jr z, __PRINTF16_2
	call __NEG32
	call __PRINT_MINUS

__PRINTF16_2:
	push hl
	ex de, hl
	call __PRINTU16 ; Prints integer part
	pop hl

	ld a, h
	or l
	ret z		; Returns if integer

	push hl
	ld a, '.'
	call __PRINT_DIGIT	; Prints decimal point
	pop hl

__PRINT_FIX_LOOP:
	ld a, h
	or l
	ret z		; Returns if no more decimals

	xor a
	ld d, h
	ld e, l
                ; Fast NUM * 10 multiplication
	add hl, hl	; 
	adc a, a    ; AHL = AHL * 2  (= X * 2)
	add hl, hl  ; 
	adc a, a    ; AHL = AHL * 2  (= X * 4)

	add hl, de  ; 
	adc a, 0    ; AHL = AHL + DE (= X * 5)
	add hl, hl
	adc a, a    ; AHL = AHL * 2 (= X * 10)

	push hl
	or '0'
	call __PRINT_DIGIT
	pop hl
	jp __PRINT_FIX_LOOP

	ENDP

