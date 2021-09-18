import math


# CONSTANT LN(2)
__LN2 = math.log(2)


def log2(x: float) -> float:
    """Returns log2(x)"""
    return math.log(x) / __LN2


def is_2n(x: int) -> bool:
    """Returns true if x is an exact
    power of 2
    """
    log = log2(x)
    return log == int(log)


def is_int_type(stype: str) -> bool:
    """Returns whether a given type is integer"""
    return stype[0] in ("u", "i")
