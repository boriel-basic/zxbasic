# Runtime Labels
from typing import Final

from . import core, datarestore, io, math, misc, random
from .namespace import NAMESPACE


class Labels(
    core.CoreLabels,
    datarestore.DataRestoreLabels,
    io.IOLabels,
    math.MathLabels,
    misc.MiscLabels,
    random.RandomLabels,
):
    """All labels"""

    NAMESPACE = NAMESPACE


RUNTIME_LABELS: Final[set[str]] = {
    getattr(Labels, x) for x in dir(Labels) if not x.startswith("__") and x != "NAMESPACE"
}


def _dict_join(*args: dict[str, str]) -> dict[str, str]:
    assert all(isinstance(x, dict) for x in args)
    result = {}

    for dict_ in args:
        for lbl in dict_:
            assert lbl in RUNTIME_LABELS, f"{lbl} is not a registered Label"
            assert lbl not in result, f"Duplicated label {lbl}"
        result.update(dict_)

    return result


LABEL_REQUIRED_MODULES: Final[dict[str, str]] = _dict_join(
    core.REQUIRED_MODULES,
    datarestore.REQUIRED_MODULES,
    math.REQUIRED_MODULES,
    io.REQUIRED_MODULES,
    random.REQUIRED_MODULES,
    misc.REQUIRED_MODULES,
)
