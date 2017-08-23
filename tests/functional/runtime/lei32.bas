REM Byte < comparison

DIM i AS Long = -2147483648
DIM j AS Long 
DIM ii, jj AS Float
DIM Counter as ULong = 0

PRINT "Testing (long) <= (long) [LEi32]"

DO
    j = -2147483648
    ii = i

    DO
        jj = j
        If (i <= j) XOR (ii <= jj) THEN
            PRINT i; "<="; j; " = "; (i <= j); " "; PAPER 2; INK 7; FLASH 1; " ERROR "; PAPER 8; FLASH 0; TAB 31
            STOP
        End If

        'print at 5, 0; Counter; " "; i; " "; j; TAB 16
        Counter = Counter + 1
        j = j + 32768
    LOOP UNTIL j = -2147483648

    i = i + 32768
LOOP UNTIL i = -2147483648

IF Counter <> 65536 << 8 THEN
    PRINT "Iterations: "; Counter; " "; PAPER 2; INK 7; FLASH 1; " ERROR "; PAPER 8; FLASH 0; TAB 31
ELSE
    PRINT PAPER 4; INK 7; " SUCCESS "; PAPER 8; TAB 31
END IF

