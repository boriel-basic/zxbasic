
__LTI8: ; Test 8 bit values A < H
        ; Returns result in A: 0 = False, Z Flag = 0, 1 = True, Z flag = 1
        sub h
        ld a, 1
        ret m
        xor a
        ret
