# RIGHT

Library: `#include <string.bas>`

Returns the last n chars of a string


###Syntax
`right(s$, N)`

Returns a substring of s$ of at most `N` characters starting from the right side.

 * If the string length is shorter than `N`, the entire string will be returned.

`right(s$, N)` is equivalent to `s$(len(s$) - N - 1 TO)`

## Examples

```basic
#include <string.bas>

PRINT right("HELLO WORLD", 5)
```
Will print `WORLD`.

---

```basic
#include <string.bas>

PRINT left("HELLO WORLD", 20)
```
This will print `HELLO WORLD`. Despite asking for 20 chars, the string contains
just 11 chars, so we get the entire string (they won't be filled with spaces).


### See also

 * [left](left.md)
 * [mid](mid.md)


Back to parent page: [String library](../string.bas.md)
