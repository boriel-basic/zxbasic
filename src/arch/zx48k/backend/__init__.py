# -*- coding: utf-8 -*-

from src.api.config import OPTIONS
from src.arch.z80 import backend
from src.arch.z80.backend import (
    HI16,
    INITS,
    LABEL_COUNTER,
    LO16,
    MEMINITS,
    MEMORY,
    QUADS,
    REQUIRES,
    TMP_COUNTER,
    TMP_STORAGES,
    _fpop,
    emit,
    emit_end,
    emit_start,
    tmp_label,
)

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
OPTIONS.zxnext = False


def init():
    # ZXNext asm enabled by default for this arch
    OPTIONS.zxnext = False

    backend.init()
