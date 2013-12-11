#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from debug import __DEBUG__

from symbol.var import SymbolVAR as VAR
from symbol.vararray import SymbolVARARRAY as VARARRAY
from symbol.typecast import SymbolTYPECAST as TYPECAST
from symbol.function import SymbolFUNCTION as FUNCTION

import global_
from config import OPTIONS

from errmsg import syntax_error
from errmsg import warning
from errmsg import warning_implicit_type
from errmsg import syntax_error_func_type_mismatch
from errmsg import syntax_error_not_array_nor_func

from constants import DEPRECATED_SUFFIXES
from constants import SUFFIX_TYPE
from constants import SCOPE
from constants import CLASS
from constants import TYPE
from constants import PTR_TYPE

from check import is_number


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

    def get_entry(self, id_, scope=None):
        ''' Returns the ID entry stored in self.table, starting
        by the first one. Returns None if not found.
        If scope is not None, only the given scope is searched.
        '''
        if id_[-1] in DEPRECATED_SUFFIXES:
            id_ = id_[:-1]  # Remove it

        idL = id_.lower()

        if scope is not None:
            if len(self.table) > scope:
                result = self[scope].get(id_, None)
                if result is None:
                    result = self.caseins[scope].get(idL, None)
            return result  # Not found

        for i in range(len(self.table)):
            try:
                return self[i][id_]
            except KeyError:
                pass
            try:
                return self.caseins[i][idL]
            except KeyError:
                pass
        return None  # Not found

    def declare(self, id_, lineno, symbol_):
        ''' Check there is no 'id' already declared in the current scope, and
            creates and returns it. Otherwise, returns None,
            and the caller function raises the syntax/semantic error.
            Parameter symbol_ is the SymbolVAR, SymbolVARARRAY, etc. instance
        '''
        id2 = id_
        type_ = symbol_.type_

        if id2[-1] in DEPRECATED_SUFFIXES:
            id2 = id2[:-1]  # Remove it
            type_ = SUFFIX_TYPE[id_[-1]]  # Overrides type_
        # Try-except is faster than IN
        try:
            self[0][id2]  # Checks if already declared
            return None
        except KeyError:
            pass
        try:
            self.caseins[0][id2.lower()]  # Checks for case insensitive
            return None
        except KeyError:
            pass

        entry = self[0][id2] = symbol_
        entry.callable = None  # True if function, strings or arrays
        entry.forwarded = False  # True for a function header
        entry.mangled = '%s_%s' % (self.mangle, entry.name)  # Mangled name
        entry.caseins = OPTIONS.case_insensitive.value
        #entry.class_ = None  # important
        entry.type_ = type_
        if entry.caseins:
            self.caseins[0][id2.lower()] = entry
        return entry

    """
    def create_id(self, id_, lineno):
        ''' HINT: DEPRECATED: Use declare_id
        Check there is no 'id' already declared in the current scope.
        If it does exists raises an error. Otherwise creates and returns it.
        '''
        result = self.declare_id(id_, lineno)
        if result is None:
            if id_ not in self.table[0].keys(): # is it case insensitive?
                id_ = id_.lower()

            syntax_error(lineno, 'Duplicated identifier "%s" (previous one at %s:%i)' %
                (id_, self.table[0][id_].filename, self.table[0][id_].lineno))

        return result

    def get_or_create(self, id_, lineno, scope=None):
        ''' HINT: DEPRECATED: use self.access
        Returns the ID entry if stored in self.table,
        otherwise, creates a new one.
        '''
        entry = self.get_entry(id_, scope)
        if entry is not None:
            return entry

        return self.create_id(id_, lineno)
    """

    # -------------------------------------------------------------------------
    # Symbol Table Checks
    # -------------------------------------------------------------------------
    def check_is_declared(self, id_, lineno, classname, scope=None):
        ''' Checks if the given id is already defined in any scope
            or raises a Syntax Error.

            Note: classname is not the class attribute, but the name of
            the class as it would appear on compiler messages.
        '''
        result = self.get_entry(id_, scope)
        if result is None or not result.declared:
            syntax_error(lineno, 'Undeclared %s "%s"' % (classname, id_))
            return False

        return True

    def check_is_undeclared(self, id_, scope=None):
        ''' The reverse of the above.
        Check the given identifier is not already declared. Returns True
        if OK, False otherwise.
        '''
        result = self.get_entry(id_, scope)
        if result is None or not result.declared:
            return True
        '''
        syntax_error(lineno,
                     'Duplicated identifier "%s" (previous one at %s:%i)' %
                     (id_, self.table[0][id_].filename,
                      self.table[0][id_].lineno))
        '''
        return False

    def check_class(self, id_, class_, lineno, scope=None):
        ''' Check the id is either undefined or defined with
        the given class.
        '''
        assert CLASS.is_valid(class_)
        entry = self.get_entry(id_, scope)
        if entry is None or entry.class_ is None:
            return True

        if entry.class_ != class_:
            if entry.class_ == CLASS.array:
                a1 = 'n'
            else:
                a1 = ''
            if class_ == CLASS.array:
                a2 = 'n'
            else:
                a2 = ''
            syntax_error(lineno, "identifier '%s' is a%s %s, not a%s %s" %
                         (id_, a1, entry.class_, a2, class_))
            return False
        return True

    # -------------------------------------------------------------------------
    # Function declaration and reated
    # -------------------------------------------------------------------------
    def start_function_body(self, funcname):
        ''' Start a new variable ambit.
        '''
        self.mangles.append(self.mangle)
        self.mangle = '%s_%s' % (self.mangle, funcname)
        self.table.insert(0, {})    # Prepends new symbol table
        self.caseins.insert(0, {})  # Prepends caseins dictionary
        global_.META_LOOPS.append(global_.LOOPS)
        global_.LOOPS = []

    def end_function_body(self):
        ''' Ends a function body and pops old symbol table.
        '''
        def entry_size(entry):
            ''' For local variables and params, returns the real variable or
            local array size in bytes
            '''
            if entry.scope == SCOPE.global_ or \
                    entry.alias is not None:  # aliases or global variables = 0
                return 0

            result = entry.size
            if (entry.class_ != CLASS.array):
                return result

            for bound in entry.bounds.next:
                result *= (bound.symbol.upper - bound.symbol.lower + 1)

            # Bytes for the array header
            result += 1 + 2 * len(entry.bounds.next)
            return result

        def sortentries(entries):
            ''' Sort in-place entries according to it sizes in ascending order
            Sorting ascending is preferable, since this make local arrays,
            for example, to be declared later. This helps using IX+n scheme
            for parameters and leave the haeavy HL + NN or IX + NN for arrays.
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

        for entry in entries:  # Symbols of the current level
            if entry._class is None:
                self.move_to_global_scope(entry.id_)

            if entry.class_ == CLASS.function:
                continue
            # Local variables offset
            if entry.class_ == CLASS.var and entry.scope == SCOPE.local:
                if entry.alias is not None:  # alias of another variable?
                    if entry.offset is None:
                        entry.offset = entry.alias.offset
                    else:
                        entry.offset = entry.alias.offset - entry.offset
                else:
                    self.offset += entry_size(entry)
                    entry.offset = self.offset

            if entry.class_ == CLASS.array and entry.scope == SCOPE.local:
                entry.offset = entry_size(entry) + self.offset
                self.offset = entry.offset

        self.mangle = self.mangles.pop()
        self.table.pop(0)
        self.caseins.pop(0)
        global_.LOOPS = global_.META_LOOPS.pop()
        return self.offset

    # -------------------------------------------------------------------------
    # Scope Managent
    # -------------------------------------------------------------------------
    def move_to_global_scope(self, id_):
        ''' If the given id is in the current scope, and there is more than
        1 scope, move the current id to the global scope and make it global.
        Labels need this.
        '''
         # In the current scope and more than 1 scope?
        if id_ in self.table[0].keys() and len(self.table) > 1:
            self.table[-1][id_] = self.table[0][id_]
            self.table[-1][id_].offset = None
            self.table[-1][id_].scope = SCOPE.global_
            del self.table[0][id_]  # Removes it from the current scope

    def make_static(self, id_):
        ''' The given ID in the current scope is changed to 'global', but the
        variable remains in the current scope, if it's a 'global private'
        variable: A variable private to a function scope, but whose contents
        are not in the stack, but in the global variable area.
        These are called 'static variables' in C.

        A copy of the instance, but mangled, is also allocated in the global
        symbol table.
        '''
        entry = self.table[0][id_]
        entry.scope = SCOPE.global_
        self.table[-1][entry.mangled_] = entry

    # -------------------------------------------------------------------------
    # Identifier Declaration (e.g DIM, FUNCTION, SUB, etc.)
    # -------------------------------------------------------------------------
    def make_var(self, id_, lineno, default_type=None, scope=None):
        '''
        FIXME: DEPRECATED. Use self.access_var instead.
        Checks whether the id exist or not.
        If it exists, it must be a variable (not a function, array, constant,
        or label)
        '''
        if not self.check_class(id_, CLASS.var, lineno, scope):
            return None
        entry = self.get_or_create(id_, lineno, scope)
        if entry.declared:
            return entry
        entry.class_ = CLASS.var  # Make it a variable
        entry.callable = False
        entry.scope = SCOPE.local if len(self.table) > 1 else SCOPE.global_
        '''
        if entry.scope == SCOPE.global_:  # ***
            entry.t = entry.mangled
        else:  # local scope
            entry.t = global_.optemps.new_t()
            if entry._type == TYPE.string:
                entry.t = '$' + entry.t
        '''
        if entry.type_ is None:  # First time used?
            if default_type is None:
                default_type = global_.DEFAULT_TYPE
                warning(lineno, "Variable '%s' declared as '%s'" %
                        (id_, default_type))

            entry.type_ = default_type  # Default type is unknown
        return entry

    def access_var(self, id_, lineno, default_type=None, default_value=None):
        '''
        Since ZX BASIC allows access to undeclared variables, we must allow
        them, and *implicitly* declare them if they are not declared already.
        This function just checks if the id_ exists and returns it if so.
        Otherwise, creates an implicit declared variable and returns its entry.
        '''
        result = self.get_entry(id_)
        if result is not None:
            return result

        return self.declare_variable(id_, lineno, default_type, default_value)

    def declare_variable(self, id_, lineno, type_, default_value=None):
        ''' Like the above, but checks that entry.declared is False.
        Otherwise raises an error.

        Parameter default_value specifies an initialized variable, if set.
        '''
        if not self.check_is_undeclared(id_, scope=0):  # 0 = Current Scope
            entry = self.get_entry(id_)
            if entry.scope == SCOPE.parameter:
                syntax_error(lineno,
                             "Variable '%s' already declared as a parameter "
                             "at %s:%i" % (id_, entry.filename, entry.lineno))
            else:
                syntax_error(lineno, "Variable '%s' already declared at "
                             "%s:%i" % (id_, entry.filename, entry.lineno))
            return None

        if not self.check_class(id_, CLASS.var, lineno):
            return None

        entry = (self.get_entry(id_, scope=0) or
                 self.declare(id_, lineno, VAR(id_, lineno,
                                               class_=CLASS.var)))
        __DEBUG__("Entry %s declared with class %s" % (entry.name, entry.class_))
        entry.declared = True  # marks it as declared

        if entry.type_ != type_.type_:
            if not type_.implicit and entry.type_ is not None:
                syntax_error(lineno,
                             "'%s' suffix is for type '%s' but it was "
                             "declared as '%s'" %
                             (id_, TYPE.to_string(entry.type_), type_))
                return None
            type_.type_ = entry.type_

        if type_.implicit:
            warning_implicit_type(lineno, id_, entry.type_)

        if default_value is not None and entry.type_ != default_value.type_:
            if is_number(default_value):
                default_value = TYPECAST.make_node(entry.type_, default_value,
                                                   lineno)
                if default_value is None:
                    return None
            else:
                syntax_error(lineno,
                             "Variable '%s' declared as '%s' but initialized "
                             "with a '%s' value" %
                             (id_, entry.type_, default_value.type_))
                return None

        # TODO: what happens to this?
        '''
        if entry.scope != SCOPE.global_ and entry.type_ == TYPE.string:
            if entry.t[0] != '$':
                entry.t = '$' + entry.t
        '''
        if default_value is not None:
            if default_value.token != 'CONST':
                default_value = default_value.value

        entry.default_value = default_value
        return entry

    def declare_const(self, id_, lineno, type_, default_value):
        ''' Similar to the above. But declares a Constant.
        '''
        if not self.check_is_undeclared(id_, scope=0):
            entry = self.get_entry(id_)
            if entry.scope == SCOPE.parameter:
                syntax_error(lineno,
                             "Constant '%s' already declared as a parameter "
                             "at %s:%i" % (id_, entry.filename, entry.lineno))
            else:
                syntax_error(lineno, "Constant '%s' already declared at "
                             "%s:%i" % (id_, entry.filename, entry.lineno))
            return None

        entry = self.declare_variable(id_, lineno, type_, default_value,
                                      'constant')
        if entry is None:
            return None

        entry.class_ = CLASS.const
        entry.value = default_value
        # entry.value = entry.t = default_value.value
        return entry

    def declare_label(self, id_, lineno):
        ''' Declares a label (line numbers are also labels).
            Unlike variables, labels are always global.
        '''
        id_ = str(id_)
        if not self.check_is_undeclared(id_, scope=0):
            entry = self.get_entry(id_)
            syntax_error(lineno, "Label '%s' already declared at %s:%i" %
                         (id_, entry.filename, entry.lineno))
            return entry

        entry = self.declare(id_, lineno, VAR(id_, lineno, class_=CLASS.label))
        if entry is None:
            return None

        if entry.declared:
            if entry.is_line_number:
                syntax_error(lineno, "Duplicated line number '%s'. "
                             "Previous was at %i" % (entry.id_, entry.lineno))
            else:
                syntax_error(lineno, "Label '%s' already declared at line %i" %
                             (id_, entry.lineno))
            return None

        if id_[0] == '.':
            id_ = id_[1:]
            # XXX: ??? Mangled name. Just the label, 'cause it starts with '.'
            entry.mangled = '%s' % id_
        else:
            # Mangled name. Labels are __LABEL__
            entry.mangled = '__LABEL__%s' % entry.id_

        entry.is_line_number = isinstance(id_, int)
        self.move_to_global_scope(id_)  # Labels are always global
        entry.declared = True
        entry.type_ = PTR_TYPE
        return entry

    def declare_param(self, id_, lineno, type_=TYPE.float_):
        ''' Declares a parmeter
        Check if entry.declared is False. Otherwise raises an error.
        '''
        entry = self.make_var(id_, lineno, type_, scope=0)

        if entry.declared:
            syntax_error(lineno, "Parameter '%s' already declared at %s:%i" %
                         (id_, entry.filename, entry.lineno))
            return None

        entry.declared = True
        entry.scope = SCOPE.parameter

        if entry._type == TYPE.string and entry.t[0] != '$':
                entry.t = '$' + entry.t

        return entry

    def declare_array(self, id_, lineno, type_, bounds, default_value=None):
        ''' Declares an array in the symboltabe (VARARRAY). Error if already
        exists.
        '''
        if not self.check_class(id_, CLASS.array, lineno, scope=0):
            return None
        entry = self.get_entry(id_, 0)
        if entry is None:
            entry = self.declare(id_, lineno, VARARRAY(id_, bounds, lineno))
        if entry.declared:
            return entry

        if not entry.declared:
            if entry.callable:
                syntax_error(lineno,
                             "Array '%s' must be declared before use. "
                             "First used at line %i" %
                             (id_, entry.lineno))
                return None
        else:
            if entry.scope == 'parameter':
                syntax_error(lineno, "variable '%s' already declared as a "
                             "parameter at line %i" % (id_, entry.lineno))
            else:
                syntax_error(lineno, "variable '%s' already declared at "
                             "line %i" % (id_, entry.lineno))
            return None

        if entry.type_ != type_.type_:
            if not type_.implicit:
                syntax_error(lineno, "Array suffix for '%s' is for type '%s' "
                             "but declared as '%s'" %
                             (entry.name, TYPE.to_string(entry.type_),
                              TYPE.to_string(type_.type_)))
                return None

            type_.implicit = False
            type_.type_ = entry.type_

        if type_.implicit:
            warning_implicit_type(lineno, id_)

        entry.declared = True
        entry.class_ = CLASS.array
        entry.type_ = type_.type_
        entry.bounds = bounds

        #entry.total_size = bounds.size * TYPE_SIZES[entry._type]
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

        entry.class_ = CLASS.function
        # Mangled name (functions always has _name as mangled)
        entry.mangled = '_%s' % entry.id_
        entry.callable = True
        entry.locals_size = 0  # Size of local variables
        entry.local_symbol_table = {}

        if not entry.forwarded:
            entry.params_size = 0  # Size of parametres
        else:
            entry.params_size = old_params_size  # Size of parametres
        return entry

    def make_callable(self, id_, lineno):
        ''' Creates a func/array/string call. Checks if id is callable or not.
        An identifier is "callable" if it can be followed by a list of para-
        meters.
        This does not mean the id_ is a function, but that it allows the same
        syntax a function does:

        For example:
           - MyFunction(a, "hello", 5) is a Function so MyFuncion is callable
           - MyArray(5, 3.7, VAL("32")) makes MyArray identifier "callable".
           - MyString(5 TO 7) or MyString(5) is a "callable" string.
        '''
        entry = self.get_or_create(id_, lineno)
        if entry.callable is False:  # Is it NOT callable?
            if entry.type_ != TYPE.string:
                syntax_error_not_array_nor_func(lineno, id_)
                return None
            else:
                # Ok, it is a string slice if it has 0 or 1 parameters
                return entry

        if entry.callable is None and entry.type_ == TYPE.string:
            # Ok, it is a string slice if it has 0 or 1 parameters
            entry.callable = False
            return entry

        # Mangled name (functions always has _name as mangled)
        entry.mangled = '_%s' % entry.name
        entry.callable = True
        return entry

    def check_labels(self):
        ''' Checks if all the labels has been declared
        '''
        for entry in self[0].values():
            if entry.class_ == CLASS.label:
                self.check_is_declared(entry.name, entry.lineno, CLASS.label)

    # TIP: DEPRECATED?. Not used.
    def check_classes(self, scope=-1):
        ''' Check if pending identifiers are defined or not. If not,
        returns a syntax error. If no scope is given, the current
        one is checked.
        '''
        for entry in self[scope].values():
            if entry.class_ is None:
                syntax_error(entry.lineno, "Unknown identifier '%s'" %
                             entry.name)

    # -------------------------------------------------------------------------
    # Properties
    # -------------------------------------------------------------------------
    @property
    def vars_(self):
        ''' Returns symbol instances corresponding to variables
        of the current scope.
        '''
        return [x for x in self[0].values() if x.class_ == CLASS.var]

    @property
    def arrays(self):
        ''' Returns symbol instances corresponding to arrays
        of the current scope.
        '''
        return [x for x in self[0].values() if x.class_ == CLASS.array]

    @property
    def functions(self):
        ''' Returns symbol instances corresponding to functions
        of the current scope.
        '''
        return [x for x in self[0].values() if x.class_ in
                (CLASS.function, CLASS.sub)]

    @property
    def aliases(self):
        ''' Returns symbol instances corresponding to aliased vars.
        '''
        return [x for x in self[0].values() if x.is_aliased]

    def __getitem__(self, level):
        ''' Returns the SYMBOL TABLE for the given scope (0 = global)
        '''
        return self.table[level]
