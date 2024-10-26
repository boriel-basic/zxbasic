# CHR

## Syntax


```
chr(<value>)
chr(<value1>[, <valueN>])
chr$(<value>)
chr$(<value1>[, <valueN>])
```

## Description

Returns a string containing the ASCII characters whose codes are the given values.
The arguments must be a numeric expression and, unlike Sinclair BASIC, parenthesis
are mandatory. Returned value type is [string](types.md#String).

## Examples

```
REM Char for ASCII code 65 is 'A'
PRINT "CHR(65) is "; CHR(65)
```

This function is extended, and several values can be given at once. The result is a concatenation of all the given values:

```
REM Chars for ASCII codes from 65 to 67 ('A' to 'C')
PRINT "CHR(65, 66, 67) is "; CHR(65, 66, 67)
```

The following lines are both equivalent, but the 2<sup>nd</sup> is faster and takes less memory:


```
REM These two sentences are equivalent
PRINT "CHR(65, 66, 67) is "; CHR(65) + CHR(66) + CHR(67)
PRINT "CHR(65, 66, 67) is "; CHR(65, 66, 67)
```


In fact, if the compiler detects the programmer is using `CHR(x) + CHR(y)`, it might compile it as
`CHR(x, y)` to perform such optimization.

## Remarks

* This function is 100% Sinclair BASIC Compatible, but parenthesis are mandatory
* This function is expanded comparing to the original Sinclair BASIC
* As with other functions and variables, the trailing `$` can be omitted.

## See Also

* [CODE](code.md)
* [STR](str.md)
* [VAL](val.md)
