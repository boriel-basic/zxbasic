# OUT


## Syntax

```
OUT <port number>, <value>
```
 

## Description

Sends the byte value to the given port.
Arguments must be a numeric expressions. Port will be converted to `UInteger`
and value will be truncated to `UByte`.

## Examples

```
REM Port 254
DIM i AS UInteger
CLS

FOR i = 1 to 10000
  OUT 254, i
NEXT
```
 

## Remarks

* This function is 100% Sinclair BASIC Compatible
* If the given port is not of type`UInteger`, it will be [converted](cast.md) to `UInteger` before operating with it.
* If the given value is not of type`Ubyte`, it will be [converted](cast.md) to `UByte` before operating with it.


## See also

* [IN](in.md)
