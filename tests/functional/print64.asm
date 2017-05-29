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
_printat64:
	push ix
	ld ix, 0
	add ix, sp
	ld a, (ix+7)
	ld (__LABEL__p64coords), a
	ld a, (ix+5)
	ld (__LABEL__p64coords + 1), a
_printat64__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_print64:
	push ix
	ld ix, 0
	add ix, sp
#line 22
		PROC
		LD L,(IX+4)
		LD H,(IX+5)
		ld a, h
		or l
		ret z
		ld c, (hl)
		inc hl
		ld b, (hl)
		inc hl
		ld a, c
		or b
		jp z, p64_END
		LOCAL examineChar
examineChar:
		ld a, (hl)
		cp 128
		jr nc, nextChar
		cp 22
		jr nz, newLine
		ex de, hl
		and a
		ld hl, 2
		sbc hl, bc
		ex de, hl
		jp nc, p64_END
		inc hl
		ld d, (hl)
		dec bc
		inc hl
		ld e, (hl)
		dec bc
		call p64_test_X
		jr p64_eaa3
		LOCAL newLine
newLine:
		cp 13
		jr nz, p64_isPrintable
		ld de, (p64_coords)
		call p64_nxtLine
		LOCAL p64_eaa3
p64_eaa3:
		ld (p64_coords), de
		jr nextChar
		LOCAL p64_isPrintable
p64_isPrintable:
		cp 31
		jr c, nextChar
		push hl
		push bc
		call p64_PrintChar
		pop bc
		pop hl
		LOCAL nextChar
nextChar:
		inc hl
		dec bc
		ld a, b
		or c
		jr nz, examineChar
		jp p64_END
		LOCAL p64_PrintChar
p64_PrintChar:
		exx
		push hl
		exx
		sub 32
		ld h, 0
		rra
		ld l, a
		ld a, 240
		jr nc, p64_eacc
		ld a, 15
		LOCAL p64_eacc
p64_eacc:
		add hl, hl
		add hl, hl
		add hl, hl
		ld de, p64_charset
		add hl, de
		exx
		ld de, (p64_coords)
		ex af, af'
		call p64_loadAndTest
		ex af, af'
		inc e
		ld (p64_coords), de
		dec e
		ld b, a
		rr e
		ld c, 0
		rl c
		and 1
		xor c
		ld c, a
		jr z, p64_eaf6
		ld a, b
		rrca
		rrca
		rrca
		rrca
		ld b, a
		LOCAL p64_eaf6
p64_eaf6:
		ld a, d
		sra a
		sra a
		sra a
		add a, 88
		ld h, a
		ld a, d
		and 7
		rrca
		rrca
		rrca
		add a, e
		ld l, a
		ld a, (23693)
		ld (hl), a
		ld a, d
		and 248
		add a, 64
		ld h, a
		ld a, b
		cpl
		ld e, a
		exx
		ld b, 8
		LOCAL p64_eb18
p64_eb18:
		ld a, (hl)
		exx
		bit 0, c
		jr z, p64_eb22
		rrca
		rrca
		rrca
		rrca
		LOCAL p64_eb22
p64_eb22:
		and b
		ld d, a
		ld a, (hl)
		and e
		or d
		ld (hl), a
		inc h
		exx
		inc hl
		djnz p64_eb18
		exx
		pop hl
		exx
		ret
		LOCAL p64_loadAndTest
p64_loadAndTest:
		ld de, (p64_coords)
		LOCAL p64_test_X
p64_test_X:
		ld a, e
		cp 64
		jr c, p64_test_Y
		LOCAL p64_nxtLine
p64_nxtLine:
		inc d
		ld e, 0
		LOCAL p64_test_Y
p64_test_Y:
		ld a, d
		cp 24
		ret c
		ld d, 0
		ret
#line 195
__LABEL__p64coords:
#line 224
		LOCAL p64_coords
p64_coords:
		defb 64
		defb 23
		LOCAL p64_charset
p64_charset:
		DEFB 0,2,2,2,2,0,2,0
		DEFB 0,80,82,7,2,7,2,0
		DEFB 0,37,113,66,114,20,117,32
		DEFB 0,34,84,32,96,80,96,0
		DEFB 0,36,66,66,66,66,36,0
		DEFB 0,0,82,34,119,34,82,0
		DEFB 0,0,0,0,7,32,32,64
		DEFB 0,1,1,2,2,100,100,0
		DEFB 0,34,86,82,82,82,39,0
		DEFB 0,34,85,18,33,69,114,0
		DEFB 0,87,84,118,17,21,18,0
		DEFB 0,55,65,97,82,84,36,0
		DEFB 0,34,85,37,83,85,34,0
		DEFB 0,0,2,32,0,34,2,4
		DEFB 0,0,16,39,64,39,16,0
		DEFB 0,2,69,33,18,32,66,0
		DEFB 0,98,149,183,181,133,101,0
		DEFB 0,98,85,100,84,85,98,0
		DEFB 0,103,84,86,84,84,103,0
		DEFB 0,114,69,116,71,69,66,0
		DEFB 0,87,82,114,82,82,87,0
		DEFB 0,53,21,22,21,85,37,0
		DEFB 0,69,71,71,69,69,117,0
		DEFB 0,82,85,117,117,85,82,0
		DEFB 0,98,85,85,103,71,67,0
		DEFB 0,98,85,82,97,85,82,0
		DEFB 0,117,37,37,37,37,34,0
		DEFB 0,85,85,85,87,39,37,0
		DEFB 0,85,85,37,82,82,82,0
		DEFB 0,119,20,36,36,68,119,0
		DEFB 0,71,65,33,33,17,23,0
		DEFB 0,32,112,32,32,32,47,0
		DEFB 0,32,86,65,99,69,115,0
		DEFB 0,64,66,101,84,85,98,0
		DEFB 0,16,18,53,86,84,35,0
		DEFB 0,32,82,69,101,67,69,2
		DEFB 0,66,64,102,82,82,87,0
		DEFB 0,20,4,53,22,21,85,32
		DEFB 0,64,69,71,71,85,37,0
		DEFB 0,0,98,85,85,85,82,0
		DEFB 0,0,99,85,85,99,65,65
		DEFB 0,0,99,84,66,65,70,0
		DEFB 0,64,117,69,69,85,34,0
		DEFB 0,0,85,85,87,39,37,0
		DEFB 0,0,85,85,35,81,85,2
		DEFB 0,0,113,18,38,66,113,0
		DEFB 0,32,36,34,35,34,36,0
		DEFB 0,6,169,86,12,6,9,6
		LOCAL p64_END
p64_END:
		ENDP
#line 281
_print64__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call __MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
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
	
#line 289 "print64.bas"
	
ZXBASIC_USER_DATA:
ZXBASIC_MEM_HEAP:
	; Defines DATA END
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP + ZXBASIC_HEAP_SIZE
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
