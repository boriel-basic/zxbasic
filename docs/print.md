# PRINT

## Syntax

```
 PRINT [<item>][;]
```

## Description

`PRINT` is a sentence used to output information on the screen. The ZX Spectrum screen is divided in 24 rows (numbered
from 0 to 23), and 32 columns (numbered from 0 to 31). So it's composed of 24 x 32 = 96 cells. Cells are referred by
its coordinate (row, column), being (0, 0) the top-leftmost cell, and (23, 31) the bottom-rightmost one.

There's a _hidden cursor_ on the screen that points to the coordinate where the next character will be printed.
Each time something is printed, a _carriage return_ is also printed and the screen cursor is advanced to 
the next line (row):

```
PRINT "I'M ON ONE LINE"
PRINT "I'M ON THE NEXT ONE"
```

If you don't want this to happen, you can add a semicolon (;) at the end of the `PRINT` sentence, and the next
printed expression will still be on the same line:

```
PRINT "I'M ON ONE LINE";
PRINT "... AND I'M ALSO ON THE SAME LINE"
PRINT "AND I'M ON A NEW LINE"
```
Notice the first `PRINT` ends with a semicolon to avoid _carriage return_. Executing a single `PRINT` will just
advance the cursor to the next line.

> **NOTE**: when the cursor reaches the end of the screen, it will **scroll upwards** all rows 1 position.

Let's prints numbers from 0 to 25 and see what happens:

```
CLS: REM Clears screeen and puts the cursor at the top-leftmost corner
FOR i = 0 TO 25
  PRINT i
NEXT i
```
You'll see that number 0 and 1 are gone (they were shifted up and went out of the screen).

> **NOTE**: When the screen is cleared with [CLS](cls.md), the cursor is set to its default position (0, 0),
> that is, the top-leftmost screen corner.
    
`PRINT` can print everything that is a _single_ expression (also called an _item_).
That is, strings (like in the previous example), numbers, variable values, and array elements
(it can not print an entire array; that's not a `single` element but a collection):

For example:

```
LET a = 5
PRINT "Variable 'a' contains the value: ";
PRINT a
```

Indeed, if you want to chain several expressions one after another you can _chain_ them in a single PRINT sentence
using semicolons:
```
LET a = 5
PRINT "Variable 'a' contains the value: "; a
```

## Changing the print position
You can change the current _cursor_ position using the [AT](at.md) modifier:

```
PRINT AT 5, 0; "This message starts at ROW 5"
PRINT AT 10, 10; "This message starts at ROW 10, COLUMN 10"
```

Again, you can chain all `PRINT` _items_ using semicolon:

```
PRINT AT 5, 0; "ROW 5"; AT 10, 10; "ROW 10, COLUMN 10"
```

## Changing appearance
You can temporarily override the aspect of the items printed using them inline:

```
CLS
FOR i = 1 to 7
  PRINT AT i, 0; PAPER 0; INK i; "PRINT AT ROW "; i; " WITH INK "; i
NEXT i
```

See the related commands section for further info.

## Examples

```
REM Prints a letter in the 10th row of the screen moving from left to right
CLS
FOR i = 0 TO 31
  PRINT AT 10, i; "A"
  PAUSE 10
  PRINT AT 10, i; " ": REM Erases the letter
NEXT i
```


## Remarks

* This sentence is compatible with Sinclair BASIC but _expands_ it, since it allows printing at rows 22 and 23
  (all 24 rows are available to the programmer). Traditionally, Sinclair BASIC only allows to print at rows 0..21.
* You can use [ITALIC](italic.md) and [BOLD](bold.md) modifiers (not available in Sinclair BASIC)

## See also

* [CLS](cls.md)
* [AT](at.md)
* [PAPER](paper.md)
* [BORDER](border.md)
* [INVERSE](inverse.md)
* [INK](ink.md)
* [ITALIC](italic.md)
* [BOLD](bold.md)
* [OVER](over.md)
