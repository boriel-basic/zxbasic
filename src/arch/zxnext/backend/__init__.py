# -*- coding: utf-8 -*-

from src.api.config import OPTIONS, Action
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
from src.arch.z80.backend import ICInfo, engine, fpop
from src.arch.z80.backend.runtime.namespace import NAMESPACE
from src.arch.zxnext.backend._8bit import _mul8
from src.arch.zxnext.peephole import OPTS_PATH

__all__ = [
    "fpop",
    "HI16",
    "INITS",
    "LO16",
    "MEMINITS",
    "REQUIRES",
    "TMP_COUNTER",
    "TMP_STORAGES",
]


class Backend(Z80Backend):
    def init(self):
        # ZXNext asm enabled by default for this arch
        super().init()
        OPTIONS.zxnext = True
        """Initializes this module"""

        # Overrides z80 generic implementation with ZX Next ones
        self._QUAD_TABLE.update(
            {
                "muli8": ICInfo(3, _mul8),
                "mulu8": ICInfo(3, _mul8),
            }
        )

        # Default code ORG
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="org", type=int, default=32768)
        # Default HEAP SIZE (Dynamic memory) in bytes
        OPTIONS(
            Action.ADD_IF_NOT_DEFINED, name="heap_size", type=int, default=4768, ignore_none=True
        )  # A bit more than 4K
        # Default HEAP ADDRESS (Dynamic memory) address
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_address", type=int, default=None, ignore_none=False)
        # Labels for HEAP START (might not be used if not needed)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_start_label", type=str, default=f"{NAMESPACE}.ZXBASIC_MEM_HEAP")
        # Labels for HEAP SIZE (might not be used if not needed)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size_label", type=str, default=f"{NAMESPACE}.ZXBASIC_HEAP_SIZE")
        # Flag for headerless mode (No prologue / epilogue)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="headerless", type=bool, default=False, ignore_none=True)

        engine.main([engine.OPTS_PATH, OPTS_PATH], force=True)  # inits the optimizer
