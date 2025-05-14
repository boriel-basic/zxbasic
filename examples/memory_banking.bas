' ---------------------------------------------------------
' - MemoryBank.bas library Test ---------------------------
' ---------------------------------------------------------
' Compile at 24576


#include "memorybank.bas"


Main()
DO:LOOP


SUB Main()
    CLS
    Test_SetBank()
    PAUSE 0
    CLS
    SetBankSample()
END SUB


SUB Test_SetBank()
    DIM n, b AS UByte

    ' SetBank and GetBank
    FOR n = 0 TO 7
        PRINT AT n+1,0;"Bank: ";n;
        SetBank(n)
        PRINT ">";GetBank();
        POKE $c000,n
    NEXT n

    ' Test banks
    FOR n = 0 TO 7
        PRINT AT n+1,9;">";n;
        SetBank(n)
        b = PEEK($c000)
        IF b = n THEN
            PRINT ">OK";
        ELSE
            PRINT ">ERROR";
        END IF
    NEXT n

    ' SetCodeBank
    FOR n = 0 TO 7
        PRINT AT n+1,16;">";n;
        SetCodeBank(n)
        IF n = 2 THEN
            PRINT ">SKIP";
        ELSE
            b = PEEK($8000)
            PRINT ">";b;
            IF b = n THEN
                PRINT ">OK";
            ELSE
                PRINT ">ERROR";
            END IF
        END IF
    NEXT n
END SUB


SUB SetBankSample()
    DIM n, b AS UByte

    ' Fill banks with data
    FOR n = 0 TO 7
        SetBank(n)
        PRINT AT n,0;"Bank: ";n;
        POKE $c000,n
    NEXT n

    ' Read banks
    FOR n = 0 TO 7
        SetBank(n)
        PRINT AT n,10;PEEK($c000);
    NEXT n

END SUB
