; MIXED __FASTCAL__ / __CALLE__ PLOT Function
; Plots a point into the screen calling the ZX ROM PLOT routine

; Y in A (accumulator)
; X in top of the stack

#include once <error.asm>
#include once <in_screen.asm>

PLOT:
	PROC

	LOCAL PLOT_SUB
	LOCAL PIXEL_ADDR
	LOCAL COORDS
	LOCAL __PLOT_ERR

	pop hl
	ex (sp), hl ; Callee

	ld b, a
	ld c, h	

	ld a, 191
	cp b
	jr c, __PLOT_ERR ; jr is faster here (#1)

__PLOT:			; __FASTCALL__ entry
	ld (COORDS), bc	; Saves current point
	ld a, 191 ; Max y coord
	call PIXEL_ADDR
	jp PLOT_SUB ; ROM PLOT

;; __PLOT_ERR:    	; Return on error
;;     ld a, ERROR_OutOfScreen
;;     ld (ERR_NR), a
;;     ret
;;__PLOT_ERR EQU __OUT_OF_SCREEN_ERR
__PLOT_ERR:
    jp __OUT_OF_SCREEN_ERR ; Spent 3 bytes, but saves 3 T-States at (#1)

PLOT_SUB EQU 22ECh
PIXEL_ADDR EQU 22ACh 
COORDS EQU 5C7Dh
	ENDP
