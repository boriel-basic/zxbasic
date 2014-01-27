	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	ld a, 2
	call INK_TMP
	ld hl, 255
	push hl
	ld hl, 175
	call DRAW
	call COPY_ATTR
	ld a, 7
	call PAPER_TMP
	ld a, 127
	push af
	ld a, 128
	call PLOT
	call COPY_ATTR
	ld a, 1
	call FLASH_TMP
	ld a, 1
	call OVER_TMP
	ld a, 127
	push af
	ld a, 87
	push af
	ld a, 60
	call CIRCLE
	call COPY_ATTR
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
#line 1 "draw.asm"
	; DRAW using bresenhams algorithm and screen positioning
; Copyleft (k) 2010 by J. Rodriguez (a.k.a. Boriel) http://www.boriel.com
; vim:ts=4:et:sw=4:
	
	; Y parameter in A
	; X parameter in high byte on top of the stack
	
#line 1 "error.asm"
	; Simple error control routines
; vim:ts=4:et:
	
	ERR_NR    EQU    23610    ; Error code system variable
	
	
	; Error code definitions (as in ZX spectrum manual)
	
; Set error code with:
	;    ld a, ERROR_CODE
	;    ld (ERR_NR), a
	
	
	ERROR_Ok                EQU    -1
	ERROR_SubscriptWrong    EQU     2
	ERROR_OutOfMemory       EQU     3
	ERROR_OutOfScreen       EQU     4
	ERROR_NumberTooBig      EQU     5
	ERROR_InvalidArg        EQU     9
	ERROR_IntOutOfRange     EQU    10
	ERROR_InvalidFileName   EQU    14 
	ERROR_InvalidColour     EQU    19
	ERROR_BreakIntoProgram  EQU    20
	ERROR_TapeLoadingErr    EQU    26
	
	
	; Raises error using RST #8
__ERROR:
	    ld (__ERROR_CODE), a
	    rst 8
__ERROR_CODE:
	    nop
	    ret
	
	; Sets the error system variable, but keeps running.
	; Usually this instruction if followed by the END intermediate instruction.
__STOP:
	    ld (ERR_NR), a
	    ret
#line 9 "draw.asm"
#line 1 "in_screen.asm"
#line 1 "sposn.asm"
	; Printing positioning library.
			PROC
			LOCAL ECHO_E 
	
__LOAD_S_POSN:		; Loads into DE current ROW, COL print position from S_POSN mem var.
			ld de, (S_POSN)
			ld hl, (MAXX)
			or a
			sbc hl, de
			ex de, hl
			ret
		
	
__SAVE_S_POSN:		; Saves ROW, COL from DE into S_POSN mem var.
			ld hl, (MAXX)
			or a
			sbc hl, de
			ld (S_POSN), hl ; saves it again
			ret
	
	
	ECHO_E	EQU 23682
	MAXX	EQU ECHO_E   ; Max X position + 1
	MAXY	EQU MAXX + 1 ; Max Y position + 1
	
	S_POSN	EQU 23688 
	POSX	EQU S_POSN		; Current POS X
	POSY	EQU S_POSN + 1	; Current POS Y
	
			ENDP
	
#line 2 "in_screen.asm"
	
	
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
#line 10 "draw.asm"
#line 1 "plot.asm"
	; MIXED __FASTCAL__ / __CALLE__ PLOT Function
	; Plots a point into the screen calling the ZX ROM PLOT routine
	
	; Y in A (accumulator)
	; X in top of the stack
	
	
	
#line 1 "cls.asm"
	; JUMPS directly to spectrum CLS
	; This routine does not clear lower screen
	
	;CLS	EQU	0DAFh
	
	; Our faster implementation
	
	
	
CLS:
		PROC
	
		LOCAL COORDS
		LOCAL __CLS_SCR
		LOCAL ATTR_P
		LOCAL SCREEN
	
		ld hl, 0
		ld (COORDS), hl
	    ld hl, 1821h
		ld (S_POSN), hl
__CLS_SCR:
		ld hl, SCREEN
		ld (hl), 0
		ld d, h
		ld e, l
		inc de
		ld bc, 6144
		ldir
	
		; Now clear attributes
	
		ld a, (ATTR_P)
		ld (hl), a
		ld bc, 767
		ldir
		ret
	
	COORDS	EQU	23677
	SCREEN	EQU 16384 ; Default start of the screen (can be changed)
	ATTR_P	EQU 23693
	;you can poke (SCREEN_SCRADDR) to change CLS, DRAW & PRINTing address
	
	SCREEN_ADDR EQU (__CLS_SCR + 1) ; Address used by print and other screen routines
								    ; to get the start of the screen
		ENDP
	
#line 10 "plot.asm"
	
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
#line 11 "draw.asm"
	
	
#line 1 "PixelDown.asm"
	;
	; PixelDown
	; Alvin Albrecht 2002
	;
	
	; Pixel Down
	;
	; Adjusts screen address HL to move one pixel down in the display.
	; (0,0) is located at the top left corner of the screen.
	;
; enter: HL = valid screen address
; exit : Carry = moved off screen
	;        Carry'= moved off current cell (needs ATTR update)
	;        HL = moves one pixel down
; used : AF, HL
	
SP.PixelDown:
	   inc h
	   ld a,h
	   and $07
	   ret nz
	   ex af, af'  ; Sets carry on F'
	   scf         ; which flags ATTR must be updated
	   ex af, af'      
	   ld a,h
	   sub $08
	   ld h,a
	   ld a,l
	   add a,$20
	   ld l,a
	   ret nc
	   ld a,h
	   add a,$08
	   ld h,a
	;IF DISP_HIRES
	;   and $18
	;   cp $18
	;ELSE
	   cp $58
	;ENDIF
	   ccf
	   ret
#line 14 "draw.asm"
#line 1 "PixelUp.asm"
	;
	; PixelUp
	; Alvin Albrecht 2002
	;
	
	; Pixel Up
	;
	; Adjusts screen address HL to move one pixel up in the display.
	; (0,0) is located at the top left corner of the screen.
	;
; enter: HL = valid screen address
; exit : Carry = moved off screen
	;        HL = moves one pixel up
; used : AF, HL
	
SP.PixelUp:
	   ld a,h
	   dec h
	   and $07
	   ret nz
	   ex af, af'
	   scf
	   ex af, af'
	   ld a,$08
	   add a,h
	   ld h,a
	   ld a,l
	   sub $20
	   ld l,a
	   ret nc
	   ld a,h
	   sub $08
	   ld h,a
	;IF DISP_HIRES
	;   and $18
	;   cp $18
	;   ccf
	;ELSE
	   cp $40
	;ENDIF
	   ret
#line 15 "draw.asm"
#line 1 "PixelLeft.asm"
	;
	; PixelLeft
	; Jose Rodriguez 2012
	;
	
	; PixelLeft
	;
	; Adjusts screen address HL and Pixel bit A to move one pixel to the left
	; on the display.  Start of line set Carry (Out of Screen)
	;
; enter: HL = valid screen address
	;        A = Bit Set
; exit : Carry = moved off screen
	;        Carry' Set if moved off current ATTR CELL
	;        HL = moves one character left, if needed
	;        A = Bit Set with new pixel pos.
; used : AF, HL
	
	
SP.PixelLeft:
	    rlca    ; Sets new pixel bit 1 to the right
	    ret nc
	    ex af, af' ; Signal in C' we've moved off current ATTR cell
	    ld a,l
	    dec a
	    ld l,a
	    cp 32      ; Carry if in screen
	    ccf
	    ld a, 1
	    ret
	
#line 16 "draw.asm"
#line 1 "PixelRight.asm"
	;
	; PixelRight
	; Jose Rodriguez 2012
	;
	
	
	; PixelRight
	;
	; Adjusts screen address HL and Pixel bit A to move one pixel to the left
	; on the display.  Start of line set Carry (Out of Screen)
	;
; enter: HL = valid screen address
	;        A = Bit Set
; exit : Carry = moved off screen
	;        Carry' Set if moved off current ATTR CELL
	;        HL = moves one character left, if needed
	;        A = Bit Set with new pixel pos.
; used : AF, HL
	
	
SP.PixelRight:
	    rrca    ; Sets new pixel bit 1 to the right
	    ret nc
	    ex af, af' ; Signal in C' we've moved off current ATTR cell
	    ld a, l
	    inc a
	    ld l, a
	    cp 32      ; Carry if IN screen
	    ccf
	    ld a, 80h
	    ret
	
#line 17 "draw.asm"
	
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
	
#line 43 "inktemp.bas"
#line 1 "ink.asm"
	; Sets ink color in ATTR_P permanently
; Parameter: Paper color in A register
	
#line 1 "const.asm"
	; Global constants
	
	P_FLAG	EQU 23697
	FLAGS2	EQU 23681
	ATTR_P	EQU 23693	; permanet ATTRIBUTES
	ATTR_T	EQU 23695	; temporary ATTRIBUTES
	CHARS	EQU 23606 ; Pointer to ROM/RAM Charset
	UDG	EQU 23675 ; Pointer to UDG Charset
	MEM0	EQU 5C92h ; Temporary memory buffer used by ROM chars
	
#line 5 "ink.asm"
	
INK:
		PROC
		LOCAL __SET_INK
		LOCAL __SET_INK2
	
		ld de, ATTR_P
	
__SET_INK:
		cp 8
		jr nz, __SET_INK2
	
		inc de ; Points DE to MASK_T or MASK_P
		ld a, (de)
		or 7 ; Set bits 0,1,2 to enable transparency
		ld (de), a
		ret
	
__SET_INK2:
		; Another entry. This will set the ink color at location pointer by DE
		and 7	; # Gets color mod 8
		ld b, a	; Saves the color
		ld a, (de)
		and 0F8h ; Clears previous value
		or b
		ld (de), a
		inc de ; Points DE to MASK_T or MASK_P
		ld a, (de)
		and 0F8h ; Reset bits 0,1,2 sign to disable transparency
		ld (de), a ; Store new attr
		ret
	
	; Sets the INK color passed in A register in the ATTR_T variable
INK_TMP:
		ld de, ATTR_T
		jp __SET_INK
	
		ENDP
	
#line 44 "inktemp.bas"
#line 1 "paper.asm"
	; Sets paper color in ATTR_P permanently
; Parameter: Paper color in A register
	
	
	
PAPER:
		PROC
		LOCAL __SET_PAPER
		LOCAL __SET_PAPER2
		
		ld de, ATTR_P
	
__SET_PAPER:
		cp 8	
		jr nz, __SET_PAPER2
		inc de
		ld a, (de)
		or 038h
		ld (de), a
		ret
	
		; Another entry. This will set the paper color at location pointer by DE
__SET_PAPER2:
		and 7	; # Remove 
		rlca
		rlca
		rlca		; a *= 8
	
		ld b, a	; Saves the color
		ld a, (de)
		and 0C7h ; Clears previous value
		or b
		ld (de), a
		inc de ; Points to MASK_T or MASK_P accordingly
		ld a, (de)
		and 0C7h  ; Resets bits 3,4,5
		ld (de), a
		ret
	
	
	; Sets the PAPER color passed in A register in the ATTR_T variable
PAPER_TMP:
		ld de, ATTR_T
		jp __SET_PAPER
		ENDP
	
#line 45 "inktemp.bas"
#line 1 "over.asm"
	; Sets OVER flag in P_FLAG permanently
; Parameter: OVER flag in bit 0 of A register
#line 1 "copy_attr.asm"
#line 4 "/Users/boriel/Documents/src/zxb/trunk/library-asm/copy_attr.asm"
	
	
	
COPY_ATTR:
		; Just copies current permanent attribs to temporal attribs
		; and sets print mode 
		PROC
	
		LOCAL INVERSE1
		LOCAL __REFRESH_TMP
	
	INVERSE1 EQU 02Fh
	
		ld hl, (ATTR_P)
		ld (ATTR_T), hl
	
		ld hl, FLAGS2
		call __REFRESH_TMP
		
		ld hl, P_FLAG
		call __REFRESH_TMP
	
	
__SET_ATTR_MODE:		; Another entry to set print modes. A contains (P_FLAG)
	
#line 63 "/Users/boriel/Documents/src/zxb/trunk/library-asm/copy_attr.asm"
		ret
#line 65 "/Users/boriel/Documents/src/zxb/trunk/library-asm/copy_attr.asm"
	
__REFRESH_TMP:
		ld a, (hl)
		and 10101010b
		ld c, a
		rra
		or c
		ld (hl), a
		ret
	
		ENDP
	
#line 4 "over.asm"
	
	
OVER:
		PROC
	
		ld c, a ; saves it for later
		and 2
		ld hl, FLAGS2
		res 1, (HL)
		or (hl)
		ld (hl), a
	
		ld a, c	; Recovers previous value
		and 1	; # Convert to 0/1
		add a, a; # Shift left 1 bit for permanent
	
		ld hl, P_FLAG
		res 1, (hl)
		or (hl)
		ld (hl), a
		ret
	
	; Sets OVER flag in P_FLAG temporarily
OVER_TMP:
		ld c, a ; saves it for later
		and 2	; gets bit 1; clears carry
		rra
		ld hl, FLAGS2
		res 0, (hl)
		or (hl)
		ld (hl), a
	
		ld a, c	; Recovers previous value
		and 1
		ld hl, P_FLAG
		res 0, (hl)
	    or (hl)
		ld (hl), a
		jp __SET_ATTR_MODE
	
		ENDP
	
#line 46 "inktemp.bas"
#line 1 "flash.asm"
	; Sets flash flag in ATTR_P permanently
; Parameter: Paper color in A register
	
	
	
FLASH:
		ld de, ATTR_P
__SET_FLASH:
		; Another entry. This will set the flash flag at location pointer by DE
		and 1	; # Convert to 0/1
	
		rrca
		ld b, a	; Saves the color
		ld a, (de)
		and 07Fh ; Clears previous value
		or b
		ld (de), a
		ret
	
	
	; Sets the FLASH flag passed in A register in the ATTR_T variable
FLASH_TMP:
		ld de, ATTR_T
		jr __SET_FLASH
	
#line 47 "inktemp.bas"
	
	
#line 1 "circle.asm"
	; Bresenham's like circle algorithm
	; best known as Middle Point Circle drawing algorithm
	
	
	
	
	
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
#line 50 "inktemp.bas"
	
ZXBASIC_USER_DATA:
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
