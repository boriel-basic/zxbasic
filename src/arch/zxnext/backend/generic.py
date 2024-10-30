# ----------------------------------------------------------
# Generic instructions
# ----------------------------------------------------------

from src.api.config import OPTIONS
from src.arch.interface.quad import Quad
from src.arch.z80.backend import Bits16, common


def _end(ins: Quad):
    """Outputs the ending sequence"""
    output = Bits16.get_oper(ins[1])
    output.append("ld b, h")
    output.append("ld c, l")

    if common.FLAG_end_emitted:
        return output + ["jp %s" % common.END_LABEL]

    common.FLAG_end_emitted = True

    output.append("%s:" % common.END_LABEL)
    if OPTIONS.headerless:
        return output + ["ret"]

    output.append("di")
    output.append("ld hl, (%s)" % common.CALL_BACK)
    output.append("ld sp, hl")
    output.append("pop iy")
    output.append("ei")
    output.append("ret")
    return output
