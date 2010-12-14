; DRAW using bresenhams algorithm and screen positioning
; Copyleft (k) 2010 by J. Rodriguez (a.k.a. Boriel) http://www.boriel.com
; vim:ts=4:et:sw=4:

; Y parameter in A
; X parameter in high byte on top of the stack

#include once <error.asm>
#include once <in_screen.asm>
#include once <plot.asm>

;; DRAW PROCEDURE
    PROC 

    LOCAL __DRAW1
    LOCAL __DRAW2
    LOCAL __DRAW3
    LOCAL __DRAW4, __DRAW4_LOOP
    LOCAL __DRAW5
    LOCAL __DRAW6, __DRAW6_LOOP
    LOCAL __DRAW_ERROR
    LOCAL DX1, DX2, DY1, DY2

;;__DRAW_ERROR EQU __OUT_OF_SCREEN_ERR
__DRAW_ERROR:
    jp __OUT_OF_SCREEN_ERR
;; __DRAW_ERROR:
;;     ; Sets error code and exits
;; 
;;     ld a, ERROR_OutOfScreen
;;     ld (ERR_NR), a
;;     ret

DRAW:
    ;; ENTRY POINT

    LOCAL PIXEL_ADDR
    LOCAL COORDS

    ex de, hl ; DE = Y OFFSET
    pop hl	; return addr
    ex (sp), hl ; CALLEE => HL = X OFFSET
    ld bc, (COORDS)

    ld a, c
    add a, l
    ld l, a
    ld a, h
    adc a, 0 ; HL = HL + C
    ld h, a
    jr nz, __DRAW_ERROR	; if a <> 0 => Out of Screen

    ld a, b
    add a, e
    ld e, a			
    ld a, d
    adc a, 0 ; DE = DE + B
    ld d, a
    jr nz, __DRAW_ERROR	; if a <> 0 => Out of Screen

    ld a, 191
    sub e
    jr c, __DRAW_ERROR	; Out of screen

    ld h, e			; now H,L = y2, x2

__DRAW:

    ; __FASTCALL__ Entry. Plots from coords to H, L
    push hl
    exx
    pop hl
    exx				; H'L' = y2, x2

    ex de, hl		; D,E = y2, x2;
    ld bc, (COORDS) ; B,C = y1, x1

    ld a, e	
    sub c			; dx = X2 - X1
    ld c, a			; Saves dx in c

    ld l, 1			; xi = 1
    ld a, 0Ch       ; inc c opcode
    jr nc, __DRAW1

    ld a, c
    neg		 		; dx = X1 - X2
    ld c, a
    ld l, -1		; xi = -1
    ld a, 0Dh       ; dec c opcode

__DRAW1:
    ld (DX1), a     ; updates dX (inc/dec)
    ld (DX2), a     ; updated dX (inc/dec)

    ld a, d
    sub b			; A = Y2 - Y1
    ld b, a			; Saves dy in b

    ld h, 1			; yi = 1
    ld a, 04h       ; inc b opcode
    jr nc, __DRAW2

    ld a, b
    neg
    ld b, a
    ld h, -1		; yi = -1
    ld a, 05h       ; dec b opcode

__DRAW2:
    ld (DY1), a     ; updates dY (inc/dec)
    ld (DY2), a     ; updated dY (inc/dec)

    push hl
    exx
    pop de			; D'E' = xi, yi
    exx

    sub c			; dy - dx
    jr c, __DRAW_DX_GT_DY	; DX > DY

    ; At this point DY >= DX
    ; --------------------------
    ; HL = error = dY / 2
    ld h, 0
    ld l, b
    srl l

    ; DE = -dX
    xor a
    sub c
    ld e, a
    sbc a, a
    ld d, a

    ; BC = DY
    ld c, b
    ld b, 0

    exx
    jp __DRAW4_LOOP

__DRAW3:			; While c != e => while y != y2
    exx
    add hl, de		; error -= dX
    bit 7, h		;
    exx				; recover coordinates
    jr z, __DRAW4	; if error < 0 

    exx
    add hl, bc		; error += dY	
    exx

DX1:                ; x += xi
    inc c           ; This will be "poked" with INC/DEC c (+1x -1x)
    
__DRAW4:

DY1:                ; y += yi
    inc b           ; This will be "poked" with INC/DEC b (+1y -1y)

    ;push de
    push hl
    call __PLOT
    pop hl
    ;pop de

__DRAW4_LOOP:
    ld bc, (COORDS)
    ld a, b
    cp h
    jp nz, __DRAW3
    ret	

__DRAW_DX_GT_DY:	; DX > DY
    ; --------------------------
    ; HL = error = dX / 2
    ld h, 0
    ld l, c	
    srl l			; HL = error = DX / 2

    ; DE = -dY
    xor a
    sub b
    ld e, a
    sbc a, a
    ld d, a

    ; BC = dX
    ld b, 0

    exx
    jp __DRAW6_LOOP

__DRAW5:			; While loop
    exx
    add hl, de		; error -= dY
    bit 7, h		; if (error < 0)
    exx				; Restore coords
    jr z, __DRAW6	; 
    exx
    add hl, bc		; error += dX
    exx	

DY2:                ; y += yi
    inc b           ; This will be "poked" with INC/DEC b (+1y -1y)
    
__DRAW6:

DX2:                ; x += xi
    inc c           ; This will be "poked" with INC/DEC c (+1x -1x)

    ;push de
    push hl
    call __PLOT
    pop hl
    ;pop de

__DRAW6_LOOP:
    ld bc, (COORDS)
    ld a, c			; Current X coord
    cp l
    jp nz, __DRAW5
    ret
    
PIXEL_ADDR	EQU 22ACh 
COORDS   EQU 5C7Dh

__DRAW_END:
    exx
    ret



    ENDP

