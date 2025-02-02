# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------


from src.api import check as check
from src.api import errmsg, global_
from src.api.config import OPTIONS
from src.api.constants import CLASS, DEPRECATED_SUFFIXES, SCOPE, SUFFIX_TYPE, TYPE
from src.api.debug import __DEBUG__
from src.api.errmsg import error as syntax_error
from src.api.errmsg import (
    syntax_error_cannot_define_default_array_argument,
    syntax_error_func_type_mismatch,
    syntax_error_not_array_nor_func,
    warning_implicit_type,
    warning_not_used,
)
from src.symbols import sym as symbols
from src.symbols.symbol_ import Symbol

from .scope import Scope


class SymbolTable:
    """Implements a symbol table.

    This symbol table stores symbols for types, functions and variables.
    Variables can be in the global or local scope. Each symbol can be
    retrieved by its name.

    Parameters are treated like local variables, but has a different scope,
    SCOPE.parameter.

    Arrays are also a derived class from var. The scope rules above
    also apply for arrays (local, global), except for parameters.

    The symbol table is implemented as a list of Scope instances.
    To get a symbol by its id, just call symboltable.get_id(id, scope).
    If scope is not given, it will search from the current scope to
    the global one, 'un-nesting' them.

    An scope is referenced by a number (it's position in the list).
    Do not use 0 to reference the global scope. Use symboltable.global_scope
    and symboltable.current_scope to get such numbers.

    Accessing symboltable[symboltable.current_scope] returns a Scope object.
    """

    def __init__(self):
        """Initializes the Symbol Table"""
        self.current_namespace = ""  # Prefix for local variables
        self.table: list[Scope] = [Scope(self.current_namespace)]
        self.namespaces: dict[str, Scope] = {self.current_namespace: self.table[-1]}
        self.basic_types = {}

        # Initialize canonical types
        for type_ in TYPE.types:
            self.basic_types[type_] = self.declare_type(symbols.BASICTYPE(type_))

    @property
    def current_scope(self) -> Scope:
        return self.table[-1]

    @property
    def global_scope(self) -> Scope:
        return self.table[0]

    def get_entry(self, id_: str, scope: Scope | None = None) -> symbols.ID | None:
        """Returns the ID entry stored in self.table, starting
        by the first one. Returns None if not found.
        If scope is not None, only the given scope is searched.
        """
        if id_[-1] in DEPRECATED_SUFFIXES:
            id_ = id_[:-1]  # Remove it

        if scope is not None:
            return scope[id_]

        for s in self:
            if s[id_] is not None:
                return s[id_]

        return None  # Not found

    def get_existing_entry(self, id_: str, scope: Scope | None = None) -> symbols.ID:
        result = self.get_entry(id_, scope)
        assert result is not None

        return result

    def declare(self, id_: str, lineno: int, entry: symbols.ID) -> None | symbols.ID | symbols.TYPE:
        """Check there is no 'id' already declared in the current scope, and
        creates and returns it. Otherwise, returns None,
        and the caller function raises the syntax/semantic error.
        Parameter entry is the SymbolVAR, SymbolVARARRAY, etc. instance
        The entry 'declared' field is leave untouched. Setting it if on
        behalf of the caller.
        """
        id2 = id_
        type_ = entry.type_

        if id2[-1] in DEPRECATED_SUFFIXES:
            id2 = id2[:-1]  # Remove it
            type_ = symbols.TYPEREF(self.basic_types[SUFFIX_TYPE[id_[-1]]], lineno)  # Overrides type_
            if entry.type_ is not None and not entry.type_.implicit and type_ != entry.type_:
                syntax_error(lineno, f"expected type {type_.name} for '{id_}', got {entry.type_.name}")

        # Checks if already declared
        if self.current_scope[id2] is not None:
            return None

        entry.caseins = OPTIONS.case_insensitive
        self.current_scope[id2] = entry
        entry.name = id2  # Removes DEPRECATED SUFFIXES if any

        if isinstance(entry, symbols.TYPE):
            return entry  # If it's a type declaration, we're done

        entry.mangled = self.make_child_namespace(self.current_namespace, entry.name)  # Mangled name
        entry.type_ = type_  # type_ now reflects entry sigil (i.e. a$ => 'string' type) if any
        entry.scope_ref = self.current_scope

        if self.current_scope == self.global_scope or entry.class_ == CLASS.label:
            entry.scope = SCOPE.global_
        else:
            entry.scope = SCOPE.local

        return entry

    def declare_safe(self, id_: str, lineno: int, entry: symbols.ID):
        """Like declare, but never returns None"""
        result = self.declare(id_, lineno, entry)
        assert result is not None

        return result

    @staticmethod
    def make_child_namespace(parent_namespace: str, child_namespace: str) -> str:
        """Compounds a new namespace appending the child namespace to the parent
        one. If the parent one is empty, the child will be mangled. Otherwise it
        will be appended with the namespace separator.
        """
        if not parent_namespace:
            return f"{global_.MANGLE_CHR}{child_namespace}"

        return f"{parent_namespace}{global_.NAMESPACE_SEPARATOR}{child_namespace}"

    # -------------------------------------------------------------------------
    # Symbol Table Checks
    # -------------------------------------------------------------------------
    def check_is_declared(
        self, id_: str, lineno: int, classname: str = "identifier", scope=None, show_error=True
    ) -> bool:
        """Checks if the given id is already defined in any scope
        or raises a Syntax Error.

        Note: classname is not the class attribute, but the name of
        the class as it would appear on compiler messages.
        """
        result = self.get_entry(id_, scope)
        if isinstance(result, symbols.TYPE):
            return True

        if result is None or not result.declared:
            if show_error:
                syntax_error(
                    lineno,
                    'Undeclared %s "%s"' % (classname, id_),
                    fname=(result.filename if result is not None else None),
                )
            return False
        return True

    def check_is_undeclared(self, id_: str, lineno: int, classname="identifier", scope=None, show_error=False) -> bool:
        """The reverse of the above.

        Check the given identifier is not already declared. Returns True
        if OK, False otherwise.
        """
        result = self.get_entry(id_, scope)
        if result is None or not result.declared:
            return True

        if scope is None:
            scope = self.current_scope

        if show_error:
            syntax_error(
                lineno,
                'Duplicated %s "%s" (previous one at %s:%i)' % (classname, id_, scope[id_].filename, scope[id_].lineno),
            )
        return False

    def check_class(self, id_: str, class_: CLASS, lineno: int, scope: Scope = None, show_error=True) -> bool:
        """Check the id is either undefined or defined with
        the given class.

        - If the identifier (e.g. variable) does not exist means
        it's undeclared, and returns True (OK).
        - If the identifier exists, but its class_ attribute is
        unknown yet (None), returns also True. This means the
        identifier has been referenced in advanced and it's undeclared.

        Otherwise, fails returning False.
        """
        assert CLASS.is_valid(class_)
        entry = self.get_entry(id_, scope)
        if entry is None or entry.class_ in (CLASS.unknown, class_):  # Undeclared yet
            return True

        if show_error:
            check.check_class(entry, class_, lineno)

        return False

    # -------------------------------------------------------------------------
    # Scope Management
    # -------------------------------------------------------------------------
    def enter_scope(self, namespace):
        """Starts a new variable scope.

        Notice the *IMPORTANT* marked lines. This is how a new scope is added,
        by pushing a new dict at the end (and popped out later).
        """
        self.current_namespace = self.make_child_namespace(self.current_namespace, namespace)
        self.table.append(Scope(self.current_namespace, parent_scope=self.current_scope))
        self.namespaces[self.current_namespace] = self.table[-1]
        global_.META_LOOPS.append(global_.LOOPS)  # saves current LOOPS state
        global_.LOOPS = []  # new LOOPS state

    @staticmethod
    def compute_offsets(scope: Scope) -> int:
        def entry_size(var_entry: symbols.ID):
            """For local variables and params, returns the real variable or
            local array size in bytes
            """
            if (
                var_entry.scope == SCOPE.global_ or var_entry.addr is not None or var_entry.class_ == CLASS.const
            ):  # aliases or global variables = 0
                return 0

            if var_entry.class_ != CLASS.array:
                return var_entry.size

            return var_entry.memsize

        entries = sorted(scope.values(filter_by_opt=True), key=entry_size)
        offset = 0

        for entry in entries:  # Symbols of the current level
            if entry.class_ in (CLASS.function, CLASS.label, CLASS.type):
                continue

            # Local variables offset
            if entry.class_ == CLASS.var and entry.scope == SCOPE.local:
                offset += entry_size(entry)
                entry.ref.offset = offset

            if entry.class_ == CLASS.array and entry.scope == SCOPE.local:
                entry.ref.offset = entry_size(entry) + offset
                offset = entry.ref.offset

        return offset

    def leave_scope(self, show_warnings=True):
        """Ends a function body and pops current scope out of the symbol table."""
        for v in self.current_scope.values(filter_by_opt=False):
            if not v.accessed:
                if v.scope == SCOPE.parameter:
                    kind = "Parameter"
                    v.accessed = True  # Parameters must always be present even if not used!
                    # byref is always marked as used: it can be used to return a value
                    if show_warnings and not v.byref:
                        warning_not_used(v.lineno, v.name, kind=kind, fname=v.filename)

        for entry in self.current_scope.values(filter_by_opt=True):  # Symbols of the current level
            if entry.class_ == CLASS.unknown:
                self.move_to_global_scope(entry.name)

        offset = self.compute_offsets(self.current_scope)
        self.current_namespace = self.current_scope.parent_namespace
        self.table.pop()
        global_.LOOPS = global_.META_LOOPS.pop()
        return offset

    def move_to_global_scope(self, id_: str):
        """If the given id is in the current scope, and there is more than
        1 scope, move the current id to the global scope and make it global.
        Labels need this.
        """
        # In the current scope and more than 1 scope?
        if id_ in self.current_scope.keys(filter_by_opt=False) and len(self.table) > 1:
            symbol = self.current_scope[id_]
            assert symbol is not None
            symbol.ref.offset = None
            symbol.scope = SCOPE.global_
            if symbol.class_ != CLASS.label:
                symbol.mangled = self.make_child_namespace(self.global_scope.namespace, id_)

            self.global_scope[id_] = symbol
            del self.current_scope[id_]  # Removes it from the current scope
            __DEBUG__(f"'{id_}' entry moved to global scope")

    def make_static(self, id_: str):
        """The given ID in the current scope is changed to 'global', but the
        variable remains in the current scope, if it's a 'global private'
        variable: A variable private to a function scope, but whose contents
        are not in the stack, not in the global variable area.
        These are called 'static variables' in C.

        A copy of the instance, but mangled, is also allocated in the global
        symbol table.
        """
        entry = self.current_scope[id_]
        assert entry is not None
        entry.scope = SCOPE.global_
        self.global_scope[entry.mangled] = entry

    # -------------------------------------------------------------------------
    # Identifier Declaration (e.g DIM, FUNCTION, SUB, etc.)
    # -------------------------------------------------------------------------

    def access_id(
        self,
        id_: str,
        lineno: int,
        scope=None,
        default_type=None,
        default_class=CLASS.unknown,
        ignore_explicit_flag=False,
    ):
        """Access a symbol by its identifier and checks if it exists.
        If not, it's supposed to be an implicitly declared variable.

        default_class is the class to use in case of an undeclared-implicit-accessed id
        """
        if isinstance(default_type, symbols.BASICTYPE):
            default_type = symbols.TYPEREF(default_type, lineno, implicit=False)
        assert default_type is None or isinstance(default_type, symbols.TYPEREF)

        if not ignore_explicit_flag:
            check.check_is_declared_explicit(lineno, id_)

        result = self.get_entry(id_, scope)
        if result is None:
            if default_type is None:
                default_type = symbols.TYPEREF(self.basic_types[global_.DEFAULT_IMPLICIT_TYPE], lineno, implicit=True)

            result = self.declare_safe(
                id_, lineno, entry=symbols.ID(id_, lineno, type_=default_type, class_=default_class)
            )
            return result

        # The entry was already declared. If it's type is auto and the default type is not None,
        # update its type.
        if default_type is not None and result.type_ == self.basic_types[TYPE.unknown]:
            if default_type == self.basic_types[TYPE.boolean]:
                default_type = self.basic_types[TYPE.ubyte]

            result.type_ = default_type
            warning_implicit_type(lineno, id_, default_type.name)

        return result

    def access_var(self, id_: str, lineno: int, scope=None, default_type=None):
        """
        Since ZX BASIC allows access to undeclared variables, we must allow
        them, and *implicitly* declare them if they are not declared already.
        This function just checks if the id_ exists and returns its entry so.
        Otherwise, creates an implicit declared variable entry and returns it.

        If the --strict command line flag is enabled (or #pragma option explicit
        is in use) checks ensures the id_ is already declared.

        Returns None on error.
        """
        result = self.access_id(id_, lineno, scope, default_type, default_class=CLASS.var)
        if result is None:
            return None

        if not self.check_class(id_, CLASS.var, lineno, scope):
            return None

        if result.class_ == CLASS.unknown:
            result = result.to_var()

        assert result.class_ == CLASS.var
        return result

    def access_array(self, id_: str, lineno: int, scope=None, default_type=None) -> symbols.ID | None:
        """
        Called whenever an accessed variable is expected to be an array.
        ZX BASIC requires arrays to be declared before usage, so they're
        checked.

        Also checks for class array.
        """
        if not self.check_is_declared(id_, lineno, "array", scope):
            return None

        if not self.check_class(id_, CLASS.array, lineno, scope):
            return None

        return self.access_id(id_, lineno, scope=scope, default_type=default_type)

    def access_func(self, id_: str, lineno: int, scope=None, default_type=None):
        """
        Since ZX BASIC allows access to undeclared functions, we must allow
        and *implicitly* declare them if they are not declared already.
        This function just checks if the id_ exists and returns its entry if so.
        Otherwise, creates an implicit declared variable entry and returns it.
        """
        assert default_type is None or isinstance(default_type, symbols.TYPEREF)

        result = self.get_entry(id_, scope)
        if result is None:
            if default_type is None:
                if global_.DEFAULT_IMPLICIT_TYPE == TYPE.unknown:
                    default_type = symbols.TYPEREF(self.basic_types[TYPE.unknown], lineno, implicit=True)
                else:
                    default_type = symbols.TYPEREF(self.basic_types[global_.DEFAULT_TYPE], lineno, implicit=True)

            return self.declare_func(id_, lineno, default_type, class_=CLASS.unknown)  # Declare SUB / Func

        if result.class_ not in (CLASS.function, CLASS.sub, CLASS.unknown):
            errmsg.syntax_error_unexpected_class(lineno, id_, result.class_, CLASS.function)
            return None

        return result

    def access_call(self, id_: str, lineno: int, scope=None, type_=None):
        """Creates a func/array/string call. Checks if id is callable or not.
        An identifier is "callable" if it can be followed by a list of para-
        meters.
        This does not mean the id_ is a function, but that it allows the same
        syntax a function does:

        For example:
           - MyFunction(a, "hello", 5) is a Function so MyFuncion is callable
           - MyArray(5, 3.7, VAL("32")) makes MyArray identifier "callable".
           - MyString(5 TO 7) or MyString(5) is a "callable" string.
        """
        entry = self.access_id(id_, lineno, scope, default_type=type_)
        if entry is None:
            return self.access_func(id_, lineno)

        if entry.callable is False:  # Is it NOT callable?
            if entry.type_ != self.basic_types[TYPE.string]:
                syntax_error_not_array_nor_func(lineno, id_)
                return None
            # Ok, it is a string slice if it has 0 or 1 parameters
            return entry

        if entry.callable is None and entry.type_ == self.basic_types[TYPE.string]:
            # Ok, it is a string slice if it has 0 or 1 parameters
            entry.callable = False
            return entry

        return entry

    def access_label(self, id_: str, lineno: int, scope: Scope | None = None):
        result = self.get_entry(id_, scope)
        if result is None:
            result = self.declare_label(id_, lineno)
            result.declared = False
        else:
            if not self.check_class(id_, CLASS.label, lineno, scope, show_error=True):
                return None

        if result.class_ != CLASS.label:  # An undeclared label used in advance
            result.to_label()

        return result

    def declare_variable(self, id_: str, lineno: int, type_, default_value=None, class_: CLASS = CLASS.var):
        """Like the above, but checks that entry.declared is False.
        Otherwise, raises an error.

        Parameter default_value specifies an initialized variable, if set.
        """
        assert isinstance(type_, symbols.TYPEREF)
        assert class_ in (CLASS.const, CLASS.var, CLASS.unknown)

        if not self.check_is_undeclared(id_, lineno, scope=self.current_scope, show_error=False):
            entry_ = self.get_existing_entry(id_)
            if entry_.scope == SCOPE.parameter:
                syntax_error(
                    lineno,
                    f"Variable '{id_}' already declared as a parameter at {entry_.filename}:{entry_.lineno}",
                )
            else:
                syntax_error(lineno, f"Variable '{id_}' already declared at {entry_.filename}:{entry_.lineno}")
            return None

        if not self.check_class(id_, class_, lineno, scope=self.current_scope):
            return None

        entry = self.get_entry(id_, scope=self.current_scope)
        if entry is None:
            entry = self.declare(id_, lineno, symbols.ID(name=id_, lineno=lineno, type_=type_))
            assert entry is not None

        if entry.class_ == CLASS.unknown:
            if class_ == CLASS.var:
                entry = entry.to_var(default_value)
            elif class_ == CLASS.const:
                entry = entry.to_const(default_value)

        __DEBUG__(
            "Entry %s declared with class %s at scope %s"
            % (entry.name, CLASS.to_string(entry.class_), self.current_scope.namespace)
        )

        assert entry.class_ == class_

        if entry.type_ is None or entry.type_ == self.basic_types[TYPE.unknown]:
            entry.type_ = type_

        if entry.type_ != type_:
            if not type_.implicit and entry.type_ is not None:
                syntax_error(
                    lineno, "'%s' suffix is for type '%s' but it was declared as '%s'" % (id_, entry.type_, type_)
                )
                return None

        entry.declared = True  # marks it as declared

        if entry.type_.implicit and entry.type_ != self.basic_types[TYPE.unknown]:
            warning_implicit_type(lineno, id_, entry.type_.name)

        if default_value is not None and entry.type_ != default_value.type_:
            if check.is_number(default_value):
                default_value = symbols.TYPECAST.make_node(entry.type_, default_value, lineno)
                if default_value is None:
                    return None
            else:
                syntax_error(
                    lineno,
                    "Variable '%s' declared as '%s' but initialized "
                    "with a '%s' value" % (id_, entry.type_, default_value.type_),
                )
                return None

        return entry

    def declare_type(self, type_):
        """Declares a type.
        Checks its name is not already used in the current scope,
        and that it's not a basic type.

        Returns the given type_ Symbol, or None on error.
        """
        assert isinstance(type_, symbols.TYPE)
        # Checks it's not a basic type
        if not type_.is_basic and type_.name.lower() in TYPE.TYPE_NAMES.values():
            syntax_error(type_.lineno, "'%s' is a basic type and cannot be redefined" % type_.name)
            return None

        if not self.check_is_undeclared(type_.name, type_.lineno, scope=self.current_scope, show_error=True):
            return None

        entry = self.declare(type_.name, type_.lineno, type_)
        return entry

    def declare_const(self, id_: str, lineno: int, type_, default_value):
        """Similar to the above. But declares a Constant."""
        if not self.check_is_undeclared(id_, lineno, scope=self.current_scope, show_error=False):
            entry = self.get_entry(id_)
            if entry.scope == SCOPE.parameter:
                syntax_error(
                    lineno,
                    "Constant '%s' already declared as a parameter at %s:%i" % (id_, entry.filename, entry.lineno),
                )
            else:
                syntax_error(lineno, "Constant '%s' already declared at %s:%i" % (id_, entry.filename, entry.lineno))
            return None

        entry = self.declare_variable(id_, lineno, type_, default_value, class_=CLASS.const)
        if entry is None:
            return None

        return entry

    def declare_label(self, id_: str, lineno: int) -> symbols.ID | None:
        """Declares a label (line numbers are also labels).
        Unlike variables, labels are always global.
        """
        # TODO: consider to make labels private
        if not self.check_is_undeclared(id_, lineno, "label"):
            e = self.get_existing_entry(id_)
            syntax_error(lineno, f"Label '{id_}' already used at {e.filename}:{e.lineno}")
            return e

        entry = self.get_entry(id_)
        if entry is not None and entry.declared:
            if entry.is_line_number:
                syntax_error(lineno, "Duplicated line number '%s'. Previous was at %i" % (entry.name, entry.lineno))
            else:
                syntax_error(lineno, "Label '%s' already declared at line %i" % (id_, entry.lineno))
            return None

        entry = (
            self.get_entry(id_, scope=self.current_scope)
            or self.get_entry(id_, scope=self.global_scope)
            or self.declare(id_, lineno, symbols.ID(id_, lineno, class_=CLASS.label))
        )
        if entry is None:
            return None

        if entry.token != "LABEL":
            entry.to_label()

        if id_[0] == global_.NAMESPACE_SEPARATOR:
            # Just the label, because it starts with '.' so it's a root-global label
            entry.mangled = f"{id_}"  # TODO: Check if this does ever happen??
        else:
            entry.to_label()  # TODO: This have to be done because labels are always global (reset namespace)

        if global_.FUNCTION_LEVEL:
            entry.ref.scope_owner = list(global_.FUNCTION_LEVEL)

        self.move_to_global_scope(id_)  # Labels are always global # TODO: not in the future
        entry.declared = True
        entry.type_ = self.basic_types[global_.PTR_TYPE]
        return entry

    def declare_param(
        self, id_: str, lineno: int, type_=None, is_array=False, default_value: Symbol | None = None
    ) -> symbols.ID | None:
        """Declares a parameter
        Check if entry.declared is False. Otherwise, raises an error.
        """
        if not self.check_is_undeclared(id_, lineno, classname="parameter", scope=self.current_scope, show_error=True):
            return None

        if is_array:
            if default_value is not None:
                syntax_error_cannot_define_default_array_argument(lineno)
                return None

            entry = self.declare_safe(id_, lineno, symbols.ID(name=id_, lineno=lineno, type_=type_)).to_vararray(
                bounds=symbols.BOUNDLIST()
            )
        else:
            entry = self.declare_safe(id_, lineno, symbols.ID(name=id_, lineno=lineno, type_=type_)).to_var(
                default_value=default_value
            )

        entry.scope = SCOPE.parameter
        entry.declared = True

        if entry.type_.implicit:
            warning_implicit_type(lineno, id_, type_)

        return entry

    def declare_array(self, id_: str, lineno: int, type_, bounds, default_value=None, addr=None):
        """Declares an array in the symbol table (VARARRAY). Error if already
        exists.
        The optional parameter addr specifies if the array elements must be placed at an specific
        (constant) memory address.
        """
        assert isinstance(type_, symbols.TYPEREF)
        assert isinstance(bounds, symbols.BOUNDLIST)

        if not self.check_class(id_, CLASS.array, lineno, scope=self.current_scope):
            return None

        entry = self.get_entry(id_, self.current_scope)
        if entry is None:
            entry = self.declare(id_, lineno, symbols.ID(name=id_, lineno=lineno, type_=type_))
            assert entry is not None

        if not entry.declared:
            if entry.callable:
                syntax_error(
                    lineno, "Array '%s' must be declared before use. First used at line %i" % (id_, entry.lineno)
                )
                return None
        else:
            if entry.scope == SCOPE.parameter:
                syntax_error(lineno, "variable '%s' already declared as a parameter at line %i" % (id_, entry.lineno))
            else:
                syntax_error(lineno, "variable '%s' already declared at line %i" % (id_, entry.lineno))
            return None

        if entry.type_ != self.basic_types[TYPE.unknown] and entry.type_ != type_:
            if not type_.implicit:
                syntax_error(
                    lineno,
                    "Array suffix for '%s' is for type '%s' but declared as '%s'" % (entry.name, entry.type_, type_),
                )
                return None

            type_.implicit = False
            type_ = entry.type_

        if type_.implicit:
            warning_implicit_type(lineno, id_, type_)

        if entry.class_ != CLASS.array:
            entry = symbols.ID.to_vararray(entry, bounds)

        entry.declared = True
        entry.type_ = type_
        entry.scope = SCOPE.global_ if self.current_scope == self.global_scope else SCOPE.local
        entry.ref.default_value = default_value
        entry.addr = addr

        __DEBUG__(
            "Entry %s declared with class %s at scope %s" % (id_, CLASS.to_string(entry.class_), self.current_scope)
        )
        return entry

    def declare_func(self, id_: str, lineno: int, type_=None, class_=CLASS.function) -> symbols.ID | None:
        """Declares a function or sub in the current scope.
        Checks whether the id exist or not (error if exists).
        And creates the entry at the symbol table.
        """
        assert class_ in (CLASS.function, CLASS.sub, CLASS.unknown)
        if not self.check_class(id_, class_, lineno):
            return None

        entry = self.get_entry(id_)  # Must not exist or have _class = None or Function and declared = False
        if entry is not None:
            if entry.declared:
                assert entry.token == "FUNCTION"
                if not entry.forwarded:
                    syntax_error(lineno, "Duplicate function name '%s', previously defined at %i" % (id_, entry.lineno))
                    return None

            if id_[-1] in DEPRECATED_SUFFIXES and entry.type_ != self.basic_types[SUFFIX_TYPE[id_[-1]]]:
                syntax_error_func_type_mismatch(lineno, entry)

            if entry.class_ == CLASS.unknown:  # This was a function or sub used in advance
                entry.to_function(class_=class_)

            entry.mangled = f"{self.current_namespace}_{entry.name}"  # HINT: mangle for nexted scopes
        else:
            entry = self.declare(id_, lineno, symbols.ID(id_, lineno, type_=type_).to_function(class_=class_))

        assert entry.token == "FUNCTION"
        if entry.forwarded:
            old_type = entry.type_  # Remembers the old type
            if entry.type_ is not None:
                if entry.type_ != old_type:
                    syntax_error_func_type_mismatch(lineno, entry)
            else:
                entry.type_ = old_type
        else:
            entry.ref.params_size = 0  # Size of parameters

        entry.ref.locals_size = 0  # Size of local variables
        return entry

    def check_labels(self):
        """Checks if all the labels has been declared"""
        for entry in self.labels:
            self.check_is_declared(entry.name, entry.lineno, CLASS.label.value)

    def check_classes(self, scope=-1):
        """Check if pending identifiers are defined or not. If not,
        returns a syntax error. If no scope is given, the current
        one is checked.
        """
        for entry in self[scope].values():
            if entry.class_ is None:
                syntax_error(entry.lineno, "Unknown identifier '%s'" % entry.name)

    # -------------------------------------------------------------------------
    # Properties
    # -------------------------------------------------------------------------
    @property
    def vars_(self):
        """Returns symbol instances corresponding to variables
        of the current scope.
        """
        return [x for x in self.current_scope.values(filter_by_opt=False) if x.class_ == CLASS.var]

    @property
    def labels(self):
        """Returns symbol instances corresponding to labels
        in the current scope.
        """
        return [x for x in self.current_scope.values(filter_by_opt=False) if x.class_ == CLASS.label]

    @property
    def types(self):
        """Returns symbol instances corresponding to type declarations
        within the current scope.
        """
        return [x for x in self.current_scope.values() if isinstance(x, symbols.TYPE)]

    @property
    def arrays(self):
        """Returns symbol instances corresponding to arrays
        of the current scope.
        """
        return [x for x in self.current_scope.values() if x.class_ == CLASS.array]

    @property
    def functions(self):
        """Returns symbol instances corresponding to functions
        of the current scope.
        """
        return [x for x in self.current_scope.values() if x.class_ in (CLASS.function, CLASS.sub)]

    @property
    def aliases(self):
        """Returns symbol instances corresponding to aliased vars."""
        return [x for x in self.current_scope.values() if x.is_aliased]

    def __getitem__(self, level: int):
        """Returns the SYMBOL TABLE for the given scope"""
        return self.table[level]

    def __iter__(self):
        """Iterates through scopes, from current one (innermost) to global
        (outermost)
        """
        for scope in self.table[::-1]:
            yield scope
