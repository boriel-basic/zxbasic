; FASTCALL bitwise or 32 version.
; Performs 32bit or 32bit and returns the bitwise
; result DE,HL
; First operand in DE,HL 2nd operand into the stack

__BOR32:
    ld b, h
    ld c, l ; BC <- HL

    pop hl  ; Return address
    ex (sp), hl ; HL <- Lower part of 2nd Operand

	ld a, b
    or h
    ld b, a

    ld a, c
    or l
    ld c, a ; BC <- BC & HL

	pop hl  ; Return dddress
    ex (sp), hl ; HL <- High part of 2nd Operand

    ld a, d
    or h
    ld d, a

    ld a, e
    or l
    ld e, a ; DE <- DE & HL

    ld h, b
    ld l, c ; HL <- BC  ; Always return DE,HL pair regs

    ret

