# SUB


ZX Basic allows function and subroutines declarations. Sinclair Basic does not allow named subroutines, only calls with the GOSUB command.

A subroutine defined with the SUB statement is invoked directly. Unlike a [FUNCTION](function.md), a SUB does not return a value. This is the fundamental difference between code defined with SUB and code defined with FUNCTION. Other than that, the setup for SUB and FUNCTION are almost identical.

## Syntax
Basic function declaration is:

```
 SUB <subroutine name>[(<paramlist>)]
     <statements>
     ...
 END SUB
```

## Example

```
SUB printat (y as uByte, x as uByte, data$ as STRING)
  print at y,x,data$
END SUB
```

While this is a rather silly example, it shows how parameters can be passed into a SUB, just like a FUNCTION. No parameters are passed back.

A SUB can be exited with the return statement.

A SUB is an excellent way of wrapping machine code or data such that it does not interfere with program execution. Such data can be placed within a SUB but after a RETURN statement:


```
SUB setupUDG ()
 DIM i,j as uInteger
 LET j=@udgdata
 FOR i=USR "A" to USR "A"+7
  POKE i,PEEK j
 NEXT i
 RETURN

udgdata:
 ASM
  defb 1,2,3,4,5,6,7,8
 END ASM
END SUB
```


Again, this is a rather silly example - far better to point the UDG system variable at the data than copy it, but it does show how an ASM context can be hidden from the main program, and accessed with an @ label.

Finally, a SUB is an excellent way of running a pure machine code routine. FUNCTION can be used in a similar manner, if you wish to pass data back into the compiled basic, of course.

```
SUB routine ()
 ASM
  (your asm code goes here)
 END ASM
END SUB
```


## Memory Optimization
If you invoke zxbasic using -O1 (or higher) optimization flag the compiler will detect and ignore unused SUB's (thus saving memory space).
It will also issue a warning (perhaps you forgot to call it?), that can be ignored.


## See Also

* [FUNCTION](function.md)
* [ASM](asm.md)
* [END](end.md)
* [RETURN](return.md)
