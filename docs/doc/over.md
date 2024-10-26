# OVER

## Syntax
```
OVER <value>
```

or

```
PRINT OVER <value>;
```

This can be used to change the permanent print settings, or the temporary ones. When used as a direct command:

```
 OVER 0
 OVER 1
 OVER 2
 OVER 3
```
then the subsequent print statements will overwrite the previous ones with differing effects.

 * After an `OVER 0` command, the characters are simply replaced, as per usual.
   This behaves just like the Sinclair Basic OVER 0 command.

 * After `OVER 1`, subsequent characters are combined with an Exclusive OR (XOR) - that is
   to say pixels are flipped by overprinting with another ink pixel, and left alone by overprinting with a paper pixel.
   This behaves identically to the OVER 1 Sinclair Basic Command.

 * After `OVER 2`, subsequent prints are combined using an AND function - that is only
   pixels will remain where BOTH characters has pixels before. If either had a paper pixel, what is left is a paper pixel.
   This is not Sinclair Basic compatible, and is an extension.

 * After `OVER 3`, Subsequent prints are combined using an OR function - that is pixels remain where EITHER
   character had pixels before. If either had an ink pixel, what is left there is an ink pixel.
   This is not Sinclair Basic compatible, and is an extension.

Just as in Sinclair basic, these commands can be used as temporary colours by combining them with a print statement:

```
Print Over 2; "This is combined as an AND function"
```

This format does not change the permanent colour settings and only affects the characters
printed within that print statement.

## Remarks
* This function is Sinclair BASIC compatible.
* This function _extends_ Sinclair BASIC.

## See also
* [PRINT](print.md)
* [PAPER](paper.md)
* [INK](ink.md)
* [BOLD](bold.md)
* [INVERSE](inverse.md)
* [ITALIC](italic.md)
