#Hex.bas

#HEX

Converts a specified integer into a 4 char string with its hex representation.

##Syntax
```
string = hex(A$)
```
Where `A$` is a 32 bit unsigned integer variable.

Or, for the 16 bit version, into a 2 char string:
```
string = hex16(B$)
```
Where `B$` is a 16 bit unsigned integer variable.

And even the 8 bit version, into a 1 char string:
```
string = hex8(C$)
```
Where `C$` is an 8 bit unsigned integer variable.

##Requirements

HEX is a library function that must be included before it can be used. Use the following directive:

```
#include <hex.bas>
```


