# ATN

## Syntax

```
ATN(numericExpression)
```


## Description

Returns the arc tangent value of the given argument.
Argument must be a numeric expression. Returned value type is [float](types.md#Float).

## Examples

```
REM Arc tangent value
PRINT "Arc Tangent value of a is "; ATN(a)
```

## Remarks

*  This function is 100% Sinclair BASIC Compatible
*  If the given argument type is not float, it will be [converted](cast.md) to float before operating with it.

## See also

* [COS](acs.md) and [ACS](asn.md)
* [SIN](sin.md) and [ASN](asn.md)
* [TAN](tan.md)
