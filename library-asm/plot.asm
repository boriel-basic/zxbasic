; MIXED __FASTCAL__ / __CALLE__ PLOT Function
; Plots a point into the screen calling the ZX ROM PLOT routine

; Y in A (accumulator)
; X in top of the stack

#include once <error.asm>
#include once <in_screen.asm>
#include once <cls.asm>

PLOT:
	PROC

	LOCAL PLOT_SUB
	LOCAL PIXEL_ADDR
	LOCAL COORDS
	LOCAL __PLOT_ERR
    LOCAL P_FLAG
    LOCAL __PLOT_OVER1

P_FLAG EQU 23697

	pop hl
	ex (sp), hl ; Callee

	ld b, a
	ld c, h	

	ld a, 191
	cp b
	jr c, __PLOT_ERR ; jr is faster here (#1)

__PLOT:			; __FASTCALL__ entry (b, c) = pixel coords (y, x)
	ld (COORDS), bc	; Saves current point
	ld a, 191 ; Max y coord
	call PIXEL_ADDR
    res 6, h    ; Starts from 0
    ld bc, (SCREEN_ADDR)
    add hl, bc  ; Now current offset

    ld b, a
    inc b
    ld a, 0FEh
LOCAL __PLOT_LOOP
__PLOT_LOOP:
    rrca
    djnz __PLOT_LOOP

    ld b, a
    ld a, (P_FLAG)
    ld c, a
    ld a, (hl)
    bit 0, c        ; is it OVER 1
    jr nz, __PLOT_OVER1
    and b

__PLOT_OVER1:
    bit 2, c        ; is it inverse 1
    jr nz, __PLOT_END

    xor b
    cpl

LOCAL __PLOT_END
__PLOT_END:
    ld (hl), a

;; gets ATTR position with offset given in SCREEN_ADDR
    ld a, h
    rrca
    rrca
    rrca
    and 3
    or 18h
    ld h, a
    ld de, (SCREEN_ADDR)
    add hl, de  ;; Final screen addr

LOCAL PO_ATTR_2
PO_ATTR_2 EQU 0BE4h  ; Another entry to PO_ATTR
    jp PO_ATTR_2   ; This will update attr accordingly. Beware, uses IY

__PLOT_ERR:
    jp __OUT_OF_SCREEN_ERR ; Spent 3 bytes, but saves 3 T-States at (#1)

PLOT_SUB EQU 22ECh
PIXEL_ADDR EQU 22ACh 
COORDS EQU 5C7Dh
	ENDP
