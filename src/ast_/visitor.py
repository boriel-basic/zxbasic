__doc__ = "Implements a generic visitor class for Trees"

from abc import abstractmethod
from collections.abc import Generator
from types import GeneratorType
from typing import Final, NamedTuple

__all__: Final[tuple[str, ...]] = ("GenericNodeVisitor",)


class ToVisit[T](NamedTuple):
    obj: T


class GenericNodeVisitor[T]:
    def visit(self, node: T | None) -> T | Generator[T | None] | None:
        stack: list[T | GeneratorType] = [ToVisit[T](node) if node is not None else None]
        last_result: T | None = None

        while stack:
            try:
                stack_top = stack[-1]
                if isinstance(stack_top, GeneratorType):
                    stack.append(stack_top.send(last_result))
                    last_result = None
                elif isinstance(stack_top, ToVisit):
                    stack.pop()
                    stack.append(self._visit(stack_top.obj))
                else:
                    last_result = stack.pop()
            except StopIteration:
                stack.pop()

        return last_result

    @abstractmethod
    def _visit(self, node: T): ...

    @abstractmethod
    def generic_visit(self, node: T) -> Generator[T | None]: ...
