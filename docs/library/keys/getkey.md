# GetKey

Library: `#include <keys.bas>`

Wait for a key to be pressed (using [INKEY$](../../inkey.md)), and return its ASCII Code.


### Syntax
`GetKey()`

Waits for a key pressed and returns its ASCII code. It cannot detect multiple keys pressed.
This is useful, for example, to program options menus in games were only a single option
can be selected.

## Examples

```
# include <keys.bas>

PRINT "PRESS A KEY"
x = GetKey
PRINT "You pressed the "; CHR x; " key"
```
Will print the key pressed. Unlike [INKEY$](../../inkey.md) it returns an Ubyte (ASCII code)
which is more efficent that working with strings.

### See also

* [GetKeyScanCode](getkeyscancode.md)
* [MultiKeys](multikeys.md)


Back to parent page: [Keys ibrary](../keys.bas.md)
