DIM a as Byte
IF 1 THEN
    a = a + 1    
ELSE
Here:
    a = a + 1
    IF 0 THEN
        a = a + 2
    END IF
END IF

GOTO Here

