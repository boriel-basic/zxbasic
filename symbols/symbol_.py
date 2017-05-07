#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import re
from ast_ import Ast
import api.global_


class Symbol(Ast):
    """ Symbol object to store everything related to
    a symbol.
    """
    def __init__(self, *children):
        super(Symbol, self).__init__()
        self._t = None
        for child in children:
            assert isinstance(child, Symbol)
            self.appendChild(child)

    @property
    def token(self):
        """ token = AST Symbol class name, removing the 'Symbol' prefix.
        """
        return self.__class__.__name__[6:]  # e.g. 'CALL', 'NUMBER', etc...

    def __str__(self):
        return self.token

    def __repr__(self):
        return str(self)

    @property
    def t(self):
        if self._t is None:
            self._t = api.global_.optemps.new_t()

        return self._t

    def copy_attr(self, other):
        """ Copies all other attributes (not methods)
        from the other object to this instance.
        """
        if not isinstance(other, Symbol):
            return  # Nothing done if not a Symbol object

        tmp = re.compile('__.*__')
        for attr in (x for x in dir(other) if not tmp.match(x)):

            if hasattr(self.__class__, attr) and str(type(getattr(self.__class__, attr)) in ('property', 'function', 'instancemethod')):
                continue

            val = getattr(other, attr)
            if isinstance(val, str) or str(val)[0] != '<':  # Not a value
                setattr(self, attr, val)
