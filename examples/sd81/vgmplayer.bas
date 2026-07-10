' ----------------------------------------------------------------------
' vgmplayer.bas — VGM music playback via the SD81 Booster MCU
'
' The MCU's built-in VGM player runs entirely in the background (only
' AY-3-8910/8912 data is supported): the Z80 program keeps running
' while the tune plays. McuPlayVgm() opens/prepares the file (adding
' .vgm if no extension is given); playback only actually starts once
' McuContVgm() is called.
'
' Change VGM_NAME below to a file that actually exists on your SD card.
' ----------------------------------------------------------------------

#include <mcu.bas>
#include <input.bas>

const VGM_NAME as string = "MUSIC.VGM"

dim st as ubyte
dim i as ubyte

print "Loading "; VGM_NAME; "..."
st = McuPlayVgm(VGM_NAME)
print "MCU status: "; st

print "Starting playback..."
McuContVgm()

' let it play for a few seconds while the Z80 keeps doing its own thing
for i = 1 to 5
    print "playing... "; i
    pause 50
next i

print "Pausing 2 seconds..."
McuPauseVgm()
pause 100
print "Resuming..."
McuContVgm()

for i = 1 to 5
    print "playing... "; i
    pause 50
next i

print "Stopping."
McuStopVgm()

print
print "Press a key..."
a$ = input(20)
