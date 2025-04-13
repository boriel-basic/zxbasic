	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld (.core.__CALL_BACK__), sp
	ei
	call .core.__MEM_INIT
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines HEAP SIZE
.core.ZXBASIC_HEAP_SIZE EQU 4768
.core.ZXBASIC_MEM_HEAP:
	DEFS 4768
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_i:
	DEFB 00
_a:
	DEFW .LABEL.__LABEL5
_a.__DATA__.__PTR__:
	DEFW _a.__DATA__
	DEFW 0
	DEFW 0
_a.__DATA__:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
.LABEL.__LABEL5:
	DEFW 0000h
	DEFB 01h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	xor a
	ld (_i), a
	jp .LABEL.__LABEL0
.LABEL.__LABEL3:
	ld a, 3
	call .core.__READ
	push af
	ld a, (_i)
	ld l, a
	ld h, 0
	push hl
	ld hl, _a
	call .core.__ARRAY
	pop af
	ld (hl), a
	ld a, (_i)
	ld l, a
	ld h, 0
	push hl
	ld hl, _a
	call .core.__ARRAY
	ld a, (hl)
	ld (0), a
	ld hl, _i
	inc (hl)
.LABEL.__LABEL0:
	ld a, 9
	ld hl, (_i - 1)
	cp h
	jp nc, .LABEL.__LABEL3
	ld bc, 0
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
___DATA__FUNCPTR__0:
	ld a, (_i)
	ld h, 6
	call .core.__MUL8_FAST
___DATA__FUNCPTR__0__leave:
	ret
___DATA__FUNCPTR__1:
	ld a, (_a.__DATA__ + 0)
___DATA__FUNCPTR__1__leave:
	ret
___DATA__FUNCPTR__2:
	ld a, (_a.__DATA__ + 1)
___DATA__FUNCPTR__2__leave:
	ret
___DATA__FUNCPTR__3:
	ld a, (_a.__DATA__ + 2)
___DATA__FUNCPTR__3__leave:
	ret
___DATA__FUNCPTR__4:
	ld a, (_a.__DATA__ + 3)
___DATA__FUNCPTR__4__leave:
	ret
___DATA__FUNCPTR__5:
	ld a, (_a.__DATA__ + 4)
___DATA__FUNCPTR__5__leave:
	ret
.DATA.__DATA__0:
	DEFB 3
	DEFB 2
	DEFB 3
	DEFB 4
	DEFB 83h
	DEFW ___DATA__FUNCPTR__0
	DEFB 3
	DEFB 7
	DEFB 3
	DEFB 0
.DATA.__DATA__1:
	DEFB 83h
	DEFW ___DATA__FUNCPTR__1
	DEFB 83h
	DEFW ___DATA__FUNCPTR__2
	DEFB 83h
	DEFW ___DATA__FUNCPTR__3
	DEFB 83h
	DEFW ___DATA__FUNCPTR__4
	DEFB 83h
	DEFW ___DATA__FUNCPTR__5
__DATA__END:
	DEFB 00h
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/mul8.asm"
	    push namespace core
__MUL8:		; Performs 8bit x 8bit multiplication
	    PROC
	    ;LOCAL __MUL8A
	    LOCAL __MUL8LOOP
	    LOCAL __MUL8B
	    ; 1st operand (byte) in A, 2nd operand into the stack (AF)
	    pop hl	; return address
	    ex (sp), hl ; CALLE convention
;;__MUL8_FAST: ; __FASTCALL__ entry
	;;	ld e, a
	;;	ld d, 0
	;;	ld l, d
	;;
	;;	sla h
	;;	jr nc, __MUL8A
	;;	ld l, e
	;;
;;__MUL8A:
	;;
	;;	ld b, 7
;;__MUL8LOOP:
	;;	add hl, hl
	;;	jr nc, __MUL8B
	;;
	;;	add hl, de
	;;
;;__MUL8B:
	;;	djnz __MUL8LOOP
	;;
	;;	ld a, l ; result = A and HL  (Truncate to lower 8 bits)
__MUL8_FAST: ; __FASTCALL__ entry, a = a * h (8 bit mul) and Carry
	    ld b, 8
	    ld l, a
	    xor a
__MUL8LOOP:
	    add a, a ; a *= 2
	    sla l
	    jp nc, __MUL8B
	    add a, h
__MUL8B:
	    djnz __MUL8LOOP
	    ret		; result = HL
	    ENDP
	    pop namespace
#line 95 "arch/zx48k/opt3_data2.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/array/array.asm"
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/fmul16.asm"
	;; Performs a faster multiply for little 16bit numbs
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/mul16.asm"
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
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/arith/fmul16.asm"
	    push namespace core
__FMUL16:
	    xor a
	    or h
	    jp nz, __MUL16_FAST
	    or l
	    ret z
	    cp 33
	    jp nc, __MUL16_FAST
	    ld b, l
	    ld l, h  ; HL = 0
1:
	    add hl, de
	    djnz 1b
	    ret
	    pop namespace
#line 20 "/zxbasic/src/lib/arch/zx48k/runtime/array/array.asm"
#line 24 "/zxbasic/src/lib/arch/zx48k/runtime/array/array.asm"
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
	    LOCAL LBOUND_PTR, UBOUND_PTR ; LBound and UBound PTR indexes
	    LOCAL RET_ADDR               ; Contains the return address popped from the stack
	LBOUND_PTR EQU 23698           ; Uses MEMBOT as a temporary variable
	UBOUND_PTR EQU LBOUND_PTR + 2  ; Next 2 bytes for UBOUND PTR
	RET_ADDR EQU UBOUND_PTR + 2    ; Next 2 bytes for RET_ADDR
	TMP_ARR_PTR EQU RET_ADDR + 2   ; Next 2 bytes for TMP_ARR_PTR
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
#line 66 "/zxbasic/src/lib/arch/zx48k/runtime/array/array.asm"
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
	    ld b, h
	    ld c, l
	    jr z, 1f
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    inc hl
	    ld (LBOUND_PTR), hl
1:
	    pop hl      ; Get next index (Ai) from the stack
	    sbc hl, bc  ; Subtract LBOUND
#line 116 "/zxbasic/src/lib/arch/zx48k/runtime/array/array.asm"
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
	    call __FMUL16        ; HL <= HL * DE mod 65536
	    jp LOOP
ARRAY_END:
	    ld a, (hl)
	    exx
#line 146 "/zxbasic/src/lib/arch/zx48k/runtime/array/array.asm"
	    LOCAL ARRAY_SIZE_LOOP
	    ex de, hl
	    ld hl, 0
	    ld b, a
ARRAY_SIZE_LOOP:
	    add hl, de
	    djnz ARRAY_SIZE_LOOP
#line 156 "/zxbasic/src/lib/arch/zx48k/runtime/array/array.asm"
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
	    ENDP
	    pop namespace
#line 96 "arch/zx48k/opt3_data2.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
	;; This implements READ & RESTORE functions
	;; Reads a new element from the DATA Address code
	;; Updates the DATA_ADDR read ptr for the next read
	;; Data codification is 1 byte for type followed by data bytes
	;; Byte type is encoded as follows
;; 00: End of data
;; 01: String
;; 02: Byte
;; 03: Ubyte
;; 04: Integer
;; 05: UInteger
;; 06: Long
;; 07: ULong
;; 08: Fixed
;; 09: Float
	;; bit7 is set for a parameter-less function
	;; In that case, the next two bytes are the ptr of the function to jump
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/error.asm"
	; Simple error control routines
; vim:ts=4:et:
	    push namespace core
	ERR_NR    EQU    23610    ; Error code system variable
	; Error code definitions (as in ZX spectrum manual)
; Set error code with:
	;    ld a, ERROR_CODE
	;    ld (ERR_NR), a
	ERROR_Ok                EQU    -1
	ERROR_SubscriptWrong    EQU     2
	ERROR_OutOfMemory       EQU     3
	ERROR_OutOfScreen       EQU     4
	ERROR_NumberTooBig      EQU     5
	ERROR_InvalidArg        EQU     9
	ERROR_IntOutOfRange     EQU    10
	ERROR_NonsenseInBasic   EQU    11
	ERROR_InvalidFileName   EQU    14
	ERROR_InvalidColour     EQU    19
	ERROR_BreakIntoProgram  EQU    20
	ERROR_TapeLoadingErr    EQU    26
	; Raises error using RST #8
__ERROR:
	    ld (__ERROR_CODE), a
	    rst 8
__ERROR_CODE:
	    nop
	    ret
	; Sets the error system variable, but keeps running.
	; Usually this instruction if followed by the END intermediate instruction.
__STOP:
	    ld (ERR_NR), a
	    ret
	    pop namespace
#line 23 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/loadstr.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/alloc.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the MIT license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the MIT license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be freed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/heapinit.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the BSD license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the BSD license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be breed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
	; ---------------------------------------------------------------------
	;  __MEM_INIT must be called to initalize this library with the
	; standard parameters
	; ---------------------------------------------------------------------
	    push namespace core
__MEM_INIT: ; Initializes the library using (RAMTOP) as start, and
	    ld hl, ZXBASIC_MEM_HEAP  ; Change this with other address of heap start
	    ld de, ZXBASIC_HEAP_SIZE ; Change this with your size
	; ---------------------------------------------------------------------
	;  __MEM_INIT2 initalizes this library
; Parameters:
;   HL : Memory address of 1st byte of the memory heap
;   DE : Length in bytes of the Memory Heap
	; ---------------------------------------------------------------------
__MEM_INIT2:
	    ; HL as TOP
	    PROC
	    dec de
	    dec de
	    dec de
	    dec de        ; DE = length - 4; HL = start
	    ; This is done, because we require 4 bytes for the empty dummy-header block
	    xor a
	    ld (hl), a
	    inc hl
    ld (hl), a ; First "free" block is a header: size=0, Pointer=&(Block) + 4
	    inc hl
	    ld b, h
	    ld c, l
	    inc bc
	    inc bc      ; BC = starts of next block
	    ld (hl), c
	    inc hl
	    ld (hl), b
	    inc hl      ; Pointer to next block
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    inc hl      ; Block size (should be length - 4 at start); This block contains all the available memory
	    ld (hl), a ; NULL (0000h) ; No more blocks (a list with a single block)
	    inc hl
	    ld (hl), a
	    ld a, 201
	    ld (__MEM_INIT), a; "Pokes" with a RET so ensure this routine is not called again
	    ret
	    ENDP
	    pop namespace
#line 70 "/zxbasic/src/lib/arch/zx48k/runtime/alloc.asm"
	; ---------------------------------------------------------------------
	; MEM_ALLOC
	;  Allocates a block of memory in the heap.
	;
	; Parameters
	;  BC = Length of requested memory block
	;
; Returns:
	;  HL = Pointer to the allocated block in memory. Returns 0 (NULL)
	;       if the block could not be allocated (out of memory)
	; ---------------------------------------------------------------------
	    push namespace core
MEM_ALLOC:
__MEM_ALLOC: ; Returns the 1st free block found of the given length (in BC)
	    PROC
	    LOCAL __MEM_LOOP
	    LOCAL __MEM_DONE
	    LOCAL __MEM_SUBTRACT
	    LOCAL __MEM_START
	    LOCAL TEMP, TEMP0
	TEMP EQU TEMP0 + 1
	    ld hl, 0
	    ld (TEMP), hl
__MEM_START:
	    ld hl, ZXBASIC_MEM_HEAP  ; This label point to the heap start
	    inc bc
	    inc bc  ; BC = BC + 2 ; block size needs 2 extra bytes for hidden pointer
__MEM_LOOP:  ; Loads lengh at (HL, HL+). If Lenght >= BC, jump to __MEM_DONE
	    ld a, h ;  HL = NULL (No memory available?)
	    or l
#line 113 "/zxbasic/src/lib/arch/zx48k/runtime/alloc.asm"
	    ret z ; NULL
#line 115 "/zxbasic/src/lib/arch/zx48k/runtime/alloc.asm"
	    ; HL = Pointer to Free block
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl          ; DE = Block Length
	    push hl         ; HL = *pointer to -> next block
	    ex de, hl
	    or a            ; CF = 0
	    sbc hl, bc      ; FREE >= BC (Length)  (HL = BlockLength - Length)
	    jp nc, __MEM_DONE
	    pop hl
	    ld (TEMP), hl
	    ex de, hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    ex de, hl
	    jp __MEM_LOOP
__MEM_DONE:  ; A free block has been found.
	    ; Check if at least 4 bytes remains free (HL >= 4)
	    push hl
	    exx  ; exx to preserve bc
	    pop hl
	    ld bc, 4
	    or a
	    sbc hl, bc
	    exx
	    jp nc, __MEM_SUBTRACT
	    ; At this point...
	    ; less than 4 bytes remains free. So we return this block entirely
	    ; We must link the previous block with the next to this one
	    ; (DE) => Pointer to next block
	    ; (TEMP) => &(previous->next)
	    pop hl     ; Discard current block pointer
	    push de
	    ex de, hl  ; DE = Previous block pointer; (HL) = Next block pointer
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a    ; HL = (HL)
	    ex de, hl  ; HL = Previous block pointer; DE = Next block pointer
TEMP0:
	    ld hl, 0   ; Pre-previous block pointer
	    ld (hl), e
	    inc hl
	    ld (hl), d ; LINKED
	    pop hl ; Returning block.
	    ret
__MEM_SUBTRACT:
	    ; At this point we have to store HL value (Length - BC) into (DE - 2)
	    ex de, hl
	    dec hl
	    ld (hl), d
	    dec hl
	    ld (hl), e ; Store new block length
	    add hl, de ; New length + DE => free-block start
	    pop de     ; Remove previous HL off the stack
	    ld (hl), c ; Store length on its 1st word
	    inc hl
	    ld (hl), b
	    inc hl     ; Return hl
	    ret
	    ENDP
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/loadstr.asm"
	; Loads a string (ptr) from HL
	; and duplicates it on dynamic memory again
	; Finally, it returns result pointer in HL
	    push namespace core
__ILOADSTR:		; This is the indirect pointer entry HL = (HL)
	    ld a, h
	    or l
	    ret z
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
__LOADSTR:		; __FASTCALL__ entry
	    ld a, h
	    or l
	    ret z	; Return if NULL
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    dec hl  ; BC = LEN(a$)
	    inc bc
	    inc bc	; BC = LEN(a$) + 2 (two bytes for length)
	    push hl
	    push bc
	    call __MEM_ALLOC
	    pop bc  ; Recover length
	    pop de  ; Recover origin
	    ld a, h
	    or l
	    ret z	; Return if NULL (No memory)
	    ex de, hl ; ldir takes HL as source, DE as destiny, so SWAP HL,DE
	    push de	; Saves destiny start
	    ldir	; Copies string (length number included)
	    pop hl	; Recovers destiny in hl as result
	    ret
	    pop namespace
#line 24 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/iload32.asm"
	; __FASTCALL__ routine which
	; loads a 32 bits integer into DE,HL
	; stored at position pointed by POINTER HL
	; DE,HL <-- (HL)
	    push namespace core
__ILOAD32:
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
	    ex de, hl
	    ret
	    pop namespace
#line 25 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/iloadf.asm"
	; __FASTCALL__ routine which
	; loads a 40 bits floating point into A ED CB
	; stored at position pointed by POINTER HL
	;A DE, BC <-- ((HL))
	    push namespace core
__ILOADF:
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
	; __FASTCALL__ routine which
	; loads a 40 bits floating point into A ED CB
	; stored at position pointed by POINTER HL
	;A DE, BC <-- (HL)
__LOADF:    ; Loads a 40 bits FP number from address pointed by HL
	    ld a, (hl)
	    inc hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    ret
	    pop namespace
#line 26 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/ftof16reg.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/ftou32reg.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/neg32.asm"
	    push namespace core
__ABS32:
	    bit 7, d
	    ret z
__NEG32: ; Negates DEHL (Two's complement)
	    ld a, l
	    cpl
	    ld l, a
	    ld a, h
	    cpl
	    ld h, a
	    ld a, e
	    cpl
	    ld e, a
	    ld a, d
	    cpl
	    ld d, a
	    inc l
	    ret nz
	    inc h
	    ret nz
	    inc de
	    ret
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/ftou32reg.asm"
	    push namespace core
__FTOU32REG:	; Converts a Float to (un)signed 32 bit integer (NOTE: It's ALWAYS 32 bit signed)
	    ; Input FP number in A EDCB (A exponent, EDCB mantissa)
    ; Output: DEHL 32 bit number (signed)
	    PROC
	    LOCAL __IS_FLOAT
	    LOCAL __NEGATE
	    or a
	    jr nz, __IS_FLOAT
	    ; Here if it is a ZX ROM Integer
	    ld h, c
	    ld l, d
	    ld d, e
	    ret
__IS_FLOAT:  ; Jumps here if it is a true floating point number
	    ld h, e
	    push hl  ; Stores it for later (Contains Sign in H)
	    push de
	    push bc
	    exx
	    pop de   ; Loads mantissa into C'B' E'D'
	    pop bc	 ;
	    set 7, c ; Highest mantissa bit is always 1
	    exx
	    ld hl, 0 ; DEHL = 0
	    ld d, h
	    ld e, l
	    ;ld a, c  ; Get exponent
	    sub 128  ; Exponent -= 128
	    jr z, __FTOU32REG_END	; If it was <= 128, we are done (Integers must be > 128)
	    jr c, __FTOU32REG_END	; It was decimal (0.xxx). We are done (return 0)
	    ld b, a  ; Loop counter = exponent - 128
__FTOU32REG_LOOP:
	    exx 	 ; Shift C'B' E'D' << 1, output bit stays in Carry
	    sla d
	    rl e
	    rl b
	    rl c
	    exx		 ; Shift DEHL << 1, inserting the carry on the right
	    rl l
	    rl h
	    rl e
	    rl d
	    djnz __FTOU32REG_LOOP
__FTOU32REG_END:
	    pop af   ; Take the sign bit
	    or a	 ; Sets SGN bit to 1 if negative
	    jp m, __NEGATE ; Negates DEHL
	    ret
__NEGATE:
	    exx
	    ld a, d
	    or e
	    or b
	    or c
	    exx
	    jr z, __END
	    inc l
	    jr nz, __END
	    inc h
	    jr nz, __END
	    inc de
	LOCAL __END
__END:
	    jp __NEG32
	    ENDP
__FTOU8:	; Converts float in C ED LH to Unsigned byte in A
	    call __FTOU32REG
	    ld a, l
	    ret
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/ftof16reg.asm"
	    push namespace core
__FTOF16REG:	; Converts a Float to 16.16 (32 bit) fixed point decimal
	    ; Input FP number in A EDCB (A exponent, EDCB mantissa)
	    ld l, a     ; Saves exponent for later
	    or d
	    or e
	    or b
	    or c
	    ld h, e
	    ret z		; Return if ZERO
	    push hl  ; Stores it for later (Contains sign in H, exponent in L)
	    push de
	    push bc
	    exx
	    pop de   ; Loads mantissa into C'B' E'D'
	    pop bc	 ;
	    set 7, c ; Highest mantissa bit is always 1
	    exx
	    ld hl, 0 ; DEHL = 0
	    ld d, h
	    ld e, l
	    pop bc
	    ld a, c  ; Get exponent
	    sub 112  ; Exponent -= 128 + 16
	    push bc  ; Saves sign in b again
	    jp z, __FTOU32REG_END	; If it was <= 128, we are done (Integers must be > 128)
	    jp c, __FTOU32REG_END	; It was decimal (0.xxx). We are done (return 0)
	    ld b, a  ; Loop counter = exponent - 128 + 16 (we need to shift 16 bit more)
	    jp __FTOU32REG_LOOP ; proceed as an u32 integer
	    pop namespace
#line 27 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/f16tofreg.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/u32tofreg.asm"
	    push namespace core
__I8TOFREG:
	    ld l, a
	    rlca
	    sbc a, a	; A = SGN(A)
	    ld h, a
	    ld e, a
	    ld d, a
__I32TOFREG:	; Converts a 32bit signed integer (stored in DEHL)
	    ; to a Floating Point Number returned in (A ED CB)
	    ld a, d
	    or a		; Test sign
	    jp p, __U32TOFREG	; It was positive, proceed as 32bit unsigned
	    call __NEG32		; Convert it to positive
	    call __U32TOFREG	; Convert it to Floating point
	    set 7, e			; Put the sign bit (negative) in the 31bit of mantissa
	    ret
__U8TOFREG:
	    ; Converts an unsigned 8 bit (A) to Floating point
	    ld l, a
	    ld h, 0
	    ld e, h
	    ld d, h
__U32TOFREG:	; Converts an unsigned 32 bit integer (DEHL)
	    ; to a Floating point number returned in A ED CB
	    PROC
	    LOCAL __U32TOFREG_END
	    ld a, d
	    or e
	    or h
	    or l
	    ld b, d
	    ld c, e		; Returns 00 0000 0000 if ZERO
	    ret z
	    push de
	    push hl
	    exx
	    pop de  ; Loads integer into B'C' D'E'
	    pop bc
	    exx
	    ld l, 128	; Exponent
	    ld bc, 0	; DEBC = 0
	    ld d, b
	    ld e, c
__U32TOFREG_LOOP: ; Also an entry point for __F16TOFREG
	    exx
	    ld a, d 	; B'C'D'E' == 0 ?
	    or e
	    or b
	    or c
	    jp z, __U32TOFREG_END	; We are done
	    srl b ; Shift B'C' D'E' >> 1, output bit stays in Carry
	    rr c
	    rr d
	    rr e
	    exx
	    rr e ; Shift EDCB >> 1, inserting the carry on the left
	    rr d
	    rr c
	    rr b
	    inc l	; Increment exponent
	    jp __U32TOFREG_LOOP
__U32TOFREG_END:
	    exx
	    ld a, l     ; Puts the exponent in a
	    res 7, e	; Sets the sign bit to 0 (positive)
	    ret
	    ENDP
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/f16tofreg.asm"
	    push namespace core
__F16TOFREG:	; Converts a 16.16 signed fixed point (stored in DEHL)
	    ; to a Floating Point Number returned in (C ED CB)
	    PROC
	    LOCAL __F16TOFREG2
	    ld a, d
	    or a		; Test sign
	    jp p, __F16TOFREG2	; It was positive, proceed as 32bit unsigned
	    call __NEG32		; Convert it to positive
	    call __F16TOFREG2	; Convert it to Floating point
	    set 7, e			; Put the sign bit (negative) in the 31bit of mantissa
	    ret
__F16TOFREG2:	; Converts an unsigned 32 bit integer (DEHL)
	    ; to a Floating point number returned in C DE HL
	    ld a, d
	    or e
	    or h
	    or l
	    ld b, h
	    ld c, l
	    ret z       ; Return 00 0000 0000 if 0
	    push de
	    push hl
	    exx
	    pop de  ; Loads integer into B'C' D'E'
	    pop bc
	    exx
	    ld l, 112	; Exponent
	    ld bc, 0	; DEBC = 0
	    ld d, b
	    ld e, c
	    jp __U32TOFREG_LOOP ; Proceed as an integer
	    ENDP
	    pop namespace
#line 28 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/free.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the BSD license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the BSD license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be breed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
	; ---------------------------------------------------------------------
	; MEM_FREE
	;  Frees a block of memory
	;
; Parameters:
	;  HL = Pointer to the block to be freed. If HL is NULL (0) nothing
	;  is done
	; ---------------------------------------------------------------------
	    push namespace core
MEM_FREE:
__MEM_FREE: ; Frees the block pointed by HL
	    ; HL DE BC & AF modified
	    PROC
	    LOCAL __MEM_LOOP2
	    LOCAL __MEM_LINK_PREV
	    LOCAL __MEM_JOIN_TEST
	    LOCAL __MEM_BLOCK_JOIN
	    ld a, h
	    or l
	    ret z       ; Return if NULL pointer
	    dec hl
	    dec hl
	    ld b, h
	    ld c, l    ; BC = Block pointer
	    ld hl, ZXBASIC_MEM_HEAP  ; This label point to the heap start
__MEM_LOOP2:
	    inc hl
	    inc hl     ; Next block ptr
	    ld e, (hl)
	    inc hl
	    ld d, (hl) ; Block next ptr
	    ex de, hl  ; DE = &(block->next); HL = block->next
	    ld a, h    ; HL == NULL?
	    or l
	    jp z, __MEM_LINK_PREV; if so, link with previous
	    or a       ; Clear carry flag
	    sbc hl, bc ; Carry if BC > HL => This block if before
	    add hl, bc ; Restores HL, preserving Carry flag
	    jp c, __MEM_LOOP2 ; This block is before. Keep searching PASS the block
	;------ At this point current HL is PAST BC, so we must link (DE) with BC, and HL in BC->next
__MEM_LINK_PREV:    ; Link (DE) with BC, and BC->next with HL
	    ex de, hl
	    push hl
	    dec hl
	    ld (hl), c
	    inc hl
	    ld (hl), b ; (DE) <- BC
	    ld h, b    ; HL <- BC (Free block ptr)
	    ld l, c
	    inc hl     ; Skip block length (2 bytes)
	    inc hl
	    ld (hl), e ; Block->next = DE
	    inc hl
	    ld (hl), d
	    ; --- LINKED ; HL = &(BC->next) + 2
	    call __MEM_JOIN_TEST
	    pop hl
__MEM_JOIN_TEST:   ; Checks for fragmented contiguous blocks and joins them
	    ; hl = Ptr to current block + 2
	    ld d, (hl)
	    dec hl
	    ld e, (hl)
	    dec hl
	    ld b, (hl) ; Loads block length into BC
	    dec hl
	    ld c, (hl) ;
	    push hl    ; Saves it for later
	    add hl, bc ; Adds its length. If HL == DE now, it must be joined
	    or a
	    sbc hl, de ; If Z, then HL == DE => We must join
	    pop hl
	    ret nz
__MEM_BLOCK_JOIN:  ; Joins current block (pointed by HL) with next one (pointed by DE). HL->length already in BC
	    push hl    ; Saves it for later
	    ex de, hl
	    ld e, (hl) ; DE -> block->next->length
	    inc hl
	    ld d, (hl)
	    inc hl
	    ex de, hl  ; DE = &(block->next)
	    add hl, bc ; HL = Total Length
	    ld b, h
	    ld c, l    ; BC = Total Length
	    ex de, hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl) ; DE = block->next
	    pop hl     ; Recovers Pointer to block
	    ld (hl), c
	    inc hl
	    ld (hl), b ; Length Saved
	    inc hl
	    ld (hl), e
	    inc hl
	    ld (hl), d ; Next saved
	    ret
	    ENDP
	    pop namespace
#line 29 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 31 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 32 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 33 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 34 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 35 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 36 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 37 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 38 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
#line 39 "/zxbasic/src/lib/arch/zx48k/runtime/read_restore.asm"
	;; Updates restore point to the given HL mem. address
	    push namespace core
__RESTORE:
	    PROC
	    LOCAL __DATA_ADDR
	    ld (__DATA_ADDR), hl
	    ret
	;; Reads a value from the DATA mem area and updates __DATA_ADDR ptr to the
	;; next item. On Out Of Data, restarts
	;;
__READ:
	    LOCAL read_restart, cont, cont2, table, no_func
	    LOCAL dynamic_cast, dynamic_cast2, dynamic_cast3, dynamic_cast4
	    LOCAL _decode_table, coerce_to_int, coerce_to_int2, promote_to_i16
	    LOCAL _from_i8, _from_u8
	    LOCAL _from_i16, _from_u16
	    LOCAL _from_i32, _from_u32
	    LOCAL _from_fixed, __data_error
	    push af  ; type of data to read
	    ld hl, (__DATA_ADDR)
read_restart:
	    ld a, (hl)
	    or a   ; 0 => OUT of data
	    jr nz, cont
	    ;; Signals out of data
	    ld hl, .DATA.__DATA__0
	    ld (__DATA_ADDR), hl
	    jr read_restart  ; Start again
cont:
	    and 0x80
	    ld a, (hl)
	    push af
	    jp z, no_func    ;; Loads data directly, not a function
	    inc hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld (__DATA_ADDR), hl  ;; Store address of next DATA
	    ex de, hl
cont2:
	    ld de, dynamic_cast
	    push de  ; ret address
	    jp (hl)  ; "call (hl)"
	    ;; Now tries to convert the given result to the expected type or raise an error
dynamic_cast:
	    exx
	    ex af, af'
	    pop af   ; type READ
	    and 0x7F ; clear bit 7
	    pop hl   ; type requested by USER (type of the READ variable)
	    ld c, h  ; save requested type (save it in register C)
	    cp h
	    exx
	    jr nz, dynamic_cast2  ; Types are identical?
	    ;; yes, they are
	    ex af, af'
	    ret
dynamic_cast2:
	    cp 1             ; Requested a number, but read a string?
	    jr nz, dynamic_cast3
	    call __MEM_FREE     ; Frees str from memory
	    jr __data_error
dynamic_cast3:
	    exx
	    ld b, a     ; Read type
	    ld a, c     ; Requested type
	    cp 1
	    jr z, __data_error
	    cp b
	    jr c, dynamic_cast4
	    ;; here the user expected type is "larger" than the read one
	    ld a, b
	    sub 2
	    add a, a
	    ld l, a
	    ld h, 0
	    ld de, _decode_table
	    add hl, de
	    ld e, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, e
	    push hl
	    ld a, c     ; Requested type
	    exx
	    ret
__data_error:
	    ;; When a data is read, but cannot be converted to the requested type
	    ;; that is, the user asked for a string and we read a number or vice versa
	    ld a, ERROR_InvalidArg
	    call __STOP  ; The user expected a string, but read a number
	    xor a
	    ld h, a
	    ld l, a
	    ld e, a
	    ld d, a
	    ld b, a
	    ld c, a
	    ret
_decode_table:
	    dw _from_i8
	    dw _from_u8
	    dw _from_i16
	    dw _from_u16
	    dw _from_i32
	    dw _from_u32
	    dw _from_fixed
_from_i8:
	    cp 4
	    jr nc, promote_to_i16
	    ex af, af'
	    ret     ;; Was from Byte to Ubyte
promote_to_i16:
	    ex af, af'
	    ld l, a
	    rla
	    sbc a, a
	    ld h, a     ; copy sgn to h
	    ex af, af'
	    jr _before_from_i16
_from_u8:
	    ex af, af'
	    ld l, a
	    ld h, 0
	    ex af, af'
	    ;; Promoted to i16
_before_from_i16:
_from_i16:
	    cp 6
	    ret c  ;; from i16 to u16
	    ;; Promote i16 to i32
	    ex af, af'
	    ld a, h
	    rla
	    sbc a, a
	    ld e, a
	    ld d, a
	    ex af, af'
_from_i32:
	    cp 7
	    ret z ;; From i32 to u32
	    ret c ;; From u16 to i32
	    cp 9
	    jp z, __I32TOFREG
_from_u32:
	    cp 9
	    jp z, __U32TOFREG
	    ex de, hl
	    ld hl, 0
	    cp 8
	    ret z
_from_fixed:  ;; From fixed to float
	    jp __F16TOFREG
_from_u16:
	    ld de, 0    ; HL 0x0000 => 32 bits
	    jp _from_i32
dynamic_cast4:
	    ;; The user type is "shorter" than the read one
	    ld a, b ;; read type
	    cp 4 ;; if user type < read type < _i16 => From Ubyte to Byte. Return af'
	    jr nc, 1f
	    ex af, af'
	    ret
1:
	    ld a, c ;; recover user required type
	    cp 8 ;; required type
	    jr c, before_to_int  ;; required < fixed (f16)
	    ex af, af'
	    exx     ;; Ok, we must convert from float to f16
	    jp __FTOF16REG
before_to_int:
	    ld a, b ;; read type
	    cp 8 ;;
	    jr c, coerce_to_int2
	    jr nz, coerce_to_int  ;; From float to int
	    ld a, c ;; user type
	    exx
	    ;; f16 to Long
	    ex de, hl
	    ld a, h
	    rla
	    sbc a, a
	    ld d, a
	    ld e, a
	    exx
	    jr coerce_to_int2
coerce_to_int:
	    exx
	    ex af, af'
	    call __FTOU32REG
	    ex af, af'   ; a contains user type
	    exx
coerce_to_int2:  ; At this point we have an u/integer in hl
	    exx
	    cp 4
	    ret nc       ; Already done. Return the result
	    ld a, l      ; Truncate to byte
	    ret
no_func:
	    exx
	    ld de, dynamic_cast
	    push de ; Ret address
	    dec a        ; 0 => string; 1, 2 => byte; 3, 4 => integer; 5, 6 => long, 7 => fixed; 8 => float
	    ld h, 0
	    add a, a
	    ld l, a
	    ld de, table
	    add hl, de
	    ld e, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, e
	    push hl ; address to jump to
	    exx
	    inc hl
	    ret     ; jp (sp)  => jump to table[a - 1]
table:
	    LOCAL __01_decode_string
	    LOCAL __02_decode_byte
	    LOCAL __03_decode_ubyte
	    LOCAL __04_decode_integer
	    LOCAL __05_decode_uinteger
	    LOCAL __06_decode_long
	    LOCAL __07_decode_ulong
	    LOCAL __08_decode_fixed
	    LOCAL __09_decode_float
	    ;; 1 -> Decode string
	    ;; 2, 3 -> Decode Byte, UByte
	    ;; 4, 5 -> Decode Integer, UInteger
	    ;; 6, 7 -> Decode Long, ULong
	    ;; 8 -> Decode Fixed
	    ;; 9 -> Decode Float
	    dw __01_decode_string
	    dw __02_decode_byte
	    dw __03_decode_ubyte
	    dw __04_decode_integer
	    dw __05_decode_uinteger
	    dw __06_decode_long
	    dw __07_decode_ulong
	    dw __08_decode_fixed
	    dw __09_decode_float
__01_decode_string:
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld (__DATA_ADDR), hl  ;; Store address of next DATA
	    ex de, hl
	    jp __LOADSTR
__02_decode_byte:
__03_decode_ubyte:
	    ld a, (hl)
	    inc hl
	    ld (__DATA_ADDR), hl
	    ret
__04_decode_integer:
__05_decode_uinteger:
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld (__DATA_ADDR), hl
	    ex de, hl
	    ret
__06_decode_long:
__07_decode_ulong:
__08_decode_fixed:
	    ld b, h
	    ld c, l
	    inc bc
	    inc bc
	    inc bc
	    inc bc
	    ld (__DATA_ADDR), bc
	    jp __ILOAD32
__09_decode_float:
	    call __LOADF
	    inc hl
	    ld (__DATA_ADDR), hl
	    ld h, a  ; returns A in H; sets A free
	    ret
__DATA_ADDR:  ;; Stores current DATA ptr
	    dw .DATA.__DATA__0
	    ENDP
	    pop namespace
#line 97 "arch/zx48k/opt3_data2.bas"
	END
