from src.api.errmsg import error
from src.ast import Ast
from src.ast.tree import NotAnAstError
from src.zxbasm.label import Label


class Expr(Ast):
    """A class derived from AST that will
    recursively parse its nodes and return the value
    """

    ignore = True  # Class flag
    funct = {
        "-": lambda x, y: x - y,
        "+": lambda x, y: x + y,
        "*": lambda x, y: x * y,
        "/": lambda x, y: x // y,
        "^": lambda x, y: x**y,
        "%": lambda x, y: x % y,
        "&": lambda x, y: x & y,
        "|": lambda x, y: x | y,
        "~": lambda x, y: x ^ y,
        "<<": lambda x, y: x << y,
        ">>": lambda x, y: x >> y,
    }

    def __init__(self, symbol=None):
        """Initializes ancestor attributes, and
        ignore flags.
        """
        Ast.__init__(self)
        self.symbol = symbol

    @property
    def left(self):
        if self.children:
            return self.children[0]

    @left.setter
    def left(self, value):
        if self.children:
            self.children[0] = value
        else:
            self.children.append(value)

    @property
    def right(self):
        if len(self.children) > 1:
            return self.children[1]

    @right.setter
    def right(self, value):
        if len(self.children) > 1:
            self.children[1] = value
        elif self.children:
            self.children.append(value)
        else:
            self.children = [None, value]

    def eval(self):
        """Recursively evals the node. Exits with an
        error if not resolved.
        """
        Expr.ignore = False
        result = self.try_eval()
        Expr.ignore = True

        return result

    def try_eval(self):
        """Recursively evals the node. Returns None
        if it is still unresolved.
        """
        item = self.symbol.item

        if isinstance(item, int):
            return item

        if isinstance(item, Label):
            if item.defined:
                if isinstance(item.value, Expr):
                    return item.value.try_eval()
                return item.value
            if Expr.ignore:
                return None

            # Try to resolve into the global namespace
            error(self.symbol.lineno, "Undefined label '%s'" % item.name)
            return None

        try:
            if isinstance(item, tuple):
                return tuple([x.try_eval() for x in item])

            if isinstance(item, list):
                return [x.try_eval() for x in item]

            if item == "-" and len(self.children) == 1:
                return -self.left.try_eval()

            if item == "+" and len(self.children) == 1:
                return self.left.try_eval()

            try:
                return self.funct[item](self.left.try_eval(), self.right.try_eval())
            except ZeroDivisionError:
                error(self.symbol.lineno, "Division by 0")
            except KeyError:
                pass

        except TypeError:
            pass

        return None

    @classmethod
    def makenode(cls, symbol, *nexts):
        """Stores the symbol in an AST instance,
        and left and right to the given ones
        """
        result = cls(symbol)
        for i in nexts:
            if i is None:
                continue
            if not isinstance(i, cls):
                raise NotAnAstError(i)
            result.append_child(i)

        return result
