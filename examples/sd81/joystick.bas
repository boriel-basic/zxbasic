' ----------------------------------------------------------------------
' joystick.bas — Programmable joystick via the SD81 Booster MCU
'
' The SD81 Booster maps a physical joystick to keypresses. Joy(keys)
' (joy.bas, cmd 21) configures that mapping: keys must be exactly 5
' characters, in order UP, DOWN, LEFT, RIGHT, FIRE. Letters (any case),
' digits and space are valid; space means "no key" for that direction.
' Returns the MCU's status byte (0 = OK, 14 = invalid parameter).
'
' Once configured, the joystick just behaves like a keyboard: read it
' with INKEY$/INPUT as usual.
' ----------------------------------------------------------------------

#include <joy.bas>

dim st as ubyte
dim k$ as string

' classic "QAOP + space" layout
st = Joy("QAOPM")
print "Joy(QAOPM) -> status "; st

print "Move the joystick (BREAK to exit)"
do
    k$ = inkey$
    if k$ <> "" then
        print k$;
    end if
loop
