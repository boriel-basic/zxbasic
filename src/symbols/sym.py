#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from src.symbols.arglist import SymbolARGLIST as ARGLIST
from src.symbols.argument import SymbolARGUMENT as ARGUMENT
from src.symbols.arrayaccess import SymbolARRAYACCESS as ARRAYACCESS
from src.symbols.arraydecl import SymbolARRAYDECL as ARRAYDECL
from src.symbols.arrayload import SymbolARRAYLOAD as ARRAYLOAD
from src.symbols.asm import SymbolASM as ASM
from src.symbols.binary import SymbolBINARY as BINARY
from src.symbols.block import SymbolBLOCK as BLOCK
from src.symbols.bound import SymbolBOUND as BOUND
from src.symbols.boundlist import SymbolBOUNDLIST as BOUNDLIST
from src.symbols.builtin import SymbolBUILTIN as BUILTIN
from src.symbols.call import SymbolCALL as CALL
from src.symbols.constexpr import SymbolCONSTEXPR as CONSTEXPR
from src.symbols.funccall import SymbolFUNCCALL as FUNCCALL
from src.symbols.funcdecl import SymbolFUNCDECL as FUNCDECL
from src.symbols.id_ import SymbolID as ID
from src.symbols.nop import SymbolNOP as NOP
from src.symbols.number import SymbolNUMBER as NUMBER
from src.symbols.paramlist import SymbolPARAMLIST as PARAMLIST
from src.symbols.sentence import SymbolSENTENCE as SENTENCE
from src.symbols.string_ import SymbolSTRING as STRING
from src.symbols.strslice import SymbolSTRSLICE as STRSLICE
from src.symbols.symbol_ import Symbol as SYMBOL
from src.symbols.type_ import SymbolBASICTYPE as BASICTYPE
from src.symbols.type_ import SymbolTYPE as TYPE
from src.symbols.type_ import SymbolTYPEREF as TYPEREF
from src.symbols.typecast import SymbolTYPECAST as TYPECAST
from src.symbols.unary import SymbolUNARY as UNARY
from src.symbols.vardecl import SymbolVARDECL as VARDECL

__all__ = [
    "ARGLIST",
    "ARGUMENT",
    "ARRAYACCESS",
    "ARRAYDECL",
    "ARRAYLOAD",
    "ASM",
    "BASICTYPE",
    "BINARY",
    "BLOCK",
    "BOUND",
    "BOUNDLIST",
    "BUILTIN",
    "CALL",
    "CONSTEXPR",
    "FUNCCALL",
    "FUNCDECL",
    "ID",
    "NOP",
    "NUMBER",
    "PARAMLIST",
    "SENTENCE",
    "STRING",
    "STRSLICE",
    "SYMBOL",
    "TYPE",
    "TYPECAST",
    "TYPEREF",
    "UNARY",
    "VARDECL",
]
