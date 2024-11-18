# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

__all__ = "OpcodesTemps", "init"


class Counter:
    """Implements a counter each time it's invoked"""

    def __init__(self, start: int = 0, step: int = 1):
        self._count = start
        self._step = step

    def __call__(self) -> int:
        result = self._count
        self._count += self._step

        return result


_COUNTER = Counter()


class OpcodesTemps:
    """Manages a table of Tn temporal values.
    This should be a SINGLETON container
    """

    def __init__(self, prefix: str = "t"):
        self._prefix = prefix

    def new_t(self):
        """Returns a new t-value name"""
        return f"{self._prefix}{_COUNTER()}"


def init():
    """Initializes the global container"""
    global _COUNTER
    _COUNTER = Counter()
