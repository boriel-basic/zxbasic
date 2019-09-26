#INK

##Syntax
```
INK <value>
```
or
```
PRINT INK <value>;
```
This can be used to change the permanent print settings, or the temporary ones. When used as a direct command:


```
INK n
```
being n a number from 0-8, then the subsequent print statements will have a foreground colour based on the number used. As the ZX Spectrum manual states:
```
 0 - black
 1 - blue
 2 - red
 3 - purple, technically called magenta
 4 - green
 5 - pale blue, technically called cyan
 6 - yellow
 7 - white
 8 - transparent (Do not change the paper value in the square being printed)
 9 - Contrast - currently NOT supported.
```
Just as in Sinclair basic, this command can be used as temporary colours by combining them with a print statement:


```
Print ink 2; "This is red text"
```
 
This format does not change the permanent colour settings and only affects the characters printed within that print statement.

##Remarks
* This function is Near Sinclair BASIC compatible.

##See also
* [PRINT](print.md)
* [PAPER](paper.md)
* [BORDER](border.md)
* [BOLD](bold.md)
* [INVERSE](inverse.md)
* [ITALIC](italic.md)
* [OVER](over.md)
