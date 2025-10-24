' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2008, 2025
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' and Conrado Badenas <conbamen@gmail.com>
'
' Use this file as a template to develop your own library file
' ----------------------------------------------------------------

#ifndef __LIBRARY_SCROLL__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_SCROLL__

#pragma push(case_insensitive)
#pragma case_insensitive = True

' ----------------------------------------------------------------
' sub ScrollRight
' pixel by pixel right scroll
' scrolls 1 pixel right the window defined by (x1, y1, x2, y2)
' ----------------------------------------------------------------
sub fastcall ScrollRight(x1 as uByte, y1 as uByte, x2 as Ubyte, y2 as Ubyte)
	asm
    push namespace core

    PROC
    LOCAL LOOP1, LOOP2, MASK1, MASK2, COLUMNN, NEQ1
    LOCAL AND1, AND2, AND3, AND4, AND5, AND6, AND7, AND8

; Read parameters, return if they are bad
    ; a = x1
    pop hl ; RET address
    pop bc ; b = y1
    pop de ; d = x2
    ex (sp), hl ; h = y2, (sp) = RET address. Stack ok now

    ld c, a  ; BC = y1x1
    ld a, d
    sub c
    ret c   ; x1 > x2

    ld a, h
    sub b
    ret c   ; y1 > y2

; Compute height and masks
    inc a
    ld e, a ; e = y2 - y1 + 1

    ld a,c  ;e.g. x1 = 3, mask1 = %11100000, CPL = %00011111
    and 7
    inc a
    ld b,a  ;B = 1 + (x1 MOD 8) = 1,2,...,8 for x1 = 0,1,...,7 + 8*n
    xor a
MASK1:
      rra
      scf   ;inject B-1 1s from the left
      djnz MASK1
    ld (AND1+1),a   ;e.g. %11100000
    ld (AND5+1),a
    cpl
    ld (AND2+1),a   ;e.g. %00011111
    ld (AND7+1),a

    ld a,d  ;e.g. x2 = 5, mask2 = %11111100, CPL = %00000011
    and 7
    inc a
    ld b,a  ;B = 1 + (x2 MOD 8) = 1,2,...,8 for x2 = 0,1,...,7 + 8*n
    xor a
MASK2:
      scf   ;inject B 1s from the left
      rra
      djnz MASK2
    ld (AND4+1),a   ;e.g. %11111100
    ld (AND8+1),a
    cpl
    ld (AND3+1),a   ;e.g. %00000011
    ld (AND6+1),a

; Compute Ncols and Display File address, and choose branch
    ld a,c  ;x1
    and %11111000
    rrca
    rrca
    rrca
    ld b,a  ;col1
    ld a,d  ;x2
    and %11111000
    rrca
    rrca
    rrca    ;col2
    sub b   ;A = Ncols - 1 = col2 - col1
    ex af,af'   ;save Ncols-1 and ZeroFlag

    ld b, h ; BC = y2x1
    ld a, 191
    call 22ACh  ; 2 bytes after the 'PIXEL ADDRESS' subroutine, because
; https://skoolkid.github.io/rom/asm/22AA.html starts with LD A,175
    res 6, h    ; Starts from 0
    ld bc, (SCREEN_ADDR)
    add hl, bc  ; Now current offset

    ex af,af'   ;load Ncols-1 and ZeroFlag
    jr z,NEQ1

; N > 1 (there are 2 or more columns)
    dec a   ;A = Ncols - 2
    ld d,a  ;D = N-2
LOOP1:
      push hl
; Scroll column 1
      ld a,(hl)
AND1:
      and %11100000     ;e.g. x1 = 3
      ld c,a    ;get out-window part of byte
      ld a,(hl)
AND2:
      and %00011111     ;e.g. x1 = 3
      rra       ;scroll in-window part of byte
      rl b      ;CF is stored as bit0 of B
      or c      ;put out-window part of byte
      ld (hl),a
      inc hl
; Scroll columns 2,3,...,N-1
      ld a,d    ;N-2
      and a     ;A=0 iff N=2
      jr z,COLUMNN
      rr b      ;CF is on stage
      ld b,a
LOOP2:
        rr (hl)
        inc hl
        djnz LOOP2
      rl b      ;CF is stored as bit0 of B
; Scroll column N
COLUMNN:
      ld a,(hl)
AND3:
      and %00000011     ;e.g. x2 = 5
      ld c,a    ;get out-window part of byte
      ld a,(hl)
      rr b      ;CF is on stage
      rra       ;scroll in-window part of byte
AND4:
      and %11111100     ;e.g. x2 = 5
      or c      ;put out-window part of byte
      ld (hl),a
; Scroll another line
      pop hl
      dec e
      ret z
      call SP.PixelDown
      jp LOOP1

; N = 1 (there is only one column)
NEQ1:
      ld b,(hl)
      ld a,b
AND5:
      and %11100000     ;e.g. x1 = 3
      ld c,a
      ld a,b
AND6:
      and %00000011     ;e.g. x2 = 5
      or c
      ld c,a    ;get out-window part of byte
      ld a,b
AND7:
      and %00011111     ;e.g. x1 = 3
      rra       ;scroll in-window part of byte
AND8:
      and %11111100     ;e.g. x2 = 5
      or c      ;put out-window part of byte
      ld (hl),a
; Scroll another line
      dec e
      ret z
      call SP.PixelDown
      jp NEQ1
    ENDP

    pop namespace
	end asm
end sub

' ----------------------------------------------------------------
' sub ScrollLeft
' pixel by pixel left scroll
' scrolls 1 pixel left the window defined by (x1, y1, x2, y2)
' ----------------------------------------------------------------
sub fastcall ScrollLeft(x1 as uByte, y1 as uByte, x2 as Ubyte, y2 as Ubyte)
	asm
    push namespace core

    PROC
    LOCAL LOOP1, LOOP2, MASK1, MASK2, COLUMN1, NEQ1
    LOCAL AND1, AND2, AND3, AND4, AND5, AND6, AND7, AND8

; Read parameters, return if they are bad
    ; a = x1
    pop hl ; RET address
    pop bc ; b = y1
    pop de ; d = x2
    ex (sp), hl ; h = y2, (sp) = RET address. Stack ok now

    ld c, a  ; BC = y1x1
    ld a, d
    sub c
    ret c   ; x1 > x2

    ld a, h
    sub b
    ret c   ; y1 > y2

; Compute height and masks
    inc a
    ld e, a ; e = y2 - y1 + 1

    ld a,c  ;e.g. x1 = 3, mask1 = %11100000, CPL = %00011111
    and 7
    inc a
    ld b,a  ;B = 1 + (x1 MOD 8) = 1,2,...,8 for x1 = 0,1,...,7 + 8*n
    xor a
MASK1:
      rra
      scf   ;inject B-1 1s from the left
      djnz MASK1
    ld (AND3+1),a   ;e.g. %00000011
    ld (AND6+1),a
    cpl
    ld (AND4+1),a   ;e.g. %11111100
    ld (AND8+1),a

    ld a,d  ;e.g. x2 = 5, mask2 = %11111100, CPL = %00000011
    and 7
    inc a
    ld b,a  ;B = 1 + (x2 MOD 8) = 1,2,...,8 for x2 = 0,1,...,7 + 8*n
    xor a
MASK2:
      scf   ;inject B 1s from the left
      rra
      djnz MASK2
    ld (AND2+1),a   ;e.g. %00011111
    ld (AND7+1),a
    cpl
    ld (AND1+1),a   ;e.g. %11100000
    ld (AND5+1),a

; Compute Ncols and Display File address, and choose branch
    ld a,c  ;x1
    and %11111000
    rrca
    rrca
    rrca
    ld b,a  ;col1
    ld a,d  ;x2
    and %11111000
    rrca
    rrca
    rrca    ;col2
    sub b   ;A = Ncols - 1 = col2 - col1
    ex af,af'   ;save Ncols-1 and ZeroFlag

    ld c, d
    ld b, h ; BC = y2x2
    ld a, 191
    call 22ACh  ; 2 bytes after the 'PIXEL ADDRESS' subroutine, because
; https://skoolkid.github.io/rom/asm/22AA.html starts with LD A,175
    res 6, h    ; Starts from 0
    ld bc, (SCREEN_ADDR)
    add hl, bc  ; Now current offset

    ex af,af'   ;load Ncols-1 and ZeroFlag
    jr z,NEQ1

; N > 1 (there are 2 or more columns)
    dec a   ;A = Ncols - 2
    ld d,a  ;D = N-2
LOOP1:
      push hl
; Scroll column N
      ld a,(hl)
AND1:
      and %00000011     ;e.g. x2 = 5
      ld c,a    ;get out-window part of byte
      ld a,(hl)
AND2:
      and %11111100     ;e.g. x2 = 5
      rla       ;scroll in-window part of byte
      rl b      ;CF is stored as bit0 of B
      or c      ;put out-window part of byte
      ld (hl),a
      dec hl
; Scroll columns N-1,...,3,2
      ld a,d    ;N-2
      and a     ;A=0 iff N=2
      jr z,COLUMN1
      rr b      ;CF is on stage
      ld b,a
LOOP2:
        rl (hl)
        dec hl
        djnz LOOP2
      rl b      ;CF is stored as bit0 of B
; Scroll column 1
COLUMN1:
      ld a,(hl)
AND3:
      and %11100000     ;e.g. x1 = 3
      ld c,a    ;get out-window part of byte
      ld a,(hl)
      rr b      ;CF is on stage
      rla       ;scroll in-window part of byte
AND4:
      and %00011111     ;e.g. x1 = 3
      or c      ;put out-window part of byte
      ld (hl),a
; Scroll another line
      pop hl
      dec e
      ret z
      call SP.PixelDown
      jp LOOP1

; N = 1 (there is only one column)
NEQ1:
      ld b,(hl)
      ld a,b
AND5:
      and %00000011     ;e.g. x2 = 5
      ld c,a
      ld a,b
AND6:
      and %11100000     ;e.g. x1 = 3
      or c
      ld c,a    ;get out-window part of byte
      ld a,b
AND7:
      and %11111100     ;e.g. x2 = 5
      rla       ;scroll in-window part of byte
AND8:
      and %00011111     ;e.g. x1 = 3
      or c      ;put out-window part of byte
      ld (hl),a
; Scroll another line
      dec e
      ret z
      call SP.PixelDown
      jp NEQ1
    ENDP

    pop namespace
	end asm
end sub


' ----------------------------------------------------------------
' sub ScrollUp
' pixel by pixel up scroll
' scrolls 1 pixel up the window defined by (x1, y1, x2, y2)
' ----------------------------------------------------------------
sub fastcall ScrollUp(x1 as uByte, y1 as uByte, x2 as Ubyte, y2 as Ubyte)
	asm
    push namespace core

    PROC
    LOCAL LOOP1, MASK1, MASK2, COLUMNN, NEQ1
    LOCAL AND1, AND2, AND3, AND4, AND5, AND6, AND7, AND8
    LOCAL EMPTYLINE

; Read parameters, return if they are bad
    ; a = x1
    pop hl ; RET address
    pop bc ; b = y1
    pop de ; d = x2
    ex (sp), hl ; h = y2, (sp) = RET address. Stack ok now

    ld c, a  ; BC = y1x1
    ld a, d
    sub c
    ret c   ; x1 > x2

    ld a, h
    sub b
    ret c   ; y1 > y2

; Compute height and masks
    push ix
    inc a
    ld ixL,a;ixL = y2 - y1 + 1

    ld a,c  ;e.g. x1 = 3, mask1 = %11100000, CPL = %00011111
    and 7
    inc a
    ld b,a  ;B = 1 + (x1 MOD 8) = 1,2,...,8 for x1 = 0,1,...,7 + 8*n
    xor a
MASK1:
      rra
      scf   ;inject B-1 1s from the left
      djnz MASK1
    ld (AND1+1),a   ;e.g. %11100000
    ld (AND5+1),a
    cpl
    ld (AND2+1),a   ;e.g. %00011111
    ld (AND7+1),a

    ld a,d  ;e.g. x2 = 5, mask2 = %11111100, CPL = %00000011
    and 7
    inc a
    ld b,a  ;B = 1 + (x2 MOD 8) = 1,2,...,8 for x2 = 0,1,...,7 + 8*n
    xor a
MASK2:
      scf   ;inject B 1s from the left
      rra
      djnz MASK2
    ld (AND4+1),a   ;e.g. %11111100
    ld (AND8+1),a
    cpl
    ld (AND3+1),a   ;e.g. %00000011
    ld (AND6+1),a

; Compute Ncols and Display File address, and choose branch
    ld a,c  ;x1
    and %11111000
    rrca
    rrca
    rrca
    ld b,a  ;col1
    ld a,d  ;x2
    and %11111000
    rrca
    rrca
    rrca    ;col2
    sub b   ;A = Ncols - 1 = col2 - col1
    ex af,af'   ;save Ncols-1 and ZeroFlag

    ld b, h ; BC = y2x1
    ld a, 191
    call 22ACh  ; 2 bytes after the 'PIXEL ADDRESS' subroutine, because
; https://skoolkid.github.io/rom/asm/22AA.html starts with LD A,175
    res 6, h    ; Starts from 0
    ld bc, (SCREEN_ADDR)
    add hl, bc  ; Now current offset

    ex af,af'   ;load Ncols-1 and ZeroFlag
    jr z,NEQ1

; N > 1 (there are 2 or more columns)
    dec a       ;A = Ncols - 2
    ld ixH,a    ;save Ncols-2
    ld b,0
LOOP1:
      dec ixL
      ld d,h
      ld e,l
      call z,EMPTYLINE      ;HL at empty line
      call nz,SP.PixelDown  ;HL at line below
      inc ixL   ;restore iterative variable for a second check
      push hl
; Scroll column 1
      ld a,(hl)
AND2:
      and %00011111     ;e.g. x1 = 3
      ld c,a    ;get in-window part of byte
      ld a,(de)
AND1:
      and %11100000     ;e.g. x1 = 3
      or c      ;put in-window part of byte
      ld (de),a
      inc hl
      inc de
; Scroll columns 2,3,...,N-1
      ld a,ixH  ;load Ncols-2
      and a
      jr z,COLUMNN
        ld c,a
        ldir
; Scroll column N
COLUMNN:
      ld a,(hl)
AND4:
      and %11111100     ;e.g. x2 = 5
      ld c,a    ;get in-window part of byte
      ld a,(de)
AND3:
      and %00000011     ;e.g. x2 = 5
      or c      ;put in-window part of byte
      ld (de),a
; Scroll another line
      pop hl
      dec ixL
      jp nz,LOOP1
    pop ix
    ret

; N = 1 (there is only one column)
NEQ1:
      dec ixL
      ld d,h
      ld e,l
      call z,EMPTYLINE      ;HL at empty line
      call nz,SP.PixelDown  ;HL at line below
      inc ixL   ;restore iterative variable for a second check

      ld a,(hl)
AND7:
      and %00011111     ;e.g. x1 = 3
AND8:
      and %11111100     ;e.g. x2 = 5
      ld c,a    ;get in-window part of byte
      ld a,(de)
AND5:
      and %11100000     ;e.g. x1 = 3
      ld b,a
      ld a,(de)
AND6:
      and %00000011     ;e.g. x2 = 5
      or b
      or c      ;put in-window part of byte
      ld (de),a
; Scroll another line
      dec ixL
      jp nz,NEQ1
    pop ix
    ret

    defs 32,0   ;empty line with 32 zero-bytes
EMPTYLINE:
    ld hl,EMPTYLINE-32
    ENDP

    pop namespace
	end asm
end sub


' ----------------------------------------------------------------
' sub ScrollDown
' pixel by pixel down scroll
' scrolls 1 pixel down the window defined by (x1, y1, x2, y2)
' ----------------------------------------------------------------
sub fastcall ScrollDown(x1 as uByte, y1 as uByte, x2 as Ubyte, y2 as Ubyte)
	asm
    push namespace core

    PROC
    LOCAL LOOP1, MASK1, MASK2, COLUMNN, NEQ1
    LOCAL AND1, AND2, AND3, AND4, AND5, AND6, AND7, AND8
    LOCAL EMPTYLINE

; Read parameters, return if they are bad
    ; a = x1
    pop hl ; RET address
    pop bc ; b = y1
    pop de ; d = x2
    ex (sp), hl ; h = y2, (sp) = RET address. Stack ok now

    ld c, a  ; BC = y1x1
    ld a, d
    sub c
    ret c   ; x1 > x2

    ld a, h
    sub b
    ret c   ; y1 > y2

; Compute height and masks
    push ix
    inc a
    ld ixL,a;ixL = y2 - y1 + 1
    ld h,b  ;y1

    ld a,c  ;e.g. x1 = 3, mask1 = %11100000, CPL = %00011111
    and 7
    inc a
    ld b,a  ;B = 1 + (x1 MOD 8) = 1,2,...,8 for x1 = 0,1,...,7 + 8*n
    xor a
MASK1:
      rra
      scf   ;inject B-1 1s from the left
      djnz MASK1
    ld (AND1+1),a   ;e.g. %11100000
    ld (AND5+1),a
    cpl
    ld (AND2+1),a   ;e.g. %00011111
    ld (AND7+1),a

    ld a,d  ;e.g. x2 = 5, mask2 = %11111100, CPL = %00000011
    and 7
    inc a
    ld b,a  ;B = 1 + (x2 MOD 8) = 1,2,...,8 for x2 = 0,1,...,7 + 8*n
    xor a
MASK2:
      scf   ;inject B 1s from the left
      rra
      djnz MASK2
    ld (AND4+1),a   ;e.g. %11111100
    ld (AND8+1),a
    cpl
    ld (AND3+1),a   ;e.g. %00000011
    ld (AND6+1),a

; Compute Ncols and Display File address, and choose branch
    ld a,c  ;x1
    and %11111000
    rrca
    rrca
    rrca
    ld b,a  ;col1
    ld a,d  ;x2
    and %11111000
    rrca
    rrca
    rrca    ;col2
    sub b   ;A = Ncols - 1 = col2 - col1
    ex af,af'   ;save Ncols-1 and ZeroFlag

    ld b, h ; BC = y1x1
    ld a, 191
    call 22ACh  ; 2 bytes after the 'PIXEL ADDRESS' subroutine, because
; https://skoolkid.github.io/rom/asm/22AA.html starts with LD A,175
    res 6, h    ; Starts from 0
    ld bc, (SCREEN_ADDR)
    add hl, bc  ; Now current offset

    ex af,af'   ;load Ncols-1 and ZeroFlag
    jr z,NEQ1

; N > 1 (there are 2 or more columns)
    dec a       ;A = Ncols - 2
    ld ixH,a    ;save Ncols-2
    ld b,0
LOOP1:
      dec ixL
      ld d,h
      ld e,l
      call z,EMPTYLINE      ;HL at empty line
      call nz,SP.PixelUp    ;HL at line above
      inc ixL   ;restore iterative variable for a second check
      push hl
; Scroll column 1
      ld a,(hl)
AND2:
      and %00011111     ;e.g. x1 = 3
      ld c,a    ;get in-window part of byte
      ld a,(de)
AND1:
      and %11100000     ;e.g. x1 = 3
      or c      ;put in-window part of byte
      ld (de),a
      inc hl
      inc de
; Scroll columns 2,3,...,N-1
      ld a,ixH  ;load Ncols-2
      and a
      jr z,COLUMNN
        ld c,a
        ldir
; Scroll column N
COLUMNN:
      ld a,(hl)
AND4:
      and %11111100     ;e.g. x2 = 5
      ld c,a    ;get in-window part of byte
      ld a,(de)
AND3:
      and %00000011     ;e.g. x2 = 5
      or c      ;put in-window part of byte
      ld (de),a
; Scroll another line
      pop hl
      dec ixL
      jp nz,LOOP1
    pop ix
    ret

; N = 1 (there is only one column)
NEQ1:
      dec ixL
      ld d,h
      ld e,l
      call z,EMPTYLINE      ;HL at empty line
      call nz,SP.PixelUp    ;HL at line below
      inc ixL   ;restore iterative variable for a second check

      ld a,(hl)
AND7:
      and %00011111     ;e.g. x1 = 3
AND8:
      and %11111100     ;e.g. x2 = 5
      ld c,a    ;get in-window part of byte
      ld a,(de)
AND5:
      and %11100000     ;e.g. x1 = 3
      ld b,a
      ld a,(de)
AND6:
      and %00000011     ;e.g. x2 = 5
      or b
      or c      ;put in-window part of byte
      ld (de),a
; Scroll another line
      dec ixL
      jp nz,NEQ1
    pop ix
    ret

    defs 32,0   ;empty line with 32 zero-bytes
EMPTYLINE:
    ld hl,EMPTYLINE-32
    ENDP

    pop namespace
	end asm
end sub

#pragma pop(case_insensitive)

REM the following is required, because it defines SCREEN_ADDR and SCREEN_ATTR_ADDR
#require "sysvars.asm"
#require "SP/PixelDown.asm"
#require "SP/PixelUp.asm"


#endif
