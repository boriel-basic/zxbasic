#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from obj import gl
from obj import OPTIONS
from obj.errmsg import syntax_error, warning

from constants import TYPE_SIZES
from symbol import Symbol


# ----------------------------------------------------------------------
# IDentifier Symbol object
# ----------------------------------------------------------------------
class SymbolID(Symbol):
    ''' Defines an ID (Identifier) symbol.
    '''
    def __init__(self, value, lineno, offset = None):
        global SYMBOL_TABLE

        Symbol.__init__(self, value, 'ID')
        self.id = value
        self.filename = gl.FILENAME    # In which file was first used
        self.lineno = lineno        # In which line was first used
        self._class = None
        self._mangled = '_%s' % value # This value will be overriden later
        self.t = self._mangled
        self.declared = False # if declared (DIM var AS <type>) this must be True
        self._type = None # Unknown type
        self.offset = offset # For local variables, offset from top of the stack
        self.default_value = None # If defined, variable will be initialized with this value (Arrays = List of Bytes)
        self.scope = 'global' # One of 'global', 'parameter', 'local'
        self.byref = False    # By default, it's a global var
        self.default_value = None # For variables, this is the default initalized value
        self.__kind = None  # If not None, it should be one of 'function' or 'sub'
        self.addr = None    # If not None, the address of this symbol (string)
        self.alias = None    # If not None, this var is an alias of another
        self.aliased_by = [] # Which variables are an alias of this one
        self.referenced_by = []    # Which objects do use this one (e.g. sentences using this variable)
        self.references = []    # Objects referenced by this one (e.g. variables used in this sentence)
        self.accessed = False    # Where this object has been accessed (if false it might be not compiled, since it is useless)
        self.caseins = OPTIONS.case_insensitive.value # Whether this ID is case insensitive or not

    @property
    def size(self):
        return TYPE_SIZES[self._type]

    def set_kind(self, value, lineno):
        if self.__kind is not None and self.__kind != value:
            q = 'SUB' if self.__kind == 'function' else 'FUNCTION'
            syntax_error(lineno, "'%s' is a %s, not a %s" % (self.id, self.__kind.upper(), q))
            return

        self.__kind = value


    @property
    def kind(self):
        return self.__kind


    def add_alias(self, entry):
        ''' Adds id to the current list 'aliased_by'
        '''
        self.aliased_by.append(entry)


    def make_alias(self, entry):
        ''' Make this variable an alias of another one
        '''
        entry.add_alias(self)
        self.alias = entry
        self.scope = entry.scope # Even local declared aliases can be "global" (static)
        self.byref = entry.byref
        self.offset = entry.offset
        self.addr = entry.addr


    @property
    def is_aliased(self):
        ''' Return if this symbol is aliased by another
        '''
        return len(self.aliased_by) > 0


