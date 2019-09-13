#TAN


##Syntax

```
TAN(numericExpression)
```
 

##Description

Returns the tangent value of the given argument.
Argument must be a numeric expression in radians units. Returned value type is [float](types#float.md).

##Examples

```
REM Tangent value
PRINT "Tangent value of a is "; TAN(a)
```
 

##Remarks

* This function is 100% Sinclair BASIC Compatible
* If the given argument type is not float, it will be [converted](cast.md) to float before operating with it.

##See also

* [SIN](sin.md) and [ASN](asn.md)
* [COS](cos.md) and [ACS](acs.md)
* [ATN](atn.md)
* Faster library option for lower accuracy trigonometry for games: [FTAN](fsin.bas.md)
