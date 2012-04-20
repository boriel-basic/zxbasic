REM Byte < comparison

DIM i AS Integer = -32768
DIM j AS Integer
DIM ii, jj AS Long
DIM Counter as ULong = 0

PRINT "Testing (integer) > (integer) [GTi16]"

DO
    j = -32768
    ii = i

    DO
        jj = j
        If (i > j) XOR (ii > jj) THEN
            PRINT i; ">"; j; " = "; (i < j); " "; PAPER 2; INK 7; FLASH 1; " ERROR "; PAPER 8; FLASH 0; TAB 31
            PRINT Counter
            STOP
        End If

        print at 5, 0; Counter; " "; i; " "; j; TAB 16
        Counter = Counter + 1
        j = j + 256
    LOOP UNTIL j = -32768

    i = i + 256
LOOP UNTIL i = -32768

IF Counter <> 65536 THEN
    PRINT "Iterations: "; Counter; " "; PAPER 2; INK 7; FLASH 1; " ERROR "; PAPER 8; FLASH 0; TAB 31
ELSE
    PRINT PAPER 4; INK 7; " SUCCESS "; PAPER 8; TAB 31
END IF

