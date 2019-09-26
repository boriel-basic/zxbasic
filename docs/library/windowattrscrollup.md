#WindowAttrScrollUp

# BLAttrWindowScrollUp.bas  

This subroutine specified rectangle of screen and scrolls up just the colour attributes up by a character.
You might be able to use it for games (though there are probably faster scrolly routines for that);
but the aim here is to be able to scroll up part of the screen, so that you can split between text on a rectangle
area and other information elsewhere - e.g. graphic adventures.
This then is an addendum for [windowScrollUP.bas](windowscrollup.md), and can be called with it -
probably less useful in its own right. Note that it leaves the last line attributes untouched -
it can't know inherently what colour to paint this section.

```
SUB BLAttrWindowScrollUp (X AS UBYTE, Y AS UBYTE, Width AS UBYTE, Height AS UBYTE)
REM Routine, acting as a pair to BLWindowScrollUp.bas that moves the attributes up - and leaves the last ATTR line untouched (no way)
ASM
    LD H,58h  ; $5800 = 22528 = Attr start
    LD L,(IX+5) ; HL now contains correct column, but top row.
    
    LD A,(IX+7) ; Y   
    CP 8
    JR C, BLAttrWindowScrollUpGotRightThird   
    INC H
    CP 16
    JR C, BLAttrWindowScrollUpGotRightThird
    INC H
    BLAttrWindowScrollUpGotRightThird:
    AND 7
    RRCA
    RRCA
    RRCA  ; Three right rotates - same as 5 left rotates = A=A*32
    ADD A,L
    LD L,A ; HL now points to correct row, top left corner.
    
    LD D,H
    LD E,L ; Copy HL to DE
    
    LD BC,32
    ADD HL,BC ; Point HL at one row down.
    LD C,(IX+9) ; width
    LD B,(IX+11) ; Height
    DEC B ; (We don't scroll past the end)
    
    BLAttrWindowScrollUpHeightLoop:
    PUSH BC ; Save our width and height
    PUSH HL
    LD B,0
    
    BLAttrWindowScrollUpWidthLoop:
    LDIR ; A one instruction width loop :P
    
    POP DE ; Last run's source is now our destination
    LD H,D
    LD L,E ; Copy into HL
    LD BC,32
    ADD HL,BC ; Move HL down one row
    
    
    POP BC ; get our counters back
    DJNZ BLAttrWindowScrollUpHeightLoop ; Dec height, and if we haven't run out of rows, go do another one.
END ASM
END SUB
```


## Usage  
```
BLAttrWindowScrollUp(TopLeftXCoordinate, TopLeftYCoordinate, WidthInCharacters, HeightInCharacters)
```

The parameters are the X,Y print coordinates of the Top Left corner, width in characters, and height in characters.

Example of use:

```
REM Put something on screen:

FOR n=1 to 12
PRINT INK RND *7; PAPER RND * 7; "01234567890123456789012345678901";
PRINT INK RND *7; PAPER RND * 7; "0ABCDEFGHI0KLMNOPQRS0UVWXYZABC0D";
NEXT n

REM Scroll it slowly:
FOR n=1 TO 10
BLAttrWindowScrollUp (3,3,8,15)
BLAttrWindowScrollUp (28,10,3,8)
PAUSE 100
NEXT n
```
