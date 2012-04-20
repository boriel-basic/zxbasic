
__LTI8: ; Test 8 bit values A < H
        ; Returns result in A: 0 = False, !0 = True
        sub h

__LTI:  ; Signed CMP
        PROC
        LOCAL __PE

        ld a, 0  ; Sets default to false
__LTI2:
        jp pe, __PE
        ; Overflow flag NOT set
        ret p
        dec a ; TRUE

__PE:   ; Overflow set
        ret m
        dec a ; TRUE
        ret
        
        ENDP
