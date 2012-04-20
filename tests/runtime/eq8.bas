REM Byte < comparison

DIM i AS Byte = -128
DIM j AS Byte
DIM ii, jj AS Integer
DIM Counter as ULong = 0

PRINT "Testing (byte) == (byte) [LEi8]"

DO
    j = -128
    ii = i

    DO
        jj = j
        If (i = j) XOR (ii = jj) THEN
            PRINT i; "=="; j; " = "; (i <= j); " "; PAPER 2; INK 7; FLASH 1; " ERROR "; PAPER 8; FLASH 0; TAB 31
            STOP
        End If

        Counter = Counter + 1
        j = j + 1
    LOOP UNTIL j = -128

    i = i + 1
LOOP UNTIL i = -128

IF Counter <> 65536 THEN
    PRINT "Iterations: "; Counter; " "; PAPER 2; INK 7; FLASH 1; " ERROR "; PAPER 8; FLASH 0; TAB 31
ELSE
    PRINT PAPER 4; INK 7; " SUCCESS "; PAPER 8; TAB 31
END IF

