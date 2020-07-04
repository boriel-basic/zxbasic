#FUNCTION

ZX Basic allows function and subroutines declarations. This feature is new to ZX Basic.
Sinclair BASIC allowed limited function definitions using `DEF FN`.

A function is a subroutine (like GO SUB) that is invoked directly.
The subroutine returns a value than can be used later.
BASIC language already has some predefined functions, like `SIN`, `COS`, `PEEK` or `LEN`.
The user is now allowed to define his/her own functions.

##Syntax
Basic function declaration is:

```
 FUNCTION <function name>[(<paramlist>)] [AS <type>]
     <sentences>
     ...
 END FUNCTION
```
##Example
A simple function declaration:

```
REM This function receives and returns a byte
FUNCTION PlusOne(x AS Byte) AS Byte
    RETURN x + 1
END FUNCTION

REM Using the function
PRINT x; " plus one is "; PlusOne(x)
```

If `AS` _type_ is omitted, the function is supposed to return a `Float`.

```
REM This function returns a float number because its type has been omitted.
REM Also, the 'x' parameter will be converted to float,
REM because it's type has been omitted too

FUNCTION Square(x)
    RETURN x^2
END FUNCTION

REM Using the function
PRINT "Square of "; x; " is "; Square(x)
```

##Recursion
Recursion is a programming technique in which a function calls itself. A classical recursion example is the factorial function:

```
FUNCTION Factorial(x)
    IF x < 2 THEN RETURN 1
    RETURN Factorial(x - 1) * x
END FUNCTION
```

However, not using types explicitly might have a negative impact on performance.
Better redefine it using data types. Factorial is usually defined on unsigned integers and also returns an unsigned
integer. Also, keep in mind that factorial numbers tends to _grow up very quickly_ (e.g. Factorial of 10 is 3628800),
so `ULong` [type](types.md) (32 bits unsigned) seems to be the most suitable for this function.

This version is faster (just the 1st line is changed):

```
FUNCTION Factorial(x AS Ulong) AS Ulong
    IF x < 2 THEN RETURN x
    RETURN Factorial(x - 1) * x
END FUNCTION
```

##Memory Optimization
If you invoke zxbasic using `-O1` (or higher) optimization flag the compiler will detect and ignore unused functions
(thus saving memory space). It will also issue a warning (perhaps you forgot to call it?),
that can be ignored.

##See Also

* [SUB](sub.md)
* [ASM](asm.md)
* [END](end.md)
* [RETURN](return.md)
* [ByREF](byref.md)
* [ByVAL](byval.md)
