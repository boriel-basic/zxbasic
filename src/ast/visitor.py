__doc__ = "Implements a generic visitor class for Trees"

from collections.abc import Generator
from types import GeneratorType
from typing import Generic, TypeVar

_T = TypeVar("_T")


class GenericNodeVisitor(Generic[_T]):
    def __init__(self, type_: type[_T]):
        self.node_type: type[_T] = type_

    def visit(self, node: _T) -> _T | Generator[_T | None, None, None] | None:
        stack: list[_T | GeneratorType] = [node]
        last_result: _T | None = None

        while stack:
            try:
                stack_top = stack[-1]
                if isinstance(stack_top, GeneratorType):
                    stack.append(stack_top.send(last_result))
                    last_result = None
                elif isinstance(stack_top, self.node_type):
                    stack.pop()
                    stack.append(self._visit(stack_top))
                else:
                    last_result = stack.pop()
            except StopIteration:
                stack.pop()

        return last_result

    def _visit(self, node):
        meth = getattr(self, f"visit_{node.token}", self.generic_visit)
        return meth(node)

    def generic_visit(self, node: _T) -> Generator[_T | None, None, None]:
        raise RuntimeError(f"No visit_{node.token}() method defined")
