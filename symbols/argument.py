#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------


from symbol_ import Symbol
from typecast import SymbolTYPECAST
from var import SymbolVAR
from api.config import OPTIONS


class SymbolARGUMENT(Symbol):
    ''' Defines an argument in a function call
    '''
    def __init__(self, value, lineno, byref=None):
        ''' Initializes the argument data. Byref must be set
        to True if this Argument is passed by reference.
        '''
        Symbol.__init__(self, value)
        self.lineno = lineno
        self.set_byref(byref if byref is not None else OPTIONS.byref.value, lineno)

    @property
    def value(self):
        return self.children[0]

    @value.setter
    def value(self, val):
        self.children[0] = val

    @property
    def type_(self):
        return self.value.type_

    @property
    def class_(self):
        return self.value.class_

    @property
    def byref(self):
        if isinstance(self.value, SymbolVAR):
            return self.value.byref
        return False  # By Value if not a Variable

    def set_byref(self, value, lineno):
        if isinstance(self.value, SymbolVAR):
            self.value.byref = value
        else:
            if value:
                # Argument can't be passed by ref because it's not an lvalue (an identifier)
                raise AttributeError

    @property
    def size(self):
        return self.type_.size

    def __eq__(self, other):
        return self.value == other

    def typecast(self, type_):
        ''' Test type casting to the argument expression.
        On sucess changes the node value to the new typecast, and returns
        True. On failure, returns False, and the node value is set to None.
        '''
        self.value = SymbolTYPECAST.make_node(type_, self.value, self.lineno)
        return self.value is not None
