' ----------------------------------------------------------------------
' filesystem.bas — SD81 Booster MCU file/directory commands
'
' Demonstrates the filesystem-management wrappers in mcu.bas: PWD, CD,
' DIR, MKDIR/RMDIR, DEL, COPY/MOVE and FREE. All of them return the
' MCU's status byte (0 = success); see the manual's error table for
' the rest of the codes.
' ----------------------------------------------------------------------

#include <mcu.bas>
#include <input.bas>

dim st as ubyte
dim buf(15) as ubyte
dim i as ubyte

print "SD81 MCU version: "; McuVersion()
print

print "Current dir: "; McuPwd()

print "CD /: "; McuCd("/")
print "DIR *.*:"
McuDirPrint("*.*")
print

print "MKDIR /SD81DEMO: "; McuMkdir("/SD81DEMO")
print "CD /SD81DEMO: "; McuCd("/SD81DEMO")
print "Current dir: "; McuPwd()

' a tiny 16-byte file, just to have something to copy/move/delete
for i = 0 to 15
    poke @buf(0) + i, i
next i
st = McuSave("DEMO.BIN", @buf(0), 16)
print "SAVE DEMO.BIN: "; st

print "COPY DEMO.BIN -> COPY.BIN: "; McuCopy("DEMO.BIN", "COPY.BIN")
print "MOVE COPY.BIN -> RENAMED.BIN: "; McuMove("COPY.BIN", "RENAMED.BIN")

print "DIR *.*:"
McuDirPrint("*.*")

print "DEL DEMO.BIN: "; McuDel("DEMO.BIN")
print "DEL RENAMED.BIN: "; McuDel("RENAMED.BIN")

print "CD /: "; McuCd("/")
print "RMDIR /SD81DEMO: "; McuRmdir("/SD81DEMO")

st = McuFree()
print "FREE: "; McuFreeFreeKb; "/"; McuFreeTotalKb; " KB, status "; st

print
print "Press a key..."
a$ = input(20)
