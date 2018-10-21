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
	push hl
	ld a, 086h
	ld de, 00004h
	ld bc, 00000h
	call DRAW3
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	push hl
	ld hl, 22
	push hl
	ld a, 086h
	ld de, 00004h
	ld bc, 00000h
	call DRAW3
	ld hl, 11
	push hl
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	push hl
	ld a, 086h
	ld de, 00004h
	ld bc, 00000h
	call DRAW3
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	push hl
	ld a, (_b)
	ld de, (_b + 1)
	ld bc, (_b + 3)
	call __FTOU32REG
	push hl
	ld a, 086h
	ld de, 00004h
	ld bc, 00000h
	call DRAW3
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	push hl
	ld a, (_b)
	ld de, (_b + 1)
	ld bc, (_b + 3)
	call __FTOU32REG
	push hl
	ld a, (_c)
	ld de, (_c + 1)
	ld bc, (_c + 3)
	call DRAW3
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
#line 1 "draw3.asm"

	; -----------------------------------------------------------
; vim: et:ts=4:sw=4:ruler:
	;
	; DRAW an arc using ZX ROM algorithm.
	; DRAW x, y, r => r = Arc in radians

	; r parameter in A ED BC register
	; X, and Y parameter in high byte on top of the stack

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
	ERROR_NonsenseInBasic   EQU    11
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
#line 11 "draw3.asm"
#line 1 "plot.asm"

	; MIXED __FASTCAL__ / __CALLE__ PLOT Function
	; Plots a point into the screen calling the ZX ROM PLOT routine

	; Y in A (accumulator)
	; X in top of the stack


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
#line 9 "plot.asm"
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
#line 12 "draw3.asm"
#line 1 "stackf.asm"

	; -------------------------------------------------------------
	; Functions to manage FP-Stack of the ZX Spectrum ROM CALC
	; -------------------------------------------------------------


	__FPSTACK_PUSH EQU 2AB6h	; Stores an FP number into the ROM FP stack (A, ED CB)
	__FPSTACK_POP  EQU 2BF1h	; Pops an FP number out of the ROM FP stack (A, ED CB)

__FPSTACK_PUSH2: ; Pushes Current A ED CB registers and top of the stack on (SP + 4)
	                 ; Second argument to push into the stack calculator is popped out of the stack
	                 ; Since the caller routine also receives the parameters into the top of the stack
	                 ; four bytes must be removed from SP before pop them out

	    call __FPSTACK_PUSH ; Pushes A ED CB into the FP-STACK
	    exx
	    pop hl       ; Caller-Caller return addr
	    exx
	    pop hl       ; Caller return addr

	    pop af
	    pop de
	    pop bc

	    push hl      ; Caller return addr
	    exx
	    push hl      ; Caller-Caller return addr
	    exx

	    jp __FPSTACK_PUSH


__FPSTACK_I16:	; Pushes 16 bits integer in HL into the FP ROM STACK
					; This format is specified in the ZX 48K Manual
					; You can push a 16 bit signed integer as
					; 0 SS LL HH 0, being SS the sign and LL HH the low
					; and High byte respectively
		ld a, h
		rla			; sign to Carry
		sbc	a, a	; 0 if positive, FF if negative
		ld e, a
		ld d, l
		ld c, h
		xor a
		ld b, a
		jp __FPSTACK_PUSH
#line 13 "draw3.asm"
#line 1 "draw.asm"

	; DRAW using bresenhams algorithm and screen positioning
; Copyleft (k) 2010 by J. Rodriguez (a.k.a. Boriel) http://www.boriel.com
; vim:ts=4:et:sw=4:

	; Y parameter in A
	; X parameter in high byte on top of the stack






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

#line 14 "draw3.asm"

	; Ripped from the ZX Spectrum ROM

DRAW3:
	        PROC
	        LOCAL STACK_TO_BC
	        LOCAL STACK_TO_A
	        LOCAL COORDS
	        LOCAL L2477
	        LOCAL L2420
	        LOCAL L2439
	        LOCAL L245F
	        LOCAL L23C1
	        LOCAL L2D28
	        LOCAL SUM_C, SUM_B

	L2D28   EQU 02D28h
	COORDS  EQU 5C7Dh
	STACK_TO_BC EQU 2307h
	STACK_TO_A  EQU 2314h

	        exx
	        ex af, af'              ;; Preserves ARC
	        pop hl
	        pop de
	        ex (sp), hl             ;; CALLEE
	        push de
	        call __FPSTACK_I16      ;; X Offset
	        pop hl
	        call __FPSTACK_I16      ;; Y Offset
	        exx
	        ex af, af'
	        call __FPSTACK_PUSH     ;; R Arc

	;   Now enter the calculator and store the complete rotation angle in mem-5

	        RST     28H             ;; FP-CALC      x, y, A.
	        DEFB    $C5             ;;st-mem-5      x, y, A.

	;   Test the angle for the special case of 360 degrees.

	        DEFB    $A2             ;;stk-half      x, y, A, 1/2.
	        DEFB    $04             ;;multiply      x, y, A/2.
	        DEFB    $1F             ;;sin           x, y, sin(A/2).
	        DEFB    $31             ;;duplicate     x, y, sin(A/2),sin(A/2)
	        DEFB    $30             ;;not           x, y, sin(A/2), (0/1).
	        DEFB    $30             ;;not           x, y, sin(A/2), (1/0).
	        DEFB    $00             ;;jump-true     x, y, sin(A/2).

	        DEFB    $06             ;;forward to L23A3, DR-SIN-NZ
	                                ;;if sin(r/2) is not zero.

	;   The third parameter is 2*PI (or a multiple of 2*PI) so a 360 degrees turn
	;   would just be a straight line.  Eliminating this case here prevents
	;   division by zero at later stage.

	        DEFB    $02             ;;delete        x, y.
	        DEFB    $38             ;;end-calc      x, y.
	        JP      L2477

	; ---

	;   An arc can be drawn.

	;; DR-SIN-NZ
	        DEFB    $C0             ;;st-mem-0      x, y, sin(A/2).   store mem-0
	        DEFB    $02             ;;delete        x, y.

	;   The next step calculates (roughly) the diameter of the circle of which the
	;   arc will form part.  This value does not have to be too accurate as it is
	;   only used to evaluate the number of straight lines and then discarded.
	;   After all for a circle, the radius is used. Consequently, a circle of
	;   radius 50 will have 24 straight lines but an arc of radius 50 will have 20
	;   straight lines - when drawn in any direction.
	;   So that simple arithmetic can be used, the length of the chord can be
	;   calculated as X+Y rather than by Pythagoras Theorem and the sine of the
	;   nearest angle within reach is used.

	        DEFB    $C1             ;;st-mem-1      x, y.             store mem-1
	        DEFB    $02             ;;delete        x.

	        DEFB    $31             ;;duplicate     x, x.
	        DEFB    $2A             ;;abs           x, x (+ve).
	        DEFB    $E1             ;;get-mem-1     x, X, y.
	        DEFB    $01             ;;exchange      x, y, X.
	        DEFB    $E1             ;;get-mem-1     x, y, X, y.
	        DEFB    $2A             ;;abs           x, y, X, Y (+ve).
	        DEFB    $0F             ;;addition      x, y, X+Y.
	        DEFB    $E0             ;;get-mem-0     x, y, X+Y, sin(A/2).
	        DEFB    $05             ;;division      x, y, X+Y/sin(A/2).
	        DEFB    $2A             ;;abs           x, y, X+Y/sin(A/2) = D.

	;    Bring back sin(A/2) from mem-0 which will shortly get trashed.
	;    Then bring D to the top of the stack again.

	        DEFB    $E0             ;;get-mem-0     x, y, D, sin(A/2).
	        DEFB    $01             ;;exchange      x, y, sin(A/2), D.

	;   Note. that since the value at the top of the stack has arisen as a result
	;   of division then it can no longer be in integer form and the next re-stack
	;   is unnecessary. Only the Sinclair ZX80 had integer division.

	        ;;DEFB    $3D             ;;re-stack      (unnecessary)

	        DEFB    $38             ;;end-calc      x, y, sin(A/2), D.

	;   The next test avoids drawing 4 straight lines when the start and end pixels
	;   are adjacent (or the same) but is probably best dispensed with.

	        LD      A,(HL)          ; fetch exponent byte of D.
	        CP      $81             ; compare to 1
	        JR      NC,L23C1        ; forward, if > 1,  to DR-PRMS

	;   else delete the top two stack values and draw a simple straight line.

	        RST     28H             ;; FP-CALC
	        DEFB    $02             ;;delete
	        DEFB    $02             ;;delete
	        DEFB    $38             ;;end-calc      x, y.

	        JP      L2477           ; to LINE-DRAW

	; ---

	;   The ARC will consist of multiple straight lines so call the CIRCLE-DRAW
	;   PARAMETERS ROUTINE to pre-calculate sine values from the angle (in mem-5)
	;   and determine also the number of straight lines from that value and the
	;   'diameter' which is at the top of the calculator stack.

	;; DR-PRMS
L23C1:  CALL    247Dh           ; routine CD-PRMS1

	                                ; mem-0 ; (A)/No. of lines (=a) (step angle)
	                                ; mem-1 ; sin(a/2)
	                                ; mem-2 ; -
	                                ; mem-3 ; cos(a)                        const
	                                ; mem-4 ; sin(a)                        const
	                                ; mem-5 ; Angle of rotation (A)         in
	                                ; B     ; Count of straight lines - max 252.

	        PUSH    BC              ; Save the line count on the machine stack.

	;   Remove the now redundant diameter value D.

	        RST     28H             ;; FP-CALC      x, y, sin(A/2), D.
	        DEFB    $02             ;;delete        x, y, sin(A/2).

	;   Dividing the sine of the step angle by the sine of the total angle gives
	;   the length of the initial chord on a unary circle. This factor f is used
	;   to scale the coordinates of the first line which still points in the
	;   direction of the end point and may be larger.

	        DEFB    $E1             ;;get-mem-1     x, y, sin(A/2), sin(a/2)
	        DEFB    $01             ;;exchange      x, y, sin(a/2), sin(A/2)
	        DEFB    $05             ;;division      x, y, sin(a/2)/sin(A/2)
	        DEFB    $C1             ;;st-mem-1      x, y. f.
	        DEFB    $02             ;;delete        x, y.

	;   With the factor stored, scale the x coordinate first.

	        DEFB    $01             ;;exchange      y, x.
	        DEFB    $31             ;;duplicate     y, x, x.
	        DEFB    $E1             ;;get-mem-1     y, x, x, f.
	        DEFB    $04             ;;multiply      y, x, x*f    (=xx)
	        DEFB    $C2             ;;st-mem-2      y, x, xx.
	        DEFB    $02             ;;delete        y. x.

	;   Now scale the y coordinate.

	        DEFB    $01             ;;exchange      x, y.
	        DEFB    $31             ;;duplicate     x, y, y.
	        DEFB    $E1             ;;get-mem-1     x, y, y, f
	        DEFB    $04             ;;multiply      x, y, y*f    (=yy)

	;   Note. 'sin' and 'cos' trash locations mem-0 to mem-2 so fetch mem-2 to the
	;   calculator stack for safe keeping.

	        DEFB    $E2             ;;get-mem-2     x, y, yy, xx.

	;   Once we get the coordinates of the first straight line then the 'ROTATION
	;   FORMULA' used in the arc loop will take care of all other points, but we
	;   now use a variation of that formula to rotate the first arc through (A-a)/2
	;   radians.
	;
	;       xRotated = y * sin(angle) + x * cos(angle)
	;       yRotated = y * cos(angle) - x * sin(angle)
	;

	        DEFB    $E5             ;;get-mem-5     x, y, yy, xx, A.
	        DEFB    $E0             ;;get-mem-0     x, y, yy, xx, A, a.
	        DEFB    $03             ;;subtract      x, y, yy, xx, A-a.
	        DEFB    $A2             ;;stk-half      x, y, yy, xx, A-a, 1/2.
	        DEFB    $04             ;;multiply      x, y, yy, xx, (A-a)/2. (=angle)
	        DEFB    $31             ;;duplicate     x, y, yy, xx, angle, angle.
	        DEFB    $1F             ;;sin           x, y, yy, xx, angle, sin(angle)
	        DEFB    $C5             ;;st-mem-5      x, y, yy, xx, angle, sin(angle)
	        DEFB    $02             ;;delete        x, y, yy, xx, angle

	        DEFB    $20             ;;cos           x, y, yy, xx, cos(angle).

	;   Note. mem-0, mem-1 and mem-2 can be used again now...

	        DEFB    $C0             ;;st-mem-0      x, y, yy, xx, cos(angle).
	        DEFB    $02             ;;delete        x, y, yy, xx.

	        DEFB    $C2             ;;st-mem-2      x, y, yy, xx.
	        DEFB    $02             ;;delete        x, y, yy.

	        DEFB    $C1             ;;st-mem-1      x, y, yy.
	        DEFB    $E5             ;;get-mem-5     x, y, yy, sin(angle)
	        DEFB    $04             ;;multiply      x, y, yy*sin(angle).
	        DEFB    $E0             ;;get-mem-0     x, y, yy*sin(angle), cos(angle)
	        DEFB    $E2             ;;get-mem-2     x, y, yy*sin(angle), cos(angle), xx.
	        DEFB    $04             ;;multiply      x, y, yy*sin(angle), xx*cos(angle).
	        DEFB    $0F             ;;addition      x, y, xRotated.
	        DEFB    $E1             ;;get-mem-1     x, y, xRotated, yy.
	        DEFB    $01             ;;exchange      x, y, yy, xRotated.
	        DEFB    $C1             ;;st-mem-1      x, y, yy, xRotated.
	        DEFB    $02             ;;delete        x, y, yy.

	        DEFB    $E0             ;;get-mem-0     x, y, yy, cos(angle).
	        DEFB    $04             ;;multiply      x, y, yy*cos(angle).
	        DEFB    $E2             ;;get-mem-2     x, y, yy*cos(angle), xx.
	        DEFB    $E5             ;;get-mem-5     x, y, yy*cos(angle), xx, sin(angle).
	        DEFB    $04             ;;multiply      x, y, yy*cos(angle), xx*sin(angle).
	        DEFB    $03             ;;subtract      x, y, yRotated.
	        DEFB    $C2             ;;st-mem-2      x, y, yRotated.

	;   Now the initial x and y coordinates are made positive and summed to see
	;   if they measure up to anything significant.

	        DEFB    $2A             ;;abs           x, y, yRotated'.
	        DEFB    $E1             ;;get-mem-1     x, y, yRotated', xRotated.
	        DEFB    $2A             ;;abs           x, y, yRotated', xRotated'.
	        DEFB    $0F             ;;addition      x, y, yRotated+xRotated.
	        DEFB    $02             ;;delete        x, y.

	        DEFB    $38             ;;end-calc      x, y.

	;   Although the test value has been deleted it is still above the calculator
	;   stack in memory and conveniently DE which points to the first free byte
	;   addresses the exponent of the test value.

	        LD      A,(DE)          ; Fetch exponent of the length indicator.
	        CP      $81             ; Compare to that for 1

	        POP     BC              ; Balance the machine stack

	        JP      C,L2477         ; forward, if the coordinates of first line
	                                ; don't add up to more than 1, to LINE-DRAW

	;   Continue when the arc will have a discernable shape.

	        PUSH    BC              ; Restore line counter to the machine stack.

	;   The parameters of the DRAW command were relative and they are now converted
	;   to absolute coordinates by adding to the coordinates of the last point
	;   plotted. The first two values on the stack are the terminal tx and ty
	;   coordinates.  The x-coordinate is converted first but first the last point
	;   plotted is saved as it will initialize the moving ax, value.

	        RST     28H             ;; FP-CALC      x, y.
	        DEFB    $01             ;;exchange      y, x.
	        DEFB    $38             ;;end-calc      y, x.

	        LD      A,(COORDS)      ;; Fetch System Variable COORDS-x
	        CALL    L2D28           ;; routine STACK-A

	        RST     28H             ;; FP-CALC      y, x, last-x.

	;   Store the last point plotted to initialize the moving ax value.

	        DEFB    $C0             ;;st-mem-0      y, x, last-x.
	        DEFB    $0F             ;;addition      y, absolute x.
	        DEFB    $01             ;;exchange      tx, y.
	        DEFB    $38             ;;end-calc      tx, y.

	        LD      A,(COORDS + 1)  ; Fetch System Variable COORDS-y
	        CALL    L2D28           ; routine STACK-A

	        RST     28H             ;; FP-CALC      tx, y, last-y.

	;   Store the last point plotted to initialize the moving ay value.

	        DEFB    $C5             ;;st-mem-5      tx, y, last-y.
	        DEFB    $0F             ;;addition      tx, ty.

	;   Fetch the moving ax and ay to the calculator stack.

	        DEFB    $E0             ;;get-mem-0     tx, ty, ax.
	        DEFB    $E5             ;;get-mem-5     tx, ty, ax, ay.
	        DEFB    $38             ;;end-calc      tx, ty, ax, ay.

	        POP     BC              ; Restore the straight line count.

	; -----------------------------------
	; THE 'CIRCLE/DRAW CONVERGENCE POINT'
	; -----------------------------------
	;   The CIRCLE and ARC-DRAW commands converge here.
	;
	;   Note. for both the CIRCLE and ARC commands the minimum initial line count
	;   is 4 (as set up by the CD_PARAMS routine) and so the zero flag will never
	;   be set and the loop is always entered.  The first test is superfluous and
	;   the jump will always be made to ARC-START.

	;; DRW-STEPS
L2420:  DEC     B               ; decrement the arc count (4,8,12,16...).

	        ;JR      Z,L245F         ; forward, if zero (not possible), to ARC-END

	        JP      L2439           ; forward to ARC-START

	; --------------
	; THE 'ARC LOOP'
	; --------------
	;
	;   The arc drawing loop will draw up to 31 straight lines for a circle and up
	;   251 straight lines for an arc between two points. In both cases the final
	;   closing straight line is drawn at ARC_END, but it otherwise loops back to
	;   here to calculate the next coordinate using the ROTATION FORMULA where (a)
	;   is the previously calculated, constant CENTRAL ANGLE of the arcs.
	;
	;       Xrotated = x * cos(a) - y * sin(a)
	;       Yrotated = x * sin(a) + y * cos(a)
	;
	;   The values cos(a) and sin(a) are pre-calculated and held in mem-3 and mem-4
	;   for the duration of the routine.
	;   Memory location mem-1 holds the last relative x value (rx) and mem-2 holds
	;   the last relative y value (ry) used by DRAW.
	;
	;   Note. that this is a very clever twist on what is after all a very clever,
	;   well-used formula.  Normally the rotation formula is used with the x and y
	;   coordinates from the centre of the circle (or arc) and a supplied angle to
	;   produce two new x and y coordinates in an anticlockwise direction on the
	;   circumference of the circle.
	;   What is being used here, instead, is the relative X and Y parameters from
	;   the last point plotted that are required to get to the current point and
	;   the formula returns the next relative coordinates to use.

	;; ARC-LOOP
L2425:  RST     28H             ;; FP-CALC
	        DEFB    $E1             ;;get-mem-1     rx.
	        DEFB    $31             ;;duplicate     rx, rx.
	        DEFB    $E3             ;;get-mem-3     cos(a)
	        DEFB    $04             ;;multiply      rx, rx*cos(a).
	        DEFB    $E2             ;;get-mem-2     rx, rx*cos(a), ry.
	        DEFB    $E4             ;;get-mem-4     rx, rx*cos(a), ry, sin(a).
	        DEFB    $04             ;;multiply      rx, rx*cos(a), ry*sin(a).
	        DEFB    $03             ;;subtract      rx, rx*cos(a) - ry*sin(a)
	        DEFB    $C1             ;;st-mem-1      rx, new relative x rotated.
	        DEFB    $02             ;;delete        rx.

	        DEFB    $E4             ;;get-mem-4     rx, sin(a).
	        DEFB    $04             ;;multiply      rx*sin(a)
	        DEFB    $E2             ;;get-mem-2     rx*sin(a), ry.
	        DEFB    $E3             ;;get-mem-3     rx*sin(a), ry, cos(a).
	        DEFB    $04             ;;multiply      rx*sin(a), ry*cos(a).
	        DEFB    $0F             ;;addition      rx*sin(a) + ry*cos(a).
	        DEFB    $C2             ;;st-mem-2      new relative y rotated.
	        DEFB    $02             ;;delete        .
	        DEFB    $38             ;;end-calc      .

	;   Note. the calculator stack actually holds   tx, ty, ax, ay
	;   and the last absolute values of x and y
	;   are now brought into play.
	;
	;   Magically, the two new rotated coordinates rx and ry are all that we would
	;   require to draw a circle or arc - on paper!
	;   The Spectrum DRAW routine draws to the rounded x and y coordinate and so
	;   repetitions of values like 3.49 would mean that the fractional parts
	;   would be lost until eventually the draw coordinates might differ from the
	;   floating point values used above by several pixels.
	;   For this reason the accurate offsets calculated above are added to the
	;   accurate, absolute coordinates maintained in ax and ay and these new
	;   coordinates have the integer coordinates of the last plot position
	;   ( from System Variable COORDS ) subtracted from them to give the relative
	;   coordinates required by the DRAW routine.

	;   The mid entry point.

	;; ARC-START
L2439:  PUSH    BC              ; Preserve the arc counter on the machine stack.

	;   Store the absolute ay in temporary variable mem-0 for the moment.

	        RST     28H             ;; FP-CALC      ax, ay.
	        DEFB    $C0             ;;st-mem-0      ax, ay.
	        DEFB    $02             ;;delete        ax.

	;   Now add the fractional relative x coordinate to the fractional absolute
	;   x coordinate to obtain a new fractional x-coordinate.

	        DEFB    $E1             ;;get-mem-1     ax, xr.
	        DEFB    $0F             ;;addition      ax+xr (= new ax).
	        DEFB    $31             ;;duplicate     ax, ax.
	        DEFB    $38             ;;end-calc      ax, ax.

	        LD      A,(COORDS)       ; COORDS-x      last x    (integer ix 0-255)
	        CALL    L2D28           ; routine STACK-A

	        RST     28H             ;; FP-CALC      ax, ax, ix.
	        DEFB    $03             ;;subtract      ax, ax-ix  = relative DRAW Dx.

	;   Having calculated the x value for DRAW do the same for the y value.

	        DEFB    $E0             ;;get-mem-0     ax, Dx, ay.
	        DEFB    $E2             ;;get-mem-2     ax, Dx, ay, ry.
	        DEFB    $0F             ;;addition      ax, Dx, ay+ry (= new ay).
	        DEFB    $C0             ;;st-mem-0      ax, Dx, ay.
	        DEFB    $01             ;;exchange      ax, ay, Dx,
	        DEFB    $E0             ;;get-mem-0     ax, ay, Dx, ay.
	        DEFB    $38             ;;end-calc      ax, ay, Dx, ay.

	        LD      A,(COORDS + 1)  ; COORDS-y      last y (integer iy 0-175)
	        CALL    L2D28           ; routine STACK-A

	        RST     28H             ;; FP-CALC      ax, ay, Dx, ay, iy.
	        DEFB    $03             ;;subtract      ax, ay, Dx, ay-iy ( = Dy).
	        DEFB    $38             ;;end-calc      ax, ay, Dx, Dy.

	        CALL    L2477           ; Routine DRAW-LINE draws (Dx,Dy) relative to
	                                ; the last pixel plotted leaving absolute x
	                                ; and y on the calculator stack.
	                                ;               ax, ay.

	        POP     BC              ; Restore the arc counter from the machine stack.

	        DJNZ    L2425           ; Decrement and loop while > 0 to ARC-LOOP

	; -------------
	; THE 'ARC END'
	; -------------

	;   To recap the full calculator stack is       tx, ty, ax, ay.

	;   Just as one would do if drawing the curve on paper, the final line would
	;   be drawn by joining the last point plotted to the initial start point
	;   in the case of a CIRCLE or to the calculated end point in the case of
	;   an ARC.
	;   The moving absolute values of x and y are no longer required and they
	;   can be deleted to expose the closing coordinates.

	;; ARC-END
L245F:  RST     28H             ;; FP-CALC      tx, ty, ax, ay.
	        DEFB    $02             ;;delete        tx, ty, ax.
	        DEFB    $02             ;;delete        tx, ty.
	        DEFB    $01             ;;exchange      ty, tx.
	        DEFB    $38             ;;end-calc      ty, tx.

	;   First calculate the relative x coordinate to the end-point.

	        LD      A,($5C7D)       ; COORDS-x
	        CALL    L2D28           ; routine STACK-A

	        RST     28H             ;; FP-CALC      ty, tx, coords_x.
	        DEFB    $03             ;;subtract      ty, rx.

	;   Next calculate the relative y coordinate to the end-point.

	        DEFB    $01             ;;exchange      rx, ty.
	        DEFB    $38             ;;end-calc      rx, ty.

	        LD      A,($5C7E)       ; COORDS-y
	        CALL    L2D28           ; routine STACK-A

	        RST     28H             ;; FP-CALC      rx, ty, coords_y
	        DEFB    $03             ;;subtract      rx, ry.
	        DEFB    $38             ;;end-calc      rx, ry.
	;   Finally draw the last straight line.
L2477:
	        call    STACK_TO_BC     ;;Pops x, and y, and stores it in B, C
	        ld      hl, (COORDS)    ;;Calculates x2 and y2 in L, H

	        rl      e               ;; Rotate left to carry
	        ld      a, c
	        jr      nc, SUM_C
	        neg
SUM_C:
	        add     a, l
	        ld      l, a            ;; X2

	        rl      d               ;; Low sign to carry
	        ld      a, b
	        jr      nc, SUM_B
	        neg
SUM_B:
	        add     a, h
	        ld      h, a
	        jp      __DRAW          ;;forward to LINE-DRAW (Fastcalled)

	        ENDP
#line 76 "draw3.bas"
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
		LOCAL __NEGATE

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
		jp m, __NEGATE ; Negates DEHL

		ret

__NEGATE:
	    exx
	    ld a, d
	    or e
	    or b
	    or c
	    exx
	    jr z, __END
	    inc l
	    jr nz, __END
	    inc h
	    jr nz, __END
	    inc de
	LOCAL __END
__END:
	    jp __NEG32
		ENDP


__FTOU8:	; Converts float in C ED LH to Unsigned byte in A
		call __FTOU32REG
		ld a, l
		ret

#line 77 "draw3.bas"

ZXBASIC_USER_DATA:
_a:
	DEFB 00, 00, 00, 00, 00
_b:
	DEFB 00, 00, 00, 00, 00
_c:
	DEFB 00, 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
