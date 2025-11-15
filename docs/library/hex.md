# HEX/HEX16/HEX8

## Syntax


```basic
A$ = hex(n32)
B$ = hex(n16)
C$ = hex(n8)
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

## Remarks

* This function is not available in Sinclair BASIC.
* Avoid recursive / multiple inclusion when calling this function.
* HEX16 ad HEX8 both call HEX to perform conversion, but differ in the size of the string they return.

## See also

