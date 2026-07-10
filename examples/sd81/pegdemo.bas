' ----------------------------------------------------------------------
' pegdemo.bas — PEG (Programmable Effects Generator) demo
'
' The PEG is a small virtual machine inside the SD81 Booster's MCU: it
' runs sound-effect programs on its own, driving the AY registers
' directly, with zero Z80 CPU cost. Up to 3 threads (0-2) can run at
' once. See the SD81 Booster manual, Appendix B, for the instruction
' set; McuLoadPeg's raw byte format is documented in mcu.bas ("2 bytes
' per instruction, little-endian").
'
' This program below is a simple one-shot "beep": set AY channel A's
' tone period, enable tone on the mixer, set full volume, hold for
' ~200ms, then silence and halt.
'   LD  R0, $30   ; tone period A, low byte
'   LD  R1, $00   ; tone period A, high byte
'   LD  R7, $3E   ; mixer: tone A enabled, everything else disabled
'   LD  R8, $0F   ; channel A volume = max, no envelope
'   WAIT 200      ; hold for 200 ms
'   LD  R8, $00   ; silence
'   HALT
'
' NOTE: this exact byte encoding hasn't been confirmed on real hardware
' yet -- if it doesn't produce sound, double check the byte order
' against a working .PEB file or the peg.py assembler mentioned in the
' manual.
' ----------------------------------------------------------------------

#include <mcu.bas>
#include <input.bas>

dim beep$ as string

beep$ = chr($30) + chr($00) + _
        chr($00) + chr($01) + _
        chr($3E) + chr($07) + _
        chr($0F) + chr($08) + _
        chr($C8) + chr($90) + _
        chr($00) + chr($08) + _
        chr($10) + chr($A0)

print "Loading PEG program at address 0..."
McuLoadPeg(0, beep$)

print "Playing on thread 0..."
McuPlayPeg(0, 0)

pause 100

print "Stopping thread 0."
McuStopPeg(0)

print
print "Press a key..."
a$ = input(20)
