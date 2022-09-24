# KEYS.BAS

Library to check for keys being pressed. It provide functions which are
much faster than [INKEY$](../inkey.md), take less memory and does not require
the Sinclair ROM to be present.

## Functions
Functions provided in this library:

* [GetKey](./keys/getkey.md)
* [GetKeyScanCode](./keys/getkeyscancode.md)
* [MultiKeys](./keys/multikeys.md)


### Scan codes

This library define some global constants named _Scan codes_ which are just
UInteger constant.

Each key has assigned a unique Scan code. The ZX Spectrum Keyboard is divided
in 8 Rows half. Each Row half comprises 5 keys (from the left or right side of the speccy
QWERTY keyboard).

For example letters H, J, K L and ENTER belong to row half #2 (see below).

It is possible, for some routines, to use more than one scan code simultaneously, with `bOR`
operator.
For example `KEYH bOR KEYL` means Key H and/or Key L.
The only restriction is that both keys must be in the same Row Half.

These are all the scan codes available and their values.
```
Scan Codes

1st Keyboard ROW half
const KEYB        AS UInteger = 07F10h
const KEYN        AS UInteger = 07F08h
const KEYM        AS UInteger = 07F04h
const KEYSYMBOL   AS UInteger = 07F02h
const KEYSPACE    AS UInteger = 07F01h

2nd Keyboard ROW half
const KEYH        AS UInteger = 0BF10h
const KEYJ        AS UInteger = 0BF08h
const KEYK        AS UInteger = 0BF04h
const KEYL        AS UInteger = 0BF02h
const KEYENTER    AS UInteger = 0BF01h

REM 3rd Keyboard ROW half
const KEYY        AS UInteger = 0DF10h
const KEYU        AS UInteger = 0DF08h
const KEYI        AS UInteger = 0DF04h
const KEYO        AS UInteger = 0DF02h
const KEYP        AS UInteger = 0DF01h

REM 4th Keyboard ROW half
const KEY6        AS UInteger = 0EF10h
const KEY7        AS UInteger = 0EF08h
const KEY8        AS UInteger = 0EF04h
const KEY9        AS UInteger = 0EF02h
const KEY0        AS UInteger = 0EF01h

REM 5th Keyboard ROW half
const KEY5        AS UInteger = 0F710h
const KEY4        AS UInteger = 0F708h
const KEY3        AS UInteger = 0F704h
const KEY2        AS UInteger = 0F702h
const KEY1        AS UInteger = 0F701h

REM 6th Keyboard ROW half
const KEYT        AS UInteger = 0FB10h
const KEYR        AS UInteger = 0FB08h
const KEYE        AS UInteger = 0FB04h
const KEYW        AS UInteger = 0FB02h
const KEYQ        AS UInteger = 0FB01h

REM 7th Keyboard ROW half
const KEYG        AS UInteger = 0FD10h
const KEYF        AS UInteger = 0FD08h
const KEYD        AS UInteger = 0FD04h
const KEYS        AS UInteger = 0FD02h
const KEYA        AS UInteger = 0FD01h

REM 8th Keyboard ROW half
const KEYV        AS UInteger = 0FE10h
const KEYC        AS UInteger = 0FE08h
const KEYX        AS UInteger = 0FE04h
const KEYZ        AS UInteger = 0FE02h
const KEYCAPS     AS UInteger = 0FE01h
```

## See Also

 * [INKEY$](../inkey.md)
