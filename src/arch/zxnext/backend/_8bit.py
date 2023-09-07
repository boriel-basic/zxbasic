# -*- coding: utf-8 -*-

from src.arch.z80.backend._8bit import _8bit_oper, int8
from src.arch.z80.backend.common import _int_ops
from src.arch.z80.backend.quad import Quad


def _mul8(ins: Quad) -> list[str]:
    """Multiplies 2 las values from the stack.

    Optimizations:
      * If any of the ops is ZERO,
        then do A = 0 ==> XOR A, cause A * 0 = 0 * A = 0

      * If any ot the ops is ONE, do NOTHING
        A * 1 = 1 * A = A
    """

    op1, op2 = tuple(ins[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _8bit_oper(op1)

        if op2 == 0:
            output.append("xor a")
            output.append("push af")
            return output

        if op2 == 1:  # A * 1 = 1 * A = A
            output.append("push af")
            return output

        if op2 == 2:  # A * 2 == A SLA 1
            output.append("add a, a")
            output.append("push af")
            return output

        if op2 == 4:  # A * 4 == A SLA 2
            output.append("add a, a")
            output.append("add a, a")
            output.append("push af")
            return output

        output.append("ld h, %i" % int8(op2))
    else:
        if op2[0] == "_":  # stack optimization
            op1, op2 = op2, op1

        output = _8bit_oper(op1, op2)

    output.append("ld d, h")  # Immediate
    output.append("ld e, a")
    output.append("mul d, e")
    output.append("ld a, e")
    output.append("push af")
    return output
