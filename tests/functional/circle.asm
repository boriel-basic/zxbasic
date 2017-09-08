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
	ld a, 11
	push af
	ld a, 22
	push af
	ld a, 33
	call CIRCLE
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	ld a, l
	push af
	ld a, 22
	push af
	ld a, 33
	call CIRCLE
	ld a, 11
	push af
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	ld a, l
	push af
	ld a, 33
	call CIRCLE
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	ld a, l
	push af
	ld a, (_b)
	ld de, (_b + 1)
	ld bc, (_b + 3)
	call __FTOU32REG
	ld a, l
	push af
	ld a, 33
	call CIRCLE
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __FTOU32REG
	ld a, l
	push af
	ld a, (_b)
	ld de, (_b + 1)
	ld bc, (_b + 3)
	call __FTOU32REG
	ld a, l
	push af
	ld a, (_c)
	ld de, (_c + 1)
	ld bc, (_c + 3)
	call __FTOU32REG
	ld a, l
	call CIRCLE
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
#line 1 "circle.asm"
	
	; Bresenham's like circle algorithm
	; best known as Middle Point Circle drawing algorithm
	
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
#line 5 "circle.asm"
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
#line 6 "circle.asm"
	
	
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
#line 76 "circle.bas"
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
	
#line 77 "circle.bas"
	
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
