#include once <sposn.asm>
#include once <error.asm>

__IN_SCREEN:
	; Returns NO carry if current coords (D, E)
	; are OUT of the screen limits (MAXX, MAXY)

	PROC
	LOCAL __IN_SCREEN_ERR

	ld hl, MAXX
	ld a, e
	cp (hl)
	jr nc, __IN_SCREEN_ERR	; Do nothing and return if out of range

	ld a, d
	inc hl
	cp (hl)
	;; jr nc, __IN_SCREEN_ERR	; Do nothing and return if out of range
	;; ret
    ret c                       ; Return if carry (OK)

__IN_SCREEN_ERR:
__OUT_OF_SCREEN_ERR:
	; Jumps here if out of screen
	ld a, ERROR_OutOfScreen
    jp __STOP   ; Saves error code and exits

	ENDP
