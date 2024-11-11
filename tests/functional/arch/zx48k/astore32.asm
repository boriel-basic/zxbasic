	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (.core.__CALL_BACK__), hl
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_score:
	DEFB 70h
	DEFB 11h
	DEFB 01h
	DEFB 00h
_r:
	DEFW .LABEL.__LABEL0
_r.__DATA__.__PTR__:
	DEFW _r.__DATA__
	DEFW 0
	DEFW 0
_r.__DATA__:
	DEFB 40h
	DEFB 9Ch
	DEFB 00h
	DEFB 00h
	DEFB 0B8h
	DEFB 88h
	DEFB 00h
	DEFB 00h
	DEFB 30h
	DEFB 75h
	DEFB 00h
	DEFB 00h
	DEFB 0A8h
	DEFB 61h
	DEFB 00h
	DEFB 00h
	DEFB 20h
	DEFB 4Eh
	DEFB 00h
	DEFB 00h
	DEFB 98h
	DEFB 3Ah
	DEFB 00h
	DEFB 00h
	DEFB 10h
	DEFB 27h
	DEFB 00h
	DEFB 00h
.LABEL.__LABEL0:
	DEFW 0000h
	DEFB 04h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld de, 1
	ld hl, 14464
	push de
	push hl
	call _main
	ld hl, (_r.__DATA__ + 0)
	ld de, (_r.__DATA__ + 0 + 2)
	ld a, l
	ld (0), a
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
_main:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld hl, _r
	call .core.__ARRAY
	ld de, 1
	ld bc, 4464
	call .core.__STORE32
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld hl, _r
	call .core.__ARRAY
	ld bc, (_score)
	ld de, (_score + 2)
	call .core.__STORE32
	ld l, (ix+4)
	ld h, (ix+5)
	ld e, (ix+6)
	ld d, (ix+7)
	push de
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	inc hl
	push hl
	ld hl, _r
	call .core.__ARRAY
	pop bc
	pop de
	call .core.__STORE32
_main__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	; -------------------------------------------------------------------
	; Simple array Index routine
	; Number of total indexes dimensions - 1 at beginning of memory
	; HL = Start of array memory (First two bytes contains N-1 dimensions)
	; Dimension values on the stack, (top of the stack, highest dimension)
	; E.g. A(2, 4) -> PUSH <4>; PUSH <2>
	; For any array of N dimension A(aN-1, ..., a1, a0)
	; and dimensions D[bN-1, ..., b1, b0], the offset is calculated as
	; O = [a0 + b0 * (a1 + b1 * (a2 + ... bN-2(aN-1)))]
; What I will do here is to calculate the following sequence:
	; ((aN-1 * bN-2) + aN-2) * bN-3 + ...
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/mul16.asm"
	    push namespace core
__MUL16:	; Mutiplies HL with the last value stored into de stack
	    ; Works for both signed and unsigned
	    PROC
	    LOCAL __MUL16LOOP
	    LOCAL __MUL16NOADD
	    ex de, hl
	    pop hl		; Return address
	    ex (sp), hl ; CALLEE caller convention
__MUL16_FAST:
	    ld b, 16
	    ld a, h
	    ld c, l
	    ld hl, 0
__MUL16LOOP:
	    add hl, hl  ; hl << 1
	    sla c
	    rla         ; a,c << 1
	    jp nc, __MUL16NOADD
	    add hl, de
__MUL16NOADD:
	    djnz __MUL16LOOP
	    ret	; Result in hl (16 lower bits)
	    ENDP
	    pop namespace
#line 20 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
#line 24 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
	    push namespace core
__ARRAY_PTR:   ;; computes an array offset from a pointer
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c    ;; HL <-- [HL]
__ARRAY:
	    PROC
	    LOCAL LOOP
	    LOCAL ARRAY_END
	    LOCAL TMP_ARR_PTR            ; Ptr to Array DATA region. Stored temporarily
	    LOCAL LBOUND_PTR, RET_ADDR
	LBOUND_PTR EQU 23698  ; Uses MEMBOT as a temporary variable
	RET_ADDR EQU 23700
	TMP_ARR_PTR EQU 23702
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl      ; DE <-- PTR to Dim sizes table
	    ld (TMP_ARR_PTR), hl  ; HL = Array __DATA__.__PTR__
	    inc hl
	    inc hl
	    ld c, (hl)
	    inc hl
	    ld b, (hl)  ; BC <-- Array __LBOUND__ PTR
	    ld (LBOUND_PTR), bc  ; Store it for later
	    ex de, hl   ; HL <-- PTR to Dim sizes table, DE <-- dummy
	    ex (sp), hl	; Return address in HL, PTR Dim sizes table onto Stack
	    ld (RET_ADDR), hl ; Stores it for later
	    exx
	    pop hl		; Will use H'L' as the pointer to Dim sizes table
	    ld c, (hl)	; Loads Number of dimensions from (hl)
	    inc hl
	    ld b, (hl)
	    inc hl		; Ready
	    exx
	    ld hl, 0	; HL = Element Offset "accumulator"
LOOP:
	    ex de, hl   ; DE = Element Offset
	    ld hl, (LBOUND_PTR)
	    ld a, h
	    or l
	    ld bc, 0
	    jr z, 1f
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    inc hl
	    ld (LBOUND_PTR), hl
1:
	    pop hl      ; Get next index (Ai) from the stack
	    sbc hl, bc  ; Subtract LBOUND
#line 95 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
	    add hl, de	; Adds current index
	    exx			; Checks if B'C' = 0
	    ld a, b		; Which means we must exit (last element is not multiplied by anything)
	    or c
	    jr z, ARRAY_END		; if B'Ci == 0 we are done
	    dec bc				; Decrements loop counter
	    ld e, (hl)			; Loads next dimension size into D'E'
	    inc hl
	    ld d, (hl)
	    inc hl
	    push de
	    exx
	    pop de				; DE = Max bound Number (i-th dimension)
	    call __FNMUL        ; HL <= HL * DE mod 65536
	    jp LOOP
ARRAY_END:
	    ld a, (hl)
	    exx
#line 125 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
	    LOCAL ARRAY_SIZE_LOOP
	    ex de, hl
	    ld hl, 0
	    ld b, a
ARRAY_SIZE_LOOP:
	    add hl, de
	    djnz ARRAY_SIZE_LOOP
#line 135 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
	    ex de, hl
	    ld hl, (TMP_ARR_PTR)
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
	    add hl, de  ; Adds element start
	    ld de, (RET_ADDR)
	    push de
	    ret
	    ;; Performs a faster multiply for little 16bit numbs
	    LOCAL __FNMUL, __FNMUL2
__FNMUL:
	    xor a
	    or h
	    jp nz, __MUL16_FAST
	    or l
	    ret z
	    cp 33
	    jp nc, __MUL16_FAST
	    ld b, l
	    ld l, h  ; HL = 0
__FNMUL2:
	    add hl, de
	    djnz __FNMUL2
	    ret
	    ENDP
	    pop namespace
#line 72 "arch/zx48k/astore32.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/store32.asm"
	    push namespace core
__PISTORE32:
	    push hl
	    push ix
	    pop hl
	    add hl, bc
	    pop bc
__ISTORE32:  ; Load address at hl, and stores E,D,B,C integer at that address
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
__STORE32:	; Stores the given integer in DEBC at address HL
	    ld (hl), c
	    inc hl
	    ld (hl), b
	    inc hl
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    ret
	    pop namespace
#line 73 "arch/zx48k/astore32.bas"
	END
