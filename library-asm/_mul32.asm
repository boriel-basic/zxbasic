
; Ripped from: http://www.andreadrian.de/oldcpu/z80_number_cruncher.html#moztocid784223
; Used with permission.
; Multiplies 32x32 bit integer (DEHL x D'E'H'L')
; 64bit result is returned in H'L'H L B'C'A C


__MUL32_64START:
		push hl
		exx
		ld b, h
		ld c, l		; BC = Low Part (A)
		pop hl		; HL = Load Part (B)
		ex de, hl	; DE = Low Part (B), HL = HightPart(A) (must be in B'C')
		push hl

		exx
		pop bc		; B'C' = HightPart(A)
		exx			; A = B'C'BC , B = D'E'DE

			; multiply routine 32 * 32bit = 64bit
			; h'l'hlb'c'ac = b'c'bc * d'e'de
			; needs register a, changes flags
			;
			; this routine was with tiny differences in the
			; sinclair zx81 rom for the mantissa multiply

__LMUL:
        and     a               ; reset carry flag
        sbc     hl,hl           ; result bits 32..47 = 0
        exx
        sbc     hl,hl           ; result bits 48..63 = 0
        exx
        ld      a,b             ; mpr is b'c'ac
        ld      b,33            ; initialize loop counter
        jp      __LMULSTART  

__LMULLOOP:
        jr      nc,__LMULNOADD  ; JP is 2 cycles faster than JR. Since it's inside a LOOP
                                ; it can save up to 33 * 2 = 66 cycles
                                ; But JR if 3 cycles faster if JUMP not taken!
        add     hl,de           ; result += mpd
        exx
        adc     hl,de
        exx

__LMULNOADD:
        exx
        rr      h               ; right shift upper
        rr      l               ; 32bit of result
        exx
        rr      h
        rr      l

__LMULSTART:
        exx
        rr      b               ; right shift mpr/
        rr      c               ; lower 32bit of result
        exx
        rra                     ; equivalent to rr a
        rr      c
        djnz    __LMULLOOP

		ret						; result in h'l'hlb'c'ac
       
