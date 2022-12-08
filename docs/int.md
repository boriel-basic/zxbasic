# INT

## Syntax


```
INT(numericExpression)
```


## Description

Rounds the given expression by truncation. This function behaves
exactly like the one in the Sinclair BASIC ROM.
Argument must be a numeric expression. Returned value is a long (32 bit) number
that will be casted (converted) to the required type.

## Examples


```
REM Round by truncation
LET a = 1.5
PRINT "Int value of a is "; INT(a)
REM 'Will print 1
```


## Remarks

* This function is 100% Sinclair BASIC Compatible

