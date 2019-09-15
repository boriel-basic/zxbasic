#DECLARE


ZX BASIC is a single pass compiler - that means it goes through your source code once and only once 
when reading your program code and compiling. Unfortunately, this method does lead to some issues when
calling [SUB](sub.md) and [FUNCTION](function.md) code. If a FUNCTION is not defined prior to being called,
the compiler neither knows what its return type nor knows parameter types, or whether you are calling the
SUB/FUNCTION correctly. The compiler, in this case, assumes the function returns the compiler's largest type:
a float. This is often incorrect and suboptimal.

Traditionally, in compiler design, there are several ways to fix this problem.
One is to have the compiler run two passes through the code; picking up the SUB/FUNCTION definitions as it goes,
then a second pass to compile. On the original ZX spectrum, most BASIC compilers were multipass
to allow for this information gathering. 

ZX BASIC remains single pass, which means there are two options open to you the programmer.
The first is to define all functions before they are used; for example, at the start of the code.
This method does work fine, but perhaps limits where you want to put functions in memory.

The second option is to use the DECLARE keyword. This way, the programmer can tell the compiler about a function
in advance before it is used, and before it is fully defined with the [FUNCTION](function.md) keyword.
Putting a DECLARE statement at the start of your code tells the compiler about the function that is defined later on.
In essence, you are making a promise to define it later. This fully defines the return type for the function,
so the receiving code can be built to work with that. It also, in theory, allows the compiler to have information
about the function and enable it to trap errors in use of the function.

##Syntax

```
DECLARE <function_name> [(<parameter_list>)] AS <return_type>
```


##Examples

```
Declare Function myFunction(n As Ubyte) As Ubyte

REM Now you can call myFunction
PRINT myFunction(32): REM This print 33

REM Now implements myFunction 
Function myFunction(n As Ubyte) As UByte
    Return n + 1
End Function
```

##See Also
* [FUNCTION](function.md)
* [SUB](sub.md)


