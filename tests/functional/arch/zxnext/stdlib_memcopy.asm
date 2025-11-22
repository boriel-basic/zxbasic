	org 32768
.core.__START_PROGRAM:
	di
	push iy
	ld iy, 0x5C3A  ; ZX Spectrum ROM variables address
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
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	pop iy
	ei
	ret
_MemMove:
#line 31 "/zxbasic/src/lib/arch/zxnext/stdlib/memcopy.bas"
		push namespace core
		exx
		pop hl
		exx
		pop de
		pop bc
		exx
		push hl
		exx
		jp __MEMCPY
		pop namespace
#line 51 "/zxbasic/src/lib/arch/zxnext/stdlib/memcopy.bas"
_MemMove__leave:
	ret
_MemCopy:
#line 67 "/zxbasic/src/lib/arch/zxnext/stdlib/memcopy.bas"
		push namespace core
		exx
		pop hl
		exx
		pop de
		pop bc
		exx
		push hl
		exx
		ldir
		pop namespace
#line 87 "/zxbasic/src/lib/arch/zxnext/stdlib/memcopy.bas"
_MemCopy__leave:
	ret
_MemSet:
#line 100 "/zxbasic/src/lib/arch/zxnext/stdlib/memcopy.bas"
		push namespace core
		pop de
		pop af
		pop bc
		push de
		ld (hl),a
		dec bc
		ld a, b
		or c
		ret z
		ld d,h
		ld e,l
		inc de
		ldir
		pop namespace
#line 122 "/zxbasic/src/lib/arch/zxnext/stdlib/memcopy.bas"
_MemSet__leave:
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/mem/memcopy.asm"
	; ----------------------------------------------------------------
	; This file is released under the MIT License
	;
	; Copyleft (k) 2008
; by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
	;
	; Use this file as a template to develop your own library file
	; ----------------------------------------------------------------
	; Emulates both memmove and memcpy C routines
	; Block will be safely copied if they overlap
	; HL => Start of source block
	; DE => Start of destiny block
	; BC => Block length
	    push namespace core
__MEMCPY:
	    PROC
	    LOCAL __MEMCPY2
	    push hl
	    add hl, bc  ; addr of last source block byte + 1
	    or a
	    sbc hl, de  ; checks if DE > HL + BC
	    pop hl      ; recovers HL. If carry => DE > HL + BC (no overlap)
	    jr c, __MEMCPY2
	    ; Now checks if DE <= HL
	    sbc hl, de  ; Even if overlap, if DE < HL then we can LDIR safely
	    add hl, de
	    jr nc, __MEMCPY2
	    dec bc
	    add hl, bc
	    ex de, hl
	    add hl, bc
	    ex de, hl
	    inc bc      ; HL and DE point to the last byte position
	    lddr        ; Copies from end to beginning
	    ret
__MEMCPY2:
	    ldir
	    ret
	    ENDP
	    pop namespace
#line 127 "/zxbasic/src/lib/arch/zxnext/stdlib/memcopy.bas"
	END
