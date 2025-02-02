from __future__ import annotations

import collections.abc
from collections.abc import Iterable, Iterator
from typing import Any

from src.api.exception import Error

__all__ = "ChildrenList", "NotAnAstError", "Tree"


class NotAnAstError(Error):
    """Thrown when the "pointer" is not
    an AST, but another thing.
    """

    def __init__(self, instance):
        self.instance = instance
        self.msg = "Object '%s' is not an Ast instance" % str(instance)

    def __str__(self):
        return self.msg


class Tree:
    """Simple tree implementation"""

    __slots__ = "_children", "parent"

    def __init__(self) -> None:
        self._children = ChildrenList(self)
        self.parent: Tree | None = None

    @property
    def children(self):
        return self._children

    @children.setter
    def children(self, value: Iterable):
        assert isinstance(value, collections.abc.Iterable)
        while len(self.children):
            self.children.pop()

        self._children = ChildrenList(self)
        for x in value:
            self.children.append(x)

    def inorder(self):
        """Traverses the tree in order"""
        for i in self.children:
            yield from i.inorder()

        yield self

    def preorder(self):
        """Traverses the tree in preorder"""
        yield self

        for i in self.children:
            yield from i.preorder()

    def postorder(self):
        """Traverses the tree in postorder"""
        for i in range(len(self.children) - 1, -1, -1):
            yield from self.children[i].postorder()

        yield self

    def append_child(self, node: Tree) -> None:
        """Appends the given node to the current children list"""
        self.children.append(node)

    def prepend_child(self, node: Tree) -> None:
        """Inserts the given node at the beginning of the children list"""
        self.children.insert(0, node)


class ChildrenList:
    owner: Tree

    def __init__(self, node: Tree) -> None:
        assert isinstance(node, Tree)
        self.owner = node  # Node having this children
        self._children: list[Tree | None] = []

    def __getitem__(self, key: int | slice) -> Tree | ChildrenList | None:
        if isinstance(key, int):
            return self._children[key]

        result = ChildrenList(self.owner)
        for x in self._children[key]:
            result.append(x)

        return result

    def __setitem__(self, key: int, value: Tree | None) -> None:
        assert value is None or isinstance(value, Tree)
        if value is not None:
            value.parent = self.owner
        self._children[key] = value

    def __delitem__(self, key: int) -> None:
        child = self._children[key]
        if child is not None:
            child.parent = None
        del self._children[key]

    def __iter__(self) -> Iterator[Tree | None]:
        return iter(self._children)

    def append(self, value: Tree | None) -> None:
        if value is not None:
            value.parent = self.owner
        self._children.append(value)

    def insert(self, pos: int, value: Tree) -> None:
        assert isinstance(value, Tree)
        value.parent = self.owner
        self._children.insert(pos, value)

    def pop(self, pos: int = -1) -> Tree | None:
        result = self._children.pop(pos)
        if result is not None:
            result.parent = None

        return result

    def __len__(self) -> int:
        return len(self._children)

    def __add__(self, other: Any) -> ChildrenList:
        if not isinstance(other, ChildrenList):
            assert isinstance(other, collections.abc.Container)

        result = ChildrenList(self.owner)
        for x in self:
            result.append(x)
        for x in other:
            result.append(x)

        return result

    def __repr__(self) -> str:
        return f"{self.owner!r}:{[repr(x) for x in self._children]!s}"
