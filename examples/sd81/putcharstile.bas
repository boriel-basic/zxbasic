' ----------------------------------------------------------------------
' putcharstile.bas — putchars.bas (putChars/paint) and puttile.bas (putTile)
'
' putchars.bas: audited, no ROM dependency (everything reads
' SCREEN_ADDR/SCREEN_ATTR_ADDR dynamically) -- no zx81sd override
' needed, used as-is from the shared zx48k stdlib.
'
' puttile.bas: DID need a zx81sd override -- the original hardcodes the
' screen/attribute base as immediate constants (add a,64 / add a,88,
' the Spectrum ROM's fixed $4000/$5800 high bytes) instead of reading
' SCREEN_ADDR/SCREEN_ATTR_ADDR. See src/lib/arch/zx81sd/stdlib/puttile.bas.
' ----------------------------------------------------------------------

#include <putchars.bas>
#include <puttile.bas>
#include <input.bas>

dim i as ubyte
dim charData(95) as ubyte
dim tileData(35) as ubyte

' 12 character cells (4 wide x 3 tall), 8 bytes each: a houndstooth fill
for i = 0 to 95
    poke @charData(0) + i, 170
next i

' 16x16 tile: 16 pixel-rows (2 bytes each, one per column) + top/bottom attrs
for i = 0 to 15
    poke @tileData(0) + i * 2, 255
    poke @tileData(0) + i * 2 + 1, 129
next i
poke @tileData(0) + 32, 56
poke @tileData(0) + 33, 56
poke @tileData(0) + 34, 63
poke @tileData(0) + 35, 63

ink 7: paper 1: cls

putChars(1, 1, 4, 3, @charData(0))
paint(6, 1, 4, 3, 71)

putTile(10, 10, @tileData(0))

' fixed-row PRINT away from the last screen row: avoids triggering a
' scroll (input()'s own cursor handling can push past row 23) that
' would shift the drawing above right before you get to look at it
print at 20, 0; "putChars/paint/putTile - press a key";
a$ = input(20)
