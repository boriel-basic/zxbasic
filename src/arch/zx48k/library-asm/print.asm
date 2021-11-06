; vim:ts=4:sw=4:et:
; PRINT command routine
; Does not print attribute. Use PRINT_STR or PRINT_NUM for that

#include once <sposn.asm>
#include once <in_screen.asm>
#include once <table_jump.asm>
#include once <ink.asm>
#include once <paper.asm>
#include once <flash.asm>
#include once <bright.asm>
#include once <over.asm>
#include once <inverse.asm>
#include once <bold.asm>
#include once <italic.asm>
#include once <sysvars.asm>
#include once <attr.asm>

; Putting a comment starting with @INIT <address>
; will make the compiler to add a CALL to <address>
; It is useful for initialization routines.
#init .core.__PRINT_INIT

    push namespace core

__PRINT_INIT: ; To be called before program starts (initializes library)
    PROC

    ld hl, __PRINT_START
    ld (PRINT_JUMP_STATE), hl

    ld hl, 1820h
    ld (MAXX), hl  ; Sets current maxX and maxY

    xor a
    ld (FLAGS2), a

    LOCAL SET_SCR_ADDR
SET_SCR_ADDR:

    call __LOAD_S_POSN
    jp   __SAVE_S_POSN

__PRINTCHAR: ; Print character store in accumulator (A register)
    ; Modifies H'L', B'C', A'F', D'E', A

    LOCAL PO_GR_1

    LOCAL __PRCHAR
    LOCAL __PRINT_CONT
    LOCAL __PRINT_CONT2
    LOCAL __PRINT_JUMP
    LOCAL __SRCADDR
    LOCAL __PRINT_UDG
    LOCAL __PRGRAPH
    LOCAL __PRINT_START
    LOCAL __ROM_SCROLL_SCR

    __ROM_SCROLL_SCR EQU 0DFEh

PRINT_JUMP_STATE EQU __PRINT_JUMP + 1

__PRINT_JUMP:
    jp __PRINT_START    ; Where to jump. If we print 22 (AT), next two calls jumps to AT1 and AT2 respectively

#ifndef DISABLE_SCROLL
    LOCAL __SCROLL
__SCROLL:  ; Scroll?
    ld hl, TVFLAGS
    bit 1, (hl)
    ret z
    call __ROM_SCROLL_SCR
    ld hl, TVFLAGS
    res 1, (hl)
    ret
#endif

__PRINT_START:
    exx               ; Switch to alternative registers
    ex af, af'        ; Saves a value (char to print) for later

    ld hl, (S_POSN)
    dec l
    jr nz, 1f
    ld a, (MAXX)
    ld l, a
    dec h
    jr nz, 2f
    inc h
    push hl
    call __ROM_SCROLL_SCR
    pop hl
2:
    ld (S_POSN), hl
    call SET_SCR_ADDR
    jr __PRINT_CHR
1:
    ld (S_POSN), hl

__PRINT_CHR:
    ex af, af'        ; Recovers char to print
    cp ' '
    jr c, __PRINT_SPECIAL    ; Characters below ' ' are special ones

    cp 80h    ; Is it an UDG or a ?
    jr c, __SRCADDR

    cp 90h
    jr nc, __PRINT_UDG

    ; Print an 8 bit pattern (80h to 8Fh)

    ld b, a
    call PO_GR_1 ; This ROM routine will generate the bit pattern at MEM0
    ld hl, MEM0
    jp __PRGRAPH

PO_GR_1 EQU 0B38h

__PRINT_UDG:
    sub 90h ; Sub ASC code
    ld bc, (UDG)
    jr __PRGRAPH0

__SOURCEADDR EQU (__SRCADDR + 1)    ; Address of the pointer to chars source
__SRCADDR:
    ld bc, (CHARS)

__PRGRAPH0:
    add a, a   ; A = a * 2 (since a < 80h) ; Thanks to Metalbrain at http://foro.speccy.org
    ld l, a
    ld h, 0    ; HL = a * 2 (accumulator)
    add hl, hl
    add hl, hl ; HL = a * 8
    add hl, bc ; HL = CHARS address

__PRGRAPH:
    ex de, hl  ; HL = Write Address, DE = CHARS address
    bit 2, (iy + $47)
    call nz, __BOLD
    bit 4, (iy + $47)
    call nz, __ITALIC
    ld b, 8 ; 8 bytes per char

    ld hl, (DFCC)
    push hl

__PRCHAR:
    ld a, (de) ; DE *must* be source, and HL destiny

PRINT_MODE:     ; Which operation is used to write on the screen
    ; Set it with:
    ; LD A, <OPERATION>
    ; LD (PRINT_MODE), A
    ;
    ; Available operations:
    ; NORMAL : 0h  --> NOP         ; OVER 0
    ; XOR    : AEh --> XOR (HL)    ; OVER 1
    ; OR     : B6h --> OR (HL)     ; PUTSPRITE
    ; AND    : A6h --> AND (HL)    ; PUTMASK
    nop     ;

INVERSE_MODE:   ; 00 -> NOP -> INVERSE 0
    nop     ; 2F -> CPL -> INVERSE 1

    ld (hl), a

    inc de
    inc h     ; Next line
    djnz __PRCHAR

    pop hl
    inc hl
    ld (DFCC), hl

    ld hl, (DFCCL)   ; current ATTR Pos
    push hl
    call __SET_ATTR
    pop hl
    inc hl
    ld (DFCCL),hl

__PRINT_CONT:
__PRINT_CONT2:
    exx
    ret

; ------------- SPECIAL CHARS (< 32) -----------------

__PRINT_SPECIAL:    ; Jumps here if it is a special char
    exx
    ld hl, __PRINT_TABLE
    jp JUMP_HL_PLUS_2A


PRINT_EOL:        ; Called WHENEVER there is no ";" at end of PRINT sentence
    exx

__PRINT_0Dh:        ; Called WHEN printing CHR$(13)
    ld hl, (S_POSN)

__PRINT_EOL1:        ; Another entry called from PRINT when next line required
    ld a, (MAXX)
    ld l, a

__PRINT_EOL2:
    dec h
    jr nz, __PRINT_EOL_END

#ifndef DISABLE_SCROLL
    inc h
    push hl
    call __ROM_SCROLL_SCR
    pop hl
#else
    ld hl, (MAXX)
#endif

__PRINT_EOL_END:
    ld (S_POSN), hl
    call SET_SCR_ADDR
    exx
    ret

__PRINT_COM:
    exx
    push hl
    push de
    push bc
    call PRINT_COMMA
    pop bc
    pop de
    pop hl
    ret

__PRINT_TAB:
    ld hl, __PRINT_TAB1
    jr __PRINT_SET_STATE

__PRINT_TAB1:
    ld (MEM0), a
    exx
    ld hl, __PRINT_TAB2
    jr __PRINT_SET_STATE

__PRINT_TAB2:
    ld a, (MEM0)        ; Load tab code (ignore the current one)
    push hl
    push de
    push bc
    ld hl, __PRINT_START
    ld (PRINT_JUMP_STATE), hl
    call PRINT_TAB
    pop bc
    pop de
    pop hl
    ret

__PRINT_AT:
    ld hl, __PRINT_AT1
    jr __PRINT_SET_STATE

__PRINT_NOP:
__PRINT_RESTART:
    ld hl, __PRINT_START

__PRINT_SET_STATE:
    ld (PRINT_JUMP_STATE), hl    ; Saves next entry call
    exx
    ret

__PRINT_AT1:    ; Jumps here if waiting for 1st parameter
    exx
    ld hl, (S_POSN)
    ld a, (MAXY)
    sub h
    ld (S_POSN + 1), a

    ld hl, __PRINT_AT2
    jr __PRINT_SET_STATE

__PRINT_AT2:
    exx
    ld hl, __PRINT_START
    ld (PRINT_JUMP_STATE), hl    ; Saves next entry call
    ld hl, (S_POSN)
    ld a, (MAXX)
    sub l
    ld l, a
    jr __PRINT_EOL_END

__PRINT_DEL:
    call __LOAD_S_POSN        ; Gets current screen position
    dec e
    ld a, -1
    cp e
    jr nz, 3f
    ld hl, (MAXX)
    ld e, l
    dec e
    dec d
    cp d
    jr nz, 3f
    ld d, h
    dec d
3:
    call __SAVE_S_POSN
    jr __PRINT_RESTART

__PRINT_INK:
    ld hl, __PRINT_INK2
    jp __PRINT_SET_STATE

__PRINT_INK2:
    exx
    call INK_TMP
    jp __PRINT_RESTART

__PRINT_PAP:
    ld hl, __PRINT_PAP2
    jp __PRINT_SET_STATE

__PRINT_PAP2:
    exx
    call PAPER_TMP
    jp __PRINT_RESTART

__PRINT_FLA:
    ld hl, __PRINT_FLA2
    jp __PRINT_SET_STATE

__PRINT_FLA2:
    exx
    call FLASH_TMP
    jp __PRINT_RESTART

__PRINT_BRI:
    ld hl, __PRINT_BRI2
    jp __PRINT_SET_STATE

__PRINT_BRI2:
    exx
    call BRIGHT_TMP
    jp __PRINT_RESTART

__PRINT_INV:
    ld hl, __PRINT_INV2
    jp __PRINT_SET_STATE

__PRINT_INV2:
    exx
    call INVERSE_TMP
    jp __PRINT_RESTART

__PRINT_OVR:
    ld hl, __PRINT_OVR2
    jp __PRINT_SET_STATE

__PRINT_OVR2:
    exx
    call OVER_TMP
    jp __PRINT_RESTART

__PRINT_BOLD:
    ld hl, __PRINT_BOLD2
    jp __PRINT_SET_STATE

__PRINT_BOLD2:
    exx
    call BOLD_TMP
    jp __PRINT_RESTART

__PRINT_ITA:
    ld hl, __PRINT_ITA2
    jp __PRINT_SET_STATE

__PRINT_ITA2:
    exx
    call ITALIC_TMP
    jp __PRINT_RESTART

__BOLD:
    push hl
    ld hl, MEM0
    ld b, 8
__BOLD_LOOP:
    ld a, (de)
    ld c, a
    rlca
    or c
    ld (hl), a
    inc hl
    inc de
    djnz __BOLD_LOOP
    pop hl
    ld de, MEM0
    ret


__ITALIC:
    push hl
    ld hl, MEM0
    ex de, hl
    ld bc, 8
    ldir
    ld hl, MEM0
    srl (hl)
    inc hl
    srl (hl)
    inc hl
    srl (hl)
    inc hl
    inc hl
    inc hl
    sla (hl)
    inc hl
    sla (hl)
    inc hl
    sla (hl)
    pop hl
    ld de, MEM0
    ret

PRINT_COMMA:
    call __LOAD_S_POSN
    ld a, e
    and 16
    add a, 16

PRINT_TAB:
    PROC
    LOCAL LOOP, CONTINUE

    inc a
    call __LOAD_S_POSN ; e = current row
    ld d, a
    ld a, e
    cp 21h
    jr nz, CONTINUE
    ld e, -1
CONTINUE:
    ld a, d
    inc e
    sub e  ; A = A - E
    and 31 ;
    ret z  ; Already at position E
    ld b, a
LOOP:
    ld a, ' '
    push bc
    exx
    call __PRINTCHAR
    exx
    pop bc
    djnz LOOP
    ret
    ENDP

PRINT_AT: ; Changes cursor to ROW, COL
    ; COL in A register
    ; ROW in stack

    pop hl    ; Ret address
    ex (sp), hl ; callee H = ROW
    ld l, a
    ex de, hl

    call __IN_SCREEN
    ret nc    ; Return if out of screen
#ifndef DISABLE_SCROLL
    ld hl, TVFLAGS
    res 1, (hl)
#endif
    jp __SAVE_S_POSN

    LOCAL __PRINT_COM
    LOCAL __BOLD
    LOCAL __BOLD_LOOP
    LOCAL __ITALIC
    LOCAL __PRINT_EOL1
    LOCAL __PRINT_EOL2
    LOCAL __PRINT_AT1
    LOCAL __PRINT_AT2
    LOCAL __PRINT_BOLD
    LOCAL __PRINT_BOLD2
    LOCAL __PRINT_ITA
    LOCAL __PRINT_ITA2
    LOCAL __PRINT_INK
    LOCAL __PRINT_PAP
    LOCAL __PRINT_SET_STATE
    LOCAL __PRINT_TABLE
    LOCAL __PRINT_TAB, __PRINT_TAB1, __PRINT_TAB2

__PRINT_TABLE:    ; Jump table for 0 .. 22 codes

    DW __PRINT_NOP    ;  0
    DW __PRINT_NOP    ;  1
    DW __PRINT_NOP    ;  2
    DW __PRINT_NOP    ;  3
    DW __PRINT_NOP    ;  4
    DW __PRINT_NOP    ;  5
    DW __PRINT_COM    ;  6 COMMA
    DW __PRINT_NOP    ;  7
    DW __PRINT_DEL    ;  8 DEL
    DW __PRINT_NOP    ;  9
    DW __PRINT_NOP    ; 10
    DW __PRINT_NOP    ; 11
    DW __PRINT_NOP    ; 12
    DW __PRINT_0Dh    ; 13
    DW __PRINT_BOLD   ; 14
    DW __PRINT_ITA    ; 15
    DW __PRINT_INK    ; 16
    DW __PRINT_PAP    ; 17
    DW __PRINT_FLA    ; 18
    DW __PRINT_BRI    ; 19
    DW __PRINT_INV    ; 20
    DW __PRINT_OVR    ; 21
    DW __PRINT_AT     ; 22 AT
    DW __PRINT_TAB    ; 23 TAB

    ENDP

    pop namespace
