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
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_x:
	DEFB 00, 00
_y:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, 1
	ld (_y), a
	ld d, 16
	ld e, a
	mul d, e
	ld a, e
	push af
	ld hl, (_x)
	call .core.__MUL16_FAST
	push hl
	call _printTest
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
_printTest:
	push ix
	ld ix, 0
	add ix, sp
	ld a, (ix+7)
	ld (0), a
_printTest__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zxnext/library-asm/mul16.asm"
	    push namespace core
__MUL16:	; Mutiplies HL with the last value stored into de stack
	    ; Works for both signed and unsigned
	    PROC
	    ex de, hl
	    pop hl		; Return address
	    ex (sp), hl ; CALLEE caller convention
__MUL16_FAST:
	    ld a,d                      ; a = xh
	    ld d,h                      ; d = yh
	    ld h,a                      ; h = xh
	    ld c,e                      ; c = xl
	    ld b,l                      ; b = yl
	    mul d,e                     ; yh * yl
	    ex de,hl
	    mul d,e                     ; xh * yl
	    add hl,de                   ; add cross products
	    ld e,c
	    ld d,b
	    mul d,e                     ; yl * xl
	    ld a,l                      ; cross products lsb
	    add a,d                     ; add to msb final
	    ld h,a
	    ld l,e                      ; hl = final
	    ret	; Result in hl (16 lower bits)
	    ENDP
	    pop namespace
#line 41 "zxnext/opt4_mul8.bas"
	END
