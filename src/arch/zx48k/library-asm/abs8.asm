; Returns absolute value for 8 bit signed integer
;
    push namespace core

__ABS8:
    or a
    ret p
    neg
    ret

    pop namespace

