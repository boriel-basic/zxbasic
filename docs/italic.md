#ITALIC

##Syntax
```
ITALIC <value>
```

or

```
PRINT ITALIC <value>;
```

This can be used to change the permanent print settings, or the temporary ones.
When used as a direct command:

```
ITALIC n
```

where n is either 0 (false) or 1 (true), then the subsequent print statements will have their `INK`
pixels slewed left at the top, and right at the bottom, making text appear italicized.

This command can be used as temporary colours by combining them with a print statement:

```
Print INK 0;PAPER 7; ITALIC 1; "This is ITALIC BLACK text on WHITE"
```

This version does not change the permanent colour settings and only affects
the characters printed within that print statement.

##Remarks
* This statement is NOT Sinclair BASIC compatible.

##See also
* [PRINT](print.md)
* [PAPER](paper.md)
* [BORDER](border.md)
* [INVERSE](inverse.md)
* [INK](ink.md)
* [BOLD](bold.md)
* [OVER](over.md)
