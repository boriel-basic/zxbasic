# HEX/HEX16/HEX8

## Syntax


```basic
string32 = hex(n32)
string16 = hex(n16)
string8 = hex(n8)
```
Where `n32` is a 32-bit ULONG, `n16` is a 16-bit UINTEGER and `n8` is an 8-bit UBYTE.

## Description

* HEX:
Takes one _32_ bit unsigned integer number and returns an 8 chars str containing the HEX string representation.
* HEX16:
Takes one _16_ bit unsigned integer number and returns a 4 chars str containing the HEX string representation.
* HEX8:
Takes one _8_ bit unsigned integer number and returns a 2 chars str containing the HEX string representation.

## Requirements

HEX, HEX16 and HEX8 can be included with the following command:

```
#include <hex.bas>
```

## See also

