# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from collections.abc import Iterable
from typing import Optional

import src.api.global_ as gl
from src.api import check, errmsg
from src.api.constants import CLASS
from src.symbols.arglist import SymbolARGLIST
from src.symbols.argument import SymbolARGUMENT
from src.symbols.id_ import SymbolID
from src.symbols.id_.ref import FuncRef
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import Type


class SymbolCALL(Symbol):
    """Defines function / procedure call. E.g. F(1, A + 2)
    It contains the symbol table entry of the called function (e.g. F)
    And a list of arguments. (e.g. (1, A + 2) in this example).

    Parameters:
        id_: The symbol table entry
        arglist: a SymbolARGLIST instance
        lineno: source code line where this call was made
    """

    def __init__(self, entry: SymbolID, arglist: Iterable[SymbolARGUMENT], lineno: int, filename: str):
        assert isinstance(entry, SymbolID)
        assert all(isinstance(x, SymbolARGUMENT) for x in arglist)
        assert entry.class_ in (CLASS.array, CLASS.function, CLASS.sub, CLASS.unknown)

        super().__init__()
        self.entry = entry
        self.args = arglist  # Func. call / array access
        self.lineno: int = lineno
        self.filename: str = filename

        ref = entry.ref
        if isinstance(ref, FuncRef):
            for arg, param in zip(arglist, ref.params):  # Sets dependency graph for each argument -> parameter
                if arg.value is not None:
                    arg.value.add_required_symbol(param)

    @property
    def entry(self):
        return self.children[0]

    @entry.setter
    def entry(self, value: SymbolID):
        assert value.token == "FUNCTION"
        if self.children is None or not self.children:
            self.children = [value]
        else:
            self.children[0] = value

    @property
    def args(self):
        return self.children[1]

    @args.setter
    def args(self, value):
        assert isinstance(value, SymbolARGLIST)
        if self.children is None or not self.children:
            self.children = [None]

        if len(self.children) < 2:
            self.children.append(value)
            return

        self.children[1] = value

    @property
    def type_(self):
        return self.entry.type_

    @classmethod
    def make_node(cls, id_: str, params, lineno: int, filename: str) -> Optional["SymbolCALL"]:
        """This will return an AST node for a function/procedure call."""
        assert isinstance(params, SymbolARGLIST)
        entry = gl.SYMBOL_TABLE.access_func(id_, lineno)
        if entry is None:  # A syntax / semantic error
            return None

        if entry.callable is False:  # Is it NOT callable?
            if entry.type_ != Type.string:
                errmsg.syntax_error_not_array_nor_func(lineno, id_)
                return None

        if entry.declared and not entry.forwarded:
            check.check_call_arguments(lineno, id_, params, filename)
        else:  # All functions goes to global scope by default
            if entry.token != "FUNCTION":
                entry = entry.to_function(lineno)
            gl.SYMBOL_TABLE.move_to_global_scope(id_)
            result = cls(entry, params, lineno, filename)
            gl.FUNCTION_CALLS.append(result)
            return result

        return cls(entry, params, lineno, filename)
