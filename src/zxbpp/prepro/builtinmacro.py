# -*- coding: utf-8 -*-

import src.zxbpp.prepro as prepro

from .id_ import ID
from .macrocall import MacroCall


class BuiltinMacro(ID):
    """A call to a builtin macro like __FILE__ or __LINE__
    Every time the macro() is called, the macro returns
    it value.
    """

    def __init__(self, macro_name: str, func):
        super().__init__(fname="", lineno=0, id_=macro_name)
        self.func = func

    def __call__(self, symbolTable: "prepro.DefinesTable" = None, macro: MacroCall = None) -> str:
        return self.func(macro)
