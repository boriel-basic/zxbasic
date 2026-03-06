# DRAW

The **DRAW** command is used to draw straight lines and circular arcs on the screen.

## Syntax

```
DRAW dx, dy [, arc]
```
or
```
DRAW <Attribute Modifiers>; dx, dy [, arc]
```

## Description
Draws a *straight line* starting from the current drawing position `(x, y)` to the new position `(x + dx, y + dy)`. The values `dx` and `dy` represent the relative horizontal and vertical distance from the current position.

The coordinate `(0, 0)` designates the bottom-left corner of the screen. After the command completes, the current drawing coordinates are updated to the last plotted position.

To set the initial drawing position, you can use the [PLOT](plot.md) command.

### ZX BASIC Enhancements
**DRAW** is enhanced in ZX BASIC to allow drawing across all 192 scan lines of the Spectrum screen. Original Sinclair BASIC only permitted drawing on the top 176 lines, reserving the bottom 16 lines for system use.

Because of this difference, programs ported from Sinclair BASIC will appear **shifted down by 16 pixels**. To maintain the same vertical screen position, you should add 16 to the Y-coordinate of the initial `PLOT` command:

**Sinclair BASIC code:**
```
PLOT x0, y0: DRAW dx, dy
```

**ZX BASIC equivalent (for same screen position):**
```
PLOT x0, y0 + 16: DRAW dx, dy
```

### Drawing Arcs
When used with three parameters, **DRAW** draws a circular arc from the current position to the relative target `(x + dx, y + dy)`.

```
DRAW dx, dy, arc
```

The `arc` parameter specifies the angle of the curve in radians.
* A positive `arc` value draws the curve turning to the left (counter-clockwise).
* A negative `arc` value draws the curve turning to the right (clockwise).

**Remark:** This routine may exhibit unusual behavior when using very large values for `arc`.

### Remarks

* **Fast Drawing**: This primitive uses Bresenham's algorithm for faster drawing instead of the Spectrum ROM implementation.
* **Compatibility**: This function is not strictly Sinclair BASIC compatible because it uses the full 192 screen lines. If you translate **PLOT**, **DRAW**, or **CIRCLE** commands from Sinclair BASIC *as is*, your drawing will be *shifted down* by 16 pixels.

### See Also
* [PLOT](plot.md)
* [CIRCLE](circle.md)
