#SQR

##Syntax


```
SQR(numericExpression)
```

##Description

Returns the square root value of the given argument.
Argument must be a numeric expression, and is returned as type [float](types#float.md).

##Examples


```
REM Square Root value
PRINT "Root of a is "; SQR(a)
```
 

##Remarks
* This function is 100% Sinclair BASIC Compatible
* If the given argument type is not float, it will be [converted](cast.md) to float before operating with it.
* This function uses the ZX Spectrum ROM code to calculate. Note that the ZX Spectrum ROM is extremely inefficient at doing this calculation. If speed is an issue, and you can spare a few bytes, there are two functions in this wiki library to speed up square root calculations. [ The first](fsqrt.bas.md) is exactly as accurate as the ROM routine, but is about 6 times faster. [ The second](isqrt.bas.md) returns an integer result, and is 50-100 times faster.

##See also
* [Library](library.md)

