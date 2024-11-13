# Runtime labels

from .namespace import NAMESPACE


class MathLabels:
    ACS = f"{NAMESPACE}.ACOS"
    ASN = f"{NAMESPACE}.ASIN"
    ATN = f"{NAMESPACE}.ATAN"
    COS = f"{NAMESPACE}.COS"
    SIN = f"{NAMESPACE}.SIN"
    TAN = f"{NAMESPACE}.TAN"

    EXP = f"{NAMESPACE}.EXP"
    LN = f"{NAMESPACE}.LN"
    SQR = f"{NAMESPACE}.SQRT"

    SGNI8 = f"{NAMESPACE}.__SGNI8"
    SGNU8 = f"{NAMESPACE}.__SGNU8"
    SGNI16 = f"{NAMESPACE}.__SGNI16"
    SGNU16 = f"{NAMESPACE}.__SGNU16"
    SGNI32 = f"{NAMESPACE}.__SGNI32"
    SGNU32 = f"{NAMESPACE}.__SGNU32"
    SGNF16 = f"{NAMESPACE}.__SGNF16"
    SGNF = f"{NAMESPACE}.__SGNF"


REQUIRED_MODULES = {
    MathLabels.ACS: "math/acos.asm",
    MathLabels.ASN: "math/asin.asm",
    MathLabels.ATN: "math/atan.asm",
    MathLabels.COS: "math/cos.asm",
    MathLabels.SIN: "math/sin.asm",
    MathLabels.TAN: "math/tan.asm",
    MathLabels.EXP: "math/exp.asm",
    MathLabels.LN: "math/logn.asm",
    MathLabels.SQR: "math/sqrt.asm",
    MathLabels.SGNI8: "sgni8.asm",
    MathLabels.SGNU8: "sgnu8.asm",
    MathLabels.SGNI16: "sgni16.asm",
    MathLabels.SGNU16: "sgnu16.asm",
    MathLabels.SGNI32: "sgni32.asm",
    MathLabels.SGNU32: "sgnu32.asm",
    MathLabels.SGNF16: "sgnf16.asm",
    MathLabels.SGNF: "sgnf.asm",
}
