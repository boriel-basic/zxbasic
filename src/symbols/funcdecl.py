# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import src.api.symboltable.scope
from src.api import global_
from src.api.constants import CLASS
from src.symbols.id_ import SymbolID
from src.symbols.symbol_ import Symbol


class SymbolFUNCDECL(Symbol):
    """Defines a Function or Sub declaration"""

    def __init__(self, entry: SymbolID, lineno):
        assert isinstance(entry, SymbolID)
        super().__init__()
        self.entry = entry  # Symbol table entry
        self.lineno = lineno  # Line of this function declaration

    @property
    def entry(self):
        return self.children[0]

    @entry.setter
    def entry(self, value: SymbolID):
        assert isinstance(value, SymbolID) and value.token == "FUNCTION"
        self.children = [value]

    @property
    def name(self):
        return self.entry.name

    @property
    def locals_size(self):
        return self.entry.ref.locals_size

    @locals_size.setter
    def locals_size(self, value):
        self.entry.ref.locals_size = value

    @property
    def local_symbol_table(self):
        return self.entry.ref.local_symbol_table

    @local_symbol_table.setter
    def local_symbol_table(self, value):
        assert isinstance(value, src.api.symboltable.scope.Scope)
        self.entry.ref.local_symbol_table = value

    @property
    def type_(self):
        return self.entry.type_

    @type_.setter
    def type_(self, value):
        self.entry.type_ = value

    @property
    def size(self):
        return self.type_.size

    @property
    def mangled(self):
        return self.entry.mangled

    @classmethod
    def make_node(cls, func_name: str, lineno: int, class_: CLASS, type_=None):
        """This will return a node with the symbol as a function."""
        assert class_ in (CLASS.sub, CLASS.function)
        entry = global_.SYMBOL_TABLE.declare_func(func_name, lineno, type_=type_, class_=class_)
        if entry is None:
            return None

        entry.declared = True
        return cls(entry, lineno)
