	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (.core.__CALL_BACK__), hl
	ei
	call .core.__MEM_INIT
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines HEAP SIZE
.core.ZXBASIC_HEAP_SIZE EQU 4768
.core.ZXBASIC_MEM_HEAP:
	DEFS 4768
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
.LABEL._10:
	call .core.CLS
.LABEL._20:
	ld a, 128
	push af
	ld a, 87
	push af
	ld a, 87
	call .core.CIRCLE
.LABEL._30:
	ld hl, .LABEL.__LABEL0
	xor a
	call .core.USR_STR
	push hl
	ld a, 87
	push af
	ld a, 128
	call _SPFill
.LABEL._40:
	ld hl, 0
	call .core.__PAUSE
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
_SPFill:
#line 11 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
		push namespace core
		PROC
		LOCAL SPPFill
		LOCAL SPPFill_start
		LOCAL SPPFill_end
		POP BC
		POP HL
		POP DE
		LD L,A
		PUSH BC
		push ix
		call SPPFill_start
		pop ix
		ret
SPPFill_IXBuffer:
		DEFB 0,0
SPPFill_start:
		LD BC,300
		LD (SPPFill_IXBuffer),IX
SPPFill:
		push de
		dec bc
		push bc
		ld a,h
		call SPGetScrnAddr
		ex de,hl
		call bytefill
		jr c, viable
		pop bc
		pop de
		jp SPPFill_end
		LOCAL viable
viable:
		ex de,hl
		ld hl,-7
		add hl,sp
		push hl
		push hl
		pop ix
		dec hl
		dec hl
		dec hl
		push hl
		ld hl,-12
		add hl,sp
		push hl
		xor a
		push af
		dec sp
		push de
		push bc
		inc sp
		push af
		dec sp
		ld c,(ix+7)
		ld b,(ix+8)
		inc bc
		ld l,c
		ld h,b
		add hl,bc
		add hl,bc
		ld c,l
		ld b,h
		ld hl,0
		sbc hl,bc
		add hl,sp
		ld (hl),0
		ld sp,hl
		ld a,$80
		push af
		inc sp
		ld e,l
		ld d,h
		inc de
		dec bc
		ldir
		LOCAL pfloop
pfloop:
		ld l,(ix+3)
		ld h,(ix+4)
		ld e,(ix+1)
		ld d,(ix+2)
		call investigate
		ld (ix+1),e
		ld (ix+2),d
		ld (ix+3),l
		ld (ix+4),h
		ld l,(ix+5)
		ld h,(ix+6)
		ld c,(ix+7)
		ld b,(ix+8)
		call applypattern
		ld (ix+7),c
		ld (ix+8),b
		ld (ix+5),l
		ld (ix+6),h
		ld a,(hl)
		cp 40h
		jp nc, pfloop
		LOCAL endpfill
endpfill:
		ld de,11
		add ix,de
		ld sp,ix
		or a
		ret
		LOCAL investigate
investigate:
		ld a,(hl)
		cp 80h
		jp c, inowrap
		push ix
		pop hl
		ld a,(hl)
		LOCAL inowrap
inowrap:
		cp 40h
		jp c, endinv
		ld b,a
		dec hl
		ld c,(hl)
		dec hl
		ld a,(hl)
		dec hl
		push hl
		ld l,c
		ld h,b
		ld b,a
		LOCAL goup
goup:
		push hl
		call SP.PixelUp
		jr c, updeadend
		push bc
		call bytefill
		call c, addnew
		pop bc
		LOCAL updeadend
updeadend:
		pop hl
		LOCAL godown
godown:
		push hl
		call SP.PixelDown
		jr c, downdeadend
		push bc
		call bytefill
		call c, addnew
		pop bc
		LOCAL downdeadend
downdeadend:
		pop hl
		LOCAL goleft
goleft:
		bit 7,b
		jr z, goright
		ld a,l
		and 31
		jr nz, okleft
		bit 5,h
		jr z, goright
		LOCAL okleft
okleft:
		push hl
		call SP.CharLeft
		push bc
		ld b,01h
		call bytefill
		call c, addnew
		pop bc
		pop hl
		LOCAL goright
goright:
		bit 0,b
		jr z, nextinv
		or a
		call SP.CharRight
		jr c, nextinv
		ld a,l
		and 31
		jr z, nextinv
		ld b,80h
		call bytefill
		call c, addnew
		LOCAL nextinv
nextinv:
		pop hl
		jp investigate
		LOCAL endinv
endinv:
		dec hl
		dec hl
		dec hl
		ld a,(de)
		cp 80h
		jr c, nowrapnew
		defb $dd
		ld e,l
		defb $dd
		ld d,h
		LOCAL nowrapnew
nowrapnew:
		xor a
		ld (de),a
		dec de
		dec de
		dec de
		ret
		LOCAL bytefill
bytefill:
		ld a,b
		xor (hl)
		and b
		ret z
		LOCAL bfloop
bfloop:
		ld b,a
		rra
		ld c,a
		ld a,b
		add a,a
		or c
		or b
		ld c,a
		xor (hl)
		and c
		cp b
		jp nz, bfloop
		or (hl)
		ld (hl),a
		scf
		ret
		LOCAL addnew
addnew:
		push hl
		ld l,(ix+7)
		ld h,(ix+8)
		ld a,h
		or l
		jr z, bail
		dec hl
		ld (ix+7),l
		ld (ix+8),h
		pop hl
		ld a,(de)
		cp 80h
		jr c, annowrap
		defb $dd
		ld e,l
		defb $dd
		ld d,h
		LOCAL annowrap
annowrap:
		ex de,hl
		ld (hl),d
		dec hl
		ld (hl),e
		dec hl
		ld (hl),b
		dec hl
		ex de,hl
		ret
		LOCAL bail
bail:
		pop hl
		ld a,b
		xor (hl)
		ld (hl),a
		xor a
		ld (de),a
		ld l,(ix+5)
		ld h,(ix+6)
		call applypattern
		call applypattern
		call applypattern
		ld de,11
		add ix,de
		ld sp,ix
		scf
		jp SPPFill_end
		LOCAL applypattern
applypattern:
		ld a,(hl)
		cp 80h
		jp c, apnowrap
		push ix
		pop hl
		ld a,(hl)
		LOCAL apnowrap
apnowrap:
		cp 40h
		jr c, endapply
		and 07h
		add a,(ix+9)
		ld e,a
		ld a,0
		adc a,(ix+10)
		ld d,a
		ld a,(de)
		ld d,(hl)
		dec hl
		ld e,(hl)
		dec hl
		and (hl)
		sub (hl)
		dec a
		ex de,hl
		and (hl)
		ld (hl),a
		ex de,hl
		dec hl
		inc bc
		jp applypattern
		LOCAL endapply
endapply:
		dec hl
		dec hl
		dec hl
		ret
SPPFill_end:
		LD IX,(SPPFill_IXBuffer)
		ENDP
		pop namespace
#line 542 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
_SPFill__leave:
	ret
.LABEL.__LABEL0:
	DEFW 0001h
	DEFB 61h
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/SP/CharLeft.asm"
	;
	; CharLeft
	; Alvin Albrecht 2002
	;
	;INCLUDE "SPconfig.def"
	;XLIB SPCharLeft
	; Char Left
	;
	; Adjusts screen address HL to move one character to the left
	; on the display.  Start of line wraps to the previous row.
	;
; enter: HL = valid screen address
	;        Carry reset
; exit : Carry = moved off screen
	;        HL = moves one character left, with line wrap
; used : AF, HL
	;IF !DISP_HIRES
	    push namespace core
SP.CharLeft:
	    ld a,l
	    dec l
	    or a
	    ret nz
	    ld a,h
	    sub $08
	    ld h,a
	    cp $40
	    ret
	    pop namespace
	;ELSE
	;.SPCharLeft
	;   ld a,h
	;   xor $20
	;   ld h,a
	;   cp $58
	;   ccf
	;   ret nc
	;   ld a,l
	;   dec l
	;   or a
	;   ret nz
	;   ld a,h
	;   sub $08
	;   ld h,a
	;   and $18
	;   cp $18
	;   ccf
	;   ret
	; ENDIF
#line 550 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/SP/CharRight.asm"
	;
	; CharRight
	; Alvin Albrecht 2002
	;
	;INCLUDE "SPconfig.def"
	;XLIB SPCharRight
	; Char Right
	;
	; Adjusts screen address HL to move one character to the right
	; on the display.  End of line wraps to the next row.
	;
; enter: HL = valid screen address
	;        Carry reset
; exit : Carry = moved off screen
	;        HL = moves one character right, with line wrap
; used : AF, HL
	;IF !DISP_HIRES
	    push namespace core
SP.CharRight:
	    inc l
	    ret nz
	    ld a,8
	    add a,h
	    ld h,a
	    cp $58
	    ccf
	    ret
	    pop namespace
	;ELSE
	;.SPCharRight
	;   ld a,h
	;   xor $20
	;   ld h,a
	;   cp $58
	;   ret nc
	;   inc l
	;   ret nz
	;   ld a,8
	;   add a,h
	;   ld h,a
	;   cp $58
	;   ccf
	;   ret
	; ENDIF
#line 551 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/SP/GetScrnAddr.asm"
	;
	; GetScrnAddr
	; Alvin Albrecht 2002
	;
	;INCLUDE "SPconfig.def"
	;XLIB SPGetScrnAddr
	; Get Screen Address
	;
	; Computes the screen address given a valid pixel coordinate.
	; (0,0) is located at the top left corner of the screen.
	;
; enter: a = h = y coord
	;        l = x coord
	;        In hi-res mode, Carry is most significant bit of x coord (0..511 pixels)
; exit : de = screen address, b = pixel mask
; uses : af, b, de, hl
	;IF !DISP_HIRES
	    push namespace core
SPGetScrnAddr:
	    and $07
	    or $40
	    ld d,a
	    ld a,h
	    rra
	    rra
	    rra
	    and $18
	    or d
	    ld d,a
	    ld a,l
	    and $07
	    ld b,a
	    ld a,$80
	    jr z, norotate
rotloop:
	    rra
	    djnz rotloop
norotate:
	    ld b,a
	    srl l
	    srl l
	    srl l
	    ld a,h
	    rla
	    rla
	    and $e0
	    or l
	    ld e,a
	    ret
	    pop namespace
	;ELSE
	;
	;.SPGetScrnAddr
	;   ld b,0
	;   ld d,b
	;   rr l
	;   rl b
	;   srl l
	;   rl b
	;   srl l
	;   rl b
	;   srl l
	;   jr nc, notodd
	;   ld d,$20
	;
	;.notodd
	;   ld a,b
	;  or a
	;   ld a,$80
	;  jr z, norotate
	;
	;.rotloop
	;   rra
	;   djnz rotloop
	;.norotate
	;   ld b,a
	;   ld a,h
	;   and $07
	;   or $40
	;   or d
	;   ld d,a
	;   ld a,h
	;   rra
	;   rra
	;   rra
	;   and $18
	;   or d
	;   ld d,a
	;
	;   ld a,h
	;   rla
	;   rla
	;   and $e0
	    ;  or l
	;   ld e,a
	;   ret
	;ENDIF
#line 552 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/SP/PixelDown.asm"
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
	    push namespace core
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
	    pop namespace
#line 553 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/SP/PixelUp.asm"
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
	    push namespace core
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
	    pop namespace
#line 554 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/circle.asm"
	; Bresenham's like circle algorithm
	; best known as Middle Point Circle drawing algorithm
#line 1 "/zxbasic/src/arch/zx48k/library-asm/error.asm"
	; Simple error control routines
; vim:ts=4:et:
	    push namespace core
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
	    pop namespace
#line 5 "/zxbasic/src/arch/zx48k/library-asm/circle.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/plot.asm"
	; MIXED __FASTCAL__ / __CALLE__ PLOT Function
	; Plots a point into the screen calling the ZX ROM PLOT routine
	; Y in A (accumulator)
	; X in top of the stack
#line 1 "/zxbasic/src/arch/zx48k/library-asm/in_screen.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/sposn.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/sysvars.asm"
	;; -----------------------------------------------------------------------
	;; ZX Basic System Vars
	;; Some of them will be mapped over Sinclair ROM ones for compatibility
	;; -----------------------------------------------------------------------
	push namespace core
SCREEN_ADDR:        DW 16384  ; Screen address (can be pointed to other place to use a screen buffer)
SCREEN_ATTR_ADDR:   DW 22528  ; Screen attribute address (ditto.)
	; These are mapped onto ZX Spectrum ROM VARS
	CHARS	            EQU 23606  ; Pointer to ROM/RAM Charset
	TVFLAGS             EQU 23612  ; TV Flags
	UDG	                EQU 23675  ; Pointer to UDG Charset
	COORDS              EQU 23677  ; Last PLOT coordinates
	FLAGS2	            EQU 23681  ;
	ECHO_E              EQU 23682  ;
	DFCC                EQU 23684  ; Next screen addr for PRINT
	DFCCL               EQU 23686  ; Next screen attr for PRINT
	S_POSN              EQU 23688
	ATTR_P              EQU 23693  ; Current Permanent ATTRS set with INK, PAPER, etc commands
	ATTR_T	            EQU 23695  ; temporary ATTRIBUTES
	P_FLAG	            EQU 23697  ;
	MEM0                EQU 23698  ; Temporary memory buffer used by ROM chars
	SCR_COLS            EQU 33     ; Screen with in columns + 1
	SCR_ROWS            EQU 24     ; Screen height in rows
	SCR_SIZE            EQU (SCR_ROWS << 8) + SCR_COLS
	pop namespace
#line 2 "/zxbasic/src/arch/zx48k/library-asm/sposn.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/attr.asm"
	; Attribute routines
; vim:ts=4:et:sw:
	    push namespace core
__ATTR_ADDR:
	    ; calc start address in DE (as (32 * d) + e)
    ; Contributed by Santiago Romero at http://www.speccy.org
	    ld h, 0                     ;  7 T-States
	    ld a, d                     ;  4 T-States
	    ld d, h
	    add a, a     ; a * 2        ;  4 T-States
	    add a, a     ; a * 4        ;  4 T-States
	    ld l, a      ; HL = A * 4   ;  4 T-States
	    add hl, hl   ; HL = A * 8   ; 15 T-States
	    add hl, hl   ; HL = A * 16  ; 15 T-States
	    add hl, hl   ; HL = A * 32  ; 15 T-States
	    add hl, de
	    ld de, (SCREEN_ATTR_ADDR)    ; Adds the screen address
	    add hl, de
	    ; Return current screen address in HL
	    ret
	; Sets the attribute at a given screen coordinate (D, E).
	; The attribute is taken from the ATTR_T memory variable
	; Used by PRINT routines
SET_ATTR:
	    ; Checks for valid coords
	    call __IN_SCREEN
	    ret nc
	    call __ATTR_ADDR
__SET_ATTR:
	    ; Internal __FASTCALL__ Entry used by printing routines
	    ; HL contains the address of the ATTR cell to set
	    PROC
__SET_ATTR2:  ; Sets attr from ATTR_T to (HL) which points to the scr address
	    ld de, (ATTR_T)    ; E = ATTR_T, D = MASK_T
	    ld a, d
	    and (hl)
	    ld c, a    ; C = current screen color, masked
	    ld a, d
	    cpl        ; Negate mask
	    and e    ; Mask current attributes
	    or c    ; Mix them
	    ld (hl), a ; Store result in screen
	    ret
	    ENDP
	    pop namespace
#line 3 "/zxbasic/src/arch/zx48k/library-asm/sposn.asm"
	; Printing positioning library.
	    push namespace core
	; Loads into DE current ROW, COL print position from S_POSN mem var.
__LOAD_S_POSN:
	    PROC
	    ld de, (S_POSN)
	    ld hl, SCR_SIZE
	    or a
	    sbc hl, de
	    ex de, hl
	    ret
	    ENDP
	; Saves ROW, COL from DE into S_POSN mem var.
__SAVE_S_POSN:
	    PROC
	    ld hl, SCR_SIZE
	    or a
	    sbc hl, de
	    ld (S_POSN), hl ; saves it again
__SET_SCR_PTR:  ;; Fast
	    push de
	    call __ATTR_ADDR
	    ld (DFCCL), hl
	    pop de
	    ld a, d
	    ld c, a     ; Saves it for later
	    and 0F8h    ; Masks 3 lower bit ; zy
	    ld d, a
	    ld a, c     ; Recovers it
	    and 07h     ; MOD 7 ; y1
	    rrca
	    rrca
	    rrca
	    or e
	    ld e, a
	    ld hl, (SCREEN_ADDR)
	    add hl, de    ; HL = Screen address + DE
	    ld (DFCC), hl
	    ret
	    ENDP
	    pop namespace
#line 2 "/zxbasic/src/arch/zx48k/library-asm/in_screen.asm"
	    push namespace core
__IN_SCREEN:
	    ; Returns NO carry if current coords (D, E)
	    ; are OUT of the screen limits
	    PROC
	    LOCAL __IN_SCREEN_ERR
	    ld hl, SCR_SIZE
	    ld a, e
	    cp l
	    jr nc, __IN_SCREEN_ERR	; Do nothing and return if out of range
	    ld a, d
	    cp h
	    ret c                       ; Return if carry (OK)
__IN_SCREEN_ERR:
__OUT_OF_SCREEN_ERR:
	    ; Jumps here if out of screen
	    ld a, ERROR_OutOfScreen
	    jp __STOP   ; Saves error code and exits
	    ENDP
	    pop namespace
#line 9 "/zxbasic/src/arch/zx48k/library-asm/plot.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/set_pixel_addr_attr.asm"
	push namespace core
	; Sets the attribute at a given screen pixel address in hl
	; HL contains the address in RAM for a given pixel (not a coordinate)
SET_PIXEL_ADDR_ATTR:
	    ;; gets ATTR position with offset given in SCREEN_ADDR
	    ld a, h
	    rrca
	    rrca
	    rrca
	    and 3
	    ld h, a
	    ld de, (SCREEN_ATTR_ADDR)
	    add hl, de  ;; Final screen addr
	    jp __SET_ATTR2
	pop namespace
#line 11 "/zxbasic/src/arch/zx48k/library-asm/plot.asm"
	    push namespace core
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
#line 37 "/zxbasic/src/arch/zx48k/library-asm/plot.asm"
#line 43 "/zxbasic/src/arch/zx48k/library-asm/plot.asm"
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
	    jp SET_PIXEL_ADDR_ATTR
__PLOT_ERR:
	    jp __OUT_OF_SCREEN_ERR ; Spent 3 bytes, but saves 3 T-States at (#1)
	PLOT_SUB EQU 22ECh
	PIXEL_ADDR EQU 22ACh
	COORDS EQU 5C7Dh
	    ENDP
	    pop namespace
#line 6 "/zxbasic/src/arch/zx48k/library-asm/circle.asm"
	; Draws a circle at X, Y of radius R
	; X, Y on the Stack, R in accumulator (Byte)
	    push namespace core
	    PROC
	    LOCAL __CIRCLE_ERROR
	    LOCAL __CIRCLE_LOOP
	    LOCAL __CIRCLE_NEXT
__CIRCLE_ERROR:
	    jp __OUT_OF_SCREEN_ERR
CIRCLE:
	    ;; Entry point
	    pop hl    ; Return Address
	    pop de    ; D = Y
	    ex (sp), hl ; __CALLEE__ convention
	    ld e, h ; E = X
	    ld h, a ; H = R
#line 33 "/zxbasic/src/arch/zx48k/library-asm/circle.asm"
#line 39 "/zxbasic/src/arch/zx48k/library-asm/circle.asm"
	    ld a, h
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
	    pop de        ; D'E' = x0, y0
	    ld h, a       ; H' = r
	    ld c, e
	    ld a, h
	    add a, d
	    ld b, a
	    call __CIRCLE_PLOT    ; PLOT (x0, y0 + r)
	    ld b, d
	    ld a, h
	    add a, e
	    ld c, a
	    call __CIRCLE_PLOT    ; PLOT (x0 + r, y0)
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
	    ld b, 0        ; B = x = 0
	    ld c, h        ; C = y = Radius
	    ld hl, 1
	    or a
	    sbc hl, bc    ; HL = f = 1 - radius
	    ex de, hl
	    ld hl, 0
	    or a
	    sbc hl, bc  ; HL = -radius
	    add hl, hl    ; HL = -2 * radius
	    ex de, hl    ; DE = -2 * radius = ddF_y, HL = f
	    xor a        ; A = ddF_x = 0
	    ex af, af'    ; Saves it
__CIRCLE_LOOP:
	    ld a, b
	    inc a
	    cp c
	    ret nc        ; Returns when x >= y
    bit 7, h    ; HL >= 0? : if (f >= 0)...
	    jp nz, __CIRCLE_NEXT
	    dec c        ; y--
	    inc de
	    inc de        ; ddF_y += 2
	    add hl, de    ; f += ddF_y
__CIRCLE_NEXT:
	    inc b        ; x++
	    ex af, af'
	    add a, 2    ; 1 Cycle faster than inc a, inc a
	    inc hl        ; f++
	    push af
	    add a, l
	    ld l, a
	    ld a, h
	    adc a, 0    ; f = f + ddF_x
	    ld h, a
	    pop af
	    ex af, af'
	    push bc
	    exx
	    pop hl        ; H'L' = Y, X
	    ld a, d
	    add a, h
	    ld b, a        ; B = y0 + y
	    ld a, e
	    add a, l
	    ld c, a        ; C = x0 + x
	    call __CIRCLE_PLOT ; plot(x0 + x, y0 + y)
	    ld a, d
	    add a, h
	    ld b, a        ; B = y0 + y
	    ld a, e
	    sub l
	    ld c, a        ; C = x0 - x
	    call __CIRCLE_PLOT ; plot(x0 - x, y0 + y)
	    ld a, d
	    sub h
	    ld b, a        ; B = y0 - y
	    ld a, e
	    add a, l
	    ld c, a        ; C = x0 + x
	    call __CIRCLE_PLOT ; plot(x0 + x, y0 - y)
	    ld a, d
	    sub h
	    ld b, a        ; B = y0 - y
	    ld a, e
	    sub l
	    ld c, a        ; C = x0 - x
	    call __CIRCLE_PLOT ; plot(x0 - x, y0 - y)
	    ld a, l
	    cp h
	    jr z, 1f
	    ld a, d
	    add a, l
	    ld b, a        ; B = y0 + x
	    ld a, e
	    add a, h
	    ld c, a        ; C = x0 + y
	    call __CIRCLE_PLOT ; plot(x0 + y, y0 + x)
	    ld a, d
	    add a, l
	    ld b, a        ; B = y0 + x
	    ld a, e
	    sub h
	    ld c, a        ; C = x0 - y
	    call __CIRCLE_PLOT ; plot(x0 - y, y0 + x)
	    ld a, d
	    sub l
	    ld b, a        ; B = y0 - x
	    ld a, e
	    add a, h
	    ld c, a        ; C = x0 + y
	    call __CIRCLE_PLOT ; plot(x0 + y, y0 - x)
	    ld a, d
	    sub l
	    ld b, a        ; B = y0 - x
	    ld a, e
	    sub h
	    ld c, a        ; C = x0 + y
	    call __CIRCLE_PLOT ; plot(x0 - y, y0 - x)
1:
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
	    pop namespace
#line 555 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/cls.asm"
	;; Clears the user screen (24 rows)
	    push namespace core
CLS:
	    PROC
	    ld hl, 0
	    ld (COORDS), hl
	    ld hl, SCR_SIZE
	    ld (S_POSN), hl
	    ld hl, (SCREEN_ADDR)
	    ld (DFCC), hl
	    ld (hl), 0
	    ld d, h
	    ld e, l
	    inc de
	    ld bc, 6143
	    ldir
	    ; Now clear attributes
	    ld hl, (SCREEN_ATTR_ADDR)
	    ld (DFCCL), hl
	    ld d, h
	    ld e, l
	    inc de
	    ld a, (ATTR_P)
	    ld (hl), a
	    ld bc, 767
	    ldir
	    ret
	    ENDP
	    pop namespace
#line 556 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/pause.asm"
	; The PAUSE statement (Calling the ROM)
	    push namespace core
__PAUSE:
	    ld b, h
	    ld c, l
	    jp 1F3Dh  ; PAUSE_1
	    pop namespace
#line 557 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/usr_str.asm"
	; This function just returns the address of the UDG of the given str.
	; If the str is EMPTY or not a letter, 0 is returned and ERR_NR set
; to "A: Invalid Argument"
	; On entry HL points to the string
	; and A register is non-zero if the string must be freed (TMP string)
#line 1 "/zxbasic/src/arch/zx48k/library-asm/free.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the BSD license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the BSD license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be breed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
#line 1 "/zxbasic/src/arch/zx48k/library-asm/heapinit.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the BSD license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the BSD license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be breed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
	; ---------------------------------------------------------------------
	;  __MEM_INIT must be called to initalize this library with the
	; standard parameters
	; ---------------------------------------------------------------------
	    push namespace core
__MEM_INIT: ; Initializes the library using (RAMTOP) as start, and
	    ld hl, ZXBASIC_MEM_HEAP  ; Change this with other address of heap start
	    ld de, ZXBASIC_HEAP_SIZE ; Change this with your size
	; ---------------------------------------------------------------------
	;  __MEM_INIT2 initalizes this library
; Parameters:
;   HL : Memory address of 1st byte of the memory heap
;   DE : Length in bytes of the Memory Heap
	; ---------------------------------------------------------------------
__MEM_INIT2:
	    ; HL as TOP
	    PROC
	    dec de
	    dec de
	    dec de
	    dec de        ; DE = length - 4; HL = start
	    ; This is done, because we require 4 bytes for the empty dummy-header block
	    xor a
	    ld (hl), a
	    inc hl
    ld (hl), a ; First "free" block is a header: size=0, Pointer=&(Block) + 4
	    inc hl
	    ld b, h
	    ld c, l
	    inc bc
	    inc bc      ; BC = starts of next block
	    ld (hl), c
	    inc hl
	    ld (hl), b
	    inc hl      ; Pointer to next block
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    inc hl      ; Block size (should be length - 4 at start); This block contains all the available memory
	    ld (hl), a ; NULL (0000h) ; No more blocks (a list with a single block)
	    inc hl
	    ld (hl), a
	    ld a, 201
	    ld (__MEM_INIT), a; "Pokes" with a RET so ensure this routine is not called again
	    ret
	    ENDP
	    pop namespace
#line 69 "/zxbasic/src/arch/zx48k/library-asm/free.asm"
	; ---------------------------------------------------------------------
	; MEM_FREE
	;  Frees a block of memory
	;
; Parameters:
	;  HL = Pointer to the block to be freed. If HL is NULL (0) nothing
	;  is done
	; ---------------------------------------------------------------------
	    push namespace core
MEM_FREE:
__MEM_FREE: ; Frees the block pointed by HL
	    ; HL DE BC & AF modified
	    PROC
	    LOCAL __MEM_LOOP2
	    LOCAL __MEM_LINK_PREV
	    LOCAL __MEM_JOIN_TEST
	    LOCAL __MEM_BLOCK_JOIN
	    ld a, h
	    or l
	    ret z       ; Return if NULL pointer
	    dec hl
	    dec hl
	    ld b, h
	    ld c, l    ; BC = Block pointer
	    ld hl, ZXBASIC_MEM_HEAP  ; This label point to the heap start
__MEM_LOOP2:
	    inc hl
	    inc hl     ; Next block ptr
	    ld e, (hl)
	    inc hl
	    ld d, (hl) ; Block next ptr
	    ex de, hl  ; DE = &(block->next); HL = block->next
	    ld a, h    ; HL == NULL?
	    or l
	    jp z, __MEM_LINK_PREV; if so, link with previous
	    or a       ; Clear carry flag
	    sbc hl, bc ; Carry if BC > HL => This block if before
	    add hl, bc ; Restores HL, preserving Carry flag
	    jp c, __MEM_LOOP2 ; This block is before. Keep searching PASS the block
	;------ At this point current HL is PAST BC, so we must link (DE) with BC, and HL in BC->next
__MEM_LINK_PREV:    ; Link (DE) with BC, and BC->next with HL
	    ex de, hl
	    push hl
	    dec hl
	    ld (hl), c
	    inc hl
	    ld (hl), b ; (DE) <- BC
	    ld h, b    ; HL <- BC (Free block ptr)
	    ld l, c
	    inc hl     ; Skip block length (2 bytes)
	    inc hl
	    ld (hl), e ; Block->next = DE
	    inc hl
	    ld (hl), d
	    ; --- LINKED ; HL = &(BC->next) + 2
	    call __MEM_JOIN_TEST
	    pop hl
__MEM_JOIN_TEST:   ; Checks for fragmented contiguous blocks and joins them
	    ; hl = Ptr to current block + 2
	    ld d, (hl)
	    dec hl
	    ld e, (hl)
	    dec hl
	    ld b, (hl) ; Loads block length into BC
	    dec hl
	    ld c, (hl) ;
	    push hl    ; Saves it for later
	    add hl, bc ; Adds its length. If HL == DE now, it must be joined
	    or a
	    sbc hl, de ; If Z, then HL == DE => We must join
	    pop hl
	    ret nz
__MEM_BLOCK_JOIN:  ; Joins current block (pointed by HL) with next one (pointed by DE). HL->length already in BC
	    push hl    ; Saves it for later
	    ex de, hl
	    ld e, (hl) ; DE -> block->next->length
	    inc hl
	    ld d, (hl)
	    inc hl
	    ex de, hl  ; DE = &(block->next)
	    add hl, bc ; HL = Total Length
	    ld b, h
	    ld c, l    ; BC = Total Length
	    ex de, hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl) ; DE = block->next
	    pop hl     ; Recovers Pointer to block
	    ld (hl), c
	    inc hl
	    ld (hl), b ; Length Saved
	    inc hl
	    ld (hl), e
	    inc hl
	    ld (hl), d ; Next saved
	    ret
	    ENDP
	    pop namespace
#line 11 "/zxbasic/src/arch/zx48k/library-asm/usr_str.asm"
	    push namespace core
USR_STR:
	    PROC
	    ex af, af'     ; Saves A flag
	    ld a, h
	    or l
	    jr z, USR_ERROR ; a$ = NULL => Invalid Arg
	    ld d, h         ; Saves HL in DE, for
	    ld e, l         ; later usage
	    ld c, (hl)
	    inc hl
	    ld a, (hl)
	    or c
	    jr z, USR_ERROR ; a$ = "" => Invalid Arg
	    inc hl
	    ld a, (hl) ; Only the 1st char is needed
	    and %11011111 ; Convert it to UPPER CASE
	    sub 144   ; CODE(UDG "A")
	    jr nc, CONT
	    add a, 144   ; It was a letter
	    sub 'A'
	    LOCAL CONT
CONT:
	    ld l, a
	    ld h, 0
	    add hl, hl
	    add hl, hl
	    add hl, hl	 ; hl = A * 8
	    ld bc, (UDG)
	    add hl, bc
	    ;; Now checks if the string must be released
	    ex af, af'  ; Recovers A flag
	    or a
	    ret z   ; return if not
	    push hl ; saves result since __MEM_FREE changes HL
	    ex de, hl   ; Recovers original HL value
	    call __MEM_FREE
	    pop hl
	    ret
USR_ERROR:
	    ex de, hl   ; Recovers original HL value
	    ex af, af'  ; Recovers A flag
	    or a
	    call nz, __MEM_FREE
	    ld a, ERROR_InvalidArg
	    ld (ERR_NR), a
	    ld hl, 0
	    ret
	    ENDP
	    pop namespace
#line 558 "/zxbasic/src/arch/zx48k/library/SP/Fill.bas"
	END
