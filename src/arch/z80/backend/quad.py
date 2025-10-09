# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.arch.interface.quad import Quad as BaseQuad

from .icinstruction import ICInstruction


class Quad(BaseQuad):
    def __init__(self, instr: ICInstruction, *args):
        ICInstruction.check(instr)
        super().__init__(instr, *args)
