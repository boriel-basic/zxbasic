#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api.constants import TYPE
from symbol_ import Symbol


class SymbolTYPE(Symbol):
    ''' Defines a type, both user defined or basic ones.
    '''
    def __init__(self, name, lineno, *children):
        ''' Implicit = True if this type has been
        "inferred" by default, or by the expression surrounding
        the ID.
        '''
        # All children must be SymbolTYPE
        assert len(children) == len(x for x in children if isinstance(x, SymbolTYPE))

        Symbol.__init__(self, *children)
        self.name = name  # typename
        self.lineno = lineno  # The line the type was defined. Line 0 = basic type
        self.final = self  # self.final always return the original aliased type (if this type is an alias)

    def __repr__(self):
        return "%s(%s)" % (self.token, str(self))

    def __str__(self):
        return self.name

    @property
    def size(self):
        return sum(x.size for x in self.children)

    @property
    def is_basic(self):
        ''' Whether this is a basic (canonical) type or not.
        '''
        return False

    @property
    def is_alias(self):
        ''' Whether this is an alias of another type or not.
        '''
        return False

    def __cmp__(self, other):
        if other.final != other:  # remove alias
            other = other.final

        if other.is_basic:
            return other == self

        if len(self.children) == 1:
            return self.children[0] == other

        if len(other.children) == 1:
            return other.children[0] == self

        if len(self.children) != len(other.children):
            return False

        for i, j in zip(self.children, other.children):
            if i != j:
                return False

        return True



class SymbolBASICTYPE(SymbolTYPE):
    ''' Defines a basic type (Ubyte, Byte, etc..)
    Basic (default) types are defined upon start and are case insensitive.
    '''
    def __init__(self, name, type_):
        ''' type_ = Internal representation (e.g. TYPE.ubyte)
        '''
        assert TYPE.is_valid(type_)
        SymbolTYPE.__init__(self, name, 0)
        self.type_ = type_

    @property
    def size(self):
        return TYPE.size(self.type_)

    @property
    def is_basic(self):
        ''' Whether this is a basic (canonical) type or not.
        '''
        return True

    def __eq__(self, other):
        if other.final != other:  # unalias type
            other = other.final

        if other.is_basic:  # for both basic types, just compare
            return self.type_ == other.final.type_

        assert other.children  # must be not empty
        if len(other.children) > 1:  # Different size
            return False

        return self == other.children[0]


class SymbolTYPEALIAS(SymbolTYPE):
    ''' Defines a type which is alias of another
    '''
    def __init__(self, name, lineno, alias):
        assert isinstance(alias, SymbolTYPE)
        SymbolTYPE.__init__(self, name, lineno)
        self.alias = alias
        self.final = alias.final

    @property
    def is_alias(self):
        ''' Whether this is an alias of another type or not.
        '''
        return True

    def __cmp__(self, other):
        return self.final == other.final  # remove aliases if any



