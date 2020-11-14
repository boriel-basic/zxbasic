; vim:ts=4:et:sw=4:
; This is a fast beep routine, but needs parameters
; codified in a different way. 
; See http://www.wearmouth.demon.co.uk/zx82.htm#L03F8

; Needs pitch on top of the stack
; HL = duration

__BEEPER:
    ex de, hl
    pop hl
    ex (sp), hl ; CALLEE
    push ix     ; BEEPER changes IX
    call 03B5h
    pop ix
    ret


