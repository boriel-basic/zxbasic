
; This test should issue a warning, since de scope starts after LOCAL
nop

PROC
    jp testLabel ; Uses a label in advance

LOCAL testLabel
testLabel:       

ENDP




