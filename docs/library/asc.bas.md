#Asc.bas

#ASC

Converts a specified character of a given string into the ASCII code equivalent.

##Syntax
```
variable = asc(A$,n)
```
Where `A$` is a string variable and `N` defines which character in the string we are interested in.

##Requirements

ASC is a library function that must be included before it can be used. Use the following directive:

```
#include <asc.bas>
```


##Remarks

* This function is for FreeBASIC compatibility. See [FreeBasic - ASC](http://www.freebasic.net/wiki/wikka.php?wakka=KeyPgAsc) for details.
* The return on this function is generally identical to that of `CODE(A$(n))`, though it will return 0, not an error,
if invoked to return the ascii code of a character beyond the length of the string.

##See also

* [ CODE ](code.md)


