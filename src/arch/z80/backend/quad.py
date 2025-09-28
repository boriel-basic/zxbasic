# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.arch.interface.quad import Quad as BaseQuad

from .icinstruction import ICInstruction


class Quad(BaseQuad):
    def __init__(self, instr: ICInstruction, *args):
        ICInstruction.check(instr)
        super().__init__(instr, *args)
