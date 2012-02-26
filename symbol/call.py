#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import gl
from typecheck import check_call_arguments
from symbol import Symbol



class Call(Symbol):
    ''' Defines a list of arguments in a function call/array access/string
    '''
    def __init__(self, lineno, _id, params, name = 'FUNCCALL'):
        if params is None:
            params = []

        entry = gl.SYMBOL_TABLE.make_callable(_id, lineno)
        if entry._class is None:
            entry._class = 'function'
    
        entry.accessed = True
        gl.SYMBOL_TABLE.check_class(_id, 'function', lineno)
    
        if entry.declared:
            check_call_arguments(lineno, _id, params)
        else:
            gl.SYMBOL_TABLE.move_to_global_scope(_id) # All functions goes to global scope (no nested functions)
            gl.FUNCTION_CALLS.append((_id, params, lineno,))

        Symbol.__init__(self, entry._mangled, name) # Func. call / array access
        self.entry = entry
        self.t = gl.optemps.new_t()
        self.lineno = lineno
        self.params = params

    @property
    def _type(self):
        return self.entry._type

    @property
    def size(self):
        return TYPE_SIZES[self._type]

    @property
    def args(self):
        return self.params

    @property
    def child(self):
        return self.params

