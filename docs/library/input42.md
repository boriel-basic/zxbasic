# Input42.bas

## INPUT42

Simple INPUT routine (not as powerful as Sinclair BASIC's), but this one uses the PRINT42 routine.
Issues a cursor to the screen, waits for the user to type and returns the user's input through PRINT42 when the user presses ENTER.

## Syntax

```basic
A$ = INPUT42(MaxChars)
```
MaxChars is the number of characters the INPUT42 function will accept as a maximum. It is a UINTEGER and thus has a maximum value of 65535.

## Requirements

INPUT42 is a library function that must be included before it can be used. Use the following directive:

```
# include <input42.bas>
```

## Remarks

* Note that this function ALWAYS RETURNS A STRING, which is very different from Sinclair BASIC's INPUT statement.
* This function places the Input cursor at the last print position, not at the bottom of the screen. Remember that ZX Basic allows access to all 24 screen lines, so PRINT AT 24,0; sets the PRINT cursor to the bottom of the screen.
* Avoid recursive / multiple inclusion
* The input subroutine DOES NOT act like ZX Spectrum INPUT command
* Uses ZX SPECTRUM ROM

## See also

* [ INKEY ](../inkey.md)
* [ INPUT ](../input.md)
* [ PRINT42 ](print42.bas.md)
