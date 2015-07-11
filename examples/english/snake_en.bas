1  REM ********************************************************************
2  REM ZXSnake by Federico J. Alvarez Valero (05-02-2003)
10 REM This program is free software; you can redistribute it and/or modify
11 REM it under the terms of the GNU General Public License as published by
12 REM the Free Software Foundation; either version 2 of the License, or
13 REM (at your option) any later version.
14 REM This program is distributed in the hope that it will be useful,
15 REM but WITHOUT ANY WARRANTY; without even the implied warranty of
16 REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
17 REM GNU General Public License for more details.
18 REM You should have received a copy of the GNU General Public License
19 REM along with this program; if not, write to the Free Software
20 REM Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
30 REM                   ENGLISH VERSION
40 REM ********************************************************************

50   BORDER 7 : PAPER 7 : INK 0 : CLS
51   PRINT AT 3,13 ; PAPER 1 ; INK 7 ; "ZXSnake"
52   PRINT AT 5,9 ; PAPER 7 ; INK 0 ; "Q - Up"
53   PRINT AT 6,9 ; PAPER 7 ; INK 0 ; "A - Down"
54   PRINT AT 7,9 ; PAPER 7 ; INK 0 ; "O - Left"
55   PRINT AT 8,9 ; PAPER 7 ; INK 0 ; "P - Right"
56   PRINT AT 10,3 ; PAPER 7 ; INK 0 ; "You have to pick up every"
57   PRINT AT 11,3 ; PAPER 7 ; INK 0 ; "fruit on the screen while"
58   PRINT AT 12,3 ; PAPER 7 ; INK 0 ; "growing up more and more..."
59   PRINT AT 15,3 ; PAPER 7 ; INK 0 ; "Press any key to start"
60   LET j$ = INKEY$
61   IF j$ = "" THEN GOTO 60: END IF

70   REM UDG
71   DIM udg(1, 7) AS uByte => { {60, 66, 129, 129, 129, 129, 66, 60}, _
								 {24, 60, 60, 60, 126, 251, 247, 126}}
73	 POKE UINTEGER 23675, @udg(0, 0): REM Sets UDG variable to first element
74   LET S$ = CHR$(144): LET F$ = CHR$(145)

75   REM Variable declaration
76   DIM p(23,34) AS UBYTE: REM Screen
77   DIM x(23,34) AS UBYTE: REM Xorientations
78   DIM y(23,34) AS UBYTE: REM Yorientations

79   DIM c, f AS UBYTE 
80   DIM headx, heady AS UBYTE : REM Head coordinates
81   DIM tailx, taily AS UBYTE : REM Tail coordinates
90   DIM score, eaten as ULONG
95   DIM maxx, maxy, minx, miny as UByte

100  REM Variable definition
110  LET headx = 11 : REM head x coordinate
120  LET heady = 5 :  REM head y coordinate
130  LET tailx = 5 :  REM tail x coordinate
140  LET taily = 5 :  REM tail y coordinate
150  LET orientationx = 1
160  LET orientationy = 0

165  REM Clear arrays p, x and y
170  FOR c = 1 to 23: FOR f = 1 to 34
180  LET p(c, f) = 0: LET x(c, f) = 0: LET y(c, f) = 0
190  NEXT f: NEXT c

200  LET score = 0
210  LET eaten = 0
220  LET maxx = 33
230  LET maxy = 22
240  LET minx = 0
250  LET miny = 0

1000 REM Screen Initialization
1010 BORDER 1
1015 CLS
1020 PRINT AT 21,0 ; PAPER 1 ; INK 7 ; " SCORE :                       "
1030 FOR c = minx TO maxx
1040 LET p(miny+1,c+1) = 4
1050 LET p(maxy+1,c+1) = 4
1060 NEXT c
1070 FOR f = miny TO maxy
1080 LET p(f+1,minx+1) = 4
1090 LET p(f+1,maxx+1) = 4
1100 NEXT f  

1500 GOSUB 8000 : REM Place first fruit

2000 REM Draw snake in its initial position
2001 PAPER 7 : INK 0
2005 REM Draw the body
2010 FOR c = tailx TO headx-1
2020 PRINT AT taily,c ; INK 0 ; "O"
2025 LET p(taily+2,c+2) = 3
2026 LET x(taily+2,c+2) = 1
2027 LET y(taily+2,c+2) = 0
2030 NEXT c
2040 REM Draw the Head
2050 PRINT AT heady,headx ; INK 0 ; S$;
2055 LET p(heady+2,headx+2) = 2
2056 LET x(heady+2,headx+2) = 1
2057 LET y(heady+2,headx+2) = 0

3000 REM Update snake position
3005 INK 0
3010 REM Change the orientation if needed
3015 LET x(heady+2,headx+2) = orientationx
3020 LET y(heady+2,headx+2) = orientationy
3025 REM Erase previous head
3030 PRINT AT heady,headx ; "O"
3035 LET p(heady+2,headx+2) = 3
3040 LET headx = headx + orientationx
3045 LET heady = heady + orientationy
3050 IF p(heady+2,headx+2) > 1 THEN GOTO 9900: END IF
3051 IF p(heady+2,headx+2) = 1 THEN
     LET score = score + 10 : PRINT AT 21,10 ; _
     PAPER 1 ; INK 7 ; score : LET eaten = 1 : GOSUB 8000: END IF
3055 REM Print the new head
3060 PRINT AT heady,headx ; S$;
3065 LET p(heady+2,headx+2) = 2
3070 IF eaten = 0 THEN GOSUB 8100: END IF
3080 LET eaten = 0

3200 REM Read the keyboard
3210 LET a$ = INKEY$
3220 IF orientationx < 1 AND (a$ = "O" OR a$ = "o") THEN
     LET orientationx = -1 : LET orientationy = 0: END IF
3230 IF orientationx > -1 AND (a$ = "P" OR a$ = "p") THEN
     LET orientationx = 1 : LET orientationy = 0: END IF
3240 IF orientationy < 1 AND (a$ = "Q" OR a$ = "q") THEN
     LET orientationx = 0 : LET orientationy = -1: END IF
3250 IF orientationy > -1 AND (a$ = "A" OR a$ = "a") THEN
     LET orientationx = 0 : LET orientationy = 1: END IF

3500 REM Pausa / Delay 
3505 BEEP 0.005, 0
3510 FOR i = 1 TO 500:
	 NEXT i

7998 GOTO 3000

8000 REM Fruit placement
8010 LET fruitx = INT(RND*30)+1
8020 LET fruity = INT(RND*20)+1
8030 IF p(fruity+2,fruitx+2) = 0 THEN GOTO 8050: END IF
8040 GOTO 8010
8050 PRINT AT fruity,fruitx ; INK 2 ; F$;
8060 LET p(fruity+2,fruitx+2) = 1
8070 RETURN

8100 REM Erase tail
8110 PRINT AT taily,tailx ; " "
8120 LET newtailx = tailx + x(taily+2,tailx+2)
8130 LET newtaily = taily + y(taily+2,tailx+2)
8140 LET p(taily+2,tailx+2) = 0
8150 LET x(taily+2,tailx+2) = 0
8160 LET y(taily+2,tailx+2) = 0
8170 LET tailx = newtailx
8180 LET taily = newtaily
8190 RETURN

9900 REM Game over
9910 PRINT AT 10,12 ; INK 2 ; "GAME OVER..."
9920 PRINT AT 11,10 ; INK 2 ; "SCORE : " ; score
9930 PRINT AT 13,10 ; INK 0 ; "Press any key"
9931 REM Mondatory pause so the msg. can be read
9932 FOR i = 0 TO 100

9933 NEXT i
9940 LET j$ = INKEY$
9950 IF j$ <> "" THEN GOTO 100: END IF
9960 GOTO 9940

