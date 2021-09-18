# Runtime labels

from .namespace import NAMESPACE


class CoreLabels:
    ABS16 = f"{NAMESPACE}.__ABS16"
    ABS8 = f"{NAMESPACE}.__ABS8"
    ABS32 = f"{NAMESPACE}.__ABS32"
    ADDF = f"{NAMESPACE}.__ADDF"
    ADDSTR = f"{NAMESPACE}.__ADDSTR"
    ALLOC_INITIALIZED_LOCAL_ARRAY = f"{NAMESPACE}.__ALLOC_INITIALIZED_LOCAL_ARRAY"
    ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS = f"{NAMESPACE}.__ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS"
    ALLOC_LOCAL_ARRAY = f"{NAMESPACE}.__ALLOC_LOCAL_ARRAY"
    ALLOC_LOCAL_ARRAY_WITH_BOUNDS = f"{NAMESPACE}.__ALLOC_LOCAL_ARRAY_WITH_BOUNDS"
    AND16 = f"{NAMESPACE}.__AND16"
    AND32 = f"{NAMESPACE}.__AND32"
    ANDF = f"{NAMESPACE}.__ANDF"
    ARRAY = f"{NAMESPACE}.__ARRAY"
    ARRAY_PTR = f"{NAMESPACE}.__ARRAY_PTR"
    ARRAYSTR_FREE_MEM = f"{NAMESPACE}.__ARRAYSTR_FREE_MEM"
    BAND16 = f"{NAMESPACE}.__BAND16"
    BAND32 = f"{NAMESPACE}.__BAND32"
    BNOT16 = f"{NAMESPACE}.__BNOT16"
    BNOT32 = f"{NAMESPACE}.__BNOT32"
    BOR16 = f"{NAMESPACE}.__BOR16"
    BOR32 = f"{NAMESPACE}.__BOR32"
    BXOR16 = f"{NAMESPACE}.__BXOR16"
    BXOR32 = f"{NAMESPACE}.__BXOR32"
    CHECK_BREAK = f"{NAMESPACE}.CHECK_BREAK"
    DIVF = f"{NAMESPACE}.__DIVF"
    DIVF16 = f"{NAMESPACE}.__DIVF16"
    DIVI16 = f"{NAMESPACE}.__DIVI16"
    DIVI32 = f"{NAMESPACE}.__DIVI32"
    DIVI8_FAST = f"{NAMESPACE}.__DIVI8_FAST"
    DIVU8_FAST = f"{NAMESPACE}.__DIVU8_FAST"
    DIVU16 = f"{NAMESPACE}.__DIVU16"
    DIVU32 = f"{NAMESPACE}.__DIVU32"
    EQ16 = f"{NAMESPACE}.__EQ16"
    EQ32 = f"{NAMESPACE}.__EQ32"
    EQF = f"{NAMESPACE}.__EQF"
    ERROR = f"{NAMESPACE}.__ERROR"
    F16TOFREG = f"{NAMESPACE}.__F16TOFREG"
    FP_PUSH_REV = f"{NAMESPACE}.__FP_PUSH_REV"
    FTOF16REG = f"{NAMESPACE}.__FTOF16REG"
    FTOU32REG = f"{NAMESPACE}.__FTOU32REG"
    GEF = f"{NAMESPACE}.__GEF"
    GTF = f"{NAMESPACE}.__GTF"
    I8TOFREG = f"{NAMESPACE}.__I8TOFREG"
    I32TOFREG = f"{NAMESPACE}.__I32TOFREG"
    ILOAD32 = f"{NAMESPACE}.__ILOAD32"
    ILOADF = f"{NAMESPACE}.__ILOADF"
    ILOADSTR = f"{NAMESPACE}.__ILOADSTR"
    ISTORE32 = f"{NAMESPACE}.__ISTORE32"
    ISTOREF = f"{NAMESPACE}.__ISTOREF"
    LBOUND = f"{NAMESPACE}.__LBOUND"
    LOADSTR = f"{NAMESPACE}.__LOADSTR"
    LOAD_DE_DE = f"{NAMESPACE}.__LOAD_DE_DE"
    LEF = f"{NAMESPACE}.__LEF"
    LEI16 = f"{NAMESPACE}.__LEI16"
    LEI32 = f"{NAMESPACE}.__LEI32"
    LEI8 = f"{NAMESPACE}.__LEI8"
    LETSUBSTR = f"{NAMESPACE}.__LETSUBSTR"
    LOADF = f"{NAMESPACE}.__LOADF"
    LTF = f"{NAMESPACE}.__LTF"
    LTI16 = f"{NAMESPACE}.__LTI16"
    LTI8 = f"{NAMESPACE}.__LTI8"
    LTI32 = f"{NAMESPACE}.__LTI32"
    MEM_FREE = f"{NAMESPACE}.__MEM_FREE"
    MODF = f"{NAMESPACE}.__MODF"
    MODF16 = f"{NAMESPACE}.__MODF16"
    MODI16 = f"{NAMESPACE}.__MODI16"
    MODI32 = f"{NAMESPACE}.__MODI32"
    MODU16 = f"{NAMESPACE}.__MODU16"
    MODU32 = f"{NAMESPACE}.__MODU32"
    MODI8_FAST = f"{NAMESPACE}.__MODI8_FAST"
    MODU8_FAST = f"{NAMESPACE}.__MODU8_FAST"
    MUL8_FAST = f"{NAMESPACE}.__MUL8_FAST"
    MUL16_FAST = f"{NAMESPACE}.__MUL16_FAST"
    MUL32 = f"{NAMESPACE}.__MUL32"
    MULF = f"{NAMESPACE}.__MULF"
    MULF16 = f"{NAMESPACE}.__MULF16"
    NEF = f"{NAMESPACE}.__NEF"
    NEG32 = f"{NAMESPACE}.__NEG32"
    NEGF = f"{NAMESPACE}.__NEGF"
    NEGHL = f"{NAMESPACE}.__NEGHL"
    NORMALIZE_BOOLEAN = f"{NAMESPACE}.__NORMALIZE_BOOLEAN"
    NOT32 = f"{NAMESPACE}.__NOT32"
    NOTF = f"{NAMESPACE}.__NOTF"
    ON_GOTO = f"{NAMESPACE}.__ON_GOTO"
    ON_GOSUB = f"{NAMESPACE}.__ON_GOSUB"
    OR32 = f"{NAMESPACE}.__OR32"
    ORF = f"{NAMESPACE}.__ORF"
    PISTORE16 = f"{NAMESPACE}.__PISTORE16"
    PISTORE32 = f"{NAMESPACE}.__PISTORE32"
    PISTOREF = f"{NAMESPACE}.__PISTOREF"
    PISTORE_STR = f"{NAMESPACE}.__PISTORE_STR"
    PISTORE_STR2 = f"{NAMESPACE}.__PISTORE_STR2"
    PLOADF = f"{NAMESPACE}.__PLOADF"
    POWF = f"{NAMESPACE}.__POW"
    PSTOREF = f"{NAMESPACE}.__PSTOREF"
    PSTORE32 = f"{NAMESPACE}.__PSTORE32"
    PSTORE_STR = f"{NAMESPACE}.__PSTORE_STR"
    PSTORE_STR2 = f"{NAMESPACE}.__PSTORE_STR2"
    SHL32 = f"{NAMESPACE}.__SHL32"
    SHRA32 = f"{NAMESPACE}.__SHRA32"
    SHRL32 = f"{NAMESPACE}.__SHRL32"
    STOREF = f"{NAMESPACE}.__STOREF"
    STOP = f"{NAMESPACE}.__STOP"
    STORE32 = f"{NAMESPACE}.__STORE32"
    STORE_STR = f"{NAMESPACE}.__STORE_STR"
    STORE_STR2 = f"{NAMESPACE}.__STORE_STR2"
    STR_ARRAYCOPY = f"{NAMESPACE}.STR_ARRAYCOPY"
    STR_FAST = f"{NAMESPACE}.__STR_FAST"
    STREQ = f"{NAMESPACE}.__STREQ"
    STRGE = f"{NAMESPACE}.__STRGE"
    STRGT = f"{NAMESPACE}.__STRGT"
    STRLE = f"{NAMESPACE}.__STRLE"
    STRLEN = f"{NAMESPACE}.__STRLEN"
    STRLT = f"{NAMESPACE}.__STRLT"
    STRNE = f"{NAMESPACE}.__STRNE"
    STRSLICE = f"{NAMESPACE}.__STRSLICE"
    SUB32 = f"{NAMESPACE}.__SUB32"
    SUBF = f"{NAMESPACE}.__SUBF"
    SWAP32 = f"{NAMESPACE}.__SWAP32"
    U32TOFREG = f"{NAMESPACE}.__U32TOFREG"
    U8TOFREG = f"{NAMESPACE}.__U8TOFREG"
    UBOUND = f"{NAMESPACE}.__UBOUND"
    XOR16 = f"{NAMESPACE}.__XOR16"
    XOR8 = f"{NAMESPACE}.__XOR8"
    XOR32 = f"{NAMESPACE}.__XOR32"
    XORF = f"{NAMESPACE}.__XORF"


REQUIRED_MODULES = {
    CoreLabels.ABS16: "abs16.asm",
    CoreLabels.ABS8: "abs8.asm",
    CoreLabels.ABS32: "abs32.asm",
    CoreLabels.ADDF: "addf.asm",
    CoreLabels.ADDSTR: "strcat.asm",
    CoreLabels.ALLOC_INITIALIZED_LOCAL_ARRAY: "arrayalloc.asm",
    CoreLabels.ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS: "arrayalloc.asm",
    CoreLabels.ALLOC_LOCAL_ARRAY: "arrayalloc.asm",
    CoreLabels.ALLOC_LOCAL_ARRAY_WITH_BOUNDS: "arrayalloc.asm",
    CoreLabels.AND16: "and16.asm",
    CoreLabels.AND32: "and32.asm",
    CoreLabels.ANDF: "andf.asm",
    CoreLabels.ARRAY: "array.asm",
    CoreLabels.ARRAY_PTR: "array.asm",
    CoreLabels.ARRAYSTR_FREE_MEM: "arraystrfree.asm",
    CoreLabels.BAND16: "band16.asm",
    CoreLabels.BAND32: "band32.asm",
    CoreLabels.BNOT16: "bnot16.asm",
    CoreLabels.BNOT32: "bnot32.asm",
    CoreLabels.BOR16: "bor16.asm",
    CoreLabels.BOR32: "bor32.asm",
    CoreLabels.BXOR16: "bxor16.asm",
    CoreLabels.BXOR32: "bxor32.asm",
    CoreLabels.CHECK_BREAK: "break.asm",
    CoreLabels.DIVF: "divf.asm",
    CoreLabels.DIVF16: "divf16.asm",
    CoreLabels.DIVI16: "div16.asm",
    CoreLabels.DIVI32: "div32.asm",
    CoreLabels.DIVU16: "div16.asm",
    CoreLabels.DIVU32: "div32.asm",
    CoreLabels.DIVI8_FAST: "div8.asm",
    CoreLabels.DIVU8_FAST: "div8.asm",
    CoreLabels.GEF: "gef.asm",
    CoreLabels.GTF: "gtf.asm",
    CoreLabels.I8TOFREG: "u32tofreg.asm",
    CoreLabels.I32TOFREG: "u32tofreg.asm",
    CoreLabels.ILOAD32: "iload32.asm",
    CoreLabels.ILOADF: "iloadf.asm",
    CoreLabels.ILOADSTR: "loadstr.asm",
    CoreLabels.ISTORE32: "store32.asm",
    CoreLabels.ISTOREF: "storef.asm",
    CoreLabels.EQ16: "eq16.asm",
    CoreLabels.EQ32: "eq32.asm",
    CoreLabels.EQF: "eqf.asm",
    CoreLabels.ERROR: "error.asm",
    CoreLabels.F16TOFREG: "f16tofreg.asm",
    CoreLabels.FP_PUSH_REV: "pushf.asm",
    CoreLabels.FTOF16REG: "ftof16reg.asm",
    CoreLabels.FTOU32REG: "ftou32reg.asm",
    CoreLabels.LBOUND: "bound.asm",
    CoreLabels.LEF: "lef.asm",
    CoreLabels.LEI16: "lei16.asm",
    CoreLabels.LEI32: "lei32.asm",
    CoreLabels.LEI8: "lei8.asm",
    CoreLabels.LETSUBSTR: "letsubstr.asm",
    CoreLabels.LOADF: "iloadf.asm",
    CoreLabels.LOADSTR: "loadstr.asm",
    CoreLabels.LOAD_DE_DE: "lddede.asm",
    CoreLabels.LTF: "ltf.asm",
    CoreLabels.LTI16: "lti16.asm",
    CoreLabels.LTI8: "lti8.asm",
    CoreLabels.LTI32: "lti32.asm",
    CoreLabels.MEM_FREE: "free.asm",
    CoreLabels.MODF: "modf.asm",
    CoreLabels.MODF16: "modf16.asm",
    CoreLabels.MODI16: "div16.asm",
    CoreLabels.MODI32: "div32.asm",
    CoreLabels.MODU16: "div16.asm",
    CoreLabels.MODU32: "div32.asm",
    CoreLabels.MODI8_FAST: "div8.asm",
    CoreLabels.MODU8_FAST: "div8.asm",
    CoreLabels.MUL8_FAST: "mul8.asm",
    CoreLabels.MUL16_FAST: "mul16.asm",
    CoreLabels.MUL32: "mul32.asm",
    CoreLabels.MULF: "mulf.asm",
    CoreLabels.MULF16: "mulf16.asm",
    CoreLabels.NEF: "nef.asm",
    CoreLabels.NEG32: "neg32.asm",
    CoreLabels.NEGF: "negf.asm",
    CoreLabels.NEGHL: "neg16.asm",
    CoreLabels.NORMALIZE_BOOLEAN: "strictbool.asm",
    CoreLabels.NOT32: "not32.asm",
    CoreLabels.NOTF: "notf.asm",
    CoreLabels.ON_GOTO: "ongoto.asm",
    CoreLabels.ON_GOSUB: "ongoto.asm",
    CoreLabels.OR32: "or32.asm",
    CoreLabels.ORF: "orf.asm",
    CoreLabels.PISTORE16: "istore16.asm",
    CoreLabels.PISTORE32: "pistore32.asm",
    CoreLabels.PISTOREF: "storef.asm",
    CoreLabels.PISTORE_STR: "storestr.asm",
    CoreLabels.PISTORE_STR2: "storestr2.asm",
    CoreLabels.PLOADF: "ploadf.asm",
    CoreLabels.POWF: "pow.asm",
    CoreLabels.PSTOREF: "pstoref.asm",
    CoreLabels.PSTORE32: "pstore32.asm",
    CoreLabels.PSTORE_STR: "pstorestr.asm",
    CoreLabels.PSTORE_STR2: "pstorestr2.asm",
    CoreLabels.SHL32: "shl32.asm",
    CoreLabels.SHRA32: "shra32.asm",
    CoreLabels.SHRL32: "shrl32.asm",
    CoreLabels.STOREF: "storef.asm",
    CoreLabels.STOP: "error.asm",
    CoreLabels.STORE32: "store32.asm",
    CoreLabels.STORE_STR: "storestr.asm",
    CoreLabels.STORE_STR2: "storestr2.asm",
    CoreLabels.STR_ARRAYCOPY: "strarraycpy.asm",
    CoreLabels.STR_FAST: "str.asm",
    CoreLabels.STREQ: "string.asm",
    CoreLabels.STRGE: "string.asm",
    CoreLabels.STRGT: "string.asm",
    CoreLabels.STRLE: "string.asm",
    CoreLabels.STRLEN: "strlen.asm",
    CoreLabels.STRLT: "string.asm",
    CoreLabels.STRNE: "string.asm",
    CoreLabels.STRSLICE: "strslice.asm",
    CoreLabels.SUB32: "sub32.asm",
    CoreLabels.SUBF: "subf.asm",
    CoreLabels.SWAP32: "swap32.asm",
    CoreLabels.U32TOFREG: "u32tofreg.asm",
    CoreLabels.U8TOFREG: "u32tofreg.asm",
    CoreLabels.UBOUND: "bound.asm",
    CoreLabels.XOR16: "xor16.asm",
    CoreLabels.XOR8: "xor8.asm",
    CoreLabels.XOR32: "xor32.asm",
    CoreLabels.XORF: "xorf.asm",
}
