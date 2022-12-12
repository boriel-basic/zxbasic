#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

import src.api.global_
from src.api.type import PrimitiveType
from src.arch.z80 import optimizer  # noqa
from src.arch.z80 import beep
from src.arch.z80.translator import *  # noqa
from src.arch.zx48k import backend  # noqa

__all__ = [
    "beep",
]


# -----------------------------------------
# Arch initialization setup
# -----------------------------------------
src.api.global_.PARAM_ALIGN = 2  # Z80 param align
src.api.global_.BOUND_TYPE = PrimitiveType.uInteger
src.api.global_.SIZE_TYPE = PrimitiveType.uByte
src.api.global_.PTR_TYPE = PrimitiveType.uInteger
src.api.global_.STR_INDEX_TYPE = PrimitiveType.uInteger
src.api.global_.MIN_STRSLICE_IDX = 0  # Min. string slicing position
src.api.global_.MAX_STRSLICE_IDX = 65534  # Max. string slicing position
