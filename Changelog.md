[v1.13.2](https://github.com/boriel/zxbasic/tree/v1.13.2)
===
+ ! Fix bug with optimizer
+ ! Fix crash with some syntax errors
+ ! Allow { and } in ASM for 3rd party assemblers
+ Other minor bugfixes

[v1.13.1](https://github.com/boriel/zxbasic/tree/v1.13.1)
===
+ ! Fix bug with LEN()

[v1.13.0](https://github.com/boriel/zxbasic/tree/v1.13.0)
===
+ ! Fix potential endless compiling
+ ! Fix several bugs unused functions
+ ! Fix bug with SAVE DATA
+ Add 2 extra optimization patterns
+ ! Fix bug with include file names on warnings
+ Add --arch=<architecture>, start of ZX Next backend!

[v1.12.1](https://github.com/boriel/zxbasic/tree/v1.12.1)
===
+ ! Fix Mac OS native package
+ ! Fix bug with DIM var AT @label (or any constant expr)
+ Other minor cosmetic changes in libraries

[v1.12.0](https://github.com/boriel/zxbasic/tree/v1.12.0)
===
+ Improved documentation
+ New binary releases now available for Linux and Mac OS!
+ Added new library for Windows scrolling

[v1.11.1](https://github.com/boriel/zxbasic/tree/v1.11.1)
===
+ ! Fix bug with constant LBOUND / UBOUND usage in array parameters

[v1.11.0](https://github.com/boriel/zxbasic/tree/v1.11.0)
===
+ Allow passing arrays as parameters byRef!
+ ! Several bugfixes and improved stability and code cleanup
+ Add PRINTFXZ by Eunar Saukas and Andrew Owen (ported by Britlion)

[v1.10.3](https://github.com/boriel/zxbasic/tree/v1.10.3)
===
+ ! Bugfixes and improved stability
+ Internal refactors in code. Also -d (debug) behaviour updated

[v1.10.2](https://github.com/boriel/zxbasic/tree/v1.10.2)
===
+ ! Fix a critical bug with local arrays

[v1.10.1](https://github.com/boriel/zxbasic/tree/v1.10.1)
===
+ Deprecating `zxb` executable in favour of `zxbc`
+ ! Many bugs fixed (CODE, VAL, preprocessor...)
+ ! Improved stability
+ Can now hide LOAD messages using -D HIDE_LOAD_MSG
+ Improved Windows deployment
+ Fixes a Warning for python 3.8.x

[v1.10.0](https://github.com/boriel/zxbasic/tree/v1.10.0)
===
+ ! Fix warning in arrays boundaries checks
+ Added support for ZX Next extended ASM instruction set
+ Allow shifting SCREEN coordinates for drawing
+ Add mini-pacman example
+ Add tool for viewing .SCR files
+ Improved compatibility with Sinclair BASIC (--sinclair)
+ Updates testing and parsing tools
+ Code generation optimized
+ Many bugfixes and improved stability
+ Updates in online documentation

[v1.9.9](https://github.com/boriel/zxbasic/tree/v1.9.9)
===
+ ! Fix warning in parameters ByRef
+ Makes LOAD and SAVE to ignore BREAK
+ ! Little bug fixes and better stability
+ Some docs and README fixes and improvements

[v1.9.8](https://github.com/boriel/zxbasic/tree/v1.9.8)
===
+ ! Fix memory leak bug when doing procrustean substring assignation
+ Also optimizes substring access not allocating mem when not needed

[v1.9.7](https://github.com/boriel/zxbasic/tree/v1.9.7)
===
+ Allow some extra chars within the ASM sections for 3rd party assemblers
+ ! Little bugfixes
+ Now printing at the end scrolls up the screen!

[v1.9.6](https://github.com/boriel/zxbasic/tree/v1.9.6)
===
+ ! Bugfix: grammar errors for RESTORE
+ Change LD (IX/IY + NN), r instructions to standardize it

[v1.9.5](https://github.com/boriel/zxbasic/tree/v1.9.5)
===
+ ! Bugfix: error compiling to binary with headerless mode (thx to em00k)
+ ! Bugfix: fixes several crashes under some conditions

[v1.9.4](https://github.com/boriel/zxbasic/tree/v1.9.4)
===
+ ! Bugfix: Fixes escape code for backslash (thx to em00k)

[v1.9.3](https://github.com/boriel/zxbasic/tree/v1.9.3)
===
+ ! Bugfix: fixes some bugs in the parser to improve stability.

[v1.9.2](https://github.com/boriel/zxbasic/tree/v1.9.2)
===
+ ! Bugfix: fixes a bug in the optimizer (-O3 and -O4)
+ Add `fastplot.bas` library

[v1.9.1](https://github.com/boriel/zxbasic/tree/v1.9.1)
===
+ ! Bugfix: array access read / write might overflow. Fixed.
+ Array access speedup and optimization.
+ Dropped support for PyPy and Python 2.x

[v1.9.0](https://github.com/boriel/zxbasic/tree/v1.9.0)
===
+ New and completely refactored optimizer which now allow patterns.<br />
  This new optimizer (after a year of hard work) not only optimizes better,<br />
  it also allows to specify new optimization patterns without touching the compiler code.
+ New optimizer level -O4 (peephole)
+ zxbasm (assembler) now allows several instructions per line using `:`
+ zxbasm allows labels to be declared without using colon.
+ Some other little optimization

[v1.8.10](https://github.com/boriel/zxbasic/tree/v1.8.10)
===
+ ! Bugfix: `FLASH 8` and `BRIGHT 8` were not working correctly. Fixed.
+ Changelog file renamed to `Changelog.md` and renovated. Now uses Markdown.
+ `PLOT`, `DRAW` and `CIRCLE` now do not use the ROM for ATTR (no ROM dependency)
+ ! Bugfix: Setting multiple `ORG` within ASM blocks crashed the compiler. Fixed.
+ Change code style to pass more flake8 tests
+ Add `--append-binary` command line flag to append binaries to tape file
+ Add `--append-headless-binary` cmdlie flag to do like the above, but headless. 

[v1.8.9](https://github.com/boriel/zxbasic/tree/v1.8.9)
===
+ ! Bugfix: Crash in `READ` and `DATA` sentences under some cases
+ ! Bugfix: Fix `INT` to behave like the original one (Round to -INF)
+ ! Bugfix: `--array-check` was not working properly. Fixed!

[v1.8.8](https://github.com/boriel/zxbasic/tree/v1.8.8)
===
+ ! Bugfix: fix 32 bit operations (`DIV`, `MOD`...)

[v1.8.7](https://github.com/boriel/zxbasic/tree/v1.8.7)
===
+ ! Bugfix: do not remove ASM blocks (optimize)

[v1.8.6](https://github.com/boriel/zxbasic/tree/v1.8.6)
===
+ ! Bugfix: `END` instruction was not returning result. Fixed.

[v1.8.5](https://github.com/boriel/zxbasic/tree/v1.8.5)
===
+ ! Bugfix: crash on bad array declaration

[v1.8.4](https://github.com/boriel/zxbasic/tree/v1.8.4)
===
+ ! Several bugfixes with contants declaration
+ Suport for UTF-8 BOM files
+ ! Bugfixes with `-O3` crash
+ ! Fixes crash with arrays
+ ! Other bugfixes and better stability
+ Better warning explanation under some circumstances

[v1.8.3](https://github.com/boriel/zxbasic/tree/v1.8.3)
===
+ ! Bugfix in the peephole optimizer (`-O2`)
+ ! Several bugfixes to improve stability
+ Optimization in the peephole optimizer (`-O1`)
+ Support for extended array str element operations
+ ! Other syntax bugfixes

[v1.8.2](https://github.com/boriel/zxbasic/tree/v1.8.2)
===
+ ! Bugfixes in the peephole optimizer
+ Shorter and faster generated code (deep optimizations)
+ ! Bugfix in the `PRINT42` routine that now supports newlines, etc
+ Implemented routine `input42` (`INPUT42.BAS`) for `PRINT42` mode

[v1.8.1](https://github.com/boriel/zxbasic/tree/v1.8.1)
===
+ ! Bugfixes in the peephole optimizer
+ ! Bugfix in `OUT` instruction
+ Fixes minor errors and bugs (i.e. `--enable-break`)
+ Improved and faster generated code (`IN`, `OUT`, `AND`, check BREAK...)
* Added `basic.bas` library (meta-interpreter) and `eval.bas` example!!
  (thanks to @mcleod_ideafix!!!)

[v1.8.0](https://github.com/boriel/zxbasic/tree/v1.8.0)
===
+ ! Bugfixes in the peephole optimizer (`-O3`)
+ Better optimized code
+ Improved compiling speed and more stability
+ Fixes minor errors and bugs
+ Now single line `IF` sentences does not require `END IF`

[v1.7.2](https://github.com/boriel/zxbasic/tree/v1.7.2)
===
+ ! Bugfixes in libraries `esxdos.bas` and `memcopy.bas`
+ Improved `pong.bas` example
+ Improved readme file :) (thanks to @harko and @haplo)

[v1.7.1](https://github.com/boriel/zxbasic/tree/v1.7.1)
===
+ ! Bugfixes with `-O3` and `DATA` statements
+ Little improvements
+ Updates `README.md` file and added `TESTING.md` one.

[v1.7.0](https://github.com/boriel/zxbasic/tree/v1.7.0)
===
+ Added `READ`, `DATA`, `RESTORE` (finally!)
+ Allows to call SUBs with no parenthesis (e.g. `mySUB 1, 2+a`)
+ Allows to call FUNCTIONS with 1 or no params with no parenthesis (e.g. `MyFunc x+2`)
+ Some bug fixes for better stability

[v1.6.13](https://github.com/boriel/zxbasic/tree/v1.6.13)
===
+ ! Fixes and improves strict mode checking
+ Adds `#error` and `#warning` directives

[v1.6.12](https://github.com/boriel/zxbasic/tree/v1.6.12)
===
+ Adds missing default font (Haplo) for Radastan mode
+ ! Bugfixes and little improvements

[v1.6.11](https://github.com/boriel/zxbasic/tree/v1.6.11)
===
+ ! Fix infinite recursive include in Windows OS (yes, win sucks)
+ Little optimizations in `memset()` and `RND`
+ Standardize file includes like in cpp

[v1.6.10](https://github.com/boriel/zxbasic/tree/v1.6.10)
===
+ Added many more drawing primitives for Radastan Mode
+ Added instructions `ON .. GOTO` and `ON .. GOSUB`
+ Added UART library (by yomboprime) for serial communication 
+ ! Several bugfixes and minor errors and better stability
+ Better code generation
+ Allows array initialization with @label references
+ Switch `.bas` libraries (not the compiler) to **MIT license**

[v1.6.9](https://github.com/boriel/zxbasic/tree/v1.6.9)
===
+ ! Fixes a bug in the peephole (`-O3`) optimizer
+ Improved speed for `Integer` / `Unteger` operations
+ Improved speed for `Byte` / `Ubyte` operations
+ Improved speed for some 32 bit operations (`Ulong`, `Long`, `Fixed`)
+ Improved code speed for `-O3` optimized level
+ Improved travis and bitbucket pipelines CI (cache, added pypy)
+ ! Fixes and improvements to the ESXDOS library (by @mcleod_ideafix)
+ Added new ESXDOS sample program (directory tree listing)

[v1.6.8](https://github.com/boriel/zxbasic/tree/v1.6.8)
===
+ ! Fixed some bugs in the assembler
+ ! Fixed a bug when calling a function in advance
+ ! Fixed a problem in tox, setting the terminal to UTF-8

[v1.6.7](https://github.com/boriel/zxbasic/tree/v1.6.7)
===
+ Added more testing and bitbucket pipelines using tox
+ ! Do not optimize user inlined ASM. It must go as is.
+ Added option `--mmap` to generate memory maps
+ Added option `--ignore-case` to allow variable names to be case insensitive
+ ! Fixes optimizer bugs
+ ! Fix to make make it to work in python 2.7
+ ! Refactorize the assembler to use centralized configuration

[v1.6.6](https://github.com/boriel/zxbasic/tree/v1.6.6)
===
+ ! Fixed a bug in constant evaluation
+ ! Allows non constant initialization of scalar variables like DIM a$ = "hi"
+ ! Fix bugs in the assembler not allowing complex expressions
+ ! Fix a rare crash when using functions before declaring them

[v1.4.0.x](https://github.com/boriel/zxbasic/tree/v1.4.0.x)
===

This is a long (near 3 year) set of versions in which the compiler
was refactored in many places. The compiler migrated from one-pass
no objects compiler to a multiple pass object like compiler.
This not only makes the code much more maintainable and elegant, but
also a bit faster.

Technical stuff:
Now the AST uses an heterogeneous AST pattern, allowing both children
traversal using indexes (and also primitives like `node.appendChild`)
and attribute traversal which depends on the `symbolTYPE` being parsed.
e.g. for `symbolBINARY` (binary expressions), we have `node.left`, `node.right`,
`node.operand`, but also `node.children[0]`, `node.children[1]`.

The major feature in this release is the posibility to declare nested functions.
These functions are declared within others, and can only be called from within
their respective parent function body.

[v1.3.0](https://github.com/boriel/zxbasic/tree/v1.3.0)
===
+ ! Fixed a bug in `USR <string>`
+ ! Fixed a bug in `SAVE` / `LOAD`
+ ! Fixed a serious bug in the preprocessor
+ ! Fixed a bug with `DIM` and constants
+ ! Fixed a bug with `SHL`/`SHR` for 0 shifts
+ Added `-D` option. ZXBasic now allows commandline macro definition
+ ! Fixed a bug with `CODE` and `INKEY$`
+ ! Fixed a bug with string slicing assignation (e.g. `a$(3) = "x"`)
+ ! Fixed a bug with arrays of integer assignation (e.g. `a(3) = 5`, being a of Integer type)
+ ! Fixed a bug with peephole optimizer (`-O3`)
+ Some changes and code refactorization towards 2.x branch

[v1.2.9](https://github.com/boriel/zxbasic/tree/v1.2.9)
===
+ ! Fixed a serious bug with ALL integer (signed/unsigned) operands
  which were not working correctly under some circumstances.
+ ! Fixed some bugs which made the compiler to crash when a syntax error is found.
+ ! Fixed a bug in `ALIGN` (assembler)
+ ZXBasic python version is now PyPy compatible.
+ `RND` is now MUCH faster and produces better random patterns (thanks to Britlion)
+ Compiler speed is now almost 100% faster!
+ Some code optimization
+ Added a recursive pattern fill library with an example (thanks to Britlion)
+ Fixed some bugs in the preprocessor which prevented some chars to be written
+ Fixed a bug with `PRINT` and comma position
+ Fixed a bug in `PEEK` which was related to the backend
+ Fixed more than 50 other minor bugs in both the compiler and the assembler
+ `THEN` keyword is now optional in `IF` statements

[v1.2.8](https://github.com/boriel/zxbasic/tree/v1.2.8)
===
+ Code rearranged and restructured for future deep refactorizations.
+ ! Complete rewritten backend (or almost!) to fix a bug in code
  generation which was being suboptimal.<br />Now generated code is
  much faster and take less memory than before!
+ Added support for Bitwise syntax (`|`, `&`, `~`)
+ Fixed some bugs in ASM
+ ! Fixed some bugs in the peephole optimized (`-O3`)
+ ! Fixed a bug with line continuation comments /' ...
+ ! Fixed bugs in ASM parser regarding to comments
+ Added `ATTRADDR()` function in `<attrib.bas>`
+ ! Many more bugs fixed related to `STRING` memory leak
+ ! Fixed a bug related to parameters.
+ Some optimizations for code size and speed for `FLOAT` types
+ Optimization for `STRING` parameters
+ Optimization for 32 bit values
+ ! Fixed a bug for `Uinteger`/`Integer` arrays assignation
+ ! Fixed 2 bugs in `CAST` operation and type conversion
+ ! Fixed a bug in `OVER` attribute during `PRINT`
+ Added PONG game example
+ ! Fixed a bug in `POKE`
+ ! `PRINT` optimized and slightly faster. Now fully compatible with
  **Sinclair Basic** (no *Out of Screen*  error on program exit)
+ ! `CSRLN` and `POS` optimized to this new `PRINT` scheme!
... and much much more

[v1.2.7](https://github.com/boriel/zxbasic/tree/v1.2.7)
===
+ `DRAW` is now much faster (and a bit more larger)
+ `PLOT`, `DRAW` and `CIRCLE` now supports change screen address (for double-buffering)
+ Added `LBOUND()` and `UBOUND()` functions
+ ! Fixed a bug in `IF`/`THEN`/`ELSEIF`/`ELSE` construct (thanks to LTee)
+ Added a completely new preprocessor which now support true macros and
  better line counting handling. This is a major change in the compiler.
+ Added string management library with `UCase()`, `LCase()`, `Ucase2()`, `LCase2()`, `InStr()` and `StrPos()`
+ ! UDG where not being handled into the Heap, which might lead to program
  crash (fixed). This is done only if `--sinclair` or `-Z` cmdline flag is used.
+ Added support for `BIN`, so `BIN 01010101` is also accepted now.
+ ! Fixed a bug with string parameters passed by value (again) not being correctly
  free upon return and crashing the program.
+ `BEEP` with constant duration and pitch (e.g. `BEEP 1, 2`) has been
  optimized for space (and also slightly faster)
+ Added Flight Simulator example

[v1.2.6](https://github.com/boriel/zxbasic/tree/v1.2.6)
===
+ Bitwise `bAND`, `bOR`, `bXOR`, `bNOT` finally added for 8, 16 and 32 bits
+ The assembler now supports `ALIGN <integer>` directive
+ Added support for logical `XOR` (`IF A XOR B THEN`...)
+ Added support for checking out of memory in runtime (`--debug-memory`)
+ Added support for checking BREAK in runtime (`--enable-break`)
+ Added support for Subscript Out of Range in runtime (`--debug-array`)
+ Added support for `--strict-boolean` (0 or 1) values
+ Added `print64()` by Britlion library routine, and Mojon Twins FourSpriter version (more to come).
+ Fixed a bug in `RANDOMIZE` which wasn't updating the seed correctly.
+ Fixed a pragma typo in `POS.bas` library which lead to errors.
+ ! Fixed a bug in `STR$`, `VAL`, `CHR$` and `CODE` which could crash the program.
+ ! Fixed a bug in string comparison
+ ! Fixed 2 more bugs in the peephole optimizer (`-O3`) which could crash the program.
+ ! Fixed some syntax bugs. `PI()` and `RND()` are now allowed.<br />
  Calling functions with no parenthesis is allowed too.
+ ! Fixed a parser bug in which empty `WHILE` / `DO` .. `LOOP` loops crashed the compiler. Fixed.
+ ! Array access has been optimized for speed. Now faster.
+ ! For loops have been slightly optimized.
+ ! MEM_FREE heap routine has been slightly optimized.
+ The `print*` intermediate code instructions have been removed and converted to routines.
+ Lot of code refactoring, and moved to the standard trunk/tag/branches SVN repository scheme.
+ String expressions are now standardized (like any other data type).
+ TDD: Begin to create tests cases for the compiler.

v1.2.5
===

##### Assembler:
+ ! Under some pathological cases, compiling or assembling will last for exponential time (minutes to hours!),
  due to a possible bug/misuse of a regular expression. Fixed. Now it takes linear time.
+ Added support for `IXh`, `IXl`, `IYh`, `IYl` registers.
+ Added support for `DEFS` macro. Now `DEFS n, B` creates a block of n times byte B
+ ! Instructions `LD A, R` and `LD R, A` where also missing. Fixed.

##### Compiler
+ ! The optimizer -O2 was broken, and contained 3 bugs. Fixed.
+ ! The optimizer -O3 was broken, and contained more than 15 bugs. It's been almost completely rewritten.<br />
  Fixed. Now it even tries to optimize ASM users code.
+ ! The @operator was broken under some circumstances (array accesses and variables). Fixed.
+ ! The memory heap was also broken almost always when using any string in the program (INKEY$, STR$, CHR$, $ variables). Fixed.
+ ! Signed LONG division was wrong for positive divisors. Fixed.
+ ! Byte comparison operators < > = >= <= were sometimes bugged. Fixed.
+ ! using MOD with Fixed type was unsupported. Fixed. Now MOD used Fixed type.
+ ! INT(Fixed) was wrong. Fixed.
 ! Temporary attributes BOLD and ITALIC were disabled. Now they are back.

v1.2.4
===
* Added `SAVE`/`LOAD`/`VERIFY` `CODE`/`SCREEN$` capabilities (uses ROM routines)
* Fixed a bug in `@ `operand which produced a memory leak

v1.2.3
===
* ! `CHR$` and `STR$` might not use the HEAP without initializing
  it first, leading to memory corruption. Fixed. Thanks to Britlion.
* HEAP size can now be set with a command line parameter.

v1.2.2
===
* ! `DIM` with array base was buggy. Fixed.
* ! `INK 8` and `PAPER 8` were being ignored. Now they work.

v1.2.0
===
* ! `DIM f% = <value>` was not working. Now it does.
* ! HEAP memory init routine slightly improved.
  Also removed a possible bug of memory corruption reported
  by Britlion. (Thanks)
* New memory scheme: Now variables and heap zone are moved
  to the end of the memory (high area). This should make
  easier to implement data bank switching on 128K machines.
  It also allows to `SAVE` all data memory in a single block.
  This is a feature to be implemented in near-future releases.
* ! Undeclared local variables caused a compiler error.
  They should just compile (like global ones do).
* ! String variables used in string slices where sometimes
  optimized (ignored).
* ! `ELSEIF` constructions were not being compiled correctly.

v1.1.9
===
+ ! Fixed a bug for constant string slicing, so
  `"0909"(A TO B)` now works. Thanks to Britlion.
+ ! Expanded grammar to allow something like `"0909"(f)`
  or `"0909"()` which are also allowed in **Sinclair Basic**. Thanks to Britlion.
+ ! Using expressions like `"0909"(f)` (like above) might corrupt the
  HEAP memory, leading to a program crash. Fixed. Thanks, Britlion :-)
+ ! Fixed a bug in typecast from signed integers to float which
  sometimes overflowed leading to wrong results.

v1.1.8
===
+ ! `%` suffix was being ignored. Fixed.
+ ! Global string variables were not optimized unless declared
  with `$` suffix. Fixed.

v1.1.7
===
+ ! `BOLD` and `ITALIC` could not be used as permanent attributes,
  only as temporary ones. Now they are allowed as permanent too.
+ Some more syntax compatibility with **Sinclair BASIC**. Expressions
  like `F$(5)` and `PRINT ;;;` are now allowed.
+ ! Single `PRINT` sentences were not working (they should print a
  newline).
+ Minor grammar corrections.
+ ! Using a suffix like `$` in a function declaration was being
  ignored. Now it's taken into account.
+ Added support for `PRINT ,` (thanks to Britlion and LCD for the
  suggestions and bug detection)
* Fixed a potential optimization bug for `SHR` and `SHL`

v1.1.6
===
+ ! Fixed many optimization bugs (almost five). Thanks to LCD
+ ! Fixed ChangeLog file
+  Internal refactored code (somewhat)

v1.1.5
===
+ Added the `ELSEIF` construct to the `IF THEN ELSE` sentence
+ Added more optimizations in some jumps
+ Added the `USR` function (both for Strings and Floats)
+ Optimized some print string generated code (now it's smaller)

v1.1.4
===
+ The peephole optimizer has been enabled and seems to be working
  reasonably well.
+ ! When a DIV BY ZERO error occurs with floating point numbers the program
  crashes and resets the computer. This behaviour has been fixed
  and now returns 0 value and sets the error code 6 (Number Too big)
  in the `ERR_NR` system variable.
+ Refactorization of both the assembler and compiler so they now
  shared the OPTIONS storage in a better way (still to be finished). This
  makes easier to program future compiler options. Now also `--debug`
  flag is additive, showing more verbosity the more it is used.
+ Memory optimization: `PRINT` routine (which is about 1K size) is not
  included if not USED.

v1.1.2
===
+ ! Fixed a bug in negative constant integer typecasting (Thanks to LCD
  at WoS for reporting it! `;-)`). It was causing decremental `FOR`..`NEXT`
  to fail.
+ ! Scientific notation numbers (e.g. `2e10`) were not correctly parsed.
  Fixed. Thanks again to LCD. ;-)
+ Added `TAB` compatibility for the `PRINT` command (both as a command
  and as a `CHR$` control character).
+ `PRINT` code optimized for size, maintaining speed.

v1.1.1
===
+ ! Fixed a bug in `CONTINUE DO` which was not being correctly compiled
+ `PRINT` routines were included even when neither PRINT nor
  drawing primitives were used. Optimized.
+ ! Fixed a lot of syntax error checks with array operations.
+ ! Fixed array dimension checking
+ Expanded syntax: Direct array assignation `a = b` (being a and b
  arrays of the same type an size)
+ ! Fixes an error exception on syntax error for array subscripting.
+ Changed alloc functions to match names of that of FreeBASIC ones.
+ Using a wrong sigil in array declaration is now forbidden.
+  Better sigils (suffixes) types managements at `DIM` declarations.
+ Lot of internal source code refactoring
+ `DIM r AT @a(k0, k1, ...)` is allowed (being k0, k1, ... constants)
+! Fixed a bug for local variables and parameters when the offset is
  very large (> 128)
+ Enabled the `--sinclair` cmdline flag for automatic sinclair libraries inclusion
+ Added `SetAttr()` routine which changes the attribute of
  screen coordinate at (I, J) with the given color attr value.
+ ! Fixed buggy `modu16` and `modi16` IC implementation that was not compiling
  correctly
+ Output asm code is now slightly optimized (for speed an memory)
+ ! Fixed a bug in integer parameters (16 and 32 bits)
+ ! Fixed a compiler crash when using arrays of Fixed Point numbers

v1.1.0
===
* SCREEN$ coordinated were swapped. Fixed.
* DIM .. AT was not correctly working with local vars nor params. Fixed.
+ Added BOLD "attribute". PRINT BOLD 1; "Hello"
+ Added ITALIC "attribute". PRINT ITALIC 1; "Hello"
+ Added malloc, free and realloc functions to work with the heap
* Some code rearrangement
* The IFDEF directive was not working in the preprocessor. Fixed.


v1.0.9
===
+ Fixed a bug which could crash the program if no memory
+ Added better error handling for parameter declaration
+ Added `UCase` function
+ Added `Lcase` and fixed ucase to be case insensitive
+ Added `MultiKeys` function (similar to that of FreeBASIC) so
  multiple keys can be checked at once
+ Added `GetKeyScanCodes`
+ Added HEX and HEX16 functions to return HEXadecimal
  string representation of numbers
+ Fixed a bug when `a$(n TO)` was specified
+ ! Optimization: Remove unnecessary jumps at function returns.
+ ! `store16` IC instruction now generates a more efficient backend (Z80 ASM) code.
+ Added alias for arrays. Now you can declare:
  ```
  DIM a(10)
  DIM c at @a
  ```
+ ! Better code generation for `store32` and `storef` backend
+ ! Optimized constant array assignation as a direct store.
+ ! Added constant array Read access optimizations
