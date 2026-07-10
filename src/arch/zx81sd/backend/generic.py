# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# ZX81 + SD81 Booster — END opcode handler
# --------------------------------------------------------------------

from src.arch.interface.quad import Quad
from src.arch.z80.backend import Bits16, common


def _end(ins: Quad):
    """End-of-program sequence for ZX81 + SD81 Booster.

    There's no ROM or BASIC to return to: it stops the CPU safely.
    If END appears more than once in the program (early exits), later
    occurrences generate a JP to the first emitted END block.
    """
    output = Bits16.get_oper(ins[1])
    output.append("ld b, h")
    output.append("ld c, l")

    if common.FLAG_end_emitted:
        return output + [f"jp {common.END_LABEL}"]

    common.FLAG_end_emitted = True

    output.append(f"{common.END_LABEL}:")
    output.append("di")
    output.append("halt")
    return output
