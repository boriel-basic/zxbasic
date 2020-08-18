' The SPLib fill routine (by Alvin Albretch, 2002-2012)
' ported to ZX Basic by Britlion (a.k.a. Paul Fisher)
'

REM Avoid double inclusion
#ifndef __SP_FILL__
#define __SP_FILL__


SUB FASTCALL SPFill(xCoord as uByte, yCoord as uByte, fillPatternAddress as uInteger)
asm
PROC
LOCAL SPPFill
LOCAL SPPFill_start
LOCAL SPPFill_end

POP BC ; return address
POP HL ; Gets Y coord into H
POP DE ; Gets Fill pattern into DE
LD L,A ; Gets Y,X into HL
PUSH BC ; Puts return address back
push ix
call SPPFill_start 
pop ix
ret
;
; SPFill
;

#include once <SP/PixelUp.asm>
#include once <SP/PixelDown.asm>
#include once <SP/CharLeft.asm>
#include once <SP/CharRight.asm>
#include once <SP/GetScrnAddr.asm>

; Patterned Flood Fill
; Alvin Albrecht 2002
; Tweaked to work in ZX Basic by Britlion, 2012.
;
; This subroutine does a byte-at-a-time breadth-first patterned flood fill.
; It works by allocating a circular queue on the stack, with the size of the
; queue determined by an input parameter.  The queue is divided into three
; contiguous blocks: the pattern block, the investigate block and the new block.
; The queue contains 3-byte structures (described below) with a special structure
; delimiting each block.  The physical end of the queue is marked with a special
; byte.  The contents of the queue grow down in memory.
;
; The pattern block holds pixels that have been blackened on screen and are
; only waiting to have the pattern applied to them before they are removed
; from the queue.
;
; The investigate block holds pixels that have been blackened on screen and
; are waiting to be investigated before they become part of the pattern
; block.  'Investigating' a pixel means trying to expand the fill in all
; four directions.  Any successful expansion causes the new pixel to be
; added to the new block.
;
; The new block holds pixels that have been blackened on screen and are
; waiting to become part of the investigate block.  The new block expands
; as the investigate block is investigated.
;
; The pattern fill algorithm follows these steps:
; 1. Examine the investigate block.  Add new pixels to the new block if an
;    expansion is possible.
; 2. Pattern the pattern block.  All pixels waiting to be patterned are
;    patterned on screen.
; 3. The investigate block becomes the pattern block.
;    The new block becomes the investigate block.
; 4. Repeat until the investigate block is empty.
;
; The algorithm may bail out prematurely if the queue fills up.  Bailing
; out causes any pending pixels in the queue to be patterned before the
; subroutine exits.  If PFILL would continue to run by refusing to enter
; new pixels when the queue is full, there would be no guarantee that
; the subroutine would ever return.
;
; In English, the idea behind the patterned flood fill is simple.  The
; start pixel grows out in a circular shape (actually a diamond).  A
; fill boundary two pixels thick is maintained in that circular shape.
; The outermost boundary is the frontier, and is where the flood fill
; is growing from (ie the investigate block).  The inner boundary is
; the pattern block, waiting to be patterned.  A solid inner boundary
; is necessary to prevent the flood-fill frontier pixels from growing
; back toward the starting pixel through holes in the pattern.  Once
; the frontier pixels are investigated, the innermost boundary is
; patterned.  The newly investigated pixels become the outermost
; boundary (the investigate block) and the old investigate block becomes
; the new pattern block.
;
; Each entry in the queue is a 3-byte struct that grows down in memory:
;       screen address      (2-bytes, MSB first)
;       fill byte           (1-byte)
; A screen address with MSB < 0x40 is used to indicate the end of a block.
; A screen address with MSB >= 0x80 is used to mark the physical end of the Q.
;
; The fill pattern is a typical 8x8 pixel character, stored in 8 bytes.

; enter: h = y coord, l = x coord, bc = max stack depth, de = address of fill pattern
;        In hi-res mode, carry flag is most significant bit of x coord
; used : ix, af, bc, de, hl
; exit : no carry = success, carry = had to bail queue was too small
; stack: 3*bc+30 bytes, not including the call to PFILL or interrupts
SPPFill_IXBuffer:
DEFB 0,0 ; buffer

SPPFill_start:
LD BC,300 ; Bytes allowed in stack.
LD (SPPFill_IXBuffer),IX
 
; enter: h = y coord, l = x coord, bc = max stack depth, de = address of fill pattern
;        In hi-res mode, carry flag is most significant bit of x coord


SPPFill:
   push de			; save (pattern pointer) variable
   dec bc			; we will start with one struct in the queue
   push bc			; save max stack depth variable

   ld a,h
   call SPGetScrnAddr	; de = screen address, b = pixel byte
   ex de,hl			; hl = screen address

;    ld b, h
;    ld c, l
;    call 22B0h      ; Uses ROM Pixel ADDR
;    ld b, a

   call bytefill	; b = fill byte
   jr c, viable
   pop bc
   pop de
   jp SPPFill_end ; quit - not viable.

   LOCAL viable
viable:
   ex de,hl			; de = screen address, b = fill byte
   ld hl,-7
   add hl,sp
   push hl			; create pattern block pointer = top of queue
   push hl
   pop ix			; ix = top of queue
   dec hl
   dec hl
   dec hl
   push hl			; create investigate block pointer
   ld hl,-12
   add hl,sp
   push hl			; create new block pointer

   xor a
   push af
   dec sp			; mark end of pattern block
   push de			; screen address and fill byte are
   push bc			;   first struct in investigate block
   inc sp
   push af
   dec sp			; mark end of investigate block

   ld c,(ix+7)
   ld b,(ix+8)		; bc = max stack depth - 1
   inc bc
   ld l,c
   ld h,b
   add hl,bc		; space required = 3*BC (max depth) + 10
   add hl,bc		; but have already taken 9 bytes
   ld c,l
   ld b,h			; bc = # uninitialized bytes in queue
   ld hl,0
   sbc hl,bc		; negate hl, additions above will not set carry
   add hl,sp
   ld (hl),0		; zero last byte in queue
   ld sp,hl			; move stack below queue
   ld a,$80
   push af			; mark end of queue with $80 byte
   inc sp
   ld e,l
   ld d,h
   inc de
   dec bc
   ldir			; zero the uninitialized bytes in queue
   
; NOTE: Must move the stack before clearing the queue, otherwise if an interrupt
; occurred, garbage could overwrite portions of the (just cleared) queue.

; ix = top of queue, bottom of queue marked with 0x80 byte

; Variables indexed by ix, LSB first:
;   ix + 11/12    return address
;   ix + 09/10    fill pattern pointer
;   ix + 07/08    max stack depth
;   ix + 05/06    pattern block pointer
;   ix + 03/04    investigate block pointer
;   ix + 01/02    new block pointer

; A picture of memory at this point:
;
;+-----------------------+   higher addresses
;|                       |         |
;|-   return address    -|        \|/
;|                       |         V
;+-----------------------+   lower addresses
;|        fill           |
;|-  pattern pointer    -|
;|                       |
;+-----------------------+
;|                       |
;|-  max stack depth    -|
;|                       |
;+-----------------------+
;|                       |
;|-   pattern block     -|
;|                       |
;+-----------------------+
;|                       |
;|- investigate block   -|
;|                       |
;+-----------------------+
;|                       |
;|-     new block       -|
;|                       |
;+-----------------------+
;|  end of block marker  |  <- ix = pattern block = top of queue
;|          ?            |
;|          ?            |
;+-----------------------+
;|  screen address MSB   |  <- investigate block
;|  screen address LSB   |
;|      fill byte        |
;+-----------------------+
;|  end of block marker  |
;|          ?            |
;|          ?            |
;+-----------------------+
;|          0            |  <- new block
;|          0            |
;|          0            |
;+-----------------------+
;|                       |
;|        ......         |  size is a multiple of 3 bytes
;|     rest of queue     |
;|      all zeroed       |
;|        ......         |
;|                       |
;+-----------------------+
;|         0x80           |  <- sp, special byte marks end of queue
;+-----------------------+

   LOCAL pfloop
pfloop:
   ld l,(ix+3)
   ld h,(ix+4)		; hl = investigate block
   ld e,(ix+1)
   ld d,(ix+2)		; de = new block
   call investigate
   ld (ix+1),e
   ld (ix+2),d		; save new block
   ld (ix+3),l
   ld (ix+4),h		; save investigate block

   ld l,(ix+5)
   ld h,(ix+6)		; hl = pattern block
   ld c,(ix+7)
   ld b,(ix+8)		; bc = max stack depth (available space)
   call applypattern
   ld (ix+7),c
   ld (ix+8),b		; save stack depth
   ld (ix+5),l
   ld (ix+6),h		; save pattern block

   ld a,(hl)		; done if the investigate block was empty
   cp 40h
   jp nc, pfloop

   LOCAL endpfill
endpfill:
   ld de,11			; return address is at ix+11
   add ix,de
   ld sp,ix
   or a			; make sure carry is clear, indicating success
   ret

; IN/OUT: hl = investigate block, de = new block

   LOCAL investigate
investigate:
   ld a,(hl)		
   cp 80h			; bit 15 of screen addr set if time to wrap		
   jp c, inowrap
   push ix
   pop hl			; hl = ix = top of queue
   ld a,(hl)

   LOCAL inowrap
inowrap:
   cp 40h			; screen address < 0x4000 marks end of block
   jp c, endinv		; are we done yet?
   ld b,a
   dec hl
   ld c,(hl)		; bc = screen address
   dec hl
   ld a,(hl)		; a = fill byte
   dec hl
   push hl			; save spot in investigate block
   ld l,c
   ld h,b			; hl = screen address
   ld b,a			; b = fill byte
   
   LOCAL goup
goup:
   push hl			; save screen address
   call SP.PixelUp		; move screen address up one pixel
   jr c, updeadend		; if went off-screen
   push bc			; save fill byte
   call bytefill
   call c, addnew		; if up is not dead end, add this to new block
   pop bc			; restore fill byte

   LOCAL updeadend
updeadend:
   pop hl			; restore screen address
   
   LOCAL godown
godown:
   push hl			; save screen address
   call SP.PixelDown		; move screen address down one pixel
   jr c, downdeadend
   push bc			; save fill byte
   call bytefill
   call c, addnew		; if down is not dead end, add this to new block
   pop bc			; restore fill byte

   LOCAL downdeadend
downdeadend:
   pop hl			; restore screen address

   LOCAL goleft
goleft:
   bit 7,b			; can only move left if leftmost bit of fill byte set
   jr z, goright
   ld a,l
   and 31
   jr nz, okleft
   bit 5,h              ; for hi-res mode: column = 1 if l=0 and bit 5 of h is set
   jr z, goright

   LOCAL okleft
okleft:
   push hl			; save screen address
   call SP.CharLeft
   push bc			; save fill byte
   ld b,01h		; set rightmost pixel for incoming byte
   call bytefill
   call c, addnew		; if left is not dead end, add this to new block
   pop bc			; restore fill byte
   pop hl			; restore screen address

   LOCAL goright
goright:
   bit 0,b			; can only move right if rightmost bit of fill byte set
   jr z, nextinv
   or a			; clear carry
   call SP.CharRight
   jr c, nextinv     	; went off screen
   ld a,l
   and 31
   jr z, nextinv  	; wrapped around line
   ld b,80h		; set leftmost pixel for incoming byte
   call bytefill
   call c, addnew		; if right is not dead end, add this to new block

   LOCAL nextinv
nextinv:
   pop hl			; hl = spot in investigate block
   jp investigate

   LOCAL endinv
endinv:
   dec hl
   dec hl
   dec hl			; investigate block now points at new block

   ld a,(de)		; check if new block is at end of queue
   cp 80h
   jr c, nowrapnew
   defb $dd
   ld e,l
   defb $dd
   ld d,h			; de = ix = top of queue

   LOCAL nowrapnew
nowrapnew:
   xor a
   ld (de),a		; store end marker for new block
   dec de
   dec de
   dec de
   ret

; enter b = incoming byte, hl = screen address
; exit  b = fill byte, screen blackened with fill byte

   LOCAL bytefill
bytefill:
   ld a,b
   xor (hl)			; zero out incoming pixels that
   and b			; run into set pixels in display
   ret z

   LOCAL bfloop
bfloop:
   ld b,a
   rra			; expand incoming pixels
   ld c,a			; to the right and left
   ld a,b			; within byte
   add a,a
   or c
   or b
   ld c,a
   xor (hl)			; zero out pixels that run into
   and c			; set pixels on display
   cp b
   jp nz, bfloop		; keep going until incoming byte does not change

   or (hl)
   ld (hl),a		; fill byte on screen
   scf			; indicate that this was a viable step
   ret

; add incoming fill byte and screen address to new block
; enter b = incoming byte, hl = screen address, de = new block

   LOCAL addnew
addnew:
   push hl			; save screen address
   ld l,(ix+7)
   ld h,(ix+8)		; hl = max stack depth
   ld a,h
   or l
   jr z, bail		; no space in queue so bail!
   dec hl			; available queue space decreases by one struct
   ld (ix+7),l
   ld (ix+8),h
   pop hl			; hl = screen address

   ld a,(de)		; check if new block is at end of queue
   cp 80h
   jr c, annowrap
   defb $dd
   ld e,l
   defb $dd
   ld d,h               ; de = ix = top of queue

   LOCAL annowrap
annowrap:
   ex de,hl
   ld (hl),d		; make struct, store screen address (2 bytes)
   dec hl
   ld (hl),e
   dec hl
   ld (hl),b		; store fill byte (1 byte)
   dec hl
   ex de,hl
   ret

; if the queue filled up, we need to bail.  Bailing means patterning any set pixels
; which may still be on the display.  If we didnt bail and tried to trudge along,
; there is no guarantee the fill would ever return.

   LOCAL bail
bail:
   pop hl			; hl = screen address, b = fill byte
   ld a,b
   xor (hl)
   ld (hl),a		; clear this byte on screen

   xor a
   ld (de),a		; mark end of new block

   ld l,(ix+5)
   ld h,(ix+6)		; hl = pattern block
   call applypattern	; for pattern block
   call applypattern	; for investigate block
   call applypattern	; for new block

   ld de,11			; return address is at ix+11
   add ix,de
   ld sp,ix
   scf			; indicate we had to bail
   jp SPPFill_end

; hl = pattern block, bc = max stack depth (available space)

   LOCAL applypattern
applypattern:
   ld a,(hl)
   cp 80h			; bit 15 of screen addr set if time to wrap
   jp c, apnowrap
   push ix
   pop hl			; hl = ix = top of queue
   ld a,(hl)

   LOCAL apnowrap
apnowrap:
   cp 40h			; screen address < 0x4000 marks end of block
   jr c, endapply		; are we done yet?

   and 07h			; use scan line 0..7 to index pattern
   add a,(ix+9)
   ld e,a
   ld a,0
   adc a,(ix+10)
   ld d,a			; de points into fill pattern
   ld a,(de)		; a = pattern 

   ld d,(hl)
   dec hl
   ld e,(hl)		; de = screen address
   dec hl

   and (hl)			; and pattern with fill byte
   sub (hl)			; or in complement of fill byte
   dec a
   ex de,hl
   and (hl)			; apply pattern to screen
   ld (hl),a
   ex de,hl
   dec hl
   inc bc			; increase available queue space
   jp applypattern

   LOCAL endapply
endapply:
   dec hl
   dec hl
   dec hl			; pattern block now pts at investigate block
   ret



SPPFill_end:
LD IX,(SPPFill_IXBuffer)
ENDP
END ASM
END SUB

#endif

