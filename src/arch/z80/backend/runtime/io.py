# I/O labels


from .namespace import NAMESPACE


class IOLabels:
    # Screen and attributes
    CLS = f"{NAMESPACE}.CLS"
    COPY_ATTR = f"{NAMESPACE}.COPY_ATTR"

    BOLD = f"{NAMESPACE}.BOLD"
    BRIGHT = f"{NAMESPACE}.BRIGHT"
    FLASH = f"{NAMESPACE}.FLASH"
    INK = f"{NAMESPACE}.INK"
    INVERSE = f"{NAMESPACE}.INVERSE"
    ITALIC = f"{NAMESPACE}.ITALIC"
    OVER = f"{NAMESPACE}.OVER"
    PAPER = f"{NAMESPACE}.PAPER"

    BOLD_TMP = f"{NAMESPACE}.BOLD_TMP"
    BRIGHT_TMP = f"{NAMESPACE}.BRIGHT_TMP"
    FLASH_TMP = f"{NAMESPACE}.FLASH_TMP"
    INK_TMP = f"{NAMESPACE}.INK_TMP"
    INVERSE_TMP = f"{NAMESPACE}.INVERSE_TMP"
    ITALIC_TMP = f"{NAMESPACE}.ITALIC_TMP"
    OVER_TMP = f"{NAMESPACE}.OVER_TMP"
    PAPER_TMP = f"{NAMESPACE}.PAPER_TMP"

    BORDER = f"{NAMESPACE}.BORDER"

    # Drawing primitives
    CIRCLE = f"{NAMESPACE}.CIRCLE"
    DRAW = f"{NAMESPACE}.DRAW"
    DRAW3 = f"{NAMESPACE}.DRAW3"
    PLOT = f"{NAMESPACE}.PLOT"

    # Keyboard
    INKEY = f"{NAMESPACE}.INKEY"

    # Print ("console")
    PRINTI16 = f"{NAMESPACE}.__PRINTI16"
    PRINTI32 = f"{NAMESPACE}.__PRINTI32"
    PRINTI8 = f"{NAMESPACE}.__PRINTI8"
    PRINTF = f"{NAMESPACE}.__PRINTF"
    PRINTF16 = f"{NAMESPACE}.__PRINTF16"
    PRINTSTR = f"{NAMESPACE}.__PRINTSTR"
    PRINTU16 = f"{NAMESPACE}.__PRINTU16"
    PRINTU32 = f"{NAMESPACE}.__PRINTU32"
    PRINTU8 = f"{NAMESPACE}.__PRINTU8"
    PRINT_AT = f"{NAMESPACE}.PRINT_AT"
    PRINT_COMMA = f"{NAMESPACE}.PRINT_COMMA"
    PRINT_EOL = f"{NAMESPACE}.PRINT_EOL"
    PRINT_EOL_ATTR = f"{NAMESPACE}.PRINT_EOL_ATTR"
    PRINT_TAB = f"{NAMESPACE}.PRINT_TAB"

    # Tape ("cassette routines")
    LOAD_CODE = f"{NAMESPACE}.LOAD_CODE"
    SAVE_CODE = f"{NAMESPACE}.SAVE_CODE"

    # Sound
    BEEP = f"{NAMESPACE}.BEEP"
    BEEPER = f"{NAMESPACE}.__BEEPER"


REQUIRED_MODULES = {
    IOLabels.CLS: "cls.asm",
    IOLabels.COPY_ATTR: "copy_attr.asm",
    IOLabels.BOLD: "bold.asm",
    IOLabels.BRIGHT: "bright.asm",
    IOLabels.FLASH: "flash.asm",
    IOLabels.INK: "ink.asm",
    IOLabels.INVERSE: "inverse.asm",
    IOLabels.ITALIC: "italic.asm",
    IOLabels.OVER: "over.asm",
    IOLabels.PAPER: "paper.asm",
    IOLabels.BOLD_TMP: "bold.asm",
    IOLabels.BRIGHT_TMP: "bright.asm",
    IOLabels.FLASH_TMP: "flash.asm",
    IOLabels.INK_TMP: "ink.asm",
    IOLabels.INVERSE_TMP: "inverse.asm",
    IOLabels.ITALIC_TMP: "italic.asm",
    IOLabels.OVER_TMP: "over.asm",
    IOLabels.PAPER_TMP: "paper.asm",
    IOLabels.BORDER: "border.asm",
    IOLabels.CIRCLE: "circle.asm",
    IOLabels.DRAW: "draw.asm",
    IOLabels.DRAW3: "draw3.asm",
    IOLabels.PLOT: "plot.asm",
    IOLabels.INKEY: "inkey.asm",
    IOLabels.LOAD_CODE: "load.asm",
    IOLabels.SAVE_CODE: "save.asm",
    IOLabels.PRINTI16: "printi16.asm",
    IOLabels.PRINTI32: "printi32.asm",
    IOLabels.PRINTI8: "printi8.asm",
    IOLabels.PRINTSTR: "printstr.asm",
    IOLabels.PRINTU16: "printu16.asm",
    IOLabels.PRINTU32: "printu32.asm",
    IOLabels.PRINTU8: "printu8.asm",
    IOLabels.PRINTF16: "printf16.asm",
    IOLabels.PRINTF: "printf.asm",
    IOLabels.PRINT_AT: "print.asm",
    IOLabels.PRINT_COMMA: "print.asm",
    IOLabels.PRINT_EOL: "print.asm",
    IOLabels.PRINT_EOL_ATTR: "print_eol_attr.asm",
    IOLabels.PRINT_TAB: "print.asm",
    IOLabels.BEEP: "beep.asm",
    IOLabels.BEEPER: "beeper.asm",
}
