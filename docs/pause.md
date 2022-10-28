#PAUSE

##Syntax
```
PAUSE <value>
```

Just as in Sinclair basic, this command pauses the execution for the given number of frames
(1 frame equals to 1/50th of second in Europe, 1/60th of second in the US: this is usually in
sync with the electricity AC frecuency) or until a key is pressed.

Bear in mind the number 0 is actually taken as 65536.
Currently this sentence uses the Sinclair BASIC ROM, so **it needs interruptions enabled**.

Example:

```
PRINT "Press any key"
PAUSE 0: REM waits for a Key pressed or for 65536 frames
```

##Remarks
* This function is 100% Sinclair BASIC compatible.
