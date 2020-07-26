#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import api.global_ as gl
from api.errmsg import error
from api.errmsg import warning
from api.check import is_number
from api.check import is_const
from api.constants import SCOPE

from .call import SymbolCALL
from .number import SymbolNUMBER as NUMBER
from .typecast import SymbolTYPECAST as TYPECAST
from .binary import SymbolBINARY as BINARY
from .vararray import SymbolVARARRAY
from .arglist import SymbolARGLIST


class SymbolARRAYACCESS(SymbolCALL):
    """ Defines an array access. It's pretty much like a function call
    (e.g. A(1, 2) could be an array access or a function call, depending on
    context). So we derive this class from SymbolCall

    Initializing this with SymbolARRAYACCESS(symbol, ARRAYLOAD) will
    make the returned expression to be loaded into the stack (by default
    it only returns the pointer address to the element).

    Parameters:
        entry will be the symbol table entry.
        Arglist a SymbolARGLIST instance.
    """
    def __init__(self, entry, arglist, lineno):
        super(SymbolARRAYACCESS, self).__init__(entry, arglist, lineno)
        assert all(gl.BOUND_TYPE == x.type_.type_ for x in arglist), "Invalid type for array index"

    @property
    def entry(self):
        return self.children[0]

    @entry.setter
    def entry(self, value):
        assert isinstance(value, SymbolVARARRAY)
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
    def arglist(self, value):
        assert isinstance(value, SymbolARGLIST)
        self.children[1] = value

    @property
    def scope(self):
        return self.entry.scope

    @property
    def offset(self):
        """ If this is a constant access (e.g. A(1))
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
            if is_number(tmp) or is_const(tmp):
                if offset is not None:
                    offset = offset * b.count + tmp.value
            else:
                offset = None
                break

        if offset is not None:
            offset *= self.type_.size

        return offset

    @classmethod
    def make_node(cls, id_, arglist, lineno):
        """ Creates an array access. A(x1, x2, ..., xn)
        """
        assert isinstance(arglist, SymbolARGLIST)
        variable = gl.SYMBOL_TABLE.access_array(id_, lineno)
        if variable is None:
            return None

        if variable.scope != SCOPE.parameter:
            if len(variable.bounds) != len(arglist):
                error(lineno, "Array '%s' has %i dimensions, not %i" %
                      (variable.name, len(variable.bounds), len(arglist)))
                return None

            # Checks for array subscript range if the subscript is constant
            # e.g. A(1) is a constant subscript access
            btype = gl.SYMBOL_TABLE.basic_types[gl.BOUND_TYPE]
            for i, b in zip(arglist, variable.bounds):
                lower_bound = NUMBER(b.lower, type_=btype, lineno=lineno)

                if is_number(i.value) or is_const(i.value):
                    val = i.value.value
                    if val < b.lower or val > b.upper:
                        warning(lineno, "Array '%s' subscript out of range" % id_)

                i.value = BINARY.make_node('MINUS',
                                           TYPECAST.make_node(btype, i.value, lineno),
                                           lower_bound, lineno, func=lambda x, y: x - y,
                                           type_=btype)
        else:
            btype = gl.SYMBOL_TABLE.basic_types[gl.BOUND_TYPE]
            for arg in arglist:
                arg.value = TYPECAST.make_node(btype, arg.value, arg.value.lineno)

        # Returns the variable entry and the node
        return cls(variable, arglist, lineno)
