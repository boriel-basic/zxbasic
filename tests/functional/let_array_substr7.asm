	org 32768
	; Defines HEAP SIZE
ZXBASIC_HEAP_SIZE EQU 4768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	call __MEM_INIT
	ld de, __LABEL0
	ld hl, _a + 9
	call __STORE_STR
	ld hl, __LABEL1
	call __LOADSTR
	push hl
	xor a
	push af
	ld hl, 1
	push hl
	ld hl, 1
	push hl
	ld hl, (_a + 9)
	call __LETSUBSTR
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
__LABEL0:
	DEFW 000Ah
	DEFB 30h
	DEFB 31h
	DEFB 32h
	DEFB 33h
	DEFB 34h
	DEFB 35h
	DEFB 36h
	DEFB 37h
	DEFB 38h
	DEFB 39h
__LABEL1:
	DEFW 0005h
	DEFB 48h
	DEFB 45h
	DEFB 4Ch
	DEFB 4Ch
	DEFB 4Fh
#line 1 "letsubstr.asm"

	; Substring assigment eg. LET a$(p0 TO p1) = "xxxx"
	; HL = Start of string
	; TOP of the stack -> p1 (16 bit, unsigned)
	; TOP -1 of the stack -> p0 register
	; TOP -2 Flag (popped out in A register)
	; 		A Register	=> 0 if HL is not freed from memory
	;					=> Not 0 if HL must be freed from memory on exit
	; TOP -3 B$ address

#line 1 "free.asm"

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

#line 1 "heapinit.asm"

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

#line 69 "free.asm"

	; ---------------------------------------------------------------------
	; MEM_FREE
	;  Frees a block of memory
	;
; Parameters:
	;  HL = Pointer to the block to be freed. If HL is NULL (0) nothing
	;  is done
	; ---------------------------------------------------------------------

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

#line 11 "letsubstr.asm"

__LETSUBSTR:
		PROC

		LOCAL __CONT0
		LOCAL __CONT1
		LOCAL __CONT2
		LOCAL __FREE_STR
		LOCAL __FREE_STR0

		exx
		pop hl ; Return address
		pop de ; p1
		pop bc ; p0
		exx

		pop af ; Flag
		ex af, af'	; Save it for later

		pop de ; B$

		exx
		push hl ; push ret addr back
		exx

		ld a, h
		or l
		jp z, __FREE_STR0 ; Return if null

		ld c, (hl)
		inc hl
		ld b, (hl) ; BC = Str length
		inc hl	; HL = String start
		push bc

		exx
		ex de, hl
		or a
		sbc hl, bc ; HL = Length of string requester by user
		inc hl	   ; len (a$(p0 TO p1)) = p1 - p0 + 1
		ex de, hl  ; Saves it in DE

		pop hl	   ; HL = String length
		exx
		jp c, __FREE_STR0	   ; Return if greather
		exx		   ; Return if p0 > p1

		or a
		sbc hl, bc ; P0 >= String length?
		exx

		jp z, __FREE_STR0	   ; Return if equal
		jp c, __FREE_STR0	   ; Return if greather

		exx
		add hl, bc ; Add it back

		sbc hl, de ; Length of substring > string => Truncate it
		add hl, de ; add it back
		jr nc, __CONT0 ; Length of substring within a$

		ld d, h
		ld e, l	   ; Truncate length of substring to fit within the strlen

__CONT0:	   ; At this point DE = Length of subtring to copy
				   ; BC = start of char to copy
		push de

		push bc
		exx
		pop bc

		add hl, bc ; Start address (within a$) so copy from b$ (in DE)

		push hl
		exx
		pop hl	   ; Start address (within a$) so copy from b$ (in DE)

		ld b, d	   ; Length of string
		ld c, e

		ld (hl), ' '
		ld d, h
		ld e, l
		inc de
		dec bc
		ld a, b
		or c
		jr z, __CONT2

		; At this point HL = DE = Start of Write zone in a$
		; BC = Number of chars to write

		ldir

__CONT2:

		pop bc	; Recovers Length of string to copy
		exx
		ex de, hl  ; HL = Source, DE = Target

		ld a, h
		or l
		jp z, __FREE_STR ; Return if B$ is NULL

		ld c, (hl)
		inc hl
		ld b, (hl)
		inc hl

		ld a, b
		or c
		jp z, __FREE_STR ; Return if len(b$) = 0

		; Now if len(b$) < len(char to copy), copy only len(b$) chars

		push de
		push hl
		push bc
		exx
		pop hl	; LEN (b$)
		or a
		sbc hl, bc
		add hl, bc
		jr nc, __CONT1

		; If len(b$) < len(to copy)
		ld b, h ; BC = len(to copy)
		ld c, l

__CONT1:
		pop hl
		pop de
		ldir	; Copy b$ into a$(x to y)

		exx
		ex de, hl

__FREE_STR0:
		ex de, hl

__FREE_STR:
		ex af, af'
		or a		; If not 0, free
		jp nz, __MEM_FREE
		ret

		ENDP

#line 51 "let_array_substr7.bas"
#line 1 "loadstr.asm"

#line 1 "alloc.asm"

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
	; if we can defragment the heap. If the block to be freed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).


	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.

	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.

#line 1 "error.asm"

	; Simple error control routines
; vim:ts=4:et:

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
#line 69 "alloc.asm"



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
#line 111 "/zxbasic/library-asm/alloc.asm"
	        ret z ; NULL
#line 113 "/zxbasic/library-asm/alloc.asm"
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


#line 2 "loadstr.asm"

	; Loads a string (ptr) from HL
	; and duplicates it on dynamic memory again
	; Finally, it returns result pointer in HL

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
#line 52 "let_array_substr7.bas"
#line 1 "storestr.asm"

; vim:ts=4:et:sw=4
	; Stores value of current string pointed by DE register into address pointed by HL
	; Returns DE = Address pointer  (&a$)
	; Returns HL = HL               (b$ => might be needed later to free it from the heap)
	;
	; e.g. => HL = _variableName    (DIM _variableName$)
	;         DE = Address into the HEAP
	;
	; This function will resize (REALLOC) the space pointed by HL
	; before copying the content of b$ into a$


#line 1 "strcpy.asm"

#line 1 "realloc.asm"

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
	; MEM_REALLOC
	;  Reallocates a block of memory in the heap.
	;
	; Parameters
	;  HL = Pointer to the original block
	;  BC = New Length of requested memory block
	;
; Returns:
	;  HL = Pointer to the allocated block in memory. Returns 0 (NULL)
	;       if the block could not be allocated (out of memory)
	;
; Notes:
	;  If BC = 0, the block is freed, otherwise
	;  the content of the original block is copied to the new one, and
	;  the new size is adjusted. If BC < original length, the content
	;  will be truncated. Otherwise, extra block content might contain
	;  memory garbage.
	;
	; ---------------------------------------------------------------------
__REALLOC:    ; Reallocates block pointed by HL, with new length BC
	        PROC

	        LOCAL __REALLOC_END

	        ld a, h
	        or l
	        jp z, __MEM_ALLOC    ; If HL == NULL, just do a malloc

	        ld e, (hl)
	        inc hl
	        ld d, (hl)    ; DE = First 2 bytes of HL block

	        push hl
	        exx
	        pop de
	        inc de        ; DE' <- HL + 2
	        exx            ; DE' <- HL (Saves current pointer into DE')

	        dec hl        ; HL = Block start

	        push de
	        push bc
	        call __MEM_FREE        ; Frees current block
	        pop bc
	        push bc
	        call __MEM_ALLOC    ; Gets a new block of length BC
	        pop bc
	        pop de

	        ld a, h
	        or l
	        ret z        ; Return if HL == NULL (No memory)

	        ld (hl), e
	        inc hl
	        ld (hl), d
	        inc hl        ; Recovers first 2 bytes in HL

	        dec bc
	        dec bc        ; BC = BC - 2 (Two bytes copied)

	        ld a, b
	        or c
	        jp z, __REALLOC_END        ; Ret if nothing to copy (BC == 0)

	        exx
	        push de
	        exx
	        pop de        ; DE <- DE' ; Start of remaining block

	        push hl        ; Saves current Block + 2 start
        ex de, hl    ; Exchanges them: DE is destiny block
	        ldir        ; Copies BC Bytes
	        pop hl        ; Recovers Block + 2 start

__REALLOC_END:

	        dec hl        ; Set HL
	        dec hl        ; To begin of block
	        ret

	        ENDP

#line 2 "strcpy.asm"

	; String library


__STRASSIGN: ; Performs a$ = b$ (HL = address of a$; DE = Address of b$)
			PROC

			LOCAL __STRREALLOC
			LOCAL __STRCONTINUE
			LOCAL __B_IS_NULL
			LOCAL __NOTHING_TO_COPY

			ld b, d
			ld c, e
			ld a, b
			or c
			jr z, __B_IS_NULL

			ex de, hl
			ld c, (hl)
			inc hl
			ld b, (hl)
			dec hl		; BC = LEN(b$)
			ex de, hl	; DE = &b$

__B_IS_NULL:		; Jumps here if B$ pointer is NULL
			inc bc
			inc bc		; BC = BC + 2  ; (LEN(b$) + 2 bytes for storing length)

			push de
			push hl

			ld a, h
			or l
			jr z, __STRREALLOC

			dec hl
			ld d, (hl)
			dec hl
			ld e, (hl)	; DE = MEMBLOCKSIZE(a$)
			dec de
			dec de		; DE = DE - 2  ; (Membloksize takes 2 bytes for memblock length)

			ld h, b
			ld l, c		; HL = LEN(b$) + 2  => Minimum block size required
			ex de, hl	; Now HL = BLOCKSIZE(a$), DE = LEN(b$) + 2

			or a		; Prepare to subtract BLOCKSIZE(a$) - LEN(b$)
			sbc hl, de  ; Carry if len(b$) > Blocklen(a$)
			jr c, __STRREALLOC ; No need to realloc
			; Need to reallocate at least to len(b$) + 2
			ex de, hl	; DE = Remaining bytes in a$ mem block.
			ld hl, 4
			sbc hl, de  ; if remaining bytes < 4 we can continue
			jr nc,__STRCONTINUE ; Otherwise, we realloc, to free some bytes

__STRREALLOC:
			pop hl
			call __REALLOC	; Returns in HL a new pointer with BC bytes allocated
			push hl

__STRCONTINUE:	;   Pops hl and de SWAPPED
			pop de	;	DE = &a$
			pop hl	; 	HL = &b$

			ld a, d		; Return if not enough memory for new length
			or e
			ret z		; Return if DE == NULL (0)

__STRCPY:	; Copies string pointed by HL into string pointed by DE
				; Returns DE as HL (new pointer)
			ld a, h
			or l
			jr z, __NOTHING_TO_COPY
			ld c, (hl)
			inc hl
			ld b, (hl)
			dec hl
			inc bc
			inc bc
			push de
			ldir
			pop hl
			ret

__NOTHING_TO_COPY:
			ex de, hl
			ld (hl), e
			inc hl
			ld (hl), d
			dec hl
			ret

			ENDP

#line 14 "storestr.asm"

__PISTORE_STR:          ; Indirect assignement at (IX + BC)
	    push ix
	    pop hl
	    add hl, bc

__ISTORE_STR:           ; Indirect assignement, hl point to a pointer to a pointer to the heap!
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c             ; HL = (HL)

__STORE_STR:
	    push de             ; Pointer to b$
	    push hl             ; Array pointer to variable memory address

	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c             ; HL = (HL)

	    call __STRASSIGN    ; HL (a$) = DE (b$); HL changed to a new dynamic memory allocation
	    ex de, hl           ; DE = new address of a$
	    pop hl              ; Recover variable memory address pointer

	    ld (hl), e
	    inc hl
	    ld (hl), d          ; Stores a$ ptr into elemem ptr

	    pop hl              ; Returns ptr to b$ in HL (Caller might needed to free it from memory)
	    ret

#line 53 "let_array_substr7.bas"

ZXBASIC_USER_DATA:
_a:
	DEFW 0000h
	DEFB 02h
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
	DEFB 00h
	DEFB 00h
ZXBASIC_MEM_HEAP:
	; Defines DATA END
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP + ZXBASIC_HEAP_SIZE
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
