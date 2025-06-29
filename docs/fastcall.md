# FASTCALL

`FastCall` is used to indicate that a [`SUB`](sub.md) or [`FUNCTION`](function.md) will follow the _FastCall_ Calling
Convention. In this convention, the 1<sup>st</sup> parameter of the function will come in the registers as follows:

* If the function takes a `Byte` (or `UByte`) parameter, then the `A` register will be set with this parameter.
* If it takes an `Integer` (or `UInteger`) parameter, then the `HL` register will be set with the value of that parameter
  on entry to the function.
* If it takes a `Long` (or `ULong`), or fixed parameter, then the `DE` and `HL` registers will
  hold the 32bit value of the parameter, where `HL` holds the lower 16 bits and `DE` the higher one.
* If it takes a `Float` type parameter, then the registers C, DE and HL will hold the five bytes for that value.
  Here, `C` is the exponent (excess 127), and `DEHL` the mantissa, being `DE` the highest 16 bits and `HL` the lower ones.

Return is automatic based on the function return type in the same way:
* 8bit returns should be in the A register
* 16bit returns should be in HL
* 32bit returns should be in DEHL
* 40bit FLOAT returns should be in CDEHL.

Strings are a 16bit `UInteger` pointer, hence the `HL` register will be used (both for parameters and return values)

`FastCall` should ONLY be used with functions that take a single parameter. If you use more than one parameter, the remaining
parameters will come in the stack. Upon return, you will have to deal with the stack (SP register) and restore it to the
state it had prior your function was called.

When entering the function, the stack will be as follows:

 * [SP + 00]: Return address. Top of the stack (16 bits)
 * [SP + 02]: 2<sup>nd</sup> parameter (if any)


## Example

```vbnet
FUNCTION FASTCALL whatLetter (A as uByte) as uByte
  Asm
            PROC
            LOCAL DATA, START
            JP START
  DATA:     DEFB "A Man, A Plan, A Canal, Panama"
  START:    LD HL,DATA
            LD D,0
            LD E,A
            ADD HL,DE
            LD A,(HL)
            ENDP
  End Asm
END FUNCTION
```

The above function, when called with `whatLetter(<value>)` will return the `<value>`-th letter of the phrase
`"A Man, A Plan, A Canal, Panama"`.

### Notes
* Note that the A register already contains `<value>` when the inline assembly is reached.
* Note that we do NOT need to put a ret opcode on the end of the assembly. The compiler will do that for us.

## See Also

 * [STDCALL](stdcall.md)
