10 REM Pong! Game

14 REM Digit data
   REM 128 => "\  "
   REM 131 => "\''"
   REM 138 => "\: "
   REM 133 => "\ :"
   REM 139 => "\:'"
   REM 141 => "\.:"
   REM 140 => "\.."
   REM 135 => "\':"
   REM 142 => "\:."

15 DIM numbers(9, 2, 1) as Ubyte = { _
    {{139, 135}, {138, 133}, {142, 141}}, _ ' Number 0
    {{128, 133}, {128, 133}, {128, 133}}, _ ' Number 1
    {{131, 135}, {139, 131}, {142, 140}}, _ ' Number 2
    {{131, 135}, {131, 135}, {140, 141}}, _ ' Number 3
    {{138, 133}, {131, 135}, {128, 133}}, _ ' Number 4
    {{139, 131}, {131, 135}, {140, 141}}, _ ' Number 5
    {{139, 131}, {139, 135}, {142, 141}}, _ ' Number 6
    {{131, 135}, {128, 133}, {128, 133}}, _ ' Number 7
    {{139, 135}, {139, 135}, {142, 141}}, _ ' Number 8
    {{139, 135}, {131, 135}, {140, 141}}  _ ' Number 9
    }
20 BORDER 0: PAPER 0: INK 7: BRIGHT 1: OVER 1: CLS
   DIM h, xx, yy, p, oldX, oldY As Byte
   DIM x, y, dx, dy as Fixed
   DIM px, py, NUM as Byte
   DIM i, delay as Uinteger
   DIM diff as Float = 0.5 : REM difficulty level
   CONST minX As Byte = 0
   CONST minY As Byte = 0
   CONST maxX As Byte = 61
   CONST maxY As Byte = 47
   CONST comp As Byte = 0: REM Computer player is left
   CONST user As Byte = 1: REM User player is left
   CONST startX as Byte = maxX / 2: REM Ball initial X coord
   CONST startY as Byte = maxY / 2: REM Ball initial Y coord
   CONST dFast as UInteger = 400
   CONST dSlow as UInteger = 1000
   CONST diffRate As Float = 1.125: REM difficulty rate

   DIM score(1) As Byte: REM Scores

30 LET xx = 31: FOR yy = minY TO maxY STEP 2: GOSUB 2000: NEXT yy
40 DIM coords(1, 1) As Byte: REM Player 0 (Left) and 1 (Right) coordinates
50 LET h = 5: REM players height (in "points"). A "point" is 4 pixels
60 LET x = startX: LET y = startY: REM Screen resolution is 64
70 LET coords(0, 0) = minX: LET coords(1, 0) = maxX
80 LET coords(0, 1) = minY + (maxY - minY) / 2: LET coords(1, 1) = coords(0, 1)
90 LET dx = 1: LET dy = 1: LET delay = dSlow: REM Ball speed
91 LET score(0) = 0: LET score(1) = 0: REM Initializes scores

93 FOR p = 0 TO 1: GOSUB 1000: NEXT p: REM Draw players
94 GOSUB 3000: REM Print scores

95 REM Draws Ball. Begin of GAME LOOP
96 LET xx = x: LET yy = y: LET oldX = x: LET oldY = y: GOSUB 2000
100 LET x = x + dx
110 IF x < minX THEN LET x = minX: LET dx = -dx: BEEP 0.02,20
        LET py = coords(0, 1)
        IF py > y OR py + h <= y THEN
            REM Player 2 wins 1 Point
            LET score(1) = score(1) + 1
            GOSUB 3000
            LET y = startY
            LET x = coords(1, 0)
            LET dx = -dx
            LET delay = dSlow
            IF comp <> 1 THEN
                LET diff = diff / diffRate
            ELSE
                LET diff = diff * diffRate
            END IF
        ELSE
            IF y = py OR y = py + h - 1 THEN
                delay = dFast
            ELSE
                delay = dSlow
            END IF
        END IF
    ELSEIF x > maxX THEN LET x = maxX: LET dx = -dx: BEEP 0.02,20
        LET py = coords(1, 1)
        IF py > y OR py + h <= y THEN
            REM Player 1 wins 1 Point
            LET score(0) = score(0) + 1
            GOSUB 3000
            LET y = startY
            LET x = coords(0, 0)
            LET dx = -dx
            LET delay = dSlow
            IF comp <> 0 THEN
                LET diff = diff / diffRate
            ELSE
                LET diff = diff * diffRate
            END IF
        ELSE
            IF y = py OR y = py + h - 1 THEN
                delay = dFast
            ELSE
                delay = dSlow
            END IF
        END IF
    END IF

120 LET y = y + dy
130 IF y < minY THEN LET y = minY: BEEP 0.02,10: LET dy = -dy
    ELSEIF y > maxY THEN LET y = maxY: BEEP 0.02,10: LET dy = -dy
    END IF

140 REM Checks if computer must move
150 LET px = coords(comp, 0): LET py = coords(comp, 1)
160 IF py > y AND RND > diff THEN: REM Must go up
        LET p = comp
        GOSUB 1500: REM Updates player padel (up)
    ELSEIF py + h - 1 < y AND RND > diff THEN
        LET p = comp
        GOSUB 1600: REM Updates player padel (down)
    END IF

200 REM Checks if Player moves ("4", "3")
210 LET px = coords(user, 0): LET py = coords(user, 1)
220 if py > minY AND INKEY$ = "4" THEN: REM Must go up
        LET p = user
        GOSUB 1500: REM Updates player padel (up)
    ELSEIF py + h < maxY AND INKEY$ = "3" THEN
        LET p = user
        GOSUB 1600: REM Updates player padel (down)
    END IF

250 FOR i = 0 TO delay: NEXT i

500 LET xx = oldX: LET yy = oldY
    ASM
    halt        ; Avois screen flickering
    END ASM
    GOSUB 2000: REM erases the ball
    GOTO 95: REM Game loop

0999 END
1000 REM Draws player p at p(p, 0), p(p, 1)
1010 LET xx = coords(p, 0)
1020 LET yy = coords(p, 1)
1030 FOR i = 1 TO h: GOSUB 2000: LET yy = yy + 1: NEXT i
1040 RETURN

1500 REM Moves up the padel for user p (p = 0 => Left, p = 1 = Right)
1510 LET xx = px
1520 FOR i = 0 TO 1: IF py <= minY THEN EXIT FOR: END IF
1530 LET py = py - 1
1540 LET yy = py: GOSUB 2000: REM Draws padel top
1550 LET yy = py + h: GOSUB 2000: REM Erases padel bottom
1560 NEXT i
1570 LET coords(p, 1) = py: RETURN

1600 REM Moves down the padel for user p (p = 0 => Left, p = 1 = Right)
1610 LET xx = px: LET yy = py
1620 FOR i = 0 TO 1: IF py + h > maxY THEN EXIT FOR: END IF
1630 LET yy = py: GOSUB 2000: REM Erases padel top
1640 LET yy = py + h: GOSUB 2000: REM Draws padel bottom
1650 LET py = py + 1
1660 NEXT i
1670 LET coords(p, 1) = py: RETURN

2000 REM Draws a "Point" at xx,yy 
2010 LET cx1 = xx bAND 1: LET cy1 = yy bAND 1
2020 LET cx2 = xx SHR 1: LET cy2 = yy SHR 1
2040 IF cx1 THEN
        IF cy1 THEN
            LET c$ = "\ ."
        ELSE
            LET c$ = "\ '"
        END IF
     ELSE
        IF cy1 THEN
            LET c$ = "\. "
        ELSE
            LET c$ = "\' "
        END IF
     END IF

2050 PRINT AT cy2, cx2; c$;
2060 RETURN

3000 REM Prints SCORES
3010 FOR player = 0 TO 1
3020 LET atY = minY + 1: LET atX = minX + 4 + player * (maxX - minX) / 4: LET sc = score(player)
3030 IF sc < 10 THEN: REM erases left digit
        FOR i = 0 TO 2: PRINT OVER 0; AT atY + i, atX; "  ";:NEXT i
     ELSE
        LET NUM = sc / 10: REM Left digit
        GOSUB 5000
     END IF
3040 LET atX = atX + 3
3050 LET NUM = sc Mod 10
3060 GOSUB 5000
3070 NEXT player
3080 RETURN

5000 REM Prints Number NUM at atY, atX
5010 FOR ny = 0 TO 2: FOR nx = 0 TO 1
5020 PRINT OVER 0; AT atY + ny, atX + nx; CHR$(numbers(NUM, ny, nx));
5030 NEXT nx: NEXT ny
5040 RETURN

