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
_printat42:
	push ix
	ld ix, 0
	add ix, sp
	ld a, (ix+7)
	ld (__LABEL__printAt42Coords), a
	ld a, (ix+5)
	ld ((__LABEL__printAt42Coords) + (1)), a
_printat42__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_print42:
	push ix
	ld ix, 0
	add ix, sp
#line 21
		PROC
		LD A, H
		OR L
		RET Z
		LD C,(HL)
		INC HL
		LD B,(HL)
		LD A, C
		OR B
		JP Z, print64end
		INC HL
		LOCAL examineChar
examineChar:
		LD A,(HL)
		CP 128
		JR NC, nextChar
		CP 22
		JR NZ, isNewline
		LOCAL isAt
isAt:
		EX DE,HL
		LD HL, -2
		ADD HL, BC
		EX DE,HL
		JP NC, print64end
		INC HL
		LD D,(HL)
		DEC BC
		INC HL
		LD E,(HL)
		DEC BC
		CALL nxtchar
		JR newline
		LOCAL isNewline
isNewline:
		CP 13
		JR NZ,checkvalid
		LOCAL newline
newline:
		CALL nxtline
		JR nextChar
		LOCAL checkvalid
checkvalid:
		CP 31
		JR C, nextChar
		LOCAL prn
prn:
		PUSH HL
		PUSH BC
		CALL printachar
		POP BC
		POP HL
		LOCAL nextChar
nextChar:
		INC HL
		DEC BC
		LD A,B
		OR C
		JR NZ, examineChar
		JP print64end
		LOCAL printachar
printachar:
		EXX
		PUSH HL
		EXX
		ld c, a
		ld h, 0
		ld l, a
		ld de, whichcolumn-32
		add hl, de
		ld a, (hl)
		cp 32
		jr nc, calcChar
		ld de, characters
		ld l, a
		call mult8
		ld b, h
		ld c, l
		jr printdata
		LOCAL calcChar
calcChar:
		ld de, 15360
		ld l, c
		call mult8
		ld de, workspace
		push de
		exx
		ld c, a
		cpl
		ld b, a
		exx
		ld b, 8
		LOCAL loop1
loop1:
		ld a, (hl)
		inc hl
		exx
		ld e, a
		and c
		ld d, a
		ld a, e
		rla
		and b
		or d
		exx
		ld (de), a
		inc de
		djnz loop1
		pop bc
		LOCAL printdata
printdata:
		call testcoords
		inc e
		ld (xycoords), de
		dec e
		ld a, e
		sla a
		ld l, a
		sla a
		add a, l
		ld l, a
		srl a
		srl a
		srl a
		ld e, a
		ld a, l
		and 7
		push af
		ex af, af'
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
		ld e, a
		ld (hl), e
		inc hl
		pop af
		cp 3
		jr c, hop1
		ld (hl), e
		LOCAL hop1
hop1:
		dec hl
		ld a, d
		and 248
		add a, 64
		ld h, a
		push hl
		exx
		pop hl
		exx
		ld a, 8
		LOCAL hop4
hop4:
		push af
		ld a, (bc)
		exx
		push hl
		ld c, 0
		ld de, 1023
		ex af, af'
		and a
		jr z, hop3
		ld b, a
		ex af, af'
		LOCAL hop2
hop2:
		and a
		rra
		rr c
		scf
		rr d
		rr e
		djnz hop2
		ex af, af'
		LOCAL hop3
hop3:
		ex af, af'
		ld b, a
		ld a, (hl)
		and d
		or b
		ld (hl), a
		inc hl
		ld a, (hl)
		and e
		or c
		ld (hl), a
		pop hl
		inc h
		exx
		inc bc
		pop af
		dec a
		jr nz, hop4
		exx
		pop hl
		exx
		ret
		LOCAL mult8
mult8:
		ld h, 0
		add hl, hl
		add hl, hl
		add hl, hl
		add hl, de
		ret
		LOCAL testcoords
testcoords:
		ld de, (xycoords)
		LOCAL nxtchar
nxtchar:
		ld a, e
		cp 42
		jr c, ycoord
		LOCAL nxtline
nxtline:
		inc d
		ld e, 0
		LOCAL ycoord
ycoord:
		ld a, d
		cp 24
		ret c
		ld d, 0
		ret
#line 257
__LABEL__printAt42Coords:
#line 312
		LOCAL xycoords
xycoords:
		defb 0
		defb 0
		LOCAL workspace
workspace:
		defb 0
		defb 0
		defb 0
		defb 0
		defb 0
		defb 0
		defb 0
		defb 0
		LOCAL whichcolumn
whichcolumn:
		defb 254
		defb 254
		defb 128
		defb 224
		defb 128
		defb 0
		defb 1
		defb 128
		defb 128
		defb 128
		defb 128
		defb 128
		defb 128
		defb 128
		defb 128
		defb 128
		defb 2
		defb 128
		defb 224
		defb 224
		defb 252
		defb 224
		defb 224
		defb 192
		defb 240
		defb 240
		defb 240
		defb 240
		defb 192
		defb 240
		defb 192
		defb 192
		defb 248
		defb 240
		defb 240
		defb 240
		defb 240
		defb 240
		defb 240
		defb 240
		defb 240
		defb 128
		defb 240
		defb 192
		defb 240
		defb 240
		defb 248
		defb 240
		defb 240
		defb 248
		defb 240
		defb 240
		defb 3
		defb 240
		defb 240
		defb 240
		defb 240
		defb 4
		defb 252
		defb 224
		defb 252
		defb 240
		defb 252
		defb 240
		defb 240
		defb 255
		defb 128
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 255
		defb 128
		defb 128
		defb 255
		defb 128
		defb 5
		LOCAL characters
characters:
		defb 0
		defb 0
		defb 100
		defb 104
		defb 16
		defb 44
		defb 76
		defb 0
		defb 0
		defb 32
		defb 80
		defb 32
		defb 84
		defb 72
		defb 52
		defb 0
		defb 0
		defb 56
		defb 76
		defb 84
		defb 84
		defb 100
		defb 56
		defb 0
		defb 0
		defb 124
		defb 16
		defb 16
		defb 16
		defb 16
		defb 16
		defb 0
		defb 0
		defb 68
		defb 68
		defb 40
		defb 16
		defb 16
		defb 16
		defb 0
		defb 0
		defb 48
		defb 72
		defb 180
		defb 164
		defb 180
		defb 72
		defb 48
		LOCAL print64end
print64end:
		ENDP
#line 477
_print42__leave:
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

#line 460 "print42.bas"

ZXBASIC_USER_DATA:
ZXBASIC_MEM_HEAP:
	; Defines DATA END
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP + ZXBASIC_HEAP_SIZE
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
