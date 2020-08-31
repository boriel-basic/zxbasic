#LOAD

#SAVE, LOAD and VERIFY

##Syntax
```
SAVE "xxx" CODE START, LENGTH
SAVE "xxx" SCREEN$ [Note: This is the functional equivalent of SAVE "xxx" CODE 16384,6912 ]

LOAD "xxx" CODE
LOAD "xxx" CODE START
LOAD "xxx" CODE START, LENGTH
LOAD "xxx" SCREEN$

VERIFY "xxx" CODE
VERIFY "xxx" SCREEN$
```
The above commands work in a manner identical to Sinclair Basic.

```
SAVE "xxx" DATA <varname>( ) 
```
This behaves like the original Sinclair BASIC, but here you can save/load/verify not only arrays, but single variables.
Parenthesis can be omitted (in Sinclair BASIC they were mandatory). You can also use `LOAD`/`VERIFY` with this.

```
 SAVE "xxx" DATA 
```

With no varname saves ALL the entire user variable area plus the HEAP memory zone.
That is, it saves the entire program state. You can also use `LOAD`/`VERIFY` with this.

##Remarks
* The save command should save bytes in a format that is 100% Sinclair BASIC Compatible
* For `LOAD` and `VERIFY`, when a R-Tape Loading error occurs, the program will not stop.
  You have to check PEEK 23610 (ERR_NR) for value 26. If that value exists, then the `LOAD`/`VERIFY` operation failed.
* `LOAD`/`SAVE`/`VERIFY` can be interrupted by the user by pressing BREAK/Space,
  which cancels the operation (signaling the break in `ERR_NR` and returning). If you want `LOAD`/`SAVE`/`VERIFY` to be
  interrupted and exit also your program (returning to the ROM Basic), compile with `--enable-break` flag.
* When using `LOAD "xxx" DATA...` you won't see the message
  _"Number array:"_ or _"Char array:"_, but _"Bytes:"_ instead.
  This is because ZX BASIC always uses bytes (`LOAD`/`SAVE ... CODE`) for storing user variables
  (ZX BASIC is machine code, so the idea of BASIC variables doesn't apply).
