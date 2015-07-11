' vim:ts=4:et:

#ifndef __PRINT42__
#define __PRINT42__

' --------------------------------------------------
' A PRINT Routine with 42 COLUMNS!
'
' Contributed by Britlion
' --------------------------------------------------

#pragma push(case_insensitive)
#pragma case_insensitive = TRUE

SUB printat42 (y as uByte, x as uByte)
    POKE @printAt42Coords,x
    POKE @printAt42Coords+1,y
END SUB


SUB print42(characters$ as string)
asm
    PROC

    LD A, H
    OR L
    RET Z

    LD C,(HL)
    INC HL
    LD B,(HL)       ; all told, LD BC with the length of the string.

    LD A, C
    OR B
    JP Z, print64end           ; Is the length of the string 0? If so, quit.

    INC HL          ;Puts HL to the first real character in the string.

LOCAL examineChar
examineChar:
    LD A,(HL)       ; Grab the character at our pointer position
    CP 128          ; Too high to print?
    JR NC, nextChar ; Then we go to the next

    CP 22           ; Is this an AT?
    JR NZ, isNewline ; If not jump over the AT routine to isNewline

LOCAL isAt
isAt:
    EX DE,HL        ; Get DE to hold HL for a moment
    ;;AND A           ; Plays with the flags. One of the things it does is reset Carry.
    ;;LD HL,00002
    ;;SBC HL,BC       ; Subtract length of string from HL.
    LD HL, -2
    ADD HL, BC
    EX DE,HL        ; Get HL back from DE
    ;;RET NC          ; If the result WASN'T negative, return. (We need AT to have parameters to make sense)
    JP NC, print64end ; If the result WASN'T negative, return. (We need AT to have parameters to make sense)

    INC HL          ; Onto our Y co-ordinate
    LD D,(HL)       ; Put it in D
    DEC BC          ; and move our string remaining counter down one               
    INC HL          ; Onto our X co-ordinate
    LD E,(HL)       ; Put the next one in E
    DEC BC          ; and move our string remaining counter down one
    CALL nxtchar      ; Call routine to shuffle right a char
    JR newline      ; Hop over to

LOCAL isNewline
isNewline:
    CP 13           ; Is this character a newline?
    JR NZ,checkvalid     ; If not, jump forward

LOCAL newline
newline:
    ;LD DE,(63536)
    CALL nxtline       ; move to next line

    ;LD (63536),DE     ; and go on to next character
    JR nextChar
       
LOCAL checkvalid
checkvalid:
    CP 31           ; Is character <31?
    JR C, nextChar  ; If not go to next character

LOCAL prn
prn:
    PUSH HL          ; Save our position
    PUSH BC          ; Save our countdown of chars left
    CALL printachar       ; Go print a character
    POP BC           ; Recover our count
    POP HL           ; Recover our position                               

LOCAL nextChar
nextChar:
    INC HL           ; Move to the next position
    DEC BC           ; count off a character
    LD A,B
    OR C            ; Did we hit the end of our string? (BC=0?)
    JR NZ, examineChar    ; If not, we need to go look at the next character.
    JP print64end    ; End the print routine       


; This routine forms the new 6-bit wide characters and
;alters the colours to match the text. The y,x co-ordinates and eight
;bytes of workspace are located at the end of this chunk.
; it starts with the character ascii code in the accumulator

LOCAL printachar
printachar:
      EXX
      PUSH HL ; Store H'L' where we can get it.
      EXX               

      ld c, a   ; Put a copy of the character in C
      ld h, 0   
      ld l, a   ; Put the Character in HL
      
      ld de, whichcolumn-32 ; the character is at least 32, so space = 0th entry.     
      add hl, de       ; HL -> table entry for char.
      ld a, (hl)       ; Load our column slice data from the table.
      cp 32          ; Is it less than 32?
      jr nc, calcChar   ; If so, go to the calculated character subroutine

; This is the special case 'we defined the character in the table' option   
      ld de, characters ; Point DE at our table
      ld l, a          ; Put our character number from our table lookup that's in HL in a
      call mult8       ; multiplies L by 8 and adds in DE [so HL points at our table entry]
      ld b, h         
      ld c, l          ; Copy our character data address into BC
      jr printdata       ; We have our data source, so we print it.

LOCAL calcChar
calcChar: ; this is the calculate from the ROM data option
      ; a holds the column kill data
      ld de, 15360       ; Character set-256. We could use CHARS here, maybe; but might not work with a redefiend character set.
      ld l, c          ; Get our character back from C
      call mult8       ; Multiply l by 8 and add to DE. (HL points at the ROM data for our character now)
      
      ld de, workspace  ; Point DE at our 8 byte workspace.
      push de          ; Save it
      exx              ;
      ld c, a          ; Put our kill column in C'
      cpl              ; Invert
      ld b, a          ; Put the inverse in B'
      exx              ;
      ld b, 8          ; 8 bytes to a character loop counter

LOCAL loop1
loop1:
      ld a, (hl)       ; Load a byte of character data
      inc hl          ; point at the next byte
      exx              ;
      ld e, a          ; Put it in e'
      and c          ; keep the left column block we're using
      ld d, a          ; and put it in d'
      ld a, e          ; grab our original back
      rla              ; shift it left (which pushes out our unwanted column)
      and b          ; keep just the right block
      or d              ; mix with the left block
      exx              ;
      ld (de), a       ; put it into our workspace
      inc de          ; next workspace byte
      djnz loop1       ; go round for our other bytes
   
      pop bc          ; Recover a pointer to our workspace.

LOCAL printdata
printdata:
      call testcoords    ; check our position, and wrap around if necessary. [returns with d=y,e=x]
      inc e          ; Bump along to next co-ordinate
      ld (xycoords), de ; Store our coordinates for the next character
      dec e          ; Bump back to our current one
      ld a, e          ; get x
      sla a          ;  Shift Left Arithmetic - *2
      ld l, a          ; put x*2 into L
      sla a          ; make it x*4
      add a, l           ; (x*2)+(x*4)=6x
      ld l, a          ; put 6x into L [Since we're in a 6 pixel font, L now contains the # of first pixel we're interested in]
      srl a          ; divide by 2
      srl a          ; divide by another 2 (/4)
      srl a          ; divide by another 2 (/8)
      ld e, a          ; Put the result in e (Since the screen has 8 pixel bytes, pixel/8 = which char pos along our first pixel is in)
      ld a, l          ; Grab our pixel number again
      and 7          ; And do mod 8 [So now we have how many pixels into the character square we're starting at]
      push af          ; Save A
      ex af, af'         
      ld a, d          ; Put y Coord into A'
      sra a          ; Divide by 2
      sra a          ; Divide by another 2 (/4 total)
      sra a          ; Divide by another 2 (/8) [Gives us a 1/3 of screen number]
      add a, 88       ; Add in start of screen attributes high byte
      ld h, a          ; And put the result in H
      ld a, d          ; grab our Y co-ord again
      and 7          ; Mod 8 (why? *I thought to give a line in this 1/3 of screen, but we're in attrs here)
      rrca              ;
      rrca              
      rrca              ; Bring the bottom 3 bits to the top - Multiply by 32
    		; (since there are 32 bytes across the screen), here, in other words. [Faster than 5 SLA instructions]
      add a, e           ; add in our x coordinate byte to give us a low screen byte
      ld l, a             ; Put the result in L. So now HL -> screen byte at the top of the character
      
      ld a, (23693)    ; ATTR P     Permanent current colours, etc (as set up by colour statements).
      ld e, a          ; Copy ATTR into e
      ld (hl), e       ; Drop ATTR value into screen
      inc hl          ; Go to next position along
      pop af          ; Pull how many pixels into this square we are
      cp 3              ; It more than 2?
      jr c, hop1       ; No? It all fits in this square - jump changing the next attribute
   
      ld (hl), e       ; 63446 Must be yes - we're setting the attributes in the next square too.

LOCAL hop1
hop1:
      dec hl          ; Back up to last position
      ld a, d          ; Y Coord into A'
      and 248          ; Turn it into 0,8 or 16. (y=0-23)
      add a, 64       ; Turn it into 64,72,80  [40,48,50 Hex] for high byte of screen pos
      ld h, a          ; Stick it in H
      push hl          ; Save it
      exx              ; Swap registers
      pop hl          ; Put it into H'L'
      exx              ; Swap Back
      ld a, 8          

LOCAL hop4
hop4:
      push af          ; Save Accumulator
      ld a, (bc)       ; Grab a byte of workspace
      exx              ; Swap registers
      push hl          ; Save h'l'
      ld c, 0          ; put 0 into c'
      ld de, 1023       ; Put 1023 into D'E'
      ex af, af'       ; Swap AF
      and a          ; Flags on A
      jr z, hop3       ; If a is zero jump forward

      ld b, a          ; A -> B
      ex af, af'       ; Swap to A'F'

LOCAL hop2
hop2:; Slides a byte right to the right position in the block (and puts leftover bits in the left side of c)
      and a          ; Clear Carry Flag
      rra              ; Rotate Right A
      rr c              ; Rotate right C (Rotates a carry flag off A and into C)
      scf              ; Set Carry Flag
      rr d              ; Rotate Right D
      rr e              ; Rotate Right E (D flows into E, with help from the carry bit)
      djnz hop2       ; Decrement B and loop back
      
      ex af, af'      

LOCAL hop3
hop3:
      ex af, af'      
      ld b, a         
      ld a, (hl)      
      and d         
      or b              
      ld (hl), a       ; Write out our byte
      inc hl          ; Go one byte right
      ld a, (hl)       ; Bring it in
      and e         
      or c              ; mix those leftover bits into the next block
      ld (hl), a       ; Write it out again
      pop hl         
      inc h               ; Next line
      exx               
      inc bc            ; Next workspace byte
      pop af         
      dec a           
      jr nz, hop4       ; And go back!
   
      exx              ; Tidy up
      pop hl           ; Clear stack leftovers
      exx              ; And...
      ret              ; Go home.

LOCAL mult8
mult8: ; Multiplies L by 8 -> HL and adds it to DE. Used for 8 byte table vectors.
      ld h, 0         
      add hl, hl      
      add hl, hl      
      add hl, hl       
      add hl, de      
      ret
             
LOCAL testcoords
testcoords:
      ld de, (xycoords)   ; get our current screen co-ordinates (d=y,e=x - little endian)

LOCAL nxtchar
nxtchar:
      ld a, e          ;
      cp 42          ; Are we >42?
      jr c, ycoord    ; if not, hop forward

LOCAL nxtline
nxtline:
      inc d          ; if so, so bump us to the next line down
      ld e, 0          ; and reset x to left edge

LOCAL ycoord
ycoord:
      ld a, d          ;
      cp 24          ; are we >24 lines?
      ret c          ; if no, exit subroutine
      ld d, 0          ; if yes, wrap around to top line again.
      ret              ; exit subroutine
end asm
printAt42Coords:
asm      
LOCAL xycoords
xycoords:
       defb 0      ; x coordinate     
       defb 0      ; y coordinate

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
   
; The data below identifies a column in the character to remove. It consists of 1's
; from the left edge. First zero bit is the column we're removing.
; If the leftmost bit is NOT 1, then the byte represents a redefined character position
; in the lookup table.
   
LOCAL whichcolumn
whichcolumn:             
    defb 254         ; SPACE
    defb 254         ; !
    defb 128         ; ""
    defb 224         ; #
    defb 128         ; $
    defb 0           ; % (Redefined below)
    defb 1           ; &  (Redefined below)
    defb 128         ; '
    defb 128         ; (
    defb 128         ; )
    defb 128         ; *
    defb 128         ; +
    defb 128         ; ,
    defb 128         ; -
    defb 128         ; .
    defb 128         ; /
    defb 2           ; 0 (Redefined below)
    defb 128       ; 1
    defb 224       ; 2
    defb 224       ; 3
    defb 252       ; 4
    defb 224        ; 5
    defb 224        ; 6
    defb 192       ; 7
    defb 240       ; 8
    defb 240       ; 9
    defb 240       ; :
    defb 240       ; ;
    defb 192       ; <
    defb 240       ; =
    defb 192       ; >
    defb 192       ; ?
    defb 248       ; @
    defb 240       ; A
    defb 240       ; B
    defb 240       ; C
    defb 240       ; D
    defb 240       ; E
    defb 240       ; F
    defb 240       ; G
    defb 240       ; H
    defb 128       ; I
    defb 240       ; J
    defb 192       ; K
    defb 240       ; L
    defb 240       ; M
    defb 248       ; N
    defb 240       ; O
    defb 240       ; P
    defb 248       ; Q
    defb 240       ; R
    defb 240       ; S
    defb 3         ; T
    defb 240       ; U
    defb 240       ; V
    defb 240       ; W
    defb 240       ; X
    defb 4         ; Y
    defb 252       ; Z
    defb 224       ; [
    defb 252       ; \
    defb 240      ; ]   
    defb 252      ; ^
    defb 240        ; _
    defb 240        ; UK Pound (Currency) Symbol
    defb 255      ; a
    defb 128      ; b
    defb 255      ; c   
    defb 255      ; d   
    defb 255      ; e   
    defb 255      ; f   
    defb 255      ; g   
    defb 255      ; h   
    defb 255      ; i   
    defb 255      ; j   
    defb 255      ; k   
    defb 255      ; l   
    defb 255      ; m   
    defb 255      ; n   
    defb 255      ; o   
    defb 255      ; p   
    defb 255      ; q   
    defb 255      ; r   
    defb 255      ; s   
    defb 255      ; t   
    defb 255      ; u   
    defb 255      ; v   
    defb 255      ; w   
    defb 255      ; x   
    defb 255      ; y   
    defb 255      ; z   
    defb 128      ; {
    defb 128      ; |
    defb 255      ; }   
    defb 128      ; ~
    defb 5         ; (c)  end column data
   
   
LOCAL characters
characters:   
    defb 0           ; %         
    defb 0         
    defb 100      
    defb 104      
    defb 16
    defb 44
    defb 76
    defb 0
   
    defb 0           ; &
    defb 32
    defb 80           
    defb 32
    defb 84           
    defb 72         
    defb 52      
    defb 0      
   
    defb 0          ; digit 0
    defb 56
    defb 76       
    defb 84         
    defb 84         
    defb 100      
    defb 56         
    defb 0
   
    defb 0           ; Letter T
    defb 124      
    defb 16
    defb 16         
    defb 16
    defb 16         
    defb 16
    defb 0        
   
    defb 0          ; Letter Y
    defb 68         
    defb 68         
    defb 40
    defb 16       
    defb 16
    defb 16       
    defb 0         
   
    defb 0          ; (c) symbol
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

end asm   
END SUB   

#pragma pop(case_insensitive)

#endif

