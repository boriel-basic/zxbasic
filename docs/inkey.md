# INKEY / INKEY$

The `INKEY` function is used to return a value of a keypress at the moment the function is accessed.
Inkey does not wait for user input. It returns a single character string containing the key pressed.
Use of Shift or Caps-Lock makes the character upper case. In some cases, a non-printable string may be returned;
for example if cursor keys are pressed at the time the function is run.

If no key is pressed, it returns a null string (`""`).

For compatibility with Sinclair Basic, `INKEY$` is also a valid synonym.


```
WHILE INKEY <> CHR(13) : REM CHR(13) is the code for the ENTER key
 PRINT INKEY; : REM PRINTS A KEYPRESS

 WHILE INKEY<>""
  REM WAIT Until the key isn't pressed any more.
 END WHILE

END WHILE
```


The above code will echo keys pressed to the screen. Note that the loop has to be held up to wait until the key is no longer pressed, in order to prevent the same character being reprinted many times.

## Remarks
* This sentence is 100% Sinclair BASIC Compatible
