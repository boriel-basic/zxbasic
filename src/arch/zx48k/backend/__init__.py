# -*- coding: utf-8 -*-

from src.api.config import OPTIONS
from src.arch.z80 import backend
from src.arch.z80.backend import (
    HI16,
    INITS,
    LO16,
    MEMINITS,
    MEMORY,
    QUADS,
    REQUIRES,
    TMP_COUNTER,
    TMP_STORAGES,
    fpop,
)

__all__ = (
    "fpop",
    "HI16",
    "INITS",
    "LO16",
    "MEMORY",
    "MEMINITS",
    "QUADS",
    "REQUIRES",
    "TMP_COUNTER",
    "TMP_STORAGES",
)


# ZXNext asm enabled by default for this arch
OPTIONS.zxnext = False


def init():
    # ZXNext asm enabled by default for this arch
    OPTIONS.zxnext = False

    backend.init()
