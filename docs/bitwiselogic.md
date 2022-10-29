#Bitwise Operators

ZX Basic allows Bit Manipulation (bitwise), on every integer type (from 8 to 32 bits).

| **BITWISE OPERATORS** |
|: ---------------------------- :|
| bAND |
| bOR  |
| bNOT |
| bXOR |

Except bNOT, all the others require two integral (Byte, Ubyte, Integer, UInteger, Long, ULong) operands.
The operation will be applied bit by bit.

---
## bAND

Performs the _Bitwise Conjunction_ and returns 1 for every bit if and only if both bits are 1.

| a  | b  | result |
|:----:|:----:|:------:|
|  0  | 0  |  0 |
|  0  | 1  | 0 |
|  1  | 0  |  0 |
|  1  | 1  |  1 |

###Example

Binary "mask" that will get only the 4 rightmost bits 0 1 2 3 of a number:

`PRINT BIN 01110111 bAND BIN 00001111` will print 3, which is 0111`

---

## bOR

Performs the _Bitwise Disjunction_ and returns 1 if any of the arguments is 1.

| a  | b  | result |
|:----:|:----:|:------:|
|  0  | 0 |  0 |
|  0  | 1  | 1 |
|  1  | 0 |  1 |
|  1  | 1  |  1 |

###Example

Ensure an ASCII letter is always in lowercase:

`PRINT CHR$(CODE "A" OR BIN 10000)` will print `a` because lowercase letters have bit 5 set.

---

## bNOT

Performs the _Bitwise Negation_ and returns _1_ if the arguments is _0_ and vice versa. 
Basically it flips all the bits in an integer number.

| a  |result |
|:----:|:------:|
|  0  | 1  |
|  1  | 0  |


###Example

Invert the first cell (upper-leftmost) in the screen:

```
PRINT AT 0, 0; "A";
FOR i = 0 TO 3
    POKE 16384 + 256 * i, bNOT PEEK(16384 + 256 * i)
NEXT
```
---

## bXOR

Performs a logical XOR and returns 1 if one and only one of the arguments is 1, 0 if both bits are the same.
In essence, returns 1 ONLY if one of the arguments is 1. 

| a  | b  | result |
|:----:|:----:|:------:|
|  0  | 0 |  0 |
|  0  | 1  | 1 |
|  1  | 0 |  1 |
|  1  | 1  |  0 |
---

###Example

Flips an ASCII letter from lower to uppercase and vice versa

`PRINT CHR$(CODE "A" bXOR BIN 10000)`
