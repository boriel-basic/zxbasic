' ----------------------------------------------------------------------
' randomaccess.bas — Random file access via the SD81 Booster MCU
'
' Demonstrates the F_* handle-based commands in mcu.bas: F_OPEN,
' F_SEEK, F_READ, F_WRITE and F_CLOSE. Unlike McuLoad/McuSave (which
' always transfer the whole file), these let a program seek to an
' arbitrary offset and read or write just part of a file -- useful for
' things like save-game slots, tile/level data files, or databases too
' big to keep fully in RAM.
' ----------------------------------------------------------------------

#include <mcu.bas>
#include <input.bas>

dim h as ubyte
dim st as ubyte
dim buf(63) as ubyte
dim i as uinteger
dim ok as ubyte

print "Creating a 64-byte test file..."
for i = 0 to 63
    poke @buf(0) + i, cast(ubyte, 200 - i)
next i
st = McuSave("RNDACC.BIN", @buf(0), 64)
print "SAVE: status "; st

print "Opening it..."
h = McuFOpenZx("RNDACC.BIN")
print "F_OPEN: handle "; h

print "Seeking to offset 32 and reading 8 bytes..."
st = McuFSeek(h, 32)
for i = 0 to 7
    poke @buf(0) + i, 0
next i
st = McuFRead(h, @buf(0), 8)
ok = 1
for i = 0 to 7
    if peek(@buf(0) + i) <> 200 - (32 + i) then
        ok = 0
    end if
next i
if ok = 1 then
    print "Read back correctly."
else
    print "Read verification FAILED."
end if

print "Overwriting the first 4 bytes and reading them back..."
st = McuFSeek(h, 0)
poke @buf(32), 11
poke @buf(33), 22
poke @buf(34), 33
poke @buf(35), 44
st = McuFWrite(h, @buf(32), 4)
st = McuFSeek(h, 0)
st = McuFRead(h, @buf(40), 4)
if peek(@buf(40)) = 11 and peek(@buf(43)) = 44 then
    print "Overwrite verified."
else
    print "Overwrite verification FAILED."
end if

print "F_CLOSE: status "; McuFClose(h)
print "Deleting test file: status "; McuDel("RNDACC.BIN")

print
print "Press a key..."
a$ = input(20)
