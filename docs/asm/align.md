# ALIGN


## Syntax 

```
ASM
ALIGN <n>
END ASM
``` 

## Description 

This works inside the ASM context, and is an assembler directive.
Moves assembling position forward so the next line begins assembling aligned with a multiple of the given parameter. Useful for aligning data with address and page boundaries. Be aware that this can in theory waste n-1 bytes of memory, as the assembled code can only be moved forwards. Use with caution.

## Examples 

```
ASM
 ALIGN 256
 DEFB 0,0,0,0,0,0
END ASM

ASM
 ALIGN 16384
 DEFS 256,0
END ASM
```
 
The first example will move compilation forward to match the next multiple of 256 bytes. This is useful in machine code routines as it matches a new "high byte" position in memory. That is to say that the data can be addressed by address ??00 - the low byte will be zero. This is often a key optimization for data tables and screen addressing routines.

Aligning to a 16K (16384) boundary might be useful in 128K programming.

