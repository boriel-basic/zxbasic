# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .call import SymbolCALL


class SymbolFUNCCALL(SymbolCALL):
    """This class is the same as CALL, we just declare it to make
    a distinction. (e.g. the Token is gotten from the class name)

    A FunctionCall is a Call whose return value is going to be used
    later within an expression. Eg.

    CALL: f(x)
    FUNCCALL: a = 2 * f(x)

    This distinction is useful to discard values returned using the HEAP
    to avoid memory leaks.
    """

    pass
