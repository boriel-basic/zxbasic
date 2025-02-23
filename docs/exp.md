# EXP

## Syntax

```
EXP(numericExpression)
```


## Description

Returns _e_ to the power of _numeric expression_ given, 
_e_ is a real number, which can be obtained with `EXP(1)`.

Both the argument and the result are of type `Float`.

## Examples

```basic
PRINT "e = "; EXP(1)
PRINT "e^2 = "; EXP(2)
```

## Remarks

*  This function is 100% Sinclair BASIC Compatible
*  If the given argument type is not float, it will be [converted](cast.md) to float before operating with it.

## See also

* [LN](ln.md)