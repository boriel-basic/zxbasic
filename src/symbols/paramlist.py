# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.symbols.symbol_ import Symbol


class SymbolPARAMLIST(Symbol):
    """Defines a list of parameters definitions in a function header"""

    def __init__(self, *params):
        super().__init__(*params)
        self.size = 0

    def __getitem__(self, key):
        return self.children[key]

    def __setitem__(self, key, value):
        self.children[key] = value

    def __len__(self):
        return len(self.children)

    def __iter__(self):
        for child in self.children:
            yield child

    @classmethod
    def make_node(cls, node, *params: list[SymbolID]):
        """This will return a node with a param_list
        (declared in a function declaration)
        Parameters:
            -node: A SymbolPARAMLIST instance or None
            -params: SymbolPARAMDECL instances
        """
        if node is None:
            node = cls()

        if node.token != "PARAMLIST":
            return cls.make_node(None, node, *params)

        for i in params:
            if i is not None:
                assert i.t
                node.append_child(i)

        return node

    def append_child(self, param):
        """Overrides base class."""
        Symbol.append_child(self, param)
        if param.ref.offset is None:
            param.ref.offset = self.size
            self.size += param.size
