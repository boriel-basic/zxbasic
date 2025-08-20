# IN


## Syntax

```
IN <port number>
```
 

## Description

Returns the byte value read in the given port.
Argument must be a numeric expression. Returned value type is [Ubyte](types.md#integral).

## Examples

```
REM Port 254
DIM i AS UInteger
CLS
PRINT "PRESS ANY KEY TO CHANGE THE READ VALUE"

FOR i = 1 to 10000
  PRINT AT 10, 0; IN 254;
NEXT
```
 

## Remarks

* This function is 100% Sinclair BASIC Compatible
* If the given argument type is not `UInteger`, it will be [converted](cast.md) to `UInteger` before operating with it.

## See also

* [OUT](out.md)
