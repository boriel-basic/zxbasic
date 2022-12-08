# DIM

**DIM** is used in Sinclair BASIC to declare arrays.
In ZX BASIC, its usage has been extended to declare any variable and its type.
A [type](types.md) is a name for the kind of data (`Integer`, `Byte`, `String`, etc.) it holds.

## Declaration of variables

### Syntax

```
DIM <variable_name>[,<variable_name>...] [AS <type>] [= <value>]
```

Where _<type>_ can be one of **INTEGER**, **BYTE**, **FLOAT**, etc.
See the list of [available types](types.md). If type is not specified, **FLOAT** will be used, unless you use
a suffix (usually called _sigil_) like `$` or `%`.

### Default variable values

ZX BASIC will initialize any numeric variable to 0 (like most BASIC flavors), and any string variable to an
empty string, so you don't need to initialize them, though it's recommended.

### Undeclared variables

ZX BASIC allows you to use undeclared variables. In Sinclair BASIC, using an unassigned variable triggered
the error _Variable not found_, but in ZX BASIC it will default to 0 value.

You can enforce variable declaration using the `--explicit` [command line option](zxb.md#command-line-options).
When it's used, the compiler will require every variable to be declared with DIM before being used for the 1st time.

You can also enforce explicit type declaration using the `--strict` [command line option](zxb.md#command-line-options).
This way, if you use `DIM` you will be required to declare also the type needed.

When you use an undeclared variable, ZX BASIC will try to guess its type by looking at the context in which 
it is being used and then will initialize it with a default value, depending on the type (0 or an empty string).
If it cannot guess the type (this is usually very difficult), it will fallback to float.
The float type is the most inefficient (though most flexible) type ZX BASIC supports,
but it is the Sinclair BASIC compatible one. So if you want the compiler to make an efficient and optimized compilation,
it is better to declare the variable types you use in advance using the DIM statement
(Note that languages like C or Pascal requires every used variable to be declared).

Declaring a variable that has already been referenced in previous lines will result in a syntax error.

## Examples

### Examples of variable declarations

```
REM Declares 'a' as a 16 bit signed integer variable
DIM a AS INTEGER

REM Declares 'b' as a Float because no type is specified
DIM b

REM Declares 'c' as String, because of the '$' suffix
DIM c$

REM Declares 'd' as String, using an explicit type
DIM d as STRING

REM Declares 'x', 'y' as 32bit unsigned integers in a single line
DIM x, y as ULONG

REM Here 'S' is declared as String, because 'R' has a '$'
DIM R$, S

REM initialize an unsigned byte with 5
DIM b as UBYTE = 5

REM warning: Using default implicit type float for 'a'
DIM a = 5

REM No warning here, because the compiler knows it is an integer (% suffix)
DIM c% = 5
```

### Examples of undeclared variables

```
REM variable a is not declared, but since you use PI, it must be float
LET a = PI
```

However, other examples might be more complex:

```
REM variable a here is taken as a FIXED not FLOAT. Beware with precision loss!
LET a = 3.5
```

For any positive integer, unsigned types will be used, but if an implicit initialization contains a negative value
the signed type will be used instead.

```
REM variable a will be declared implicitly as BYTE 
FOR a = -1 TO 10
   ...
NEXT

REM Warning, truncation!
LET a = -3.5

REM variable b will be declared as UByte
FOR b = 1 TO 10
   ...
NEXT

REM Warning, sign overflow!
LET b = -1
```

As you might see, using undeclared variables might lead to errors (truncation, overflow).
The compiler will try to warning about these whenever it can, but sometimes this will be not possible,
and errors might pass silently... (you might experience strange behaviors in your program).

It might even be difficult for you to guess which type will be implicitly used for an undeclared variable.
The safest choice is to always declare them.

## Variable mapping

You can declare a variable at a fixed memory address. This is called _variable mapping_.

E.g. in ZX Spectrum Sinclair's ROM address 23675 contains a system variable which points to UDG address.
You could traditionally read this content by doing:

```
PRINT "UDG memory address is "; PEEK 23675 + 256 * PEEK 23676
```

It is a 16 bit unsigned integer value (`Uinteger`). We can map a variable on that address:

```
DIM UDGaddr AS Uinteger AT 23675
PRINT "UDG memory address is "; UDGaddr
```

This is more readable. Also, setting a value to this variable changes UDG address.

## Variable aliasing

A variable is just a memory position containing data. In same cases you might find useful a variable having
more than one name, for the sake of code readability:

```
DIM a AS Float = PI

REM Now let's declare an alias of 'a', called 'radians'
DIM radians AS Float AT @a

PRINT "radians = "; radians
LET radians = 1.5
PRINT "a = "; a
```

As you can see, both _**radians**_ and _**a**_ can be used interchangeably.

## Array Declaration

### Syntax

```
DIM a([<lower_bound> TO] <upper_bound> [, ...]) AS <type>
```

### Description

By default, array indexes starts from 0, not from 1 as in Sinclair BASIC. You can change this behavior setting 
a different array base index using either a [#pragma option](pragma.md) or a [command line option](zxb.md#command-line-options).

### Examples


```
REM 'a' is an array of 11 floats, from a(0) to a(10)
DIM a(10)

REM 'b' has the same size
DIM b(0 TO 10)
```


### Initialized arrays
You can also use DIM to declare an array, and promptly fill it with data. At the moment, this is not valid for string arrays, only numerical arrays. One handy way to use this would be to use an array to store a table, such as user defined graphics:

```
REM udg will be an array of 8 UBytes
REM Remember, the default in ZX Basic is for arrays to begin at zero, so 0-7 is 8 bytes
DIM udg(7) AS uByte => {0,1,3,7,15,31,63,127}

REM This sets the System UDG variable to point to the 1st array element:
POKE UINTEGER 23675,@udg(0): REM udg(0) is the 1st array element
```

Arrays of 2 or more dimensions can be initialized using this syntax:

```
DIM udg(1, 7) AS uByte => {{0,1,3,7,15,31,63,127}, _
                           {1,2,4,7,15,31,63,127}}

REM Each row contains an UDG. All bytes are stored in a continuous memory block
```

Note the usage of `@variable` to denote the location in memory the variable is stored into. Also see the extensions to [POKE](poke.md).

## See also

* [LBOUND](lbound.md)
* [UBOUND](ubound.md)
* [Arrays](types.md#arrays)
