' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2023
' by Juan Segura (a.k.a. Duefectu) <http://zx.duefectucorp.com>
'
' Mode 2 interrupt handling library
' ----------------------------------------------------------------

#ifndef __LIBRARY_IM2__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_IM2__


' ----------------------------------------------------------------
' IM2Start configures and initialises the interrupt service.
' At each interruption the address "callBack" shall be called.
' When this service is activated, the FRAMES counter and the
' PAUSE and INKEY$ instructions no longer work correctly.
' Not working with "INVES +" models
'
' Sample of use:
' IM2Start(@MyIM2Routine)   ' Use @<name>
' SUB MyIM2Routine()
'   ' Do something not too complicated
' END SUB
'
' Parameters:
'     callback (UInteger): Address to jump on every interrupt
' ----------------------------------------------------------------
sub IM2Start(callBack AS UInteger)
ASM
    PROC
    LOCAL IM2_Table, IM2_Tick, IM2_Tick_End, IM2_End, IM2_CallBack

    ld [IM2_CallBack],hl

    di              ; Disable interrupts
    ld hl,IM2_Table-256 ; The end of the IM2 table
    ld a,h          ; Adjust the value of I at the end of the table
    ld i,a

    ld hl,IM2_Tick      ; Set IM2_Tick address
    ld a,l              ; Al final de la tabla
    ld (IM2_Table-1),a
    ld a,h
    ld (IM2_Table),a

    im 2            ; Set interrupt mode to 2
    ei              ; Enable interrupts
    jp IM2_End      ; Jump to the end to exit


    ; Here you will jump at every interrupt
IM2_Tick:
    ; Save all registers
    push af
    push hl
    push bc
    push de
    push ix
    push iy
    exx
    ex af, af'
    push af
    push hl
    push bc
    push de

    ld hl,IM2_Tick_End    ; Set return address
    push hl
    ld hl,[IM2_CallBack]  ; Jump to callBack routine
    jp [hl]

IM2_Tick_End:
    ; Restore registers
    pop de
    pop bc
    pop hl
    pop af
    ex af, af'
    exx
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af

    ei              ; Enable interrupts
    reti            ; Return from interrupt


    ; Space for the interrupt vector table
    ; Must start at an address multiple of 256
    db 0            ; The first jump value is in $ff
    ALIGN 256       ; Align to 256
IM2_Table:
    db 0            ; The second jump value is $00

IM2_CallBack:       ; CallBack address
    DW 0

IM2_End:
    ENDP
END ASM
end sub


' ----------------------------------------------------------------
' IM2Stop stops the interrupt service and restores ROM interrupts
' ----------------------------------------------------------------
sub IM2Stop()
ASM
    di              ; Disable interrupts
    im 1            ; Set interrupt mode 1 (ROM)
    ei              ; Enable interrupts
END ASM
end sub
#endif
