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
	ld hl, 11
	push hl
	ld hl, 22
	call DRAW
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	push hl
	ld hl, 22
	call DRAW
	ld hl, 11
	push hl
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	call DRAW
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	push hl
	ld a, (_b)
	ld de, (_b + 1)
	ld bc, (_b + 3)
	call __FTOU32REG
	call DRAW
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
	
#line 46 "draw.bas"
#line 1 "ftou32reg.asm"
#line 1 "neg32.asm"
__ABS32:
		bit 7, d
		ret z
	
__NEG32: ; Negates DEHL (Two's complement)
		ld a, l
		cpl
		ld l, a
	
		ld a, h
		cpl
		ld h, a
	
		ld a, e
		cpl
		ld e, a
		
		ld a, d
		cpl
		ld d, a
	
		inc l
		ret nz
	
		inc h
		ret nz
	
		inc de
		ret
	
#line 2 "ftou32reg.asm"
	
__FTOU32REG:	; Converts a Float to (un)signed 32 bit integer (NOTE: It's ALWAYS 32 bit signed)
					; Input FP number in A EDCB (A exponent, EDCB mantissa)
				; Output: DEHL 32 bit number (signed)
		PROC
	
		LOCAL __IS_FLOAT
	
		or a
		jr nz, __IS_FLOAT 
		; Here if it is a ZX ROM Integer
	
		ld h, c
		ld l, d
	ld a, e	 ; Takes sign: FF = -, 0 = +
		ld de, 0
		inc a
		jp z, __NEG32	; Negates if negative
		ret
	
__IS_FLOAT:  ; Jumps here if it is a true floating point number
		ld h, e	
		push hl  ; Stores it for later (Contains Sign in H)
	
		push de
		push bc
	
		exx
		pop de   ; Loads mantissa into C'B' E'D' 
		pop bc	 ; 
	
		set 7, c ; Highest mantissa bit is always 1
		exx
	
		ld hl, 0 ; DEHL = 0
		ld d, h
		ld e, l
	
		;ld a, c  ; Get exponent
		sub 128  ; Exponent -= 128
		jr z, __FTOU32REG_END	; If it was <= 128, we are done (Integers must be > 128)
		jr c, __FTOU32REG_END	; It was decimal (0.xxx). We are done (return 0)
	
		ld b, a  ; Loop counter = exponent - 128
	
__FTOU32REG_LOOP:
		exx 	 ; Shift C'B' E'D' << 1, output bit stays in Carry
		sla d
		rl e
		rl b
		rl c
	
	    exx		 ; Shift DEHL << 1, inserting the carry on the right
		rl l
		rl h
		rl e
		rl d
	
		djnz __FTOU32REG_LOOP
	
__FTOU32REG_END:
		pop af   ; Take the sign bit
		or a	 ; Sets SGN bit to 1 if negative
		jp m, __NEG32 ; Negates DEHL
		
		ret
	
		ENDP
	
	
__FTOU8:	; Converts float in C ED LH to Unsigned byte in A
		call __FTOU32REG
		ld a, l
		ret
	
#line 47 "draw.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00, 00, 00, 00, 00
_b:
	DEFB 00, 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
