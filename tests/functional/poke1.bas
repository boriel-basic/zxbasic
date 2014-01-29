SUB test
    DIM i as Uinteger = 16384
    
    DIM j as Ubyte
    FOR j = 0 to 250
        POKE Uinteger i, 65535
        i = i + 1
    NEXT j
END SUB

test()

