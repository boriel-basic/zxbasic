##Requirements

ATTR is a library function to be included with the following command:

```
#include <attr.bas>
```

##Description
`ATTR(row, col)`

Returns the ATTR (color attribute) of the given screen coordinate at the given row and column.


##Sample usage

```
#include <attr.bas>

PRINT AT 9, 10;PAPER 4; "A"
LET s = ATTR$(9, 10)
PRINT AT 0, 0; "The attribute of screen position 9, 10 is "; s
```

##Remarks

* This function extends the one in Sinclair BASIC (and it's compatible with it) since it also allows rows 22 and 23.



##See also

* [ CSRLIN ](csrlin.md)
* [ POS](pos.md)
* [ AT ](../at.md)
