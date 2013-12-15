DIM a As Ubyte = 1

#define MyMacro  \
    PRINT a; " MACRO START" \
    ASM \
    ld hl, _a \
    inc (hl) \
    END ASM \
    PRINT a; " MACRO END"

PRINT "HELLO WORLD"
MyMacro

