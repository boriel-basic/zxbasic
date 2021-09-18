from src.api.errmsg import error
from src.zxbasm import global_ as asm_gl


class Label:
    """A class to store Label information (NAME, line number and Address)"""

    def __init__(self, name: str, lineno: int, value=None, local=False, namespace=None, is_address=False):
        """Defines a Label object.

        :param name: The label name. e.g. __LOOP. If an integer number is given, it's a temporary label
        :param lineno: Where was this label defined.
        :param value: Memory address or numeric value this label refers to (None if undefined yet)
        :param local: whether this is a local label or a global one
        :param namespace: If the label is DECLARED (not accessed), this is its prefixed namespace
        :param is_address: Whether this label refers to a memory address (declared without EQU)
        """
        self._name = name
        self.lineno = lineno
        self.value = value
        self.local = local
        self.namespace = namespace
        self.current_namespace = asm_gl.NAMESPACE  # Namespace under which the label was referenced (not declared)
        self.is_address = is_address

    @property
    def defined(self):
        """Returns whether it has a value already or not."""
        return self.value is not None

    def define(self, value, lineno: int, namespace=None):
        """Defines label value. It can be anything. Even an AST"""
        if self.defined:
            error(lineno, "label '%s' already defined at line %i" % (self.name, self.lineno))

        self.value = value
        self.lineno = lineno
        self.namespace = asm_gl.NAMESPACE if namespace is None else namespace

    @property
    def is_temporary(self):
        return self._name[0].isdecimal()

    @property
    def direction(self) -> int:
        """Direction to search for this label (-1, 1)"""
        return 0 if not self.is_temporary else {"B": -1, "F": 1}.get(self._name[-1], 0)

    @property
    def name(self):
        return self._name if not self.is_temporary else self._name.strip("BF")

    def __eq__(self, other):
        if isinstance(other, Label):
            return other.name == self.name and other.namespace == self.namespace

        return False
