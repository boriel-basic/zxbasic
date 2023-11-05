REM PRINTFZX Example

#include <printfzx.bas>

CLS

printFzxSetFontAddr(@font1)
printFzxAt(70, 90)
printFzxStr("Big Bold Font")

printFzxSetFontAddr(@font2)
printFzxAt(90, 90)
printFzxStr("Cobra Font")
PAUSE 0
END : REM important to finish here or CPU will crash on next line

font1:
ASM
INCBIN "fzx_fonts/bigbold.fzx"
END ASM

font2:
ASM
INCBIN "fzx_fonts/cobra.fzx"
END ASM
