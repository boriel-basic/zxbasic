# Library

## Library of Routines and Functions

This is a list of additions to the language that have been produced. They extend the functionality of the compiler by
effectively adding reserved words to the language. At their heart, they are all SUB or FUNCTION sets.

For the standard library go to the [standard library](library/stdlib.md) page.


---
## Non-standard libraries

These ones might not be bundled yet with ZX Basic (mostly due to lack of time). If so, you have
to copy the listing shown in this wiki and create the .bas file yourself, as explained in the following
section.

### How to Include a Library Function
You can either copy and paste the `SUB` or `FUNCTION` into your code, or, perhaps more easily,
save the text as the recommended name (e.g. fSqrt.bas) and use `#include "fSqrt.bas"` at the start of the program.
Note that the file has to be in the same folder or directory as the original in order for the compiler to find it.
If the code is included in the ZX Basic standard library, this is mentioned in the description.
It's then possible to add the code simply with a `#include` directive.

#### Maths Library
* [distance.bas](library/distance.bas.md)
<br />Fast distance calculation - SQR(x<sup>2</sup> + y<sup>2</sup>) - using taylor series expansion.
Accuracy tends to drop as x and y get large, but is about 5 times faster even than using iSqrt
(and about 750 times faster than using the ROM sqr function).

* [Faster Trigonometric Functions - fSin, fCos, fTan](library/fsin.bas.md)
<br />Sin giving you a headache? At the cost of a few bytes, here are faster and less accurate versions for quick and
dirty games calculations.

* [fSqrt.bas](library/fsqrt.bas.md)
<br />SQR too slow? Here's a faster (and completely accurate - at least as accurate as Sinclair Basic) replacement for
the internal SQR function.

* [iSqrt.bas](library/isqrt.bas.md)
<br />[fSqrt.bas](library/fsqrt.bas.md) still too slow? Don't need _quite_ so accurate an answer? Try Integer Square roots!

* [randomStream.bas](library/randomstream.bas.md)
<br />A random stream generator. Fast and efficient. ZX Basic does use this generator, but it's locked to float output.
Here are some alternative functions using faster integer and fixed output.

#### Graphics Library
* [attrAddress.bas](library/attraddress.md)
<br /> Function to get the attribute address for a given X-Y character co-ordinate.

* [clearBox.bas](library/clearbox.md)
<br /> Sub to clear a subset of the screen - a window defined with a character box.

* [crslin.bas](library/csrlin.md)
<br /> Function to get the current cursor vertical co-ordinate.

* [fastPlot.bas](library/fastplot.md)
<br /> Routine to plot a pixel on screen (without attributes - speed optimized)

* [HRPrint.bas](library/hrprint.bas.md)
<br /> High Resolution Print<br /> Subroutine to print characters at any pixel level position on the screen,
instead of just character positions. (Rather slow for sprites, but fine if speed isn't needed)

* [HRPrintFast.bas](library/hrprintfast.bas.md)
<br /> High Resolution Print<br /> Subroutine to print characters at any pixel level position on the screen,
instead of just character positions. (20% faster per character, but much larger version using lookup tables)

* [hMirror.bas](library/hmirror.bas.md)
<br /> Function to mirror the bits in a byte - the basis of printing, say a left facing sprite,
if all you have are right facing graphics stored.

* [pos.bas](library/pos.md)
<br /> Function to get the current cursor horizontal co-ordinate.

* [windowPaint.bas](library/windowpaint.md)
<br /> Set attributes in a rectangle without changing the bitmap.

* [putchars.bas](library/putchars.bas.md)
<br /> Subroutines to put graphics data to the screen in a block. Also contains routines for attribute painting as a
block. Passable for character based sprites.

* [scrAddress.bas](library/scraddress.md)
<br /> Function to get the top screen address for a given X-Y character co-ordinate.

* [putTile.bas](library/puttile.md)
<br /> Subroutine to paint a 2X2 character tile to the screen from a given data address, with attributes.
Uses PUSH/POP to the screen memory for speed.

* [pixelScroll.bas](library/pixelscroll.md)
<br /> Subroutines to scroll the screen by a specified number of pixel rows. (No attribute scroll)

* [windowScrollUP.bas](library/windowscrollup.md)
<br /> Subroutine to character scroll a window of screen - good for that sidebar of information.
Keep status updates scrolling in and sliding up without affecting the game window.

* [windowAttrScrollUP.bas](library/windowattrscrollup.md)
<br /> Subroutine to character scroll the attributes of a window of screen - really a handy addendum utility
for [windowScrollUP.bas](library/windowscrollup.md)

#### Text Handling Library

* [asc.bas](library/asc.bas.md)
<br /> Ascii Code of a character in a string. Compatible with FreeBasic

* [doubleSizePrint.bas](library/doublesizeprint.bas.md)
<br /> Prints to the screen with Double Size Characters

* [HRPrint.bas](library/hrprint.bas.md)
<br /> High Resolution Print<br /> Subroutine to print characters at any pixel level position on the screen,
instead of just character positions. (Rather slow for sprites, but fine if speed isn't needed)

* [propPrint.bas](library/propprint.bas.md)
<br /> Need characters to look more professional? LCD has weighed in with a Proportional Printing routine -
and one that lets you set text position with Pixel accuracy!

* [print42.bas](library/print42.bas.md)
<br /> Need more screen space? You could try the 42 Character Printing routine. Text still lines up in columns,
and attributes are allowed (with limitations).

* [print64.bas](library/print64.bas.md)
<br /> Need even MORE screen space? Here's a 64 characters per line Subroutine. Works in a very similar way to print42,
with printat64 and print64 subs.

* [Print64x32.bas](library/print64x32.bas.md)
<br /> What, just 64 chars to a line not enough? This is 64X32 Character printing.
Will print 64 characters to a line (grid, not proportional), and 32 lines of text to a screen.
Upping the standard 768 character screen to 2048 characters of text on one screen at once.
Works in a similar way to print42. This version uses screen tables.

####Compression / Decompression Library

* [megaLZDepack.bas](library/megalz.bas.md)
<br /> Routine wrapping the megaLZ decompression algorithm.

* [zx0](library/zx0.md)
<br /> Routine wrapping the ZX0 decompression algorithm.
