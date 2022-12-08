# MID

Library: `#include <string.bas>`

Return a portion of a string.


### Syntax
`mid(s$, start, N)`

Returns a substring of s$ of at most `N` characters starting at the given
`start` position.

 * If the string length is shorter than `start + N` position (the `end` position is
beyond the end of the string), the substring starting from `start` position will
be returned.

 * If the start position is beyond the end of the string, an empty string
will be returned.

`mid(s$, start, N)` is equivalent to `s$(start TO start + N - 1)`

## Examples

```basic
#include <string.bas>

PRINT mid("HELLO WORLD", 0, 5)
```
Will print `HELLO`.

---

```basic
#include <string.bas>

PRINT mid("HELLO WORLD", 6, 8)
```
This will print just `WORLD`.
It'll start at position 6-th (for a 0-based string this is 7-th char), and print
up to 8 chars, but since there are only 5, it will get just `WORLD`.

---

```basic
#include <string.bas>

PRINT mid("HELLO WORLD", 12, 5)
```
This will print just an empty string: start position is beyond the end
of the string.


### See also

 * [left](left.md)
 * [right](right.md)


Back to parent page: [String library](../string.bas.md)
