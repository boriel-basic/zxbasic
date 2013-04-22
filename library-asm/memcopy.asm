; ----------------------------------------------------------------
; This file is released under the GPL v3 License
; 
; Copyleft (k) 2008
; by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
;
; Use this file as a template to develop your own library file
; ----------------------------------------------------------------

; Emulates both memmove and memcpy C routines
; Blocks will safely copies if they overlap

; HL => Start of source block
; DE => Start of destiny block
; BC => Block length

__MEMCPY:

    PROC
    LOCAL __MEMCPY2

	push hl
	add hl, bc
    or a
    sbc hl, de  ; checks if DE > HL + BC
    pop hl  ; recovers HL. If Carry set => DE > HL
    jr c, __MEMCPY2

	; Now checks if DE <= HL

	sbc hl, de
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
