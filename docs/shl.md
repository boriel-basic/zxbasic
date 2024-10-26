# SHL and SHR

# Bit Shift Instructions

## Syntax

```
 <expr> SHL <distance>
```
```
 <expr> SHR <distance>
```


Bit shifts `<expr>` expression by `<distance>` bits to the left (`SHL`) or to the right (`SHR`).
`SHR` can be replaced by `>>` and `SHL` by `<<` for more legibility.

The <expr> argument should be of an integer type: `uByte`, `Byte`, `uInteger`, `Integer`, `uLong` or `Long`.
Use of bitshifting with fixed and float gives undefined results.
`CAST` or `INT` should be used to convert floating point numbers into integer type numbers before use of the bit shift instructions.

Owing to the nature of moving bits right and left, `SHL` n is the equivalent of a multiply by 2<sup>n</sup>, and `SHR`
would be the equivalent of an integer division by 2<sup>n</sup> (destroying any fractional part).

### Examples
```
PRINT 2 << 1: REM prints 4
PRINT 16 SHR 2: REM again 4
```


## Remarks
* This function is not available in Sinclair BASIC.
* The syntax is similar to C's `<<` and `>>` operators.
