#BRIGHT

##Syntax
```
BRIGHT <value>
```
or
```
PRINT BRIGHT <value>;
```
This can be used to change the permanent print settings, or the temporary ones.
When used as a direct command:

```
BRIGHT n
```
where n is either 0 (false) or 1 (true), then the subsequent print statements will have both their `INK` and `PAPER`
values set to the higher intensity `BRIGHT` mode.

Just as in Sinclair basic, this command can be used as temporary colours by combining them with a print statement:


```
Print INK 0;PAPER 7; BRIGHT 1; "This is BLACK text on BRIGHT WHITE background"
```

Note that the BRIGHT black and standard black are identical.

This format does not change the permanent colour settings and only affects the characters printed within that print statement.

##Remarks
* This statement is 100% Sinclair BASIC compatible.

##See also
* [PRINT](print.md)
* [PAPER](paper.md)
* [BORDER](border.md)
* [BOLD](bold.md)
* [INK](ink.md)
* [ITALIC](italic.md)
* [OVER](over.md)
* [INVERSE](inverse.md)
* [FLASH](flash.md)
