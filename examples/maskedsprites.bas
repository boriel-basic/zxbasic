' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyright (C) 2026 Conrado Badenas <conbamen@gmail.com>
'
' Example for
' Print Masked (AND+OR) Sprites, version 2026.04.05
' ----------------------------------------------------------------

' DEFINEs to control the library cb/maskedsprites.bas
 #define NumberofMaskedSprites 10 ' Try 50 here, with #define USE_MSFS
 #define         MaskedSprites_USE_STACK_TRANSFER
'#include       "maskedsprites.bas"
 #include    <cb/maskedsprites.bas>

' DEFINEs to control this example program
 #define NUMWAITS    -1
 #define BORDER_WAIT 0
 #define USE_MSFS
 #define INTS        di

#include <random.bas>

CONST NUMSPRITES as UByte = NumberofMaskedSprites

dim i as Byte
dim memoryPaging,numberofscrolls,loops,warnings,modulus as UByte
dim x0(0 to NUMSPRITES-1) as UByte
dim y0(0 to NUMSPRITES-1) as UByte
dim x1(0 to NUMSPRITES-1) as UByte
dim y1(0 to NUMSPRITES-1) as UByte
dim back(0 to NUMSPRITES-1) as UInteger
#ifdef USE_MSFS
    dim regs(0 to NUMSPRITES-1) as UInteger
    dim regHero0,regFoe00,regFoe20,regFoe21,regFoe22,regFoe23 as UInteger
#endif
dim temp as Integer
dim pointx1,pointx2,pointy1,pointy2 as Integer 'for subtractions

ASM
    INTS
END ASM

for i=0 to NUMSPRITES-1
    y0(i)=255:y1(i)=255:x1(i)=randomLimit(240)
next i:x1(0)=120

'DIM Rosquilla_Sprite(31) AS UByte => { _
'		$00,$07,$18,$20,$23,$44,$48,$48, _
'		$48,$48,$44,$23,$20,$18,$07,$00, _
'		$00,$E0,$18,$04,$C4,$22,$12,$12, _
'		$12,$12,$22,$C4,$04,$18,$E0,$00 _
'	}
DIM Rosquilla0(31) AS UByte => { _
		$00,$07,$19,$21,$23,$44,$48,$48, _
		$48,$58,$7C,$3B,$20,$18,$07,$00, _
		$00,$E0,$98,$84,$C4,$22,$12,$12, _
		$12,$1A,$3E,$DC,$04,$18,$E0,$00 _
	}
DIM Rosquilla1(31) AS UByte => { _
		$00,$07,$1C,$2E,$2F,$44,$48,$48, _
		$48,$48,$44,$2F,$2E,$1C,$07,$00, _
		$00,$E0,$18,$04,$C4,$22,$12,$1E, _
		$1E,$12,$22,$C4,$04,$18,$E0,$00 _
	}
DIM Rosquilla2(31) AS UByte => { _
		$00,$07,$18,$20,$3B,$7C,$58,$48, _
		$48,$48,$44,$23,$21,$19,$07,$00, _
		$00,$E0,$18,$04,$DC,$3E,$1A,$12, _
		$12,$12,$22,$C4,$84,$98,$E0,$00 _
	}
DIM Rosquilla3(31) AS UByte => { _
		$00,$07,$18,$20,$23,$44,$48,$78, _
		$78,$48,$44,$23,$20,$18,$07,$00, _
		$00,$E0,$38,$74,$F4,$22,$12,$12, _
		$12,$12,$22,$F4,$74,$38,$E0,$00 _
	}
memoryPaging = CheckMemoryPaging()
if memoryPaging then SetVisibleScreen(5) '128K
paper 1:ink 7:border 0:cls

for i=0 to 126
    pointx1=randomLimit(255):pointy1=randomLimit(191)
    pointx2=randomLimit(255):pointy2=randomLimit(191)
    plot pointx1,pointy1:draw pointx2-pointx1,pointy2-pointy1
next i

#ifdef USE_MSFS
    print "Init MSFS at ";InitMaskedSpritesFileSystem()
    print "Free Blocks in MSFS = ";GetNumberofFreeBlocksInMSFS()
    regHero0 = RegisterSpriteImageInMSFS(@hero0):if regHero0=0 then STOP
    print "regHero0 = ";regHero0
    regFoe00 = RegisterSpriteImageInMSFS(@foe00):if regFoe00=0 then STOP
    print "regFoe00 = ";regFoe00
    regFoe20 = RegisterSpriteGraphAndMaskInMSFS(@Rosquilla0(0),@Rosquilla_Sprite_Mask):if regFoe20=0 then STOP
    print "regFoe20 = ";regFoe20
    regFoe21 = RegisterSpriteGraphAndMaskInMSFS(@Rosquilla1(0),@Rosquilla_Sprite_Mask):if regFoe21=0 then STOP
    print "regFoe21 = ";regFoe21
    regFoe22 = RegisterSpriteGraphAndMaskInMSFS(@Rosquilla2(0),@Rosquilla_Sprite_Mask):if regFoe22=0 then STOP
    print "regFoe22 = ";regFoe22
    regFoe23 = RegisterSpriteGraphAndMaskInMSFS(@Rosquilla3(0),@Rosquilla_Sprite_Mask):if regFoe23=0 then STOP
    print "regFoe23 = ";regFoe23

    for i=0 to NUMSPRITES-1: modulus = i mod 2
        if i=0 then
            regs(0)=regHero0
        elseif modulus=1 then
            regs(i)=regFoe00
        else ' modulus=0 with i>0
            regs(i)=regFoe20
        end if
    next i
'    pause 0
#endif

for i=0 to NUMSPRITES-1
    back(i)=MaskedSpritesBackground(i)
'    print back(i)
next i
'    print:pause 0

if memoryPaging then '128K
    dim back0(0 to NUMSPRITES-1) as UInteger
    ChangeMaskedSpritesBackgroundSet
    for i=0 to NUMSPRITES-1
        back0(i)=MaskedSpritesBackground(i)
'        print back0(i)
    next i
    ChangeMaskedSpritesBackgroundSet
'    print:print MaskedSpritesFileSystemStart:pause 0

    CopyScreen5ToScreen7()
'    print at 11,8;"This is Screen5"
    SetDrawingScreen7() 'Bank7 is set at $c000
'    print at 13,8;"This is Screen7"
    SetDrawingScreen5() 'Bank7 is still set at $c000
'    print at 15,8;"This is Screen5"
end if

' We start with VisibleScreen = DrawingScreen = 5
numberofscrolls=0
warnings=0
loops=0
WaitForNewFrame(0)
do

    ' 128K
    if memoryPaging then
        ' The brand-new VisibleScreen is ready for the ULA to show it on TV
        ' But we wait to the beginning of a frame to avoid tearing
        ' (unless wanted time-to-wait has already been spent)
        out 254,BORDER_WAIT:WaitForNewFrame(NUMWAITS):out 254,0
'GetInterruptStatusInBorder()
        ToggleVisibleScreen()
        ' Now we can modify DrawingScreen because it is not Visible

        ' We restore background in x0,y0 if it is saved in MaskedSpritesBackground
        if MaskedSpritesBackgroundSet then
            for i=NUMSPRITES-1 to 0 step -1
                if y0(i)<>255 then RestoreBackground(x0(i),y0(i),back0(i))
            next i
        else
            for i=NUMSPRITES-1 to 0 step -1
                if y0(i)<>255 then RestoreBackground(x0(i),y0(i),back(i))
            next i
        end if
    end if

    ' After restoring background in a Spectrum 128K, you can use CPU to do something else:
    '
    ' 0. Change/scroll background (ONLY NOW!!!)
    ' 1. Check collisions
    ' 2. Resolve collisions
    ' 3. Change images of sprites for:
    '     a. Animation of regular motion
    '     b. Explosions and other extraordinary events
    ' 4. Upgrade the score
    ' 5. Play sound/music
    ' ...
    '
    ' You have plenty of time to do whatever you want in a Spectrum 128K

    ' 0. Change/scroll background (ONLY NOW!!!)
    if memoryPaging=1 then '128K
        if (in($7ffe) bAND 1)=0 then
            if numberofscrolls=1 then
                Scroll2()
            else
                Scroll1()
                numberofscrolls=1
            end if
        else
            if numberofscrolls=1 then
                Scroll1()
            end if
            numberofscrolls=0
        end if
    end if

#ifdef USE_MSFS
    ' 3. Change images of sprites for: a. Animation of regular motion
    for i=2 to NUMSPRITES-1 step 2: modulus = (i+loops) mod 4
        if modulus=0 then
            regs(i)=regFoe20
        elseif modulus=1 then
            regs(i)=regFoe21
        elseif modulus=2 then
            regs(i)=regFoe22
        else
            regs(i)=regFoe23
        end if
    next i
#endif

    ' We update x0,y0 and compute new x1,y1
    for i=1 to NUMSPRITES-1
        temp=x1(i): x0(i)=temp
            temp=temp-1
            if temp<0 then temp=240
        x1(i)=temp
        temp=y1(i): y0(i)=temp
            if temp=255 then temp=randomLimit(176)
            if randomLimit(3)=0 then temp=temp+randomLimit(2)-1
            if temp<0   then temp=0
            if temp>176 then temp=176
        y1(i)=temp
    next i

    'Special code for the hero
    temp=x1(0): x0(0)=temp
        temp=temp+1 -2*(in($dffe) bAND 1) +2*((in($dffe)>>1) bAND 1) '-noP+noO
        if temp<0   then temp=240
        if temp>240 then temp=0
    x1(0)=temp
    temp=y1(0): y0(0)=temp
        if temp=255 then temp=randomLimit(176)
        temp=temp -(in($fdfe) bAND 1) +(in($fbfe) bAND 1) '-noA+noQ
        if temp<0   then temp=0
        if temp>176 then temp=176
    y1(0)=temp

    ' 48K We restore background in x0,y0 if it is saved in MaskedSpritesBackground
    if not memoryPaging then
        for i=NUMSPRITES-1 to 0 step -1
            if y0(i)<>255 then RestoreBackground(x0(i),y0(i),back(i))
        next i
    end if

#ifdef USE_MSFS
    ' Print WARNING (if not scrolling) twice if MSFS has run out of free blocks
    if not numberofscrolls and warnings<2 and not GetNumberofFreeBlocksInMSFS() then
        print at 23,0;"WARNING! MSFS has NO free blocks";
        warnings=warnings+1
    end if
#endif

    ' After restoring background in a Spectrum 48K, you should do NOTHING
    ' ...
    ' You have ABSOLUTELY NO TIME to do anything in a Spectrum 48K

    ' We save background in MaskedSpritesBackground and draw sprites in x,y...
#ifdef USE_MSFS
    ' ...using SaveBackgroundAndDrawSpriteRegisteredInMSFS(,,,)
    if MaskedSpritesBackgroundSet then
        for i=0 to NUMSPRITES-1
            SaveBackgroundAndDrawSpriteRegisteredInMSFS(x1(i),y1(i),back0(i),regs(i))
        next i
    else
        for i=0 to NUMSPRITES-1
            SaveBackgroundAndDrawSpriteRegisteredInMSFS(x1(i),y1(i),back(i),regs(i))
        next i
    end if
#else
    ' ...using SaveBackgroundAndDrawSprite(,,,)
    if MaskedSpritesBackgroundSet then
        SaveBackgroundAndDrawSprite(x1(0),y1(0),back0(0),@hero0)
        for i=1 to NUMSPRITES-1
            SaveBackgroundAndDrawSprite(x1(i),y1(i),back0(i),@foe00)
        next i
    else
        SaveBackgroundAndDrawSprite(x1(0),y1(0),back(0),@hero0)
        for i=1 to NUMSPRITES-1
            SaveBackgroundAndDrawSprite(x1(i),y1(i),back(i),@foe00)
        next i
    end if
#endif

    ' After drawing sprites, you can use CPU to do something else:
    '
    ' 1. Check collisions
    ' 2. Resolve collisions
    ' 3. Change images of sprites for:
    '     a. Animation of regular motion
    '     b. Explosions and other extraordinary events
    ' 4. Upgrade the score
    ' 5. Play sound/music
    ' ...
    '
    ' You have plenty of time to do whatever you want in ANY Spectrum

    ' We change the Set of Backgrounds (128K) for next iteration
    if memoryPaging then ChangeMaskedSpritesBackgroundSet()

    ' We have finished drawing
    if memoryPaging then
        ' We change DrawingScreen (128K) for next iteration
        ToggleDrawingScreen()
    else
        ' ULA shows DrawingScreen (48K) on TV for some frames before going on
        out 254,BORDER_WAIT:WaitForNewFrame(NUMWAITS):out 254,0
    end if
'GetInterruptStatusInBorder()
    ' Now, VisibleScreen = DrawingScreen, and
    ' we could see anything we draw whilst it is drawn
    loops=loops+1
loop

' SUB/FUNCTIONs that are not used, are "used" here to check compilation is OK
      SetBankPreservingINTs(0)
print GetBankPreservingRegs()
print CheckMemoryPaging()
      SetVisibleScreen(0)
print GetVisibleScreen()
      ToggleVisibleScreen()
      CopyScreen5ToScreen7()
      CopyScreen7ToScreen5()
      SetDrawingScreen5()
print SetDrawingScreen7()
      ToggleDrawingScreen()
print ChangeMaskedSpritesBackgroundSet()
      SaveBackgroundAndDrawSprite(0,0,0,0)
      RestoreBackground(0,0,0)
print InitMaskedSpritesFileSystem()
print GetNumberofFreeBlocksInMSFS()
print RegisterSpriteImageInMSFS(0)
print RegisterSpriteGraphAndMaskInMSFS(0,0)
      SaveBackgroundAndDrawSpriteRegisteredInMSFS(0,0,0,0)
GetInterruptStatusInBorder()
Scroll()
Scroll1()
Scroll2()
' Delete/Comment all these "uses" when used, or compilation checking is not needed

hero0:
ASM
    defb %11000000,%00000000,%00001111,%00000000;1
    defb %10000000,%00011111,%00000000,%11100000;2
    defb %00000000,%00100000,%00000000,%00111110;3
    defb %00000000,%01001110,%00000000,%11111000;4
    defb %00000000,%01011001,%00000001,%00001100;5
    defb %00000000,%01011010,%00000000,%00010100;6
    defb %00000000,%00000011,%00000000,%11100010;7
    defb %00000000,%01111100,%00000000,%00100010;8
    defb %00000000,%01111100,%00000000,%00100010;8
    defb %00000000,%00000011,%00000000,%11100010;7
    defb %00000000,%01011010,%00000000,%00010100;6
    defb %00000000,%01011001,%00000001,%00001100;5
    defb %00000000,%01001110,%00000000,%11111000;4
    defb %00000000,%00100000,%00000000,%00111110;3
    defb %10000000,%00011111,%00000000,%11100000;2
    defb %11000000,%00000000,%00001111,%00000000;1
END ASM

foe00:
ASM
    defb %00000011,%00000000,%11000000,%00000000;1
    defb %00000011,%01111000,%11000000,%00011110;2
    defb %00000011,%01000000,%11000000,%00010000;3
    defb %00000001,%01010000,%10000000,%00010100;4
    defb %00000000,%01001000,%00000000,%00100010;5
    defb %00000000,%00000010,%00000000,%01110000;6
    defb %11100000,%00000111,%00000111,%11100000;7
    defb %11110000,%00000010,%00001111,%01000000;8
    defb %11110000,%00000010,%00001111,%01000000;8
    defb %11100000,%00000111,%00000111,%11100000;7
    defb %00000000,%00001110,%00000000,%01000000;6'
    defb %00000000,%01110100,%00000000,%00011110;5'
    defb %00000001,%01000000,%10000000,%00010000;4'
    defb %00000011,%01010000,%11000000,%00010100;3'
    defb %00000011,%01001000,%11000000,%00010010;2'
    defb %00000011,%00000000,%11000000,%00000000;1
END ASM

Rosquilla_Sprite_Mask:
ASM
	db	$FF,$F8,$E0,$C0,$C0,$83,$87,$87
	db	$87,$87,$83,$C0,$C0,$E0,$F8,$FF
	db	$FF,$1F,$07,$03,$03,$C1,$E1,$E1
	db	$E1,$E1,$C1,$03,$03,$07,$1F,$FF
END ASM


' ----------------------------------------------------------------
' READ_IFF2 is a MACRO that reads correctly the IFF2 flip-flop,
' avoiding a "bug" reported in the Z80 User Manual,
' which Pedro Picapiedra aka ProgramadorHedonista kindly pointed
' me to: "If an interrupt occurs during execution of this
' instruction [LD A,I or LD A,R], the Parity flag contains a 0."
' ----------------------------------------------------------------
#define READ_IFF2                                               \
    ld a,i      ; IFF2=0/1=DI/EI is saved in PF=0/1=Odd/Even    \
    jp pe,1f    ; if PF=Even=1,  it is sure that IFF2=1=EI      \
    ld a,i      ; read IFF2 again to ensure that IFF2=0=DI      \
1:


' ----------------------------------------------------------------
' Wait for New Frame
' This SUB uses a hack to ensure a good reading of the IFF2 flip-flop.
' Hack was found thanks to Pedro Picapiedra aka ProgramadorHedonista.
' Parameters:
'     Byte: if =0, you want just one HALT
'           if >0, minimum number of frames spent since last wait
'           if <0, return without waiting
' ----------------------------------------------------------------
SUB FASTCALL WaitForNewFrame(minimumNumberofFramesToWaitSinceLastWait AS Byte)
ASM
    PROC
    LOCAL wait,temp
    and a
    ret m       ; return if minimumNumberofFramesToWaitSinceLastWait < 0
    ld hl,temp
    ld de,23672
    ld c,a      ; A = C = minimumNumberofFramesToWaitSinceLastWait
    READ_IFF2
    ex af,af'    
    ei          ; interrupts MUST be enabled before HALT
    halt
wait:
    ld a,(de)
    sub (hl)    ; A = number of frames since last RET
    cp c        ; is A >= C? Yes: NoCarry. No: Carry
    jr c,wait   ; repeat if A < minimumNumberofFramesToWaitSinceLastWait
    ld a,(de)
    ld (hl),a
    ex af,af'
    ret pe      ; Return with EI if IFF2=1=EI at the beginning
    di          ; Return with DI if IFF2=0=DI at the beginning
    RET
temp:
    defb 0
    ENDP
END ASM
END SUB


' ----------------------------------------------------------------
' Get Interrupt Status in Border
' This SUB uses a hack to ensure a good reading of the IFF2 flip-flop.
' Hack was found thanks to Pedro Picapiedra aka ProgramadorHedonista.
' Border results: 2 Red   if Interrupts are Disabled IFF2=0
'                 4 Green if Interrupts are  Enabled IFF2=1
' ----------------------------------------------------------------
SUB FASTCALL GetInterruptStatusInBorder()
ASM
    READ_IFF2
    push af
    pop bc
    ld a,c
    and 4       ; A=0/4 iff IFF2=0/1
    rra         ; A=0/2 iff IFF2=0/1
    add a,2     ; A=2/4 iff IFF2=0/1
    out (254),a
END ASM
END SUB


SUB FASTCALL Scroll()
ASM
    PROC
    LOCAL loop
    ld hl,(.core.SCREEN_ADDR)
    ld de,31
    ld b,192
loop:
; Here, HL = screen address for first column
        add hl,de; column 32
        xor a
        rl (hl) ; 32
        dec l
        rl (hl) ; 31
        dec l
        rl (hl) ; 30
        dec l
        rl (hl) ; 29
        dec l
        rl (hl) ; 28
        dec l
        rl (hl) ; 27
        dec l
        rl (hl) ; 26
        dec l
        rl (hl) ; 25
        dec l
        rl (hl) ; 24
        dec l
        rl (hl) ; 23
        dec l
        rl (hl) ; 22
        dec l
        rl (hl) ; 21
        dec l
        rl (hl) ; 20
        dec l
        rl (hl) ; 19
        dec l
        rl (hl) ; 18
        dec l
        rl (hl) ; 17
        dec l
        rl (hl) ; 16
        dec l
        rl (hl) ; 15
        dec l
        rl (hl) ; 14
        dec l
        rl (hl) ; 13
        dec l
        rl (hl) ; 12
        dec l
        rl (hl) ; 11
        dec l
        rl (hl) ; 10
        dec l
        rl (hl) ; 09
        dec l
        rl (hl) ; 08
        dec l
        rl (hl) ; 07
        dec l
        rl (hl) ; 06
        dec l
        rl (hl) ; 05
        dec l
        rl (hl) ; 04
        dec l
        rl (hl) ; 03
        dec l
        rl (hl) ; 02
        dec l
        rl (hl) ; 01
        rla     ; save CF in A
        add hl,de; column 32
        or (hl)
        ld (hl),a
        inc hl  ; first column
        djnz loop
    ENDP
END ASM
END SUB


' ----------------------------------------------------------------
' NEXT_ROW is a MACRO of ASM code, based on code from
' https://zonadepruebas.com/viewtopic.php?f=15&t=8372&start=40#p81507
' and found by Joaquin Ferrero
' ----------------------------------------------------------------
#define NEXT_ROW                                                        \
    sub 224 ; 7   A was L, now A = L + 32 (SUB 224 is similar to +32)   \
            ;     CF = 0/1 iff E >=/< 224 iff a third is/isn't crossed  \
    ld l,a  ; 4                                                         \
    sbc a,a ; 4   A = 0/255                                             \
    and 248 ; 7   A = 0/248 (248 = -8)                                  \
    add a,h ; 4   A = H/H-8 iff a third is/isn't crossed                \
    ld h,a  ; 4 += 30 Ts


' ----------------------------------------------------------------
' Scroll 1 pixel up
' ----------------------------------------------------------------
SUB FASTCALL Scroll1()
ASM
    PROC
    LOCAL loop1,loop2,exit
    push ix
    xor a
    ld hl,(.core.SCREEN_ADDR); HL = $4000 or $c000
    ld de,buffer0
    call ldi32      ; scanline0
                    ; DEC HL is not needed because row = 0 <> 7, 15, 23
    ld ixh,24       ; 24 rows (rows 0-23)
loop1:
      ld l,a        ; A = low byte of screen addresses for this row
; HL = scanline0 for this row
      ld d,h
      ld e,l        ; DE = scanline0 of this row
      inc h         ; HL = scanline1 of this row
      ld ixl,7      ; first 7 scanlines of one row
loop2:
; HL,DE = origin,destination screen address
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi         ; BC-=32 DE+=32 HL+=32 (if E,L was 224, then D,H changes)
        dec hl      ;  6    in case H changes (because L was 224: rows 7,15,23)
        ld l,a      ; +4 = 10 Ts < 21 Ts (PUSH+POP)
        ld d,h
        ld e,l      ; scanline_N+0 of this row
        inc h       ; scanline_N+1 of this row
        dec ixl
        jp nz,loop2
      dec ixh
      jr z,exit     ; this JR Z here (instead of an JP NZ later) adds +7 Ts/row = 161 Ts for 23 rows
; last scanline of first 23 rows: DE is OK, HL must change
      NEXT_ROW
      ld a,l
      call ldi32    ; 539 Ts needed for each row except last row
      dec hl        ; with JR Z,EXIT before, we save 539-161 = 378 Ts for last row
      jp loop1
exit:
    ld hl,buffer0
    call ldi32      ; DE = scanline7 of last row
    pop ix
    ENDP
END ASM
END SUB


' ----------------------------------------------------------------
' Scroll 2 pixels up
' ----------------------------------------------------------------
SUB FASTCALL Scroll2()
ASM
    PROC
    LOCAL loop1,loop2,exit
    push ix
    xor a
    ld hl,(.core.SCREEN_ADDR); HL = $4000 or $c000
    ld de,buffer0
    call ldi32      ; scanline0
                    ; DEC HL is not needed because row = 0 <> 7, 15, 23
    ld l,a
    inc h
    call ldi32      ; scanline1
                    ; DEC HL is not needed because row = 0 <> 7, 15, 23
    ld ixh,24       ; 24 rows (rows 0-23)
loop1:
      ld l,a        ; A = low byte of screen addresses for this row
; HL = scanline1 for this row
      ld d,h
      ld e,l
      dec d         ; DE = scanline0 of this row
      inc h         ; HL = scanline2 of this row
      ld ixl,6      ; first 6 scanlines of one row
loop2:
; HL,DE = origin,destination screen address
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi         ; BC-=32 DE+=32 HL+=32 (if E,L was 224, then D,H changes)
        dec hl      ;  6    in case H changes (because L was 224: rows 7,15,23)
        ld l,a      ; +4 = 10 Ts < 21 Ts (PUSH+POP)
        ld d,h
        ld e,l
        dec d       ; DE = scanline_N+0 of this row
        inc h       ; HL = scanline_N+2 of this row
        dec ixl
        jp nz,loop2
      dec ixh
      jr z,exit     ; this JR Z here (instead of an JP NZ later) adds +7 Ts/row = 161 Ts for 23 rows
; last scanline of first 23 rows: DE is OK, HL must change
      NEXT_ROW
      ld c,h        ; C=H is larger than 32, so B does not change when BC-=32
      ld b,e        ; DE = scanline6 of this row  SAVED in B
      ld a,l        ; HL = scanline0' of next row SAVED in A
      call ldi32    ; 539 Ts needed for each row except last row
      dec hl
      ld l,a
      dec de        ; LD C,H + LD B,E + LD A,L + DEC HL + LD L,A + DEC DE + LD E,B
      ld e,b        ; = 4+4+4+6+4+6+4 = 32 Ts < 42 Ts 2*(PUSH+POP)
      inc d         ; DE = scanline7 of this row
      inc h         ; HL = scanline1' of next row
      call ldi32    ; 539 Ts needed for each row except last row
      dec hl        ; with JR Z,EXIT before, we save 2*539-161 = 917 Ts for last row
      jp loop1
exit:
    ld hl,buffer0
    call ldi32      ; DE = scanline6 of last row
    dec de
    ld e,a
    inc d           ; DE = scanline7 of last row
    call ldi32
    pop ix
    ret
    ENDP

buffer0:
    defs 32

buffer1:
    defs 32

ldi32:
    ldi ; 32 LDI = 32*16 = 512 Ts
    ldi ; CALL + RET = 17+10 = 27 Ts
    ldi ; call ldi32 (+ret) = 512+27 = 539 Ts
    ldi
    ldi ; LD BC,32 + LDIR = 10 + 21*31+16 = 677 Ts
    ldi
    ldi ; 677 - 539 = 138 Ts
    ldi
    ldi ; then, "call ldi32 (+ret)" is 138 Ts faster than "ld bc,32 + ldir"
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi ; BC-=32 DE+=32 HL+=32 (if E,L was >=224, then D,H changes)
END ASM
END SUB

