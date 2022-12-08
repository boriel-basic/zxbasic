# ASM


## Syntax


```
asm
  (z80 assembler code)
  ...
end asm
```

## Description

Starts immediate inline assembly context using standard z80 opcodes.
Use with caution.

## Examples

```
FUNCTION FASTCALL whatLetter (A as uByte) as uByte
   Asm
             JP START
   DATA:     DEFB "A Man, A Plan, A Canal, Panama"
   START:    LD HL,DATA
             LD E, A
             LD D, 0
             ADD HL, DE
             LD A, (HL)
   End Asm
END FUNCTION
```


The above function, when called with `whatLetter(<value>)` will return the `<value>`-th letter of the phrase
`"A Man, A Plan, A Canal, Panama"`.

## See also

* [ALIGN](asm/align.md)
* [FASTCALL](fastcall.md)
* [INCBIN](asm/incbin.md)
* [Inline Assembly](syntax.md#inline-assembly)
