# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from collections import OrderedDict
from typing import Optional

from src.api.config import OPTIONS
from src.symbols.id_ import SymbolID
from src.symbols.symbol_ import Symbol


class Scope:
    """Implements a Scope in the SymbolTable

    A Scope is just a dictionary.

    To get a symbol, just access it by its name. So scope['a'] will
    return the 'a' symbol (e.g. a declared variable 'a') or None
    if nothing is declared in that scope (no KeyError exception is raised
    if the identifier is not defined in such scope).

    The caseins dict stores the symbol names in lowercase only if
    the global OPTION ignore case is enabled (True). This is because
    most BASIC dialects are case-insensitive. 'caseins' will be used
    as a fallback if the symbol name does not exist.

    On init() the parent mangle can be stored. The mangle is a prefix
    added to every symbol to avoid name collision.

    E.g. for a global var o function, the mangle will be '_'. So
    'a' will be output in asm as '_a'. For nested scopes, the mangled
    is composed as _function-name_varname. So a local variable in function
    myFunct will be output as _myFunct_a.
    """

    def __init__(self, namespace: str = "", parent_scope: Optional["Scope"] = None):
        from src.symbols.funcdecl import SymbolFUNCDECL

        self.symbols: dict[str, SymbolID] = OrderedDict()
        self.caseins: dict[str, SymbolID] = OrderedDict()
        self.namespace: str = namespace
        self._owner: SymbolFUNCDECL | None = None  # Function, Sub, etc. owning this scope
        self.parent_scope: Scope | None = parent_scope
        self.parent_namespace: str | None = parent_scope.namespace if parent_scope is not None else None

    def __getitem__(self, key: str) -> SymbolID | None:
        return self.symbols.get(key, self.caseins.get(key.lower(), None))

    def __setitem__(self, key: str, value: SymbolID):
        assert isinstance(value, Symbol)
        self.symbols[key] = value
        if value.caseins:  # Declared with case-insensitive option?
            self.caseins[key.lower()] = value

    def __delitem__(self, key: str):
        self.symbols.pop(key, None)
        self.caseins.pop(key, None)

    def values(self, filter_by_opt=True):
        if filter_by_opt and OPTIONS.optimization_level > 1:
            return [y for x, y in self.symbols.items() if y.accessed]
        return [y for x, y in self.symbols.items()]

    def keys(self, filter_by_opt=True):
        if filter_by_opt and OPTIONS.optimization_level > 1:
            return [x for x, y in self.symbols.items() if y.accessed]
        return self.symbols.keys()

    def items(self, filter_by_opt=True):
        if filter_by_opt and OPTIONS.optimization_level > 1:
            return [(x, y) for x, y in self.symbols.items() if y.accessed]
        return self.symbols.items()

    @property
    def owner(self):
        return self._owner

    @owner.setter
    def owner(self, value):
        from src.symbols.funcdecl import SymbolFUNCDECL

        assert value is None or isinstance(value, SymbolFUNCDECL)
        self._owner = value
