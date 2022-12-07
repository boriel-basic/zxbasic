# COS

## Syntax

```
COS(numericExpression)
```
 

## Description

Returns the cosine value of the given argument.
Argument must be a numeric expression in radians units. Returned value type is [float](types.md#Float).

## Examples

```
REM Cosine value
PRINT "Cosine value of a is "; COS(a)
```
 

## Remarks

*  This function is 100% Sinclair BASIC Compatible
*  If the given argument type is not float, it will be [converted](cast.md) to float before operating with it.

## See also

* [SIN](sin.md) and [ASN](asn.md)
* [TAN](tan.md) and [ATN](atn.md)
* [ACS](acs.md)
*  Faster library option for lower accuracy trigonometry for games: [FCOS](library/fsin.bas.md)

