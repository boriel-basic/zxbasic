; Bresenham's like circle algorithm
; best known as Middle Point Circle drawing algorithm

#include once <error.asm>
#include once <plot.asm>
#include once <in_screen.asm>

; Draws a circle at X, Y of radius R
; X, Y on the Stack, R in accumulator (Byte)

		PROC
		LOCAL __CIRCLE_ERROR
		LOCAL __CIRCLE_LOOP
		LOCAL __CIRCLE_NEXT

__CIRCLE_ERROR:
        jp __OUT_OF_SCREEN_ERR
;; __CIRCLE_ERROR EQU __OUT_OF_SCREEN_ERR
;; __CIRCLE_ERROR:
;; 		; Jumps here if out of screen
;; 		scf ; Always sets carry Flag
;; 
;; 		ld a, ERROR_OutOfScreen
;; 		ld (ERR_NR), a
;; 		ret
CIRCLE:
        ;; Entry point
		pop hl	; Return Address
		pop de	; D = Y
		ex (sp), hl ; __CALLEE__ convention
		ld e, h ; E = X


		ld h, a ; H = R	
		add a, d
		sub 192
		jr nc, __CIRCLE_ERROR

		ld a, d
		sub h
		jr c, __CIRCLE_ERROR

		ld a, e
		sub h
		jr c, __CIRCLE_ERROR

		ld a, h
		add a, e
		jr c, __CIRCLE_ERROR


; __FASTCALL__ Entry: D, E = Y, X point of the center
; A = Radious
__CIRCLE:
		push de	
		ld a, h
		exx
		pop de		; D'E' = x0, y0
		ld h, a		; H' = r

		ld c, e
		ld a, h
		add a, d
		ld b, a
		call __CIRCLE_PLOT	; PLOT (x0, y0 + r)

		ld b, d
		ld a, h
		add a, e
		ld c, a
		call __CIRCLE_PLOT	; PLOT (x0 + r, y0)

		ld c, e
		ld a, d
		sub h
		ld b, a
		call __CIRCLE_PLOT ; PLOT (x0, y0 - r)

		ld b, d
		ld a, e
		sub h
		ld c, a
		call __CIRCLE_PLOT ; PLOT (x0 - r, y0)

		exx
		ld b, 0		; B = x = 0
		ld c, h		; C = y = Radius
		ld hl, 1
		or a
		sbc hl, bc	; HL = f = 1 - radius

		ex de, hl
		ld hl, 0
		or a
		sbc hl, bc  ; HL = -radius
		add hl, hl	; HL = -2 * radius
		ex de, hl	; DE = -2 * radius = ddF_y, HL = f

		xor a		; A = ddF_x = 0
		ex af, af'	; Saves it

__CIRCLE_LOOP:
		ld a, b
		cp c
		ret nc		; Returns when x >= y

		bit 7, h	; HL >= 0? : if (f >= 0)...
		jp nz, __CIRCLE_NEXT

		dec c		; y--
		inc de
		inc de		; ddF_y += 2

		add hl, de	; f += ddF_y

__CIRCLE_NEXT:
		inc b		; x++
		ex af, af'
		add a, 2	; 1 Cycle faster than inc a, inc a

		inc hl		; f++
		push af
		add a, l
		ld l, a
		ld a, h
		adc a, 0	; f = f + ddF_x
		ld h, a
		pop af
		ex af, af'

		push bc	
		exx
		pop hl		; H'L' = Y, X
		
		ld a, d
		add a, h
		ld b, a		; B = y0 + y
		ld a, e
		add a, l
		ld c, a		; C = x0 + x
		call __CIRCLE_PLOT ; plot(x0 + x, y0 + y)

		ld a, d
		add a, h
		ld b, a		; B = y0 + y
		ld a, e
		sub l
		ld c, a		; C = x0 - x
		call __CIRCLE_PLOT ; plot(x0 - x, y0 + y)

		ld a, d
		sub h
		ld b, a		; B = y0 - y
		ld a, e
		add a, l
		ld c, a		; C = x0 + x
		call __CIRCLE_PLOT ; plot(x0 + x, y0 - y)

		ld a, d
		sub h
		ld b, a		; B = y0 - y
		ld a, e
		sub l
		ld c, a		; C = x0 - x
		call __CIRCLE_PLOT ; plot(x0 - x, y0 - y)
		
		ld a, d
		add a, l
		ld b, a		; B = y0 + x
		ld a, e	
		add a, h
		ld c, a		; C = x0 + y
		call __CIRCLE_PLOT ; plot(x0 + y, y0 + x)
		
		ld a, d
		add a, l
		ld b, a		; B = y0 + x
		ld a, e	
		sub h
		ld c, a		; C = x0 - y
		call __CIRCLE_PLOT ; plot(x0 - y, y0 + x)

		ld a, d
		sub l
		ld b, a		; B = y0 - x
		ld a, e	
		add a, h
		ld c, a		; C = x0 + y
		call __CIRCLE_PLOT ; plot(x0 + y, y0 - x)

		ld a, d
		sub l
		ld b, a		; B = y0 - x
		ld a, e	
		sub h
		ld c, a		; C = x0 + y
		call __CIRCLE_PLOT ; plot(x0 - y, y0 - x)

		exx
		jp __CIRCLE_LOOP



__CIRCLE_PLOT:
		; Plots a point of the circle, preserving HL and DE
		push hl
		push de
		call __PLOT	
		pop de
		pop hl
		ret
		
		ENDP
