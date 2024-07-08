# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNUv3 General License
# ----------------------------------------------------------------------

import importlib
from types import ModuleType

from src.api.debug import __DEBUG__

__all__ = (
    "zx48k",
    "zxnext",
)

AVAILABLE_ARCHITECTURES = __all__
target: ModuleType


def set_target_arch(target_arch: str):
    global target
    assert target_arch in AVAILABLE_ARCHITECTURES, f"Invalid target architecture '{target_arch}'"
    target = importlib.import_module(f".{target_arch}", "src.arch")
    __DEBUG__(f"Target architecture set to {target_arch}")


set_target_arch(AVAILABLE_ARCHITECTURES[0])
