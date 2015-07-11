sub x2()
    DIM a AS UBYTE

    LET a = 129
    IF (a <= 32) THEN
        PRINT "Ops"
    ELSE
        PRINT "OK"
    END IF
end sub

x2()

