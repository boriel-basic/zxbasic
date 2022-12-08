# INPUT

Issues a cursor to the screen, waits for the user to type and returns the user's input when the user presses ENTER.

## Syntax
```
variable = INPUT(max_length)
```
Max_length is the number of characters the INPUT function will accept as a maximum.

## Requirements

INPUT is a library function that must be included before it can be used. Use the following directive:

```
#include <input.bas>
```

## Remarks
* This function is similar, but not equivalent to the INPUT statement available in Sinclair BASIC.
* Note that this function ALWAYS RETURNS A STRING, which is very different from Sinclair BASIC's INPUT statement.
* This function places the Input cursor at the last print position, not at the bottom of the screen. Remember that ZX Basic allows access to all 24 screen lines, so PRINT AT 24,0; sets the PRINT cursor to the bottom of the screen.

## See also

* [ INKEY ](inkey.md)
