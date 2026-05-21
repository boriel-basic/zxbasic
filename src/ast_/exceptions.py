from typing import Final

from src.api.exception import Error

__all__: Final[tuple[str, ...]] = ("NotAnAstError",)


class NotAnAstError(Error):
    """Thrown when the "pointer" is not
    an AST, but another thing.
    """

    def __init__(self, instance):
        self.instance = instance
        self.msg = "Object '%s' is not an Ast instance" % str(instance)

    def __str__(self):
        return self.msg
