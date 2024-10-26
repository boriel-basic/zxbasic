# SCREEN

## Syntax


```
SCREEN$(row, col)
```

## Description

Returns a string with the character (if possible) located at the given screen coordinate (row, column).
The character in the screen must exactly match the one in the current font character set being used.

## Requirements

SCREEN is a library function to be included with the following command:


```
# include <screen.bas>
```

## Sample usage

```
# include <screen.bas>

PRINT AT 9, 10; "A"
LET c$ = SCREEN$(9, 10)
PRINT AT 0, 0; "The character at 9, 10 is "; c$
```

## Remarks

* This function extends the one in Sinclair BASIC (and it's compatible with it) since it also allows rows 22 and 23.
* When using _--sinclair_ cmd line parameter this function is already available (i.e. no _#include <screen.bas>_ sentence is needed)

## See also

* [ CSRLIN ](csrlin_.md)
* [ POS](pos_.md)
* [ AT ](../at.md)
