
DIM i, j, k as Byte

i = 127
DO
    i = i + 1
    j = 127
    DO
        j = j + 1
        IF i > j THEN
            let k = i > j
            if not k THEN
                PRINT i; " !> "; j; " "; FLASH 1; INK 2; " ERROR "
                STOP
            END IF
        END IF
    LOOP UNTIL j = 127
LOOP UNTIL i = 127

PRINT PAPER 4; INK 7; " SUCCESS "; PAPER 8; TAB 31

