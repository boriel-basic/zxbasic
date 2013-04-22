; FASTCALL bitwise and 32 version.
; Performs 32bit and 32bit and returns the bitwise
; result in DE,HL
; First operand in DE,HL 2nd operand into the stack

__BAND32:
    ld b, h
    ld c, l ; BC <- HL

    pop hl  ; Return address
    ex (sp), hl ; HL <- Lower part of 2nd Operand

	ld a, b
    and h
    ld b, a

    ld a, c
    and l
    ld c, a ; BC <- BC & HL

	pop hl  ; Return dddress
    ex (sp), hl ; HL <- High part of 2nd Operand

    ld a, d
    and h
    ld d, a

    ld a, e
    and l
    ld e, a ; DE <- DE & HL

    ld h, b
    ld l, c ; HL <- BC  ; Always return DE,HL pair regs

    ret

