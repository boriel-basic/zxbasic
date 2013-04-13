
nop

PROC
    jp testLabel ; Uses a label in advance

LOCAL testLabel
testLabel:       

ENDP

; This label should be used in favour of the local one
; because the jp instruction uses it before declaring it
; local
testLabel:

nop





