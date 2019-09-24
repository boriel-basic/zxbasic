#SIN

##Syntax

```
SIN(numericExpression)
```

##Description

Returns the sine value of the given argument.
Argument must be a numeric expression in radians units. Returned value type is [float](types#float.md).

##Examples

```
REM Sine value
PRINT "Sine value of a is "; SIN(a)
```
 
##Remarks
*  This function is 100% Sinclair BASIC Compatible
*  If the given argument type is not float, it will be [converted](cast.md) to float before operating with it.

##See also

* [COS](cos.md) and [ACS](acs.md)
* [TAN](tan.md) and [ATN](atn.md)
* [ASN](asn.md)
*  Faster library option for lower accuracy trigonometry for games: [FSIN](library/fsin.bas.md)
