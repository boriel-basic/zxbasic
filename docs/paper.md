# PAPER

## Syntax
```
PAPER <value>
```

or

```
PRINT PAPER <value>;
```
This can be used to change the permanent print settings, or the temporary ones. When used as a direct command:

```
PAPER n
```

where n is a number from 1-8, then the subsequent print statements will have a background colour based on
the number used. As the ZX Spectrum manual states:
```
 0 - black
 1 - blue
 2 - red
 3 - purple, technically called magenta
 4 - green
 5 - pale blue, technically called cyan
 6 - yellow
 7 - white
 8 - transparent (do not change the paper value in the square being printed)
```

Just as in Sinclair basic, this command can be used as temporary colours by combining them with a print statement:

```
Print paper 2; "This is on a red background"
```

This format does not change the permanent colour settings and only affects the characters printed within
that print statement.

## Remarks
* This function is 100% Sinclair BASIC compatible.

## See also
* [PRINT](print.md)
* [BORDER](border.md)
* [INK](ink.md)
* [BOLD](bold.md)
* [INVERSE](inverse.md)
* [ITALIC](italic.md)
* [OVER](over.md)
