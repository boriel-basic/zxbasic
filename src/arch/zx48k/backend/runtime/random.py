# Runtime labels

from .namespace import NAMESPACE


class RandomLabels:
    RANDOMIZE = f"{NAMESPACE}RANDOMIZE"


REQUIRED_MODULES = {
    RandomLabels.RANDOMIZE: 'random.asm',
}
