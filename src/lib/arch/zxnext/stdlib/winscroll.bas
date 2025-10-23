' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2008, 2025
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' and Conrado Badenas <conbamen@gmail.com>
'
' Use this file as a template to develop your own library file
' ----------------------------------------------------------------

#ifndef __LIBRARY_WINSCROLL__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_WINSCROLL__

#pragma push(case_insensitive)
#pragma case_insensitive = True

' ---------------------------------------------------------------------
' sub WinScrollRight
' scrolls the window defined by (row, col, width, height) 1 cell right
' it works with width=1 or height=1 but it is not impressive
' nothing is done if width=0 or height=0
' ---------------------------------------------------------------------
sub fastcall WinScrollRight(row as uByte, col as uByte, width as Ubyte, height as Ubyte)
	asm
    push namespace core
    PROC
    LOCAL BucleRows, BucleScans, AfterLDDR, AfterLDDR2, AfterLDDR3

; Read parameters, return if they are bad
    ld b, a     ;row
    pop hl      ;return address
    pop de
    ld a, d     ;colLeft
    pop de      ;width
    add a, d
    dec a
    ld c, a     ;colRight = colLeft + width - 1
    ex (sp), hl
    ld e, h     ;height
    ld a, e
    or a
    ret z       ;height=0
    ld a, d
    or a
    ret z       ;width=0

; Compute Attributes address
    sub 2       ;CF=1 if width=1, CF=0 if width>1
    inc a
    ex af,af'   ;A' = width-1, CF'=1 if width=1, CF'=0 if width>1
    push ix
    ld ixL,e    ;IXl = height, iterative variable
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,l
    add a,c
    ld l,a      ;HL = row*32 + colRight
    ld de,(SCREEN_ATTR_ADDR)
    add hl,de

; For each row, compute Display File address
BucleRows:
      push bc   ;coords = row,col
      push hl   ;attr address
      ld a,b    ;row
      and %00011000 ;select third (0,1,2)
      ld h,a
      ld a,b
      and %00000111 ;select Row In Third (0,...,7)
      rrca
      rrca
      rrca      ;A = %RIT00000
      add a,c
      ld l,a    ;HL = %000th000RITcolmn
      ld de,(SCREEN_ADDR)
      add hl,de
      ld b,0
      ex af,af' ;A = width-1, CF=1 if width=1, CF=0 if width>1
      ld ixH,7

; For each row, transfer 8 scans
BucleScans:
        push hl
        jr c,AfterLDDR
          ld d,h
          ld e,l    ;DE = to address
          dec hl    ;HL = from address
          ld c,a
          lddr      ;1st-7th scan in row
          ex de,hl
AfterLDDR:
        ld (hl),b ;clean up leftmost
        pop hl
        inc h     ;scan below
        dec ixH
        jp nz,BucleScans

      jr c,AfterLDDR2
        ld d,h
        ld e,l    ;DE = to address
        dec hl    ;HL = from address
        ld c,a
        lddr      ;8th scan in row
        ex de,hl
AfterLDDR2:
      ld (hl),b ;clean up leftmost

; For each row, transfer a line of attributes
      pop hl    ;attr address
      jr c,AfterLDDR3
        ld d,h
        ld e,l    ;DE = to address
        dec hl    ;HL = from address
        ld c,a
        push de
        lddr      ;attrs in row
        pop hl
AfterLDDR3:
      ex af,af' ;A' = width-1, CF'=1 if width=1, CF'=0 if width>1
      ld de,32
      add hl,de ;row below
      pop bc
      inc b     ;row below
      dec ixL      
      jp nz,BucleRows

    pop ix
    ENDP
    pop namespace
	end asm
end sub


' ---------------------------------------------------------------------
' sub WinScrollLeft
' scrolls the window defined by (row, col, width, height) 1 cell left
' it works with width=1 or height=1 but it is not impressive
' nothing is done if width=0 or height=0
' ---------------------------------------------------------------------
sub fastcall WinScrollLeft(row as uByte, col as uByte, width as Ubyte, height as Ubyte)
	asm
    push namespace core
    PROC
    LOCAL BucleRows, BucleScans, AfterLDIR, AfterLDIR2, AfterLDIR3

; Read parameters, return if they are bad
    ld b, a     ;row
    pop hl      ;return address
    pop de
    ld c, d     ;col
    pop de      ;width
    ex (sp), hl
    ld e, h     ;height
    ld a, e
    or a
    ret z       ;height=0
    ld a, d
    or a
    ret z       ;width=0

; Compute Attributes address
    sub 2       ;CF=1 if width=1, CF=0 if width>1
    inc a
    ex af,af'   ;A' = width-1, CF'=1 if width=1, CF'=0 if width>1
    push ix
    ld ixL,e    ;IXl = height, iterative variable
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,l
    add a,c
    ld l,a      ;HL = row*32 + col
    ld de,(SCREEN_ATTR_ADDR)
    add hl,de

; For each row, compute Display File address
BucleRows:
      push bc   ;coords = row,col
      push hl   ;attr address
      ld a,b    ;row
      and %00011000 ;select third (0,1,2)
      ld h,a
      ld a,b
      and %00000111 ;select Row In Third (0,...,7)
      rrca
      rrca
      rrca      ;A = %RIT00000
      add a,c
      ld l,a    ;HL = %000th000RITcolmn
      ld de,(SCREEN_ADDR)
      add hl,de
      ld b,0
      ex af,af' ;A = width-1, CF=1 if width=1, CF=0 if width>1
      ld ixH,7

; For each row, transfer 8 scans
BucleScans:
        push hl
        jr c,AfterLDIR
          ld d,h
          ld e,l    ;DE = to address
          inc hl    ;HL = from address
          ld c,a
          ldir      ;1st-7th scan in row
          ex de,hl
AfterLDIR:
        ld (hl),b ;clean up rightmost
        pop hl
        inc h     ;scan below
        dec ixH
        jp nz,BucleScans

      jr c,AfterLDIR2
        ld d,h
        ld e,l    ;DE = to address
        inc hl    ;HL = from address
        ld c,a
        ldir      ;8th scan in row
        ex de,hl
AfterLDIR2:
      ld (hl),b ;clean up rightmost

; For each row, transfer a line of attributes
      pop hl    ;attr address
      jr c,AfterLDIR3
        ld d,h
        ld e,l    ;DE = to address
        inc hl    ;HL = from address
        ld c,a
        push de
        ldir      ;attrs in row
        pop hl
AfterLDIR3:
      ex af,af' ;A' = width-1, CF'=1 if width=1, CF'=0 if width>1
      ld de,32
      add hl,de ;row below
      pop bc
      inc b     ;row below
      dec ixL      
      jp nz,BucleRows

    pop ix
    ENDP
    pop namespace
	end asm
end sub


' ---------------------------------------------------------------------
' sub WinScrollUp
' scrolls the window defined by (row, col, width, height) 1 cell up
' it works with width=1 or height=1 but it is not impressive
' nothing is done if width=0 or height=0
' ---------------------------------------------------------------------
sub fastcall WinScrollUp(row as uByte, col as uByte, width as Ubyte, height as Ubyte)
	asm
    push namespace core
    PROC
    LOCAL BucleRows, BucleScans, AttrAddress
    LOCAL CleanBottomRow, CleanBottomScans, AfterLDIR

; Read parameters, return if they are bad
    ld b, a     ;row
    pop hl      ;return address
    pop de
    ld c, d     ;col
    pop de      ;width
    ex (sp), hl
    ld e, h     ;height
    ld a, e
    or a
    ret z       ;height=0
    ld a, d
    or a
    ret z       ;width=0

; Compute TopRow Attributes address
    ex af,af'   ;A' = width
    push ix
    ld ixL,e    ;IXl = height, iterative variable
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,l
    add a,c
    ld l,a      ;HL = row*32 + col
    ld de,(SCREEN_ATTR_ADDR)
    add hl,de
    ld (AttrAddress+1),hl

; Compute TopRow Display File address
    ld a,b      ;row
    and %00011000 ;select third (0,1,2)
    ld h,a
    ld a,b
    and %00000111 ;select Row In Third (0,...,7)
    rrca
    rrca
    rrca        ;A = %RIT00000
    add a,c
    ld l,a      ;HL = %000th000RITcolmn
    ld de,(SCREEN_ADDR)
    add hl,de
    push hl     ;HL = from address 

BucleRows:
      dec ixL
      jr z,CleanBottomRow
; For each row, compute Display File address
      inc b     ;row below
      ld a,b    ;row
      and %00011000 ;select third (0,1,2)
      ld h,a
      ld a,b
      and %00000111 ;select Row In Third (0,...,7)
      rrca
      rrca
      rrca      ;A = %RIT00000
      add a,c
      ld l,a    ;HL = %000th000RITcolmn
      ld de,(SCREEN_ADDR)
      add hl,de

; For each row, transfer 8 scans
      pop de    ;DE = to address, obtained from last "push hl; from address"
      push hl   ;HL = from address, will be the next "to address"
      push bc   ;coords = row,col
      ld b,0
      ex af,af' ;A = width
      ld ixH,7
BucleScans:
        ld c,a
        push de
        push hl
        ldir      ;1st-7th scan in row
        pop hl
        pop de
        inc h     ;scan below
        inc d     ;scan below
        dec ixH
        jp nz,BucleScans

      ld c,a
      ldir      ;8th scan in row

; For each row, transfer a line of attributes
AttrAddress:
      ld hl,AttrAddress
      ld d,h
      ld e,l    ;DE = to address
      ld c,32
      add hl,bc ;HL = from address
      ld (AttrAddress+1),hl
      ld c,a
      ldir      ;attrs in row
      ex af,af' ;A' = width
      pop bc
      jp BucleRows

; Clean bottom row (Display File, not Attributes)
CleanBottomRow:
    ld b,0
    ex af,af' ;A = width
    ld ixH,8  ;no need to speed up code by processing scans 1-7 apart of scan 8
    pop hl
CleanBottomScans:
      ld (hl),b
      ld c,a
      dec c
      jr z,AfterLDIR
        push hl
        ld d,h
        ld e,l
        inc de
        ldir
        pop hl
AfterLDIR:
      inc h
      dec ixH
      jp nz,CleanBottomScans

    pop ix
    ENDP
    pop namespace
	end asm
end sub


' ---------------------------------------------------------------------
' sub WinScrollDown
' scrolls the window defined by (row, col, width, height) 1 cell down
' it works with width=1 or height=1 but it is not impressive
' nothing is done if width=0 or height=0
' ---------------------------------------------------------------------
sub fastcall WinScrollDown(row as uByte, col as uByte, width as Ubyte, height as Ubyte)
	asm
    push namespace core
    PROC
    LOCAL BucleRows, BucleScans, AttrAddress
    LOCAL CleanTopRow, CleanTopScans, AfterLDIR

; Read parameters, return if they are bad
    ld b, a     ;rowTop
    pop hl      ;return address
    pop de
    ld c, d     ;col
    pop de      ;width
    ex (sp), hl
    ld e, h     ;height
    ld a, b
    add a, e
    dec a
    ld b, a     ;rowBottom = rowTop + height - 1
    ld a, e
    or a
    ret z       ;height=0
    ld a, d
    or a
    ret z       ;width=0

; Compute BottomRow Attributes address
    ex af,af'   ;A' = width
    push ix
    ld ixL,e    ;IXl = height, iterative variable
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,l
    add a,c
    ld l,a      ;HL = row*32 + col
    ld de,(SCREEN_ATTR_ADDR)
    add hl,de
    ld (AttrAddress+1),hl

; Compute BottomRow Display File address
    ld a,b      ;row
    and %00011000 ;select third (0,1,2)
    ld h,a
    ld a,b
    and %00000111 ;select Row In Third (0,...,7)
    rrca
    rrca
    rrca        ;A = %RIT00000
    add a,c
    ld l,a      ;HL = %000th000RITcolmn
    ld de,(SCREEN_ADDR)
    add hl,de
    push hl     ;HL = from address 

BucleRows:
      dec ixL
      jr z,CleanTopRow
; For each row, compute Display File address
      dec b     ;row above
      ld a,b    ;row
      and %00011000 ;select third (0,1,2)
      ld h,a
      ld a,b
      and %00000111 ;select Row In Third (0,...,7)
      rrca
      rrca
      rrca      ;A = %RIT00000
      add a,c
      ld l,a    ;HL = %000th000RITcolmn
      ld de,(SCREEN_ADDR)
      add hl,de

; For each row, transfer 8 scans
      pop de    ;DE = to address, obtained from last "push hl; from address"
      push hl   ;HL = from address, will be the next "to address"
      push bc   ;coords = row,col
      ld b,0
      ex af,af' ;A = width
      ld ixH,7
BucleScans:
        ld c,a
        push de
        push hl
        ldir      ;1st-7th scan in row
        pop hl
        pop de
        inc h     ;scan below
        inc d     ;scan below
        dec ixH
        jp nz,BucleScans

      ld c,a
      ldir      ;8th scan in row

; For each row, transfer a line of attributes
AttrAddress:
      ld hl,AttrAddress
      ld d,h
      ld e,l    ;DE = to address
      ld c,32   ;it is a "mORAcle" that CarryFlag is always 0 here
      sbc hl,bc ;HL = from address
      ld (AttrAddress+1),hl
      ld c,a
      ldir      ;attrs in row
      ex af,af' ;A' = width
      pop bc
      jp BucleRows

; Clean top row (Display File, not Attributes)
CleanTopRow:
    ld b,0
    ex af,af' ;A = width
    ld ixH,8  ;no need to speed up code by processing scans 1-7 apart of scan 8
    pop hl
CleanTopScans:
      ld (hl),b
      ld c,a
      dec c
      jr z,AfterLDIR
        push hl
        ld d,h
        ld e,l
        inc de
        ldir
        pop hl
AfterLDIR:
      inc h
      dec ixH
      jp nz,CleanTopScans

    pop ix
    ENDP
    pop namespace
	end asm
end sub

#pragma pop(case_insensitive)

REM the following is required, because it defines SCREEN_ADDR and SCREEN_ATTR_ADDR
#require "sysvars.asm"


#endif
