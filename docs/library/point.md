# POINT

## Syntax


```
POINT(x, y)
```

## Description

Returns 1 if the pixel at coordinates (x, y) is set. 0 if it is not.

## Requirements

POINT is a library function to be included with the following command:


```
# include <point.bas>
```

## Sample usage

```basic
# include <point.bas>

PLOT 10, 10
PRINT "Point at (10, 10) is "; POINT(10, 10): REM 1
PRINT "Point at (15, 15) is "; POINT(15, 15): REM 0
```

## Remarks

* This function extends the one in Sinclair BASIC (and it's compatible with it) since it also allows rows 22 and 23.
* When using `--sinclair` cmd line parameter this function is already available (i.e. no `#include <point.bas>` sentence is needed)

## See also

* [ AT ](../at.md)
* [ CSRLIN ](csrlin.md)
* [ SCREEN ](screen.md)
* [ POS](pos.md)
