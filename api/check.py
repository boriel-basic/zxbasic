#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:sw=4:et:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from . import config
from . import global_
from .constants import CLASS
from .constants import SCOPE
from .errmsg import syntax_error


__all__ = ['check_type',
           'check_is_declared_strict',
           'check_call_arguments',
           'check_pending_calls',
           'check_pending_labels',
           'is_number',
           'is_const',
           'is_static',
           'is_string',
           'is_numeric',
           'is_dynamic',
           'is_null',
           'is_unsigned',
           'common_type'
           ]

# ----------------------------------------------------------------------
# Several check functions.
# These functions trigger syntax errors if checking goal fails.
# ----------------------------------------------------------------------


def check_type(lineno, type_list, arg):
    ''' Check arg's type is one in type_list, otherwise,
    raises an error.
    '''
    if not isinstance(type_list, list):
        type_list = [type_list]

    if arg.type_ in type_list:
        return True

    if len(type_list) == 1:
        syntax_error(lineno, "Wrong expression type '%s'. Expected '%s'" %
                     (arg.type_, type_list[0]))
    else:
        syntax_error(lineno, "Wrong expression type '%s'. Expected one of '%s'"
                     % (arg.type_, tuple(type_list)))

    return False


def check_is_declared_strict(lineno, id_, classname='variable'):
    ''' Check if the current ID is already declared.
    If not, triggers a "undeclared identifier" error,
    if the --strict command line flag is enabled (or #pragma
    option strict is in use).

    If not in strict mode, passes it silently.
    '''
    if not config.OPTIONS.explicit.value:
        return True

    entry = global_.SYMBOL_TABLE.check_is_declared(id_, lineno, classname)
    return entry is not None  # True if declared


def check_call_arguments(lineno, id_, args):
    ''' Check arguments against function signature.

        Checks every argument in a function call against a function.
        Returns True on success.
    '''
    if not global_.SYMBOL_TABLE.check_is_declared(id_, lineno, 'function'):
        return False

    if not global_.SYMBOL_TABLE.check_class(id_, CLASS.function, lineno):
        return False

    entry = global_.SYMBOL_TABLE.get_entry(id_)

    if len(args) != len(entry.params):
        c = 's' if len(entry.params) != 1 else ''
        syntax_error(lineno, "Function '%s' takes %i parameter%s, not %i" %
                     (id_, len(entry.params), c, len(args)))
        return False

    for arg, param in zip(args, entry.params):
        if not arg.typecast(param.type_):
            return False

        if param.byref:
            from symbols.var import SymbolVAR
            if not isinstance(arg.value, SymbolVAR):
                syntax_error(lineno, "Expected a variable name, not an "
                                     "expression (parameter By Reference)")
                return False

            if arg.class_ not in (CLASS.var, CLASS.array):
                syntax_error(lineno, "Expected a variable or array name "
                                     "(parameter By Reference)")
                return False

            arg.byref = True

    return True


def check_pending_calls():
    ''' Calls the above function for each pending call of the current scope
    level
    '''
    result = True

    # Check for functions defined after calls (parametres, etc)
    for id_, params, lineno in global_.FUNCTION_CALLS:
        result = result and check_call_arguments(lineno, id_, params)

    return result


def check_pending_labels(ast):
    ''' Iteratively traverses the node looking for ID with no class set,
    marks them as labels, and check they've been declared.

    This way we avoid stack overflow for high line-numbered listings.
    '''
    result = True
    visited = set()
    pending = [ast]

    while pending:
        node = pending.pop()

        if node is None or node in visited:  # Avoid recursive infinite-loop
            continue

        visited.add(node)
        for x in node.children:
            pending.append(x)

        if node.token != 'VAR' or (node.token == 'VAR' and node.class_ is not CLASS.unknown):
            continue

        tmp = global_.SYMBOL_TABLE.get_entry(node.name)
        if tmp is None or tmp.class_ is CLASS.unknown:
            syntax_error(node.lineno, 'Undeclared identifier "%s"'
                         % node.name)
        else:
            assert tmp.class_ == CLASS.label
            node.to_label(node)

        result = result and tmp is not None

    return result


# ----------------------------------------------------------------------
# Function for checking some arguments
# ----------------------------------------------------------------------
def is_null(*symbols):
    ''' True if no nodes or all the given nodes are either
    None, NOP or empty blocks.
    '''
    from symbols.symbol_ import Symbol

    for sym in symbols:
        if sym is None:
            continue
        if not isinstance(sym, Symbol):
            return False
        if sym.token == 'NOP':
            continue
        if sym.token == 'BLOCK' and not sym:
            continue
        return False
    return True


def is_SYMBOL(token, *symbols):
    ''' Returns True if ALL of the given argument are AST nodes
    of the given token (e.g. 'BINARY')
    '''
    from symbols.symbol_ import Symbol
    assert all(isinstance(x, Symbol) for x in symbols)
    for sym in symbols:
        if sym.token != token:
            return False

    return True


def is_string(*p):
    return is_SYMBOL('STRING', *p)


def is_const(*p):
    ''' A constant in the program, like CONST a = 5
    '''
    return is_SYMBOL('VAR', *p) and all(x.class_ == CLASS.const for x in p)


def is_CONST(*p):
    ''' Not to be confused with the above.
    Check it's a CONSTant expression
    '''
    return is_SYMBOL('CONST', *p)


def is_static(*p):
    ''' A static value (does not change at runtime)
     which is known at compile time
    '''
    return all(is_SYMBOL('CONST', x)
               or is_number(x)
               or is_const(x)
               for x in p)


def is_number(*p):
    ''' Returns True if ALL of the arguments are AST nodes
    containing NUMBER or numeric CONSTANTS
    '''
    try:
        for i in p:
            if i.token != 'NUMBER' and (i.token != 'ID' or
                                        i.class_ != CLASS.const):
                return False

        return True
    except:
        pass

    return False


def is_var(*p):
    ''' Returns True if ALL of the arguments are AST nodes
    containing ID
    '''
    return is_SYMBOL('VAR', *p)


def is_integer(*p):
    from symbols.type_ import Type

    try:
        for i in p:
            if not i.is_basic or not Type.is_integral(i.type_):
                return False

        return True
    except:
        pass

    return False


def is_unsigned(*p):
    ''' Returns false unless all types in p are unsigned
    '''
    from symbols.type_ import Type

    try:
        for i in p:
            if not i.type_.is_basic or not Type.is_unsigned(i.type_):
                return False

        return True
    except:
        pass

    return False


def is_signed(*p):
    ''' Returns false unless all types in p are signed
    '''
    from symbols.type_ import Type

    try:
        for i in p:
            if not i.type_.is_basic or not Type.is_signed(i.type_):
                return False

        return True
    except:
        pass

    return False


def is_numeric(*p):
    from symbols.type_ import Type

    try:
        for i in p:
            if not i.type_.is_basic or not Type.is_numeric(i.type_):
                return False

        return True
    except:
        pass

    return False


def is_type(type_, *p):
    ''' True if all args have the same type
    '''
    try:
        for i in p:
            if i.type_ != type_:
                return False

        return True
    except:
        pass

    return False


def is_dynamic(*p):  #TODO: Explain this better
    ''' True if all args are dynamic (e.g. Strings, dynamic arrays, etc)
    The use a ptr (ref) and it might change during runtime.
    '''
    from symbols.type_ import Type

    try:
        for i in p:
            if i.scope == SCOPE.global_ and i.is_basic and \
                            i.type_ != Type.string:
                return False

        return True
    except:
        pass

    return False


def common_type(a, b):
    ''' Returns a type which is common for both a and b types.
    Returns None if no common types allowed.
    '''
    from symbols.type_ import SymbolBASICTYPE as BASICTYPE
    from symbols.type_ import Type as TYPE
    from symbols.type_ import SymbolTYPE

    if a is None or b is None:
        return None

    if not isinstance(a, SymbolTYPE):
        a = a.type_

    if not isinstance(b, SymbolTYPE):
        b = b.type_

    if a == b:    # Both types are the same?
        return a  # Returns it

    if a == TYPE.unknown and b == TYPE.unknown:
        return BASICTYPE(global_.DEFAULT_TYPE)

    if a == TYPE.unknown:
        return b

    if b == TYPE.unknown:
        return a

    # TODO: This will removed / expanded in the future
    assert a.is_basic
    assert b.is_basic

    types = (a, b)

    if TYPE.float_ in types:
        return TYPE.float_

    if TYPE.fixed in types:
        return TYPE.fixed

    if TYPE.string in types:  # TODO: Check this ??
        return TYPE.unknown

    result = a if a.size > b.size else b

    if not TYPE.is_unsigned(a) or not TYPE.is_unsigned(b):
        result = TYPE.to_signed(result)

    return result
