# MultiKeys

Library: `#include <keys.bas>`

Returns whether any of the given keys is being pressed.
Unlike [INKEY$](../../inkey.md), it can detect multiple keys pressed at once
(with some restrictions).


### Syntax
`MultiKeys(KeyCode1 bOR KeyCode2 bOR ...)`

Returns whether any of the given keys was pressed. If no key was pressed, returns 0.
It's possible to check for more than one key pressed at once, and to decode
which keys were pressed by examining the returned value.

## Examples

```
#include <keys.bas>

DO
LOOP UNTIL MultiKeys(KEYH bOR KEYL)

PAUSE 10  'Needed to allow the user to wait press 2 keys
x = MultiKeys(KEYH bOR KEYL)
IF x bAND KEYH PRINT "Key H was pressed"
IF x bAND KEYL PRINT "Key L was pressed"

```
Will print whether the Key H o the Key L or both bas been pressed.

Checking for 2 or more keys will work only if these keys are in the same
"row half", that is: in the same row and in the same group of 5 keys of that
row (the left one or the right one)

### See also

* [GetKey](getkey.md)
* [GetKeyScanCode](getkeyscancode.md)


Back to parent page: [Keys library](../keys.bas.md)
