# STRING.BAS

Library for generic string manipulation in Boriel ZX BASIC.

By default, the first character in a ZX BASIC string starts at position 0.
This is not very common in many BASIC dialects (i.e. Sinclair BASIC) were strings
start at position 1. This is done for efficiency. If you want your strings
to start at position 1, compile with `--string-base=1`.


### String slicing
Functions to retrieve a substring from a string given its position:

* [left](string/left.md)
* [mid](string/mid.md)
* [right](string/right.md)


### String trimming
Functions to remove a substring from a string:

* [trim]
* [ltrim]
* [rtrim]


### String case conversion
Functions to change the overall case of a string:

* [lcase]
* [ucase]


### String searching
Functions to find a substring in a string:

* [strpos]
* [instr]
