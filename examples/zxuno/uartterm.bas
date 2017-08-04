REM UART terminal example


#include <zxuno/uart.bas>

DIM c as Integer
DIM ky as String

CLS
UARTbegin()
PRINT "UART opened. Type in something to send bytes."
PRINT "Press "#" to exit"

DO 
    c = UARTread()
    IF c >= 0 THEN
        IF c >= 32 AND c < 127 OR c = 13 OR c = 10 THEN
            PRINT CHR$(c);
        ELSE
            PRINT "-";
        END IF
    END IF

    ky = INKEY$
    IF ky = "#" THEN
        EXIT DO
    END IF

    IF ky <> "" THEN
        DO LOOP WHILE INKEY$ <> "": REM wait for key release
        IF ky = CHR$(13) THEN
            UARTwriteByte(13)
            UARTwriteByte(10)
        ELSE
            UARTwriteByte(CODE ky)
        END IF
    END IF
LOOP

PRINT "End. Press any key"
PAUSE 0
