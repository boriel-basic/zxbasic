# SGN

## Syntax
```basic
SGN(expression)
```

## Description

Returns the sign of a numeric expression as follows:
* -1 if the number is negative
* 0 if the number is zero
* 1 if the number is positive

The returned value type is [byte](types.md#Integral).

## Examples

```basic
REM Print sign of different numbers
PRINT "Sign of -5 is "; SGN(-5) ' Prints -1
PRINT "Sign of 0 is "; SGN(0) ' Prints 0
PRINT "Sign of 3.14 is "; SGN(3.14) ' Prints 1
```

## Remarks

* This function is 100% Sinclair BASIC Compatible
* If the argument is an unsigned value, the result will always be either 0 or 1
* Using SGN with string expressions will result in a compile-time error

## See also

* [ABS](abs.md)
