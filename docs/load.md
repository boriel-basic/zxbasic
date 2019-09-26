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

With no varname saves ALL the entire user variable variable área plus the HEAP memory zone.
That is, it saves all the program state. You can also use `LOAD`/`VERIFY` with this.

##Remarks
* The save command should save bytes in a format that is 100% Sinclair BASIC Compatible
* For `LOAD` and `VERIFY`, when a R-Tape Loading error occurs, the program will not stop.
  You have to check PEEK 23610 (ERR_NR) for value 26. If that value exists, then the `LOAD`/`VERIFY` operation failed.
* At this moment, `LOAD`/`SAVE`/`VERIFY` can be interrupted by the user by pressing BREAK/Space,
  which exits the program and returns to the ROM BASIC. This may be changed in the future to behave like
  the previous point (signaling the break in `ERR_NR` and returning).
* When using `LOAD "xxx" DATA...` you won't see the message
  _"Number array:"_ or _"Char array:"_, but _"Bytes:"_ instead.
  This is because ZX BASIC always uses bytes (`LOAD`/`SAVE ... CODE`) for storing user variables
  (ZX BASIC is machine code, so the idea of BASIC variables doesn't apply).
