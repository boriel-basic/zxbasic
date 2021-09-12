    push namespace core

__MUL16:	; Mutiplies HL with the last value stored into de stack
    ; Works for both signed and unsigned

    PROC

    ex de, hl
    pop hl		; Return address
    ex (sp), hl ; CALLEE caller convention

__MUL16_FAST:
    ld a,d                      ; a = xh
    ld d,h                      ; d = yh
    ld h,a                      ; h = xh
    ld c,e                      ; c = xl
    ld b,l                      ; b = yl
    mul d,e                     ; yh * yl
    ex de,hl
    mul d,e                     ; xh * yl
    add hl,de                   ; add cross products
    ld e,c
    ld d,b
    mul d,e                     ; yl * xl
    ld a,l                      ; cross products lsb
    add a,d                     ; add to msb final
    ld h,a
    ld l,e                      ; hl = final

    ret	; Result in hl (16 lower bits)

    ENDP

    pop namespace
