# GO TO


## Syntax
```
GO TO <label>
GOTO <label>
```
Continues (jumps) the execution at the given label or line number.

This sentence exists just for compatibility with legacy BASIC
dialects. You should use [DO...LOOP](do.md), [FOR](for.md), [SUB](sub.md)
or [FUNCTION](function.md) instead.

You can't GOTO into a function or sub.

### Example with GO TO

```
10 GOTO 30
20 END
30 PRINT "This is executed before END"
40 GOTO 20
```

This will `This is executed before END` and then jump into
line 20, finishing the program.


## Remarks
* This statement is Sinclair BASIC compatible.

## See also
* [GO SUB](gosub.md)
