#GO SUB


##Syntax
```
GO SUB <label>
GOSUB <label>
```
Continues the execution at the given label or line number.
The current execution point is pushed (stored) onto the stack,
to be recovered later.

When a [RETURN](return.md) is found and executed, the previous
execution point is popped out (recovered) from the stack and
continues just after the GO SUB. This is a way to create simple
subroutines.

This sentence exists just for compatibility with legacy BASIC
dialects. You should use [SUB](sub.md) or [FUNCTION](function.md) instead.

GO SUB cannot be used within neither subroutines nor functions.
You can't GOSUB into a function or sub. So GOSUB is limited to
global [scope](scope.md)

> **WARNING**: Using GO SUB continuously without returning with
> RETURN will eventually fill the stack (stack overflow) and crash
> your program.

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


##Remarks
* This statement is Sinclair BASIC compatible.
* GO SUB cannot be used within subrutines nor functions.

##See also
* [RETURN](return.md)
* [FUNCTION](function.md)
* [SUB](sub.md)
