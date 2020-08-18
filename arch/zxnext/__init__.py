#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

from . import beep
from .translator import *  # noqa

import api.global_
from api.constants import TYPE


__all__ = [
    'beep',
]


# -----------------------------------------
# Arch initialization setup
# -----------------------------------------
api.global_.PARAM_ALIGN = 2  # Z80 param align
api.global_.BOUND_TYPE = TYPE.uinteger
api.global_.SIZE_TYPE = TYPE.ubyte
api.global_.PTR_TYPE = TYPE.uinteger
api.global_.STR_INDEX_TYPE = TYPE.uinteger
api.global_.MIN_STRSLICE_IDX = 0      # Min. string slicing position
api.global_.MAX_STRSLICE_IDX = 65534  # Max. string slicing position
