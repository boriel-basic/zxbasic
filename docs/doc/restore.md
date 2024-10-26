# RESTORE


## Syntax
```
RESTORE [<label>]
```
**RESTORE** statement is used to change the order in which [DATA](data.md) lines are read.
The **RESTORE** _label_ statement will make the next [READ](read.md) to get the data from the label line onwards.
If no label is specified, the data reading sequence is restarted from the beginning.


## Example

```
RESTORE numbers

FOR i = 1 TO 3
    READ a
    PRINT a
NEXT i

REM These will be skipped by the RESTORE above
strings:
DATA "Hello world!", "ZX Spectrum", "ZX Rules!"

REM This will be read since RESTORE pointed to numbers: label
numbers:
DATA 10, 20, 30
```

This will output:

```
 10
 20
 30
```
Notice the strings section has been skipped over.

## Remarks
* This statement is Sinclair BASIC compatible.

## See also
* [DATA](data.md)
* [READ](read.md)
