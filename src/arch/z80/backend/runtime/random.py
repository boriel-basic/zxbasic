# Runtime labels

from .namespace import NAMESPACE


class RandomLabels:
    RANDOMIZE = f"{NAMESPACE}.RANDOMIZE"
    RND = f"{NAMESPACE}.RND"


REQUIRED_MODULES = {RandomLabels.RANDOMIZE: "random.asm", RandomLabels.RND: "random.asm"}
