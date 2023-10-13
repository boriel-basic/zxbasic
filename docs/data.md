# DATA

## Syntax
```
 DATA <expression>[, <expression>, <expression>...]
```

**DATA** statement stores values to be retrieved using the [READ](read.md) sentence. These can be numerical or string expressions.
Instead of using INPUT() function or [LET](let.md) assignments, you can write a sequence (or several of them) of **DATA**
which might result in a compact and more readable code to initialize data variables.

**DATA** statements can be placed anywhere in the code, but they're usually located at the end for better readability.

## Example

```
FOR i = 1 TO 2
    READ a, b, c$

    PRINT "a: "; a
    PRINT "b: "; b
    PRINT "c: "; c
NEXT i

REM notice the a * a expression
DATA 2, a * a, "Hello"
DATA b * 5, 32, "World"
```

This will output:

```
 a: 2
 b: 4
 c: Hello
 a: 20
 b: 32
 c: World

```
Expressions are read and evaluated one by one. When a **DATA** line is finished, the next one in the listing will be read.
Traditionally if there's no more data to read, an _OUT of Data_ error happened. In ZX Basic, the read sequence restarts from the beginning.

## Remarks
* This statement is Sinclair BASIC compatible.

## See also
* [READ](read.md)
* [RESTORE](restore.md)
