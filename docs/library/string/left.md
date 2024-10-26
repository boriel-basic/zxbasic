# LEFT

Library: `#include <string.bas>`

Returns the first n chars of a string


### Syntax
`left(s$, N)`

Returns a substring of s$ of at most `N` characters starting from the left side.

 * If the string length is shorter than `N`, the entire string will be returned.

`left(s$, N)` is equivalent to `s$(TO N - 1)`

## Examples

```basic
# include <string.bas>

PRINT left("HELLO WORLD", 5)
```
Will print `HELLO`.

---

```basic
# include <string.bas>

PRINT left("HELLO WORLD", 20)
```
This will print `HELLO WORLD`. Despite asking for 20 chars, the string contains
just 11 chars, so we get the entire string (they won't be filled with spaces).


### See also

 * [mid](mid.md)
 * [right](right.md)


Back to parent page: [String library](../string.bas.md)
