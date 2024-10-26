# POKE

## Syntax

```
poke <address>, <value>
poke <type> <address>, <value>
```

## Description

Stores the given (numeric) _value_ at the specified memory _address_. If _valueType_ is omitted, it is supposed to be _ubyte_ (8 bit unsigned integer).

The _value_ is [converted](cast.md) to the given _[valueType](zx_basic:types.md)_ and stored at the given _Address_. _Type_ can be any numeric one (like _[float](zx_basic:types#float.md)_ or _[integer](zx_basic:types#integer.md)_).

## Examples

It is possible to _poke a decimal value_ (5 bytes) at a memory position:

```
poke float 16384, pi
```

Traditionally, in Sinclair BASIC, to store a 16 bit value the programmer does something like this:

```
10 LET i = 16384
20 LET value = 65500
30 POKE i, value - 256 * INT(value / 256) : REM value MOD 256
40 POKE i + 1, INT(value / 256)
```

This can be done in a single sentence in ZX BASIC:


```
poke uinteger 16384, 65500
```

It's faster and the recommended way.

## Remarks

* This statement is Sinclair BASIC compatible.
* This statement extends the Sinclair BASIC one.
* This statement also allows parenthesis and [FreeBASIC syntax](http://www.freebasic.net/wiki/wikka.php?wakka=KeyPgPoke)

## See also
* [PEEK](peek.md)
