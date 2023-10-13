# GetKey

Library: `#include <keys.bas>`

Returns the Key Scan code of the key pressed or 0 if no keypress is detected.


### Syntax
`GetKeyScanCode()`

Examines the keyboard and returns 0 if no key is pressed (Unlike [GetKey](getkey.md), it
does not way for a key press).

If there is at least a key pressed, returns all of them ORed (bitwise).

## Examples

```
# include <keys.bas>

PRINT "PRESS H, L or both"
DO
LOOP UNTIL GetKeyScanCode()
PAUSE 10
x = GetKeyScanCode()

IF x = KEYH THEN PRINT "You pressed the H key"
IF x = KEYL THEN PRINT "You pressed the L key"
IF x = KEYL bOR KEYH THEN PRINT "You pressed both"
```
To detect more than one key, they must be in the same "row half" (see [keys.bas library](../keys.bas.md))
for further explanation.

### See also

* [GetKey](getkey.md)
* [MultiKeys](multikeys.md)


Back to parent page: [Keys library](../keys.bas.md)
