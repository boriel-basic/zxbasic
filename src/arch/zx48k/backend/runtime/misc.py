# Miscelaneous functions

from .namespace import NAMESPACE


class MiscLabels:
    PAUSE = f"{NAMESPACE}__PAUSE"


REQUIRED_MODULES = {
    MiscLabels.PAUSE: 'pause.asm'
}
