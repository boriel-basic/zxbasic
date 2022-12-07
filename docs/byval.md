# ByVAL

`ByVal` is a modifier used in function parameters to specify that the parameters is passed by value (that is, 
a copy of the value is passed to the [FUNCTION](function.md) or [SUB](sub.md)).

## Syntax

It's used in function parameter declaration as in this example:

```
FUNCTION plusOne(ByVal a As Ubyte) As UByte
  LET a = a + 1
  RETURN a
END FUNCTION

LET a = 0
PRINT plusOne(a): REM prints 1
PRINT a: REM prints 0; original value of A is preserved
```
 
Here the variable `a` is being modified within the function, but the original value is preserved upon return.
Except for arrays, when [ByREF](byref.md) or `ByVal` is not specified in [FUNCTION](function.md) or [SUB](sub.md)
parameters, `ByVal` will be used by default. On the other hand, if the parameter is an array, and no access is 
specified, it's supposed to be [ByREF](byref.md) (arrays cannot be passed by value).

See also:

* [FUNCTION](function.md)
* [SUB](sub.md)
* [ByREF](byref.md)
