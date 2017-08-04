REM test for local array with labels
label1:
label2:
label3:

FUNCTION test()
    DIM a(1 TO 3) as UInteger => {@label1, @label2, @label3}
    POKE a(1), 5
END FUNCTION

test()

