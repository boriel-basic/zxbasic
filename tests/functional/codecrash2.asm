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
	ld de, (_b)
	ld hl, (_b)
	call __ADDSTR
	ld a, 1
	call __ASC
	ld (_a), a
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
#line 1 "strcat.asm"
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
	
#line 70 "alloc.asm"
	
	
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
	        LOCAL TEMP
	
	        ld hl, 0
	        ld (TEMP), hl
	
__MEM_START:
	        ld hl, ZXBASIC_MEM_HEAP  ; This label point to the heap start
	        inc bc
	        inc bc  ; BC = BC + 2 ; block size needs 2 extra bytes for hidden pointer
	        
__MEM_LOOP:  ; Loads lengh at (HL, HL+). If Lenght >= BC, jump to __MEM_DONE
	        ld a, h ;  HL = NULL (No memory available?)
	        or l
#line 109 "/Users/boriel/Documents/src/zxbasic/library-asm/alloc.asm"
	        ret z ; NULL
#line 111 "/Users/boriel/Documents/src/zxbasic/library-asm/alloc.asm"
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
	        ld hl, (TEMP) ; Pre-previous block pointer
	
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
	            
	TEMP    EQU 23563   ; DEFADD variable
	
	        ENDP
	
	
#line 2 "strcat.asm"
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
	
	
#line 3 "strcat.asm"
	
__ADDSTR:	; Implements c$ = a$ + b$
				; hl = &a$, de = &b$ (pointers)
	
	
__STRCAT2:	; This routine creates a new string in dynamic space
				; making room for it. Then copies a$ + b$ into it.
				; HL = a$, DE = b$
	
			PROC
	
			LOCAL __STR_CONT
			LOCAL __STRCATEND
	
			push hl
			call __STRLEN
			ld c, l
			ld b, h		; BC = LEN(a$)
			ex (sp), hl ; (SP) = LEN (a$), HL = a$
			push hl		; Saves pointer to a$
	
			inc bc
			inc bc		; +2 bytes to store length
	
			ex de, hl
			push hl
			call __STRLEN
			; HL = len(b$)
	
			add hl, bc	; Total str length => 2 + len(a$) + len(b$)
	
			ld c, l
			ld b, h		; BC = Total str length + 2
			call __MEM_ALLOC 
			pop de		; HL = c$, DE = b$ 
	
			ex de, hl	; HL = b$, DE = c$
			ex (sp), hl ; HL = a$, (SP) = b$ 
	
			exx
			pop de		; D'E' = b$ 
			exx
	
			pop bc		; LEN(a$)
	
			ld a, d
			or e
		ret z		; If no memory: RETURN
	
__STR_CONT:
			push de		; Address of c$
	
			ld a, h
			or l
			jr nz, __STR_CONT1 ; If len(a$) != 0 do copy
	
	        ; a$ is NULL => uses HL = DE for transfer
			ld h, d
			ld l, e
			ld (hl), a	; This will copy 00 00 at (DE) location
	        inc de      ; 
	        dec bc      ; Ensure BC will be set to 1 in the next step
	
__STR_CONT1:        ; Copies a$ (HL) into c$ (DE)
			inc bc			
			inc bc		; BC = BC + 2
		ldir		; MEMCOPY: c$ = a$
			pop hl		; HL = c$
	
			exx
			push de		; Recovers b$; A ex hl,hl' would be very handy
			exx
	
			pop de		; DE = b$ 
	
__STRCAT: ; ConCATenate two strings a$ = a$ + b$. HL = ptr to a$, DE = ptr to b$
		  ; NOTE: Both DE, BC and AF are modified and lost
			  ; Returns HL (pointer to a$)
			  ; a$ Must be NOT NULL
			ld a, d
			or e
			ret z		; Returns if de is NULL (nothing to copy)
	
			push hl		; Saves HL to return it later
	
			ld c, (hl)
			inc hl
			ld b, (hl)
			inc hl
			add hl, bc	; HL = end of (a$) string ; bc = len(a$)
			push bc		; Saves LEN(a$) for later
	
			ex de, hl	; DE = end of string (Begin of copy addr)
			ld c, (hl)
			inc hl
			ld b, (hl)	; BC = len(b$)
	
			ld a, b
			or c
			jr z, __STRCATEND; Return if len(b$) == 0
	
			push bc			 ; Save LEN(b$)
			inc hl			 ; Skip 2nd byte of len(b$)
			ldir			 ; Concatenate b$
	
			pop bc			 ; Recovers length (b$)
			pop hl			 ; Recovers length (a$)
			add hl, bc		 ; HL = LEN(a$) + LEN(b$) = LEN(a$+b$)
			ex de, hl		 ; DE = LEN(a$+b$)
			pop hl
	
			ld (hl), e		 ; Updates new LEN and return
			inc hl
			ld (hl), d
			dec hl
			ret
	
__STRCATEND:
			pop hl		; Removes Len(a$)
			pop hl		; Restores original HL, so HL = a$
			ret
	
			ENDP
	
#line 24 "codecrash2.bas"
#line 1 "asc.asm"
	; Returns the ascii code for the given str
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
	
#line 3 "asc.asm"
	
__ASC:
		PROC
		LOCAL __ASC_END
		
		ex af, af'	; Saves free_mem flag
	
		ld a, h
		or l
		ret z		; NULL? return
	
		ld c, (hl)
		inc hl
		ld b, (hl)
	
		ld a, b
		or c
		jr z, __ASC_END		; No length? return
	
		inc hl
		ld a, (hl)
	    dec hl
		
__ASC_END:
		dec hl
		ex af, af'
		or a
		call nz, __MEM_FREE	; Free memory if needed
	
		ex af, af'	; Recover result
	
		ret
		ENDP
#line 25 "codecrash2.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00
_b:
	DEFB 00, 00
ZXBASIC_MEM_HEAP:
	; Defines DATA END
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP + ZXBASIC_HEAP_SIZE
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
