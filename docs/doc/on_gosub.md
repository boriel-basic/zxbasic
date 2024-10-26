# ON ... GOSUB

## Syntax
```
ON <expression> GOSUB <label0>, <label1>, <label2>, ..., <labelN>
ON <expression> GO SUB <label0>, <label1>, <label2>, ..., <labelN>
```

Transfers control to one of a series of specified line numbers or labels based on the value of an expression. This statement expects a `RETURN` statement in the subroutine to return control to the line following the `ON ... GOSUB` statement.

> This statement uses a **jump table** for faster execution.

### Parameters
- `<expression>`: An integer expression that determines which label to jump to. It can be any numeric expression.
- `<label0>, <label1>, <label2>, ..., <labelN>`: A comma-separated list of line numbers or labels.
  These are the destinations for control transfer based on the value of `<expression>`.

The value of `<expression>` is converted to a [uByte](types.md#integral) (Unsigned Byte), so,
for example, a value of 256 will be converted to 0.
If the `<expression>` value is greater than the number of labels,
this instruction will be ignored and the execution will continue normally.

### Example with ON ... GOSUB
```BASIC
 5 REM Random value between [0..3] both included
10 LET X = INT(RND * 4): LET ok = 0
20 ON X GOSUB 50, 100, 150: IF ok THEN END
30 PRINT "Invalid choice: "; X
40 GOTO 10
50 PRINT "You chose option 0": LET ok = 1
60 RETURN
100 PRINT "You chose option 1": LET ok = 1
110 RETURN
150 PRINT "You chose option 2": LET ok = 1
160 RETURN
```

In this example:
 * If `X` is 0, the execution will jump to line 50.
 * If `X` is 1, it will jump to line 100.
 * If `X` is 2, it will jump to line 150.

In each block, after executing the corresponding print statement, the program sets the `ok` variable to 1, indicating a valid choice. Then, the `RETURN` statement returns control to the line following the `ON ... GOSUB` statement.

## Remarks
- The `<expression>` is evaluated, and if it results in a value outside the range 0 to N (where N is the number of labels), no action is taken.
- `ON ... GOSUB` is a structured programming alternative to multiple `IF...THEN...GOSUB` statements.

## Compatibility
- This statement is not compatible with Sinclair BASIC.

## See also
- [GO TO](goto.md)
- [GO SUB](gosub.md)
- [ON ... GOTO](on_goto.md)
