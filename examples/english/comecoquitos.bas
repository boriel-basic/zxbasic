10 REM      COMECOQUITOS  (LITTLE-PACMAN) by Luis Amado & MICROHOBBY SEMANAL Magazine (Issue #18)
11 REM ---------------------------------------------------------------------------------------------------------------------------
12 REM Modified by Pedro Güida in 2020 to make Little Pac-man movements more fluid when compiled to machine code.
13 REM Comecoquitos was the first program I typed from in mid 80's from Microhobby magazine to my ZX Spectrum Plus
14 REM So this "improvements" are my way to pay homage to that great moment. Thanks Luis! Because it was due to this
15 REM program I got the kick off to become a videogames developer!
16 REM And thanks to Jose too, for tweaking it to compile with Boriel ZX Basic!
17 REM ---------------------------------------------------------------------------------------------------------------------------
18 DIM max, punt as UINTEGER: REM Needed to avoid overflow, since ZX BASIC will try byte
19 BORDER 1: PAPER 1: INK 7: CLS : PRINT AT 10,10; FLASH 1;"STOP THE TAPE": PAUSE 200
20 GO SUB 810
30 LET max=0
40 LET x2=18: LET x3=4: LET y3=18: LET y2=15: LET px=10: LET py=15: LET v$="\G": LET j$="\B": LET j2$=j$ : LET r = 0
50 FUNCTION p$(a): RETURN ("000"+ STR$ a)( LEN STR$ a TO ): END FUNCTION : REM Needed because DEF FN is not allowed
60 BORDER 4: PAPER 6: INK 2: CLS 
70 LET punt=0
80 DIM l$(19)
90 LET l$(1)="\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H\H"
100 LET l$(2)="\H\F\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\I\F\H"
110 LET l$(3)="\H\I\H\H\H\I\H\I\I\H\H\H\I\H\H\H\I\H\H\H\I\I\H\I\H\H\H\I\H\H"
120 LET l$(4)="\H\I\I\H\I\I\H\H\H\F\H\I\I\F\I\F\I\I\H\F\H\H\H\I\I\H\I\I\H\H"
130 LET l$(5)="\H\I\H\H\I\H\H\F\H\I\H\H\H\H\H\H\H\H\H\I\H\F\H\H\I\H\H\I\H\H"
140 LET l$(6)="\H\I\I\H\I\I\I\I\H\I\I\I\I\I\I\I\I\I\I\I\H\I\I\I\I\H\I\I\H\H"
150 LET l$(7)="\H\I\H\H\H\H\I\H\H\I\H\I\H\H\H\H\H\I\H\I\H\H\I\H\H\H\H\I\H\H"
160 LET l$(8)="\H\I\I\I\I\I\I\I\I\I\H\I\H\I\I\I\H\I\H\I\I\I\I\I\I\I\I\I\I\H"
170 LET l$(9)="\H\I\H\H\H\H\H\H\H\H\H\I\H\H\I\H\H\I\H\H\H\H\H\H\H\H\H\H\I\H"
180 LET l$(10)="\H\I\I\I\I\I\I\I\I\I\I\I\H\I\I\I\H\I\I\I\I\I\I\I\I\I\I\I\I\H"
190 LET l$(11)="\H\I\H\H\H\H\H\H\H\H\H\I\H\I\H\I\H\I\H\H\H\H\H\H\H\H\H\H\I\H"
200 LET l$(12)="\H\I\H\I\I\I\I\I\I\I\H\I\I\I\H\I\I\I\H\I\I\I\I\I\I\I\F\H\I\H"
210 LET l$(13)="\H\I\H\H\I\H\I\H\F\H\I\H\H\H\H\H\H\H\I\I\H\I\H\I\H\I\H\H\I\H"
220 LET l$(14)="\H\I\H\I\I\I\I\H\H\I\I\I\I\I\I\I\I\I\I\H\H\I\I\I\I\I\I\H\I\H"
230 LET l$(15)="\H\I\I\I\H\H\H\I\I\I\H\H\H\H\H\H\H\H\H\I\I\I\H\H\H\H\I\I\I\H"
240 LET l$(16)="\H\I\H\I\I\I\I\I\H\H\I\I\H\F\I\F\H\I\I\I\H\I\I\I\I\I\I\H\I\H"
250 LET l$(17)="\H\I\H\H\H\H\H\H\H\H\I\H\H\H\I\H\H\H\I\H\H\H\H\H\H\H\H\H\I\H"
260 LET l$(18)=l$(2)
270 LET l$(19)=l$(1)
280 PRINT : FOR f=1 TO 19: INK 1: PAPER 6: PRINT TAB 1;l$(f): NEXT f
290 FOR f=0 TO 21: PRINT INK 0; AT f,0;"\::"; AT f,31;"\::": NEXT f
300 PRINT AT 20,0; PAPER 0; INK 7; BRIGHT 1;"     C O M E C O Q U I T O S    "
310 PRINT AT 21,0; INK 2; PAPER 6;"SCORE:0000         HI-SCORE:0000"
320 PRINT AT 0,0; INK 5; PAPER 0;" LAR SOFTWARE  LALIN-PONTEVEDRA "
330 LET l$(px)(py)=" "
340 IF punt<1730 THEN GO TO 400
350 IF punt=1730 THEN PRINT AT 2,13; INK 4; PAPER 1; FLASH 1; BRIGHT 1;"WELL DONE!"; AT 8,14;"YOU'VE"; AT 10,6;""; AT 10,14;"WON"
360 PRINT AT 18,7; INK 7; PAPER 0; FLASH 1;"CONTINUE? (y/n)"
370 IF INKEY$="y" THEN GO TO 60
380 IF INKEY$="n" THEN GO TO 9999
390 IF INKEY$<>"y" OR INKEY$<>"n" THEN GO TO 370
400 LET j2$ = j$
410 IF INKEY$="" THEN GO TO 460
420 IF INKEY$="o" THEN LET j$="\C"
430 IF INKEY$="a" THEN LET j$="\D"
440 IF INKEY$="q" THEN LET j$="\A"
450 IF INKEY$="p" THEN LET j$="\B"
460 FOR t=0 TO 1750: NEXT t: PRINT AT px,py;" "
470 LET r = 0
480 IF j$="\A" AND l$(px-1)(py) <>"\H" THEN LET px=px-1 : GOTO 630
490 IF j$<>"\A" THEN GOTO 510
500 GOTO 590
510 IF j$="\B" AND l$(px)(py+1) <>"\H" THEN LET py=py+1 : GOTO 630
520 IF j$<>"\B" THEN GOTO 540
530 GOTO 590
540 IF j$="\D" AND l$(px+1)(py) <>"\H" THEN LET px=px+1 : GOTO 630
550 IF j$<>"\D" THEN GOTO 570
560 GOTO 590
570 IF j$="\C" AND l$(px)(py-1) <>"\H" THEN LET py=py-1 : GOTO 630
580 IF j$<>"\C" THEN GOTO 610
590 LET r = 1
600 IF J$=J2$ THEN GOTO 630 
610 LET j$ = j2$
620 IF r = 1 THEN GOTO 470
630 PRINT AT px,py; INK 3;v$
640 IF l$(px)(py)="\I" THEN LET punt=punt+5: BEEP .01,12
650 IF l$(px)(py)="\F" THEN LET punt=punt+30: BEEP .02,16
660 IF max<punt THEN LET max=punt
670 PRINT AT 21,6; p$(punt); AT 21,28; p$(max): BEEP .001,50
680 PRINT AT x2,y2;l$(x2)(y2): IF INT ( RND*2)+(x2>px) AND l$(x2-1)(y2) <>"\H" THEN LET x2=x2-1
690 IF INT ( RND*2)+(x2<px) AND l$(x2+1)(y2) <>"\H" THEN LET x2=x2+1
700 IF INT ( RND*2)+(y2>py) AND l$(x2)(y2-1) <>"\H" THEN LET y2=y2-1
710 IF INT ( RND*2)+(y2<py) AND l$(x2)(y2+1) <>"\H" THEN LET y2=y2+1
720 PRINT AT x2,y2; INK 2;"\E"
730 PRINT AT px,py; INK 3;j$
740 IF (x2=px AND y2=py) OR (x3=px AND y3=py) THEN FOR g=1 TO 10: FOR f=0 TO 7: PRINT INK f; AT px,py;j$: NEXT f: NEXT g: PRINT AT px,py; INK 6;j$: GO TO 960
750 PRINT AT x3,y3;l$(x3)(y3): IF INT ( RND*2)+(x3>px) AND l$(x3-1)(y3) <>"\H" THEN LET x3=x3-1
760 IF INT ( RND*2)+(x3<px) AND l$(x3+1)(y3) <>"\H" THEN LET x3=x3+1
770 IF INT ( RND*2)+(y3>py) AND l$(x3)(y3-1) <>"\H" THEN LET y3=y3-1
780 IF INT ( RND*2)+(y3<py) AND l$(x3)(y3+1) <>"\H" THEN LET y3=y3+1
790 PRINT AT x3,y3; INK 2;"\E"
800 GO TO 330
810 DATA 66,129,129,195,231,255,126,60
820 DATA 62,121,240,224,224,240,121,62
830 DATA 124,158,15,7,7,15,158,124
840 DATA 60,126,255,231,195,129,129,66
850 DATA 56,124,214,214,254,254,170,170
860 DATA 24,82,255,255,255,255,126,36
870 DATA 0,60,126,126,126,126,60,0
880 DATA 170,85,170,85,170,85,170,85
890 DATA 0,0,0,24,24,0,0,0
900 RESTORE 810
910 FOR i=1 TO 9: FOR n=0 TO 7
920 READ a
930 POKE USR CHR$(i+143)+n,a
940 NEXT n: NEXT i
950 RETURN
960 PRINT AT 2,11; INK 7; PAPER 1; FLASH 1;"GAME OVER"
970 PRINT AT 18,7; INK 7; PAPER 0; FLASH 1;"CONTINUE? (Y/N)"
980 IF INKEY$="y" THEN GO TO 40
990 IF INKEY$="n" THEN GO TO 9999
1000 IF INKEY$<>"n" OR INKEY$<>"y" THEN GO TO 980
9999 REM
