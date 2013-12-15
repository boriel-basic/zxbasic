
sub p()

asm
    PROC

    CP 22           ; Is this an AT?
    JR NZ, isNewline ; If not jump over the AT routine to isNewline

LOCAL isAt
isAt:
    EX DE,HL        ; Get DE to hold HL for a moment
    ;;AND A           ; Plays with the flags. One of the things it does is reset Carry.
    ;;LD HL,00002
    ;;SBC HL,BC       ; Subtract length of string from HL.
    LD HL, -2
    ADD HL, BC
    EX DE,HL        ; Get HL back from DE
    ;;RET NC          ; If the result WASN'T negative, return. (We need AT to have parameters to make sense)

    INC HL          ; Onto our Y co-ordinate
    LD D,(HL)       ; Put it in D
    DEC BC          ; and move our string remaining counter down one               
    INC HL          ; Onto our X co-ordinate
    LD E,(HL)       ; Put the next one in E
    DEC BC          ; and move our string remaining counter down one

LOCAL isNewline
isNewline:
    ENDP

End ASM

end sub

p()

