#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol import Symbol


class SymbolCALL(Symbol):
    ''' Defines function call. E.g. F(1, A + 2)
    It contains the symboltable entry of the called function (e.g. F)
    And a list of arguments. (e.g. (1, A + 2) in this example).
    
    Parameters:
        id_: The symbol table entry
        arglist: a SymbolArglist instance
        lineno: source code line where this call was made
        access: 'FUNCALL' to signalize this is a Function Call an not an
                array access, which has the same syntax.
                
    The last parameter is FUNCCALL by default. But can later be changed
    if the compiler discover it was an ARRAYACCESS for example.
    '''
    def __init__(self, id_, arglist, lineno, access = 'FUNCCALL'):
        Symbol.__init__(self, id_, arglist) # Func. call / array access
        self.lineno = lineno
        self.access = access

    @property
    def entry(self):
        return self.children[0]

    @property
    def args(self):
        return self.children[1]

    @property
    def type_(self):
        return self.entry.type_
