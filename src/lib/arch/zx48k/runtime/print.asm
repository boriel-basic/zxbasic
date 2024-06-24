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

    ;; Clears ATTR2 flags (OVER 2, etc)
    xor a
    ld (FLAGS2), a

    LOCAL SET_SCR_ADDR
    call __LOAD_S_POSN
    jp __SET_SCR_PTR

    ;; Receives HL = future value of S_POSN
    ;; Stores it at (S_POSN) and refresh screen pointers (ATTR, SCR)
SET_SCR_ADDR:
    ld (S_POSN), hl
    ex de, hl
    ld hl, SCR_SIZE
    or a
    sbc hl, de
    ex de, hl
    dec e
    jp __SET_SCR_PTR

__PRINTCHAR: ; Print character store in accumulator (A register)
    ; Modifies H'L', B'C', A'F', D'E', A

    LOCAL PO_GR_1

    LOCAL __PRCHAR
    LOCAL __PRINT_JUMP
    LOCAL __SRCADDR
    LOCAL __PRINT_UDG
    LOCAL __PRGRAPH
    LOCAL __PRINT_START

PRINT_JUMP_STATE EQU __PRINT_JUMP + 2

__PRINT_JUMP:
    exx                 ; Switch to alternative registers
    jp __PRINT_START    ; Where to jump. If we print 22 (AT), next two calls jumps to AT1 and AT2 respectively

__PRINT_START:

__PRINT_CHR:
    cp ' '
    jr c, __PRINT_SPECIAL    ; Characters below ' ' are special ones
    ex af, af'               ; Saves a value (char to print) for later

    ld hl, (S_POSN)
    dec l
    jr nz, 1f
    ld l, SCR_COLS - 1
    dec h
    jr nz, 2f

#ifndef __ZXB_DISABLE_SCROLL
    inc h
    push hl
    call __SCROLL_SCR
    pop hl
#else
    ld h, SCR_ROWS - 1
#endif
2:
    call SET_SCR_ADDR
    jr 4f
1:
    ld (S_POSN), hl
4:
    ex af, af'

    cp 80h    ; Is it a "normal" (printable) char
    jr c, __SRCADDR

    cp 90h    ; Is it an UDG?
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

#ifndef __ZXB_DISABLE_BOLD
    bit 2, (iy + $47)
    call nz, __BOLD
#endif

#ifndef __ZXB_DISABLE_ITALIC
    bit 4, (iy + $47)
    call nz, __ITALIC
#endif

    ld hl, (DFCC)
    push hl

    ld b, 8 ; 8 bytes per char

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
    nop         ; Set to one of the values above

INVERSE_MODE:   ; 00 -> NOP -> INVERSE 0
    nop         ; 2F -> CPL -> INVERSE 1

    ld (hl), a

    inc de
    inc h     ; Next line
    djnz __PRCHAR

    pop hl
    inc hl
    ld (DFCC), hl

    ld hl, (DFCCL)   ; current ATTR Pos
    inc hl
    ld (DFCCL), hl
    dec hl
    call __SET_ATTR
    exx
    ret

; ------------- SPECIAL CHARS (< 32) -----------------

__PRINT_SPECIAL:    ; Jumps here if it is a special char
    ld hl, __PRINT_TABLE
    jp JUMP_HL_PLUS_2A

PRINT_EOL:        ; Called WHENEVER there is no ";" at end of PRINT sentence
    exx

__PRINT_0Dh:        ; Called WHEN printing CHR$(13)
    ld hl, (S_POSN)
    dec l
    jr nz, 1f
    dec h
    jr nz, 1f
#ifndef __ZXB_DISABLE_SCROLL
    inc h
    push hl
    call __SCROLL_SCR
    pop hl
#else
    ld h, SCR_ROWS - 1
#endif
1:
    ld l, 1

__PRINT_EOL_END:
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
    ld hl, __PRINT_TAB2
    jr __PRINT_SET_STATE

__PRINT_TAB2:
    ld a, (MEM0)        ; Load tab code (ignore the current one)
    ld hl, __PRINT_START
    ld (PRINT_JUMP_STATE), hl
    exx
    push hl
    push bc
    push de
    call PRINT_TAB
    pop de
    pop bc
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
    ld hl, (S_POSN)
    ld h, a
    ld a, SCR_ROWS
    sub h
    ld (S_POSN + 1), a

    ld hl, __PRINT_AT2
    jr __PRINT_SET_STATE

__PRINT_AT2:
    call __LOAD_S_POSN
    ld e, a
    call __SAVE_S_POSN
    jr __PRINT_RESTART

__PRINT_DEL:
    call __LOAD_S_POSN        ; Gets current screen position
    dec e
    ld a, -1
    cp e
    jr nz, 3f
    ld e, SCR_COLS - 2
    dec d
    cp d
    jr nz, 3f
    ld d, SCR_ROWS - 1
3:
    call __SAVE_S_POSN
    exx
    ret

__PRINT_INK:
    ld hl, __PRINT_INK2
    jr __PRINT_SET_STATE

__PRINT_INK2:
    call INK_TMP
    jr __PRINT_RESTART

__PRINT_PAP:
    ld hl, __PRINT_PAP2
    jr __PRINT_SET_STATE

__PRINT_PAP2:
    call PAPER_TMP
    jr __PRINT_RESTART

__PRINT_FLA:
    ld hl, __PRINT_FLA2
    jr __PRINT_SET_STATE

__PRINT_FLA2:
    call FLASH_TMP
    jr __PRINT_RESTART

__PRINT_BRI:
    ld hl, __PRINT_BRI2
    jr __PRINT_SET_STATE

__PRINT_BRI2:
    call BRIGHT_TMP
    jr __PRINT_RESTART

__PRINT_INV:
    ld hl, __PRINT_INV2
    jr __PRINT_SET_STATE

__PRINT_INV2:
    call INVERSE_TMP
    jr __PRINT_RESTART

__PRINT_OVR:
    ld hl, __PRINT_OVR2
    jr __PRINT_SET_STATE

__PRINT_OVR2:
    call OVER_TMP
    jr __PRINT_RESTART

#ifndef __ZXB_DISABLE_BOLD
__PRINT_BOLD:
    ld hl, __PRINT_BOLD2
    jp __PRINT_SET_STATE

__PRINT_BOLD2:
    call BOLD_TMP
    jp __PRINT_RESTART
#endif

#ifndef __ZXB_DISABLE_ITALIC
__PRINT_ITA:
    ld hl, __PRINT_ITA2
    jp __PRINT_SET_STATE

__PRINT_ITA2:
    call ITALIC_TMP
    jp __PRINT_RESTART
#endif

#ifndef __ZXB_DISABLE_BOLD
    LOCAL __BOLD

__BOLD:
    push hl
    ld hl, MEM0
    ld b, 8
1:
    ld a, (de)
    ld c, a
    rlca
    or c
    ld (hl), a
    inc hl
    inc de
    djnz 1b
    pop hl
    ld de, MEM0
    ret
#endif

#ifndef __ZXB_DISABLE_ITALIC
    LOCAL __ITALIC

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
#endif

#ifndef __ZXB_DISABLE_SCROLL
    LOCAL __SCROLL_SCR

#  ifdef __ZXB_ENABLE_BUFFER_SCROLL
__SCROLL_SCR:  ;; Scrolls screen and attrs 1 row up
    ld de, (SCREEN_ADDR)
    ld b, 3
3:
    push bc
    ld a, 8
1:
    ld hl, 32
    add hl, de
    ld bc, 32 * 7
    push de
    ldir
    pop de
    inc d
    dec a
    jr nz, 1b
    push hl
    ld bc, -32 - 256 * 7
    add hl, bc
    ex de, hl
    ld a, 8
2:
    ld bc, 32
    push hl
    push de
    ldir
    pop de
    pop hl
    inc d
    inc h
    dec a
    jr nz, 2b
    pop de
    pop bc
    djnz 3b

    dec de
    ld h, d
    ld l, e
    ld a, 8
3:
    push hl
    push de
    ld (hl), b
    dec de
    ld bc, 31
    lddr
    pop de
    pop hl
    dec d
    dec h
    dec a
    jr nz, 3b

    ld de, (SCREEN_ATTR_ADDR)
    ld hl, 32
    add hl, de
    ld bc, 32 * 23
    ldir

    ld h, d
    ld l, e
    ld a, (ATTR_P)
    ld (hl), a
    inc de
    ld bc, 31
    ldir
    ret
#  else
__SCROLL_SCR EQU 0DFEh  ; Use ROM SCROLL
#  endif
#endif


PRINT_COMMA:
    call __LOAD_S_POSN
    ld a, e
    and 16
    add a, 16

PRINT_TAB:
    ; Tabulates the number of spaces in A register
    ; If the current cursor position is already A, does nothing
    PROC
    LOCAL LOOP

    call __LOAD_S_POSN ; e = current row
    sub e
    and 31
    ret z

    ld b, a
LOOP:
    ld a, ' '
    call __PRINTCHAR
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
    jp __SAVE_S_POSN

    LOCAL __PRINT_COM
    LOCAL __PRINT_AT1
    LOCAL __PRINT_AT2
    LOCAL __PRINT_BOLD
    LOCAL __PRINT_ITA
    LOCAL __PRINT_INK
    LOCAL __PRINT_PAP
    LOCAL __PRINT_SET_STATE
    LOCAL __PRINT_TABLE
    LOCAL __PRINT_TAB, __PRINT_TAB1, __PRINT_TAB2

#ifndef __ZXB_DISABLE_ITALIC
    LOCAL __PRINT_ITA2
#else
    __PRINT_ITA EQU __PRINT_NOP
#endif

#ifndef __ZXB_DISABLE_BOLD
    LOCAL __PRINT_BOLD2
#else
    __PRINT_BOLD EQU __PRINT_NOP
#endif

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
