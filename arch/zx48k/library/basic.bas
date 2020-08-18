
/' --------------------------------------------------------------------------------------
BASIC Interpreter KEYIN command for Sinclair BASIC
A function to execute a string as a BASIC command
Copyright 2018 Miguel Angel Rodriguez Jodar (mcleod_ideafix). zxprojects.com

   Licensed under the Apache License, Version 2.0 (the "License")
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

USAGE:

Build a string with valid BASIC tokens and pass it to the EvalBASIC() function
execute it.

10 EvalBASIC("BEEP 1,20"): REM this will execute command BEEP 1,20

Multiple sentences can be executed as well:

20 a = EvalBASIC("FOR n=0 TO 7: BORDER n: BEEP 0.1,n*8: NEXT n")

Of course, the parameter can be any valid string parameter, so a BASIC program
can build a sentence or a group of sentences and execute them using this
function. Think of it as a even more versatile VAL or VAL$ function.

Note that this function returns the value of the BC register.

BUGS:
Most probably a lot. I'm still learning how to interact with the BASIC interpreter.
-------------------------------------------------------------------------------------- '/


#ifndef __LIBRARY_EVALBASIC__
REM Avoid recursive / multiple inclusion
#define __LIBRARY_EVALBASIC__

#pragma push(case_insensitive)
#pragma case_insensitive = true

Function fastcall EvalBASIC(ByVal basic as String) as Uinteger
    ASM
    PROC

    LOCAL E_LINE
    LOCAL CH_ADD
    LOCAL SET_MIN
    LOCAL MAKE_ROOM
    LOCAL K_CUR
    LOCAL LINE_SCAN
    LOCAL LINE_RUN
    LOCAL DEF_ADD
    LOCAL NEWPPC
    LOCAL NSPPC
    LOCAL PPC
    LOCAL SUBPPC
    LOCAL NXTLIN

    E_LINE            equ 5c59h
    CH_ADD            equ 5c5dh
    SET_MIN           equ 16b0h
    MAKE_ROOM         equ 1655h
    K_CUR             equ 5c5bh
    LINE_SCAN         equ 1b17h
    LINE_RUN          equ 1b8ah
    DEF_ADD           equ 5c0bh
    NEWPPC            equ 5c42h
    NSPPC             equ 5c44h
    PPC               equ 5c45h
    SUBPPC            equ 5c47h
    NXTLIN            equ 5c55h

    ld a, h
    or l
    ret z              ; Empty (NULL) string? return

    ld de,(CH_ADD)     ; Save some BASIC pointers
    push de            ; that will change while our string is
    ld de,(NXTLIN)     ; being executed, so at the end of it,
    push de            ; normal program can resume execution
    ld de,(PPC)        ;
    push de            ;
    ld a,(SUBPPC)      ;
    push af            ;
    ld de,(NEWPPC)     ;
    push de            ;
    ld a,(NSPPC)       ;
    push af            ;
    push ix            ; Not sure if IX is modified, but ...

    ld c, (hl)
    inc hl
    ld b, (hl)         ; BC = string length
    inc hl             ; HL = start of string
    push hl
    push bc            ; And save both address and length for future use
    call SET_MIN       ; Clear edit and work space
    ld hl,(E_LINE)     ; HL = start of editor area
    pop bc             ; Retrieve temporarily string address
    push bc
    call MAKE_ROOM     ; Make room for BC bytes (length of the string) starting in the editor area (HL)
    pop bc
    pop hl             ; Finally, retrieve both string address and length
    ld de,(E_LINE)     ; Destination: recently opened space in editor area
    ldir               ; Transfer string into there (key it in into editor)
    ld (K_CUR),de      ; Update K_CUR to point to the end of the "keyed in" line
    call LINE_SCAN     ; Check syntax
    bit 7,(iy+0)       ; If syntax error...
    ld a, ERROR_NonsenseInBasic
    jp z, __ERROR      ; ... return with C Nonsense in BASIC
    ld hl,(E_LINE)     ; Copy the start of the now syntax clean line to execute
    ld (CH_ADD),hl     ; into CH_ADD to start executing
    set 7,(iy+1)       ; Signal we are going to execute a line
    ld (iy+0),0xff     ; Clear ERR-NO (OK)
    ld (iy+10),1       ; Point NSPPC to the first statement into the line
    call LINE_RUN      ; Execute the line

    pop ix
    pop af             ;
    ld (NSPPC),a       ; Restore BASIC pointers
    pop hl             ; to resume execution of the
    ld (NEWPPC),hl     ; next line/sentence by the
    pop af             ; interpreter
    ld (SUBPPC),a      ;
    pop hl             ;
    ld (PPC),hl        ;
    pop hl             ;
    ld (NXTLIN),hl     ;
    pop hl             ;
    ld (CH_ADD),hl     ;

    ENDP
    END ASM
End Function

#pragma pop(case_insensitive)
#require "error.asm"

#endif