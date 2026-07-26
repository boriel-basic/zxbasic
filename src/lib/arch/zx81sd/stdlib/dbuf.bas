' SD81 Booster — double buffer (present-blit) control, port $E7 pseudo-block 8.
'
' Hardware spec (SD81 Booster, ay author): while enabled, the video
' stops reading the live screen block (HFILE) and instead scans out a
' private front buffer inside the FPGA's own screen shadow RAM. On every
' vertical blanking period the hardware copies the live screen into that
' front buffer, so what's on screen is always a complete snapshot taken
' at the last VSYNC -- no tearing even if the program erases/redraws in
' the middle of a scan.
'
' Two control paths exist on real hardware: POKE 2057 (memory-mapped IO)
' and this port $E7 pseudo-block-8 path. zx81sd's boot (tools/boot1.asm)
' always disables memory-mapped IO (POKE 2056,0) and leaves the $E7
' mapper in full-paging mode before jumping to the compiled program, so
' every zx81sd binary is in exactly the state the port path needs -- the
' POKE 2057 path is NOT usable from zxbasic (memory-mapped IO is off).
'
' Front buffer block: this is NOT one of the program's own blocks 0-5
' (code/data, mapped via boot1.asm/vectors.asm) nor block 6 (the live
' screen, $C000) nor block 7 (data banking, see Map() in mcu.bas) -- the
' front buffer lives in the FPGA's private screen shadow RAM, addressed
' with its own independent 0-7 block index. The hardware spec recommends
' 4 or 5 and explicitly says to avoid 0-3 and 6-7.
'
' Untested on the port $E7 path as of this writing (the POKE 2057 path
' was the one validated on real hardware) -- this library is meant to be
' its first test. See examples/sd81/bounce_sd81.bas.

' Turns the double buffer ON. frontBlk: 0-7, see notes above (4 or 5
' recommended).
sub fastcall SD81DBufOn(frontBlk as ubyte)
    asm
        ; A = frontBlk (fastcall)
        and  7
        or   32             ; bit5 = enable
        ld   b, a
        ld   a, 8           ; pseudo-block 8 (D3=1, D2:0=0)
        ld   c, $E7
        out  (c), a
    end asm
end sub

' Turns the double buffer OFF.
sub SD81DBufOff()
    asm
        ld   b, 0
        ld   a, 8
        ld   c, $E7
        out  (c), a
    end asm
end sub

' Waits for the rising edge of VSYNC (bit 0 of port $AF): if currently
' inside the vsync pulse, waits for it to end, then waits for the next
' one to start. This is the point right after the double buffer's
' automatic blit finishes (the copy starts as soon as the visible area
' ends), so it's the right place to erase/redraw when using SD81DBufOn.
'
' Note: this is a different wait than VSYNC_TICK/PAUSE (which just waits
' for at least one pulse since the last read, using bits 6-1 as a pulse
' counter) -- this one specifically detects the edge to align with the
' double buffer's blit timing.
sub SD81WaitVSync()
    asm
        PROC
        LOCAL SDVS_INSIDE, SDVS_WAIT

SDVS_INSIDE:
        in   a, ($AF)
        rrca
        jr   c, SDVS_INSIDE   ; still inside the vsync pulse: wait for it to end

SDVS_WAIT:
        in   a, ($AF)
        rrca
        jr   nc, SDVS_WAIT    ; wait for the next pulse to start

        ENDP
    end asm
end sub
