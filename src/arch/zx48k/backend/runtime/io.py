# I/O labels


from .namespace import NAMESPACE


class IOLabels:
    # Screen and attributes
    CLS = f"{NAMESPACE}CLS"
    BOLD = f"{NAMESPACE}BOLD"
    BRIGHT = f"{NAMESPACE}BRIGHT"
    FLASH = f"{NAMESPACE}FLASH"
    INK = f"{NAMESPACE}INK"
    INVERSE = f"{NAMESPACE}INVERSER"
    ITALIC = f"{NAMESPACE}ITALIC"
    OVER = f"{NAMESPACE}OVER"
    PAPER = f"{NAMESPACE}PAPER"

    # Drawing primitives
    CIRCLE = f"{NAMESPACE}CIRCLE"
    DRAW = f"{NAMESPACE}DRAW"
    DRAW3 = f"{NAMESPACE}DRAW3"
    PLOT = f"{NAMESPACE}PLOT"

    # Print ("console")
    PRINTI16 = f"{NAMESPACE}__PRINTI16"
    PRINTI32 = f"{NAMESPACE}__PRINTI32"
    PRINTI8 = f"{NAMESPACE}__PRINTI8"
    PRINTF = f"{NAMESPACE}__PRINTF"
    PRINTF16 = f"{NAMESPACE}__PRINTF16"
    PRINTSTR = f"{NAMESPACE}__PRINTSTR"
    PRINTU16 = f"{NAMESPACE}__PRINTU16"
    PRINTU32 = f"{NAMESPACE}__PRINTU32"
    PRINTU8 = f"{NAMESPACE}__PRINTU8"
    PRINT_AT = f"{NAMESPACE}PRINT_AT"
    PRINT_COMMA = f"{NAMESPACE}PRINT_COMMA"
    PRINT_EOL = f"{NAMESPACE}PRINT_EOL"
    PRINT_EOL_ATTR = f"{NAMESPACE}PRINT_EOL_ATTR"
    PRINT_TAB = f"{NAMESPACE}PRINT_TAB"

    # Tape ("cassette routines")
    LOAD_CODE = f"{NAMESPACE}LOAD_CODE"
    SAVE_CODE = f"{NAMESPACE}SAVE_CODE"


REQUIRED_MODULES = {
    IOLabels.CIRCLE: 'circle.asm',
    IOLabels.CLS: 'cls.asm',
    IOLabels.DRAW: 'draw.asm',
    IOLabels.DRAW3: 'draw3.asm',
    IOLabels.PLOT: 'plot.asm',

    IOLabels.LOAD_CODE: 'load.asm',
    IOLabels.SAVE_CODE: 'save.asm',

    IOLabels.PRINTI16: 'printi16.asm',
    IOLabels.PRINTI32: 'printi32.asm',
    IOLabels.PRINTI8: 'printi8.asm',
    IOLabels.PRINTSTR: 'printstr.asm',
    IOLabels.PRINTU16: 'printu16.asm',
    IOLabels.PRINTU32: 'printu32.asm',
    IOLabels.PRINTU8: 'printu8.asm',
    IOLabels.PRINTF16: 'printf16.asm',
    IOLabels.PRINTF: 'printf.asm',
    IOLabels.PRINT_AT: 'print.asm',
    IOLabels.PRINT_COMMA: 'print.asm',
    IOLabels.PRINT_EOL: 'print.asm',
    IOLabels.PRINT_EOL_ATTR: 'print_eol_attr.asm',
    IOLabels.PRINT_TAB: 'print.asm',
}
