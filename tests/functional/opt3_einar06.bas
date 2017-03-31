sub test()
    asm
        ld      hl, 56469
        ld      de, 5
        ld      (hl), e
        ld      (hl), d
        ld h, l
        ld h, 5
        inc     l
;        ret
    end asm
end sub

test()

