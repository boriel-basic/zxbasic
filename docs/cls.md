# CLS

## Syntax

```
 CLS
```

## Description

`CLS` is short for *CLear Screen*, and will do just that: it will clear the screen, setting the background
with the current [PAPER](paper.md) color, and placing the Screen Cursor at (0, 0) - screen top-leftmost corner.


## Examples

```
REM sets the screen black, and INK white
BORDER 0: PAPER 0: INK 7
CLS
PRINT "White text on black background"
```


## Remarks

* This sentence is compatible with Sinclair BASIC 

## See also

* [PRINT](print.md)
* [AT](at.md)
* [PAPER](paper.md)
* [BORDER](border.md)
* [INVERSE](inverse.md)
* [INK](ink.md)
* [ITALIC](italic.md)
* [BOLD](bold.md)
* [OVER](over.md)
