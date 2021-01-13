#ByREF

`ByRef` is a modifier used in function parameters to specify that the parameters is passed by reference (that is, 
the original variable is passed to the [FUNCTION](function.md) or [SUB](sub.md)).

##Syntax

It's used in function parameter declaration as in this example:

```
FUNCTION plusOne(ByRef a As Ubyte) As UByte
  LET a = a + 1
  RETURN a
END FUNCTION

LET a = 0
PRINT plusOne(a): REM prints 1
PRINT a: REM prints 1; original value of A has been *modified* within the function
```
 
Here the variable `a` is being modified within the function, and this modification persist upon return.
Except for arrays, when `ByRef` or [ByVAL](byval.md) is not specified in [FUNCTION](function.md) or [SUB](sub.md)
parameters, [ByVAL](byval.md) will be used by default. On the other hand, if the parameter is an array,
and no access is specified, it's supposed to be `ByRef` (arrays cannot be passed by value).

ByRef allows us to pass arrays to [FUNCTION](function.md) or [SUB](sub.md):

```
REM arrays passed to functions can be of *any dimensions*.
REM Use LBOUND and UBOUND to detect dimensions!

FUNCTION maxValue(ByRef a() as Ubyte) As UByte
  DIM i as UInteger
  DIM result As UByte = 0 
  FOR i = LBOUND(a, 1) TO UBOUND(a, 1)
    IF a(i) > result THEN result = a(i)
  NEXT i
  RETURN result
END FUNCTION

DIM myArray(4) As UByte = {4, 3, 1, 2, 5}
PRINT "Max value is "; maxValue(myArray)
```

When passing arrays like in this example, if `ByRef` can be omitted.
Arrays parameters cannot be passed to a function using [ByVAL](byval.md).

`ByRef` is also useful to return values in the parameters. [RETURN](return.md) allows to return a single value
from a [FUNCTION](function.md), but we can return several values by storing the result in those parameters.

`ByRef` requires the parameter to be an _lvalue_, that is, a variable, an array or an array cell. You cannot use
`ByRef` with expressions (i.e. numbers) because you cannot store a value in them.

Example of wrong usage:

```
FUNCTION plusOne(ByRef a As Ubyte) As UByte
  LET a = a + 1
  RETURN a
END FUNCTION


DIM i as UByte = 7
DIM myArray(5) as Ubyte

PRINT plusOne(5): REM syntax error, 5 is not a variable or an array element.
PRINT plusOne(i): REM Ok. Will change i value to 8, and print 8)
PRINT plusOne(i + 1): REM syntax error, i + 1 is not a variable
PRINT plusOne(myArray(3)): REM Ok. Will increase myArray(3) by 1 and print the result
```

See also:

* [FUNCTION](function.md)
* [RETURN](return.md)
* [SUB](sub.md)
* [ByVAL](byval.md)
