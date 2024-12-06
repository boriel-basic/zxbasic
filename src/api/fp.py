# Floating point converter


def fp(x: float) -> tuple[str, str]:
    """Returns a floating point number as EXP+128, Mantissa"""

    def bin32(f: float) -> str:
        """Returns ASCII 32 bit binary representation of a number"""
        return bin(int(f) & 0xFFFF_FFFF)[2:].zfill(32)

    def bindec32(f: float) -> str:
        """Returns binary representation of a mantissa x (x is float)"""
        result = "0"
        a = f

        if f >= 1:
            result = bin32(f)

        result += "."
        c = int(a)

        for i in range(32):
            a -= c
            a *= 2
            c = int(a)
            result += str(c)

        return result

    e = 0  # exponent
    s = 1 if x < 0 else 0  # sign
    m = abs(x)  # mantissa

    while m >= 1:
        m /= 2.0
        e += 1

    while 0 < m < 0.5:
        m *= 2.0
        e -= 1

    M = bindec32(m)[3:]
    M = str(s) + M
    E = bin32(e + 128)[-8:] if x != 0 else bin32(0)[-8:]

    return M, E


def immediate_float(x: float) -> tuple[str, str, str]:
    """Returns C DE HL as values for loading
    and immediate floating point.
    """

    def bin2hex(y: str) -> str:
        return "%02X" % int(y, 2)

    M, E = fp(x)

    C = "0" + bin2hex(E) + "h"
    ED = "0" + bin2hex(M[8:16]) + bin2hex(M[:8]) + "h"
    LH = "0" + bin2hex(M[24:]) + bin2hex(M[16:24]) + "h"

    return C, ED, LH


def fp2float(mantissa: str, exp: str) -> float:
    """Converts a mantissa, exponent to floating point"""
    if not (mantissa + exp).strip("0"):
        return 0.0

    M = "1" + mantissa[1:]
    S = -1 if mantissa[0] == "1" else 1
    E = int(exp, 2) - 128 - 32

    value = S * int(M, 2) * 2**E
    return value
