#Tools

##The ZX BASIC SDK

As you might already know, ZX BASIC is not a single program. It consist in 3 python (.py) programs that might be used standalone or not, depending on how they are invoked.

###ZXB
[ZXb](zxb.md) is the main compiler executable (for Windows you can use the .exe _converted_ version). It will compile a BASIC program into a binary file. At this moment, supported binary formats are: [TZX](http://www.worldofspectrum.org/TZXformat.html), [TAP](http://www.tjornov.dk/spectrum/faq/fileform.html#TAPZ)  and raw binary (.BIN) format.

Go to the [zxb page](zxb.md) for help on using the compiler.

###ZXBasm
[ZXbasm](zxbasm.md) is a cross-platform Z80 assembler. It will assemble plain ASCII files containing asm source code into the same formats described above. This tool is completely finished.

Go to the [zxbasm page](zxbasm.md) for help on using the assembler.

###ZXBpp
The [zxbpp](zxbpp.md) utility is a preprocessor which works in the same way as many C preprocessors (cpp) programs do. It is used both by [zxb](zxb.md) and [zxbasm](zxbasm.md). It basically filter an input file and produces a modified output one, by replacing macros and include files. If your used to C preprocessors (e.g. you've used Z88Dk), you will probably be very familiar with it.

Go to the [zxbpp page](zxbpp.md) for help on using the preprocessor.


