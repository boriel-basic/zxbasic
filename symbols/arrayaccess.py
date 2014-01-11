#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import  api.global_ as gl
from api.errmsg import syntax_error
from api.errmsg import warning
from api.check import is_number
from api.constants import TYPE_SIZES
from api.constants import CLASS

from call import SymbolCALL
from number import SymbolNUMBER as NUMBER
from typecast import SymbolTYPECAST as TYPECAST
from binary import SymbolBINARY as BINARY
from vararray import SymbolVARARRAY

from type_ import Type

class SymbolARRAYACCESS(SymbolCALL):
    ''' Defines an array access. It's pretty much like a function call
    (e.g. A(1, 2) could be an array access or a function call, depending on
    context). So we derive this class from SymbolCall

    Initializing this with SymbolARRAYACCESS(symbol, ARRAYLOAD) will
    make the returned expression to be loaded into the stack (by default
    it only returns the pointer address to the element).

    Parameters:
        entry will be the symboltable entry.
        Arglist a SymbolARGLIST instance.
    '''
    def __init__(self, entry, arglist, lineno, offset=None):
        SymbolCALL.__init__(self, entry, arglist, lineno)
        self.offset = offset

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
    def scope(self):
        return self.entry.scope

    @classmethod
    def make_node(cls, id_, arglist, lineno):
        ''' Creates an array access. A(x1, x2, ..., xn)
        '''
        check = gl.SYMBOL_TABLE.check_class(id_, CLASS.array, lineno)
        if not check:
            return None

        if not gl.SYMBOL_TABLE.check_is_declared(id_, lineno, 'array'):
            return None

        variable = gl.SYMBOL_TABLE.get_entry(id_)
        if len(variable.bounds) != len(arglist):
            syntax_error(lineno, "Array '%s' has %i dimensions, not %i" %
                         (variable.name, len(variable.bounds), len(arglist)))
            return None

        offset = 0
        # Now we must typecast each argument to a u16 (POINTER) type
        # i is the dimension ith index, b is the bound
        for i, b in zip(arglist, variable.bounds):
            lower_bound = NUMBER(b.lower, type_=Type.uinteger, lineno=lineno)
            i.value = BINARY.make_node('MINUS',
                                       TYPECAST.make_node(gl.SYMBOL_TABLE.basic_types[gl.BOUND_TYPE],
                                                          i.children[0], lineno),
                                       lower_bound, lineno, lambda x, y: x - y,
                                       type_=Type.uinteger)

            if is_number(i.value):
                val = i.value.value
                if val < 0 or val > (b.upper - b.lower):
                    warning(lineno, "Array '%s' subscript out of range" % id)

                if offset is not None:
                    offset = offset * (1 + b.upper - b.lower) + val
            else:
                offset = None

        if offset is not None:
            offset *= variable.type_.size

        # Returns the variable entry and the node
        return cls(variable, arglist, lineno, offset=offset)
