# Miscelaneous functions

from .namespace import NAMESPACE


class MiscLabels:
    ASC = f"{NAMESPACE}__ASC"
    CHR = f"{NAMESPACE}CHR"
    PAUSE = f"{NAMESPACE}__PAUSE"
    VAL = f"{NAMESPACE}VAL"


REQUIRED_MODULES = {
    MiscLabels.ASC: 'asc.asm',
    MiscLabels.CHR: 'chr.asm',
    MiscLabels.PAUSE: 'pause.asm',
    MiscLabels.VAL: 'val.asm'
}
