#include once <alloc.asm>
#include once <free.asm>
#include once <print.asm>

LOAD_CODE:
; This function will implement the LOAD CODE Routine
; Parameters in the stack are HL => String with LOAD name
; (only first 12 chars will be taken into account)
; DE = START address of CODE to save
; BC = Length of data in bytes
; A = 1 => LOAD 0 => Verify

    PROC
    
    LOCAL LOAD_CONT, LOAD_CONT2, LOAD_CONT3
    LOCAL LD_BYTES
    LOCAL LOAD_HEADER
    LOCAL LD_LOOK_H
    LOCAL HEAD1
    LOCAL TMP_HEADER
    LOCAL LD_NAME
    LOCAL LD_CH_PR
    LOCAL LOAD_END
    LOCAL VR_CONTROL, VR_CONT_1, VR_CONT_2

HEAD1 EQU MEM0 + 8 ; Uses CALC Mem for temporary storage
               ; Must skip first 8 bytes used by
               ; PRINT routine
TMP_HEADER EQU HEAD1 + 17 ; Temporary HEADER2 pointer storage

LD_BYTES EQU 0556h ; ROM Routine LD-BYTES
TMP_FLAG EQU 23655 ; Uses BREG as a Temporary FLAG
    
    pop hl         ; Return address
    pop af         ; A = 1 => LOAD; A = 0 => VERIFY
    pop bc         ; data length in bytes
    pop de         ; address start
    ex (sp), hl    ; CALLE => now hl = String
    
__LOAD_CODE: ; INLINE version
    push ix ; saves IX
    ld (TMP_FLAG), a ; Stores verify/load flag

    ; Prepares temporary 1st header descriptor
    ld ix, HEAD1
    ld (ix + 0), 3     ; ZXBASIC ALWAYS uses CODE
    ld (ix + 1), 0FFh  ; Wildcard for empty string

    ld (ix + 11), c
    ld (ix + 12), b ; Store length in bytes
    ld (ix + 13), e
    ld (ix + 14), d ; Store address in bytes

    ld a, h
    or l
    ld b, h
    ld c, l
    jr z, LOAD_HEADER ; NULL STRING => LOAD ""
    
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl

    ld a, b
    or c
    jr z, LOAD_CONT2 ; NULL STRING => LOAD ""

    ; Fill with blanks
    push hl
    push bc
    ld hl, HEAD1 + 2
    ld de, HEAD1 + 3
    ld bc, 8
    ld (hl), ' '
    ldir
    pop bc
    pop hl
    
LOAD_HEADER:
    ex de, hl  ; Saves HL in DE
    ld hl, 10
    or a
    sbc hl, bc ; Test BC > 10?
    ex de, hl  ; Retrieve HL
    jr nc, LOAD_CONT ; Ok BC <= 10
    ld bc, 10 ; BC at most 10 chars
            
LOAD_CONT:
    ld de, HEAD1 + 1
    ldir     ; Copy String block NAME in header

LOAD_CONT2:
    ld bc, 17; 2nd Header
    call __MEM_ALLOC

    ld a, h
    or l
    jr nz, LOAD_CONT3; there's memory

    ld a, ERROR_OutOfMemory
    jp __ERROR

LOAD_CONT3:
    ld (TMP_HEADER), hl
    push hl
    pop ix

;; LD-LOOK-H --- RIPPED FROM ROM at 0x767
LD_LOOK_H:
    push ix                 ; save IX
    ld de, 17               ; seventeen bytes
    xor a                   ; reset zero flag
    scf                     ; set carry flag
    
    call LD_BYTES           ; routine LD-BYTES loads a header from tape
                            ; to second descriptor.
    pop ix                  ; restore IX
    jr nc, LD_LOOK_H        ; loop back to LD-LOOK-H until header found.

    ld c, 80h               ; C has bit 7 set to indicate header type mismatch as
                            ; a default startpoint.

    ld a, (ix + 0)          ; compare loaded type
    cp 3		            ; with expected bytes header
    jr nz, LD_TYPE          ; forward to LD-TYPE with mis-match.

    ld c, -10               ; set C to minus ten - will count characters
                            ; up to zero.
LD_TYPE:
    cp 4                    ; check if type in acceptable range 0 - 3.
    jr nc, LD_LOOK_H        ; back to LD-LOOK-H with 4 and over.
                            ; else A indicates type 0-3.
    call PRINT_TAPE_MESSAGES; Print tape msg
    ld hl, HEAD1 + 1        ; point HL to 1st descriptor.
    ld de, (TMP_HEADER)     ; point DE to 2nd descriptor.
    ld b, 10                ; the count will be ten characters for the
                            ; filename.

    ld a, (hl)              ; fetch first character and test for 
    inc a                   ; value 255.
    jr nz, LD_NAME          ; forward to LD-NAME if not the wildcard.

;   but if it is the wildcard, then add ten to C which is minus ten for a type
;   match or -128 for a type mismatch. Although characters have to be counted
;   bit 7 of C will not alter from state set here.

    ld a, c                 ; transfer $F6 or $80 to A
    add a, b                ; add 10 
    ld c, a                 ; place result, zero or -118, in C.

;   At this point we have either a type mismatch, a wildcard match or ten
;   characters to be counted. The characters must be shown on the screen.

;; LD-NAME
LD_NAME:
    inc de                  ; address next input character
    ld a, (de)              ; fetch character
    cp (hl)                 ; compare to expected
    inc hl                  ; address next expected character
    jr nz, LD_CH_PR         ; forward to LD-CH-PR with mismatch

    inc c                   ; increment matched character count

;; LD-CH-PR
LD_CH_PR:
    call __PRINTCHAR        ; PRINT-A prints character
    djnz LD_NAME            ; loop back to LD-NAME for ten characters.

    bit 7, c                ; test if all matched
    jr nz, LD_LOOK_H        ; back to LD-LOOK-H if not

;   else print a terminal carriage return.

    ld a, 0Dh               ; prepare carriage return.
    call __PRINTCHAR        ; PRINT-A outputs it.

    ld a, (HEAD1)
    cp 03                   ; Only "bytes:" header is used un ZX BASIC
    jr nz, LD_LOOK_H

    ; Ok, ready to check for bytes start and end

VR_CONTROL:
    ld e, (ix + 11)         ; fetch length of new data
    ld d, (ix + 12)         ; to DE.

    ld hl, HEAD1 + 11
    ld a, (hl)              ; fetch length of old data (orig. header)
    inc hl
    ld h, (hl)              ; to HL
    ld l, a
    or h                    ; check length of old for zero. (Carry reset)
    jr z, VR_CONT_1         ; forward to VR-CONT-1 if length unspecified
                            ; e.g. LOAD "x" CODE
    sbc hl, de
    jr nz, LOAD_ERROR       ; Lenghts don't match

VR_CONT_1:
    ld hl, HEAD1 + 13       ; fetch start of old data (orig. header)
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    or h                    ; check start for zero (unespecified)
    jr nz, VR_CONT_2        ; Jump if there was a start

    ld l, (ix + 13)         ; otherwise use destination in header
    ld h, (ix + 14)         ; and load code at addr. saved from

VR_CONT_2:
    push hl
    pop ix                  ; Transfer load addr to IX

    ld a, (TMP_FLAG)        ; load verify/load flag
    sra a                   ; shift bit 0 to Carry (1 => Load, 0 = Verify), A = 0
    dec a                   ; a = 0xFF (Data) 
    call LD_BYTES
    jr c, LOAD_END         ; if carry, load/verification was ok

LOAD_ERROR:
    ; Sets ERR_NR with Tape Loading, and returns
    ld a, ERROR_TapeLoadingErr
    ld (ERR_NR), a

LOAD_END:
    pop ix                  ; Recovers stack frame pointer
    ld hl, (TMP_HEADER)     ; Recovers tmp_header pointer
    jp MEM_FREE             ; Returns via FREE_MEM, freeing tmp header
    
    ENDP


PRINT_TAPE_MESSAGES:

    PROC

    LOCAL LOOK_NEXT_TAPE_MSG
    LOCAL PRINT_TAPE_MSG

    ; Print tape messages according to A value
    ; Each message starts with a carriage return and 
    ; ends with last char having its bit 7 set

    ; A = 0 => '\nProgram: '
    ; A = 1 => '\nNumber array: '
    ; A = 2 => '\nCharacter array: '
    ; A = 3 => '\nBytes: '

    push bc

    ld hl, 09C0h            ; address base of last 4 tape messages
    ld b, a
    inc b                   ; avoid 256-loop if b == 0
    ld a, 0Dh               ; Msg start mark        

    ; skip memory bytes looking for next tape msg entry
    ; each msg ends when 0Dh is fond
LOOK_NEXT_TAPE_MSG:
    inc hl                  ; Point to next char
    cp (hl)                 ; Is it 0Dh?
    jr nz, LOOK_NEXT_TAPE_MSG
                            ; Ok next message found
    djnz LOOK_NEXT_TAPE_MSG ; Repeat if more msg to skip

PRINT_TAPE_MSG:
                            ; Ok. This will print bytes after (HL)
                            ; until one of them has bit 7 set
    ld a, (hl)
    and 7Fh		    ; Clear bit 7 of A
    call __PRINTCHAR

    ld a, (hl)
    inc hl
    add a, a                ; Carry if A >= 128
    jr nc, PRINT_TAPE_MSG

    pop bc
    ret
    
    ENDP
