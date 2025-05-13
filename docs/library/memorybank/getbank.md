# GetBank

## Syntax

```
#include <memorybank.bas>

PRINT "Current bank at $c000: ";GetBank()
```

## Description
Returns the memory bank located at $c000 based on the system variable BANKM.

Only works on 128K and compatible models.

**Danger:** If our program exceeds the address $c000 it may cause problems, use this function at your own risk.


## Memory banks
- $c000 > Bank 0 to Bank 7
- $8000 > Bank 2 (fixed)
- $4000 > Bank 5 (screen)
- $0000 > ROM

Banks 2 and 5 are permanently fixed at addresses $8000 and $4000, so it is not common to use them.
Banks 1, 3, 5 and 7 are banks in contention with the ULA, their use is not recommended in processes requiring maximum speed.


## Examples

```basic
#include "memorybank.bas"

DIM n AS UByte

' Fill banks with data
FOR n = 0 TO 7
    SetBank(n)
    PRINT AT n,0;"Bank: ";n;
    POKE $c000,n
    PRINT " > ";GetBank();
NEXT n

' Read banks
FOR n = 0 TO 7
    SetBank(n)
    PRINT AT n,15;PEEK($c000);
NEXT n
```

## See also
- [SetBank](setbank.md)
- [SetCodeBank](setcodebank.md)
