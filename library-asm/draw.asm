; DRAW using bresenhams algorithm and screen positioning
; Copyleft (k) 2010 by J. Rodriguez (a.k.a. Boriel) http://www.boriel.com
; vim:ts=4:et:sw=4:

; Y parameter in A
; X parameter in high byte on top of the stack

#include once <error.asm>
#include once <in_screen.asm>

#include once <cls.asm>

#include once <SP/PixelDown.asm>
#include once <SP/PixelUp.asm>
#include once <SP/PixelLeft.asm>
#include once <SP/PixelRight.asm>

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
    LOCAL __INCX, __INCY, __DECX, __DECY
    LOCAL P_FLAG
P_FLAG EQU 23697

__DRAW_ERROR:
    jp __OUT_OF_SCREEN_ERR

DRAW:
    ;; ENTRY POINT

    LOCAL PIXEL_ADDR
    LOCAL COORDS
    LOCAL __DRAW_SETUP1, __DRAW_START, __PLOTOVER, __PLOTINVERSE

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
    ; __FASTCALL__ Entry. Plots from (COORDS) to coord H, L
    push hl
    ex de, hl		; D,E = y2, x2;

    ld a, (P_FLAG)
    ld c, a
    bit 2, a        ; Test for INVERSE1
    jr z, __DRAW_SETUP1
    ld a, 2Fh       ; CPL
    ld (__PLOTINVERSE), a
    ld a, 0A6h      ; and (hl)
    jp __DRAW_START

__DRAW_SETUP1:
    xor a           ; nop
    ld (__PLOTINVERSE), a
    ld a, 0B6h      ; or (hl)
    bit 0, c        ; Test for OVER
    jr z, __DRAW_START
    ld a, 0AEh      ; xor (hl)

__DRAW_START:
    ld (__PLOTOVER), a ; "Pokes" last operation
    exx
    ld bc, (COORDS) ; B'C' = y1, x1
    ld d, b         ; Saves B' in D'
    ld a, 191
    LOCAL __PIXEL_ADDR
__PIXEL_ADDR EQU 22ACh
    call __PIXEL_ADDR

    ;; Now gets pixel mask in A register
    ld b, a
    inc b
    xor a
    scf
    LOCAL __PIXEL_MASK
__PIXEL_MASK:
    rra
    djnz __PIXEL_MASK

    ld b, d         ; Restores B' from D'
    pop de			; D'E' = y2, x2
    exx             ; At this point: D'E' = y2,x2 coords
                    ; B'C' = y1, y1  coords
    ex af, af'      ; Saves A reg for later
                    ; A' = Pixel mask
                    ; H'L' = Screen Address of pixel

    ld bc, (COORDS) ; B,C = y1, x1

    ld a, e	
    sub c			; dx = X2 - X1
    ld c, a			; Saves dx in c

    ld a, 0Ch       ; INC C opcode
    ld hl, __INCX   ; xi = 1
    jr nc, __DRAW1

    ld a, c
    neg		 		; dx = X1 - X2
    ld c, a
    ld a, 0Dh       ; DEC C opcode
    ld hl, __DECX   ; xi = -1

__DRAW1:
    ld (DX1), a
    ld (DX1 + 2), hl ; Updates DX1 call address
    ld (DX2), a
    ld (DX2 + 2), hl ; Updates DX2 call address

    ld a, d
    sub b			; dy = Y2 - Y1
    ld b, a			; Saves dy in b

    ld a, 4         ; INC B opcode
    ld hl, __INCY   ; y1 = 1
    jr nc, __DRAW2

    ld a, b
    neg
    ld b, a         ; dy = Y2 - Y1
    ld a, 5         ; DEC B opcode
    ld hl, __DECY   ; y1 = -1

__DRAW2:
    ld (DY1), a
    ld (DY1 + 2), hl ; Updates DX1 call address
    ld (DY2), a
    ld (DY2 + 2), hl ; Updates DX2 call address

    ld a, b
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
    ld b, h

    exx
    scf             ; Sets Carry to signal update ATTR
    ex af, af'      ; Brings back pixel mask
    ld e, a         ; Saves it in free E register
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

    ld a, e
DX1:                ; x += xi
    inc c
    call __INCX     ; This address will be dynamically updated
    ld e, a
    
__DRAW4:

DY1:                ; y += yi
    inc b
    call __INCY     ; This address will be dyncamically updated
    ld a, e         ; Restores A reg.
    call __FASTPLOT

__DRAW4_LOOP:
    ld a, b
    cp d
    jp nz, __DRAW3
    ld (COORDS), bc
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
    ld b, h

    exx
    ld d, e
    scf             ; Sets Carry to signal update ATTR
    ex af, af'      ; Brings back pixel mask
    ld e, a         ; Saves it in free E register
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
    inc b
    call __INCY     ; This address will be dynamically updated
    
__DRAW6:
    ld a, e
DX2:                ; x += xi
    inc c
    call __INCX     ; This address will be dynamically updated
    ld e, a
    call __FASTPLOT

__DRAW6_LOOP:
    ld a, c			; Current X coord
    cp d
    jp nz, __DRAW5
    ld (COORDS), bc
    ret
    
PIXEL_ADDR	EQU 22ACh 
COORDS   EQU 5C7Dh

__DRAW_END:
    exx
    ret

    ;; Given a A mask and an HL screen position
    ;; return the next left position
    ;; Also updates BC coords
__DECX EQU SP.PixelLeft

    ;; Like the above, but to the RIGHT
    ;; Also updates BC coords
__INCX EQU SP.PixelRight

    ;; Given an HL screen position, calculates
    ;; the above position
    ;; Also updates BC coords
__INCY EQU SP.PixelUp

    ;; Given an HL screen position, calculates
    ;; the above position
    ;; Also updates BC coords
__DECY EQU SP.PixelDown

    ;; Puts the A register MASK in (HL)
__FASTPLOT:
__PLOTINVERSE:
    nop         ; Replace with CPL if INVERSE 1
__PLOTOVER:
    or (hl)     ; Replace with XOR (hl) if OVER 1 AND INVERSE 0
                ; Replace with AND (hl) if INVERSE 1

    ld (hl), a
    ex af, af'  ; Recovers flag. If Carry set => update ATTR
    ld a, e     ; Recovers A reg
    ret nc

    push hl
    push de
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
    call PO_ATTR_2   ; This will update attr accordingly. Beware, uses IY

    pop de
    pop hl

    LOCAL __FASTPLOTEND 
__FASTPLOTEND: 
    or a        ; Resets carry flag
    ex af, af'  ; Recovers A reg
    ld a, e
    ret

    ENDP

