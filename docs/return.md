# RETURN


## Syntax
```
RETURN [<expr>]
```
**RETURN** statement is used in 3 cases:

1. When returning from a [GO SUB](gosub.md) sentence
2. When returning (exiting) from a [SUB](sub.md) (a subroutine)
3. When returning (exiting) from a [FUNCTION](function.md). In this case a return value must be specified.


Returns in the global scope (that is, outside any function or sub) are treated as return from [GO SUB](gosub.md).
Otherwise they are considered as returning from the function or sub they are into.

> **WARNING**: Using RETURN in global scope without a GOSUB will mostly crash your program. <br>
> Use `--stack-check` if you suspect you have this bug, to detect it.

### Example with GO SUB

```
10 LET number = 10
20 GOSUB 1000 : REM calls the subroutine
30 LET number = 20
40 GOSUB 1000 : REM calls the subroutine again
100  END : REM the program must end here to avoid entering the subroutine without using GOSUB
1000 REM Subroutine that prints number + 1
1010 PRINT "number + 1 is "; number + 1
1020 RETURN : REM return to the caller
```

This will output:

```
number + 1 is 11
number + 1 is 21
```

## Remarks
* This statement is Sinclair BASIC compatible.

## See also
* [GO SUB](gosub.md)
* [FUNCTION](function.md)
* [SUB](sub.md)
