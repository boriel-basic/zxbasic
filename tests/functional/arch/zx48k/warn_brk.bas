FUNCTION distance () as uByte
    DIM c as integer
    return CAST(uByte,c)
END FUNCTION

POKE 0, distance()

