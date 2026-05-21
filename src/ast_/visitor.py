__doc__ = "Implements a generic visitor class for Trees"

from abc import abstractmethod
from collections.abc import Generator
from types import GeneratorType
from typing import Final, Generic, NamedTuple, TypeVar

__all__: Final[tuple[str, ...]] = ("GenericNodeVisitor",)

_T = TypeVar("_T")


class ToVisit(NamedTuple, Generic[_T]):
    obj: _T


class GenericNodeVisitor(Generic[_T]):
    def visit(self, node: _T | None) -> _T | Generator[_T | None, None, None] | None:
        stack: list[_T | GeneratorType] = [ToVisit[_T](node) if node is not None else None]
        last_result: _T | None = None

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
    def _visit(self, node: _T): ...

    @abstractmethod
    def generic_visit(self, node: _T) -> Generator[_T | None, None, None]: ...
