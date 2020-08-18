; FASTCALL bitwise xor 32 version.
; Performs 32bit xor 32bit and returns the bitwise
; result DE,HL
; First operand in DE,HL 2nd operand into the stack

__BXOR32:
    ld b, h
    ld c, l ; BC <- HL

    pop hl  ; Return address
    ex (sp), hl ; HL <- Lower part of 2nd Operand

	ld a, b
    xor h
    ld b, a

    ld a, c
    xor l
    ld c, a ; BC <- BC & HL

	pop hl  ; Return dddress
    ex (sp), hl ; HL <- High part of 2nd Operand

    ld a, d
    xor h
    ld d, a

    ld a, e
    xor l
    ld e, a ; DE <- DE & HL

    ld h, b
    ld l, c ; HL <- BC  ; Always return DE,HL pair regs

    ret

