sub x2()
    DIM a AS UBYTE

    LET a = 129
    IF (a <= 32) THEN
        POKE 0, a
    ELSE
        POKE 1, a
    END IF
end sub

x2()
