# ON ... GOTO
## Syntax
```
ON <expression> GOTO <label0>, <label1>, <label2>, ..., <labelN>
ON <expression> GO TO <label0>, <label1>, <label2>, ..., <labelN>
```

Transfers control to one of a series of specified line numbers or labels based on the value of an expression.

### Parameters
- `<expression>`: An integer expression that determines which label to jump to. It can be any numeric expression.
- `<label0>, <label1>, <label2>, ..., <labelN>`: A comma-separated list of line numbers or labels. These are the destinations for control transfer based on the value of `<expression>`.

The value of expression is converted to a [uByte](types.md#integral) (Unsigned Byte), so, for example, a value of 256 will be converted to 0.
If the expression value is greater than the number of labels, this instruction will be ignored and the execution will continue normally.

> This sentence uses a **jump table** for faster execution.

### Example with ON ... GOTO
```BASIC
 5 REM Random value between [0..3] both included
10 LET X = INT(RND * 4)
20 ON X GOTO 50, 100, 150
30 PRINT "Invalid choice: "; X
40 GOTO 10
50 PRINT "You chose option 0"
60 END
100 PRINT "You chose option 1"
110 END
150 PRINT "You chose option 2"
160 END
```

In this example, 
 * if `X` is 0, the execution will jump to line 50
 * if `X` is 1, it will jump to line 100;
 * if `X` is 2, it will jump to line 150.
 * If `X` is outside this range, the `ON ... GOTO` sentence will be ignored. <br/>
   The program will print _"Invalid choice"_ and ask for input again.

## Remarks
- The `<expression>` is evaluated, and if it results in a value outside the range 0 to N (where N is the number of labels), no action is taken.
- `ON ... GOTO` is a structured programming alternative to multiple `IF...THEN...GOTO` statements.

## Compatibility
- This statement is not compatible Sinclair BASIC.

## See also
- [GO TO](goto.md)
- [GO SUB](gosub.md)
- [ON ... GO SUB](on_gosub.md)