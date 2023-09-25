#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

import src.api.global_
from src.api.constants import TYPE
from src.arch.z80 import beep

from .visitor.function_translator import FunctionTranslator
from .visitor.translator import Translator
from .visitor.var_translator import VarTranslator

__all__ = "beep", "FunctionTranslator", "Translator", "VarTranslator"


# -----------------------------------------
# Arch initialization setup
# -----------------------------------------
src.api.global_.PARAM_ALIGN = 2  # Z80 param align
src.api.global_.BOUND_TYPE = TYPE.uinteger
src.api.global_.SIZE_TYPE = TYPE.ubyte
src.api.global_.PTR_TYPE = TYPE.uinteger
src.api.global_.STR_INDEX_TYPE = TYPE.uinteger
src.api.global_.MIN_STRSLICE_IDX = 0  # Min. string slicing position
src.api.global_.MAX_STRSLICE_IDX = 65534  # Max. string slicing position
