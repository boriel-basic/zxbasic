#VAL

##Syntax


```
VAL(<string value>)
```

##Description

Converts the given numeric string value into its numeric value. It's the opposite of [STR](str.md).
If the string can be converted into a number, [PEEK](peek.md) 23610 (ROM ERR_NR variable) will return 255 (_Ok_).

On the other side, if expression cannot be parsed (i.e. it's not a valid number expression), 0 will be returned,
and [PEEK](peek.md) 23610 (ROM ERR_NR variable) will return 9 (_Invalid Argument_).

Returned value type is [Float](types.md#float).

##Examples

```
REM Convert numeric expression to value
LET a$ = "-55.3e-1"
PRINT "Value of "; a$; " is "; VAL(a$)
LET a$ = "aaa"
PRINT "Numeric value of "; a$; " is "; VAL(a$): REM prints 0
```

##Remarks

* This function is 100% Sinclair BASIC Compatible

##See Also

* [CHR](chr.md)
* [CODE](code.md)  
* [STR](str.md)
