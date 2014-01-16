#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api import global_
from api.config import OPTIONS
from api.constants import SCOPE
from api.constants import KIND
from api.constants import CLASS
from symbol_ import Symbol
from type_ import SymbolTYPE

# ----------------------------------------------------------------------
# IDentifier Symbol object
# ----------------------------------------------------------------------
class SymbolVAR(Symbol):
    ''' Defines an VAR (Variable) symbol.
    These class and their children classes are also stored in the symbol
    table as table entries to store variable data
    '''
    def __init__(self, varname, lineno, offset=None, type_=None, class_=None):
        Symbol.__init__(self)
        self.name = varname
        self.filename = global_.FILENAME    # In which file was first used
        self.lineno = lineno        # In which line was first used
        self.class_ = class_
        self.mangled = '_%s' % varname  # This value will be overriden later
        self.declared = False  # if explicitly declared (DIM var AS <type>)
        self.type_ = type_  # if None => unknown type (yet)
        self.offset = offset  # If local variable, offset from top of the stack
        self.default_value = None  # If defined, variable will be initialized with this value (Arrays = List of Bytes)
        self.scope = SCOPE.global_  # One of 'global', 'parameter', 'local'
        self.byref = False    # By default, it's a global var
        self.default_value = None  # default initialized value
        self.__kind = KIND.var  # If not None, it should be one of 'function' or 'sub'
        self.addr = None    # If not None, the address of this symbol (string)
        self.alias = None   # If not None, this var is an alias of another
        self.aliased_by = []  # Which variables are an alias of this one
        #self.referenced_by = []  # Which objects do use this one (e.g. sentences using this variable)
        #self.references = []    # Objects referenced by this one (e.g. variables used in this sentence)
        self.accessed = False  # Where this object has been accessed (if false it might be not compiled)
        self.caseins = OPTIONS.case_insensitive.value  # Whether this ID is case insensitive or not
        self._t = global_.optemps.new_t()

    @property
    def size(self):
        if self.type_ is None:
            return 0
        return self.type_.size

    @property
    def kind(self):
        return self.__kind

    def set_kind(self, value, lineno):
        assert KIND.is_valid(value)

        # TODO: This is no longer needed
        '''
        if self.__kind is not None and self.__kind != value:
            q = 'SUB' if self.__kind == KIND.function else 'FUNCTION'
            syntax_error(lineno, "'%s' is a %s, not a %s" %
                         (self.name, KIND.to_string(self.__kind).upper(), q))
            return
        '''
        self.__kind = value

    @property
    def byref(self):
        return self.__byref

    @byref.setter
    def byref(self, value):
        assert isinstance(value, bool)
        self.__byref = value

    def add_alias(self, entry):
        ''' Adds id to the current list 'aliased_by'
        '''
        assert isinstance(entry, SymbolVAR)
        self.aliased_by.append(entry)

    def make_alias(self, entry):
        ''' Make this variable an alias of another one
        '''
        entry.add_alias(self)
        self.alias = entry
        self.scope = entry.scope  # Local aliases can be "global" (static)
        self.byref = entry.byref
        self.offset = entry.offset
        self.addr = entry.addr

    @property
    def is_aliased(self):
        ''' Return if this symbol is aliased by another
        '''
        return len(self.aliased_by) > 0

    def __str__(self):
        return self.name

    def __repr__(self):
        return "ID:%s" % str(self)

    @property
    def t(self):
        return self.mangled if self.scope == SCOPE.global_ else self._t

    @property
    def type_(self):
        return self._type

    @type_.setter
    def type_(self, value):
        assert (value is None) or isinstance(value, SymbolTYPE)
        self._type = value

    @staticmethod
    def to_label(var_instance):
        ''' Converts a var_instance to a label one
        '''
        # This can be done 'cause LABEL is just a dummy descent of VAR
        from symbols import LABEL
        var_instance.__class__ = LABEL
        var_instance.class_ = CLASS.label
        return var_instance
