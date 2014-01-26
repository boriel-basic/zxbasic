#!/usr/bin/python
# -*- coding: utf-8 -*-

__all__ = ['NotAnAstError', 'Tree']

import copy
import collections
from api.errors import Error


class NotAnAstError(Error):
    ''' Thrown when the "pointer" is not
    an AST, but another thing.
    '''
    def __init__(self, instance):
        self.instance = instance
        self.msg = "Object '%s' is not an Ast instance" % str(instance)

    def __str__(self):
        return self.msg


class Tree(object):
    ''' Simple tree implementation
    '''
    class childrenList(object):
        def __init__(self, node):
            assert isinstance(node, Tree)
            self.node = node  # Node having this children
            self._children = []

        def __getitem__(self, key):
            if isinstance(key, int):
                return self._children[key]

            result = Tree.childrenList(self.node)
            for x in self._children[key]:
                result.append(x)
            return result

        def __setitem__(self, key, value):
            assert value is None or isinstance(value, Tree)
            if value is not None:
                value.parent = self.node
            self._children[key] = value

        def __delitem__(self, key):
            self._children[key].parent = None
            del self._children[key]

        def append(self, value):
            assert isinstance(value, Tree)
            value.parent = self.node
            self._children.append(value)

        def insert(self, pos, value):
            assert isinstance(value, Tree)
            value.parent = self.node
            self._children.insert(pos, value)

        def pop(self, pos=-1):
            result = self._children.pop(pos)
            result.parent = None
            return result

        def __len__(self):
            return len(self._children)

        def __add__(self, other):
            if not isinstance(other, Tree.childrenList):
                assert isinstance(other, collections.Container)

            result = Tree.childrenList(self.node)
            for x in self:
                result.append(x)
            for x in other:
                result.append(x)
            return result

        def __repr__(self):
            return "%s:%s" % (self.node.__repr__(), str([x.__repr__() for x in self._children]))



    def __init__(self):
        self._children = Tree.childrenList(self)

    @property
    def children(self):
        return self._children

    @children.setter
    def children(self, value):
        assert isinstance(value, collections.Container)
        while len(self.children):
            self.children.pop()

        self._children = Tree.childrenList(self)
        for x in value:
            self.children.append(x)

    def inorder(self, funct, stopOn=None):
        ''' Iterates in order, calling the function with the current node.
        If stopOn is set to True or False, it will stop on true or false.
        '''
        if stopOn is None:
            for i in self.children:
                i.inorder(funct)
        else:
            for i in self.children:
                if i.inorder(funct) == stopOn:
                    return stopOn

        return funct(self)

    def preorder(self, funct, stopOn=None):
        ''' Iterates in preorder, calling the function with the current node.
            If stopOn is set to True or False, it will stop on true or false.
        '''
        if funct(self.symbol) == stopOn and stopOn is not None:
            return stopOn

        if stopOn is None:
            for i in self.children:
                i.preorder(funct)
        else:
            for i in self.children:
                if i.preorder(funct) == stopOn:
                    return stopOn

    def postorder(self, funct, stopOn=None):
        ''' Iterates in postorder, calling the function with the current node.
        If stopOn is set to True or False, it will stop on true or false.
        '''
        if stopOn is None:
            for i in range(len(self.children) - 1, -1, -1):
                self.children[i].postorder(funct)
        else:
            for i in range(len(self.children) - 1, -1, -1):
                if self.children[i].postorder(funct) == stopOn:
                    return stopOn
        return funct(self.symbol)

    def appendChild(self, node):
        ''' Appends the given node to the current children list
        '''
        self.children.append(node)

    def prependChild(self, node):
        ''' Inserts the given node at the beginning of the children list
        '''
        self.children.insert(0, node)

    @classmethod
    def makenode(clss, symbol, *nexts):
        ''' Stores the symbol in an AST instance,
        and left and right to the given ones
        '''
        result = clss(symbol)
        for i in nexts:
            if i is None:
                continue
            if not isinstance(i, clss):
                raise NotAnAstError(i)
            result.appendChild(i)

        return result

    def __deepcopy(self, memo):
        result = Tree(self.symbol)  # No need to duplicate the symbol memory
        result.next = copy.deepcopy(self.children)

        return result
