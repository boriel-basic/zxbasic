# -*- coding: utf-8 -*-

from src.api.config import OPTIONS
from src.arch.z80.backend import (
    HI16,
    INITS,
    LO16,
    MEMINITS,
    REQUIRES,
    TMP_COUNTER,
    TMP_STORAGES,
)
from src.arch.z80.backend import Backend as Z80Backend
from src.arch.z80.backend import fpop

__all__ = (
    "fpop",
    "HI16",
    "INITS",
    "LO16",
    "MEMINITS",
    "REQUIRES",
    "TMP_COUNTER",
    "TMP_STORAGES",
    "Backend",
)


# ZXNext asm enabled by default for this arch
OPTIONS.zxnext = False


class Backend(Z80Backend):
    def init(self):
        # ZXNext asm enabled by default for this arch
        OPTIONS.zxnext = False
        super().init()
