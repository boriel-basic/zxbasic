#!/usr/bin/python
# -*- coding: utf-8 -*-

from typing import Optional

import collections
from api.errors import Error

__all__ = ['NotAnAstError', 'Tree']


class NotAnAstError(Error):
    """ Thrown when the "pointer" is not
    an AST, but another thing.
    """
    def __init__(self, instance):
        self.instance = instance
        self.msg = "Object '%s' is not an Ast instance" % str(instance)

    def __str__(self):
        return self.msg


class Tree:
    """ Simple tree implementation
    """
    parent: Optional['Tree'] = None

    class ChildrenList:
        def __init__(self, node: 'Tree'):
            assert isinstance(node, Tree)
            self.parent = node  # Node having this children
            self._children = []

        def __getitem__(self, key):
            if isinstance(key, int):
                return self._children[key]

            result = Tree.ChildrenList(self.parent)
            for x in self._children[key]:
                result.append(x)
            return result

        def __setitem__(self, key, value):
            assert value is None or isinstance(value, Tree)
            if value is not None:
                value.parent = self.parent
            self._children[key] = value

        def __delitem__(self, key):
            self._children[key].parent = None
            del self._children[key]

        def append(self, value):
            assert isinstance(value, Tree)
            value.parent = self.parent
            self._children.append(value)

        def insert(self, pos, value):
            assert isinstance(value, Tree)
            value.parent = self.parent
            self._children.insert(pos, value)

        def pop(self, pos=-1):
            result = self._children.pop(pos)
            result.parent = None
            return result

        def __len__(self):
            return len(self._children)

        def __add__(self, other):
            if not isinstance(other, Tree.ChildrenList):
                assert isinstance(other, collections.Container)

            result = Tree.ChildrenList(self.parent)
            for x in self:
                result.append(x)
            for x in other:
                result.append(x)
            return result

        def __repr__(self):
            return "%s:%s" % (self.parent.__repr__(), str([x.__repr__() for x in self._children]))

    def __init__(self):
        self._children = Tree.ChildrenList(self)

    @property
    def children(self):
        return self._children

    @children.setter
    def children(self, value):
        assert isinstance(value, collections.Iterable)
        while len(self.children):
            self.children.pop()

        self._children = Tree.ChildrenList(self)
        for x in value:
            self.children.append(x)

    def inorder(self):
        """ Traverses the tree in order
        """
        for i in self.children:
            yield from i.inorder()

        yield self

    def preorder(self):
        """ Traverses the tree in preorder
        """
        yield self

        for i in self.children:
            yield from i.preorder()

    def postorder(self):
        """ Traverses the tree in postorder
        """
        for i in range(len(self.children) - 1, -1, -1):
            yield from self.children[i].postorder()

        yield self

    def appendChild(self, node):
        """ Appends the given node to the current children list
        """
        self.children.append(node)

    def prependChild(self, node):
        """ Inserts the given node at the beginning of the children list
        """
        self.children.insert(0, node)
