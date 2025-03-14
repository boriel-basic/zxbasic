# vim: ts=4:et:sw=4:
from functools import cached_property
from typing import Optional

import src.api.global_ as gl
from src.api import check, errmsg
from src.api.constants import SCOPE
from src.symbols.arglist import SymbolARGLIST
from src.symbols.call import SymbolCALL
from src.symbols.id_ import SymbolID
from src.symbols.typecast import SymbolTYPECAST as TYPECAST

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------


class SymbolARRAYACCESS(SymbolCALL):
    """Defines an array access. It's pretty much like a function call
    (e.g. A(1, 2) could be an array access or a function call, depending on
    context). So we derive this class from SymbolCall

    Initializing this with SymbolARRAYACCESS(symbol, ARRAYLOAD) will
    make the returned expression to be loaded into the stack (by default
    it only returns the pointer address to the element).

    Parameters:
        entry will be the symbol table entry.
        Arglist a SymbolARGLIST instance.
    """

    def __init__(self, entry, arglist: SymbolARGLIST, lineno: int, filename: str):
        super().__init__(entry, arglist, lineno, filename)
        assert all(gl.BOUND_TYPE == x.type_.type_ for x in arglist), "Invalid type for array index"
        self.entry.ref.is_dynamically_accessed = True

    @property
    def entry(self):
        return self.children[0]

    @entry.setter
    def entry(self, value: SymbolID):
        assert isinstance(value, SymbolID) and value.token == "VARARRAY"
        if self.children is None or not self.children:
            self.children = [value]
        else:
            self.children[0] = value

    @property
    def type_(self):
        return self.entry.type_

    @property
    def arglist(self):
        return self.children[1]

    @arglist.setter
    def arglist(self, value: SymbolARGLIST):
        assert isinstance(value, SymbolARGLIST)
        self.children[1] = value

    @property
    def scope(self):
        return self.entry.scope

    @cached_property
    def offset(self) -> int | None:
        """If this is a constant access (e.g. A(1))
        return the offset in bytes from the beginning of the
        variable in memory.

        Otherwise, if it's not constant (e.g. A(i))
        returns None
        """
        if self.scope == SCOPE.parameter:
            return None

        offset = 0
        # Now we must typecast each argument to a u16 (POINTER) type
        # i is the dimension ith index, b is the bound
        for i, b in zip(self.arglist, self.entry.bounds):
            tmp = i.children[0]
            if check.is_number(tmp) or check.is_const(tmp):
                offset = offset * b.count + (tmp.value - b.lower)
            else:
                return None

        offset *= self.type_.size
        return offset

    @cached_property
    def is_constant(self) -> bool:
        """Whether this array access is constant.
        e.g. A(1) is constant. A(i) is not."""
        return self.offset is None

    @classmethod
    def make_node(cls, id_: str, arglist: SymbolARGLIST, lineno: int, filename: str) -> Optional["SymbolARRAYACCESS"]:
        """Creates an array access. A(x1, x2, ..., xn)"""
        assert isinstance(arglist, SymbolARGLIST)
        variable = gl.SYMBOL_TABLE.access_array(id_, lineno)
        if variable is None:
            return None

        if variable.scope != SCOPE.parameter:
            if len(variable.bounds) != len(arglist):
                errmsg.error(
                    lineno, "Array '%s' has %i dimensions, not %i" % (variable.name, len(variable.bounds), len(arglist))
                )
                return None

            # Checks for array subscript range if the subscript is constant
            # e.g. A(1) is a constant subscript access
            btype = gl.SYMBOL_TABLE.basic_types[gl.BOUND_TYPE]
            for i, b in zip(arglist, variable.bounds):
                if check.is_number(i.value) or check.is_const(i.value):
                    val = i.value.value
                    if val < b.lower or val > b.upper:
                        errmsg.warning(lineno, "Array '%s' subscript out of range" % id_)

                i.value = TYPECAST.make_node(btype, i.value, lineno)
        else:
            btype = gl.SYMBOL_TABLE.basic_types[gl.BOUND_TYPE]
            for arg in arglist:
                arg.value = TYPECAST.make_node(btype, arg.value, arg.value.lineno)

        # Returns the variable entry and the node
        return cls(variable, arglist, lineno, filename)
