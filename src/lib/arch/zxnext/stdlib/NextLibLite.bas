' ---------------------------------------------------------
' NextLibLite v0.2
' This is a subset of nextBuild/NextLib library
' ZX Spectrum Next library
'
' This file is released under the MIT License
' Copyleft (k) 2024
' Adapted by Juan Segura "Duefectu" from NextBuild/NextLib
' NextLib by David Saphier "emook"
' Help and thanks Boriel, Flash, Baggers, Britlion, Shiru,
' Mike Daily, Matt Davies, Michael WareF
'
' Commands included:
' NextInit, BREAK, BBREAK
' NextReg, NextRegA, GetReg
' ShowLayer2, CLS256, PlotL2, ScrollLayer
' InitSprites, RemoveSprite, UpdateSprite
' DoTile, DoTile8
' LoadSD, SaveSD, LoadBMP
' ---------------------------------------------------------


' - Avoid recursive / multiple inclusion ------------------
#IFNDEF __NEXTLIBLITE__
#DEFINE __NEXTLIBLITE__


' - PRAGMAS -----------------------------------------------
' Avoid case sensitive troubles
#PRAGMA push(case_insensitive)
#PRAGMA case_insensitive = True


' - Defines -----------------------------------------------
' Layer 2
#DEFINE LAYER2_ACCESS_PORT $123B

' esxDOS constants
ASM
    M_GETSETDRV     equ $89
    F_OPEN          equ $9a
    F_CLOSE         equ $9b
    F_READ          equ $9d
    F_WRITE         equ $9e
    F_SEEK          equ $9f
    F_STAT          equ $a1
    FA_READ         equ $01
    FA_APPEND       equ $06
    FA_OVERWRITE    equ $0C
END ASM

#DEFINE ESXDOS \
        rst 8


' - Work space --------------------------------------------
filename:
ASM
filename:
    DEFS 255,0
END ASM



' - NextInit ----------------------------------------------
' Initializes the library
' ---------------------------------------------------------
SUB NextInit()
    ASM
        ld iy,$5c3a    ; Patch for NextCreator: IY must point to SystemVars
    END ASM
END SUB


' ---------------------------------------------------------
' - Debug -------------------------------------------------
' ---------------------------------------------------------

' - BREAK -------------------------------------------------
' Put a breakpoint for ASM debug in CSpect
' ---------------------------------------------------------
#define BREAK \
    DB $c5,$DD,$01,$0,$0,$c1 \


' - BBREAK ------------------------------------------------
' Put a breakpoint for BASIC debug in CSpect
' ---------------------------------------------------------
#define BBREAK \
    ASM\
    BREAK\
    END ASM\


' ---------------------------------------------------------
' - Next registers ----------------------------------------
' ---------------------------------------------------------

' - NextReg -----------------------------------------------
' Write a value into Next register
' This implementation can only be used if REG and VAL are
' fixed values. If we want to use variables for any of the
' parameters, we must use "NextRegA", which is slower and
' takes up more space.
' Parameters:
'   REG (UByte): Register to change
'   VAL (UByte): Value to write
' ---------------------------------------------------------
#DEFINE NextReg(REG,VAL) \
    ASM\
    DW $91ED\
    DB REG\
    DB VAL\
    END ASM\


' - NextRegA ----------------------------------------------
' Write a value into Next register
' If we can use fixed values (not coming from a variable),
' it is better to use "NextReg" instead of this subroutine.
' Parameters:
'   reg (UByte): Register to change
'   value (UByte): Value to write
' ---------------------------------------------------------
SUB NextRegA(reg AS UByte,value AS UByte)
    asm
        PROC
        LOCAL reg
        ld a,(IX+5)
        ld (reg),a
        ld a,(IX+7)
        DW $92ED
    reg:
        db 0
        ENDP
    end asm
END SUB


' - GetReg ------------------------------------------------
' Returns the value of a Next register
' Parameters:
'   REG (UByte): Register to read
' Returns:
'   UByte: Value of the Next register
' ---------------------------------------------------------
FUNCTION FASTCALL GetReg(ByVal slot AS UByte) AS UByte
    asm
        ld bc,$243B            ; Register Select
        out(c),a            ;
        ld bc,$253B            ; reg access
        in a,(c)
    end asm
END FUNCTION


' ---------------------------------------------------------
' - Layer 2 256x192, 256 colours --------------------------
' ---------------------------------------------------------

' - ShowLayer2 --------------------------------------------
' Display or hide Layer 2 with a resolution of 256x192 and
' 256 colours
' Parameters:
'   switch (UByte): 0 para ocultar, 1 para mostrar
' ---------------------------------------------------------
SUB FASTCALL ShowLayer2(BYVAL switch AS UByte)
    ' 0 to disable layer 2
    ' 1 to enable layer 2
    ASM
        PROC
        LOCAL disable
        or         a
        jr         z,disable
        nextreg $69,%10000000
        ret
disable:
        nextreg $69,0
        ENDP
    END ASM
end sub



' - CLS256 ------------------------------------------------
' Clear the Layer 2 screen (256x192) with the specified
' colour.
' Original code Mike Dailly
' Parameters:
'   colour (UByte): Background colour
' ---------------------------------------------------------
SUB CLS256(byval colour as ubyte)
    ASM


    Cls256:
        push    bc
        push    de
        push    hl

        ld bc,$123b                ; L2 port
        in a,(c)                ; read value
        push af                 ; store it
        xor a
        out    (c),a


        ld a,(IX+5)                ; get colour

        ld    d,a                    ; byte to clear to
        ld    e,3                    ; number of blocks
        ld    a,1                    ; first bank... (bank 0 with write enable bit set)

        ld      bc, $123b
    LoadAll:
        out    (c),a                ; bank in first bank
        push    af
                ; Fill lower 16K with the desired byte
        ld    hl,0
    ClearLoop:
        ld    (hl),d
        inc    l
        jr    nz,ClearLoop
        inc    h
        ld    a,h
        cp    $40
        jr    nz,ClearLoop

        pop    af                    ; get block back
        add    a,$40
        dec    e                    ; loops 3 times
        jr    nz,LoadAll

        ld  bc, $123b            ; switch off background (should probably do an IN to get the original value)
        ;ld    a,0
        pop af
        out    (c),a

        pop    hl
        pop    de
        pop    bc

    end asm
end Sub


' - PlotL2 ------------------------------------------------
' Draw a colored pixel in Layer2 256x192 mode
' Original from David Saphier's NextLib v6
'
' Sample of use:
' PlotL2(10,20,30)
'
' Parameters:
'   x (UByte): X coordinate from left (0-255)
'   y (UByte): Y coordinate from top (0-191)
'   c (Ubyte): Pixel colour index (0-255)
' ---------------------------------------------------------
Sub fastcall PlotL2(ByVal x As ubyte, ByVal y As ubyte, ByVal c As ubyte)
ASM
    ;BREAK
    ld   bc, LAYER2_ACCESS_PORT
    pop  hl      ; save return address
    ld   e, a     ; put a into e
    pop  af      ; pop stack into a
    ld   d, a     ; put into d
    And  192     ; yy00 0000

    Or   3       ; yy00 0011
    out(c),a   ; Select 8k-bank
    ld   a, d     ; yyyy yyyy
    And  63      ; 00yy yyyy
    ld   d, a
    pop  af      ; get colour/map value
    ld(de),a   ; Set pixel value

    ld   a, 2     ; 0000 0010
    out(c),a   ; Select ROM?
    push hl      ; restore return address

; 6-7    Video RAM bank select
; 3        Shadow Layer 2 RAM select
; 1        Layer 2 visible
; 0        Enable Layer 2 write paging

  End ASM
End Sub


' - ScrollLayer -------------------------------------------
' Performs horizontal and/or vertical scrolling of Layer 2.
' What it actually does is to set the offset of the screen
' to the X and Y coordinates indicated.
'
' Parameters:
'   x (UByte): Horizontal offset
'   y (UByte): Vertical offset
' ---------------------------------------------------------
Sub FASTCALL ScrollLayer(byval x as ubyte,byval y as ubyte)
    asm
        PROC
        pop     hl                     ; store ret address
        nextreg $16,a                ; a has x
        pop     af
        nextreg $17,a                 ; now a as y
        push     hl
        ENDP
    end asm
END SUB


' ---------------------------------------------------------
' - Sprites -----------------------------------------------
' ---------------------------------------------------------

' - InitSprites -------------------------------------------
' Defines the set, or a part of it, of sprites to be used
'
' Parameters:
'   Total (UByte): Number of sprites to be defined
'   spraddress (UInteger): Address of the sprites
'   firstSprite (UByte): Number of the first sprite to define
' ---------------------------------------------------------
SUB InitSprites(byVal Total as ubyte, spraddress as uinteger, byval firstSprite as ubyte = 0)
    ASM
        PROC
        LOCAL sploop
        ld d,(IX+5)
        ;Select slot #0
        ;xor a
        ld a,(ix+9)
        ld bc, $303b
        out (c), a

        ld b,d                                ; how many sprites to send

        ld l, (IX+6)
        ld h, (IX+7)
sploop:
        push bc
        ld bc,$005b
        otir
        pop bc
        djnz sploop
        ENDP
    end asm
END Sub


' - RemoveSprite ------------------------------------------
' Deletes (makes disappear) a sprite from the screen
' Parameters:
'   spriteId (UByte): Identifier of the sprite to hide
'   visible (UByte): 0 = Hidden, 1 = Visible
' ---------------------------------------------------------
Sub RemoveSprite(spriteid AS UBYTE, visible as ubyte)
    ASM
        push bc
        ld a,(IX+5)                    ; get ID spriteid
        ld bc, $303b                ; selct sprite
        out (c), a
        ld bc, $57                    ; sprite port

        ; REM now send 4 bytes

        xor a                         ; get x and send byte 1
        out (c), a                  ;   X POS
        ;ld a,0                        ; get y and send byte 2
        out (c), a                  ;   X POS
        ;ld a,0                        ; no palette offset and no rotate and mirrors flags send  byte 3
        out (c), a
        ld a,(IX+7)                    ; Sprite visible and show pattern #0 byte 4
        out (c), a
        pop bc
    END ASM
END Sub


' - UpdateSprite ------------------------------------------
' Updates the position and properties of the sprite on the screen.
' The sprites are printed from the hardware top-left edge of the Next.
' To place a sprite at position 0,0 in Layer 2, you must point to 32,32.
' Parameters:
'   x (UInteger): Horizontal position of the sprite (0-319) - (32-287)
'   x (UByte): Vertical position of the sprite (0-255) - (32-223)
'   spriteId (UByte): Identifier of the sprite to hide
'   pattern (UByte): Number of element to use for the sprite within the sprite set
'   mflip (UByte): Attribute 2 of the sprite (0=default). Bits: PPPXYRH
'                   PPPP = Palette offset for the sprite
'                   X = Horizontal mirror, 0 = Off, 1 = On
'                   Y = Vertical mirror, 0 = Off, 1 = On
'                   R = Rotation, 0 = None, 1 = 90 degrees clockwise
'                   H = Ignored
'   anchor (UByte): Attribute 4 of the sprite (0=default). Bits: ---ZXZY-
'                   ZX: Horizontal zoom factor (0-3)
'                   ZY: Vertical zoom factor (0-3)
' ---------------------------------------------------------
Sub UpdateSprite(ByVal x AS uinteger,ByVal y AS UBYTE,ByVal spriteid AS UBYTE,ByVal pattern AS UBYTE,ByVal mflip as ubyte,ByVal anchor as ubyte)
    '                  5                    7              9                     11                   13                   15                        17
    '  http://devnext.referata.com/wiki/Sprite_Attribute_Upload
    '  Uploads attributes of the sprite slot selected by Sprite Status/Slot Select ($303B).
    ' Attributes are in 4 byte blocks sent in the following order; after sending 4 bytes the address auto-increments to the next sprite.
    ' This auto-increment is independent of other sprite ports. The 4 bytes are as follows:

    ' Byte 1 is the low bits of the X position. Legal X positions are 0-319 if sprites are allowed over the border or 32-287 if not. The MSB is in byte 3.
    ' Byte 2 is the Y position. Legal Y positions are 0-255 if sprites are allowed over the border or 32-223 if not.
    ' Byte 3 is bitmapped:

    ' Bit    Description
    ' 4-7    Palette offset, added to each palette index from pattern before drawing
    ' 3    Enable X mirror
    ' 2    Enable Y mirror
    ' 1    Enable rotation
    ' 0    MSB of X coordinate
    ' Byte 4 is also bitmapped:
    '
    ' Bit    Description
    ' 7    Enable visibility
    ' 6    Reserved
    ' 5-0    Pattern index ("Name")

    ASM
        ;
        ;                X   Y ID  Pa
        ;               45   7  9  11 13 15
        ;                0   1  0  3  2  4
        ; UpdateSprite(32 ,32 ,1 ,1 ,0 ,6<<1)
        ld a,(IX+9)            ;19                        ; get ID spriteid
        ld bc, $303b        ;10                        ; selct sprite slot
        ; sprite
        out (c), a            ;12

        ld bc, $57            ;10                        ; sprite control port
        ld a,(IX+4)         ;19                        ; attr 0 = x  (msb in byte 3)
        out (c), a          ;12

        ld a,(IX+7)            ;19                        ; attr 1 = y  (msb in optional byte 5)
        out (c), a             ;12

        ld d,(IX+13)        ;19                        ; attr 2 = now palette offset and no rotate and mirrors flags send  byte 3 and the MSB of X
        ;or (IX+5)            ;19

        ld a,(IX+5)            ;19                        ; msb of x
        and 1                ;7
        or d                 ;4
        out (c), a             ;12                    ; attr 3


        ld a,(IX+11)        ;19                        ; attr 4 = Sprite visible and show pattern
        or 192                 ;7                        ; bit 7 for visibility bit 6 for 4 bit

        out (c), a            ;12
        ld a,(IX+15)        ;19                        ; attr 5 the sub-pattern displayed is selected by "N6" bit in 5th sprite-attribute byte.
        out (c), a            ;12                     ; att
        ; 243 T
    END ASM
END SUB





' ---------------------------------------------------------
' - Tiles -------------------------------------------------
' ---------------------------------------------------------

' - DoTile ------------------------------------------------
' Draw a 16x16 tile on the Layer 2 screen
' The tile bank must be located at address $c000
' Parameters:
'   X (UByte): Horizontal position of the tile divided by 16 (0-15)
'   Y (UByte): Vertical position of the tile divided by 16 (0-12)
'   T (UByte): Tile number to draw (0-64)
SUB DoTile(byVal X as ubyte, byval Y as ubyte, byval T as ubyte)

    ASM
        PUSH IX
        ; Grab xyt
        ld b,(IX+7)
        ld c,(IX+5)
        ld a,(IX+9)

    ; tile data @ $c000
        ;----------------
        ; Original code by Michael Ware adjustd to work with ZXB
        ; Plot tile to layer 2
        ; in - bc = y/x tile coordinate (0-11, 0-15)
        ; in - a = number of tile to display
        ;----------------

    PlotTile16:
        ex af,af'
        ld a,b
        SWAPNIB
        ld d,a
        ld a,c
        SWAPNIB
        ld e,a
        ld a,d
        and 192
        or 3
        ld bc,LAYER2_ACCESS_PORT
        out (c),a                 ; select bank
        ex af, af'
        or 192                     ; tiles start from $C000
        ld h,a
        ld l,0                    ; put tile number * 256 into hl.
        ld a,d
        and 63
        ld d,a
        ld a,16
        ld b,0
    plotTilesLoop:
        ld c, 16                ; t 7
        push de
        ldir
        ;DB $ED,$B4
        pop de                    ; blat from hl to de, bc times
        inc d
        dec a
        jr nz,plotTilesLoop
        ;ret

        ld a,2            ; Bug ?
        ld bc,LAYER2_ACCESS_PORT
        out(c),a

        POP IX
    END ASM
end sub


' - DoTile8 -----------------------------------------------
' Draw a 8x8 tile on the Layer 2 screen
' The tile bank must be located at address $c000
' Parameters:
'   X (UByte): Horizontal position of the tile divided by 8 (0-31)
'   Y (UByte): Vertical position of the tile divided by 8 (0-23)
'   T (UByte): Tile number to draw (0-64)
SUB DoTile8(byVal X as ubyte, byval Y as ubyte, byval T as ubyte)
    ASM
        ;BREAK
        ;PUSH IX
        ; Grab xyt
        ld l,(IX+5)

        ld h,(IX+7)

        ld a,(IX+9)

        ;----------------
        ; Original code by Michael Ware adjustd to work with ZXB
        ; Plot tile to layer 2 (needs to accept > 256 tiles)
        ; in - hl = y/x tile coordinate (0-17, 0-31)
        ; in - a = number of tile to display
        ;----------------
PlotTile8:
        ld d,64
        ld e,a                ; 11
        MUL_DE                    ; ?

        ld a,%11000000
        or d             ; 8
        ex de,hl                ; 4            ; cannot avoid an ex (de now = yx)
        ld h,a                    ; 4
        ld a,e
        rlca
        rlca
        rlca
        ld e,a        ; 4+4+4+4+4 = 20    ; mul x,8
        ld a,d
        rlca
        rlca
        rlca
        ld d,a        ; 4+4+4+4+4 = 20    ; mul y,8
        and 192
        or 3            ; or 3 to keep layer on                ; 8
        ld bc,LAYER2_ACCESS_PORT
        out (c),a      ; 21            ; select bank

        ld a,d
        and 63
        ld d,a            ; clear top 2 bits of y (dest) (4+4+4 = 12)
        ; T96 here
        ld a,8                    ; 7
plotTilesLoop2:
        push de                    ; 11
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi        ; 8 * 16 = 128

        pop de                    ; 11
        inc d                    ; 4 add 256 for next line down
        dec a                    ; 4
        jr nz,plotTilesLoop2            ; 12/7
        ;ret

        ld a,2            ; Bug ?
        ld bc,LAYER2_ACCESS_PORT
        out(c),a
    END ASM
END SUB



' ---------------------------------------------------------
' - File management ---------------------------------------
' ---------------------------------------------------------

' - LoadSD ------------------------------------------------
' Load a file from SD.
' Parameters:
'   filen (String): File name to load
'   address (UInteger): Memory address where file data will be loaded
'   length (UInteger): Size of data to be downloaded
'   offset (Uinteger): Offset in the file of the data to read
SUB LoadSD(byval filen as String,ByVal address as uinteger,ByVal length as uinteger,ByVal offset as ulong)

    dim tlen, nbx as ubyte
    filen = filen + chr(0)
    tlen=len(filen)+1
    dim cco as ubyte=0

    asm
    ld hl,.LABEL._filename
        ld de,.LABEL._filename+1
        ld bc,64
        ld (hl),0
        ldir
    end asm
    for nbx=0 to tlen
        if code(filen(cco))>32

        poke @filename+cast(uinteger,cco),code (filen(cco))

        endif
        cco=cco+1
    next
    poke @filename+nbx+1,0

    asm
        PROC
        LOCAL initdrive
        LOCAL filehandle
        LOCAL error
        LOCAL fileopen
        LOCAL mloop
        LOCAL divfix
        LOCAL fileseek
        LOCAL fileread
        LOCAL loadsdout

        push ix
        push hl
        ld e,(ix+6)                ; address
        ld d,(ix+7)
        ld c,(ix+8)                ; size
        ld b,(ix+9)
        ld l,(ix+10)
        ld h,(ix+11)            ; offset
        push bc                 ; store size
        push de                 ; srote address
        push hl                 ; offset 32bit 1111xxxx
        ld l,(ix+12)
        ld h,(ix+13)            ; offset xxxx1111
        push hl                 ; offset

    initdrive:
        xor a
        rst $08
        db $89                    ; M_GETSETDRV equ $89
        ld (filehandle),a

        ld ix,.LABEL._filename
        call fileopen
        ld a,(filehandle)
        or a
        ; bug in divmmc requries us to read a byte first
        ; at thie point stack = offset
        ; stack +2 = address
        ; stack +4 = length to load


divfix:
        ld bc,1
        ld ix,0
        rst $08                    ; read a byte
        db $9d                    ; read bytes

        ld a,(filehandle)

fileseek:

        ld l,0                    ; start
        ;ld bc,0                    ; highword
        pop bc
        pop de                    ; offset into de

        rst $08
        db $9f                    ; seek
        pop ix                     ; address to load from DE in stack
        pop bc                     ; length to load from BC in stack
        call fileread
        jp loadsdout

    fileread:

        ;push ix                    ; save ix
        ;pop hl                    ; pop into hl

        ;rst $08
        db 62                    ; read

    filehandle:
        db 0
        or a
        jp z,error
        rst $08
        db $9d                    ; read bytes
        ; bc read bytes
        ld (filesize),bc
        ret

        jp loadsdout
end asm
filesize:
asm
filesize:
        dw 0000

    error:
        ld b,5
    mloop:
        ld a,2
        out (254),a
        ld a,7
        out (254),a
        djnz mloop
        jp loadsdout

    fileopen:

        ld b,$01                ; mode 1 read
        ;db 33                        ; open
        ;ld    b,$0c
        push ix
        pop hl
    ;    ld a,42
        rst $08
        db $9a
        ld (filehandle),a
        ret

    loadsdout:

        ld a,(filehandle)
        or a
        rst $08
        db $9b                ; done, close file

        pop hl
        pop ix                 ; restore stack n stuff
        ENDP
    end asm
END SUB


' - SaveSD ------------------------------------------------
' Saves a portion of memory to a file on the SD memory card
' Parameters
'   filen (String): File name to load
'   address (UInteger): Memory address where file data will be save
'   length (UInteger): Size of data to be saved
SUB SaveSD(byval filen as String,ByVal address as uinteger,ByVal length as uinteger)
    '
    ' saves to SD filen=filename address=start address to save lenght=number of bytes to save
    '
    dim tlen as uinteger
    filen = filen + chr(0)
    tlen=len(filen)+1
    'dim cco as ubyte=0
    for nbx=0 to tlen
        'if code(filen(cco))>32
        poke @filename+nbx,code (filen(nbx))
        'cco=cco+1
        'endif
    next
    poke @filename+nbx+1,0

    asm
        PROC
        LOCAL initdrive
        LOCAL filehandle
        LOCAL error
        LOCAL fileopen
        LOCAL mloop
        push ix                        ; both needed for returning nicely
        push hl
        ld e,(ix+6)                    ; address in to de
        ld d,(ix+7)
        ld c,(ix+8)                    ; size in to bc
        ld b,(ix+9)
        ;ld l,(ix+10)                ; for offset but not used here
        ;ld h,(ix+11)                ; offset
        push bc                     ; store size
        push de                     ; srote address
    ;    push hl                     ; offset

    initdrive:
        xor a
        rst $08
        db $89                        ; M_GETSETDRV = $89
        ld (filehandle),a            ; store filehandle from a to filehandle buffer

        ld ix,.LABEL._filename     ; load ix with filename buffer address
        call fileopen                ; open
        ld a,(filehandle)             ; make sure a had filehandel again
        ;or a

        ; not needed here but may add back in to save on an offset ....
        ; bug in divmmc requries us to read a byte first
        ; at thie point stack = offset
        ; stack +2 = address
        ; stack +4 = length to SAVE

        ;divfix:
        ;    ld bc,1
        ;    ld ix,0
        ;    rst $08                    ; read a byte
        ;    db $9d                    ; read bytes

        ;ld a,(filehandle)

    ;fileseek:

        ;ld l,0                        ; start
        ;ld bc,0                    ; highword

        ;pop de                        ; offset into de

        ;rst $08
        ;db $9f                        ; seek
        pop ix                         ; address to Save from DE in stack
        pop bc                         ; length to SAVE from BC in stack
        call filewrite
        jp savesdout

    filewrite:

        db 62                        ; read

    filehandle:
        db 0
        or a
        jp z,error
        rst $08
        db $9e                        ; write bytes
        ret

        jp savesdout

    error:
        ld b,5
    mloop:
        ld a,2
        out (254),a
        ld a,7
        out (254),a
        djnz mloop
        jp savesdout

    fileopen:

        ld b,$e                    ; mode write
        ;db 33                        ; open
        ;ld    b,$0c
        push ix
        pop hl
    ;    ld a,42
        rst $08
        db $9a                        ; F_OPEN
        ld (filehandle),a
        ret

    savesdout:

        ld a,(filehandle)
        or a
        rst $08
        db $9b                    ; done, close file

        pop hl
        pop ix                     ; restore stack n stuff
    ENDP

    end asm
END SUB


' - LoadBMP ------------------------------------------------
' Loads and displays a .bmp image at Layer 2 (256x192)
' For proper display:
' - Fixed resolution of 256x192 pixels
' - Make a vertical mirror of the image
' - Use 256-colour indexed colour format
' - Use the standard Next palette or adjust it manually
'
' Parameters:
'   fname (String): File name to show
' ---------------------------------------------------------
SUB LoadBMP(byval fname as String)

        dim pos as ulong

        pos = 1024+54+16384*2

        asm
                ld a,1
                ld (loadbank),a
                DW $91ed,$2456
                DW $91ed,$2557
        keeploading:

        end asm
        '

        LoadSD(fname, $c000, $4000, pos)                 'dump its contents to the screen
        pos=pos-16384

        asm

                ld bc, $123b
                ld a,(loadbank)
                or %00000001
                out (c),a
                ld    bc,$4000        ;we need to copy it backwards
                ld    hl,$FFFF        ;start at $ffff
                ld c,64             ; 64 lines per third
                ld de,255            ; start top right
        ownlddr:
                ld b,0                ; b=256 loops
        innderlddr:

                ld a,(hl)
                ld (de),a             ; put a in (de)
                ;and %00000101        ; for border effect
                ;out ($fe),a

                dec hl                 ; dec hl and de
                dec de
                djnz innderlddr        ; has b=0 again?
                inc d                 ; else inc d 256*2
                inc d
                dec bc                ; dec bc b=0 if we're here
                ld a,b                ; a into b
                or c                ; or outer loop c with a
                jp nz,ownlddr        ; both a and c are not zero

                ld a, 0                ; enable write
                ld bc, $123b         ; set port for writing
                out (c), a

                ld a,(loadbank)
                add a,$40
                ld (loadbank),a
                cp $c1
                jp nz,keeploading

                jp endingn
        loadbank:
                db 0
        endingn:
                ld a,0
                ld (loadbank),a
                Dw $91ed,$0056
                Dw $91ed,$0157
        end asm
END SUB

#PRAGMA pop(case_insensitive)

#ENDIF
