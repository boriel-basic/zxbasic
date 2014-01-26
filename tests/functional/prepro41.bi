#define BIFROSTstop() \
    asm               \
        call 65012    \
    end asm

10 PAUSE 0 : BIFROSTstop() : PAUSE 0


