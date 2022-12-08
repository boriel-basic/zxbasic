# Labels

Labels are [identifiers](identifier.md) where the program execution flow can _jump_ into using either [GO TO](goto.md) or [GO SUB](gosub.md).
Unlike [variables](types.md) identifiers, their [scope](scope.md) is **always global** (even if declared inside 
functions or subroutines). Usage of labels is discouraged.

In ZX BASIC, line numbers are treated as labels:

```
10 REM An endless print loop
20 PRINT "Hello world!"
30 GO TO 20
```

Since line numbers are _just labels_, the order sequence is irrelevant.
The following listing is equivalent to the above one. Notice the 
out-of-order line sequence:

```
10 REM An endless print loop
30 PRINT "Hello world!"
20 GO TO 30
```


### Declaring labels

Identifiers can be used as labels.
A label identifier is declared by writing it at the beginning of a line, followed by a colon:

```
REM Declaring a label
mylabel:
```

You can _use_ the label with [GO TO](goto.md) and [GO SUB](gosub.md) sentences,
and with the [@ operator](operators.md#-operator): the previous example can be rewritten using labels instead of line numbers:

```
endlessloop:
  PRINT "Hello world!"
  GO TO endlessloop
```

A label can also be referred before it has been declared:

```
  GO TO EndOfRoutine
  REM Instructions here are skipped

EndOfRoutine:
  PRINT "End Of Routine"
```
