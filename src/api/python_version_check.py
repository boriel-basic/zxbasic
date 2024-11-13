import sys
from typing import Final

MINIMUM_REQUIRED_PYTHON_VERSION: Final[tuple[int, int]] = (3, 12)


def init():
    if sys.version_info < MINIMUM_REQUIRED_PYTHON_VERSION:
        sys.exit("Python %i.%i or later is required." % MINIMUM_REQUIRED_PYTHON_VERSION)


init()
