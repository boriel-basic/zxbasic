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
	call CLS
	ld hl, __LABEL0
	call __LOADSTR
	push hl
	xor a
	push af
	ld a, 10
	push af
	call _doubleSizePrint
	ld a, 8
	call __STOP
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
	ld hl, 0
	ld b, h
	ld c, l
	jp __END_PROGRAM
_doubleSizePrint:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	push hl
	inc sp
	ld (ix-1), 0
	jp __LABEL1
__LABEL4:
	ld l, (ix+8)
	ld h, (ix+9)
	push hl
	ld a, (ix-1)
	ld l, a
	ld h, 0
	push hl
	ld a, (ix-1)
	ld l, a
	ld h, 0
	push hl
	xor a
	call __STRSLICE
	ld d, h
	ld e, l
	ld bc, -3
	call __PSTORE_STR2
	ld a, (ix+7)
	add a, 2
	ld (ix+7), a
__LABEL5:
	inc (ix-1)
__LABEL1:
	ld a, (ix-1)
	push af
	ld l, (ix+8)
	ld h, (ix+9)
	call __STRLEN
	dec hl
	ld a, l
	pop hl
	cp h
	jp nc, __LABEL4
__LABEL3:
_doubleSizePrint__leave:
	ex af, af'
	exx
	ld l, (ix+8)
	ld h, (ix+9)
	call __MEM_FREE
	ld l, (ix-3)
	ld h, (ix-2)
	call __MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
__LABEL0:
	DEFW 000Bh
	DEFB 48h
	DEFB 65h
	DEFB 6Ch
	DEFB 6Ch
	DEFB 6Fh
	DEFB 20h
	DEFB 57h
	DEFB 6Fh
	DEFB 72h
	DEFB 6Ch
	DEFB 64h
#line 1 "cls.asm"

	; JUMPS directly to spectrum CLS
	; This routine does not clear lower screen

	;CLS	EQU	0DAFh

	; Our faster implementation

#line 1 "sposn.asm"

	; Printing positioning library.
			PROC
			LOCAL ECHO_E

__LOAD_S_POSN:		; Loads into DE current ROW, COL print position from S_POSN mem var.
			ld de, (S_POSN)
			ld hl, (MAXX)
			or a
			sbc hl, de
			ex de, hl
			ret


__SAVE_S_POSN:		; Saves ROW, COL from DE into S_POSN mem var.
			ld hl, (MAXX)
			or a
			sbc hl, de
			ld (S_POSN), hl ; saves it again
			ret


	ECHO_E	EQU 23682
	MAXX	EQU ECHO_E   ; Max X position + 1
	MAXY	EQU MAXX + 1 ; Max Y position + 1

	S_POSN	EQU 23688
	POSX	EQU S_POSN		; Current POS X
	POSY	EQU S_POSN + 1	; Current POS Y

			ENDP

#line 9 "cls.asm"

CLS:
		PROC

		LOCAL COORDS
		LOCAL __CLS_SCR
		LOCAL ATTR_P
		LOCAL SCREEN

		ld hl, 0
		ld (COORDS), hl
	    ld hl, 1821h
		ld (S_POSN), hl
__CLS_SCR:
		ld hl, SCREEN
		ld (hl), 0
		ld d, h
		ld e, l
		inc de
		ld bc, 6144
		ldir

		; Now clear attributes

		ld a, (ATTR_P)
		ld (hl), a
		ld bc, 767
		ldir
		ret

	COORDS	EQU	23677
	SCREEN	EQU 16384 ; Default start of the screen (can be changed)
	ATTR_P	EQU 23693
	;you can poke (SCREEN_SCRADDR) to change CLS, DRAW & PRINTing address

	SCREEN_ADDR EQU (__CLS_SCR + 1) ; Address used by print and other screen routines
								    ; to get the start of the screen
		ENDP

#line 111 "slice2.bas"
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
#line 112 "slice2.bas"
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

#line 113 "slice2.bas"
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
#line 111 "/zbasic/library-asm/alloc.asm"
	        ret z ; NULL
#line 113 "/zbasic/library-asm/alloc.asm"
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
#line 114 "slice2.bas"
#line 1 "pstorestr2.asm"

; vim:ts=4:et:sw=4
	;
	; Stores an string (pointer to the HEAP by DE) into the address pointed
	; by (IX + BC). No new copy of the string is created into the HEAP, since
	; it's supposed it's already created (temporary string)
	;

#line 1 "storestr2.asm"

	; Similar to __STORE_STR, but this one is called when
	; the value of B$ if already duplicated onto the stack.
	; So we needn't call STRASSING to create a duplication
	; HL = address of string memory variable
	; DE = address of 2n string. It just copies DE into (HL)
	; 	freeing (HL) previously.



__PISTORE_STR2: ; Indirect store temporary string at (IX + BC)
	    push ix
	    pop hl
	    add hl, bc

__ISTORE_STR2:
		ld c, (hl)  ; Dereferences HL
		inc hl
		ld h, (hl)
		ld l, c		; HL = *HL (real string variable address)

__STORE_STR2:
		push hl
		ld c, (hl)
		inc hl
		ld h, (hl)
		ld l, c		; HL = *HL (real string address)

		push de
		call __MEM_FREE
		pop de

		pop hl
		ld (hl), e
		inc hl
		ld (hl), d
		dec hl		; HL points to mem address variable. This might be useful in the future.

		ret

#line 9 "pstorestr2.asm"

__PSTORE_STR2:
	    push ix
	    pop hl
	    add hl, bc
	    jp __STORE_STR2

#line 115 "slice2.bas"
#line 1 "strlen.asm"

	; Returns len if a string
	; If a string is NULL, its len is also 0
	; Result returned in HL

__STRLEN:	; Direct FASTCALL entry
			ld a, h
			or l
			ret z

			ld a, (hl)
			inc hl
			ld h, (hl)  ; LEN(str) in HL
			ld l, a
			ret


#line 116 "slice2.bas"
#line 1 "strslice.asm"

	; String slicing library
	; HL = Str pointer
	; DE = String start
	; BC = String character end
	; A register => 0 => the HL pointer wont' be freed from the HEAP
	; e.g. a$(5 TO 10) => HL = a$; DE = 5; BC = 10

	; This implements a$(X to Y) being X and Y first and
	; last characters respectively. If X > Y, NULL is returned

	; Otherwise returns a pointer to a$ FROM X to Y (starting from 0)
	; if Y > len(a$), then a$ will be padded with spaces (reallocating
	; it in dynamic memory if needed). Returns pointer (HL) to resulting
	; string. NULL (0) if no memory for padding.
	;





__STRSLICE:			; Callee entry
		pop hl			; Return ADDRESS
		pop bc			; Last char pos
		pop de			; 1st char pos
		ex (sp), hl		; CALLEE. -> String start

__STRSLICE_FAST:	; __FASTCALL__ Entry
		PROC

		LOCAL __CONT
		LOCAL __EMPTY
		LOCAL __FREE_ON_EXIT

		push hl			; Stores original HL pointer to be recovered on exit
		ex af, af'		; Saves A register for later

		push hl
		call __STRLEN
		inc bc			; Last character position + 1 (string starts from 0)
		or a
		sbc hl, bc		; Compares length with last char position
		jr nc, __CONT	; If Carry => We must copy to end of string
		add hl, bc		; Restore back original LEN(a$) in HL
		ld b, h
		ld c, l			; Copy to the end of str
		ccf				; Clears Carry flag for next subtraction

__CONT:
		ld h, b
		ld l, c			; HL = Last char position to copy (1 for char 0, 2 for char 1, etc)
		sbc hl, de		; HL = LEN(a$) - DE => Number of chars to copy
		jr z, __EMPTY	; 0 Chars to copy => Return HL = 0 (NULL STR)
		jr c, __EMPTY	; If Carry => Nothing to return (NULL STR)

		ld b, h
		ld c, l			; BC = Number of chars to copy
		inc bc
		inc bc			; +2 bytes for string length number

		push bc
		push de
		call __MEM_ALLOC
		pop de
		pop bc
		ld a, h
		or l
		jr z, __EMPTY	; Return if NULL (no memory)

		dec bc
		dec bc			; Number of chars to copy (Len of slice)

		ld (hl), c
		inc hl
		ld (hl), b
		inc hl			; Stores new string length

		ex (sp), hl		; Pointer to A$ now in HL; Pointer to new string chars in Stack
		inc hl
		inc hl			; Skip string length
		add hl, de		; Were to start from A$
		pop de			; Start of new string chars
		push de			; Stores it again
		ldir			; Copies BC chars
		pop de
		dec de
		dec de			; Points to String LEN start
		ex de, hl		; Returns it in HL
		jr __FREE_ON_EXIT

__EMPTY:			; Return NULL (empty) string
		pop hl
		ld hl, 0		; Return NULL


__FREE_ON_EXIT:
		ex af, af'		; Recover original A register
		ex (sp), hl		; Original HL pointer

		or a
		call nz, __MEM_FREE

		pop hl			; Recover result
		ret

		ENDP

#line 117 "slice2.bas"

ZXBASIC_USER_DATA:
ZXBASIC_MEM_HEAP:
	; Defines DATA END
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP + ZXBASIC_HEAP_SIZE
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
