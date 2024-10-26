# MSX

## References
* http://map.grauw.nl/resources/msxbios.php
* http://map.grauw.nl/resources/subrom.php
* http://map.grauw.nl/resources/msxsystemvars.php
* http://www.konamiman.com/msx/msx2th/th-ap.txt
* http://www.angelfire.com/art2/unicorndreams/msx/RR-RAM.html
* http://www.konamiman.com/msx/msx2th/kunbasic.txt
* http://www.konamiman.com/msx/msx-e.html#nestorbasic
* http://www.faq.msxnet.org/gfx9000.html
* http://www.teambomba.net/gfx9klib.html
* http://msxbanzai.tni.nl/v9990/manual.html
* http://www.faq.msxnet.org/suffix.html
* http://www.gamecastentertainment.com/forum/viewtopic.php?f=3&t=18#p53 (z80 asm code for accessing screen modes)

## Library

for now, this is merelly about a small sketch of the msx1/2 (also 2+) msx-basic command used, and their z80 assembly similars - they are not accuraced and may need fixes and improvements.

* cls   - cls
```
    call 0x00c3     #-cls


```* color

```
  sub msxcolor(v_ink as ubyte, v_paper as ubyte, v_border as ubyte):
  poke $F3E9,v_ink
  poke $F3EA,v_paper
  poke $F3EB,v_border
  end sub


```* vpoke

```
  sub msx1vpoke(v_address as uinteger,v_value as uinteger)
  asm
  ld h,(ix+5)
  ld l,(ix+4)
  ld a,(ix+6)
  call $004D
  end asm
  end sub

  sub msx2vpoke(v_address as uinteger,v_value as uinteger)
  asm
  ld h,(ix+5)
  ld l,(ix+4)
  ld a,(ix+6)
  call $0177
  end asm
  end sub


```* vpeek -    v_value= vpeek (v_address)
```
    ld hl,v_address
    call 0x004A    #-rdvrm
    ld v_value,a


```* screen -   screen v_screenmode,v_spritemode,v_click,v_printflag,v_?,v_?,v_?,v_?,v_?,v_?
```
    ld a,v_screenmode;call 0x005F     #- chgmod
    #- ld bc,0xE201:call WRTVDP - v_spritemode - ????
    ld (0xF3DB),v_click    #- cliksw
    ld (0xF416),v_prtflg    #- printflag


```* width -    width v_width
```
    if (v_screenmode=0) then:
         ld (0xF3AE),v_width
         ld (0xF3B0),v_width
         end if
    if (v_screenmode=1) then:
         ld (0xF3AF),v_width
         ld (0xF3B0),v_width
         end if


```* sprite$ -    sprite$(v_spriteindex)=s_spritebitpmap$
```
    ld hl,(s_spritebitpmap$)
    ld de,0x3800+(v_spriteindex*32)
    ld bc,32
    call 0x005c   #- ldirvm


```* putsprite -    putsprite(v_id,v_x,v_y,v_layer,v_colour) - i don't know how to put sprites in screens 5 to 12
```
    vpoke (0x1B00+(v_id*4)+0 ),v_y
    vpoke (0x1B00+(v_id*4)+1 ),v_x
    vpoke (0x1B00+(v_id*4)+2 ),v_layer
    vpoke (0x1B00+(v_id*4)+3 ),v_colour


```* cls (msx2)   - cls
```
    ld ix,0x0115    #- cls (subrom)
    call 0x015C     #- subrom


```* setpage (msx2) -    setpage v_dpage,v_apage (?)
```
    ld [0xFAF5],v_dpage    #- dppage
    ld [0xFAF6],v_apage    #- acpage
    ld ix,0x013D    #- setpag (subrom)
    call 0x015C     #- subrom


```* palette (gfx9000)
```
  sub msxgfx9kpalette(tidx as ubyte,tpr as ubyte,tpg as ubyte,tpb as ubyte):
  '- this code seems not acuraced yet
  out $64,14
  out $63,(tidx mod 64)*4
  out $61,tpr
  out $61,tpg
  out $61,tpb
  end sub


```* screen (gfx9000)
```
  sub msxgfx9kscreen(tscm6 as ubyte,tscm7 as ubyte):
  '- this code seems not acuraced yet
  out $64,6
  out $63,tscm6
  out $64,7
  out $63,tscm7
  out $67,1
  end sub


```* vpoke (gfx9000)
```
  sub msxgfx9kvpoke(tadr as udouble, tvl as ubyte):
  '- this code seems not acuraced yet
  out $64,0
  tvou=tadr band 255:tvou=int(tvou/256)
  out $63,tvou
  tvou=tadr band 255:tvou=int(tvou/256)
  out $63,tvou
  tvou=tadr band 255:tvou=int(tvou/256)
  out $63,tvou
  out $60,tvl
  end sub
