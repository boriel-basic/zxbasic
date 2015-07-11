 5 REM From the ZX Spectrum manual on Drawing primitives
 6 DIM x1, y1, x2, y2, c as Integer

10 BORDER 1: PAPER 0: INK 7: CLS: REM turn screen blank
20 LET x1 = 0: LET y1 = 0: REM line start
30 LET c = 1: REM Ink color starting from blue
40 LET x2 = INT(RND * 256): LET y2 = INT(RND * 192): REM Random line end
50 DRAW INK c; x2 - x1, y2 - y1
60 LET x1 = x2: LET y1 = y2: REM Next line starts at current one's ending
70 LET c = c + 1: IF c = 8 THEN LET c = 1: END IF: REM Next color
80 GOTO 40

