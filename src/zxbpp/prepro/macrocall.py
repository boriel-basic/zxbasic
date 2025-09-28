# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import copy
import re
from typing import Union

from src.api.debug import __DEBUG__
from src.zxbpp import prepro

from .exceptions import PreprocError

DEBUG_LEVEL = 3  # Which -d level is required to show debug info
RE_ID = re.compile("(?:.*[^_0-9a-zA-Z]|^)([a-zA-Z_][a-zA-Z_0-9]*)$")


class MacroCall:
    """A call to a macro, stored in an object.
    Every time the macro() is called, the macro returns
    it value.
    """

    __slots__ = "callargs", "fname", "id_", "lineno", "table"

    def __init__(self, fname: str, lineno: int, table: "prepro.DefinesTable", id_: Union["MacroCall", str], args=None):
        """Initializes the object with the ID table, the ID name and
        optionally, the passed args.
        """
        self.table: prepro.DefinesTable = table
        self.id_ = id_
        self.callargs = args
        self.lineno: int = lineno
        self.fname: str = fname

    @staticmethod
    def eval(arg) -> str:
        """Evaluates a given argument. The token will be returned by default
        "as is", except if it's a macrocall. In such case it will be evaluated
        recursively.
        """
        return str(arg())  # Evaluate the arg (could be a macrocall)

    def __call__(self, symbolTable: "prepro.DefinesTable" = None) -> str:
        """Execute the macro call using LAZY evaluation"""
        if isinstance(self.id_, MacroCall):
            self.id_ = self.id_()

        __DEBUG__("evaluating '%s'" % self.id_, DEBUG_LEVEL)
        if symbolTable is None:
            symbolTable = self.table

        # The macro is not defined => returned as is
        if not self.is_defined(symbolTable):
            __DEBUG__("macro '%s' not defined" % self.id_, DEBUG_LEVEL)
            tmp = self.id_
            if self.callargs is not None:
                tmp += str(self.callargs)
            __DEBUG__("evaluation result: %s" % tmp, DEBUG_LEVEL)
            return tmp

        # The macro is defined
        __DEBUG__("macro '%s' defined" % self.id_, DEBUG_LEVEL)
        table = copy.deepcopy(symbolTable)
        id_ = table[self.id_]  # Get the defined macro
        assert isinstance(id_, prepro.ID)
        if id_.hasArgs and self.callargs is None:
            return self.id_  # If no args passed, returned as is

        args = []
        if self.callargs:  # has args. Evaluate them removing spaces
            __DEBUG__("'%s' has args defined" % self.id_, DEBUG_LEVEL)
            __DEBUG__("evaluating %i arg(s) for '%s'" % (len(self.callargs), self.id_), DEBUG_LEVEL)
            args = [x(table).strip() for x in self.callargs]
            __DEBUG__("macro call: %s%s" % (self.id_, "(" + ", ".join(args) + ")"), DEBUG_LEVEL)

        if not id_.hasArgs:  # The macro doesn't need args
            __DEBUG__("'%s' has no args defined" % self.id_, DEBUG_LEVEL)
            tmp = id_(table, self)  # If no args passed, returned as is
            if self.callargs is not None:
                tmp += "(" + ", ".join(args) + ")"

            __DEBUG__("evaluation result: %s" % tmp, DEBUG_LEVEL)
            return tmp

        # Now ensure both args and callargs have the same length
        if len(self.callargs) != len(id_.args):
            raise PreprocError(
                'Macro "%s" expected %i params, got %i' % (str(self.id_), len(id_.args), len(self.callargs)),
                self.lineno,
            )

        # Carry out unification
        __DEBUG__("carrying out args unification", DEBUG_LEVEL)
        for i in range(len(self.callargs)):
            __DEBUG__("arg '%s' = '%s'" % (id_.args[i].name, args[i]), DEBUG_LEVEL)
            table.set(id_.args[i].name, self.lineno, args[i])

        tmp = id_(table, self)
        return tmp

    def is_defined(self, symbolTable: "prepro.DefinesTable" = None) -> bool:
        """True if this macro has been defined"""
        if symbolTable is None:
            symbolTable = self.table

        assert isinstance(self.id_, str)
        return symbolTable.defined(self.id_)
