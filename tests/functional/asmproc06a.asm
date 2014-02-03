
; This label should be used in favour of the local one
; because the jp instruction uses it before declaring it
; local
NAMESPACE test

testLabel:
nop

PROC
    jp testLabel ; Uses a label in advance
    jp .anotherTest

LOCAL testLabel
testLabel:       

ENDP
jp testLabel

NAMESPACE default
anotherTest:





