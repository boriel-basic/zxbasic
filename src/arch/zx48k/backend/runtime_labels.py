# Runtime labels

class Labels:
    NAMESPACE = ''

    ABS16 = f"{NAMESPACE}__ABS16"
    ABS8 = f"{NAMESPACE}__ABS8"
    ABS32 = f"{NAMESPACE}__ABS32"
    ADDF = f"{NAMESPACE}__ADDF"
    ADDSTR = f"{NAMESPACE}__ADDSTR"
    ALLOC_INITIALIZED_LOCAL_ARRAY = f"{NAMESPACE}__ALLOC_INITIALIZED_LOCAL_ARRAY"
    ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS = f"{NAMESPACE}__ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS"
    ALLOC_LOCAL_ARRAY = f"{NAMESPACE}__ALLOC_LOCAL_ARRAY"
    ALLOC_LOCAL_ARRAY_WITH_BOUNDS = f"{NAMESPACE}__ALLOC_LOCAL_ARRAY_WITH_BOUNDS"
    AND16 = f"{NAMESPACE}__AND16"
    AND32 = f"{NAMESPACE}__AND32"
    ANDF = f"{NAMESPACE}__ANDF"
    ARRAY = f"{NAMESPACE}__ARRAY"
    ARRAY_PTR = f"{NAMESPACE}__ARRAY_PTR"
    ARRAYSTR_FREE_MEM = f"{NAMESPACE}__ARRAYSTR_FREE_MEM"
    BAND16 = f"{NAMESPACE}__BAND16"
    BAND32 = f"{NAMESPACE}__BAND32"
    BNOT16 = f"{NAMESPACE}__BNOT16"
    BNOT32 = f"{NAMESPACE}__BNOT32"
    BOR16 = f"{NAMESPACE}__BOR16"
    BOR32 = f"{NAMESPACE}__BOR32"
    BXOR16 = f"{NAMESPACE}__BXOR16"
    BXOR32 = f"{NAMESPACE}__BXOR32"
    CLS = f"{NAMESPACE}CLS"
    DIVF = f"{NAMESPACE}__DIVF"
    DIVF16 = f"{NAMESPACE}__DIVF16"
    DIVI16 = f"{NAMESPACE}__DIVI16"
    DIVI32 = f"{NAMESPACE}__DIVI32"
    DIVI8_FAST = f"{NAMESPACE}__DIVI8_FAST"
    DIVU8_FAST = f"{NAMESPACE}__DIVU8_FAST"
    DIVU16 = f"{NAMESPACE}__DIVU16"
    DIVU32 = f"{NAMESPACE}__DIVU32"
    EQ16 = f"{NAMESPACE}__EQ16"
    EQ32 = f"{NAMESPACE}__EQ32"
    EQF = f"{NAMESPACE}__EQF"
    ERROR = f"{NAMESPACE}__ERROR"
    F16TOFREG = f"{NAMESPACE}__F16TOFREG"
    FP_PUSH_REV = f"{NAMESPACE}__FP_PUSH_REV"
    FTOF16REG = f"{NAMESPACE}__FTOF16REG"
    FTOU32REG = f"{NAMESPACE}__FTOU32REG"
    GEF = f"{NAMESPACE}__GEF"
    GTF = f"{NAMESPACE}__GTF"
    I8TOFREG = f"{NAMESPACE}__I8TOFREG"
    I32TOFREG = f"{NAMESPACE}__I32TOFREG"
    ILOAD32 = f"{NAMESPACE}__ILOAD32"
    ILOADF = f"{NAMESPACE}__ILOADF"
    ILOADSTR = f"{NAMESPACE}__ILOADSTR"
    ISTORE32 = f"{NAMESPACE}__ISTORE32"
    ISTOREF = f"{NAMESPACE}__ISTOREF"
    LOADSTR = f"{NAMESPACE}__LOADSTR"
    LOAD_DE_DE = f"{NAMESPACE}__LOAD_DE_DE"
    LEF = f"{NAMESPACE}__LEF"
    LEI16 = f"{NAMESPACE}__LEI16"
    LEI8 = f"{NAMESPACE}__LEI8"
    LEI32 = f"{NAMESPACE}__LEI32"
    LOADF = f"{NAMESPACE}__LOADF"
    LTF = f"{NAMESPACE}__LTF"
    LTI16 = f"{NAMESPACE}__LTI16"
    LTI8 = f"{NAMESPACE}__LTI8"
    LTI32 = f"{NAMESPACE}__LTI32"
    MEM_FREE = f"{NAMESPACE}__MEM_FREE"
    MODF = f"{NAMESPACE}__MODF"
    MODF16 = f"{NAMESPACE}__MODF16"
    MODI16 = f"{NAMESPACE}__MODI16"
    MODI32 = f"{NAMESPACE}__MODI32"
    MODU16 = f"{NAMESPACE}__MODU16"
    MODU32 = f"{NAMESPACE}__MODU32"
    MODI8_FAST = f"{NAMESPACE}__MODI8_FAST"
    MODU8_FAST = f"{NAMESPACE}__MODU8_FAST"
    MUL8_FAST = f"{NAMESPACE}__MUL8_FAST"
    MUL16_FAST = f"{NAMESPACE}__MUL16_FAST"
    MUL32 = f"{NAMESPACE}__MUL32"
    MULF = f"{NAMESPACE}__MULF"
    MULF16 = f"{NAMESPACE}__MULF16"
    NEF = f"{NAMESPACE}__NEF"
    NEG32 = f"{NAMESPACE}__NEG32"
    NEGF = f"{NAMESPACE}__NEGF"
    NEGHL = f"{NAMESPACE}__NEGHL"
    NORMALIZE_BOOLEAN = f"{NAMESPACE}__NORMALIZE_BOOLEAN"
    NOT32 = f"{NAMESPACE}__NOT32"
    NOTF = f"{NAMESPACE}__NOTF"
    OR32 = f"{NAMESPACE}__OR32"
    ORF = f"{NAMESPACE}__ORF"
    PISTORE16 = f"{NAMESPACE}__PISTORE16"
    PISTORE32 = f"{NAMESPACE}__PISTORE32"
    PISTOREF = f"{NAMESPACE}__PISTOREF"
    PISTORE_STR = f"{NAMESPACE}__PISTORE_STR"
    PISTORE_STR2 = f"{NAMESPACE}__PISTORE_STR2"
    PLOADF = f"{NAMESPACE}__PLOADF"
    POWF = f"{NAMESPACE}__POW"
    PSTOREF = f"{NAMESPACE}__PSTOREF"
    PSTORE32 = f"{NAMESPACE}__PSTORE32"
    PSTORE_STR = f"{NAMESPACE}__PSTORE_STR"
    PSTORE_STR2 = f"{NAMESPACE}__PSTORE_STR2"
    RANDOMIZE = f"{NAMESPACE}RANDOMIZE"
    SHL32 = f"{NAMESPACE}__SHL32"
    SHRA32 = f"{NAMESPACE}__SHRA32"
    SHRL32 = f"{NAMESPACE}__SHRL32"
    STOREF = f"{NAMESPACE}__STOREF"
    STOP = f"{NAMESPACE}__STOP"
    STORE32 = f"{NAMESPACE}__STORE32"
    STORE_STR = f"{NAMESPACE}__STORE_STR"
    STORE_STR2 = f"{NAMESPACE}__STORE_STR2"
    STR_ARRAYCOPY = f"{NAMESPACE}STR_ARRAYCOPY"
    STREQ = f"{NAMESPACE}__STREQ"
    STRGE = f"{NAMESPACE}__STRGE"
    STRGT = f"{NAMESPACE}__STRGT"
    STRLE = f"{NAMESPACE}__STRLE"
    STRLEN = f"{NAMESPACE}__STRLEN"
    STRLT = f"{NAMESPACE}__STRLT"
    STRNE = f"{NAMESPACE}__STRNE"
    SUB32 = f"{NAMESPACE}__SUB32"
    SUBF = f"{NAMESPACE}__SUBF"
    SWAP32 = f"{NAMESPACE}__SWAP32"
    U32TOFREG = f"{NAMESPACE}__U32TOFREG"
    U8TOFREG = f"{NAMESPACE}__U8TOFREG"
    XOR16 = f"{NAMESPACE}__XOR16"
    XOR8 = f"{NAMESPACE}__XOR8"
    XOR32 = f"{NAMESPACE}__XOR32"
    XORF = f"{NAMESPACE}__XORF"


RUNTIME_LABELS = set(getattr(Labels, x) for x in Labels.__dict__ if not x.startswith('__'))

LABEL_REQUIRED_MODULES = {
    Labels.ABS16: 'abs16.asm',
    Labels.ABS8: 'abs8.asm',
    Labels.ABS32: 'abs32.asm',
    Labels.ADDF: 'addf.asm',
    Labels.ADDSTR: 'strcat.asm',
    Labels.ALLOC_INITIALIZED_LOCAL_ARRAY: 'arrayalloc.asm',
    Labels.ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS: 'arrayalloc.asm',
    Labels.ALLOC_LOCAL_ARRAY: 'arrayalloc.asm',
    Labels.ALLOC_LOCAL_ARRAY_WITH_BOUNDS: 'arrayalloc.asm',
    Labels.AND16: 'and16.asm',
    Labels.AND32: 'and32.asm',
    Labels.ANDF: 'andf.asm',
    Labels.ARRAY: 'array.asm',
    Labels.ARRAY_PTR: 'array.asm',
    Labels.ARRAYSTR_FREE_MEM: 'arraystrfree.asm',
    Labels.BAND16: 'band16.asm',
    Labels.BAND32: 'band32.asm',
    Labels.BNOT16: 'bnot16.asm',
    Labels.BNOT32: 'bnot32.asm',
    Labels.BOR16: 'bor16.asm',
    Labels.BOR32: 'bor32.asm',
    Labels.BXOR16: 'bxor16.asm',
    Labels.BXOR32: 'bxor32.asm',
    Labels.CLS: 'cls.asm',
    Labels.DIVF: 'divf.asm',
    Labels.DIVF16: 'divf16.asm',
    Labels.DIVI16: 'div16.asm',
    Labels.DIVI32: 'div32.asm',
    Labels.DIVU16: 'div16.asm',
    Labels.DIVU32: 'div32.asm',
    Labels.DIVI8_FAST: 'div8.asm',
    Labels.DIVU8_FAST: 'div8.asm',
    Labels.GEF: 'gef.asm',
    Labels.GTF: 'gtf.asm',
    Labels.I8TOFREG: 'u32tofreg.asm',
    Labels.I32TOFREG: 'u32tofreg.asm',
    Labels.ILOAD32: 'iload32.asm',
    Labels.ILOADF: 'iloadf.asm',
    Labels.ILOADSTR: 'loadstr.asm',
    Labels.ISTORE32: 'store32.asm',
    Labels.ISTOREF: 'storef.asm',
    Labels.EQ16: 'eq16.asm',
    Labels.EQ32: 'eq32.asm',
    Labels.EQF: 'eqf.asm',
    Labels.ERROR: 'error.asm',
    Labels.F16TOFREG: 'f16tofreg.asm',
    Labels.FP_PUSH_REV: 'pushf.asm',
    Labels.FTOF16REG: 'ftof16reg.asm',
    Labels.FTOU32REG: 'ftou32reg.asm',
    Labels.LOADF: 'iloadf.asm',
    Labels.LOADSTR: 'loadstr.asm',
    Labels.LOAD_DE_DE: 'lddede.asm',
    Labels.LEF: 'lef.asm',
    Labels.LEI16: 'lei16.asm',
    Labels.LEI8: 'lei8.asm',
    Labels.LEI32: 'lei32.asm',
    Labels.LTF: 'ltf.asm',
    Labels.LTI16: 'lti16.asm',
    Labels.LTI8: 'lti8.asm',
    Labels.LTI32: 'lti32.asm',
    Labels.MEM_FREE: 'free.asm',
    Labels.MODF: 'modf.asm',
    Labels.MODF16: 'modf16.asm',
    Labels.MODI16: 'div16.asm',
    Labels.MODI32: 'div32.asm',
    Labels.MODU16: 'div16.asm',
    Labels.MODU32: 'div32.asm',
    Labels.MODI8_FAST: 'div8.asm',
    Labels.MODU8_FAST: 'div8.asm',
    Labels.MUL8_FAST: 'mul8.asm',
    Labels.MUL16_FAST: 'mul16.asm',
    Labels.MUL32: 'mul32.asm',
    Labels.MULF: 'mulf.asm',
    Labels.MULF16: 'mulf16.asm',
    Labels.NEF: 'nef.asm',
    Labels.NEG32: 'neg32.asm',
    Labels.NEGF: 'negf.asm',
    Labels.NEGHL: 'neg16.asm',
    Labels.NORMALIZE_BOOLEAN: 'strictbool.asm',
    Labels.NOT32: 'not32.asm',
    Labels.NOTF: 'notf.asm',
    Labels.OR32: 'or32.asm',
    Labels.ORF: 'orf.asm',
    Labels.PISTORE16: 'istore16.asm',
    Labels.PISTORE32: 'pistore32.asm',
    Labels.PISTOREF: 'storef.asm',
    Labels.PISTORE_STR: 'storestr.asm',
    Labels.PISTORE_STR2: 'storestr2.asm',
    Labels.PLOADF: 'ploadf.asm',
    Labels.POWF: 'pow.asm',
    Labels.PSTOREF: 'pstoref.asm',
    Labels.PSTORE32: 'pstore32.asm',
    Labels.PSTORE_STR: 'pstorestr.asm',
    Labels.PSTORE_STR2: 'pstorestr2.asm',
    Labels.RANDOMIZE: 'random.asm',
    Labels.SHL32: 'shl32.asm',
    Labels.SHRA32: 'shra32.asm',
    Labels.SHRL32: 'shrl32.asm',
    Labels.STOREF: 'storef.asm',
    Labels.STOP: 'error.asm',
    Labels.STORE32: 'store32.asm',
    Labels.STORE_STR: 'storestr.asm',
    Labels.STORE_STR2: 'storestr2.asm',
    Labels.STR_ARRAYCOPY: 'strarraycpy.asm',
    Labels.STREQ: 'string.asm',
    Labels.STRGE: 'string.asm',
    Labels.STRGT: 'string.asm',
    Labels.STRLE: 'string.asm',
    Labels.STRLEN: 'strlen.asm',
    Labels.STRLT: 'string.asm',
    Labels.STRNE: 'string.asm',
    Labels.SUB32: 'sub32.asm',
    Labels.SUBF: 'subf.asm',
    Labels.SWAP32: 'swap32.asm',
    Labels.U32TOFREG: 'u32tofreg.asm',
    Labels.U8TOFREG: 'u32tofreg.asm',
    Labels.XOR16: 'xor16.asm',
    Labels.XOR8: 'xor8.asm',
    Labels.XOR32: 'xor32.asm',
    Labels.XORF: 'xorf.asm',
}
