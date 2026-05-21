# TAB

## Syntax
```
PRINT TAB <value>;
```

`TAB` is not a statement, but a [PRINT](print.md) modifier. It is used to move the cursor to a specific column.
The ZX Spectrum screen has 32 columns, numbered from 0 to 31.

When `TAB` is used, the cursor moves to the specified column. If the current position is already past the requested column, the cursor moves to that column on the next line.


```
PRINT TAB 10; "Hello"
```

The above example will print "Hello" starting at column 10 of the current row.

## Remarks
* This modifier is Sinclair BASIC compatible.
* If the value is 32 or more, it is taken modulo 32.

## See also
* [PRINT](print.md)
* [AT](at.md)
* [POS](library/pos.md)
* [CSRLIN](library/csrlin.md)
