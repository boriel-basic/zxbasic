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
from api.constants import CLASS
from api.config import OPTIONS
from api.decorator import classproperty
from .symbol_ import Symbol


class SymbolTYPE(Symbol):
    ''' A Type definition. Defines a type,
    both user defined or basic ones.
    '''
    def __init__(self, name, lineno, *children):
        # All children (if any) must be SymbolTYPE
        assert len(children) == len([x for x in children if isinstance(x, SymbolTYPE)])

        Symbol.__init__(self, *children)
        self.name = name  # typename
        self.lineno = lineno  # The line the type was defined. Line 0 = basic type
        self.final = self  # self.final always return the original aliased type (if this type is an alias)
        self.caseins = OPTIONS.case_insensitive.value  # Whether this ID is case insensitive or not
        self.class_ = CLASS.type_
        self.accessed = False  # Whether this type has been used or not

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
        if len(self.children) == 1:
            return self.children[0].is_basic

        return False

    @property
    def is_signed(self):
        if self is not self.final:
            return self.final.is_signed

        if len(self.children) != 1:
            return False

        return self.children[0].is_signed

    @property
    def is_dynamic(self):
        ''' True if this type uses dynamic (Heap) memory.
        e.g. strings or dynamic arrays
        '''
        if self is not self.final:
            return self.final.is_dynamic

        return any([x.is_dynamic for x in self.children])

    @property
    def is_alias(self):
        ''' Whether this is an alias of another type or not.
        '''
        return False

    def __eq__(self, other):
        if self is not self.final:
            return self.final == other

        other = other.final  # remove alias

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

    def __ne__(self, other):
        return not (self == other)

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        if self is not self.final:
            return bool(self.final)

        for x in self.children:
            if x:
                return True
        return False



class SymbolBASICTYPE(SymbolTYPE):
    ''' Defines a basic type (Ubyte, Byte, etc..)
    Basic (default) types are defined upon start and are case insensitive.
    If name is None or '', default typename from TYPES.to_string will be used.
    '''
    def __init__(self, type_, name=None):
        ''' type_ = Internal representation (e.g. TYPE.ubyte)
        '''
        assert TYPE.is_valid(type_)
        if not name:
            name = TYPE.to_string(type_)
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

    @property
    def is_signed(self):
        return TYPE.is_signed(self.type_)

    def to_signed(self):
        ''' Returns another instance with the signed equivalent
        of this type.
        '''
        return SymbolBASICTYPE(TYPE.to_signed(self.type_))

    @property
    def is_dynamic(self):
        return self.type_ == TYPE.string

    def __hash__(self):
        return self.type_

    def __eq__(self, other):
        if self is not self.final:
            return self.final == other

        other = other.final  # remove alias

        if other.is_basic:  # for both basic types, just compare
            return self.type_ == other.final.type_

        assert other.children  # must be not empty
        if len(other.children) > 1:  # Different size
            return False

        return self == other.children[0]

    def __bool__(self):
        return self.type_ != TYPE.unknown


class SymbolTYPEALIAS(SymbolTYPE):
    ''' Defines a type which is alias of another
    '''
    def __init__(self, name, lineno, alias):
        assert isinstance(alias, SymbolTYPE)
        SymbolTYPE.__init__(self, name, lineno, alias)
        self.final = alias.final

    @property
    def is_alias(self):
        ''' Whether this is an alias of another type or not.
        '''
        return True

    def __eq__(self, other):
        return self.final == other.final  # remove aliases if any

    @property
    def size(self):
        return self.final.size

    @property
    def is_basic(self):
        return self.final.is_basic

    @property
    def alias(self):
        return self.children[0]

    @property
    def to_signed(self):
        assert self.is_basic
        return self.final.to_signed()


class SymbolTYPEREF(SymbolTYPEALIAS):
    ''' Creates a Type reference or usage.
    Eg. DIM a As Integer
    In this case, the Integer type is accessed.
    It's an alias type, containing just the
    original Type definition (SymbolTYPE), the
    the lineno it is currently being accessed,
    and if it was implicitly inferred or explicitly declared.
    '''
    def __init__(self, type_, lineno, implicit=False):
        assert(isinstance(type_, SymbolTYPE))
        SymbolTYPEALIAS.__init__(self, type_.name, lineno, type_)
        self.implicit = implicit

    def to_signed(self):
        assert self.is_basic
        return self.final.to_signed()

    @property
    def type_(self):
        assert self.is_basic
        return self.final.type_


class Type(object):
    ''' Class for enumerating Basic Types.
    e.g. Type.string.
    '''
    unknown = auto = SymbolBASICTYPE(TYPE.unknown)
    ubyte = SymbolBASICTYPE(TYPE.ubyte)
    byte_ = SymbolBASICTYPE(TYPE.byte_)
    uinteger = SymbolBASICTYPE(TYPE.uinteger)
    long_ = SymbolBASICTYPE(TYPE.long_)
    ulong = SymbolBASICTYPE(TYPE.ulong)
    integer = SymbolBASICTYPE(TYPE.integer)
    fixed = SymbolBASICTYPE(TYPE.fixed)
    float_ = SymbolBASICTYPE(TYPE.float_)
    string = SymbolBASICTYPE(TYPE.string)

    types = [unknown,
             ubyte, byte_,
             uinteger, integer,
             ulong, long_,
             fixed, float_,
             string]

    _by_name = {x.name: x for x in types}

    @staticmethod
    def size(t):
        assert isinstance(t, SymbolTYPE)
        return t.size

    @staticmethod
    def to_string(t):
        assert isinstance(t, SymbolTYPE)
        return t.name

    @classmethod
    def by_name(cls, typename):
        ''' Converts a given typename to Type
        '''
        return cls._by_name.get(typename, None)

    @classproperty
    def integrals(cls):
        return (cls.byte_, cls.ubyte, cls.integer, cls.uinteger,
                cls.long_, cls.ulong)

    @classproperty
    def signed(cls):
        return cls.byte_, cls.integer, cls.long_, cls.fixed, cls.float_

    @classproperty
    def unsigned(cls):
        return cls.ubyte, cls.uinteger, cls.ulong

    @classproperty
    def decimals(cls):
        return cls.fixed, cls.float_

    @classproperty
    def numbers(cls):
        return tuple(list(cls.integrals) + list(cls.decimals))

    @classmethod
    def is_numeric(cls, t):
        assert isinstance(t, SymbolTYPE)
        return t.final in cls.numbers

    @classmethod
    def is_signed(cls, t):
        assert isinstance(t, SymbolTYPE)
        return t.final in cls.signed

    @classmethod
    def is_unsigned(cls, t):
        assert isinstance(t, SymbolTYPE)
        return t.final in cls.unsigned

    @classmethod
    def is_integral(cls, t):
        assert isinstance(t, SymbolTYPE)
        return t.final in cls.integrals

    @classmethod
    def is_decimal(cls, t):
        assert isinstance(t, SymbolTYPE)
        return t.final in cls.decimals

    @classmethod
    def is_string(cls, t):
        assert isinstance(t, SymbolTYPE)
        return t.final == cls.string

    @classmethod
    def to_signed(cls, t):
        ''' Return signed type or equivalent
        '''
        assert isinstance(t, SymbolTYPE)
        t = t.final
        assert t.is_basic
        if cls.is_unsigned(t):
            return {cls.ubyte: cls.byte_,
                    cls.uinteger: cls.integer,
                    cls.ulong: cls.long_}[t]
        if cls.is_signed(t) or cls.is_decimal(t):
            return t
        return cls.unknown
