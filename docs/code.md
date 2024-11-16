# CODE

## Syntax


```
code(<value>)
```

## Description

Returns the ASCII code of the first character of the given string value.
If the string is empty, the returned value is 0.
Returned value type is [UByte](types.md#UByte).

## Examples

```
REM ASCII CODE of "A"
PRINT "ASCII CODE of A is "; CODE("A")
LET a$ = ""
PRINT "ASCII CODE of emtpy string is "; CODE(a$)
```

## Remarks

* This function is 100% Sinclair BASIC Compatible

## See Also

* [ASC](library/asc.bas.md)
* [CHR](chr.md)
* [STR](str.md)
