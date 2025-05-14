# SetCodeBank

## Syntax

```
#include <memorybank.bas>

SetCodeBank(3)
```

## Description
Place the bank indicated by bankNumber in the memory slot between $c000 and $ffff and updates the system variable BANKM.
This command is applicable to the architecture described in chapter 14 of the Boriel Basic for ZX Spectrum book.

Only works on 128K and compatible models.

**Danger:** If our program exceeds the address $c000 it may cause problems, use this function at your own risk.
Bank 2 is destroyed in this operation, apart from the contents of $8000 to $bfff, so it should not be used.


## Memory banks
- $c000 > Bank 0 to Bank 7
- $8000 > Bank 2 (fixed)
- $4000 > Bank 5 (screen)
- $0000 > ROM

Banks 2 and 5 are permanently fixed at addresses $8000 and $4000, so it is not common to use them.
Banks 1, 3, 5 and 7 are banks in contention with the ULA, their use is not recommended in processes requiring maximum speed.


## Examples

```
#include <memorybank.bas>

DIM n, b AS UByte

' Fill banks with data
FOR n = 0 TO 7
    SetBank(n)
    PRINT AT n,0;"Bank: ";n;
    POKE $c000,n
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
```

## See also
- [SetBank](setbank.md)
- [GetBank](getbank.md)
