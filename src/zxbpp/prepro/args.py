# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .macrocall import MacroCall


class Arg:
    """Implements an argument (a list of tokens and macrocalls)"""

    def __init__(self, value=None, table=None):
        self.table = table
        self.value = []
        if value is not None:
            self.value += [value]

    def __len__(self):
        return len(self.value)

    def __str__(self):
        return self()

    def __call__(self, symbolTable=None):
        result = ""
        if symbolTable is None:
            symbolTable = self.table

        for x in self.value:
            if isinstance(x, MacroCall):
                result += x(symbolTable)
            else:
                result += str(x)

        return result

    def addToken(self, token):
        self.value += [token]

    def __iter__(self):
        if self.value is not None:
            for x in self.value:
                yield x


class ArgList:
    """Implements an arglist"""

    def __init__(self, table):
        self.table = table
        self.value = []
        self.start_lineno = -1
        self.end_lineno = -1

    def __len__(self):
        return len(self.value)

    def __call__(self):
        if self.value is None:
            return None

        return [x() for x in self.value]

    def addNewArg(self, value):
        if value is not None:
            self.value += [Arg(value, self.table)]

    def __iter__(self):
        for x in self.value:
            yield x

    def __str__(self):
        if self() is None:
            return ""

        result = "(" + ",".join(self()) + ")"
        return result

    def __getitem__(self, key):
        if self.value is None:
            return None

        return self.value[key]
