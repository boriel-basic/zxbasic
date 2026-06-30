# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# ZX81 + SD81 Booster — handler del opcode END
# --------------------------------------------------------------------

from src.arch.interface.quad import Quad
from src.arch.z80.backend import Bits16, common


def _end(ins: Quad):
    """Secuencia de fin de programa para ZX81 + SD81 Booster.

    No hay ROM ni BASIC al que volver: detiene la CPU de forma segura.
    Si END aparece varias veces en el programa (salidas anticipadas),
    los casos posteriores generan un JP al primer bloque END emitido.
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
