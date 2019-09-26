#BOLD

##Syntax
```
BOLD <value> 
```
or

```
PRINT BOLD <value>;
```

This can be used to change the permanent print settings, or the temporary ones. When used as a direct command:

```
BOLD n
```
where n is either 0 (false) or 1 (true), then the subsequent print statements will have their INK pixels emphasized,
making text appear bolder.

This command can be used as temporary colours by combining them with a print statement:


```
Print INK 0;PAPER 7; BOLD 1; "This is BOLD BLACK text on WHITE"
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
* [ITALIC](italic.md)
* [OVER](over.md)
