   0 REM From MicroHOBBY magazine, Num. 18, page 27  :')
   1 BORDER 1: PAPER 1: INK 7: CLS : PRINT AT 10,10; FLASH 1;"STOP THE TAPE": PAUSE 200
   5 DIM M(8,6): DIM p,pp,n as FLOAT
   6 BORDER 1: PAPER 1: INK 6: CLS
  10 LET x=0: LET y=0: LET j=0
  20 PRINT INK 4;" \ : \:    \:'\'' \:'\'.\ :   \:'\': \:'\': \:.\.: \:'\':       \''\:    \:'  \:  \'.   \: \.: \:.\.:  \:  \:.\.:        \:    \:.\.. \:  \ :   \: \'. \: \ :  \:  \: \ :"; INK 6;AT 21,5;" \*  by \{vi}$R\{vn}         R.Bernat."
  25 PRINT AT 15,3;"Who starts, You or Me? (y/m).": GOSUB 2800: PRINT AT 15,3;"                             ": GO SUB 2500
  30 FOR i=1 TO 8: FOR m=1 TO 6
  40 LET M(i,m)=0: NEXT m: NEXT i
 100 PLOT 0,16: DRAW 12,16: DRAW 0,100: DRAW 8,0: DRAW 0,-92
 110 FOR n=1 TO 8: DRAW 8,0,PI: DRAW 0,92: DRAW 8,0: DRAW 0,-92: NEXT n: DRAW 0,-8: DRAW 12,-16: DRAW -25,0: DRAW 0,9: DRAW -110,0: DRAW 0,-9: DRAW -25,0
 120 PRINT AT 5,1;"\{vi} 1 2 3 4 5 6 7 8 \{vn}"
 450 IF a$="m" THEN GO TO 700: END IF
 480 LET M(5,1)=1: LET xp=5: LET yp=1: LET color=1: GO SUB 3000
 490 GO TO 700
 500 PRINT AT 12,20; INK 4; FLASH 1;"THINKING ": LET pp=0
 510 LET p=0
 520 FOR i=1 TO 8
 530 LET x=i: GO SUB 2000
 540 IF y>6 THEN CONTINUE FOR: END IF: REM NEXT i
 550 LET color=1: GO SUB 1030: PRINT FLASH 1;AT 5,i+20;i
 560 IF psp>p AND psp<30 THEN GO SUB 1600: END IF
 570 IF psp>p THEN LET p=psp: LET xp=x: LET yp=y: END IF
 575 IF psp=.05 THEN CONTINUE FOR: END IF: REM NEXT i
 580 LET color=2: GO SUB 1030: IF psp>=30 THEN LET psp=29.9: GOTO 590: END IF
 585 LET pp=psp:GOSUB 1600:IF psp>=30 THEN LET pp=.05:END IF: LET psp=pp
 590 IF psp>p THEN LET p=psp: LET xp=x: LET yp=y: END IF
 600 NEXT i: PRINT INK 1; FLASH 0;AT 5,20;"             "
 610 LET color=1: LET M(xp,yp)=1
 620 GO SUB 2500: GO SUB 3000: LET j=j+1
 630 IF p>=30 THEN GO TO 3500: END IF
 640 IF j=48 THEN PRINT AT 12,20;"-Draw-": GO TO 3600: END IF
 700 REM ********************************  YOU PLAY  *******************************************
 701 PRINT INK 4;AT 12,20;"YOUR MOVE"
 710 GOSUB 2700: LET x=VAL a$
 720 IF x<1 OR x>8 THEN GO TO 710: END IF
 725 LET color=2: GO SUB 2000: IF y>6 THEN PRINT AT 12,20;"Not valid": GO TO 710: END IF
 730 LET yp=y: LET xp=x: LET color=2: GO SUB 3000
 740 LET M(xp,yp)=2: LET j=j+1
 750 REM check if you win
 760 GO SUB 1030
 770 IF psp>=30 THEN GO TO 3550: END IF
 780 IF j=48 THEN PRINT OVER 1;AT 21,0;"              ...end": GO TO 3600: END IF
 790 GO TO 500
1030 LET psp=0: LET np=0
1040 LET dx=1: LET dy=0: GO SUB 1500
1050 LET psp=ps
1060 LET dx=-1: LET dy=0: GO SUB 1500
1070 LET psp=psp+ps
1080 LET dx=0: LET dy=-1: GO SUB 1500
1090 IF ps>psp THEN LET psp=ps: END IF
1100 LET dx=1: LET dy=-1: GO SUB 1500
1200 LET np=ps
1210 LET dx=-1: LET dy=1: GO SUB 1500
1220 LET np=np+ps
1230 IF np>psp THEN LET psp=np: END IF
1240 LET dx=1: LET dy=1: GO SUB 1500
1250 LET np=ps
1260 LET dx=-1: LET dy=-1: GO SUB 1500
1270 LET np=np+ps
1280 IF np>psp THEN LET psp=np: END IF
1290 RETURN
1500 LET ps=0: LET xx=x: LET yy=y: LET b=0
1510 LET xx=xx+dx: LET yy=yy+dy
1520 IF (xx<1) OR (yy<1) OR (xx>8) OR (yy>6) THEN RETURN: END IF
1530 IF M(xx,yy)<>color AND M(xx,yy)<>0 THEN RETURN: END IF
1540 IF M(xx,yy)=color AND b=0 THEN LET ps=ps+10: GO TO 1510: END IF
1550 LET ps=ps+1: LET b=1: GO TO 1510
1599 REM ******************************************************
1600 LET M(x,y)=1: LET color=2: LET y=y+1
1610 GO SUB 1030
1620 IF psp>=30 THEN LET psp=0.05: END IF
1630 LET y=y-1: LET M(x,y)=0: RETURN
2000 LET cont=0
2010 LET cont=cont+1
2020 IF cont>6 THEN LET y=7: RETURN: END IF
2030 IF M(x,cont)<>0 THEN GO TO 2010: END IF
2040 LET y=cont: RETURN
2500 FOR n=1 TO 6: BEEP n*n/100,n: BEEP n/50,n: NEXT n: RETURN
2700 REM Waits for a Key press since we lack the INPUT sentence
2710 LET a$=INKEY$: IF a$="" THEN GO TO 2710: END IF
2720 RETURN
2800 GOSUB 2700: IF a$ <> "y" AND a$ <> "m" THEN GOTO 2800: END IF
2810 RETURN
3000 IF color=1 THEN INK 7: END IF
3005 IF color=2 THEN INK 2: END IF
3010 LET xx=((xp*2)+1)*8: LET yy=((yp*2)+3)*8
3020 FOR n=1 TO 7: CIRCLE xx,yy,n: NEXT n: INK 7
3030 RETURN
3500 PRINT INK 2;"  \{vi}\  \::\::\  \::\  \  \  \  \::\::\::\  \  \  \::   \:: \.'\::\  \::\  \  \  \::\::\::\::\::  \::\:: \::\:: \::\::\:: \::\::\:: \:: \:: \::\.' \:: \:: \::\::\::\::\::\  \::\::\:: \::\:: \::\::\:: \:: \::   \:: \::\:: \::\  \::\  \::\::\::\::\:: \::\::\::    \::\::\::   \:: \:: \:: \::\:: \::\  \  \  \{vn}": GO TO 3600
3550 PRINT INK 2;"\::\::\:: \::\  \::   \::\::\:: \::\::\:: \::\'.\  \:: \::\::\:: \::\::\::\  \  \  \::\  \  \::\  \::\  \  \  \::\  \  \  \::\  \::\  \::\  \'.\::\  \::\  \::\  \'.\..\  \  \  \  \::\  \  \:: \::   \:: \:: \::\::\::\  \::\  \  \::\  \::\::\::\  \  \  \'.   \::  \::\::\::\  \  \  \::\::\::\  \::\  \::\  \::\  \  \::\  \::\  \::\  \::\::\::"
3600 PRINT "Play Again? (y/n)": GOSUB 2700: IF a$="y" THEN GO TO 6: END IF: IF a$<>"n" THEN GOTO 3600: END IF
