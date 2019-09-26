#Print42.bas

The 42 column printing routine allows text to be 6 pixels wide instead of 8.
It is NOT proportional printing, but this is still useful for lining things up in columns.

This routine has been adopted as an included library - so you may include it with

```
#include <print42.bas>
```

##Usage

```
printat42(y,x)
```

Moves the print42 system's print cursor to row Y, column X. Note that `0 <= x <= 41` - that is the range of values
for X can be up to 41. The range of values for Y is the normal 0-23.

```
printat42(STRING)
```

Prints the string to the screen at the current Print42 co-ordinates. It does so in the current permanent colours.

NOTE: The ZX Spectrum's attribute system is encoded into the hardware as a 32 character grid. Print42 does its best,
but changing the `paper`/`bright`/`flash` colour from the background is likely to look imperfect as the attribute blocks
cannot line up well with the pixel blocks.
