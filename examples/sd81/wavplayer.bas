' ----------------------------------------------------------------------
' wavplayer.bas — WAV audio playback via the SD81 Booster MCU
'
' The MCU's LOAD command (cmd 9, wrapped here as McuLoad) recognises
' the .WAV extension automatically: instead of loading the file into
' memory it plays it directly (uncompressed PCM, 8-bit mono, 11025 Hz
' per the manual). McuLoad returns 0 bytes in that case; the real
' result is in McuStatus.
'
' Change WAV_NAME below to a file that actually exists on your SD card
' (with or without the .WAV extension).
' ----------------------------------------------------------------------

#include <mcu.bas>
#include <input.bas>

const WAV_NAME as string = "DEMO.WAV"

print "Playing "; WAV_NAME; " ..."
McuLoad(WAV_NAME, 0)
print "Done. MCU status: "; McuStatus

print
print "Press a key..."
a$ = input(20)
