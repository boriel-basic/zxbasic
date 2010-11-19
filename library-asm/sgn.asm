; Returns SGN (SIGN) for 32, 16 and 8 bits signed integers, Fixed and FLOAT

    PROC
    LOCAL __ENDSGN

__SGNF:
    or b
    or c
    or d
    or e
    ret z
    ld a, e
    jr __ENDSGN

__SGNF16:
__SGNI32:
	ld a, h
	or l
	or e
	or d
	ret z

    ld a, d
    jr __ENDSGN

__SGNI16:
	ld a, h
	or l
	ret z
	ld a, h

__ENDSGN:
	or a
	ld a, 1
	ret p
	neg
	ret

    ENDP

