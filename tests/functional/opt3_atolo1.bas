ASM
ld a,(bc)
ld h, a
inc c
ld a, (bc)
ld l, a
call 0x000
END ASM

