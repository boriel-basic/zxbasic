#RANDOMIZE

##Syntax

```
RANDOMIZE
RANDOMIZE <number>
```

##Description

Sets the random seed to the given number. If no number is given, the seed
is taken from the FRAMES counter (timer) variable.

Using RANDOMIZE at least once in the program prevents the pseudorandom generated
sequence to be always the same.

On the other hand, if a given fixed number is used as a seed, the sequence will be always the same.
This is useful to produce predictable sequences (i.e. for testing).

##Example


```
REM Sets a random sequence
RANDOMIZE 10
FOR i = 1 TO 10: PRINT RND * 10; " "; NEXT i: PRINT

REM Repeat the pseudorandom sequence
RANDOMIZE 10
FOR i = 1 TO 10: PRINT RND * 10; " "; NEXT i: PRINT
```

##Remarks
This instruction is Sinclair BASIC compatible but the pseudorandom sequences
generated are not the same.

##See also

* [RND](rnd.md)
