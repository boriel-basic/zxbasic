#PLOT

##Syntax

```
PLOT x, y
```
 
or

``` 
PLOT <Attribute Modifiers>; x, y
```
Plots a _pixel_ at coordinates (x, y) (pixel column, pixel row). Coordinate (0, 0) designates bottom-left screen corner.

**PLOT** is enhanced in ZX BASIC to allow plotting in the last two screen rows (this was not possible in Sinclair BASIC). So now we have 16 lines more (192 in total). Sinclair BASIC only used top 176 scan-lines. This means that in Sinclair BASIC

```
PLOT x, y
```

must be translated to ZX BASIC as

```
PLOT x, y + 16
```

if you want your drawing to appear at the same vertical screen position Sinclair BASIC uses.

###Remarks

* This function is not strictly Sinclair BASIC compatible since it uses all 192 screen lines instead of top 176. If you translate **PLOT** & **DRAW** commands from Sinclair BASIC _as is_ your drawing will be _shifted down_ 16 pixels.

###See Also
* [DRAW](draw.md)
* [CIRCLE](circle.md)
