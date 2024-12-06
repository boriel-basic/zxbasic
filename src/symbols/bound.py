# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from src.api import check
from src.api.errmsg import error
from src.api.utils import eval_to_num
from src.symbols.number import SymbolNUMBER
from src.symbols.symbol_ import Symbol


class SymbolBOUND(Symbol):
    """Defines an array bound.
    Eg.:
    DIM a(1 TO 10, 3 TO 5, 8) defines 3 bounds,
      1..10, 3..5, and 0..8
    """

    def __init__(self, lower, upper):
        if isinstance(lower, SymbolNUMBER):
            lower = lower.value
        if isinstance(upper, SymbolNUMBER):
            upper = upper.value

        assert isinstance(lower, int)
        assert isinstance(upper, int)
        assert upper >= lower >= 0

        super().__init__()
        self.lower = lower
        self.upper = upper

    @property
    def count(self):
        return self.upper - self.lower + 1

    @staticmethod
    def make_node(lower, upper, lineno):
        """Creates an array bound"""
        if not check.is_static(lower, upper):
            error(lineno, "Array bounds must be constants")
            return None

        lower_value = eval_to_num(lower.t)
        if lower_value is None:  # semantic error
            error(lineno, "Unknown lower bound for array dimension")
            return None

        upper_value = eval_to_num(upper.t)
        if upper_value is None:  # semantic error
            error(lineno, "Unknown upper bound for array dimension")
            return None

        if lower_value < 0:
            error(lineno, "Array bounds must be greater than 0")
            return None

        if lower_value > upper_value:
            error(lineno, "Lower array bound must be less or equal to upper one")
            return None

        return SymbolBOUND(lower_value, upper_value)

    def __str__(self):
        if self.lower == 0:
            return f"({self.upper})"

        return f"({self.lower} TO {self.upper})"

    def __repr__(self):
        return self.token + str(self)
