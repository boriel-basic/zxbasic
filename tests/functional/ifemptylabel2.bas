DIM a as Byte
IF 1 THEN
    a = a + 1    
ELSE
Here:
    a = a + 2
    IF 0 THEN
        a = a + 3
    END IF
END IF

GOTO Here

