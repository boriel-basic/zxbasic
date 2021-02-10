# ZX0

This is an interface library for using data compressor [ZX0](https://github.com/einar-saukas/ZX0)
in ZX BASIC programs. For further details see:

[https://github.com/einar-saukas/ZX0](https://github.com/einar-saukas/ZX0)


## Syntax

Available functions:

```
dzx0Standard(src, dst)
dzx0StandardBack(src, dst)
dzx0Turbo(src, dst)
dzx0TurboBack(src, dst)
dzx0Mega(src, dst)
dzx0MegaBack(src, dst)
dzx0SmartRCS(src, dst)
dzx0SmartRCSBack(src, dst)
dzx0AgileRCS(src, dst)
```

Parameters:

* `src` - source address of the compressed data
* `dst` - destination address for the uncompressed data


## Usage

Include this library in your program:

```
#include <zx0.bas>
```

Afterwards you can use any of the available [ZX0](https://github.com/einar-saukas/ZX0) functions in 
your program. For instance:

```
dzx0Turbo(51200, 16384)
```

The [ZX0](https://github.com/einar-saukas/ZX0) decompressors can be freely used without restrictions, 
even in commercial programs. Just please remember to mention [ZX0](https://github.com/einar-saukas/ZX0)
in your documentation, as requested at the [ZX0](https://github.com/einar-saukas/ZX0) page.


## Examples

The following program will decompress a compressed RCS+ZX0 image directly to the screen:

```
introscr:
    asm
        incbin "intro.scr.rcs.zx0"
    end asm

#include "zx0.bas"

dzx0AgileRCS(@introscr, 16384)
```
