#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol.var import SymbolVAR
from symbol.vararray import SymbolVARARRAY
from symbol.typecast import SymbolTYPECAST
from symbol.function import SymbolFUNCTION

from api import global_
from api.config import OPTIONS

from api.errmsg import syntax_error
from api.errmsg import warning

from api.constants import DEPRECATED_SUFFIXES
from api.constants import SUFFIX_TYPE
from api.constants import ID_CLASSES


# ----------------------------------------------------------------------
# Symbol table. Each id level will push a new symbol table
# ----------------------------------------------------------------------
class SymbolTable(object):
    ''' Implements a symbol table
    '''
    def __init__(self):
        ''' Initializes the S.T.
        '''
        self.table = [{}]    # New levels will push dictionaries
        self.mangle = ''     # Prefix for local variables
        self.mangles = []    # Mangles stack
        self.size = 0        # Size (in bytes) of variables
        self.caseins = [{}]  # Case insensitive identifiers

    def get_id_entry(self, id_, scope=None):
        ''' Returns the ID entry stored in self.table, starting
        by the first one. Returns None if not found.

        If scope is not None, only the given scope is searched.
        '''
        if id_[-1] in DEPRECATED_SUFFIXES:
            id_ = id_[:-1]  # Remove it

        idL = id_.lower()

        if scope is not None:
            if len(self.table) > scope:
                result = self.table[scope].get(id_,
                         self.caseins[scope].get(idL, None))
            return result  # Not found

        for i in range(len(self.table)):
            try:
                return self.table[i][id_]
            except KeyError:
                pass

            try:
                return self.caseins[i][idL]
            except KeyError:
                pass

        return None  # Not found

    def declare_id(self, id_, lineno):
        ''' Check there is no 'id' already declared in the current scope, and
            creates and returns it. Otherwise, returns None,
            and the caller function raises the syntax/semantic error.
        '''
        id2 = id_
        _type = None

        if id2[-1] in DEPRECATED_SUFFIXES:
            id2 = id2[:-1]  # Remove it
            _type = SUFFIX_TYPE[id_[-1]]

        # Try-except is faster than IN
        try:
            self.table[0][id2]  # Checks if already declared
            return None
        except KeyError:
            pass

        try:
            self.caseins[0][id2.lower()] # Checks for case insensitive
            return None
        except KeyError:
            pass

        entry = self.table[0][id2] = SymbolID(id2, lineno)
        entry.callable = None  # True for function, strings or arrays. False for any other
        entry.forwarded = False # True for a function header
        entry._mangled = '%s_%s' % (self.mangle, entry.id) # Mangled name
        entry.caseins = OPTIONS.case_insensitive.value
        entry._class = None
        entry._type = _type

        if entry.caseins:
            self.caseins[0][id2.lower()] = entry

        return entry


    def create_id(self, id_, lineno):
        ''' Check there is no 'id' already declared in the current scope.
        If it does exists raises an error. Otherwise creates and returns it.
        '''
        result = self.declare_id(id_, lineno)
        if result is None:
            if id_ not in self.table[0].keys(): # is it case insensitive?
                id_ = id_.lower()

            syntax_error(lineno, 'Duplicated identifier "%s" (previous one at %s:%i)' %
                (id_, self.table[0][id_].filename, self.table[0][id_].lineno))

        return result


    def get_or_create(self, id_, lineno, scope = None):
        ''' Returns the ID entry if stored in self.table,
        otherwise, creates a new one.
        '''
        entry = self.get_id_entry(id_, scope)
        if entry is not None:
            return entry

        return self.create_id(id_, lineno)


    def check_declared(self, id_, lineno, classname = 'variable'):
        ''' Checks if the given id is already defined in any scope
            or raises a Syntax Error.

            Note: classname is not the class attribute, but the name of
            the class as it would appear on compiler messages.
        '''
        result = self.get_id_entry(id_)
        if result is None or not result.declared:
            syntax_error(lineno, 'Undeclared %s "%s"' % (classname, id_))
            return None

        return result


    def check_class(self, id_, class_, lineno, scope = None):
        ''' Check the id is either undefined or defined as a
        the given class.
        '''
        if class_ not in ID_CLASSES:
            syntax_error(lineno, 'INTERNAL ERROR: Invalid class "%s". ' +
                'Please contact the autor(s).' % class_)

        entry = self.get_id_entry(id_, scope)
        if entry is None or entry.class_ is None:
            return True

        if entry.class_ != class_:
            if entry.class_ == 'array':
                a1 = 'n'
            else:
                a1 = ''

            if class_ == 'array':
                a2 = 'n'
            else:
                a2 = ''

            syntax_error(lineno, "identifier '%s' is a%s %s, not a%s %s" %
                (id_, a1, entry.class_, a2, class_))
            return False

        return True


    def start_function_body(self, funcname):
        ''' Start a new variable ambit.
        '''
        self.mangles.append(self.mangle)
        self.mangle = '%s_%s' % (self.mangle, funcname)
        self.table.insert(0, {})   # Prepends new symbol table
        self.caseins.insert(0, {}) # Prepends caseins dictionary
        global_.META_LOOPS.append(global_.LOOPS)
        global_.LOOPS = []


    def end_function_body(self):
        ''' Ends a function body and pops old symbol table.
        '''

        def entry_size(entry):
            ''' For local variables and params, returns the real variable or local array size in bytes
            '''
            if entry.scope == 'global' or entry.alias is not None: # aliases and global variables = 0
                return 0

            result = entry.size
            if (entry.class_ != 'array'):
                return result

            for bound in entry.bounds.next:
                result *= (bound.symbol.upper - bound.symbol.lower + 1)

            result += 1 + 2 * len(entry.bounds.next) # Bytes for the array header

            return result


        def sortentries(entries):
            ''' Sort in-place entries according to it sizes in ascending order
            '''
            for i in range(len(entries)):
                tmp = entries[i]
                size = entry_size(tmp)
                I = i

                for j in range(i + 1, len(entries)):
                    tmp1 = entries[j]
                    size1 = entry_size(tmp1)
                    if size > size1:
                        tmp = tmp1
                        size = size1
                        I = j

                entries[I], entries[i] = entries[i], entries[I]

        self.offset = 0
        entries = self.table[0].values()
        sortentries(entries)

        for entry in entries: # Symbols of the current level
            if entry._class is None:
                self.move_to_global_scope(entry.id_)

            if entry.class_ == 'function': continue

            if entry.class_ == 'var' and entry.scope == 'local': # Local variables offset
                if entry.alias is not None: # Is it an alias of another declared variable?
                    if entry.offset is None:
                        entry.offset = entry.alias.offset
                    else:
                        entry.offset = entry.alias.offset - entry.offset
                else:
                    self.offset += entry_size(entry)
                    entry.offset = self.offset

            if entry.class_ == 'array' and entry.scope == 'local':
                entry.offset = entry_size(entry) + self.offset
                self.offset = entry.offset


        self.mangle = self.mangles.pop()
        self.table.pop(0)
        self.caseins.pop(0)
        global_.LOOPS = global_.META_LOOPS.pop()

        return self.offset


    def move_to_global_scope(self, id_):
        ''' If the given id is in the current scope, and there is more than 1 scope,
        move the current id to the global scope and make it global. Labels need
        this.
        '''
        if id_ in self.table[0].keys() and len(self.table) > 1: # In the current scope and more than 1 scope?
            self.table[-1][id_] = self.table[0][id_]
            self.table[-1][id_].offset = None
            self.table[-1][id_].scope = 'global'
            del self.table[0][id_] # Removes it from the current scope


    def make_static(self, id_):
        ''' The given ID in the current scope is changed to 'global', but the variable remains in the
        current scope, if it's a 'global private' variable: A variable private to a function
        scope, but whose contents are not in the stack, but in the global variable area.
        These are called 'static variables' in C.

        A copy of the instance, but mangled, is also allocated in the global symbol table.
        '''
        entry = self.table[0][id_]
        entry.scope = 'global'
        self.table[-1][entry._mangled] = entry


    def make_id(self, id_, lineno, scope = None):
        ''' Checks whether the id exist or not.
        If it exist, returns it, otherwise, create it.
        Scope is related to which scope to search in the SYMBOL TABLE. If scope
        is None, all of them (from inner to outer) will be searched.
        '''
        return self.get_or_create(id_, lineno, scope)


    def make_var(self, id_, lineno, default_type = None, scope = None):
        ''' Checks whether the id exist or not.
        If it exists, it must be a variable (not a function, array, constant, or label)
        '''
        if not self.check_class(id_, 'var', lineno, scope):
            return None

        entry = self.get_or_create(id_, lineno, scope)

        if entry.declared == True:
            return entry

        entry.class_ = 'var' # Make it a variable
        entry.callable = False
        entry.scope = 'local' if len(self.table) > 1 else 'global'

        if entry.scope == 'global': # ***
            entry.t = entry.mangled
        else:  # local scope
            entry.t = global_.optemps.new_t()
            if entry._type == 'string':
                entry.t = '$' + entry.t

        if entry.typ_e is None: # First time used?
            if default_type is None:
                default_type = global_.DEFAULT_TYPE
                warning(lineno, "Variable '%s' declared as '%s'" % (id_, default_type))

            entry.type_ = default_type # Default type is unknown

        return entry


    def get_id_or_make_var(self, id_, lineno, default_type = None, scope = None):
        ''' Returns the id if already created. Otherwise, create a var
        '''
        result = self.get_id_entry(id_)
        if result is not None:
            return result

        return self.make_var(id_, lineno, default_type, scope)


    def make_vardecl(self, id_, lineno, type_, default_value = None, kind = 'variable'):
        ''' Like the above, but checks that entry.declared is False.
        Otherwise raises an error.

        Parameter default_value specifies an initalized
        variable, if set.
        '''
        entry = self.make_var(id, lineno, type_.type_, scope = 0)
        if entry is None:
            return None

        if entry.declared:
            if entry.scope == 'parameter':
                syntax_error(lineno,
                    "%s '%s' already declared as a parameter at %s:%i" %
                    (kind, id_, entry.filename, entry.lineno))
            else:
                syntax_error(lineno, "%s '%s' already declared at %s:%i" %
                    (kind, id_, entry.filename, entry.lineno))
            return None

        entry.declared = True

        if entry.type_ != type_.type_:
            if not type_.symbol.implicit:
                syntax_error(lineno,
                    "%s suffix for '%s' is for type '%s' but declared as '%s'" %
                    (kind, id_, entry.type_, type_.type_))
                return None

            type_.symbol.implicit = False
            type_.type_ = entry.type_

        if type_.symbol.implicit:
            warning_implicit_type(lineno, id_, entry.type_)

        if default_value is not None and entry.type_ != default_value.type_:
            if is_number(default_value):
                default_value = make_typecast(entry.type_, default_value)
                if default_value is None:
                    return None
            else:
                syntax_error(lineno,
                    "%s '%s' declared as '%s' but initialized with a '%s' value" %
                    (kind, id_, entry.type_, default_value.type_))
                return None

        if entry.scope != 'global' and entry.type_ == 'string':
            if entry.t[0] != '$':
                entry.t = '$' + entry.t

        if default_value is not None:
            if default_value.symbol.token != 'CONST':
                default_value = default_value.value
            else:
                default_value = default_value.symbol

        entry.default_value = default_value

        return entry


    def make_constdecl(self, id_, lineno, type_, default_value):
        entry = self.create_id(id_, lineno)

        if entry is None:
            return

        entry = self.make_vardecl(id_, lineno, type_, default_value, 'constant')

        if entry is None:
            return

        entry.class_ = 'const'
        entry.value = entry.t = default_value.value

        return entry


    def make_label(self, id_, lineno):
        ''' Unlike variables, labels are always global.
        '''
        id_ = str(id_)

        if not self.check_class(id_, 'label', lineno):
            return None

        entry = self.get_id_entry(id_)  # Must not exist, or, if created,
            # have _class = None or Function and declared = False
        if entry is None:
            entry = self.create_id(id_, lineno)

        entry.class_ = 'label'
        entry.type_ = None  # Labels does not have type

        if id_[0] == '.':
            id_ = id_[1:]
            entry.mangled = '%s' % id_ # Mangled name. Labels are just the label, 'cause it starts with '.'
        else:
            entry.mangled = '__LABEL__%s' % entry.id_ # Mangled name. Labels are __LABEL__

        entry.is_line_number = isinstance(id_, int)
        self.move_to_global_scope(id_)

        return entry


    def make_labeldecl(self, id_, lineno):
        entry = self.make_label(id_, lineno)
        if entry is None:
            return None

        if entry.declared:
            if entry.is_line_number:
                syntax_error(lineno, "Duplicated line number '%s'. Previous was at %i" %
                    (entry.id_, entry.lineno))
            else:
                syntax_error(lineno, "Label '%s' already declared at line %i" %
                    (id_, entry.lineno))
            return None

        entry.declared = True
        entry.type_ = PTR_TYPE

        return entry


    def make_paramdecl(self, id, lineno, _type = 'float'):
        ''' Like the above, but checks for parameters. Check if entry.declared is False.
        Otherwise raises an error.
        '''
        entry = self.make_var(id, lineno, _type, scope = 0)

        if entry.declared:
            syntax_error(lineno, "Parameter '%s' already declared at %s:%i" % (id, entry.filename, entry.lineno))
            return None

        entry.declared = True
        entry.scope = 'parameter'

        if entry._type == 'string' and entry.t[0] != '$':
                entry.t = '$' + entry.t

        return entry


    def make_arraydecl(self, id, lineno, _type, bounds, default_value = None):
        ''' Like the above, but declares an array. It checks that entry.declared is False.
        Otherwise raises an error.
        '''
        entry = self.make_var(id, lineno, default_type = _type._type, scope = 0)
        if entry is None:
            return None

        if not entry.declared:
            if entry.callable:
                syntax_error(lineno, "Array '%s' must be declared before use. First used at line %i" % (id, entry.lineno))
                return None
        else:
            if entry.scope == 'parameter':
                syntax_error(lineno, "variable '%s' already declared as a parameter at line %i" % (id, entry.lineno))
            else:
                syntax_error(lineno, "variable '%s' already declared at line %i" % (id, entry.lineno))
            return None

        if entry._type != _type._type:
            if not _type.symbol.implicit:
                syntax_error(lineno, "Array suffix for '%s' is for type '%s' but declared as '%s'" % (entry.id, entry._type, _type._type))
                return None

            _type.symbol.implicit = False
            _type._type = entry._type

        if _type.symbol.implicit:
            warning_implicit_type(lineno, id)

        entry.declared = True
        entry._class = 'array'
        entry._type = _type._type
        entry.bounds = bounds
        entry.count = bounds.symbol.count # Number of bounds
        entry.total_size = bounds.size * TYPE_SIZES[entry._type]
        entry.default_value = default_value
        entry.callable = True
        entry.lbound_used = entry.ubound_used = False # Flag to true when LBOUND/UBOUND used somewhere in the code

        return entry


    def make_func(self, id_, lineno):
        ''' Checks whether the id exist or not (error if exists).
        And creates the entry at the symbol table.
        '''
        if not self.check_class(id_, 'function', lineno):
            entry = self.get_id_entry(id_) # Must not exist, or, if created, hav _class = None or Function and declared = False
            an = 'an' if entry._class.lower()[0] in 'aeio' else 'a'
            syntax_error(lineno, "'%s' already declared as %s %s at %i" % (id_, an, entry.class_, entry.lineno))
            return None

        entry = self.get_id_entry(id_) # Must not exist, or, if created, hav _class = None or Function and declared = False

        if entry is not None:
            if entry.declared and not entry.forwarded:
                syntax_error(lineno, "Duplicate function name '%s', previously defined at %i" % (id_, entry.lineno))
                return None

            if entry.callable == False:
                syntax_error_not_array_nor_func(lineno, id_)
                return None

            if id_[-1] in DEPRECATED_SUFFIXES and entry._type != SUFFIX_TYPE[id_[-1]]:
                syntax_error_func_type_mismatch(lineno, entry)
        else:
            entry = self.create_id(id_, lineno)

        if entry.forwarded:
            old_type = entry.type_ # Remembers the old type
            old_params_size = entry.params_size

            if entry.type_ is not None:
                if entry.type_ != old_type:
                    syntax_error_func_type_mismatch(lineno, entry)
            else:
                entry.type_ = old_type

        entry.class_ = 'function'
        entry.mangled = '_%s' % entry.id_ # Mangled name (functions always has _name as mangled)
        entry.callable = True
        entry.locals_size = 0 # Size of local variables
        entry.local_symbol_table = {}

        if not entry.forwarded:
            entry.params_size = 0 # Size of parametres
        else:
            entry.params_size = old_params_size # Size of parametres

        return entry


    def make_callable(self, id_, lineno):
        ''' Creates a func/array/string call. Checks if id is callable or not.
        '''
        entry = self.get_or_create(id_, lineno)
        if entry.callable == False: # Is it NOT callable?
            if entry.type_ != 'string':
                syntax_error_not_array_nor_func(lineno, id)
                return None
            else:
                # Ok, it is a string slice if it has 0 or 1 parameters
                return entry

        if entry.callable is None and entry.type_ == 'string':
            # Ok, it is a string slice if it has 0 or 1 parameters
            entry.callable = False
            return entry

        entry.mangled = '_%s' % entry.id_ # Mangled name (functions always has _name as mangled)
        entry.callable = True

        return entry


    def check_labels(self):
        ''' Checks if all the labels has been declared
        '''
        for entry in self.table[0].values():
            if entry._class == 'label':
                self.check_declared(entry.id_, entry.lineno, 'label')


    def check_classes(self, scope = -1):
        ''' Check if pending identifiers are defined or not. If not,
        returns a syntax error. If no scope is given, the current
        one is checked.
        '''
        for entry in self.table[scope].values():
            if entry._class is None:
                syntax_error(entry.lineno, "Unknown identifier '%s'" % entry.id_)


    @property
    def vars(self):
        ''' Returns symbol instances corresponding to variables
        of the current scope.
        '''
        return [x for x in self.table[0].values() if x.class_ == 'var']


    @property
    def arrays(self):
        ''' Returns symbol instances corresponding to arrays
        of the current scope.
        '''
        return [x for x in self.table[0].values() if x.class_ == 'array']


    @property
    def functions(self):
        ''' Returns symbol instances corresponding to functions
        of the current scope.
        '''
        return [x for x in self.table[0].values() if x.class_ == 'function']


    @property
    def aliases(self):
        ''' Returns symbol instances corresponding to aliased vars.
        '''
        return [x for x in self.table[0].values() if x.is_aliased]


    def __getitem__(self, level):
        ''' Returns the SYMBOL TABLE for the given scope (0 = global)
        '''
        return self.table[level]


