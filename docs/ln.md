# LN

## Syntax

```
LN(numericExpression)
```


## Description

Returns the Natural Logarithm of the _numeric expression given_.
A natural logarithm is a logarithm in base _e_ (_e_ value can be
obtained with `EXP(1)`).

Both the argument and the result are of type `Float`.

## Examples

```basic
PRINT "LN(10) is "; LN(10)
```

You can compute the logarithm in any `base` dividing `LN(x)` by `LN(base)`:

```basic
PRINT "LN2(8) is "; LN(8) / LN(2) : REM Base 2 Logarithm
PRINT "LOG(100) is "; LN(100) / LN(10) : REM Base 10 Logarithm
```


## Remarks

*  This function is 100% Sinclair BASIC Compatible
*  If the given argument type is not float, it will be [converted](cast.md) to float before operating with it.

## See also

* [EXP](exp.md)