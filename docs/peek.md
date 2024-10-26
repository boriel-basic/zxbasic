# PEEK


## Syntax


```
peek (address)
peek (typeToRead, address)
```

## Description

Returns the memory content (byte) stored at _address_ position. If _address_ is not a 16 bit unsigned integer, it will be [converted](cast.md) to such type before reading the memory.

When _typeToRead_ is specified, the given [type](types.md) is read from memory; otherwise the type of the read value is supposed to be _ubyte_ (8 bit unsigned integer).

The type of the returning value is the _typeToRead_ specified, or _ubyte_ if no type is specified.

## Examples

The following example reads a 16 bit unsigned integer at position 23675 (this is the System Variable for <abbr title="User Defined Graphics">UDG</abbr> in Sinclair BASIC systems):

```
print "Address of UDG is "; peek(23675) + 256 * peek(23676)
```

But it's faster to specify the type of the value:

```
print "Address of UDG is "; peek(uinteger, 23675)
```

## Remarks

* This function is Sinclair BASIC compatible.
* This function extends the Sinclair BASIC version.

## See also

* [poke](poke.md)
