; 2nd a succesive repeated LOCAL directives
; should be ignored (and maybe warned)

PROC


LOCAL test
LOCAL test
test:

jr test

ENDP


