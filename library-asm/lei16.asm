

__LEI16: ; Test 16 bit signed values HL <= DE
        ; Returns result in A: 0 = False, !0 = True
        xor a
        sbc hl, de
        ld a, 1
        ret z
        ret m
        xor a
        ret

