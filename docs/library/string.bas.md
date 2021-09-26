# STRING.BAS

Library for generic string manipulation in Boriel ZX BASIC.

By default, the first character in a ZX BASIC string starts at position 0.
This is not very common in many BASIC dialects (i.e. Sinclair BASIC) were strings
start at position 1. This is done by efficiency. If you want your strings
to start at position 1, compile with `--string-base=1`.


### String slicing
Functions to retrieve a substring from a string:

* [left](../string/left)
* [mid](../string/mid)
* [right](../string/right)
