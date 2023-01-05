' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2008-2023
' by Paul Fisher (a.k.a. BritLion) <http://www.zxbasic.net>
' ----------------------------------------------------------------

#ifndef __LIBRARY_PUTTILE__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_PUTTILE__

#pragma push(case_insensitive)
#pragma case_insensitive = True


' ----------------------------------------------------------------
' SUB putTile
'
' Routine to place a 16 pixel by 16 pixel "Tile" onto the screen at character position x,y from adddress given.
' Data must be in the format of 16 bit rows, followed by attribute data.
' (c) 2010 Britlion, donated to the ZX BASIC project.
' Thanks to Boriel, LCD and Na_than for inspiration behind this.

' This routine could be used as the basis for a fast sprite system, provided all sprites can be in 4 character blocks.
' It can also be used to clean up dirty background (erase sprites), or put backgrounds from tiled blocks onto a screen.
'
' Note the comments about Self Modifying code should be ignored. This has been updated with IX+n methods, which overall
' are faster than accessing and changing the code.
' (They would have to be accessed to change the memory anyway - may as well just access them directly.)

' Parameters:
'   x - x coordinate (cell column)
'   y - y coordinate (cell row)
'   graphicsAddr - Memory address of the graphicc
'
' ----------------------------------------------------------------

SUB putTile(x as uByte, y as uByte, graphicsAddr as uInteger)
    ASM
        PROC
        LOCAL ptstackSave, pt_start, ptNextThird3, ptSameThird3
        LOCAL ptAddrDone3, ptNextSprite2, pt_nointerrupts

        jp pt_start

ptstackSave:
        defb 0,0

pt_start:
        ld a,i
        push af ; Save interrupt status.

        ; Routine to save the background to the buffer
        di ; we REALLY can NOT be having interrupts while the stack and IX and IY are pointed elsewhere.

        push ix
        push iy
        ld d,(ix+9)
        ld e,(ix+8)
        ex de,hl

        ;; Print sprites routine
        ld (ptstackSave), sp ; Save Stack Pointer
        ld sp,hl   ; now SP points at the start of the graphics.

        ; This function returns the address into HL of the screen address
        ld      a,(IX+5) ; Load in x - note the Self Modifying value
        ld      IYH, a ; save it
        ld      l,a
        ld      a,(IX+7) ; Load in y - note the Self Modifying value
        ld      IYL, a ; save it
        ld      d,a
        and     24
        add     a,64
        ld      h,a
        ld      a,d
        and     7
        rrca
        rrca
        rrca
        or      l
        add     a,2   ; Need to be to the right so backwards writing pushes land properly.
        ld      l,a

        ; SO now, HL -> Screen address, and SP -> Graphics. Time to start loading.

        pop bc    ; row 0
        pop de    ; row 1
        ex af,af'
        pop af    ; row 2
        ex af,af'
        exx
        pop bc    ; row 3
        pop de    ; row 4
        pop hl    ; row 5
        exx

        ; All right. We're loaded. Time to dump!

        ld ix,0
        add ix,sp  ; Save our stack pointer into ix

        ld sp,hl  ; point at the screen.
        push bc   ; row 0

        inc h
        ld sp,hl
        push de   ; row 1

        inc h
        ld sp,hl
        ex af,af'
        push af   ; row 2

        inc h
        ld sp,hl
        exx
        push bc   ; row 3
        exx

        inc h
        ld sp,hl
        exx
        push de   ; row 4
        exx

        inc h
        ld sp,hl
        exx
        push hl   ; row 5
        exx

        ; We're empty. Time to load up again.

        ld sp,ix
        pop bc    ; row 6
        pop de    ; row 7
        ex af,af'
        pop af    ; row 8
        ex af,af'
        exx
        pop bc    ; row 9
        pop de    ; row 10
        pop hl    ; row 11
        exx

        ; and we're loaded up again! Time to dump this graphic on the screen.

        ld ix,0
        add ix,sp ; save SP in IX

        inc h
        ld sp,hl
        push bc   ; row 6

        inc h
        ld sp,hl
        push de   ; row 7

        dec hl
        dec hl

        ; Aha. Snag. We're at the bottom of a character. What's the next address down?
        ld   a,l
        and  224
        cp   224
        jr   nz, ptNextThird3

ptSameThird3:
        ld   de,32
        add  hl,de
        jp ptAddrDone3

ptNextThird3:
        ld   de,-1760
        add  hl,de

ptAddrDone3:
        inc hl
        inc hl

        ld sp,hl
        ex af,af'
        push af  ; row 8

        inc h
        ld sp,hl
        exx
        push bc  ; row 9
        exx

        inc h
        ld sp,hl
        exx
        push de  ; row 10
        exx

        inc h
        ld sp,hl
        exx
        push hl  ; row 11
        exx

        ; Okay. Registers empty. Reload time!
        ld sp,ix
        pop bc    ; row 12
        pop de    ; row 13

        exx
        pop bc    ; row 14
        pop de    ; row 15
        pop hl    ; top attrs
        exx

        ex af,af'
        pop af    ; bottom attrs
        ex af,af'

        ; and the last dump to screen

        inc h
        ld sp,hl
        push bc

        inc h
        ld sp,hl
        push de

        inc h
        ld sp,hl
        exx
        push bc
        exx

        inc h
        ld sp,hl
        exx
        push de
        exx

        ; Pixels done. Just need to do the attributes.
        ; So set HL to the attr address:

        ld      a,iyl        ;ypos

        rrca
        rrca
        rrca               ; Multiply by 32
        ld      l,a        ; Pass to L
        and     3          ; Mask with 00000011
        add     a,88       ; 88 * 256 = 22528 - start of attributes.
        ld      h,a        ; Put it in the High Byte
        ld      a,l        ; We get y value *32
        and     224        ; Mask with 11100000
        ld      l,a        ; Put it in L
        ld      a,iyh      ; xpos
        adc     a,l        ; Add it to the Low byte
        ld      l,a        ; Put it back in L, and we're done. HL=Address.
        inc hl             ; we need to be to the right of the attr point as pushes write backwards.
        inc hl

        ; attr
        ld sp,hl
        exx
        push hl            ; top row
        exx

        ld hl,34           ; we need to move down to the next row. We already backed up 2, so we add 34.
        add hl,sp
        ld sp,hl
        ex af,af'          ; bottom row
        push af

ptNextSprite2:
        ; done. Cleanup.
        ld sp,(ptstackSave) ;  put our stack back together.

        ; done all 4 final clean up

        pop iy
        pop ix

        pop af  ; recover interrupt status
        jp po, pt_nointerrupts
        ei      ; Okay. We put everything back. If you need interrupts, you can go with em.

pt_nointerrupts:
        ENDP
    END ASM
END SUB


#pragma pop(case_insensitive)

#endif

