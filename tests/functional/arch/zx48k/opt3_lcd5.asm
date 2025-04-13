	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld (.core.__CALL_BACK__), sp
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_x:
	DEFB 00, 00, 00, 00, 00
_y:
	DEFB 00, 00, 00, 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, 3
	push af
	ld a, (_y)
	ld de, (_y + 1)
	ld bc, (_y + 3)
	call .core.__FTOU32REG
	push hl
	ld a, (_x)
	ld de, (_x + 1)
	ld bc, (_x + 3)
	call .core.__FTOU32REG
	push hl
	call _SetField
	ld a, (_y)
	ld de, (_y + 1)
	ld bc, (_y + 3)
	call .core.__FTOU32REG
	ld a, l
	push af
	ld a, (_x)
	ld de, (_x + 1)
	ld bc, (_x + 3)
	call .core.__FTOU32REG
	ld a, l
	push af
	call _ScanNear
.LABEL._chessboard:
.LABEL._overlay:
	ld bc, 0
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
_ScanField:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	ex de, hl
	ld hl, 0
	call .core.__LEI16
	push af
	ld l, (ix+4)
	ld h, (ix+5)
	ld de, 8
	call .core.__LTI16
	ld h, a
	pop af
	or a
	jr z, .LABEL.__LABEL6
	ld a, h
.LABEL.__LABEL6:
	push af
	ld l, (ix+6)
	ld h, (ix+7)
	ex de, hl
	ld hl, 0
	call .core.__LEI16
	ld h, a
	pop af
	or a
	jr z, .LABEL.__LABEL7
	ld a, h
.LABEL.__LABEL7:
	push af
	ld l, (ix+6)
	ld h, (ix+7)
	ld de, 8
	call .core.__LTI16
	ld h, a
	pop af
	or a
	jr z, .LABEL.__LABEL8
	ld a, h
.LABEL.__LABEL8:
	or a
	jp z, .LABEL.__LABEL0
	ld hl, .LABEL._overlay
	push hl
	ld l, (ix+6)
	ld h, (ix+7)
	add hl, hl
	add hl, hl
	add hl, hl
	ex de, hl
	pop hl
	add hl, de
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	ex de, hl
	pop hl
	add hl, de
	ld (ix-2), l
	ld (ix-1), h
	ld a, (hl)
	and (ix+9)
	jp _ScanField__leave
.LABEL.__LABEL0:
	xor a
_ScanField__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
_SetField:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	ld l, (ix+6)
	ld h, (ix+7)
	add hl, hl
	add hl, hl
	add hl, hl
	ex de, hl
	ld hl, .LABEL._overlay
	add hl, de
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	ex de, hl
	pop hl
	add hl, de
	ld (ix-2), l
	ld (ix-1), h
	push hl
	ld a, (hl)
	pop hl
	or (ix+9)
	ld (hl), a
_SetField__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
_ScanNear:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	inc sp
	ld a, 7
	push af
	ld a, (ix+7)
	dec a
	ld l, a
	push hl
	ld a, (ix+5)
	dec a
	ld l, a
	push hl
	call _ScanField
	dec a
	sub 1
	sbc a, a
	push af
	ld a, 7
	push af
	ld a, (ix+7)
	dec a
	ld l, a
	ld h, 0
	push hl
	ld a, (ix+5)
	inc a
	ld l, a
	push hl
	call _ScanField
	pop de
	dec a
	sub 1
	sbc a, a
	or d
	jp z, .LABEL.__LABEL3
	ld (ix-1), 1
.LABEL.__LABEL3:
	ld a, 7
	push af
	ld a, (ix+7)
	dec a
	ld l, a
	ld h, 0
	push hl
	ld a, (ix+5)
	dec a
	ld l, a
	push hl
	call _ScanField
	sub 6
	sub 1
	sbc a, a
	push af
	ld a, 7
	push af
	ld a, (ix+7)
	dec a
	ld l, a
	ld h, 0
	push hl
	ld a, (ix+5)
	ld l, a
	push hl
	call _ScanField
	pop de
	sub 6
	sub 1
	sbc a, a
	or d
	push af
	ld a, 7
	push af
	ld a, (ix+7)
	dec a
	ld l, a
	ld h, 0
	push hl
	ld a, (ix+5)
	inc a
	ld l, a
	push hl
	call _ScanField
	pop de
	sub 6
	sub 1
	sbc a, a
	or d
	push af
	ld a, 7
	push af
	ld a, (ix+7)
	ld l, a
	ld h, 0
	push hl
	ld a, (ix+5)
	dec a
	ld l, a
	push hl
	call _ScanField
	pop de
	sub 6
	sub 1
	sbc a, a
	or d
	push af
	ld a, 7
	push af
	ld a, (ix+7)
	ld l, a
	ld h, 0
	push hl
	ld a, (ix+5)
	inc a
	ld l, a
	push hl
	call _ScanField
	pop de
	sub 6
	sub 1
	sbc a, a
	or d
	push af
	ld a, 7
	push af
	ld a, (ix+7)
	inc a
	ld l, a
	ld h, 0
	push hl
	ld a, (ix+5)
	dec a
	ld l, a
	push hl
	call _ScanField
	pop de
	sub 6
	sub 1
	sbc a, a
	or d
	push af
	ld a, 7
	push af
	ld a, (ix+7)
	inc a
	ld l, a
	ld h, 0
	push hl
	ld a, (ix+5)
	ld l, a
	push hl
	call _ScanField
	pop de
	sub 6
	sub 1
	sbc a, a
	or d
	push af
	ld a, 7
	push af
	ld a, (ix+7)
	inc a
	ld l, a
	ld h, 0
	push hl
	ld a, (ix+5)
	inc a
	ld l, a
	push hl
	call _ScanField
	pop de
	sub 6
	sub 1
	sbc a, a
	or d
	jp z, .LABEL.__LABEL5
	ld a, (ix-1)
	or 32
	ld (ix-1), a
.LABEL.__LABEL5:
	ld a, (ix-1)
_ScanNear__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lei16.asm"
	    push namespace core
__LEI16:
	    PROC
	    LOCAL checkParity
	    or a
	    sbc hl, de
	    ld a, 1
	    ret z
	    jp po, checkParity
	    ld a, h
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 354 "arch/zx48k/opt3_lcd5.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lti16.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lei8.asm"
	    push namespace core
__LEI8: ; Signed <= comparison for 8bit int
	    ; A <= H (registers)
	    PROC
	    LOCAL checkParity
	    sub h
	    jr nz, __LTI
	    inc a
	    ret
__LTI8:  ; Test 8 bit values A < H
	    sub h
__LTI:   ; Generic signed comparison
	    jp po, checkParity
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lti16.asm"
	    push namespace core
__LTI16: ; Test 8 bit values HL < DE
    ; Returns result in A: 0 = False, !0 = True
	    PROC
	    LOCAL checkParity
	    or a
	    sbc hl, de
	    jp po, checkParity
	    ld a, h
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 355 "arch/zx48k/opt3_lcd5.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/ftou32reg.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/neg32.asm"
	    push namespace core
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
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/ftou32reg.asm"
	    push namespace core
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
	    ld d, e
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
	    pop namespace
#line 356 "arch/zx48k/opt3_lcd5.bas"
	END
