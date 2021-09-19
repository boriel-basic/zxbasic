# -*- coding: utf-8 -*-

from src.api.config import OPTIONS
from src.arch.z80 import backend
from src.arch.z80.backend import ICInfo

from src.arch.zxnext.backend._8bit import _mul8

from src.arch.z80.backend import tmp_label, _fpop, HI16, INITS, LO16, LABEL_COUNTER, MEMORY, MEMINITS
from src.arch.z80.backend import QUADS, REQUIRES, TMP_COUNTER, TMP_STORAGES
from src.arch.z80.backend import emit, emit_end, emit_start


__all__ = [
    "tmp_label",
    "_fpop",
    "HI16",
    "INITS",
    "LO16",
    "LABEL_COUNTER",
    "MEMORY",
    "MEMINITS",
    "QUADS",
    "REQUIRES",
    "TMP_COUNTER",
    "TMP_STORAGES",
    "emit",
    "emit_end",
    "emit_start",
]


# ZXNext asm enabled by default for this arch
OPTIONS.zxnext = True


# Override z80 generic implementation with ZX Next ones
QUADS.update({"muli8": ICInfo(3, _mul8), "mulu8": ICInfo(3, _mul8)})


def init():
    # ZXNext asm enabled by default for this arch
    OPTIONS.zxnext = True

    backend.init()
