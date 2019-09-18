#FLASH

##Syntax
```
FLASH <value>
```
or
```
PRINT FLASH <value>;
```
This can be used to change the permanent print settings, or the temporary ones.
When used as a direct command:

```
FLASH n
```
being `n` either 0 (false) or 1 (true), then the subsequent print statements will print characters that have
their `INK` and `PAPER` values swapped at regular intervals automatically by the Spectrum's ULA.

Just as in Sinclair Basic, this command can be used as temporary colours by combining them with a print statement:

```
Print INK 0;PAPER 7; FLASH 1; "This is flashing black and white text"
```
This format does not change the permanent colour settings and only affects the characters printed within that print statement.

##Remarks
* This function is 100% Sinclair BASIC compatible.

##See also

* [PRINT](print.md)
* [PAPER](paper.md)
* [BORDER](border.md)
* [BOLD](bold.md)
* [INK](ink.md)
* [ITALIC](italic.md)
* [OVER](over.md)
* [INVERSE](inverse.md)
* [BRIGHT](bright.md)
