' bounce_sd81.bas — SD81 Booster double buffer (dbuf) demo, port $E7
'
' ZX BASIC port of bounce.asm (SD81-Booster/EXAMPLES/DBUF), reworked for
' the zxbasic runtime:
'   - the screen ($C000), Superfast HiRes Spectrum mode and Chroma81
'     colour are already set up by tools/boot1.asm for every zx81sd
'     program -- no need to POKE 2043/2044/2045 or write to $7FEF here.
'   - screen + attributes are already cleared at program start by
'     runtime/bootstrap.asm -- no need to clear them here either.
'   - memory-mapped IO (POKE 2056/2057) is disabled by boot1.asm before
'     the compiled program starts, so the double buffer is controlled
'     through port $E7's pseudo-block-8 path (SD81DBufOn/SD81DBufOff,
'     see stdlib/dbuf.bas) instead of the classic POKE 2057.
'
' A 16x16 ball bounces around the screen. Each frame: wait for VSYNC,
' erase the ball, waste ~6ms on purpose (simulates heavy drawing that
' crosses the beam), move, redraw.
'   - dbuf ON  (green border): solid image, no flicker.
'   - dbuf OFF (red border):   visible flicker/tearing.
' SPACE toggles the double buffer live; M freezes/unfreezes movement;
' Q quits.
'
' This is also the first real test of the port $E7 pseudo-block-8 dbuf
' path (only the POKE 2057 path had been validated on real hardware
' before this): see stdlib/dbuf.bas for the front-buffer-block notes.

#include <dbuf.bas>

dim bally as ubyte
dim ballx as ubyte
dim dy as byte
dim dx as byte
dim moven as ubyte
dim dbufst as ubyte
dim k$ as string

bally = 80
ballx = 14
dy = 2
dx = 1
moven = 1
dbufst = 1

' PaintBall(y, x, fillVal): fills 16 rows x 2 bytes at screen row y,
' byte-column x, with fillVal (0 = erase, 255 = draw). Same pixel
' address formula as the Spectrum, but with $C0 as the screen's base
' high byte instead of Spectrum's $40 (zx81sd's screen is fixed at
' $C000, set once by boot1.asm).
sub PaintBall(y as ubyte, x as ubyte, fillVal as ubyte)
    asm
        PROC
        LOCAL PB_LOOP, PB_PIXAD, PB_DONE

        ld   a, (ix + 5)    ; y
        ld   d, a
        ld   a, (ix + 7)    ; x
        ld   e, a
        ld   a, (ix + 9)    ; fillVal
        ld   c, a
        ld   b, 16

PB_LOOP:
        push bc
        push de
        call PB_PIXAD
        ld   (hl), c
        inc  l
        ld   (hl), c
        pop  de
        pop  bc
        inc  d
        djnz PB_LOOP
        jr   PB_DONE

PB_PIXAD:
        ld   a, d
        and  $C0
        rrca
        rrca
        rrca
        ld   h, a
        ld   a, d
        and  7
        or   h
        or   $C0            ; screen base high byte ($C000)
        ld   h, a
        ld   a, d
        and  $38
        add  a, a
        add  a, a
        or   e
        ld   l, a
        ret

PB_DONE:
        ENDP
    end asm
end sub

' ~6ms busy loop at 3.25MHz: simulates a heavy redraw that crosses the
' video beam, so the difference between dbuf ON/OFF is visible.
sub Delay
    asm
        PROC
        LOCAL DL_LOOP

        ld   bc, 1024
DL_LOOP:
        dec  bc
        ld   a, b
        or   c
        jr   nz, DL_LOOP

        ENDP
    end asm
end sub

' On bounce, the position is left unchanged for this frame (matching
' bounce.asm) and only the direction flips; it moves next frame.
'
' Kept entirely in ubyte (8-bit, mod-256) arithmetic on purpose, same
' as bounce.asm's "add a,b / cp 177": mixing ubyte+byte and widening to
' integer sign-extends the 8-bit sum based on its own bit 7 (bally=126,
' dy=2 -> 8-bit sum 128 gets read as -128, not +128), which is wrong
' here since bally is genuinely unsigned. Comparing unsigned in ubyte
' space sidesteps that entirely.
sub Move
    dim newY as ubyte
    dim newX as ubyte

    if moven <> 0 then
        newY = bally + dy
        if newY >= 177 then
            dy = -dy
        else
            bally = newY
        end if

        newX = ballx + dx
        if newX >= 31 then
            dx = -dx
        else
            ballx = newX
        end if
    end if
end sub

' Returns 0 if Q was pressed (caller should quit), 1 otherwise.
' SPACE toggles dbuf live; M freezes/unfreezes movement.
function Keys() as ubyte
    k$ = INKEY$

    if k$ = " " then
        dbufst = 1 - dbufst
        if dbufst <> 0 then
            SD81DBufOn(5)
            border 4
        else
            SD81DBufOff()
            border 2
        end if
        do
        loop while INKEY$ <> ""
    end if

    if k$ = "m" or k$ = "M" then
        moven = 1 - moven
        do
        loop while INKEY$ <> ""
    end if

    if k$ = "q" or k$ = "Q" then
        return 0
    end if

    return 1
end function

SD81DBufOn(5)
border 4

do
    SD81WaitVSync()
    PaintBall(bally, ballx, 0)
    Delay
    Move
    PaintBall(bally, ballx, 255)
loop while Keys() <> 0

SD81DBufOff()
border 7
