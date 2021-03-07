# Runtime Labels

from typing import Dict

from .namespace import NAMESPACE

from . import core
from . import datarestore
from . import io
from . import math
from . import random


class Labels(
    core.CoreLabels,
    datarestore.DataRestoreLabels,
    io.IOLabels,
    math.MathLabels,
    random.RandomLabels
):
    """ All labels
    """
    NAMESPACE = NAMESPACE


RUNTIME_LABELS = set(getattr(Labels, x) for x in dir(Labels) if not x.startswith('__') and x != 'NAMESPACE')


def dict_join(*args: Dict[str, str]) -> Dict[str, str]:
    assert all(isinstance(x, dict) for x in args)
    result = {}

    for dict_ in args:
        for lbl in dict_:
            assert lbl in RUNTIME_LABELS, f"{lbl} is not a registered Label"
            assert lbl not in result, f"Duplicated label {lbl}"
        result.update(dict_)

    return result


LABEL_REQUIRED_MODULES = dict_join(
    core.REQUIRED_MODULES,
    datarestore.REQUIRED_MODULES,
    math.REQUIRED_MODULES,
    io.REQUIRED_MODULES,
    random.REQUIRED_MODULES
)
